import Foundation
#if canImport(LocalAuthentication)
import LocalAuthentication
#endif

public struct AuthenticationToken: Sendable, Equatable {
    public let issuedAt: Date
    public let expiresAt: Date

    public init(issuedAt: Date = .now, expiresAt: Date) {
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
    }

    public var isFresh: Bool {
        expiresAt > .now
    }
}

public protocol Authenticator: Sendable {
    func authenticate(reason: String) async throws -> AuthenticationToken
}

public struct LocalOnlyAuthenticator: Authenticator {
    private let sessionDuration: TimeInterval

    public init(sessionDuration: TimeInterval = 300) {
        self.sessionDuration = sessionDuration
    }

    public func authenticate(reason: String) async throws -> AuthenticationToken {
        _ = reason
        let now = Date()
        return AuthenticationToken(issuedAt: now, expiresAt: now.addingTimeInterval(sessionDuration))
    }
}

#if canImport(LocalAuthentication)
public struct DeviceOwnerAuthenticator: Authenticator {
    private let sessionDuration: TimeInterval

    public init(sessionDuration: TimeInterval = 300) {
        self.sessionDuration = sessionDuration
    }

    public func authenticate(reason: String) async throws -> AuthenticationToken {
        let context = LAContext()
        var authError: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) else {
            throw SecurityError.authenticationFailed
        }

        let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: granted)
            }
        }

        guard success else {
            throw SecurityError.authenticationFailed
        }

        let now = Date()
        return AuthenticationToken(
            issuedAt: now,
            expiresAt: now.addingTimeInterval(sessionDuration)
        )
    }
}
#endif
