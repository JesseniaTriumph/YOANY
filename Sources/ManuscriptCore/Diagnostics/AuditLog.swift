import Foundation

public enum AuditEventType: String, Codable, Sendable {
    case projectCreated
    case projectUnlocked
    case projectLocked
    case projectDeleted
}

public struct AuditEvent: Codable, Sendable, Equatable {
    public let type: AuditEventType
    public let projectID: ProjectID
    public let timestamp: Date
    public let resultCode: String
    public let securityControlVersion: String

    public init(
        type: AuditEventType,
        projectID: ProjectID,
        timestamp: Date = .now,
        resultCode: String,
        securityControlVersion: String = "phase1-foundation"
    ) {
        self.type = type
        self.projectID = projectID
        self.timestamp = timestamp
        self.resultCode = resultCode
        self.securityControlVersion = securityControlVersion
    }
}

public actor AuditLogStore {
    private(set) var events: [AuditEvent] = []

    public init() {}

    public func record(_ event: AuditEvent) {
        events.append(event)
    }
}
