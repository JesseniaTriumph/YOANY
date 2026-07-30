import Foundation
import Testing
@testable import ManuscriptCore

struct DOCXDocumentImporterTests {
    private let minimalDocumentXML = """
    <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
      <w:body>
        <w:p><w:r><w:t>Titre:</w:t></w:r></w:p>
        <w:p><w:r><w:t>Bonjour le monde.</w:t></w:r></w:p>
      </w:body>
    </w:document>
    """

    @Test func importsSimpleDocumentXMLFromDocxArchive() throws {
        let docxData = try SimpleStoredZIPBuilder.buildSingleEntryArchive(
            path: "word/document.xml",
            payload: Data(minimalDocumentXML.utf8)
        )

        let document = try DOCXDocumentImporter().import(data: docxData)

        #expect(document.format == .docx)
        #expect(document.pages.count == 1)
        #expect(document.pages[0].segments.count == 2)
        #expect(document.pages[0].segments[0].kind == .heading)
        #expect(document.pages[0].segments[1].text == "Bonjour le monde.")
    }

    @Test func rejectsArchiveWithoutDocumentXML() throws {
        let archive = try SimpleStoredZIPBuilder.buildSingleEntryArchive(
            path: "word/other.xml",
            payload: Data("noop".utf8)
        )

        #expect(throws: DOCXImportError.missingDocumentXML) {
            _ = try DOCXDocumentImporter().import(data: archive)
        }
    }

    @Test func rejectsArchiveContainingMacroProject() throws {
        let archive = try SimpleStoredZIPBuilder.buildArchive(
            entries: [
                ("word/document.xml", Data(minimalDocumentXML.utf8)),
                ("word/vbaProject.bin", Data([0x00, 0x01, 0x02])),
            ]
        )

        #expect(throws: DOCXImportError.unsupportedStructure) {
            _ = try DOCXDocumentImporter().import(data: archive)
        }
    }

    @Test func rejectsArchiveContainingEmbeddedPayload() throws {
        let archive = try SimpleStoredZIPBuilder.buildArchive(
            entries: [
                ("word/document.xml", Data(minimalDocumentXML.utf8)),
                ("word/embeddings/oleObject1.bin", Data([0x10, 0x20])),
            ]
        )

        #expect(throws: DOCXImportError.unsupportedStructure) {
            _ = try DOCXDocumentImporter().import(data: archive)
        }
    }

    @Test func rejectsExternalRelationships() throws {
        let relationshipsXML = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship
            Id="rId1"
            Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/attachedTemplate"
            Target="https://example.invalid/template.dotm"
            TargetMode="External"/>
        </Relationships>
        """
        let archive = try SimpleStoredZIPBuilder.buildArchive(
            entries: [
                ("word/document.xml", Data(minimalDocumentXML.utf8)),
                ("word/_rels/document.xml.rels", Data(relationshipsXML.utf8)),
            ]
        )

        #expect(throws: DOCXImportError.unsupportedStructure) {
            _ = try DOCXDocumentImporter().import(data: archive)
        }
    }

    @Test func rejectsPathTraversalEntry() throws {
        let archive = try SimpleStoredZIPBuilder.buildArchive(
            entries: [
                ("../word/document.xml", Data(minimalDocumentXML.utf8)),
            ]
        )

        #expect(throws: DOCXImportError.unsupportedStructure) {
            _ = try DOCXDocumentImporter().import(data: archive)
        }
    }
}
