#if canImport(PDFKit)
import Foundation
import PDFKit

public struct PDFImportOptions: Sendable {
    public let maxPages: Int
    public let maxPageCharacters: Int
    public let maxObjects: Int
    public let maxStreams: Int

    public init(
        maxPages: Int = 1500,
        maxPageCharacters: Int = 100_000,
        maxObjects: Int = 20_000,
        maxStreams: Int = 5_000
    ) {
        self.maxPages = maxPages
        self.maxPageCharacters = maxPageCharacters
        self.maxObjects = maxObjects
        self.maxStreams = maxStreams
    }
}

public struct PDFDocumentImporter: Sendable {
    private let options: PDFImportOptions

    public init(options: PDFImportOptions = PDFImportOptions()) {
        self.options = options
    }

    public func `import`(data: Data) throws -> CanonicalDocument {
        try preflightValidate(rawPDFData: data)
        guard let pdf = PDFDocument(data: data) else {
            throw DocumentImportError.malformedPDF
        }
        if pdf.isLocked {
            throw DocumentImportError.encryptedPDFUnsupported
        }
        guard pdf.pageCount <= options.maxPages else {
            throw DocumentImportError.pdfPageLimitExceeded(maxPages: options.maxPages)
        }

        var warnings: [DocumentWarning] = []
        var pages: [DocumentPage] = []
        var sawTrustedText = false

        for pageIndex in 0..<pdf.pageCount {
            guard let page = pdf.page(at: pageIndex) else {
                throw DocumentImportError.malformedPDF
            }

            let pageID = PageID.make()
            let pageText = (page.string ?? "")
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\r", with: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if pageText.count > options.maxPageCharacters {
                throw DocumentImportError.oversizedPDFPage(
                    pageIndex: pageIndex,
                    maxCharacters: options.maxPageCharacters
                )
            }

            let segments: [DocumentSegment]
            if pageText.isEmpty {
                warnings.append(
                    DocumentWarning(
                        code: .emptyPage,
                        message: "PDF page contains no trusted extractable text.",
                        pageIndex: pageIndex
                    )
                )
                segments = []
            } else {
                sawTrustedText = true
                segments = splitSegments(from: pageText)
                    .enumerated()
                    .map { segmentIndex, text in
                        DocumentSegment(
                            pageID: pageID,
                            orderIndex: segmentIndex,
                            kind: inferKind(from: text),
                            text: text,
                            sourceRange: SourceRangeReference(pageIndex: pageIndex, segmentIndex: segmentIndex)
                        )
                    }
            }

            pages.append(
                DocumentPage(
                    id: pageID,
                    pageIndex: pageIndex,
                    sourceLabel: page.label ?? "Page \(pageIndex + 1)",
                    segments: segments
                )
            )
        }

        guard sawTrustedText else {
            throw DocumentImportError.missingTrustedTextLayer
        }

        return CanonicalDocument(
            format: .pdf,
            contentHash: CanonicalDocument.sha256Hex(for: data),
            pages: pages,
            warnings: warnings
        )
    }

    private func preflightValidate(rawPDFData: Data) throws {
        guard let rawString = String(data: rawPDFData, encoding: .isoLatin1) else {
            throw DocumentImportError.malformedPDF
        }

        let trimmedPrefix = rawString.prefix(1024)
        guard trimmedPrefix.contains("%PDF-") else {
            throw DocumentImportError.malformedPDF
        }

        let trimmedSuffix = rawString.suffix(2048)
        guard trimmedSuffix.contains("%%EOF") else {
            throw DocumentImportError.malformedPDF
        }

        let forbiddenMarkerPatterns = [
            #"/JavaScript\b"#,
            #"/JS\b"#,
            #"/Launch\b"#,
            #"/OpenAction\b"#,
            #"/AA\b"#,
            #"/RichMedia\b"#,
            #"/EmbeddedFile\b"#,
            #"/XFA\b"#,
            #"/SubmitForm\b"#,
            #"/ImportData\b"#
        ]
        if forbiddenMarkerPatterns.contains(where: { rawString.containsRegularExpression($0) }) {
            throw DocumentImportError.unsupportedPDFActiveContent
        }

        let objectCount = rawString.numberOfMatches(for: #"\n\d+\s+\d+\s+obj\b"#)
        guard objectCount <= options.maxObjects else {
            throw DocumentImportError.pdfObjectLimitExceeded(maxObjects: options.maxObjects)
        }

        let streamCount = rawString.numberOfMatches(for: #"\bstream\b"#)
        guard streamCount <= options.maxStreams else {
            throw DocumentImportError.pdfStreamLimitExceeded(maxStreams: options.maxStreams)
        }
    }

    private func splitSegments(from pageText: String) -> [String] {
        let normalized = pageText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let paragraphSplit = normalized
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if paragraphSplit.count > 1 {
            return paragraphSplit
        }

        return normalized
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
#else
import Foundation

public struct PDFDocumentImporter: Sendable {
    public init(options: PDFImportOptions = PDFImportOptions()) {
        _ = options
    }

    public func `import`(data: Data) throws -> CanonicalDocument {
        _ = data
        throw DocumentImportError.unavailablePDFRuntime
    }
}

public struct PDFImportOptions: Sendable {
    public let maxPages: Int
    public let maxPageCharacters: Int
    public let maxObjects: Int
    public let maxStreams: Int

    public init(
        maxPages: Int = 1500,
        maxPageCharacters: Int = 100_000,
        maxObjects: Int = 20_000,
        maxStreams: Int = 5_000
    ) {
        self.maxPages = maxPages
        self.maxPageCharacters = maxPageCharacters
        self.maxObjects = maxObjects
        self.maxStreams = maxStreams
    }
}
#endif

private extension String {
    func numberOfMatches(for pattern: String) -> Int {
        guard let expression = try? NSRegularExpression(pattern: pattern) else {
            return 0
        }
        let range = NSRange(startIndex..<endIndex, in: self)
        return expression.numberOfMatches(in: self, options: [], range: range)
    }

    func containsRegularExpression(_ pattern: String) -> Bool {
        numberOfMatches(for: pattern) > 0
    }
}
