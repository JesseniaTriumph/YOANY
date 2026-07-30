import Foundation

public struct FileFormatDetector: Sendable {
    public init() {}

    public func detect(data: Data, filename: String) throws -> SourceDocumentFormat {
        if isPDF(data: data) {
            return .pdf
        }
        if isDOCX(data: data, filename: filename) {
            return .docx
        }
        if isProbablyUTF8Text(data: data) {
            return .plainText
        }
        throw DocumentImportError.unsupportedFormat
    }

    private func isPDF(data: Data) -> Bool {
        data.starts(with: Data("%PDF".utf8))
    }

    private func isDOCX(data: Data, filename: String) -> Bool {
        let lower = filename.lowercased()
        return lower.hasSuffix(".docx") && data.starts(with: Data([0x50, 0x4B, 0x03, 0x04]))
    }

    private func isProbablyUTF8Text(data: Data) -> Bool {
        String(data: data, encoding: .utf8) != nil
    }
}
