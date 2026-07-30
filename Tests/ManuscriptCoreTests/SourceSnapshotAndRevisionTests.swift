import Foundation
import Testing
@testable import ManuscriptCore

struct SourceSnapshotAndRevisionTests {
    @Test func persistsImmutableSourceSnapshotAfterImport() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let document = try PlainTextDocumentImporter().import(text: "Chapitre:\n\nBonjour.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)

        let snapshot = try await fixture.repository.sourceSnapshot(projectID: project.id)
        #expect(snapshot?.document == document)
        #expect(snapshot?.format == .plainText)
    }

    @Test func rejectsReplacingImmutableSourceSnapshot() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let first = try PlainTextDocumentImporter().import(text: "Bonjour.")
        let second = try PlainTextDocumentImporter().import(text: "Salut.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: first)

        await #expect(throws: RepositoryMutationError.sourceSnapshotAlreadyExists(project.id)) {
            _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: second)
        }
    }

    @Test func acceptedRevisionUsesSourceSegmentAsInitialPriorState() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let document = try PlainTextDocumentImporter().import(text: "Bonjour.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)
        let segmentID = try #require(document.pages.first?.segments.first?.id)

        let event = try await fixture.repository.acceptRevision(
            proposal: AcceptedRevisionProposal(
                projectID: project.id,
                segmentID: segmentID,
                replacementText: "Bonjour !",
                proposalKind: .proofreading,
                meaningChange: false,
                compositionChange: false
            )
        )

        #expect(event.priorHash == RevisionEvent.textHash("Bonjour."))
        #expect(event.newHash == RevisionEvent.textHash("Bonjour !"))
        #expect(event.proposalKind == .proofreading)
    }

    @Test func acceptedRevisionChainsFromPriorAcceptedRevision() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let document = try PlainTextDocumentImporter().import(text: "Bonjour.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)
        let segmentID = try #require(document.pages.first?.segments.first?.id)

        _ = try await fixture.repository.acceptRevision(
            proposal: AcceptedRevisionProposal(
                projectID: project.id,
                segmentID: segmentID,
                replacementText: "Bonjour !",
                proposalKind: .proofreading,
                meaningChange: false,
                compositionChange: false
            )
        )

        let second = try await fixture.repository.acceptRevision(
            proposal: AcceptedRevisionProposal(
                projectID: project.id,
                segmentID: segmentID,
                replacementText: "Bonjour !!",
                proposalKind: .userEdit,
                meaningChange: false,
                compositionChange: false
            )
        )

        #expect(second.priorHash == RevisionEvent.textHash("Bonjour !"))
        #expect(second.newHash == RevisionEvent.textHash("Bonjour !!"))
    }

    @Test func materializesCurrentDocumentFromAcceptedRevisions() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let document = try PlainTextDocumentImporter().import(text: "Bonjour.\n\nEncore.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)
        let segmentID = try #require(document.pages.first?.segments.first?.id)

        _ = try await fixture.repository.acceptRevision(
            proposal: AcceptedRevisionProposal(
                projectID: project.id,
                segmentID: segmentID,
                replacementText: "Bonjour !",
                proposalKind: .proofreading,
                meaningChange: false,
                compositionChange: false
            )
        )

        let current = try await fixture.repository.currentDocument(projectID: project.id)
        #expect(current?.pages.first?.segments.first?.text == "Bonjour !")
        #expect(current?.pages.first?.segments.last?.text == "Encore.")
    }

    @Test func rejectsRevisionWhenSegmentDoesNotBelongToSource() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )

        let document = try PlainTextDocumentImporter().import(text: "Bonjour.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)
        let unknownID = SegmentID.make()

        await #expect(throws: RevisionEngineError.segmentNotFound(unknownID)) {
            try await fixture.repository.acceptRevision(
                proposal: AcceptedRevisionProposal(
                    projectID: project.id,
                    segmentID: unknownID,
                    replacementText: "Salut.",
                    proposalKind: .proofreading,
                    meaningChange: false,
                    compositionChange: false
                )
            )
        }
    }
}
