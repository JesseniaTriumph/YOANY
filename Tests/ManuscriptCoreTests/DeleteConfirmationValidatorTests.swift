import Foundation
import Testing
@testable import ManuscriptCore

struct DeleteConfirmationValidatorTests {
    @Test func validatesMatchingConfirmationWithinWindow() throws {
        let validator = DeleteConfirmationValidator(maxAge: 60)
        let projectID = ProjectID.make()
        let confirmation = validator.issue(
            projectID: projectID,
            now: Date(timeIntervalSince1970: 100)
        )

        try validator.validate(
            confirmation: confirmation,
            projectID: projectID,
            now: Date(timeIntervalSince1970: 120)
        )
    }

    @Test func rejectsExpiredDeleteConfirmation() {
        let validator = DeleteConfirmationValidator(maxAge: 10)
        let projectID = ProjectID.make()
        let confirmation = validator.issue(
            projectID: projectID,
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(throws: DeleteConfirmationError.expired) {
            try validator.validate(
                confirmation: confirmation,
                projectID: projectID,
                now: Date(timeIntervalSince1970: 200)
            )
        }
    }

    @Test func rejectsMismatchedDeleteConfirmationProject() {
        let validator = DeleteConfirmationValidator(maxAge: 60)
        let confirmation = validator.issue(projectID: ProjectID.make())

        #expect(throws: DeleteConfirmationError.projectMismatch) {
            try validator.validate(
                confirmation: confirmation,
                projectID: ProjectID.make()
            )
        }
    }
}
