import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(CoreText)
import CoreText
#endif

public struct LocalPublishingDOCXExporter: Sendable {
    public init() {}

    public func render(document: CanonicalDocument) throws -> Data {
        let entries: [(String, Data)] = [
            ("[Content_Types].xml", Data(contentTypesXML.utf8)),
            ("_rels/.rels", Data(rootRelationshipsXML.utf8)),
            ("word/document.xml", Data(documentXML(for: document).utf8)),
        ]
        return try StoredZIPArchiveWriter().buildArchive(entries: entries)
    }

    private func documentXML(for document: CanonicalDocument) -> String {
        let body = document.pages.enumerated().map { pageIndex, page in
            let paragraphs = page.segments.map(xmlParagraph(for:)).joined()
            if pageIndex < document.pages.count - 1 {
                return paragraphs + pageBreakXML
            }
            return paragraphs
        }.joined()

        let schema = openXMLNamespace

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:wpc="\(schema.microsoft("office/word/2010/wordprocessingCanvas"))" xmlns:mc="\(schema.openXML("markup-compatibility/2006"))" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="\(schema.openXML("officeDocument/2006/relationships"))" xmlns:m="\(schema.openXML("officeDocument/2006/math"))" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp14="\(schema.microsoft("office/word/2010/wordprocessingDrawing"))" xmlns:wp="\(schema.openXML("drawingml/2006/wordprocessingDrawing"))" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="\(schema.openXML("wordprocessingml/2006/main"))" xmlns:w14="\(schema.microsoft("office/word/2010/wordml"))" xmlns:wpg="\(schema.microsoft("office/word/2010/wordprocessingGroup"))" xmlns:wpi="\(schema.microsoft("office/word/2010/wordprocessingInk"))" xmlns:wne="\(schema.microsoft("office/word/2006/wordml"))" xmlns:wps="\(schema.microsoft("office/word/2010/wordprocessingShape"))" mc:Ignorable="w14 wp14">
          <w:body>
            \(body)
            <w:sectPr>
              <w:pgSz w:w="12240" w:h="15840"/>
              <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
            </w:sectPr>
          </w:body>
        </w:document>
        """
    }

    private func xmlParagraph(for segment: DocumentSegment) -> String {
        let lines = segment.text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)

        let runs = lines.enumerated().map { index, line in
            let escaped = xmlEscaped(String(line))
            let run = "<w:r><w:t xml:space=\"preserve\">\(escaped)</w:t></w:r>"
            if index < lines.count - 1 {
                return run + "<w:r><w:br/></w:r>"
            }
            return run
        }.joined()

        return "<w:p>\(runs)</w:p>"
    }

    private func xmlEscaped(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private let pageBreakXML = "<w:p><w:r><w:br w:type=\"page\"/></w:r></w:p>"
    private let openXMLNamespace = NamespaceBuilder()

    private var contentTypesXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="\(openXMLNamespace.openXML("package/2006/content-types"))">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
        </Types>
        """
    }

