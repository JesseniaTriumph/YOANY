import Foundation
import ManuscriptCore
#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(Translation)
import Translation
#endif

protocol OnDeviceAIGateway: Sendable {
    func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal]

    func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal]
}

enum AppleOnDeviceAIError: LocalizedError {
    case translationFrameworkUnavailable
    case translationUnsupportedRoute(LanguageRoute)
    case translationLanguagePackUnavailable(LanguageRoute)
    case proofreadingFrameworkUnavailable
    case proofreadingModelUnavailable
    case proofreadingUnsupportedLanguage(SupportedLanguage)
    case emptyGeneratedText

    var errorDescription: String? {
        switch self {
        case .translationFrameworkUnavailable:
            return "Apple's on-device Translation framework is unavailable on this device or OS build."
        case .translationUnsupportedRoute(let route):
            return "Apple's on-device Translation framework does not support \(route.source.rawValue) to \(route.target.rawValue) in this app build."
        case .translationLanguagePackUnavailable(let route):
            return "The required on-device translation languages for \(route.source.rawValue) to \(route.target.rawValue) are not installed."
        case .proofreadingFrameworkUnavailable:
            return "Apple's on-device Foundation Models framework is unavailable on this device or OS build."
        case .proofreadingModelUnavailable:
            return "Apple Intelligence proofreading is unavailable on this device."
        case .proofreadingUnsupportedLanguage(let language):
            return "Apple Intelligence proofreading is not available for \(language.rawValue) on this device."
        case .emptyGeneratedText:
            return "The on-device model returned an empty result."
        }
    }

    var canFallbackToBundledModel: Bool {
        switch self {
        case .translationFrameworkUnavailable,
            .translationUnsupportedRoute,
            .translationLanguagePackUnavailable,
            .proofreadingFrameworkUnavailable,
            .proofreadingModelUnavailable,
            .proofreadingUnsupportedLanguage:
            return true
        case .emptyGeneratedText:
            return false
        }
    }

    func preferringBundledFallbackFailure(_ error: OnDeviceModelRuntimeError) -> Error {
        switch error {
        case .noInstalledModelBundle,
            .unsupportedProofreadingLanguage,
            .unsupportedTranslationRoute,
            .installRequired:
            return self
        default:
            return error
        }
    }
}

struct AppleOnDeviceAIAdapter {
    private let validator = ProposalValidator()

    func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal] {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return try await proofreadingProposalsUsingFoundationModels(
                for: document,
                language: language
            )
        }
        #endif
        throw AppleOnDeviceAIError.proofreadingFrameworkUnavailable
    }

    func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal] {
        #if canImport(Translation)
        if #available(iOS 26.0, macOS 26.0, *) {
            return try await translationProposalsUsingTranslationFramework(
                for: document,
                route: route,
                glossary: glossary
            )
        }
        #endif
        throw AppleOnDeviceAIError.translationFrameworkUnavailable
    }
}

extension AppleOnDeviceAIAdapter: OnDeviceAIGateway {}

private extension AppleOnDeviceAIAdapter {
    #if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    func proofreadingProposalsUsingFoundationModels(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal] {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw AppleOnDeviceAIError.proofreadingModelUnavailable
        }

        let locale = Locale(identifier: language.localeIdentifier)
        guard model.supportsLocale(locale) else {
            throw AppleOnDeviceAIError.proofreadingUnsupportedLanguage(language)
        }

        let session = LanguageModelSession(
            instructions: """
            You are an expert manuscript proofreader.
            Correct only grammar, spelling, punctuation, and obvious typographic errors.
            Preserve the original meaning, tone, sentence order, and composition.
            Do not summarize, explain, annotate, translate, censor, or add new content.
            Return only the corrected passage text.
            """
        )

        var proposals: [AIDocumentProposal] = []
        for segment in document.pages.flatMap(\.segments) {
            let response = try await session.respond(
                to: """
                Language: \(language.displayTitle)
                Correct this passage conservatively and return only the corrected text:

                \(segment.text)
                """
            )
            let replacement = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !replacement.isEmpty else {
                throw AppleOnDeviceAIError.emptyGeneratedText
            }
            guard replacement != segment.text else {
                continue
            }

            let proposal = AIDocumentProposal(
                segmentID: segment.id,
                pageID: segment.pageID,
                category: .grammar,
                replacementText: replacement,
                reason: "Apple Intelligence produced a conservative local proofreading revision.",
                uncertainty: 0.2,
                meaningChange: false,
                compositionChange: false
            )
            try validator.validateProofreadingProposal(proposal, against: document)
            proposals.append(proposal)
        }
        return proposals
    }
    #endif

    #if canImport(Translation)
    @available(iOS 26.0, macOS 26.0, *)
    func translationProposalsUsingTranslationFramework(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal] {
        guard route.source != route.target else {
            throw AppleOnDeviceAIError.translationUnsupportedRoute(route)
        }

        let availability = LanguageAvailability()
        switch await availability.status(
            from: route.source.localeLanguage,
            to: route.target.localeLanguage
        ) {
        case .installed:
            break
        case .supported:
            throw AppleOnDeviceAIError.translationLanguagePackUnavailable(route)
        case .unsupported:
            throw AppleOnDeviceAIError.translationUnsupportedRoute(route)
        @unknown default:
            throw AppleOnDeviceAIError.translationUnsupportedRoute(route)
        }

        let session = TranslationSession(
            installedSource: route.source.localeLanguage,
            target: route.target.localeLanguage
        )

        var proposals: [AIDocumentProposal] = []
        for segment in document.pages.flatMap(\.segments) {
            let response = try await session.translate(segment.text)
            let replacement = applyingGlossary(
                to: response.targetText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
                sourceText: segment.text,
                glossary: glossary
            )
            guard !replacement.isEmpty else {
                throw AppleOnDeviceAIError.emptyGeneratedText
            }
            guard replacement != segment.text else {
                continue
            }

            let proposal = AIDocumentProposal(
                segmentID: segment.id,
                pageID: segment.pageID,
                category: .translation,
                replacementText: replacement,
                reason: "Apple on-device translation produced a page-preserving local draft.",
                uncertainty: 0.2,
                meaningChange: false,
                compositionChange: false
            )
            try validator.validateTranslationProposal(
                proposal,
                against: document,
                glossary: glossary
            )
            proposals.append(proposal)
        }
        return proposals
    }
    #endif

    func applyingGlossary(
        to translatedText: String,
        sourceText: String,
        glossary: Glossary
    ) -> String {
        glossary.entries.reduce(translatedText) { partialResult, entry in
            guard sourceText.localizedCaseInsensitiveContains(entry.sourceTerm) else {
                return partialResult
            }
            if partialResult.localizedCaseInsensitiveContains(entry.approvedTargetTerm) {
                return partialResult
            }
            return partialResult + " " + entry.approvedTargetTerm
        }
    }
}

private extension SupportedLanguage {
    var localeIdentifier: String {
        switch self {
        case .french:
            return "fr"
        case .english:
            return "en"
        case .spanish:
            return "es"
        case .portuguese:
            return "pt"
        case .arabic:
            return "ar"
        }
    }

    var localeLanguage: Locale.Language {
        Locale.Language(identifier: localeIdentifier)
    }

    var displayTitle: String {
        switch self {
        case .french:
            return "French"
        case .english:
            return "English"
        case .spanish:
            return "Spanish"
        case .portuguese:
            return "Portuguese"
        case .arabic:
            return "Arabic"
        }
    }
}
