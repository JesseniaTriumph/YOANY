import Foundation

public struct DocumentAIReviewService: Sendable {
    private let runtime: any OnDeviceModelRuntime

    public init(runtime: any OnDeviceModelRuntime) {
        self.runtime = runtime
    }

    public func activeModelDescriptor() throws -> OnDeviceModelDescriptor {
        try runtime.activeDescriptor()
    }

    public func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) throws -> [AIDocumentProposal] {
        try document.pages
            .flatMap(\.segments)
            .compactMap { segment in
                let proposal = try runtime.proofreadingProposal(
                    for: segment,
                    in: document,
                    language: language
                )
                return proposal.replacementText == segment.text ? nil : proposal
            }
    }

    public func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) throws -> [AIDocumentProposal] {
        try document.pages
            .flatMap(\.segments)
            .compactMap { segment in
                let proposal = try runtime.translationProposal(
                    for: segment,
                    in: document,
                    route: route,
                    glossary: glossary
                )
                return proposal.replacementText == segment.text ? nil : proposal
            }
    }
}
