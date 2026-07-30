import Foundation
import Testing
@testable import ManuscriptCore

struct ExportConfirmationValidatorTests {
    @Test func validatesMatchingConfirmationWithinWindow() throws {
        let validator = ExportConfirmationValidator(maxAge: 60)
        let projectID = ProjectID.make()
        let revisionID = RevisionID.make()
        let issuedAt = Date()
        let confirmation = validator.issue(
            kind: .publishingPlainText,
            projectID: projectID,
            revisionID: revisionID,
            destinationLabel: "On My iPad",
            now: issuedAt
        )

        try validator.validate(
            confirmation: confirmation,
            kind: .publishingPlainText,
            projectID: projectID,
            revisionID: revisionID,
            destinationLabel: "On My iPad",
            now: issuedAt.addingTimeInterval(30)
        )
    }

    @Test func rejectsExpiredConfirmation() {
        let validator = ExportConfirmationValidator(maxAge: 10)
        let projectID = ProjectID.make()
        let confirmation = validator.issue(
            kind: .publishingPlainText,
            projectID: projectID,
            revisionID: nil,
            destinationLabel: "On My iPad",
            now: Date(timeIntervalSince1970: 100)
        )

        #expect(throws: ExportConfirmationError.expired) {
            try validator.validate(
                confirmation: confirmation,
                kind: .publishingPlainText,
                projectID: projectID,
                revisionID: nil,
                destinationLabel: "On My iPad",
                now: Date(timeIntervalSince1970: 200)
            )
        }
    }

    @Test func rejectsMismatchedExportKind() {
        let validator = ExportConfirmationValidator(maxAge: 60)
        let projectID = ProjectID.make()
        let confirmation = validator.issue(
            kind: .publishingPlainText,
            projectID: projectID,
            revisionID: nil,
            destinationLabel: "On My iPad"
        )

        #expect(throws: ExportConfirmationError.kindMismatch) {
            try validator.validate(
                confirmation: confirmation,
                kind: .publishingDOCX,
                projectID: projectID,
                revisionID: nil,
                destinationLabel: "On My iPad"
            )
        }
    }
}
