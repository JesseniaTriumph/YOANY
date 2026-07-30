import CryptoKit
import Foundation
import Testing
@testable import ManuscriptCore

struct EncryptedArchiveTests {
    @Test func exportsAndRestoresEncryptedArchive() async throws {
        let sourceFixture = try RepositoryFixture()
        let project = try await sourceFixture.repository.createProject(title: "Archive Draft")
        _ = try await sourceFixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let document = try PlainTextDocumentImporter().import(text: "Bonjour archive.")
        _ = try await sourceFixture.repository.importSourceDocument(projectID: project.id, document: document)

        let archiveData = try await sourceFixture.repository.exportEncryptedArchive(projectID: project.id)

        let restoreFixture = try RepositoryFixture()
        let restored = try await restoreFixture.repository.restoreEncryptedArchive(data: archiveData)
        #expect(restored.id == project.id)

        _ = try await restoreFixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let restoredSnapshot = try await restoreFixture.repository.sourceSnapshot(projectID: project.id)
        #expect(restoredSnapshot?.document == document)
    }

    @Test func rejectsRestoringArchiveWhenProjectAlreadyExists() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Archive Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let document = try PlainTextDocumentImporter().import(text: "Bonjour archive.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)

        let archiveData = try await fixture.repository.exportEncryptedArchive(projectID: project.id)

        await #expect(throws: ArchiveRestoreError.projectAlreadyExists(project.id)) {
            _ = try await fixture.repository.restoreEncryptedArchive(data: archiveData)
        }
    }

    @Test func failedRestoreKeyImportLeavesNoPartialState() async throws {
        let sourceFixture = try RepositoryFixture()
        let project = try await sourceFixture.repository.createProject(title: "Archive Draft")
        _ = try await sourceFixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let document = try PlainTextDocumentImporter().import(text: "Bonjour archive.")
        _ = try await sourceFixture.repository.importSourceDocument(projectID: project.id, document: document)
        let archiveData = try await sourceFixture.repository.exportEncryptedArchive(projectID: project.id)

        let failingKeyWrapping = FailingArchiveImportKeyWrappingService()
        let restoreRootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let restoreRepository = try ProjectVaultRepository(
            rootURL: restoreRootURL,
            keyWrapping: failingKeyWrapping
        )

        await #expect(throws: TestRestoreFailure.importFailed) {
            _ = try await restoreRepository.restoreEncryptedArchive(data: archiveData)
        }

        let destinationURL = restoreRootURL
            .appendingPathComponent(project.id.rawValue)
            .appendingPathExtension("projectvault")
        let stagingURL = restoreRootURL
            .appendingPathComponent(project.id.rawValue + ".restore")
            .appendingPathExtension("projectvault")

        #expect(!FileManager.default.fileExists(atPath: destinationURL.path))
        #expect(!FileManager.default.fileExists(atPath: stagingURL.path))
        #expect(failingKeyWrapping.removedProjectIDs.contains(project.id))
    }

    @Test func rejectsArchiveWithManifestProjectMismatch() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Archive Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour archive.")
        )

        let archiveData = try await fixture.repository.exportEncryptedArchive(projectID: project.id)
        var container = try JSONDecoder().decode(EncryptedArchiveContainer.self, from: archiveData)
        container = EncryptedArchiveContainer(
            manifest: EncryptedArchiveManifest(
                projectID: ProjectID.make(),
                createdAt: container.manifest.createdAt,
                packageCreatedAt: container.manifest.packageCreatedAt,
                packageUpdatedAt: container.manifest.packageUpdatedAt,
                payloadDigest: container.manifest.payloadDigest,
                sourceSnapshotHash: container.manifest.sourceSnapshotHash,
                revisionCount: container.manifest.revisionCount,
                formatVersion: container.manifest.formatVersion
            ),
            packageData: container.packageData,
            integrityDigest: container.integrityDigest
        )
        let tamperedData = try JSONEncoder().encode(container)

        let restoreFixture = try RepositoryFixture()
        await #expect(throws: ArchiveRestoreError.manifestMismatch) {
            _ = try await restoreFixture.repository.restoreEncryptedArchive(data: tamperedData)
        }
    }

    @Test func rejectsArchiveWithUnsupportedManifestVersion() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Archive Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour archive.")
        )

        let archiveData = try await fixture.repository.exportEncryptedArchive(projectID: project.id)
        var container = try JSONDecoder().decode(EncryptedArchiveContainer.self, from: archiveData)
        container = EncryptedArchiveContainer(
            manifest: EncryptedArchiveManifest(
                projectID: container.manifest.projectID,
                createdAt: container.manifest.createdAt,
                packageCreatedAt: container.manifest.packageCreatedAt,
                packageUpdatedAt: container.manifest.packageUpdatedAt,
                payloadDigest: container.manifest.payloadDigest,
                sourceSnapshotHash: container.manifest.sourceSnapshotHash,
                revisionCount: container.manifest.revisionCount,
                formatVersion: 99
            ),
            packageData: container.packageData,
            integrityDigest: container.integrityDigest
        )
        let tamperedData = try JSONEncoder().encode(container)

        let restoreFixture = try RepositoryFixture()
        await #expect(throws: ArchiveRestoreError.unsupportedArchiveVersion(99)) {
            _ = try await restoreFixture.repository.restoreEncryptedArchive(data: tamperedData)
        }
    }
}

private enum TestRestoreFailure: Error, Equatable {
    case importFailed
}

private final class FailingArchiveImportKeyWrappingService: ArchiveRestorableKeyWrapping, @unchecked Sendable {
    private let lock = NSLock()
    private(set) var removedProjectIDs: [ProjectID] = []

    func wrap(projectID: ProjectID, key: SymmetricKey) throws -> WrappedKey {
        let raw = key.withUnsafeBytes { Data($0) }
        return WrappedKey(bytes: raw)
    }

    func unwrap(projectID: ProjectID, wrappedKey: WrappedKey) throws -> SymmetricKey {
        _ = projectID
        return SymmetricKey(data: wrappedKey.bytes)
    }

    func remove(projectID: ProjectID) throws {
        lock.lock()
        removedProjectIDs.append(projectID)
        lock.unlock()
    }

    func importWrappedKey(projectID: ProjectID, wrappedKey: WrappedKey) throws {
        _ = projectID
        _ = wrappedKey
        throw TestRestoreFailure.importFailed
    }
}
