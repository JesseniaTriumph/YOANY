import Foundation

public enum ExportKind: String, Codable, Sendable {
    case encryptedArchive
    case publishingDOCX
    case publishingPDF
    case publishingPlainText
}

public struct ExportIntent: Codable, Sendable, Equatable {
    public let kind: ExportKind
    public let projectID: ProjectID
    public let revisionID: RevisionID?
    public let destinationLabel: String

    public init(kind: ExportKind, projectID: ProjectID, revisionID: RevisionID?, destinationLabel: String) {
        self.kind = kind
        self.projectID = projectID
        self.revisionID = revisionID
        self.destinationLabel = destinationLabel
    }
}

public struct EncryptedArchiveManifest: Codable, Sendable, Equatable {
    public let projectID: ProjectID
    public let createdAt: Date
    public let packageCreatedAt: Date
    public let packageUpdatedAt: Date
    public let payloadDigest: String
    public let sourceSnapshotHash: String?
    public let revisionCount: Int
    public let formatVersion: Int

    public init(
        projectID: ProjectID,
        createdAt: Date = .now,
        packageCreatedAt: Date,
        packageUpdatedAt: Date,
        payloadDigest: String,
        sourceSnapshotHash: String?,
        revisionCount: Int,
        formatVersion: Int = 1
    ) {
        self.projectID = projectID
        self.createdAt = createdAt
        self.packageCreatedAt = packageCreatedAt
        self.packageUpdatedAt = packageUpdatedAt
        self.payloadDigest = payloadDigest
        self.sourceSnapshotHash = sourceSnapshotHash
        self.revisionCount = revisionCount
        self.formatVersion = formatVersion
    }
}
