import Foundation
import Testing
@testable import ManuscriptCore

struct ProjectVaultRepositoryTests {
    @Test func createListUnlockLockAndDeleteProject() async throws {
        let fixture = try RepositoryFixture()
        let summary = try await fixture.repository.createProject(title: "Synthetic Draft")

        let listed = try await fixture.repository.listProjects()
        #expect(listed.count == 1)
        #expect(listed.first?.id == summary.id)

        let snapshot = try await fixture.repository.unlockProject(
            projectID: summary.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        #expect(snapshot.projectID == summary.id)

        try await fixture.repository.requireUnlocked(projectID: summary.id)
        await fixture.repository.lockProject(projectID: summary.id)
        await #expect(throws: SecurityError.projectLocked(summary.id)) {
            try await fixture.repository.requireUnlocked(projectID: summary.id)
        }

        let confirmation = DeleteConfirmationValidator(maxAge: 60).issue(projectID: summary.id)

        try await fixture.repository.deleteProject(
            projectID: summary.id,
            confirmation: confirmation,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let afterDelete = try await fixture.repository.listProjects()
        #expect(afterDelete.isEmpty)
    }

    @Test func rejectsDeleteWithMismatchedProjectConfirmation() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Synthetic Draft")
        let otherProjectID = ProjectID.make()
        let confirmation = DeleteConfirmationValidator(maxAge: 60).issue(projectID: otherProjectID)

        await #expect(throws: DeleteConfirmationError.projectMismatch) {
            try await fixture.repository.deleteProject(
                projectID: project.id,
                confirmation: confirmation,
                authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
            )
        }
    }

    @Test func rejectsDeleteWithExpiredConfirmation() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Synthetic Draft")
        let validator = DeleteConfirmationValidator(maxAge: 10)
        let confirmation = validator.issue(
            projectID: project.id,
            now: Date(timeIntervalSince1970: 100)
        )
        let repository = try ProjectVaultRepository(
            rootURL: fixture.rootURL,
            keyWrapping: InMemoryKeyWrappingService(),
            deleteConfirmationValidator: validator
        )

        await #expect(throws: DeleteConfirmationError.expired) {
            try await repository.deleteProject(
                projectID: project.id,
                confirmation: confirmation,
                authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
            )
        }
    }

    @Test func substitutedPackageIsRejected() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Synthetic Draft")
        let packageURL = fixture.packageURL(for: project.id)
        let data = try Data(contentsOf: packageURL)
        var payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        payload?["projectID"] = "proj_substituted"
        let tampered = try JSONSerialization.data(withJSONObject: payload ?? [:], options: [.sortedKeys])
        try tampered.write(to: packageURL, options: .atomic)

        await #expect(throws: SecurityError.replayedOrSubstitutedPackage(project.id)) {
            _ = try await fixture.repository.unlockProject(
                projectID: project.id,
                authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
            )
        }
    }

    @Test func corruptedCiphertextIsRejected() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Synthetic Draft")
        let packageURL = fixture.packageURL(for: project.id)
        let data = try Data(contentsOf: packageURL)
        var payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        payload?["ciphertext"] = Data("tampered".utf8).base64EncodedString()
        let tampered = try JSONSerialization.data(withJSONObject: payload ?? [:], options: [.sortedKeys])
        try tampered.write(to: packageURL, options: .atomic)

        await #expect(throws: SecurityError.corruptedProjectPackage(project.id)) {
            _ = try await fixture.repository.unlockProject(
                projectID: project.id,
                authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
            )
        }
    }

    @Test func auditLogContainsMetadataOnlyEvents() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Synthetic Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let events = await fixture.repository.auditEvents()
        let encoded = try JSONEncoder().encode(events)
        let content = String(decoding: encoded, as: UTF8.self)

        #expect(content.contains(project.id.rawValue))
        #expect(!content.contains("Synthetic Draft"))
    }
}
