import Foundation

public enum DeleteConfirmationError: Error, Equatable, Sendable {
    case expired
    case projectMismatch
}

public struct DeleteConfirmationValidator: Sendable {
    private let maxAge: TimeInterval

    public init(maxAge: TimeInterval = 300) {
        self.maxAge = maxAge
    }

    public func issue(
        projectID: ProjectID,
        now: Date = .now
    ) -> DeleteConfirmation {
        DeleteConfirmation(projectID: projectID, issuedAt: now)
    }

    public func validate(
        confirmation: DeleteConfirmation,
        projectID: ProjectID,
        now: Date = .now
    ) throws {
        guard confirmation.projectID == projectID else {
            throw DeleteConfirmationError.projectMismatch
        }
        guard now.timeIntervalSince(confirmation.issuedAt) <= maxAge else {
            throw DeleteConfirmationError.expired
        }
    }
}
