import Foundation

public enum SecurityReviewLevel: Int, Codable, Sendable {
    case level0
    case level1
    case level2
}

public enum ProjectLifecycleState: String, Codable, Sendable {
    case locked
    case unlocked
    case deleted
}

public struct SecurityReviewReport: Codable, Sendable {
    public let level: SecurityReviewLevel
    public let trigger: String
    public let affectedTrustBoundaries: [String]
    public let controlsImplemented: [String]
    public let unverifiedItems: [String]

    public init(
        level: SecurityReviewLevel,
        trigger: String,
        affectedTrustBoundaries: [String],
        controlsImplemented: [String],
        unverifiedItems: [String]
    ) {
        self.level = level
        self.trigger = trigger
        self.affectedTrustBoundaries = affectedTrustBoundaries
        self.controlsImplemented = controlsImplemented
        self.unverifiedItems = unverifiedItems
    }
}

public struct ProjectSummary: Codable, Sendable, Hashable {
    public let id: ProjectID
    public let createdAt: Date
    public let updatedAt: Date
    public let state: ProjectLifecycleState

    public init(id: ProjectID, createdAt: Date, updatedAt: Date, state: ProjectLifecycleState) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.state = state
    }
}

public struct ProjectSnapshot: Codable, Sendable, Equatable {
    public let projectID: ProjectID
    public let encryptedTitle: String
    public let createdAt: Date
    public let updatedAt: Date
    public let sourceSnapshotHash: String?
    public let revisionIDs: [RevisionID]

    public init(
        projectID: ProjectID,
        encryptedTitle: String,
        createdAt: Date,
        updatedAt: Date,
        sourceSnapshotHash: String?,
        revisionIDs: [RevisionID]
    ) {
        self.projectID = projectID
        self.encryptedTitle = encryptedTitle
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sourceSnapshotHash = sourceSnapshotHash
        self.revisionIDs = revisionIDs
    }
}

public struct ExportConfirmation: Codable, Sendable, Equatable {
    public let id: ExportConfirmationID
    public let exportKind: ExportKind
    public let projectID: ProjectID
    public let revisionID: RevisionID?
    public let destinationLabel: String
    public let issuedAt: Date

    public init(
        id: ExportConfirmationID = .make(),
        exportKind: ExportKind,
        projectID: ProjectID,
        revisionID: RevisionID?,
        destinationLabel: String,
        issuedAt: Date = .now
    ) {
        self.id = id
        self.exportKind = exportKind
        self.projectID = projectID
        self.revisionID = revisionID
        self.destinationLabel = destinationLabel
        self.issuedAt = issuedAt
    }
}

public struct DeleteConfirmation: Codable, Sendable, Equatable {
    public let id: DeleteConfirmationID
    public let projectID: ProjectID
    public let issuedAt: Date

    public init(
        id: DeleteConfirmationID = .make(),
        projectID: ProjectID,
        issuedAt: Date = .now
    ) {
        self.id = id
        self.projectID = projectID
        self.issuedAt = issuedAt
    }
}
