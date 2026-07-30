import CryptoKit
import Foundation

public enum LocalModelBundleInstallerError: Error, Equatable, Sendable {
    case unsupportedSource(URL)
    case missingManifest
    case invalidManifest
    case missingLicenseDeclaration
    case missingProvenanceDeclaration
    case missingSignatureDeclaration
    case missingRequiredDigest(String)
    case unsupportedSignatureAlgorithm(String)
    case untrustedSigner(String)
    case revokedSigner(String)
    case invalidSignatureEncoding
    case signatureDigestMismatch
    case signatureVerificationFailed
    case unsupportedBackend(String)
    case missingRequiredAsset(String)
    case invalidProvenanceDocument
    case assetDigestMismatch(String)
    case undeclaredBundleAsset(String)
}

public struct InstalledLocalModel: Equatable, Sendable {
    public let descriptor: OnDeviceModelDescriptor
    public let backend: String?
    public let license: String?
    public let provenance: String?
    public let installedAt: URL

    public init(
        descriptor: OnDeviceModelDescriptor,
        backend: String?,
        license: String?,
        provenance: String?,
        installedAt: URL
    ) {
        self.descriptor = descriptor
        self.backend = backend
        self.license = license
        self.provenance = provenance
        self.installedAt = installedAt
    }
}

private struct BundleProvenanceDocument: Codable, Equatable, Sendable {
    let modelID: String
    let displayName: String
    let license: String
    let source: String
    let sourceRevision: String
    let distributor: String
    let convertedAt: String
}

public struct ModelBundleTrustStore: Sendable {
    private let trustedSignerKeys: [String: Data]
    private let revokedSignerKeyIDs: Set<String>

    public init(
        trustedSignerKeys: [String: Data],
        revokedSignerKeyIDs: Set<String> = []
    ) {
        self.trustedSignerKeys = trustedSignerKeys
        self.revokedSignerKeyIDs = revokedSignerKeyIDs
    }

    public func publicKeyData(for signerKeyID: String) -> Data? {
        trustedSignerKeys[signerKeyID]
    }

    public func isRevoked(_ signerKeyID: String) -> Bool {
        revokedSignerKeyIDs.contains(signerKeyID)
    }

    public static let builtIn = ModelBundleTrustStore(
        trustedSignerKeys: [
            "yoan-translator-dev-1": Data(base64Encoded: "p2n59VX8ycNe5F8v0a+QDxe2NHkxojxqbGDab16zmYE=")!,
        ]
    )
}

public struct LocalModelBundleInstaller {
    private let modelsRootURL: URL
    private let fileManager: FileManager
    private let trustStore: ModelBundleTrustStore

    public init(
        modelsRootURL: URL,
        fileManager: FileManager = .default,
        trustStore: ModelBundleTrustStore = .builtIn
    ) {
        self.modelsRootURL = modelsRootURL
        self.fileManager = fileManager
        self.trustStore = trustStore
    }

