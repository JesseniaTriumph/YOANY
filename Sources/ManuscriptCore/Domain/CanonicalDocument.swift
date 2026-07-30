import CryptoKit
import Foundation

public enum SourceDocumentFormat: String, Codable, Sendable {
    case plainText
    case docx
    case pdf
}

public enum SegmentKind: String, Codable, Sendable {
    case paragraph
    case heading
    case dialogue
    case sceneBreak
    case footnote
    case unknownPreservedBlock
}

public enum DocumentWarningCode: String, Codable, Sendable {
    case emptyDocument
    case emptyPage
    case oversizedSegment
    case unsupportedEncoding
}

public struct DocumentWarning: Codable, Sendable, Equatable {
    public let code: DocumentWarningCode
    public let message: String
    public let pageIndex: Int?

    public init(code: DocumentWarningCode, message: String, pageIndex: Int? = nil) {
        self.code = code
        self.message = message
        self.pageIndex = pageIndex
    }
}

public struct SourceRangeReference: Codable, Sendable, Equatable {
    public let pageIndex: Int
    public let segmentIndex: Int

    public init(pageIndex: Int, segmentIndex: Int) {
        self.pageIndex = pageIndex
        self.segmentIndex = segmentIndex
    }
}

public struct DocumentSegment: Codable, Sendable, Equatable {
    public let id: SegmentID
    public let pageID: PageID
    public let orderIndex: Int
    public let kind: SegmentKind
    public let text: String
    public let sourceRange: SourceRangeReference

    public init(
        id: SegmentID = .make(),
        pageID: PageID,
        orderIndex: Int,
        kind: SegmentKind,
        text: String,
        sourceRange: SourceRangeReference
    ) {
        self.id = id
        self.pageID = pageID
        self.orderIndex = orderIndex
        self.kind = kind
        self.text = text
        self.sourceRange = sourceRange
    }
}

public struct DocumentPage: Codable, Sendable, Equatable {
    public let id: PageID
    public let pageIndex: Int
    public let sourceLabel: String
    public let segments: [DocumentSegment]

    public init(
        id: PageID = .make(),
        pageIndex: Int,
        sourceLabel: String,
        segments: [DocumentSegment]
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.sourceLabel = sourceLabel
        self.segments = segments
    }
}

public struct CanonicalDocument: Codable, Sendable, Equatable {
    public let format: SourceDocumentFormat
    public let contentHash: String
    public let importedAt: Date
    public let pages: [DocumentPage]
    public let warnings: [DocumentWarning]

    public init(
        format: SourceDocumentFormat,
        contentHash: String,
        importedAt: Date = .now,
        pages: [DocumentPage],
        warnings: [DocumentWarning]
    ) {
        self.format = format
        self.contentHash = contentHash
        self.importedAt = importedAt
        self.pages = pages
        self.warnings = warnings
    }
}

public extension CanonicalDocument {
    static func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
