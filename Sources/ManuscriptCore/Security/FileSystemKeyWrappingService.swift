import CryptoKit
import Foundation

public final class FileSystemKeyWrappingService: ArchiveRestorableKeyWrapping, @unchecked Sendable {
    private let rootURL: URL
    private let fileManager: FileManager

    public init(
        rootURL: URL,
        fileManager: FileManager = .default
    ) throws {
        self.rootURL = rootURL
        self.fileManager = fileManager

        try fileManager.createDirectory(
            at: rootURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
    }

    public func wrap(projectID: ProjectID, key: SymmetricKey) throws -> WrappedKey {
        let raw = key.withUnsafeBytes { Data($0) }
        try store(raw, projectID: projectID)
        return WrappedKey(bytes: raw)
    }

    public func unwrap(projectID: ProjectID, wrappedKey: WrappedKey) throws -> SymmetricKey {
        let stored = try load(projectID: projectID)
        guard stored == wrappedKey.bytes else {
            throw SecurityError.keyUnavailable(projectID)
        }
        return SymmetricKey(data: stored)
    }

    public func remove(projectID: ProjectID) throws {
        let url = fileURL(for: projectID)
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        try fileManager.removeItem(at: url)
    }

    public func importWrappedKey(projectID: ProjectID, wrappedKey: WrappedKey) throws {
        try store(wrappedKey.bytes, projectID: projectID)
    }

    private func store(_ data: Data, projectID: ProjectID) throws {
        let url = fileURL(for: projectID)
        try data.write(to: url, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func load(projectID: ProjectID) throws -> Data {
        let url = fileURL(for: projectID)
        guard fileManager.fileExists(atPath: url.path) else {
            throw SecurityError.keyUnavailable(projectID)
        }
        return try Data(contentsOf: url)
    }

    private func fileURL(for projectID: ProjectID) -> URL {
        rootURL.appendingPathComponent(projectID.rawValue).appendingPathExtension("key")
    }
}
