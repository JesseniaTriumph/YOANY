import Foundation

public enum ArchiveRestoreError: Error, Equatable, Sendable {
    case malformedArchive
    case integrityMismatch
    case manifestMismatch
    case unsupportedArchiveVersion(Int)
    case projectAlreadyExists(ProjectID)
    case unsupportedKeyRestoration
}

public protocol ArchiveRestorableKeyWrapping: KeyWrapping {
    func importWrappedKey(projectID: ProjectID, wrappedKey: WrappedKey) throws
}

public struct EncryptedArchiveContainer: Codable, Sendable, Equatable {
    public let manifest: EncryptedArchiveManifest
    public let packageData: Data
    public let integrityDigest: String

    public init(manifest: EncryptedArchiveManifest, packageData: Data, integrityDigest: String) {
        self.manifest = manifest
        self.packageData = packageData
        self.integrityDigest = integrityDigest
    }
}
