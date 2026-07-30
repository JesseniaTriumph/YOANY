import CryptoKit
import Foundation

public struct WrappedKey: Codable, Sendable, Equatable {
    public let bytes: Data

    public init(bytes: Data) {
        self.bytes = bytes
    }
}

public protocol KeyWrapping: Sendable {
    func wrap(projectID: ProjectID, key: SymmetricKey) throws -> WrappedKey
    func unwrap(projectID: ProjectID, wrappedKey: WrappedKey) throws -> SymmetricKey
    func remove(projectID: ProjectID) throws
}

public protocol EncryptionService: Sendable {
    func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> Data
    func decrypt(_ ciphertext: Data, using key: SymmetricKey) throws -> Data
    func digestHex(_ data: Data) -> String
}

public final class InMemoryKeyWrappingService: ArchiveRestorableKeyWrapping, @unchecked Sendable {
    private let lock = NSLock()
    private var wrappedKeys: [ProjectID: Data] = [:]

    public init() {}

    public func wrap(projectID: ProjectID, key: SymmetricKey) throws -> WrappedKey {
        let raw = key.withUnsafeBytes { Data($0) }
        lock.lock()
        wrappedKeys[projectID] = raw
        lock.unlock()
        return WrappedKey(bytes: raw)
    }

    public func unwrap(projectID: ProjectID, wrappedKey: WrappedKey) throws -> SymmetricKey {
        lock.lock()
        defer { lock.unlock() }
        guard let stored = wrappedKeys[projectID], stored == wrappedKey.bytes else {
            throw SecurityError.keyUnavailable(projectID)
        }
        return SymmetricKey(data: stored)
    }

    public func remove(projectID: ProjectID) throws {
        lock.lock()
        wrappedKeys.removeValue(forKey: projectID)
        lock.unlock()
    }

    public func importWrappedKey(projectID: ProjectID, wrappedKey: WrappedKey) throws {
        lock.lock()
        wrappedKeys[projectID] = wrappedKey.bytes
        lock.unlock()
    }
}

public struct AESGCMEncryptionService: EncryptionService {
    public init() {}

    public func encrypt(_ plaintext: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        guard let combined = sealed.combined else {
            throw CocoaError(.coderInvalidValue)
        }
        return combined
    }

    public func decrypt(_ ciphertext: Data, using key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealed, using: key)
    }

    public func digestHex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
