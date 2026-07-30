import CryptoKit
import Foundation
@testable import ManuscriptCore
import Testing

struct LocalModelBundleInstallerTests {
    @Test
    func rejectsManifestOnlyExternalInstall() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let manifestURL = fixture.rootURL.appendingPathComponent("manifest.json")
        try fixture.writeManifest(
            fixture.signedManifestJSON(
                id: "model_preview",
                displayName: "Preview Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "deterministic-preview",
                license: "Apache-2.0",
                provenance: "https://example.invalid/models/preview-runtime"
            ),
            to: manifestURL
        )

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        #expect(throws: LocalModelBundleInstallerError.unsupportedSource(manifestURL)) {
            try installer.installBundle(from: manifestURL)
        }
    }

    @Test
    func installsDirectoryBundleIntoSealedBundleDirectory() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("FrenchEnglish.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let licenseData = Data("MIT license text".utf8)
        let provenanceData = fixture.provenanceData(
            modelID: "model_bundle",
            displayName: "Bundle Runtime",
            license: "MIT",
            source: "https://example.invalid/models/bundle-runtime"
        )
        let weightsData = Data("weights".utf8)
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_bundle",
                displayName: "Bundle Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [
                    LanguageRoute(source: .french, target: .english),
                    LanguageRoute(source: .french, target: .arabic),
                ],
                backend: "deterministic-preview",
                license: "MIT",
                provenance: "https://example.invalid/models/bundle-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(licenseData),
                    "PROVENANCE.json": fixture.digestHex(provenanceData),
                    "weights.bin": fixture.digestHex(weightsData),
                ]
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )
        let weightsURL = bundleURL.appendingPathComponent("weights.bin")
        try weightsData.write(to: weightsURL)
        try licenseData.write(to: bundleURL.appendingPathComponent("LICENSE.txt"))
        try provenanceData.write(to: bundleURL.appendingPathComponent("PROVENANCE.json"))

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        let installed = try installer.installBundle(from: bundleURL)

        #expect(installed.descriptor.id == ModelID(rawValue: "model_bundle"))
        #expect(installed.license == "MIT")
        #expect(installed.provenance == "https://example.invalid/models/bundle-runtime")
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/manifest.json").path))
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/weights.bin").path))
    }

    @Test
    func rejectsDirectoryBundleWithUndeclaredExtraAsset() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("UndeclaredAsset.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let licenseData = Data("MIT license text".utf8)
        let provenanceData = fixture.provenanceData(
            modelID: "model_bundle",
            displayName: "Bundle Runtime",
            license: "MIT",
            source: "https://example.invalid/models/bundle-runtime"
        )
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_bundle",
                displayName: "Bundle Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "deterministic-preview",
                license: "MIT",
                provenance: "https://example.invalid/models/bundle-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(licenseData),
                    "PROVENANCE.json": fixture.digestHex(provenanceData),
                ]
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )
        try Data("weights".utf8).write(to: bundleURL.appendingPathComponent("weights.bin"))
        try licenseData.write(to: bundleURL.appendingPathComponent("LICENSE.txt"))
        try provenanceData.write(to: bundleURL.appendingPathComponent("PROVENANCE.json"))

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        #expect(throws: LocalModelBundleInstallerError.undeclaredBundleAsset("weights.bin")) {
            try installer.installBundle(from: bundleURL)
        }
    }

    @Test
    func rejectsBundleWithoutManifest() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("Broken.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)

        #expect(throws: LocalModelBundleInstallerError.missingManifest) {
            try installer.installBundle(from: bundleURL)
        }
    }

    @Test
    func installsBuiltInStarterBundle() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        let installed = try installer.installBuiltInStarterBundle()

        #expect(installed.descriptor.id == ModelID(rawValue: "model_starter_rules"))
        #expect(installed.backend == "bundle-rules-v1")
        #expect(installed.license == "Bundled local starter ruleset")
        #expect(installed.provenance == "Repository bundled offline starter asset")
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/manifest.json").path))
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/LICENSE.txt").path))
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/PROVENANCE.json").path))
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/proofreading_rules.json").path))
        #expect(FileManager.default.fileExists(atPath: fixture.modelsURL.appendingPathComponent("bundle/translation_lexicon.json").path))
    }

    @Test
    func rejectsBundleWithMismatchedAssetDigest() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("BrokenDigest.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let licenseData = Data("MIT license text".utf8)
        let provenanceData = fixture.provenanceData(
            modelID: "model_bundle",
            displayName: "Bundle Runtime",
            license: "MIT",
            source: "https://example.invalid/models/bundle-runtime"
        )
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_bundle",
                displayName: "Bundle Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "bundle-rules-v1",
                license: "MIT",
                provenance: "https://example.invalid/models/bundle-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(licenseData),
                    "PROVENANCE.json": fixture.digestHex(provenanceData),
                    "proofreading_rules.json": "deadbeef",
                    "translation_lexicon.json": "deadbeef",
                ]
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )
        try licenseData.write(to: bundleURL.appendingPathComponent("LICENSE.txt"))
        try provenanceData.write(to: bundleURL.appendingPathComponent("PROVENANCE.json"))
        try Data(#"{"languages":{"french":{"replacements":{" .":"."}}}}"#.utf8)
            .write(to: bundleURL.appendingPathComponent("proofreading_rules.json"))
        try Data(#"{"routes":[]}"#.utf8)
            .write(to: bundleURL.appendingPathComponent("translation_lexicon.json"))

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        do {
            let _ = try installer.installBundle(from: bundleURL)
            Issue.record("Expected bundle installation to fail on a corrupted asset digest.")
        } catch let error as LocalModelBundleInstallerError {
            guard case .assetDigestMismatch(let assetName) = error else {
                Issue.record("Expected an asset digest mismatch, got \(error).")
                return
            }
            #expect(assetName == "proofreading_rules.json" || assetName == "translation_lexicon.json")
        } catch {
            Issue.record("Expected LocalModelBundleInstallerError, got \(error).")
        }
    }

    @Test
    func rejectsBundleWithoutLicenseDeclaration() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("MissingLicense.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let provenanceData = fixture.provenanceData(
            modelID: "model_preview",
            displayName: "Preview Runtime",
            license: "Apache-2.0",
            source: "https://example.invalid/models/preview-runtime"
        )
        try Data("Apache-2.0".utf8).write(to: bundleURL.appendingPathComponent("LICENSE.txt"))
        try provenanceData.write(to: bundleURL.appendingPathComponent("PROVENANCE.json"))
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_preview",
                displayName: "Preview Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "deterministic-preview",
                license: nil,
                provenance: "https://example.invalid/models/preview-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(Data("Apache-2.0".utf8)),
                    "PROVENANCE.json": fixture.digestHex(provenanceData),
                ]
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        #expect(throws: LocalModelBundleInstallerError.missingLicenseDeclaration) {
            try installer.installBundle(from: bundleURL)
        }
    }

    @Test
    func rejectsDirectoryBundleWithoutProvenanceDocument() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("MissingProvenance.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let licenseData = Data("MIT license text".utf8)
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_bundle",
                displayName: "Bundle Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "deterministic-preview",
                license: "MIT",
                provenance: "https://example.invalid/models/bundle-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(licenseData),
                    "PROVENANCE.json": "deadbeef",
                ]
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )
        try licenseData.write(to: bundleURL.appendingPathComponent("LICENSE.txt"))

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        #expect(throws: LocalModelBundleInstallerError.missingRequiredAsset("PROVENANCE.json")) {
            try installer.installBundle(from: bundleURL)
        }
    }

    @Test
    func rejectsManifestSignedByUntrustedSigner() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("UntrustedSigner.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let licenseData = Data("Apache-2.0".utf8)
        let provenanceData = fixture.provenanceData(
            modelID: "model_preview",
            displayName: "Preview Runtime",
            license: "Apache-2.0",
            source: "https://example.invalid/models/preview-runtime"
        )
        try licenseData.write(to: bundleURL.appendingPathComponent("LICENSE.txt"))
        try provenanceData.write(to: bundleURL.appendingPathComponent("PROVENANCE.json"))
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_preview",
                displayName: "Preview Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "deterministic-preview",
                license: "Apache-2.0",
                provenance: "https://example.invalid/models/preview-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(licenseData),
                    "PROVENANCE.json": fixture.digestHex(provenanceData),
                ],
                signerKeyID: "untrusted-signer"
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )

        let installer = LocalModelBundleInstaller(modelsRootURL: fixture.modelsURL)
        #expect(throws: LocalModelBundleInstallerError.untrustedSigner("untrusted-signer")) {
            try installer.installBundle(from: bundleURL)
        }
    }

    @Test
    func rejectsManifestSignedByRevokedSigner() throws {
        let fixture = try LocalModelInstallerFixture()
        defer { try? FileManager.default.removeItem(at: fixture.rootURL) }

        let bundleURL = fixture.rootURL.appendingPathComponent("RevokedSigner.yoanmodel", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        let licenseData = Data("Apache-2.0".utf8)
        let provenanceData = fixture.provenanceData(
            modelID: "model_preview",
            displayName: "Preview Runtime",
            license: "Apache-2.0",
            source: "https://example.invalid/models/preview-runtime"
        )
        try licenseData.write(to: bundleURL.appendingPathComponent("LICENSE.txt"))
        try provenanceData.write(to: bundleURL.appendingPathComponent("PROVENANCE.json"))
        try fixture.writeManifest(
            try fixture.signedManifestJSON(
                id: "model_preview",
                displayName: "Preview Runtime",
                proofreadingLanguages: [.french],
                translationRoutes: [LanguageRoute(source: .french, target: .english)],
                backend: "deterministic-preview",
                license: "Apache-2.0",
                provenance: "https://example.invalid/models/preview-runtime",
                assetDigests: [
                    "LICENSE.txt": fixture.digestHex(licenseData),
                    "PROVENANCE.json": fixture.digestHex(provenanceData),
                ]
            ),
            to: bundleURL.appendingPathComponent("manifest.json")
        )

        let installer = LocalModelBundleInstaller(
            modelsRootURL: fixture.modelsURL,
            trustStore: ModelBundleTrustStore(
                trustedSignerKeys: [
                    "yoan-translator-dev-1": Data(base64Encoded: "p2n59VX8ycNe5F8v0a+QDxe2NHkxojxqbGDab16zmYE=")!,
                ],
                revokedSignerKeyIDs: ["yoan-translator-dev-1"]
            )
        )
        #expect(throws: LocalModelBundleInstallerError.revokedSigner("yoan-translator-dev-1")) {
            try installer.installBundle(from: bundleURL)
        }
    }
}

