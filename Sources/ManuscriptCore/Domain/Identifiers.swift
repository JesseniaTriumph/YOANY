import Foundation

public protocol OpaqueIdentifier: RawRepresentable, Codable, Hashable, Sendable where RawValue == String {
    static var prefix: String { get }
    init(rawValue: String)
}

public extension OpaqueIdentifier {
    static func make() -> Self {
        Self(rawValue: "\(prefix)_\(UUID().uuidString.lowercased())")
    }
}

public struct ProjectID: OpaqueIdentifier {
    public static let prefix = "proj"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct RevisionID: OpaqueIdentifier {
    public static let prefix = "rev"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct SegmentID: OpaqueIdentifier {
    public static let prefix = "seg"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct PageID: OpaqueIdentifier {
    public static let prefix = "page"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ModelID: OpaqueIdentifier {
    public static let prefix = "model"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct ExportConfirmationID: OpaqueIdentifier {
    public static let prefix = "confirm"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct DeleteConfirmationID: OpaqueIdentifier {
    public static let prefix = "delete"
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
