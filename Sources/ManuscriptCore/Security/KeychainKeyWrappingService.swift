import CryptoKit
import Foundation
#if canImport(Security)
import Security

public final class KeychainKeyWrappingService: ArchiveRestorableKeyWrapping, @unchecked Sendable {
    private let serviceName: String
    private let accessGroup: String?

    public init(
        serviceName: String = "com.openai.YoanTranslator.vault",
        accessGroup: String? = nil
    ) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
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
        let status = SecItemDelete(baseQuery(projectID: projectID) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityError.keyUnavailable(projectID)
        }
    }

    public func importWrappedKey(projectID: ProjectID, wrappedKey: WrappedKey) throws {
        try store(wrappedKey.bytes, projectID: projectID)
    }

    private func store(_ data: Data, projectID: ProjectID) throws {
        var addQuery = baseQuery(projectID: projectID)
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let deleteStatus = SecItemDelete(baseQuery(projectID: projectID) as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw SecurityError.keyUnavailable(projectID)
        }

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keyUnavailable(projectID)
        }
    }

    private func load(projectID: ProjectID) throws -> Data {
        var query = baseQuery(projectID: projectID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            throw SecurityError.keyUnavailable(projectID)
        }
        return data
    }

    private func baseQuery(projectID: ProjectID) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: projectID.rawValue,
            kSecUseDataProtectionKeychain as String: true,
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
#endif
