import Foundation

public enum ReleaseDecision: String, Codable, Sendable {
    case ready = "READY"
    case conditional = "CONDITIONAL"
    case blocked = "BLOCKED"
}

public struct AppSecurityProfile: Sendable {
    public static let currentReview = SecurityReviewReport(
        level: .level2,
        trigger: "Native app-shell integration of local vault, authentication abstraction, encryption, lifecycle locking, and platform key storage.",
        affectedTrustBoundaries: [
            "TB-2 Encrypted vault to decrypted working memory",
            "TB-5 App lifecycle to operating system",
            "TB-6 App process to local credential/key storage",
        ],
        controlsImplemented: [
            "Per-project AES-GCM encryption for repository payloads",
            "Short-lived project unlock session actor",
            "Lifecycle coordinator for background lock and snapshot obscuring state",
            "Filesystem-only local key wrapping for app runtime storage",
            "Metadata-only audit events",
            "Delete requires fresh authentication and exact-project confirmation",
            "Tamper detection via payload digest and project identity binding",
        ],
        unverifiedItems: [
            "Actual LocalAuthentication integration on iPadOS",
            "App-switcher snapshot obscuring in a built iPad target",
            "Keychain item inspection and Secure Enclave policy verification on physical iPad hardware",
            "Network capture evidence for the native app bundle",
        ]
    )

    public static let currentDecision: ReleaseDecision = .blocked
}
