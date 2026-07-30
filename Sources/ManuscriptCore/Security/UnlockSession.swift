import Foundation

public actor ProjectUnlockSessionController {
    private let timeout: TimeInterval
    private var activeProjectID: ProjectID?
    private var token: AuthenticationToken?

    public init(timeout: TimeInterval = 300) {
        self.timeout = timeout
    }

    public func open(projectID: ProjectID, token: AuthenticationToken) throws {
        guard token.isFresh else {
            throw SecurityError.authenticationFailed
        }

        activeProjectID = projectID
        self.token = AuthenticationToken(
            issuedAt: token.issuedAt,
            expiresAt: min(token.expiresAt, Date().addingTimeInterval(timeout))
        )
    }

    public func requireAuthorizedProject(_ projectID: ProjectID) throws {
        guard let activeProjectID, let token else {
            throw SecurityError.projectLocked(projectID)
        }
        guard activeProjectID == projectID else {
            throw SecurityError.unauthorizedProjectAccess(projectID)
        }
        guard token.isFresh else {
            throw SecurityError.unlockSessionExpired
        }
    }

    public func lock() {
        activeProjectID = nil
        token = nil
    }

    public func expireForBackgrounding() {
        lock()
    }

    public func activeProject() -> ProjectID? {
        guard let token, token.isFresh else {
            return nil
        }
        return activeProjectID
    }
}
