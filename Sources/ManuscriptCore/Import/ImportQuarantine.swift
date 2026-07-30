import Foundation

public struct ImportQuarantine: Sendable {
    private let rootURL: URL

    public init(rootURL: URL) throws {
        self.rootURL = rootURL
        try FileManager.default.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }

    public func stage(request: DocumentImportRequest) throws -> URL {
        let stagedURL = rootURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("import")
        try FileManager.default.copyItem(at: request.sourceURL, to: stagedURL)
        return stagedURL
    }

    public func cleanup(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
