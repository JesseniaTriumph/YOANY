import CryptoKit
import Foundation

struct StoredProjectPackage: Codable, Sendable {
    let projectID: ProjectID
    let createdAt: Date
    let updatedAt: Date
    let wrappedKey: WrappedKey
    let payloadDigest: String
    let ciphertext: Data
}

private struct StoredProjectPayload: Codable, Sendable, Equatable {
    let projectID: ProjectID
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let sourceSnapshot: SourceSnapshot?
    let revisionEvents: [RevisionEvent]
}

public actor ProjectVaultRepository {
    private static let supportedArchiveFormatVersion = 1
    private let rootURL: URL
    private let keyWrapping: KeyWrapping
    private let encryptionService: EncryptionService
    private let auditLog: AuditLogStore
    private let unlockController: ProjectUnlockSessionController
    private let revisionEngine: RevisionEngine
    private let deleteConfirmationValidator: DeleteConfirmationValidator
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        rootURL: URL,
        keyWrapping: KeyWrapping,
        encryptionService: EncryptionService = AESGCMEncryptionService(),
        auditLog: AuditLogStore = AuditLogStore(),
        unlockController: ProjectUnlockSessionController = ProjectUnlockSessionController(),
        revisionEngine: RevisionEngine = RevisionEngine(),
        deleteConfirmationValidator: DeleteConfirmationValidator = DeleteConfirmationValidator()
    ) throws {
        self.rootURL = rootURL
        self.keyWrapping = keyWrapping
        self.encryptionService = encryptionService
        self.auditLog = auditLog
        self.unlockController = unlockController
        self.revisionEngine = revisionEngine
        self.deleteConfirmationValidator = deleteConfirmationValidator
        encoder.outputFormatting = [.sortedKeys]

        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public func createProject(title: String) async throws -> ProjectSummary {
        let projectID = ProjectID.make()
        let now = Date()
        let key = SymmetricKey(size: .bits256)
        let wrappedKey = try keyWrapping.wrap(projectID: projectID, key: key)
        let payload = StoredProjectPayload(
            projectID: projectID,
            title: title,
            createdAt: now,
            updatedAt: now,
            sourceSnapshot: nil,
            revisionEvents: []
        )
        let package = try packageForStorage(payload: payload, wrappedKey: wrappedKey, key: key)
        try write(package, for: projectID)
        await auditLog.record(AuditEvent(type: .projectCreated, projectID: projectID, resultCode: "created"))
        return ProjectSummary(id: projectID, createdAt: now, updatedAt: now, state: .locked)
    }

    public func listProjects() throws -> [ProjectSummary] {
        try storedPackages().map {
            ProjectSummary(id: $0.projectID, createdAt: $0.createdAt, updatedAt: $0.updatedAt, state: .locked)
        }.sorted { $0.createdAt < $1.createdAt }
    }

    public func unlockProject(
        projectID: ProjectID,
        authenticator: Authenticator,
        reason: String = "Unlock encrypted manuscript project."
    ) async throws -> ProjectSnapshot {
        let package = try load(projectID: projectID)
        let token = try await authenticator.authenticate(reason: reason)
        let key = try keyWrapping.unwrap(projectID: projectID, wrappedKey: package.wrappedKey)
        let payload = try decryptPayload(package: package, key: key)
        try await unlockController.open(projectID: projectID, token: token)
        await auditLog.record(AuditEvent(type: .projectUnlocked, projectID: projectID, resultCode: "unlocked"))
        return ProjectSnapshot(
            projectID: payload.projectID,
            encryptedTitle: encryptionService.digestHex(Data(payload.title.utf8)),
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            sourceSnapshotHash: payload.sourceSnapshot.map { hash(snapshot: $0) },
            revisionIDs: payload.revisionEvents.map(\.id)
        )
    }

    public func lockProject(projectID: ProjectID) async {
        await unlockController.lock()
        await auditLog.record(AuditEvent(type: .projectLocked, projectID: projectID, resultCode: "locked"))
    }

    public func deleteProject(
        projectID: ProjectID,
        confirmation: DeleteConfirmation,
        authenticator: Authenticator,
        reason: String = "Delete encrypted manuscript project."
    ) async throws {
        let token = try await authenticator.authenticate(reason: reason)
        guard token.isFresh else {
            throw SecurityError.deleteRequiresFreshAuthentication(projectID)
        }
        try deleteConfirmationValidator.validate(
            confirmation: confirmation,
            projectID: projectID
        )
        let url = fileURL(for: projectID)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SecurityError.projectNotFound(projectID)
        }

        await unlockController.lock()
        try keyWrapping.remove(projectID: projectID)
        try FileManager.default.removeItem(at: url)
        await auditLog.record(AuditEvent(type: .projectDeleted, projectID: projectID, resultCode: "deleted"))
    }

    public func requireUnlocked(projectID: ProjectID) async throws {
        try await unlockController.requireAuthorizedProject(projectID)
    }

    public func importSourceDocument(
        projectID: ProjectID,
        document: CanonicalDocument
    ) async throws -> ProjectSnapshot {
        try await unlockController.requireAuthorizedProject(projectID)
        let package = try load(projectID: projectID)
        let key = try keyWrapping.unwrap(projectID: projectID, wrappedKey: package.wrappedKey)
        var payload = try decryptPayload(package: package, key: key)
        guard payload.sourceSnapshot == nil else {
            throw RepositoryMutationError.sourceSnapshotAlreadyExists(projectID)
        }
        let importedAt = Date()
        payload = StoredProjectPayload(
            projectID: payload.projectID,
            title: payload.title,
            createdAt: payload.createdAt,
            updatedAt: importedAt,
            sourceSnapshot: SourceSnapshot(format: document.format, document: document, importedAt: importedAt),
            revisionEvents: payload.revisionEvents
        )
        let updatedPackage = try packageForStorage(payload: payload, wrappedKey: package.wrappedKey, key: key)
        try write(updatedPackage, for: projectID)

        return ProjectSnapshot(
            projectID: payload.projectID,
            encryptedTitle: encryptionService.digestHex(Data(payload.title.utf8)),
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            sourceSnapshotHash: payload.sourceSnapshot.map { hash(snapshot: $0) },
            revisionIDs: payload.revisionEvents.map(\.id)
        )
    }

    public func acceptRevision(
        proposal: AcceptedRevisionProposal
    ) async throws -> RevisionEvent {
        try await unlockController.requireAuthorizedProject(proposal.projectID)
        let package = try load(projectID: proposal.projectID)
        let key = try keyWrapping.unwrap(projectID: proposal.projectID, wrappedKey: package.wrappedKey)
        var payload = try decryptPayload(package: package, key: key)
        let event = try revisionEngine.applyAcceptedRevision(
            proposal: proposal,
            sourceSnapshot: payload.sourceSnapshot,
            existingRevisions: payload.revisionEvents
        )
        payload = StoredProjectPayload(
            projectID: payload.projectID,
            title: payload.title,
            createdAt: payload.createdAt,
            updatedAt: event.createdAt,
            sourceSnapshot: payload.sourceSnapshot,
            revisionEvents: payload.revisionEvents + [event]
        )
        let updatedPackage = try packageForStorage(payload: payload, wrappedKey: package.wrappedKey, key: key)
        try write(updatedPackage, for: proposal.projectID)
        return event
    }

    public func sourceSnapshot(projectID: ProjectID) async throws -> SourceSnapshot? {
        try await unlockController.requireAuthorizedProject(projectID)
        let package = try load(projectID: projectID)
        let key = try keyWrapping.unwrap(projectID: projectID, wrappedKey: package.wrappedKey)
        let payload = try decryptPayload(package: package, key: key)
        return payload.sourceSnapshot
    }

    public func revisionEvents(projectID: ProjectID) async throws -> [RevisionEvent] {
        try await unlockController.requireAuthorizedProject(projectID)
        let package = try load(projectID: projectID)
        let key = try keyWrapping.unwrap(projectID: projectID, wrappedKey: package.wrappedKey)
        let payload = try decryptPayload(package: package, key: key)
        return payload.revisionEvents
    }

    public func currentDocument(projectID: ProjectID) async throws -> CanonicalDocument? {
        try await unlockController.requireAuthorizedProject(projectID)
        let package = try load(projectID: projectID)
        let key = try keyWrapping.unwrap(projectID: projectID, wrappedKey: package.wrappedKey)
        let payload = try decryptPayload(package: package, key: key)
        guard payload.sourceSnapshot != nil else {
            return nil
        }
        return try revisionEngine.materializeCurrentDocument(
            sourceSnapshot: payload.sourceSnapshot,
            revisions: payload.revisionEvents
        )
    }

    public func auditEvents() async -> [AuditEvent] {
        await auditLog.events
    }

    public func exportEncryptedArchive(projectID: ProjectID) async throws -> Data {
        try await unlockController.requireAuthorizedProject(projectID)
        let package = try load(projectID: projectID)
        let packageData = try encoder.encode(package)
        let sourceSnapshotHash = try await sourceSnapshot(projectID: projectID).map { hash(snapshot: $0) }
        let revisionCount = try await revisionEvents(projectID: projectID).count
        let manifest = EncryptedArchiveManifest(
            projectID: projectID,
            packageCreatedAt: package.createdAt,
            packageUpdatedAt: package.updatedAt,
            payloadDigest: package.payloadDigest,
            sourceSnapshotHash: sourceSnapshotHash,
            revisionCount: revisionCount
        )
        let digest = encryptionService.digestHex(packageData)
        return try encoder.encode(
            EncryptedArchiveContainer(
                manifest: manifest,
                packageData: packageData,
                integrityDigest: digest
            )
        )
    }

    public func restoreEncryptedArchive(data: Data) async throws -> ProjectSummary {
        let container: EncryptedArchiveContainer
        do {
            container = try decoder.decode(EncryptedArchiveContainer.self, from: data)
        } catch {
            throw ArchiveRestoreError.malformedArchive
        }
        guard encryptionService.digestHex(container.packageData) == container.integrityDigest else {
            throw ArchiveRestoreError.integrityMismatch
        }
        let package: StoredProjectPackage
        do {
            package = try decoder.decode(StoredProjectPackage.self, from: container.packageData)
        } catch {
            throw ArchiveRestoreError.malformedArchive
        }
        guard container.manifest.formatVersion == Self.supportedArchiveFormatVersion else {
            throw ArchiveRestoreError.unsupportedArchiveVersion(container.manifest.formatVersion)
        }
        guard manifestMatchesPackage(container.manifest, package: package) else {
            throw ArchiveRestoreError.manifestMismatch
        }

        let destinationURL = fileURL(for: package.projectID)
        guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
            throw ArchiveRestoreError.projectAlreadyExists(package.projectID)
        }
        guard let restorable = keyWrapping as? ArchiveRestorableKeyWrapping else {
            throw ArchiveRestoreError.unsupportedKeyRestoration
        }

        let stagingURL = restoreStagingURL(for: package.projectID)
        let packageData = try encoder.encode(package)
        try packageData.write(to: stagingURL, options: .atomic)

        do {
            try restorable.importWrappedKey(projectID: package.projectID, wrappedKey: package.wrappedKey)
            try FileManager.default.moveItem(at: stagingURL, to: destinationURL)
        } catch {
            try? FileManager.default.removeItem(at: stagingURL)
            try? keyWrapping.remove(projectID: package.projectID)
            throw error
        }

        return ProjectSummary(
            id: package.projectID,
            createdAt: package.createdAt,
            updatedAt: package.updatedAt,
            state: .locked
        )
    }

    private func storedPackages() throws -> [StoredProjectPackage] {
        let urls = try FileManager.default.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "projectvault" }
        return try urls.map { url in
            let data = try Data(contentsOf: url)
            return try decoder.decode(StoredProjectPackage.self, from: data)
        }
    }

    private func load(projectID: ProjectID) throws -> StoredProjectPackage {
        let url = fileURL(for: projectID)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SecurityError.projectNotFound(projectID)
        }
        do {
            let data = try Data(contentsOf: url)
            let package = try decoder.decode(StoredProjectPackage.self, from: data)
            guard package.projectID == projectID else {
                throw SecurityError.replayedOrSubstitutedPackage(projectID)
            }
            return package
        } catch let error as SecurityError {
            throw error
        } catch {
            throw SecurityError.corruptedProjectPackage(projectID)
        }
    }

    private func write(_ package: StoredProjectPackage, for projectID: ProjectID) throws {
        let data = try encoder.encode(package)
        try data.write(to: fileURL(for: projectID), options: .atomic)
    }

    private func packageForStorage(
        payload: StoredProjectPayload,
        wrappedKey: WrappedKey,
        key: SymmetricKey
    ) throws -> StoredProjectPackage {
        let plaintext = try encoder.encode(payload)
        let ciphertext = try encryptionService.encrypt(plaintext, using: key)
        return StoredProjectPackage(
            projectID: payload.projectID,
            createdAt: payload.createdAt,
            updatedAt: payload.updatedAt,
            wrappedKey: wrappedKey,
            payloadDigest: encryptionService.digestHex(plaintext),
            ciphertext: ciphertext
        )
    }

    private func decryptPayload(package: StoredProjectPackage, key: SymmetricKey) throws -> StoredProjectPayload {
        let plaintext: Data
        do {
            plaintext = try encryptionService.decrypt(package.ciphertext, using: key)
        } catch {
            throw SecurityError.corruptedProjectPackage(package.projectID)
        }
        let digest = encryptionService.digestHex(plaintext)
        guard digest == package.payloadDigest else {
            throw SecurityError.replayedOrSubstitutedPackage(package.projectID)
        }
        do {
            let payload = try decoder.decode(StoredProjectPayload.self, from: plaintext)
            guard payload.projectID == package.projectID else {
                throw SecurityError.replayedOrSubstitutedPackage(package.projectID)
            }
            return payload
        } catch let error as SecurityError {
            throw error
        } catch {
            throw SecurityError.corruptedProjectPackage(package.projectID)
        }
    }

    private func fileURL(for projectID: ProjectID) -> URL {
        rootURL.appendingPathComponent(projectID.rawValue).appendingPathExtension("projectvault")
    }

    private func restoreStagingURL(for projectID: ProjectID) -> URL {
        rootURL
            .appendingPathComponent(projectID.rawValue + ".restore")
            .appendingPathExtension("projectvault")
    }

    private func hash(snapshot: SourceSnapshot) -> String {
        let data = (try? encoder.encode(snapshot)) ?? Data()
        return encryptionService.digestHex(data)
    }

    private func manifestMatchesPackage(
        _ manifest: EncryptedArchiveManifest,
        package: StoredProjectPackage
    ) -> Bool {
        manifest.projectID == package.projectID &&
        manifest.packageCreatedAt == package.createdAt &&
        manifest.packageUpdatedAt == package.updatedAt &&
        manifest.payloadDigest == package.payloadDigest
    }
}
