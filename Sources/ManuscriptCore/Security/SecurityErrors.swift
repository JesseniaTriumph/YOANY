import Foundation

public enum SecurityError: Error, Equatable, Sendable {
    case authenticationFailed
    case unlockSessionExpired
    case projectNotFound(ProjectID)
    case projectLocked(ProjectID)
    case unauthorizedProjectAccess(ProjectID)
    case corruptedProjectPackage(ProjectID)
    case replayedOrSubstitutedPackage(ProjectID)
    case keyUnavailable(ProjectID)
    case deleteRequiresFreshAuthentication(ProjectID)
}