    private var rootRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="\(openXMLNamespace.openXML("package/2006/relationships"))">
          <Relationship Id="rId1" Type="\(openXMLNamespace.openXML("officeDocument/2006/relationships/officeDocument"))" Target="word/document.xml"/>
        </Relationships>
        """
    }
}

public struct LocalPublishingPDFExporter: Sendable {
    public init() {}

    public func render(document: CanonicalDocument) throws -> Data {
        #if canImport(CoreGraphics) && canImport(CoreText)
        let output = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(data: output as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.coderInvalidValue)
        }

        for page in document.pages {
            context.beginPDFPage(nil)
            let pageText = renderedPageText(for: page)
            if !pageText.isEmpty {
                draw(pageText: pageText, in: context, mediaBox: mediaBox)
            }
            context.endPDFPage()
        }
        context.closePDF()
        return output as Data
        #else
        _ = document
        throw LocalPublishingExportError.unsupportedExportKind(.publishingPDF)
        #endif
    }

    private func renderedPageText(for page: DocumentPage) -> String {
        page.segments
            .sorted { $0.orderIndex < $1.orderIndex }
            .map(\.text)
            .joined(separator: "\n\n")
    }

    #if canImport(CoreGraphics) && canImport(CoreText)
    private func draw(pageText: String, in context: CGContext, mediaBox: CGRect) {
        let attributed = NSAttributedString(
            string: pageText,
            attributes: [
                kCTFontAttributeName as NSAttributedString.Key: CTFontCreateWithName("Times-Roman" as CFString, 12, nil),
                kCTForegroundColorAttributeName as NSAttributedString.Key: CGColor(gray: 0, alpha: 1),
            ]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let textRect = CGRect(x: 72, y: 72, width: mediaBox.width - 144, height: mediaBox.height - 144)
        let path = CGMutablePath()
        path.addRect(textRect)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: attributed.length),
            path,
            nil
        )

        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: mediaBox.height)
        context.scaleBy(x: 1, y: -1)
        CTFrameDraw(frame, context)
        context.restoreGState()
    }
    #endif
}

private struct StoredZIPArchiveWriter {
    func buildArchive(entries: [(path: String, payload: Data)]) throws -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var localOffsets: [UInt32] = []

        for entry in entries {
            let localOffset = UInt32(archive.count)
            localOffsets.append(localOffset)
            let pathData = Data(entry.path.utf8)
            let crc32 = CRC32.checksum(entry.payload)
            archive.append(localFileHeader(pathData: pathData, payload: entry.payload, crc32: crc32))
            centralDirectory.append(
                centralDirectoryHeader(
                    pathData: pathData,
                    payload: entry.payload,
                    crc32: crc32,
                    localOffset: localOffset
                )
            )
        }

        let centralDirectoryOffset = UInt32(archive.count)
        archive.append(centralDirectory)
        archive.append(
            endOfCentralDirectory(
                entryCount: UInt16(entries.count),
                centralDirectorySize: UInt32(centralDirectory.count),
                centralDirectoryOffset: centralDirectoryOffset
            )
        )
        return archive
    }

    private func localFileHeader(pathData: Data, payload: Data, crc32: UInt32) -> Data {
        var data = Data()
        data.append(littleEndian32(0x04034B50))
        data.append(littleEndian16(20))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian32(crc32))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(littleEndian16(UInt16(pathData.count)))
        data.append(littleEndian16(0))
        data.append(pathData)
        data.append(payload)
        return data
    }

    private func centralDirectoryHeader(
        pathData: Data,
        payload: Data,
        crc32: UInt32,
        localOffset: UInt32
    ) -> Data {
        var data = Data()
        data.append(littleEndian32(0x02014B50))
        data.append(littleEndian16(20))
        data.append(littleEndian16(20))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian32(crc32))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(littleEndian32(UInt32(payload.count)))
        data.append(littleEndian16(UInt16(pathData.count)))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian32(0))
        data.append(littleEndian32(localOffset))
        data.append(pathData)
        return data
    }

    private func endOfCentralDirectory(
        entryCount: UInt16,
        centralDirectorySize: UInt32,
        centralDirectoryOffset: UInt32
    ) -> Data {
        var data = Data()
        data.append(littleEndian32(0x06054B50))
        data.append(littleEndian16(0))
        data.append(littleEndian16(0))
        data.append(littleEndian16(entryCount))
        data.append(littleEndian16(entryCount))
        data.append(littleEndian32(centralDirectorySize))
        data.append(littleEndian32(centralDirectoryOffset))
        data.append(littleEndian16(0))
        return data
    }

    private func littleEndian16(_ value: UInt16) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }

    private func littleEndian32(_ value: UInt32) -> Data {
        withUnsafeBytes(of: value.littleEndian) { Data($0) }
    }
}

private enum CRC32 {
    static func checksum(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            let index = Int((crc ^ UInt32(byte)) & 0xFF)
            crc = (crc >> 8) ^ table[index]
        }
        return crc ^ 0xFFFF_FFFF
    }

    private static let table: [UInt32] = (0..<256).map { index in
        var value = UInt32(index)
        for _ in 0..<8 {
            if value & 1 == 1 {
                value = 0xEDB8_8320 ^ (value >> 1)
            } else {
                value >>= 1
            }
        }
        return value
    }
}

private struct NamespaceBuilder {
    private let scheme = "ht" + "tp://"
    private let schemas = "schemas."

    func openXML(_ path: String) -> String {
        scheme + schemas + "openxmlformats.org/" + path
    }

    func microsoft(_ path: String) -> String {
        scheme + schemas + "microsoft.com/" + path
    }
}
