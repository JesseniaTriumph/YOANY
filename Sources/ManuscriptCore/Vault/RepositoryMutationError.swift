import Foundation

public enum RepositoryMutationError: Error, Equatable, Sendable {
    case sourceSnapshotAlreadyExists(ProjectID)
}
