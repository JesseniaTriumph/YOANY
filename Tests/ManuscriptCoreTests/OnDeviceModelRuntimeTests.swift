import CryptoKit
import Foundation
@testable import ManuscriptCore
import Testing

struct OnDeviceModelRuntimeTests {
    @Test
    func missingManifestThrowsNoInstalledModelBundle() throws {
        let modelsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: modelsURL) }

        let runtime = InstalledModelManifestRuntime(modelsRootURL: modelsURL)

        #expect(throws: OnDeviceModelRuntimeError.noInstalledModelBundle(modelsRootURL: modelsURL)) {
            try runtime.activeDescriptor()
        }
    }

    @Test
    func deterministicManifestProducesFrenchToEnglishTranslationProposal() throws {
        let fixture = try ModelRuntimeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.modelsURL) }

        try fixture.writeManifest(
            """
            {
              "id": "model_preview",
              "displayName": "Preview Runtime",
              "proofreadingLanguages": ["french"],
              "translationRoutes": [
                { "source": "french", "target": "english" },
                { "source": "french", "target": "arabic" }
              ],
              "backend": "deterministic-preview"
            }
            """
        )

        let runtime = InstalledModelManifestRuntime(modelsRootURL: fixture.modelsURL)
        let segment = fixture.segment(text: "Bonjour monde.")
        let proposal = try runtime.translationProposal(
            for: segment,
            in: fixture.document(segment: segment),
            route: LanguageRoute(source: .french, target: .english),
            glossary: Glossary()
        )

        #expect(proposal.replacementText == "Hello world.")
        #expect(proposal.category == .translation)
    }

    @Test
    func unsupportedRouteThrowsSpecificError() throws {
        let fixture = try ModelRuntimeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.modelsURL) }

        try fixture.writeManifest(
            """
            {
              "id": "model_preview",
              "displayName": "Preview Runtime",
              "proofreadingLanguages": ["french"],
              "translationRoutes": [
                { "source": "french", "target": "english" }
              ],
              "backend": "deterministic-preview"
            }
            """
        )

        let runtime = InstalledModelManifestRuntime(modelsRootURL: fixture.modelsURL)
        let route = LanguageRoute(source: .english, target: .spanish)
        let segment = fixture.segment(text: "Hello world.")

        #expect(throws: OnDeviceModelRuntimeError.unsupportedTranslationRoute(route)) {
            try runtime.translationProposal(
                for: segment,
                in: fixture.document(segment: segment),
                route: route,
                glossary: Glossary()
            )
        }
    }

    @Test
    func bundleRulesBackendLoadsDigestCheckedAssets() throws {
        let fixture = try ModelRuntimeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.modelsURL) }

        let proofreadingRules = Data(
            """
            {
              "languages": {
                "french": {
                  "replacements": {
                    " ,": ",",
                    " .": "."
                  }
                }
              }
            }
            """.utf8
        )
        let translationLexicon = Data(
            """
            {
              "routes": [
                {
                  "source": "french",
                  "target": "english",
                  "replacements": {
                    "Bonjour": "Hello",
                    "monde": "world"
                  }
                }
              ]
            }
            """.utf8
        )
        try proofreadingRules.write(
            to: fixture.modelsURL.appendingPathComponent("proofreading_rules.json"),
            options: .atomic
        )
        try translationLexicon.write(
            to: fixture.modelsURL.appendingPathComponent("translation_lexicon.json"),
            options: .atomic
        )

        try fixture.writeManifest(
            """
            {
              "formatVersion": 1,
              "id": "model_rules",
              "displayName": "Rules Runtime",
              "proofreadingLanguages": ["french"],
              "translationRoutes": [
                { "source": "french", "target": "english" }
              ],
              "backend": "bundle-rules-v1",
              "assetDigests": {
                "proofreading_rules.json": "\(fixture.digestHex(proofreadingRules))",
                "translation_lexicon.json": "\(fixture.digestHex(translationLexicon))"
              }
            }
            """
        )

        let runtime = InstalledModelManifestRuntime(modelsRootURL: fixture.modelsURL)
        let proofSegment = fixture.segment(text: "Bonjour monde .")
        let proofProposal = try runtime.proofreadingProposal(
            for: proofSegment,
            in: fixture.document(segment: proofSegment),
            language: .french
        )
        #expect(proofProposal.replacementText == "Bonjour monde.")

        let translationSegment = fixture.segment(text: "Bonjour monde.")
        let translationProposal = try runtime.translationProposal(
            for: translationSegment,
            in: fixture.document(segment: translationSegment),
            route: LanguageRoute(source: .french, target: .english),
            glossary: Glossary()
        )
        #expect(translationProposal.replacementText == "Hello world.")
    }

    @Test
    func bundleRulesDigestMismatchThrowsSpecificError() throws {
        let fixture = try ModelRuntimeFixture()
        defer { try? FileManager.default.removeItem(at: fixture.modelsURL) }

        try Data(
            """
            { "languages": { "french": { "replacements": { " .": "." } } } }
            """.utf8
        ).write(to: fixture.modelsURL.appendingPathComponent("proofreading_rules.json"))
        try Data(
            """
            { "routes": [] }
            """.utf8
        ).write(to: fixture.modelsURL.appendingPathComponent("translation_lexicon.json"))

        try fixture.writeManifest(
            """
            {
              "formatVersion": 1,
              "id": "model_rules",
              "displayName": "Rules Runtime",
              "proofreadingLanguages": ["french"],
              "translationRoutes": [
                { "source": "french", "target": "english" }
              ],
              "backend": "bundle-rules-v1",
              "assetDigests": {
                "proofreading_rules.json": "deadbeef",
                "translation_lexicon.json": "deadbeef"
              }
            }
            """
        )

        let runtime = InstalledModelManifestRuntime(modelsRootURL: fixture.modelsURL)
        let segment = fixture.segment(text: "Bonjour monde .")
        #expect(throws: OnDeviceModelRuntimeError.assetDigestMismatch("proofreading_rules.json")) {
            _ = try runtime.proofreadingProposal(
                for: segment,
                in: fixture.document(segment: segment),
                language: .french
            )
        }
    }
}

private struct ModelRuntimeFixture {
    let modelsURL: URL
    private let pageID = PageID.make()

    init() throws {
        modelsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: modelsURL,
            withIntermediateDirectories: true
        )
    }

    func writeManifest(_ json: String) throws {
        let manifestURL = modelsURL.appendingPathComponent("manifest.json")
        try Data(json.utf8).write(to: manifestURL, options: .atomic)
    }

    func digestHex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func segment(text: String) -> DocumentSegment {
        DocumentSegment(
            pageID: pageID,
            orderIndex: 0,
            kind: .paragraph,
            text: text,
            sourceRange: SourceRangeReference(pageIndex: 0, segmentIndex: 0)
        )
    }

    func document(segment: DocumentSegment) -> CanonicalDocument {
        let page = DocumentPage(
            id: pageID,
            pageIndex: 0,
            sourceLabel: "Page 1",
            segments: [segment]
        )
        return CanonicalDocument(
            format: .plainText,
            contentHash: CanonicalDocument.sha256Hex(for: Data(segment.text.utf8)),
            pages: [page],
            warnings: []
        )
    }
}