    public func installBundle(from sourceURL: URL) throws -> InstalledLocalModel {
        guard sourceURL.hasDirectoryPath else {
            throw LocalModelBundleInstallerError.unsupportedSource(sourceURL)
        }
        let manifest = try loadManifest(from: sourceURL)
        try validate(manifest: manifest, sourceURL: sourceURL)
        let descriptor = OnDeviceModelDescriptor(
            id: ModelID(rawValue: manifest.id),
            displayName: manifest.displayName,
            proofreadingLanguages: manifest.proofreadingLanguages,
            translationRoutes: manifest.translationRoutes
        )

        try fileManager.createDirectory(
            at: modelsRootURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        let installedAtURL: URL
        installedAtURL = modelsRootURL.appendingPathComponent("bundle", isDirectory: true)
        try replaceDirectory(at: installedAtURL, withContentsOf: sourceURL)

        return InstalledLocalModel(
            descriptor: descriptor,
            backend: manifest.backend,
            license: manifest.license,
            provenance: manifest.provenance,
            installedAt: installedAtURL
        )
    }

    public func installBuiltInStarterBundle() throws -> InstalledLocalModel {
        try fileManager.createDirectory(
            at: modelsRootURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let bundleURL = modelsRootURL.appendingPathComponent("bundle", isDirectory: true)
        if fileManager.fileExists(atPath: bundleURL.path) {
            try fileManager.removeItem(at: bundleURL)
        }
        try fileManager.createDirectory(
            at: bundleURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        let proofreadingRules = builtInProofreadingRulesData()
        let translationLexicon = builtInTranslationLexiconData()
        let assetDigests = [
            "LICENSE.txt": digestHex(builtInLicenseData()),
            "PROVENANCE.json": digestHex(builtInProvenanceData()),
            "proofreading_rules.json": digestHex(proofreadingRules),
            "translation_lexicon.json": digestHex(translationLexicon),
        ]
        let manifest = OnDeviceModelManifest(
            id: "model_starter_rules",
            displayName: "Bundled Starter Rules",
            proofreadingLanguages: [.french],
            translationRoutes: [
                LanguageRoute(source: .french, target: .english),
                LanguageRoute(source: .french, target: .spanish),
                LanguageRoute(source: .french, target: .portuguese),
                LanguageRoute(source: .french, target: .arabic),
            ],
            backend: "bundle-rules-v1",
            license: "Bundled local starter ruleset",
            provenance: "Repository bundled offline starter asset",
            assetDigests: assetDigests
        )
        let manifestData = try JSONEncoder().encode(manifest)

        try manifestData.write(
            to: bundleURL.appendingPathComponent("manifest.json"),
            options: .atomic
        )
        try builtInLicenseData().write(
            to: bundleURL.appendingPathComponent("LICENSE.txt"),
            options: .atomic
        )
        try builtInProvenanceData().write(
            to: bundleURL.appendingPathComponent("PROVENANCE.json"),
            options: .atomic
        )
        try proofreadingRules.write(
            to: bundleURL.appendingPathComponent("proofreading_rules.json"),
            options: .atomic
        )
        try translationLexicon.write(
            to: bundleURL.appendingPathComponent("translation_lexicon.json"),
            options: .atomic
        )
        try applyPermissionsRecursively(at: bundleURL)

        return InstalledLocalModel(
            descriptor: OnDeviceModelDescriptor(
                id: ModelID(rawValue: manifest.id),
                displayName: manifest.displayName,
                proofreadingLanguages: manifest.proofreadingLanguages,
                translationRoutes: manifest.translationRoutes
            ),
            backend: manifest.backend,
            license: manifest.license,
            provenance: manifest.provenance,
            installedAt: bundleURL
        )
    }

    public func installedModel() throws -> InstalledLocalModel {
        let bundleURL = installedBundleRoot()
        let manifest = try loadManifest(from: bundleURL)
        return InstalledLocalModel(
            descriptor: OnDeviceModelDescriptor(
                id: ModelID(rawValue: manifest.id),
                displayName: manifest.displayName,
                proofreadingLanguages: manifest.proofreadingLanguages,
                translationRoutes: manifest.translationRoutes
            ),
            backend: manifest.backend,
            license: manifest.license,
            provenance: manifest.provenance,
            installedAt: bundleURL
        )
    }

    private func loadManifest(from sourceURL: URL) throws -> OnDeviceModelManifest {
        let manifestURL: URL
        if sourceURL.hasDirectoryPath {
            manifestURL = sourceURL.appendingPathComponent("manifest.json")
        } else if sourceURL.lastPathComponent.lowercased() == "manifest.json" || sourceURL.pathExtension.lowercased() == "json" {
            manifestURL = sourceURL
        } else {
            throw LocalModelBundleInstallerError.unsupportedSource(sourceURL)
        }

        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw LocalModelBundleInstallerError.missingManifest
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            return try JSONDecoder().decode(OnDeviceModelManifest.self, from: data)
        } catch {
            throw LocalModelBundleInstallerError.invalidManifest
        }
    }

    private func validate(manifest: OnDeviceModelManifest, sourceURL: URL) throws {
        let normalizedLicense = manifest.license?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalizedLicense.isEmpty else {
            throw LocalModelBundleInstallerError.missingLicenseDeclaration
        }

        let normalizedProvenance = manifest.provenance?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !normalizedProvenance.isEmpty else {
            throw LocalModelBundleInstallerError.missingProvenanceDeclaration
        }

        try validateManifestSignature(manifest)

        if sourceURL.hasDirectoryPath {
            try validateBundleAssetInventory(sourceURL: sourceURL, manifest: manifest)
            try validateTextAsset(named: "LICENSE.txt", sourceURL: sourceURL, manifest: manifest)
            let provenanceDocument = try validateJSONAsset(
                named: "PROVENANCE.json",
                sourceURL: sourceURL,
                manifest: manifest,
                as: BundleProvenanceDocument.self
            )
            try validateProvenanceDocument(
                provenanceDocument,
                manifest: manifest
            )
        }

        switch manifest.backend ?? "deterministic-preview" {
        case "deterministic-preview":
            return
        case "bundle-rules-v1":
            try validateAsset(
                named: "proofreading_rules.json",
                manifest: manifest,
                sourceURL: sourceURL
            )
            try validateAsset(
                named: "translation_lexicon.json",
                manifest: manifest,
                sourceURL: sourceURL
            )
        case let backend:
            throw LocalModelBundleInstallerError.unsupportedBackend(backend)
        }
    }

    private func validateBundleAssetInventory(
        sourceURL: URL,
        manifest: OnDeviceModelManifest
    ) throws {
        let declaredAssetDigests = manifest.assetDigests ?? [:]
        let actualAssetURLs = try bundleAssetURLs(in: sourceURL)
        let actualAssetNames = Set(actualAssetURLs.keys)
        let declaredAssetNames = Set(declaredAssetDigests.keys)

        if let undeclaredAsset = actualAssetNames.subtracting(declaredAssetNames).sorted().first {
            throw LocalModelBundleInstallerError.undeclaredBundleAsset(undeclaredAsset)
        }

        if let missingAsset = declaredAssetNames.subtracting(actualAssetNames).sorted().first {
            throw LocalModelBundleInstallerError.missingRequiredAsset(missingAsset)
        }

        for (assetName, assetURL) in actualAssetURLs {
            guard let expectedDigest = declaredAssetDigests[assetName] else {
                throw LocalModelBundleInstallerError.missingRequiredDigest(assetName)
            }
            let data = try Data(contentsOf: assetURL)
            guard digestHex(data) == expectedDigest else {
                throw LocalModelBundleInstallerError.assetDigestMismatch(assetName)
            }
        }
    }

    private func validateManifestSignature(_ manifest: OnDeviceModelManifest) throws {
        let signerKeyID = manifest.signerKeyID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let algorithm = manifest.signatureAlgorithm?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let signedPayloadDigest = manifest.signedPayloadDigest?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let manifestSignature = manifest.manifestSignature?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !signerKeyID.isEmpty, !algorithm.isEmpty, !signedPayloadDigest.isEmpty, !manifestSignature.isEmpty else {
            throw LocalModelBundleInstallerError.missingSignatureDeclaration
        }
        guard algorithm == "curve25519-signing-v1" else {
            throw LocalModelBundleInstallerError.unsupportedSignatureAlgorithm(algorithm)
        }
        guard !trustStore.isRevoked(signerKeyID) else {
            throw LocalModelBundleInstallerError.revokedSigner(signerKeyID)
        }
        guard let publicKeyData = trustStore.publicKeyData(for: signerKeyID) else {
            throw LocalModelBundleInstallerError.untrustedSigner(signerKeyID)
        }
        guard let signatureData = Data(base64Encoded: manifestSignature) else {
            throw LocalModelBundleInstallerError.invalidSignatureEncoding
        }

        let payloadData = signaturePayload(for: manifest)
        let computedDigest = digestHex(payloadData)
        guard computedDigest == signedPayloadDigest else {
            throw LocalModelBundleInstallerError.signatureDigestMismatch
        }

        do {
            let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: publicKeyData)
            if !publicKey.isValidSignature(signatureData, for: payloadData) {
                throw LocalModelBundleInstallerError.signatureVerificationFailed
            }
        } catch let error as LocalModelBundleInstallerError {
            throw error
        } catch {
            throw LocalModelBundleInstallerError.signatureVerificationFailed
        }
    }

    private func signaturePayload(for manifest: OnDeviceModelManifest) -> Data {
        let assetDigestLines = (manifest.assetDigests ?? [:])
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "\n")

        let routeLines = manifest.translationRoutes
            .map { "\($0.source.rawValue)->\($0.target.rawValue)" }
            .sorted()
            .joined(separator: "\n")

        let proofreadingLines = manifest.proofreadingLanguages
            .map(\.rawValue)
            .sorted()
            .joined(separator: "\n")

        return Data(
            """
            formatVersion=\(manifest.formatVersion)
            id=\(manifest.id)
            displayName=\(manifest.displayName)
            backend=\(manifest.backend ?? "")
            license=\(manifest.license ?? "")
            provenance=\(manifest.provenance ?? "")
            proofreadingLanguages=
            \(proofreadingLines)
            translationRoutes=
            \(routeLines)
            assetDigests=
            \(assetDigestLines)
            """.utf8
        )
    }

