import Foundation

public enum AppScenePhaseState: String, Codable, Sendable {
    case active
    case inactive
    case background
}

public enum AppLockReason: String, Codable, Sendable, Equatable {
    case backgrounded
    case inactivityTimeout
    case authenticationInvalidated
    case deviceLocked
    case manualLock
}

public struct AppLifecycleSecurityState: Sendable, Equatable {
    public let scenePhase: AppScenePhaseState
    public let shouldObscureSnapshots: Bool
    public let activeProjectID: ProjectID?
    public let lastLockReason: AppLockReason?

    public init(
        scenePhase: AppScenePhaseState,
        shouldObscureSnapshots: Bool,
        activeProjectID: ProjectID?,
        lastLockReason: AppLockReason?
    ) {
        self.scenePhase = scenePhase
        self.shouldObscureSnapshots = shouldObscureSnapshots
        self.activeProjectID = activeProjectID
        self.lastLockReason = lastLockReason
    }
}

public actor AppLifecycleSecurityCoordinator {
    private let unlockController: ProjectUnlockSessionController
    private var scenePhase: AppScenePhaseState
    private var shouldObscureSnapshots: Bool
    private var lastLockReason: AppLockReason?

    public init(
        unlockController: ProjectUnlockSessionController = ProjectUnlockSessionController(),
        initialScenePhase: AppScenePhaseState = .active
    ) {
        self.unlockController = unlockController
        self.scenePhase = initialScenePhase
        self.shouldObscureSnapshots = initialScenePhase != .active
    }

    public func projectUnlocked(projectID: ProjectID, token: AuthenticationToken) async throws {
        try await unlockController.open(projectID: projectID, token: token)
        lastLockReason = nil
    }

    public func requireAuthorizedProject(_ projectID: ProjectID) async throws {
        try await unlockController.requireAuthorizedProject(projectID)
    }

    public func scenePhaseChanged(_ newPhase: AppScenePhaseState) async {
        scenePhase = newPhase
        shouldObscureSnapshots = newPhase != .active

        if newPhase == .background {
            await lock(reason: .backgrounded)
        }
    }

    public func handleInactivityTimeout() async {
        await lock(reason: .inactivityTimeout)
    }

    public func handleAuthenticationInvalidation() async {
        await lock(reason: .authenticationInvalidated)
    }

    public func handleDeviceLock() async {
        await lock(reason: .deviceLocked)
    }

    public func lockManually() async {
        await lock(reason: .manualLock)
    }

    public func state() async -> AppLifecycleSecurityState {
        AppLifecycleSecurityState(
            scenePhase: scenePhase,
            shouldObscureSnapshots: shouldObscureSnapshots,
            activeProjectID: await unlockController.activeProject(),
            lastLockReason: lastLockReason
        )
    }

    private func lock(reason: AppLockReason) async {
        await unlockController.lock()
        lastLockReason = reason
    }
}
