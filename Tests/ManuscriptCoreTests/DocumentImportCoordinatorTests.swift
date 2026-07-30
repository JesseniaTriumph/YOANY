import Foundation
import Testing
@testable import ManuscriptCore

struct DocumentImportCoordinatorTests {
    @Test func importsPlainTextThroughCoordinator() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let sourceURL = directory.appendingPathComponent("draft.txt")
        try Data("Titre:\n\nBonjour.".utf8).write(to: sourceURL)

        let coordinator = try DocumentImportCoordinator(
            quarantine: ImportQuarantine(rootURL: directory.appendingPathComponent("quarantine"))
        )

        let result = try coordinator.import(request: DocumentImportRequest(sourceURL: sourceURL))
        #expect(result.format == .plainText)
        #expect(result.document.pages.first?.segments.count == 2)

        coordinator.cleanup(result: result)
        #expect(!FileManager.default.fileExists(atPath: result.quarantineURL.path))
    }

    @Test func rejectsUnsupportedBinaryInput() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let sourceURL = directory.appendingPathComponent("binary.bin")
        try Data([0x00, 0xFF, 0x10, 0x80]).write(to: sourceURL)

        let coordinator = try DocumentImportCoordinator(
            quarantine: ImportQuarantine(rootURL: directory.appendingPathComponent("quarantine"))
        )

        #expect(throws: DocumentImportError.unsupportedFormat) {
            _ = try coordinator.import(request: DocumentImportRequest(sourceURL: sourceURL))
        }
    }

    @Test func importsDocxThroughCoordinator() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let sourceURL = directory.appendingPathComponent("draft.docx")
        let xml = """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
          <w:body>
            <w:p><w:r><w:t>Bonjour.</w:t></w:r></w:p>
          </w:body>
        </w:document>
        """
        let payload = Data(xml.utf8)
        let archive = try SimpleStoredZIPBuilder.buildSingleEntryArchive(
            path: "word/document.xml",
            payload: payload
        )
        try archive.write(to: sourceURL)

        let coordinator = try DocumentImportCoordinator(
            quarantine: ImportQuarantine(rootURL: directory.appendingPathComponent("quarantine"))
        )

        let result = try coordinator.import(request: DocumentImportRequest(sourceURL: sourceURL))
        #expect(result.format == .docx)
        #expect(result.document.pages.first?.segments.first?.text == "Bonjour.")
    }
}
