import CryptoKit
import Foundation

public enum ProposalKind: String, Codable, Sendable {
    case proofreading
    case translation
    case userEdit
}

public struct SourceSnapshot: Codable, Sendable, Equatable {
    public let format: SourceDocumentFormat
    public let document: CanonicalDocument
    public let importedAt: Date

    public init(format: SourceDocumentFormat, document: CanonicalDocument, importedAt: Date = .now) {
        self.format = format
        self.document = document
        self.importedAt = importedAt
    }
}

public struct RevisionEvent: Codable, Sendable, Equatable {
    public let id: RevisionID
    public let projectID: ProjectID
    public let segmentID: SegmentID
    public let priorHash: String
    public let newHash: String
    public let proposalKind: ProposalKind
    public let meaningChange: Bool
    public let compositionChange: Bool
    public let acceptedByUser: Bool
    public let createdAt: Date
    public let replacementText: String

    public init(
        id: RevisionID = .make(),
        projectID: ProjectID,
        segmentID: SegmentID,
        priorHash: String,
        newHash: String,
        proposalKind: ProposalKind,
        meaningChange: Bool,
        compositionChange: Bool,
        acceptedByUser: Bool,
        createdAt: Date = .now,
        replacementText: String
    ) {
        self.id = id
        self.projectID = projectID
        self.segmentID = segmentID
        self.priorHash = priorHash
        self.newHash = newHash
        self.proposalKind = proposalKind
        self.meaningChange = meaningChange
        self.compositionChange = compositionChange
        self.acceptedByUser = acceptedByUser
        self.createdAt = createdAt
        self.replacementText = replacementText
    }
}

public extension RevisionEvent {
    static func textHash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
