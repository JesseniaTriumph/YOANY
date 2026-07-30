import Foundation

public enum ProposalCategory: String, Codable, Sendable {
    case spelling
    case grammar
    case punctuation
    case style
    case translation
    case terminology
}

public struct AIDocumentProposal: Codable, Sendable, Equatable {
    public let segmentID: SegmentID
    public let pageID: PageID?
    public let category: ProposalCategory
    public let replacementText: String
    public let reason: String
    public let uncertainty: Double
    public let meaningChange: Bool
    public let compositionChange: Bool

    public init(
        segmentID: SegmentID,
        pageID: PageID?,
        category: ProposalCategory,
        replacementText: String,
        reason: String,
        uncertainty: Double,
        meaningChange: Bool,
        compositionChange: Bool
    ) {
        self.segmentID = segmentID
        self.pageID = pageID
        self.category = category
        self.replacementText = replacementText
        self.reason = reason
        self.uncertainty = uncertainty
        self.meaningChange = meaningChange
        self.compositionChange = compositionChange
    }
}
