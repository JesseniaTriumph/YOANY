import Foundation

public struct PlainTextImportOptions: Sendable {
    public let maxBytes: Int
    public let maxSegmentCharacters: Int

    public init(maxBytes: Int = 2_000_000, maxSegmentCharacters: Int = 20_000) {
        self.maxBytes = maxBytes
        self.maxSegmentCharacters = maxSegmentCharacters
    }
}

public struct PlainTextDocumentImporter: Sendable {
    private let options: PlainTextImportOptions

    public init(options: PlainTextImportOptions = PlainTextImportOptions()) {
        self.options = options
    }

    public func `import`(data: Data) throws -> CanonicalDocument {
        guard !data.isEmpty else {
            throw DocumentImportError.emptyInput
        }
        guard data.count <= options.maxBytes else {
            throw DocumentImportError.fileTooLarge(maxBytes: options.maxBytes)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw DocumentImportError.unsupportedEncoding
        }
        return buildDocument(from: text, rawData: data)
    }

    public func `import`(text: String) throws -> CanonicalDocument {
        let data = Data(text.utf8)
        return try `import`(data: data)
    }

    private func buildDocument(from text: String, rawData: Data) -> CanonicalDocument {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let rawPages = normalized.components(separatedBy: "\u{000C}")

        var warnings: [DocumentWarning] = []
        var pages: [DocumentPage] = []

        for (pageIndex, rawPage) in rawPages.enumerated() {
            let pageID = PageID.make()
            let segments = parseSegments(in: rawPage, pageID: pageID, pageIndex: pageIndex, warnings: &warnings)
            if segments.isEmpty {
                warnings.append(
                    DocumentWarning(
                        code: .emptyPage,
                        message: "Page contains no importable text segments.",
                        pageIndex: pageIndex
                    )
                )
            }
            pages.append(
                DocumentPage(
                    id: pageID,
                    pageIndex: pageIndex,
                    sourceLabel: "Page \(pageIndex + 1)",
                    segments: segments
                )
            )
        }

        if pages.allSatisfy({ $0.segments.isEmpty }) {
            warnings.append(
                DocumentWarning(
                    code: .emptyDocument,
                    message: "Document contains no importable text."
                )
            )
        }

        return CanonicalDocument(
            format: .plainText,
            contentHash: CanonicalDocument.sha256Hex(for: rawData),
            pages: pages,
            warnings: warnings
        )
    }

    private func parseSegments(
        in rawPage: String,
        pageID: PageID,
        pageIndex: Int,
        warnings: inout [DocumentWarning]
    ) -> [DocumentSegment] {
        let paragraphCandidates = rawPage
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var segments: [DocumentSegment] = []
        segments.reserveCapacity(paragraphCandidates.count)

        for (segmentIndex, candidate) in paragraphCandidates.enumerated() {
            if candidate.count > options.maxSegmentCharacters {
                warnings.append(
                    DocumentWarning(
                        code: .oversizedSegment,
                        message: "Segment exceeds recommended size and may need downstream chunking.",
                        pageIndex: pageIndex
                    )
                )
            }

            segments.append(
                DocumentSegment(
                    pageID: pageID,
                    orderIndex: segmentIndex,
                    kind: inferKind(from: candidate),
                    text: candidate,
                    sourceRange: SourceRangeReference(pageIndex: pageIndex, segmentIndex: segmentIndex)
                )
            )
        }

        return segments
    }

    private func inferKind(from text: String) -> SegmentKind {
        if text == "***" || text == "---" {
            return .sceneBreak
        }
        if text.hasSuffix(":") && text.count < 120 {
            return .heading
        }
        if text.hasPrefix("—") || text.hasPrefix("\"") || text.hasPrefix("«") {
            return .dialogue
        }
        return .paragraph
    }
}
