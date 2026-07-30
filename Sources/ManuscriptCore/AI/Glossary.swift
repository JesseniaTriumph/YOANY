import Foundation

public struct GlossaryEntry: Codable, Sendable, Equatable, Hashable {
    public let sourceTerm: String
    public let approvedTargetTerm: String
    public let notes: String?

    public init(sourceTerm: String, approvedTargetTerm: String, notes: String? = nil) {
        self.sourceTerm = sourceTerm
        self.approvedTargetTerm = approvedTargetTerm
        self.notes = notes
    }
}

public struct Glossary: Codable, Sendable, Equatable {
    public let entries: [GlossaryEntry]

    public init(entries: [GlossaryEntry] = []) {
        self.entries = entries
    }

    public func approvedTarget(for sourceTerm: String) -> String? {
        entries.first(where: { $0.sourceTerm.caseInsensitiveCompare(sourceTerm) == .orderedSame })?.approvedTargetTerm
    }
}
