import CryptoKit
import Foundation
import Testing
@testable import ManuscriptCore

struct SecurityAndDomainSupportTests {
    @Test func authenticationTokenFreshnessReflectsExpiration() {
        let freshToken = AuthenticationToken(
            issuedAt: Date().addingTimeInterval(-5),
            expiresAt: Date().addingTimeInterval(60)
        )
        #expect(freshToken.isFresh)

        let staleToken = AuthenticationToken(
            issuedAt: Date().addingTimeInterval(-120),
            expiresAt: Date().addingTimeInterval(-60)
        )
        #expect(!staleToken.isFresh)
    }

    @Test func localOnlyAuthenticatorIssuesTimeBoundToken() async throws {
        let authenticator = LocalOnlyAuthenticator(sessionDuration: 90)
        let before = Date()

        let token = try await authenticator.authenticate(reason: "Unlock project")

        #expect(token.issuedAt >= before.addingTimeInterval(-1))
        #expect(token.expiresAt.timeIntervalSince(token.issuedAt) >= 89)
        #expect(token.isFresh)
    }

    @Test func fileSystemKeyWrappingStoresLoadsImportsAndRemovesKeys() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = try FileSystemKeyWrappingService(rootURL: rootURL)
        let projectID = ProjectID.make()
        let key = SymmetricKey(size: .bits256)

        let wrapped = try service.wrap(projectID: projectID, key: key)
        let unwrapped = try service.unwrap(projectID: projectID, wrappedKey: wrapped)
        #expect(wrapped.bytes == key.withUnsafeBytes { Data($0) })
        #expect(unwrapped.withUnsafeBytes { Data($0) } == wrapped.bytes)

        let importedProject = ProjectID.make()
        try service.importWrappedKey(projectID: importedProject, wrappedKey: wrapped)
        let imported = try service.unwrap(projectID: importedProject, wrappedKey: wrapped)
        #expect(imported.withUnsafeBytes { Data($0) } == wrapped.bytes)

        try service.remove(projectID: projectID)
        #expect(throws: SecurityError.self) {
            _ = try service.unwrap(projectID: projectID, wrappedKey: wrapped)
        }
    }

    @Test func fileSystemKeyWrappingRejectsMismatchedWrappedKey() throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = try FileSystemKeyWrappingService(rootURL: rootURL)
        let projectID = ProjectID.make()
        let key = SymmetricKey(size: .bits256)
        let wrapped = try service.wrap(projectID: projectID, key: key)
        var mutatedBytes = wrapped.bytes
        mutatedBytes[0] ^= 0xFF

        #expect(throws: SecurityError.self) {
            _ = try service.unwrap(
                projectID: projectID,
                wrappedKey: WrappedKey(bytes: mutatedBytes)
            )
        }
    }

    @Test func incidentContainmentPolicyChecksSingleAndMultipleFeatures() throws {
        let policy = IncidentContainmentPolicy(disabledFeatures: [.translation, .decryptedExport])

        #expect(!policy.isEnabled(.translation))
        #expect(policy.isEnabled(.proofreading))
        #expect(throws: IncidentContainmentError.self) {
            try policy.requireEnabled(.translation)
        }
        #expect(throws: IncidentContainmentError.self) {
            try policy.requireAllEnabled([.proofreading, .decryptedExport])
        }

        try policy.requireAllEnabled([.proofreading, .plainTextImport])
    }

    @Test func glossaryLookupIsCaseInsensitiveAndReturnsNilWhenMissing() {
        let glossary = Glossary(entries: [
            GlossaryEntry(sourceTerm: "Bonjour", approvedTargetTerm: "Hello", notes: "Greeting")
        ])

        #expect(glossary.approvedTarget(for: "bonjour") == "Hello")
        #expect(glossary.approvedTarget(for: "BONJOUR") == "Hello")
        #expect(glossary.approvedTarget(for: "Au revoir") == nil)
    }

    @Test func securityDomainModelsPreserveConfiguredValues() {
        let projectID = ProjectID.make()
        let revisionID = RevisionID.make()
        let createdAt = Date(timeIntervalSince1970: 10)
        let updatedAt = Date(timeIntervalSince1970: 20)

        let report = SecurityReviewReport(
            level: .level2,
            trigger: "Coverage review",
            affectedTrustBoundaries: ["AI boundary", "Vault"],
            controlsImplemented: ["Deterministic tests"],
            unverifiedItems: ["Device evidence"]
        )
        #expect(report.level == .level2)
        #expect(report.trigger == "Coverage review")

        let summary = ProjectSummary(
            id: projectID,
            createdAt: createdAt,
            updatedAt: updatedAt,
            state: .unlocked
        )
        #expect(summary.id == projectID)
        #expect(summary.state == .unlocked)

        let snapshot = ProjectSnapshot(
            projectID: projectID,
            encryptedTitle: "ciphertext",
            createdAt: createdAt,
            updatedAt: updatedAt,
            sourceSnapshotHash: "hash",
            revisionIDs: [revisionID]
        )
        #expect(snapshot.projectID == projectID)
        #expect(snapshot.revisionIDs == [revisionID])

        let exportConfirmation = ExportConfirmation(
            exportKind: .publishingPlainText,
            projectID: projectID,
            revisionID: revisionID,
            destinationLabel: "Files"
        )
        #expect(exportConfirmation.projectID == projectID)
        #expect(exportConfirmation.revisionID == revisionID)

        let deleteConfirmation = DeleteConfirmation(projectID: projectID)
        #expect(deleteConfirmation.projectID == projectID)
    }
}

