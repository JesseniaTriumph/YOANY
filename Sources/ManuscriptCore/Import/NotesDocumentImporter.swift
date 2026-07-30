import Foundation

public struct NotesDocumentImporter: Sendable {
    private let textImporter: PlainTextDocumentImporter

    public init(textImporter: PlainTextDocumentImporter = PlainTextDocumentImporter()) {
        self.textImporter = textImporter
    }

    public func `import`(noteText: String) throws -> CanonicalDocument {
        try textImporter.import(text: noteText)
    }
}
