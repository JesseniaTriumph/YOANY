import Foundation
import Testing
@testable import ManuscriptCore

struct ProposalValidatorTests {
    @Test func rejectsOverreachingProofreadingProposal() throws {
        let document = try PlainTextDocumentImporter().import(text: "Bonjour.")
        let segment = try #require(document.pages.first?.segments.first)
        let validator = ProposalValidator()

        let proposal = AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .grammar,
            replacementText: "Bonjour a tous et bienvenue dans cette version entierement differente du texte.",
            reason: "Rewrite heavily.",
            uncertainty: 0.2,
            meaningChange: true,
            compositionChange: true
        )

        #expect(throws: ProposalValidationError.overreachingProofreadingProposal) {
            try validator.validateProofreadingProposal(proposal, against: document)
        }
    }

    @Test func rejectsTranslationProposalThatViolatesGlossary() throws {
        let document = try PlainTextDocumentImporter().import(text: "Bonjour monde.")
        let segment = try #require(document.pages.first?.segments.first)
        let validator = ProposalValidator()
        let glossary = Glossary(entries: [
            GlossaryEntry(sourceTerm: "monde", approvedTargetTerm: "world")
        ])

        let proposal = AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .translation,
            replacementText: "Hello earth.",
            reason: "Translation attempt.",
            uncertainty: 0.3,
            meaningChange: false,
            compositionChange: false
        )

        #expect(throws: ProposalValidationError.glossaryViolation(sourceTerm: "monde", expectedTarget: "world")) {
            try validator.validateTranslationProposal(proposal, against: document, glossary: glossary)
        }
    }

    @Test func deterministicRuntimeProducesConservativeProofreadingProposal() throws {
        let document = try PlainTextDocumentImporter().import(text: "Bonjour , monde .")
        let segment = try #require(document.pages.first?.segments.first)
        let fixture = try ProposalRuntimeFixture()
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

        let proposal = try InstalledModelManifestRuntime(modelsRootURL: fixture.modelsURL)
            .proofreadingProposal(for: segment, in: document, language: .french)
        #expect(proposal.replacementText == "Bonjour, monde.")
        #expect(proposal.compositionChange == false)
    }

    @Test func deterministicRuntimeUsesGlossaryCompliantRoute() throws {
        let document = try PlainTextDocumentImporter().import(text: "Bonjour monde.")
        let segment = try #require(document.pages.first?.segments.first)
        let glossary = Glossary(entries: [
            GlossaryEntry(sourceTerm: "monde", approvedTargetTerm: "world")
        ])
        let fixture = try ProposalRuntimeFixture()
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
        let proposal = try InstalledModelManifestRuntime(modelsRootURL: fixture.modelsURL)
            .translationProposal(
                for: segment,
                in: document,
                route: LanguageRoute(source: .french, target: .english),
                glossary: glossary
            )

        #expect(proposal.replacementText.contains("Hello"))
        #expect(proposal.replacementText.contains("world"))
    }
}

private struct ProposalRuntimeFixture {
    let modelsURL: URL

    init() throws {
        modelsURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: modelsURL,
            withIntermediateDirectories: true
        )
    }

    func writeManifest(_ json: String) throws {
        try Data(json.utf8).write(
            to: modelsURL.appendingPathComponent("manifest.json"),
            options: .atomic
        )
    }
}
