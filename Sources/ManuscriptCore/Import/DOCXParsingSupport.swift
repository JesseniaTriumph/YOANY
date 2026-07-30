import Foundation

public enum DOCXImportError: Error, Equatable, Sendable {
    case invalidZipArchive
    case missingDocumentXML
    case unsupportedStructure
    case malformedXML
    case entryLimitExceeded
}

struct DOCXArchiveEntry: Sendable, Equatable {
    let path: String
    let compressionMethod: UInt16
    let compressedSize: UInt32
    let uncompressedSize: UInt32
    let dataOffset: Int
}

struct DOCXArchiveReader {
    private let data: Data
    private let maxEntries: Int

    init(data: Data, maxEntries: Int = 2000) {
        self.data = data
        self.maxEntries = maxEntries
    }

    func entries() throws -> [DOCXArchiveEntry] {
        try readEntries()
    }

    func extractEntry(named name: String) throws -> Data {
        let entries = try readEntries()
        guard let entry = entries.first(where: { $0.path == name }) else {
            throw DOCXImportError.missingDocumentXML
        }
        return try extract(entry: entry)
    }

    private func readEntries() throws -> [DOCXArchiveEntry] {
        guard data.count >= 4 else {
            throw DOCXImportError.invalidZipArchive
        }

        var entries: [DOCXArchiveEntry] = []
        var offset = 0

        while offset + 4 <= data.count {
            let signature = data.readUInt32LE(at: offset)
            if signature != 0x04034B50 {
                break
            }

            guard entries.count < maxEntries else {
                throw DOCXImportError.entryLimitExceeded
            }

            let compressionMethod = data.readUInt16LE(at: offset + 8)
            let compressedSize = data.readUInt32LE(at: offset + 18)
            let uncompressedSize = data.readUInt32LE(at: offset + 22)
            let fileNameLength = Int(data.readUInt16LE(at: offset + 26))
            let extraLength = Int(data.readUInt16LE(at: offset + 28))
            let nameStart = offset + 30
            let nameEnd = nameStart + fileNameLength
            let extraEnd = nameEnd + extraLength
            guard extraEnd <= data.count else {
                throw DOCXImportError.invalidZipArchive
            }
            let pathData = data.subdata(in: nameStart..<nameEnd)
            guard let path = String(data: pathData, encoding: .utf8) else {
                throw DOCXImportError.invalidZipArchive
            }
            guard isSafePath(path) else {
                throw DOCXImportError.unsupportedStructure
            }

            let entry = DOCXArchiveEntry(
                path: path,
                compressionMethod: compressionMethod,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                dataOffset: extraEnd
            )
            entries.append(entry)

            let nextOffset = extraEnd + Int(compressedSize)
            guard nextOffset <= data.count else {
                throw DOCXImportError.invalidZipArchive
            }
            offset = nextOffset

            if compressionMethod != 0 {
                throw DOCXImportError.unsupportedStructure
            }
        }

        return entries
    }

    private func extract(entry: DOCXArchiveEntry) throws -> Data {
        let payloadEnd = entry.dataOffset + Int(entry.compressedSize)
        guard payloadEnd <= data.count else {
            throw DOCXImportError.invalidZipArchive
        }
        let payload = data.subdata(in: entry.dataOffset..<payloadEnd)

        guard entry.compressionMethod == 0 else {
            throw DOCXImportError.unsupportedStructure
        }
        return payload
    }

    private func isSafePath(_ path: String) -> Bool {
        if path.isEmpty || path.hasPrefix("/") || path.contains("\\") || path.contains(":") {
            return false
        }

        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        return !components.contains(where: { $0 == "." || $0 == ".." || $0.isEmpty })
    }
}

final class DOCXDocumentXMLParser: NSObject, XMLParserDelegate {
    private(set) var paragraphs: [String] = []
    private var currentParagraphParts: [String] = []
    private var currentText: String = ""
    private var insideTextNode = false

    func parse(data: Data) throws -> [String] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw DOCXImportError.malformedXML
        }

        flushParagraphIfNeeded()
        return paragraphs
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        _ = parser
        _ = namespaceURI
        _ = qName
        _ = attributeDict

        switch elementName {
        case "w:p":
            currentParagraphParts.removeAll(keepingCapacity: true)
        case "w:t":
            insideTextNode = true
            currentText = ""
        case "w:tab":
            currentParagraphParts.append("\t")
        case "w:br":
            currentParagraphParts.append("\n")
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        _ = parser
        guard insideTextNode else { return }
        currentText.append(string)
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        _ = parser
        _ = namespaceURI
        _ = qName

        switch elementName {
        case "w:t":
            insideTextNode = false
            currentParagraphParts.append(currentText)
            currentText = ""
        case "w:p":
            flushParagraphIfNeeded()
        default:
            break
        }
    }

    private func flushParagraphIfNeeded() {
        let paragraph = currentParagraphParts.joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !paragraph.isEmpty {
            paragraphs.append(paragraph)
        }
        currentParagraphParts.removeAll(keepingCapacity: true)
    }
}

final class DOCXRelationshipsParser: NSObject, XMLParserDelegate {
    private var foundExternalTarget = false

    func parse(data: Data) throws -> Bool {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw DOCXImportError.malformedXML
        }
        return foundExternalTarget
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        _ = parser
        _ = namespaceURI
        _ = qName

        guard elementName == "Relationship" || elementName.hasSuffix(":Relationship") else {
            return
        }

        if attributeDict.first(where: {
            $0.key.caseInsensitiveCompare("TargetMode") == .orderedSame &&
            $0.value.caseInsensitiveCompare("External") == .orderedSame
        }) != nil {
            foundExternalTarget = true
        }
    }
}

private extension Data {
    func readUInt16LE(at offset: Int) -> UInt16 {
        let lower = UInt16(self[offset])
        let upper = UInt16(self[offset + 1]) << 8
        return lower | upper
    }

    func readUInt32LE(at offset: Int) -> UInt32 {
        let b0 = UInt32(self[offset])
        let b1 = UInt32(self[offset + 1]) << 8
        let b2 = UInt32(self[offset + 2]) << 16
        let b3 = UInt32(self[offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }
}
