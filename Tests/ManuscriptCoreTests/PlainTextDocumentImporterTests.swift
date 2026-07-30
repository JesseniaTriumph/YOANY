import Foundation
import Testing
@testable import ManuscriptCore

struct PlainTextDocumentImporterTests {
    @Test func importsSinglePageTextIntoParagraphSegments() throws {
        let importer = PlainTextDocumentImporter()
        let document = try importer.import(text: "Titre:\n\nPremier paragraphe.\n\nDeuxieme paragraphe.")

        #expect(document.format == .plainText)
        #expect(document.pages.count == 1)
        #expect(document.pages[0].segments.count == 3)
        #expect(document.pages[0].segments[0].kind == .heading)
        #expect(document.pages[0].segments[1].text == "Premier paragraphe.")
    }

    @Test func preservesPageBoundariesUsingFormFeed() throws {
        let importer = PlainTextDocumentImporter()
        let document = try importer.import(text: "Page un.\u{000C}Page deux.")

        #expect(document.pages.count == 2)
        #expect(document.pages[0].pageIndex == 0)
        #expect(document.pages[1].pageIndex == 1)
        #expect(document.pages[1].segments.first?.text == "Page deux.")
    }

    @Test func rejectsNonUtf8Input() async throws {
        let importer = PlainTextDocumentImporter()
        let bytes = Data([0xFF, 0xFE, 0x00, 0x00])

        #expect(throws: DocumentImportError.unsupportedEncoding) {
            try importer.import(data: bytes)
        }
    }

    @Test func flagsOversizedSegments() throws {
        let importer = PlainTextDocumentImporter(options: PlainTextImportOptions(maxBytes: 500_000, maxSegmentCharacters: 10))
        let document = try importer.import(text: "Un segment franchement trop long.")

        #expect(document.warnings.contains(where: { $0.code == .oversizedSegment }))
    }
}
