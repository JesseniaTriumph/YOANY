import Foundation

public struct DocumentImportRequest: Sendable {
    public let sourceURL: URL
    public let preferredFilename: String

    public init(sourceURL: URL, preferredFilename: String? = nil) {
        self.sourceURL = sourceURL
        self.preferredFilename = preferredFilename ?? sourceURL.lastPathComponent
    }
}

public struct DocumentImportResult: Sendable, Equatable {
    public let format: SourceDocumentFormat
    public let document: CanonicalDocument
    public let quarantineURL: URL

    public init(format: SourceDocumentFormat, document: CanonicalDocument, quarantineURL: URL) {
        self.format = format
        self.document = document
        self.quarantineURL = quarantineURL
    }
}

public struct ImportValidationOptions: Sendable {
    public let maxBytes: Int

    public init(maxBytes: Int = 10_000_000) {
        self.maxBytes = maxBytes
    }
}
