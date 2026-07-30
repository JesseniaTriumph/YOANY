import CryptoKit
import Foundation

public enum OnDeviceModelRuntimeError: Error, Equatable, Sendable {
    case noInstalledModelBundle(modelsRootURL: URL)
    case invalidManifest
    case unsupportedBackend(String)
    case unsupportedProofreadingLanguage(SupportedLanguage)
    case unsupportedTranslationRoute(LanguageRoute)
    case missingRequiredAsset(String)
    case assetDigestMismatch(String)
    case invalidBundleData(String)
    case installRequired(String)
}

public struct OnDeviceModelDescriptor: Codable, Equatable, Sendable {
    public let id: ModelID
    public let displayName: String
    public let proofreadingLanguages: [SupportedLanguage]
    public let translationRoutes: [LanguageRoute]

    public init(
        id: ModelID,
        displayName: String,
        proofreadingLanguages: [SupportedLanguage],
        translationRoutes: [LanguageRoute]
    ) {
        self.id = id
        self.displayName = displayName
        self.proofreadingLanguages = proofreadingLanguages
        self.translationRoutes = translationRoutes
    }
}

public struct OnDeviceModelManifest: Codable, Equatable, Sendable {
    public let formatVersion: Int
    public let id: String
    public let displayName: String
    public let proofreadingLanguages: [SupportedLanguage]
    public let translationRoutes: [LanguageRoute]
    public let backend: String?
    public let license: String?
    public let provenance: String?
    public let assetDigests: [String: String]?
    public let signerKeyID: String?
    public let signatureAlgorithm: String?
    public let signedPayloadDigest: String?
    public let manifestSignature: String?

    public init(
        formatVersion: Int = 1,
        id: String,
        displayName: String,
        proofreadingLanguages: [SupportedLanguage],
        translationRoutes: [LanguageRoute],
        backend: String?,
        license: String? = nil,
        provenance: String? = nil,
        assetDigests: [String: String]? = nil,
        signerKeyID: String? = nil,
        signatureAlgorithm: String? = nil,
        signedPayloadDigest: String? = nil,
        manifestSignature: String? = nil
    ) {
        self.formatVersion = formatVersion
        self.id = id
        self.displayName = displayName
        self.proofreadingLanguages = proofreadingLanguages
        self.translationRoutes = translationRoutes
        self.backend = backend
        self.license = license
        self.provenance = provenance
        self.assetDigests = assetDigests
        self.signerKeyID = signerKeyID
        self.signatureAlgorithm = signatureAlgorithm
        self.signedPayloadDigest = signedPayloadDigest
        self.manifestSignature = manifestSignature
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion
        case id
        case displayName
        case proofreadingLanguages
        case translationRoutes
        case backend
        case license
        case provenance
        case assetDigests
        case signerKeyID
        case signatureAlgorithm
        case signedPayloadDigest
        case manifestSignature
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try container.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        proofreadingLanguages = try container.decode([SupportedLanguage].self, forKey: .proofreadingLanguages)
        translationRoutes = try container.decode([LanguageRoute].self, forKey: .translationRoutes)
        backend = try container.decodeIfPresent(String.self, forKey: .backend)
        license = try container.decodeIfPresent(String.self, forKey: .license)
        provenance = try container.decodeIfPresent(String.self, forKey: .provenance)
        assetDigests = try container.decodeIfPresent([String: String].self, forKey: .assetDigests)
        signerKeyID = try container.decodeIfPresent(String.self, forKey: .signerKeyID)
        signatureAlgorithm = try container.decodeIfPresent(String.self, forKey: .signatureAlgorithm)
        signedPayloadDigest = try container.decodeIfPresent(String.self, forKey: .signedPayloadDigest)
        manifestSignature = try container.decodeIfPresent(String.self, forKey: .manifestSignature)
    }
}

private struct BundleProofreadingRules: Codable, Equatable, Sendable {
    struct LanguageRules: Codable, Equatable, Sendable {
        let replacements: [String: String]
    }

    let languages: [String: LanguageRules]
}

private struct BundleTranslationLexicon: Codable, Equatable, Sendable {
    struct RouteRules: Codable, Equatable, Sendable {
        let source: SupportedLanguage
        let target: SupportedLanguage
        let replacements: [String: String]
    }

    let routes: [RouteRules]
}

public protocol OnDeviceModelRuntime: Sendable {
    func activeDescriptor() throws -> OnDeviceModelDescriptor
    func proofreadingProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        language: SupportedLanguage
    ) throws -> AIDocumentProposal
    func translationProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) throws -> AIDocumentProposal
}

public struct InstalledModelManifestRuntime: OnDeviceModelRuntime {
    private let modelsRootURL: URL
    private let validator: ProposalValidator

    public init(
        modelsRootURL: URL,
        validator: ProposalValidator = ProposalValidator()
    ) {
        self.modelsRootURL = modelsRootURL
        self.validator = validator
    }

    public func activeDescriptor() throws -> OnDeviceModelDescriptor {
        let manifest = try loadManifest()
        return OnDeviceModelDescriptor(
            id: ModelID(rawValue: manifest.id),
            displayName: manifest.displayName,
            proofreadingLanguages: manifest.proofreadingLanguages,
            translationRoutes: manifest.translationRoutes
        )
    }

