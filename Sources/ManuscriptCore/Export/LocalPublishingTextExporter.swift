import Foundation

public struct LocalPublishingTextExporter: Sendable {
    public init() {}

    public func render(document: CanonicalDocument) -> String {
        let pageSeparator = "\n\n" + String("\u{000C}") + "\n\n"
        return document.pages.map { page in
            page.segments.map(\.text).joined(separator: "\n\n")
        }.joined(separator: pageSeparator)
    }
}
