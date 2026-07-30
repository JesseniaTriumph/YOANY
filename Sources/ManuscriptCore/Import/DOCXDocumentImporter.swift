import Foundation

public struct DOCXDocumentImporter: Sendable {
    public init() {}

    public func `import`(data: Data) throws -> CanonicalDocument {
        let archive = DOCXArchiveReader(data: data)
        let entries = try archive.entries()
        try validate(entries: entries, archive: archive)
        let documentXML = try archive.extractEntry(named: "word/document.xml")
        let parser = DOCXDocumentXMLParser()
        let paragraphs = try parser.parse(data: documentXML)

        let pageID = PageID.make()
        var warnings: [DocumentWarning] = []
        if paragraphs.isEmpty {
            warnings.append(
                DocumentWarning(
                    code: .emptyDocument,
                    message: "DOCX contained no importable paragraph text."
                )
            )
        }

        let segments = paragraphs.enumerated().map { index, text in
            DocumentSegment(
                pageID: pageID,
                orderIndex: index,
                kind: inferKind(from: text),
                text: text,
                sourceRange: SourceRangeReference(pageIndex: 0, segmentIndex: index)
            )
        }

        return CanonicalDocument(
            format: .docx,
            contentHash: CanonicalDocument.sha256Hex(for: data),
            pages: [
                DocumentPage(
                    id: pageID,
                    pageIndex: 0,
                    sourceLabel: "Document",
                    segments: segments
                )
            ],
            warnings: warnings
        )
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

    private func validate(entries: [DOCXArchiveEntry], archive: DOCXArchiveReader) throws {
        let forbiddenEntryMarkers = [
            "word/vbaproject",
            "word/embeddings/",
            "word/activex/",
            "word/oleobject",
            "word/package",
        ]
        let forbiddenExtensions = [
            ".exe", ".dll", ".js", ".jse", ".vbs", ".vbe", ".bat", ".cmd", ".com", ".ps1", ".sh", ".app"
        ]

        for entry in entries {
            let lowercasedPath = entry.path.lowercased()
            if forbiddenEntryMarkers.contains(where: { lowercasedPath.hasPrefix($0) }) {
                throw DOCXImportError.unsupportedStructure
            }
            if forbiddenExtensions.contains(where: { lowercasedPath.hasSuffix($0) }) {
                throw DOCXImportError.unsupportedStructure
            }
            if lowercasedPath.hasSuffix(".rels") {
                let relationshipsXML = try archive.extractEntry(named: entry.path)
                let containsExternalTargets = try DOCXRelationshipsParser().parse(data: relationshipsXML)
                if containsExternalTargets {
                    throw DOCXImportError.unsupportedStructure
                }
            }
        }
    }
}
