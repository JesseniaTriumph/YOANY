import Foundation

public actor ProjectWorkspaceService {
    private let repository: ProjectVaultRepository
    private let noteImporter: NotesDocumentImporter
    private let textImporter: PlainTextDocumentImporter

    public init(
        repository: ProjectVaultRepository,
        noteImporter: NotesDocumentImporter = NotesDocumentImporter(),
        textImporter: PlainTextDocumentImporter = PlainTextDocumentImporter()
    ) {
        self.repository = repository
        self.noteImporter = noteImporter
        self.textImporter = textImporter
    }

    public func importPlainText(
        projectID: ProjectID,
        text: String
    ) async throws -> ProjectSnapshot {
        let document = try textImporter.import(text: text)
        return try await repository.importSourceDocument(projectID: projectID, document: document)
    }

    public func importNoteText(
        projectID: ProjectID,
        noteText: String
    ) async throws -> ProjectSnapshot {
        let document = try noteImporter.import(noteText: noteText)
        return try await repository.importSourceDocument(projectID: projectID, document: document)
    }

    public func currentDocument(projectID: ProjectID) async throws -> CanonicalDocument? {
        try await repository.currentDocument(projectID: projectID)
    }

    public func acceptUserEdit(
        projectID: ProjectID,
        segmentID: SegmentID,
        replacementText: String,
        meaningChange: Bool,
        compositionChange: Bool
    ) async throws -> RevisionEvent {
        try await repository.acceptRevision(
            proposal: AcceptedRevisionProposal(
                projectID: projectID,
                segmentID: segmentID,
                replacementText: replacementText,
                proposalKind: .userEdit,
                meaningChange: meaningChange,
                compositionChange: compositionChange
            )
        )
    }

    public func latestRevisionID(projectID: ProjectID) async throws -> RevisionID? {
        try await repository.revisionEvents(projectID: projectID).last?.id
    }
}
