import Foundation

public struct DocumentImportCoordinator: Sendable {
    private let validationOptions: ImportValidationOptions
    private let quarantine: ImportQuarantine
    private let detector: FileFormatDetector
    private let textImporter: PlainTextDocumentImporter
    private let docxImporter: DOCXDocumentImporter
    private let pdfImporter: PDFDocumentImporter

    public init(
        validationOptions: ImportValidationOptions = ImportValidationOptions(),
        quarantine: ImportQuarantine,
        detector: FileFormatDetector = FileFormatDetector(),
        textImporter: PlainTextDocumentImporter = PlainTextDocumentImporter(),
        docxImporter: DOCXDocumentImporter = DOCXDocumentImporter(),
        pdfImporter: PDFDocumentImporter = PDFDocumentImporter()
    ) {
        self.validationOptions = validationOptions
        self.quarantine = quarantine
        self.detector = detector
        self.textImporter = textImporter
        self.docxImporter = docxImporter
        self.pdfImporter = pdfImporter
    }

    public func `import`(request: DocumentImportRequest) throws -> DocumentImportResult {
        let stagedURL = try quarantine.stage(request: request)
        do {
            let data = try Data(contentsOf: stagedURL)
            guard data.count <= validationOptions.maxBytes else {
                throw DocumentImportError.fileTooLarge(maxBytes: validationOptions.maxBytes)
            }
            let format = try detector.detect(data: data, filename: request.preferredFilename)
            let document = try parse(data: data, as: format)
            return DocumentImportResult(format: format, document: document, quarantineURL: stagedURL)
        } catch {
            quarantine.cleanup(url: stagedURL)
            throw error
        }
    }

    public func cleanup(result: DocumentImportResult) {
        quarantine.cleanup(url: result.quarantineURL)
    }

    private func parse(data: Data, as format: SourceDocumentFormat) throws -> CanonicalDocument {
        switch format {
        case .plainText:
            return try textImporter.import(data: data)
        case .docx:
            return try docxImporter.import(data: data)
        case .pdf:
            return try pdfImporter.import(data: data)
        }
    }
}
