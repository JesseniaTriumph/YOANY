import Foundation

public enum ExportConfirmationError: Error, Equatable, Sendable {
    case expired
    case kindMismatch
    case projectMismatch
    case revisionMismatch
    case destinationMismatch
}

public struct ExportConfirmationValidator: Sendable {
    private let maxAge: TimeInterval

    public init(maxAge: TimeInterval = 300) {
        self.maxAge = maxAge
    }

    public func issue(
        kind: ExportKind,
        projectID: ProjectID,
        revisionID: RevisionID?,
        destinationLabel: String,
        now: Date = .now
    ) -> ExportConfirmation {
        ExportConfirmation(
            exportKind: kind,
            projectID: projectID,
            revisionID: revisionID,
            destinationLabel: destinationLabel,
            issuedAt: now
        )
    }

    public func validate(
        confirmation: ExportConfirmation,
        kind: ExportKind,
        projectID: ProjectID,
        revisionID: RevisionID?,
        destinationLabel: String,
        now: Date = .now
    ) throws {
        guard confirmation.exportKind == kind else {
            throw ExportConfirmationError.kindMismatch
        }
        guard confirmation.projectID == projectID else {
            throw ExportConfirmationError.projectMismatch
        }
        guard confirmation.revisionID == revisionID else {
            throw ExportConfirmationError.revisionMismatch
        }
        guard confirmation.destinationLabel == destinationLabel else {
            throw ExportConfirmationError.destinationMismatch
        }
        guard now.timeIntervalSince(confirmation.issuedAt) <= maxAge else {
            throw ExportConfirmationError.expired
        }
    }
}
