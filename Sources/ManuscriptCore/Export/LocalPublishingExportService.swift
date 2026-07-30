import Foundation

public enum LocalPublishingExportError: Error, Equatable, Sendable {
    case unsupportedExportKind(ExportKind)
    case documentUnavailable(ProjectID)
    case revisionStateMismatch(expected: RevisionID?, actual: RevisionID?)
    case replayedConfirmation(ExportConfirmationID)
}

public struct LocalPublishingExportArtifact: Sendable, Equatable {
    public let confirmationID: ExportConfirmationID
    public let intent: ExportIntent
    public let fileURL: URL
    public let createdAt: Date

    public init(
        confirmationID: ExportConfirmationID,
        intent: ExportIntent,
        fileURL: URL,
        createdAt: Date
    ) {
        self.confirmationID = confirmationID
        self.intent = intent
        self.fileURL = fileURL
        self.createdAt = createdAt
    }
}

public actor LocalPublishingExportService {
    private let repository: ProjectVaultRepository
    private let confirmationValidator: ExportConfirmationValidator
    private let textExporter: LocalPublishingTextExporter
    private let stagingRootURL: URL
    private var usedConfirmationIDs: Set<ExportConfirmationID> = []

    public init(
        repository: ProjectVaultRepository,
        confirmationValidator: ExportConfirmationValidator = ExportConfirmationValidator(),
        textExporter: LocalPublishingTextExporter = LocalPublishingTextExporter(),
        stagingRootURL: URL
    ) throws {
        self.repository = repository
        self.confirmationValidator = confirmationValidator
        self.textExporter = textExporter
        self.stagingRootURL = stagingRootURL

        try FileManager.default.createDirectory(
            at: stagingRootURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public func materializeExport(
        intent: ExportIntent,
        confirmation: ExportConfirmation,
        now: Date = .now
    ) async throws -> LocalPublishingExportArtifact {
        try confirmationValidator.validate(
            confirmation: confirmation,
            kind: intent.kind,
            projectID: intent.projectID,
            revisionID: intent.revisionID,
            destinationLabel: intent.destinationLabel,
            now: now
        )
        guard !usedConfirmationIDs.contains(confirmation.id) else {
            throw LocalPublishingExportError.replayedConfirmation(confirmation.id)
        }

        guard intent.kind == .publishingPlainText else {
            throw LocalPublishingExportError.unsupportedExportKind(intent.kind)
        }

        let currentRevisionID = try await repository.revisionEvents(projectID: intent.projectID).last?.id
        guard currentRevisionID == intent.revisionID else {
            throw LocalPublishingExportError.revisionStateMismatch(
                expected: intent.revisionID,
                actual: currentRevisionID
            )
        }

        guard let document = try await repository.currentDocument(projectID: intent.projectID) else {
            throw LocalPublishingExportError.documentUnavailable(intent.projectID)
        }

        let exportDirectory = stagingRootURL
            .appendingPathComponent(intent.projectID.rawValue, isDirectory: true)
            .appendingPathComponent(confirmation.id.rawValue, isDirectory: true)
        try FileManager.default.createDirectory(
            at: exportDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let outputURL = exportDirectory.appendingPathComponent("manuscript.txt")
        let exportText = textExporter.render(document: document)
        try Data(exportText.utf8).write(to: outputURL, options: .atomic)
        usedConfirmationIDs.insert(confirmation.id)

        return LocalPublishingExportArtifact(
            confirmationID: confirmation.id,
            intent: intent,
            fileURL: outputURL,
            createdAt: now
        )
    }

    public func cleanupExport(_ artifact: LocalPublishingExportArtifact) throws {
        let exportDirectory = artifact.fileURL.deletingLastPathComponent()
        if FileManager.default.fileExists(atPath: exportDirectory.path) {
            try FileManager.default.removeItem(at: exportDirectory)
        }
    }
}
