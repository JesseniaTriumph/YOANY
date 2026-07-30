import Foundation
import Testing
@testable import ManuscriptCore

struct LocalPublishingExportServiceTests {
    @Test func materializesPlainTextExportAndCleansItUp() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Export Draft")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        let document = try PlainTextDocumentImporter().import(text: "Bonjour.\n\nDeuxieme paragraphe.")
        _ = try await fixture.repository.importSourceDocument(projectID: project.id, document: document)

        let intent = ExportIntent(
            kind: .publishingPlainText,
            projectID: project.id,
            revisionID: nil,
            destinationLabel: "On My iPad"
        )
        let validator = ExportConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(
            kind: intent.kind,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: intent.destinationLabel,
            now: Date(timeIntervalSince1970: 100)
        )
        let service = try LocalPublishingExportService(
            repository: fixture.repository,
            confirmationValidator: validator,
            stagingRootURL: fixture.rootURL.appendingPathComponent("exports", isDirectory: true)
        )

        let artifact = try await service.materializeExport(
            intent: intent,
            confirmation: confirmation,
            now: Date(timeIntervalSince1970: 120)
        )
        let exportedData = try Data(contentsOf: artifact.fileURL)
        let exportedText = try #require(String(data: exportedData, encoding: .utf8))

        #expect(exportedText == "Bonjour.\n\nDeuxieme paragraphe.")
        #expect(artifact.fileURL.path.contains(project.id.rawValue))
        #expect(!artifact.fileURL.lastPathComponent.contains("Export Draft"))

        try await service.cleanupExport(artifact)
        #expect(!FileManager.default.fileExists(atPath: artifact.fileURL.path))
    }

    @Test func rejectsExportWhenRevisionStateChangesAfterConfirmation() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Revision Export")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour.")
        )

        let intent = ExportIntent(
            kind: .publishingPlainText,
            projectID: project.id,
            revisionID: nil,
            destinationLabel: "On My iPad"
        )
        let validator = ExportConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(
            kind: intent.kind,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: intent.destinationLabel
        )
        let current = try await fixture.repository.currentDocument(projectID: project.id)
        let segmentID = try #require(current?.pages.first?.segments.first?.id)
        _ = try await fixture.repository.acceptRevision(
            proposal: AcceptedRevisionProposal(
                projectID: project.id,
                segmentID: segmentID,
                replacementText: "Bonjour a tous.",
                proposalKind: .userEdit,
                meaningChange: false,
                compositionChange: true
            )
        )

        let service = try LocalPublishingExportService(
            repository: fixture.repository,
            confirmationValidator: validator,
            stagingRootURL: fixture.rootURL.appendingPathComponent("exports", isDirectory: true)
        )
        let latestRevisionID = try #require(try await fixture.repository.revisionEvents(projectID: project.id).last?.id)

        await #expect(throws: LocalPublishingExportError.revisionStateMismatch(expected: nil, actual: latestRevisionID)) {
            _ = try await service.materializeExport(intent: intent, confirmation: confirmation)
        }
    }

    @Test func rejectsUnsupportedPublishingFormat() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "DOCX Export")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour.")
        )

        let intent = ExportIntent(
            kind: .publishingDOCX,
            projectID: project.id,
            revisionID: nil,
            destinationLabel: "On My iPad"
        )
        let validator = ExportConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(
            kind: intent.kind,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: intent.destinationLabel
        )
        let service = try LocalPublishingExportService(
            repository: fixture.repository,
            confirmationValidator: validator,
            stagingRootURL: fixture.rootURL.appendingPathComponent("exports", isDirectory: true)
        )

        await #expect(throws: LocalPublishingExportError.unsupportedExportKind(.publishingDOCX)) {
            _ = try await service.materializeExport(intent: intent, confirmation: confirmation)
        }
    }

    @Test func rejectsMismatchedDestinationConfirmation() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Destination Export")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour.")
        )

        let intent = ExportIntent(
            kind: .publishingPlainText,
            projectID: project.id,
            revisionID: nil,
            destinationLabel: "External Provider"
        )
        let validator = ExportConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(
            kind: intent.kind,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: "On My iPad"
        )
        let service = try LocalPublishingExportService(
            repository: fixture.repository,
            confirmationValidator: validator,
            stagingRootURL: fixture.rootURL.appendingPathComponent("exports", isDirectory: true)
        )

        await #expect(throws: ExportConfirmationError.destinationMismatch) {
            _ = try await service.materializeExport(intent: intent, confirmation: confirmation)
        }
    }

    @Test func rejectsReplayedConfirmation() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Replay Export")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour.")
        )

        let intent = ExportIntent(
            kind: .publishingPlainText,
            projectID: project.id,
            revisionID: nil,
            destinationLabel: "On My iPad"
        )
        let validator = ExportConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(
            kind: intent.kind,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: intent.destinationLabel
        )
        let service = try LocalPublishingExportService(
            repository: fixture.repository,
            confirmationValidator: validator,
            stagingRootURL: fixture.rootURL.appendingPathComponent("exports", isDirectory: true)
        )

        let artifact = try await service.materializeExport(intent: intent, confirmation: confirmation)

        await #expect(throws: LocalPublishingExportError.replayedConfirmation(confirmation.id)) {
            _ = try await service.materializeExport(intent: intent, confirmation: confirmation)
        }

        try await service.cleanupExport(artifact)
    }

    @Test func rejectsMismatchedExportKindConfirmation() async throws {
        let fixture = try RepositoryFixture()
        let project = try await fixture.repository.createProject(title: "Kind Export")
        _ = try await fixture.repository.unlockProject(
            projectID: project.id,
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120)
        )
        _ = try await fixture.repository.importSourceDocument(
            projectID: project.id,
            document: PlainTextDocumentImporter().import(text: "Bonjour.")
        )

        let intent = ExportIntent(
            kind: .publishingPlainText,
            projectID: project.id,
            revisionID: nil,
            destinationLabel: "On My iPad"
        )
        let validator = ExportConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(
            kind: .publishingDOCX,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: intent.destinationLabel
        )
        let service = try LocalPublishingExportService(
            repository: fixture.repository,
            confirmationValidator: validator,
            stagingRootURL: fixture.rootURL.appendingPathComponent("exports", isDirectory: true)
        )

        await #expect(throws: ExportConfirmationError.kindMismatch) {
            _ = try await service.materializeExport(intent: intent, confirmation: confirmation)
        }
    }
}
