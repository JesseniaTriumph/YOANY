import Foundation

public enum DocumentImportError: Error, Equatable, Sendable {
    case unsupportedEncoding
    case emptyInput
    case fileTooLarge(maxBytes: Int)
    case unsupportedFormat
    case unsupportedInCurrentBuild(SourceDocumentFormat)
    case malformedPDF
    case unsupportedPDFActiveContent
    case pdfObjectLimitExceeded(maxObjects: Int)
    case pdfStreamLimitExceeded(maxStreams: Int)
    case missingTrustedTextLayer
    case unavailablePDFRuntime
    case encryptedPDFUnsupported
    case pdfPageLimitExceeded(maxPages: Int)
    case oversizedPDFPage(pageIndex: Int, maxCharacters: Int)
}
