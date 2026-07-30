import Foundation
import Testing
@testable import ManuscriptCore

struct ProjectWorkspaceServiceTests {
    @Test func importsNotesTextIntoWorkspaceAndMaterializesCurrentDocument() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Notes Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let workspace = ProjectWorkspaceService(repository: fixture.repository)
        _ = try await workspace.importNoteText(
            projectID: project.id,
            noteText: "Titre:\n\nCeci vient d'une note."
        )

        let current = try await workspace.currentDocument(projectID: project.id)
        #expect(current?.pages.count == 1)
        #expect(current?.pages.first?.segments.first?.kind == .heading)
        #expect(current?.pages.first?.segments.last?.text == "Ceci vient d'une note.")
    }

    @Test func acceptsUserEditThroughWorkspaceService() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Workspace Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let workspace = ProjectWorkspaceService(repository: fixture.repository)
        _ = try await workspace.importPlainText(projectID: project.id, text: "Bonjour.")
        let current = try await workspace.currentDocument(projectID: project.id)
        let segmentID = try #require(current?.pages.first?.segments.first?.id)

        let revision = try await workspace.acceptUserEdit(
            projectID: project.id,
            segmentID: segmentID,
            replacementText: "Bonjour a tous.",
            meaningChange: false,
            compositionChange: true
        )

        #expect(revision.proposalKind == .userEdit)
        let revisedDocument = try await workspace.currentDocument(projectID: project.id)
        #expect(revisedDocument?.pages.first?.segments.first?.text == "Bonjour a tous.")
    }
}
