import Foundation
import Testing
@testable import ManuscriptCore

struct UnlockSessionTests {
    @Test func rejectsUnauthorizedProjectAccess() async throws {
        let controller = ProjectUnlockSessionController(timeout: 60)
        let projectA = ProjectID.make()
        let projectB = ProjectID.make()
        let token = AuthenticationToken(expiresAt: Date().addingTimeInterval(60))

        try await controller.open(projectID: projectA, token: token)

        await #expect(throws: SecurityError.unauthorizedProjectAccess(projectB)) {
            try await controller.requireAuthorizedProject(projectB)
        }
    }

    @Test func expiresSessionAfterTimeoutWindow() async throws {
        let controller = ProjectUnlockSessionController(timeout: -1)
        let project = ProjectID.make()
        let token = AuthenticationToken(expiresAt: Date().addingTimeInterval(60))

        try await controller.open(projectID: project, token: token)

        await #expect(throws: SecurityError.unlockSessionExpired) {
            try await controller.requireAuthorizedProject(project)
        }
    }
}