private struct LocalModelInstallerFixture {
    let rootURL: URL
    let modelsURL: URL

    init() throws {
        rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
    }

    func writeManifest(_ json: String, to url: URL) throws {
        try Data(json.utf8).write(to: url, options: .atomic)
    }

    func digestHex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func signedManifestJSON(
        id: String,
        displayName: String,
        proofreadingLanguages: [SupportedLanguage],
        translationRoutes: [LanguageRoute],
        backend: String?,
        license: String?,
        provenance: String?,
        assetDigests: [String: String]? = nil,
        signerKeyID: String = "yoan-translator-dev-1"
    ) throws -> String {
        let unsignedManifest = OnDeviceModelManifest(
            id: id,
            displayName: displayName,
            proofreadingLanguages: proofreadingLanguages,
            translationRoutes: translationRoutes,
            backend: backend,
            license: license,
            provenance: provenance,
            assetDigests: assetDigests
        )
        let payload = signaturePayload(for: unsignedManifest)
        let digest = digestHex(payload)
        let privateKey = try Curve25519.Signing.PrivateKey(
            rawRepresentation: Data(base64Encoded: "AbD4PYxpfEqhmYgDlIy5IJFqIrYjKYHfG14ZfFwvwgM=")!
        )
        let signature = try privateKey.signature(for: payload)
        let signedManifest = OnDeviceModelManifest(
            id: id,
            displayName: displayName,
            proofreadingLanguages: proofreadingLanguages,
            translationRoutes: translationRoutes,
            backend: backend,
            license: license,
            provenance: provenance,
            assetDigests: assetDigests,
            signerKeyID: signerKeyID,
            signatureAlgorithm: "curve25519-signing-v1",
            signedPayloadDigest: digest,
            manifestSignature: signature.base64EncodedString()
        )
        let data = try JSONEncoder().encode(signedManifest)
        return String(decoding: data, as: UTF8.self)
    }

    func signaturePayload(for manifest: OnDeviceModelManifest) -> Data {
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

    func provenanceData(
        modelID: String,
        displayName: String,
        license: String,
        source: String
    ) -> Data {
        Data(
            """
            {
              "modelID": "\(modelID)",
              "displayName": "\(displayName)",
              "license": "\(license)",
              "source": "\(source)",
              "sourceRevision": "abc123",
              "distributor": "Fixture Installer",
              "convertedAt": "2026-07-29"
            }
            """.utf8
        )
    }
}
