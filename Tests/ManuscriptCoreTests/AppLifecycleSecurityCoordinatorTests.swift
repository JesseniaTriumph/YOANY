import Foundation
import Testing
@testable import ManuscriptCore

struct AppLifecycleSecurityCoordinatorTests {
    @Test func inactiveSceneObscuresSnapshotsButKeepsProjectUnlocked() async throws {
        let unlockController = ProjectUnlockSessionController(timeout: 300)
        let coordinator = AppLifecycleSecurityCoordinator(unlockController: unlockController)
        let projectID = ProjectID.make()

        try await coordinator.projectUnlocked(
            projectID: projectID,
            token: AuthenticationToken(expiresAt: Date().addingTimeInterval(300))
        )
        await coordinator.scenePhaseChanged(.inactive)

        let state = await coordinator.state()
        #expect(state.scenePhase == .inactive)
        #expect(state.shouldObscureSnapshots)
        #expect(state.activeProjectID == projectID)
        #expect(state.lastLockReason == nil)
    }

    @Test func backgroundSceneLocksProjectAndObscuresSnapshots() async throws {
        let unlockController = ProjectUnlockSessionController(timeout: 300)
        let coordinator = AppLifecycleSecurityCoordinator(unlockController: unlockController)
        let projectID = ProjectID.make()

        try await coordinator.projectUnlocked(
            projectID: projectID,
            token: AuthenticationToken(expiresAt: Date().addingTimeInterval(300))
        )
        await coordinator.scenePhaseChanged(.background)

        let state = await coordinator.state()
        #expect(state.scenePhase == .background)
        #expect(state.shouldObscureSnapshots)
        #expect(state.activeProjectID == nil)
        #expect(state.lastLockReason == .backgrounded)
    }

    @Test func inactivityTimeoutLocksProjectWithoutChangingForegroundState() async throws {
        let unlockController = ProjectUnlockSessionController(timeout: 300)
        let coordinator = AppLifecycleSecurityCoordinator(unlockController: unlockController)
        let projectID = ProjectID.make()

        try await coordinator.projectUnlocked(
            projectID: projectID,
            token: AuthenticationToken(expiresAt: Date().addingTimeInterval(300))
        )
        await coordinator.handleInactivityTimeout()

        let state = await coordinator.state()
        #expect(state.scenePhase == .active)
        #expect(!state.shouldObscureSnapshots)
        #expect(state.activeProjectID == nil)
        #expect(state.lastLockReason == .inactivityTimeout)
    }

    @Test func returningActiveClearsSnapshotObscuring() async {
        let coordinator = AppLifecycleSecurityCoordinator(initialScenePhase: .inactive)

        await coordinator.scenePhaseChanged(.active)

        let state = await coordinator.state()
        #expect(state.scenePhase == .active)
        #expect(!state.shouldObscureSnapshots)
    }

    @Test func authInvalidationLocksProject() async throws {
        let unlockController = ProjectUnlockSessionController(timeout: 300)
        let coordinator = AppLifecycleSecurityCoordinator(unlockController: unlockController)
        let projectID = ProjectID.make()

        try await coordinator.projectUnlocked(
            projectID: projectID,
            token: AuthenticationToken(expiresAt: Date().addingTimeInterval(300))
        )
        await coordinator.handleAuthenticationInvalidation()

        let state = await coordinator.state()
        #expect(state.activeProjectID == nil)
        #expect(state.lastLockReason == .authenticationInvalidated)
    }
}
