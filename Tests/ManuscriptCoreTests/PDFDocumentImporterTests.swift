#if canImport(PDFKit) && canImport(AppKit)
import AppKit
import Foundation
import PDFKit
import Testing
@testable import ManuscriptCore

struct PDFDocumentImporterTests {
    @Test func importsSimpleTextPDF() throws {
        let pdfData = try SimplePDFBuilder.makeTextPDF(pages: ["Titre:\n\nBonjour le monde."])
        let document = try PDFDocumentImporter().import(data: pdfData)

        #expect(document.format == .pdf)
        #expect(document.pages.count == 1)
        #expect(document.pages[0].segments.first?.kind == .heading)
    }

    @Test func rejectsImageOnlyPDFWithoutTextLayer() throws {
        let pdf = PDFDocument()
        let image = NSImage(size: NSSize(width: 200, height: 200))
        image.lockFocus()
        NSColor.white.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: 200, height: 200)).fill()
        image.unlockFocus()
        let page = PDFPage(image: image)
        pdf.insert(page!, at: 0)
        let data = try #require(pdf.dataRepresentation())

        #expect(throws: DocumentImportError.missingTrustedTextLayer) {
            _ = try PDFDocumentImporter().import(data: data)
        }
    }

    @Test func rejectsPDFWithActiveContentMarker() throws {
        var pdfData = try SimplePDFBuilder.makeTextPDF(pages: ["Bonjour."])
        pdfData.append(Data("\n/JavaScript".utf8))

        #expect(throws: DocumentImportError.unsupportedPDFActiveContent) {
            _ = try PDFDocumentImporter().import(data: pdfData)
        }
    }

    @Test func rejectsPDFWithoutEOFMarker() throws {
        let pdfData = Data("%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>\n".utf8)

        #expect(throws: DocumentImportError.malformedPDF) {
            _ = try PDFDocumentImporter().import(data: pdfData)
        }
    }

    @Test func rejectsPDFThatExceedsObjectLimit() throws {
        let repeatedObjects = (0..<5).map { index in
            "\(index) 0 obj\n<< /Type /Test >>\nendobj\n"
        }.joined()
        let pdfData = Data("%PDF-1.7\n\(repeatedObjects)%%EOF".utf8)
        let importer = PDFDocumentImporter(
            options: PDFImportOptions(maxPages: 1500, maxPageCharacters: 100_000, maxObjects: 3, maxStreams: 5_000)
        )

        #expect(throws: DocumentImportError.pdfObjectLimitExceeded(maxObjects: 3)) {
            _ = try importer.import(data: pdfData)
        }
    }

    @Test func rejectsPDFThatExceedsStreamLimit() throws {
        let repeatedStreams = (0..<4).map { _ in
            "1 0 obj\n<< /Length 1 >>\nstream\nA\nendstream\nendobj\n"
        }.joined()
        let pdfData = Data("%PDF-1.7\n\(repeatedStreams)%%EOF".utf8)
        let importer = PDFDocumentImporter(
            options: PDFImportOptions(maxPages: 1500, maxPageCharacters: 100_000, maxObjects: 20_000, maxStreams: 2)
        )

        #expect(throws: DocumentImportError.pdfStreamLimitExceeded(maxStreams: 2)) {
            _ = try importer.import(data: pdfData)
        }
    }
}

private enum SimplePDFBuilder {
    static func makeTextPDF(pages: [String]) throws -> Data {
        let output = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let consumer = CGDataConsumer(data: output as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.coderInvalidValue)
        }

        for text in pages {
            context.beginPDFPage(nil)
            let ns = NSAttributedString(
                string: text,
                attributes: [
                    .font: NSFont.systemFont(ofSize: 16),
                    .foregroundColor: NSColor.black
                ]
            )
            let frame = NSRect(x: 72, y: 72, width: 468, height: 648)
            NSGraphicsContext.saveGraphicsState()
            let graphics = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = graphics
            ns.draw(in: frame)
            NSGraphicsContext.restoreGraphicsState()
            context.endPDFPage()
        }
        context.closePDF()
        return output as Data
    }
}
#endif