    public func proofreadingProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        language: SupportedLanguage
    ) throws -> AIDocumentProposal {
        let manifest = try loadManifest()
        guard manifest.proofreadingLanguages.contains(language) else {
            throw OnDeviceModelRuntimeError.unsupportedProofreadingLanguage(language)
        }
        let replacement: String
        switch manifest.backend ?? "deterministic-preview" {
        case "deterministic-preview":
            replacement = segment.text
                .replacingOccurrences(of: " ,", with: ",")
                .replacingOccurrences(of: " .", with: ".")
        case "bundle-rules-v1":
            let rules = try loadProofreadingRules(manifest: manifest)
            replacement = applyProofreadingRules(rules, to: segment.text, language: language)
        case let backend:
            throw OnDeviceModelRuntimeError.unsupportedBackend(backend)
        }

        let proposal = AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .grammar,
            replacementText: replacement,
            reason: "On-device proofreading pass produced a conservative grammar and punctuation revision.",
            uncertainty: 0.1,
            meaningChange: false,
            compositionChange: false
        )
        try validator.validateProofreadingProposal(proposal, against: document)
        return proposal
    }

    public func translationProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) throws -> AIDocumentProposal {
        let manifest = try loadManifest()
        guard manifest.translationRoutes.contains(route) else {
            throw OnDeviceModelRuntimeError.unsupportedTranslationRoute(route)
        }
        let replacement: String
        switch manifest.backend ?? "deterministic-preview" {
        case "deterministic-preview":
            replacement = deterministicPreviewTranslation(for: segment.text, route: route)
        case "bundle-rules-v1":
            let lexicon = try loadTranslationLexicon(manifest: manifest)
            replacement = applyTranslationLexicon(lexicon, to: segment.text, route: route)
        case let backend:
            throw OnDeviceModelRuntimeError.unsupportedBackend(backend)
        }

        let proposal = AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .translation,
            replacementText: replacement,
            reason: "On-device translation pass produced a draft for user review.",
            uncertainty: 0.3,
            meaningChange: false,
            compositionChange: false
        )
        try validator.validateTranslationProposal(proposal, against: document, glossary: glossary)
        return proposal
    }

    private func installedBundleRoot() -> URL {
        let bundled = modelsRootURL.appendingPathComponent("bundle", isDirectory: true)
        if FileManager.default.fileExists(atPath: bundled.path) {
            return bundled
        }
        return modelsRootURL
    }

    private func loadManifest() throws -> OnDeviceModelManifest {
        let manifestURL = installedBundleRoot().appendingPathComponent("manifest.json")
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            throw OnDeviceModelRuntimeError.noInstalledModelBundle(modelsRootURL: modelsRootURL)
        }
        do {
            let data = try Data(contentsOf: manifestURL)
            return try JSONDecoder().decode(OnDeviceModelManifest.self, from: data)
        } catch {
            throw OnDeviceModelRuntimeError.invalidManifest
        }
    }

    private func deterministicPreviewTranslation(for text: String, route: LanguageRoute) -> String {
        switch (route.source, route.target) {
        case (.french, .english):
            text
                .replacingOccurrences(of: "Bonjour", with: "Hello")
                .replacingOccurrences(of: "monde", with: "world")
        case (.french, .spanish):
            text
                .replacingOccurrences(of: "Bonjour", with: "Hola")
                .replacingOccurrences(of: "monde", with: "mundo")
        case (.french, .portuguese):
            text
                .replacingOccurrences(of: "Bonjour", with: "Ola")
                .replacingOccurrences(of: "monde", with: "mundo")
        case (.french, .arabic):
            text
                .replacingOccurrences(of: "Bonjour", with: "مرحبا")
                .replacingOccurrences(of: "monde", with: "العالم")
        default:
            text
        }
    }

    private func loadProofreadingRules(manifest: OnDeviceModelManifest) throws -> BundleProofreadingRules {
        try loadAsset(
            named: "proofreading_rules.json",
            as: BundleProofreadingRules.self,
            manifest: manifest
        )
    }

    private func loadTranslationLexicon(manifest: OnDeviceModelManifest) throws -> BundleTranslationLexicon {
        try loadAsset(
            named: "translation_lexicon.json",
            as: BundleTranslationLexicon.self,
            manifest: manifest
        )
    }

    private func loadAsset<T: Decodable>(
        named assetName: String,
        as type: T.Type,
        manifest: OnDeviceModelManifest
    ) throws -> T {
        let assetURL = installedBundleRoot().appendingPathComponent(assetName)
        guard FileManager.default.fileExists(atPath: assetURL.path) else {
            throw OnDeviceModelRuntimeError.missingRequiredAsset(assetName)
        }

        let data = try Data(contentsOf: assetURL)
        if let expectedDigest = manifest.assetDigests?[assetName] {
            let actualDigest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            guard actualDigest == expectedDigest else {
                throw OnDeviceModelRuntimeError.assetDigestMismatch(assetName)
            }
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw OnDeviceModelRuntimeError.invalidBundleData(assetName)
        }
    }

    private func applyProofreadingRules(
        _ rules: BundleProofreadingRules,
        to text: String,
        language: SupportedLanguage
    ) -> String {
        guard let languageRules = rules.languages[language.rawValue] else {
            return text
        }

        return languageRules.replacements.reduce(into: text) { partial, replacement in
            partial = partial.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }

    private func applyTranslationLexicon(
        _ lexicon: BundleTranslationLexicon,
        to text: String,
        route: LanguageRoute
    ) -> String {
        guard let routeRules = lexicon.routes.first(where: {
            $0.source == route.source && $0.target == route.target
        }) else {
            return text
        }

        return routeRules.replacements.reduce(into: text) { partial, replacement in
            partial = partial.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }
}