#if canImport(Security)
import Security

extension SecurityAndDomainSupportTests {
    @Test func keychainKeyWrappingStoresLoadsImportsAndRemovesKeys() throws {
        let service = KeychainKeyWrappingService(
            serviceName: "com.openai.YoanTranslator.tests.\(UUID().uuidString)"
        )
        let projectID = ProjectID.make()
        let key = SymmetricKey(size: .bits256)

        let wrapped: WrappedKey
        do {
            wrapped = try service.wrap(projectID: projectID, key: key)
        } catch let error as SecurityError {
            #expect(error == .keyUnavailable(projectID))
            return
        }

        let unwrapped = try service.unwrap(projectID: projectID, wrappedKey: wrapped)
        #expect(unwrapped.withUnsafeBytes { Data($0) } == wrapped.bytes)

        let importedProject = ProjectID.make()
        try service.importWrappedKey(projectID: importedProject, wrappedKey: wrapped)
        let imported = try service.unwrap(projectID: importedProject, wrappedKey: wrapped)
        #expect(imported.withUnsafeBytes { Data($0) } == wrapped.bytes)

        try service.remove(projectID: projectID)
        try service.remove(projectID: importedProject)
        #expect(throws: SecurityError.self) {
            _ = try service.unwrap(projectID: projectID, wrappedKey: wrapped)
        }
    }

    @Test func keychainKeyWrappingRejectsMismatchedBytes() throws {
        let service = KeychainKeyWrappingService(
            serviceName: "com.openai.YoanTranslator.tests.\(UUID().uuidString)"
        )
        let projectID = ProjectID.make()
        let key = SymmetricKey(size: .bits256)
        let wrapped: WrappedKey
        do {
            wrapped = try service.wrap(projectID: projectID, key: key)
        } catch let error as SecurityError {
            #expect(error == .keyUnavailable(projectID))
            return
        }
        var mutatedBytes = wrapped.bytes
        mutatedBytes[0] ^= 0xFF

        defer {
            try? service.remove(projectID: projectID)
        }

        #expect(throws: SecurityError.self) {
            _ = try service.unwrap(
                projectID: projectID,
                wrappedKey: WrappedKey(bytes: mutatedBytes)
            )
        }
    }
}
#endif