    private func validateTextAsset(
        named assetName: String,
        sourceURL: URL,
        manifest: OnDeviceModelManifest
    ) throws {
        guard sourceURL.hasDirectoryPath else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }
        let assetURL = sourceURL.appendingPathComponent(assetName)
        guard fileManager.fileExists(atPath: assetURL.path) else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }

        let data = try Data(contentsOf: assetURL)
        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }

        guard let expectedDigest = manifest.assetDigests?[assetName] else {
            throw LocalModelBundleInstallerError.missingRequiredDigest(assetName)
        }
        guard digestHex(data) == expectedDigest else {
            throw LocalModelBundleInstallerError.assetDigestMismatch(assetName)
        }
    }

    private func validateJSONAsset<T: Decodable>(
        named assetName: String,
        sourceURL: URL,
        manifest: OnDeviceModelManifest,
        as type: T.Type
    ) throws -> T {
        guard sourceURL.hasDirectoryPath else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }
        let assetURL = sourceURL.appendingPathComponent(assetName)
        guard fileManager.fileExists(atPath: assetURL.path) else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }

        let data = try Data(contentsOf: assetURL)
        guard let expectedDigest = manifest.assetDigests?[assetName] else {
            throw LocalModelBundleInstallerError.missingRequiredDigest(assetName)
        }
        guard digestHex(data) == expectedDigest else {
            throw LocalModelBundleInstallerError.assetDigestMismatch(assetName)
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw LocalModelBundleInstallerError.invalidProvenanceDocument
        }
    }

    private func validateProvenanceDocument(
        _ provenanceDocument: BundleProvenanceDocument,
        manifest: OnDeviceModelManifest
    ) throws {
        let manifestLicense = manifest.license?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let manifestProvenance = manifest.provenance?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard provenanceDocument.modelID == manifest.id,
              provenanceDocument.displayName == manifest.displayName,
              provenanceDocument.license == manifestLicense,
              provenanceDocument.source == manifestProvenance,
              !provenanceDocument.sourceRevision.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !provenanceDocument.distributor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !provenanceDocument.convertedAt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LocalModelBundleInstallerError.invalidProvenanceDocument
        }
    }

    private func validateAsset(
        named assetName: String,
        manifest: OnDeviceModelManifest,
        sourceURL: URL
    ) throws {
        guard sourceURL.hasDirectoryPath else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }
        let assetURL = sourceURL.appendingPathComponent(assetName)
        guard fileManager.fileExists(atPath: assetURL.path) else {
            throw LocalModelBundleInstallerError.missingRequiredAsset(assetName)
        }

        guard let expectedDigest = manifest.assetDigests?[assetName] else {
            throw LocalModelBundleInstallerError.missingRequiredDigest(assetName)
        }
        let data = try Data(contentsOf: assetURL)
        guard digestHex(data) == expectedDigest else {
            throw LocalModelBundleInstallerError.assetDigestMismatch(assetName)
        }
    }

    private func bundleAssetURLs(in sourceURL: URL) throws -> [String: URL] {
        let enumerator = fileManager.enumerator(
            at: sourceURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var assetURLs: [String: URL] = [:]
        while let itemURL = enumerator?.nextObject() as? URL {
            let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory != true else {
                continue
            }

            let relativePath = try relativeAssetPath(for: itemURL, in: sourceURL)
            guard relativePath != "manifest.json" else {
                continue
            }
            assetURLs[relativePath] = itemURL
        }
        return assetURLs
    }

    private func relativeAssetPath(for itemURL: URL, in rootURL: URL) throws -> String {
        let normalizedRootComponents = rootURL.resolvingSymlinksInPath().standardizedFileURL.pathComponents
        let normalizedItemComponents = itemURL.resolvingSymlinksInPath().standardizedFileURL.pathComponents
        guard normalizedItemComponents.starts(with: normalizedRootComponents) else {
            throw LocalModelBundleInstallerError.unsupportedSource(itemURL)
        }

        return normalizedItemComponents
            .dropFirst(normalizedRootComponents.count)
            .joined(separator: "/")
    }

    private func installedBundleRoot() -> URL {
        let bundleURL = modelsRootURL.appendingPathComponent("bundle", isDirectory: true)
        if fileManager.fileExists(atPath: bundleURL.path) {
            return bundleURL
        }
        return modelsRootURL
    }

    private func replaceDirectory(at destinationURL: URL, withContentsOf sourceURL: URL) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        try applyPermissionsRecursively(at: destinationURL)

        let manifestURL = destinationURL.appendingPathComponent("manifest.json")
        if !fileManager.fileExists(atPath: manifestURL.path) {
            throw LocalModelBundleInstallerError.missingManifest
        }
    }

    private func applyPermissionsRecursively(at rootURL: URL) throws {
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: rootURL.path)
        let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        while let itemURL = enumerator?.nextObject() as? URL {
            let values = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let permissions: NSNumber = values.isDirectory == true ? 0o700 : 0o600
            try fileManager.setAttributes([.posixPermissions: permissions], ofItemAtPath: itemURL.path)
        }
    }

    private func digestHex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func builtInProofreadingRulesData() -> Data {
        Data(
            """
            {
              "languages": {
                "french": {
                  "replacements": {
                    " ,": ",",
                    " .": ".",
                    " ;": ";",
                    " :": ":",
                    " ?": "?",
                    " !": "!"
                  }
                }
              }
            }
            """.utf8
        )
    }

    private func builtInTranslationLexiconData() -> Data {
        Data(
            """
            {
              "routes": [
                {
                  "source": "french",
                  "target": "english",
                  "replacements": {
                    "Bonjour": "Hello",
                    "monde": "world",
                    "manuscrit": "manuscript",
                    "prive": "private",
                    "revision": "revision"
                  }
                },
                {
                  "source": "french",
                  "target": "spanish",
                  "replacements": {
                    "Bonjour": "Hola",
                    "monde": "mundo",
                    "manuscrit": "manuscrito",
                    "prive": "privado",
                    "revision": "revision"
                  }
                },
                {
                  "source": "french",
                  "target": "portuguese",
                  "replacements": {
                    "Bonjour": "Ola",
                    "monde": "mundo",
                    "manuscrit": "manuscrito",
                    "prive": "privado",
                    "revision": "revisao"
                  }
                },
                {
                  "source": "french",
                  "target": "arabic",
                  "replacements": {
                    "Bonjour": "مرحبا",
                    "monde": "العالم",
                    "manuscrit": "مخطوطة",
                    "prive": "خاص",
                    "revision": "مراجعة"
                  }
                }
              ]
            }
            """.utf8
        )
    }

    private func builtInLicenseData() -> Data {
        Data(
            """
            Bundled local starter ruleset for offline verification and UI integration testing.
            Not a publication-grade neural model.
            """.utf8
        )
    }

    private func builtInProvenanceData() -> Data {
        Data(
            """
            {
              "modelID": "model_starter_rules",
              "displayName": "Bundled Starter Rules",
              "license": "Bundled local starter ruleset",
              "source": "Repository bundled offline starter asset",
              "sourceRevision": "workspace-local",
              "distributor": "Yoan Translator workspace",
              "convertedAt": "2026-07-29"
            }
            """.utf8
        )
    }
}
