import Foundation

public enum SupportedLanguage: String, Codable, Sendable, CaseIterable {
    case french
    case english
    case spanish
    case portuguese
    case arabic
}

public struct LanguageRoute: Codable, Sendable, Equatable, Hashable {
    public let source: SupportedLanguage
    public let target: SupportedLanguage

    public init(source: SupportedLanguage, target: SupportedLanguage) {
        self.source = source
        self.target = target
    }
}
