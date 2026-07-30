import Foundation

public enum ProposalValidationError: Error, Equatable, Sendable {
    case missingReason
    case uncertaintyOutOfRange
    case emptyReplacement
    case segmentNotFound(SegmentID)
    case overreachingProofreadingProposal
    case glossaryViolation(sourceTerm: String, expectedTarget: String)
}

public struct ProposalValidator: Sendable {
    public init() {}

    public func validateProofreadingProposal(
        _ proposal: AIDocumentProposal,
        against document: CanonicalDocument
    ) throws {
        guard !proposal.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProposalValidationError.missingReason
        }
        guard (0...1).contains(proposal.uncertainty) else {
            throw ProposalValidationError.uncertaintyOutOfRange
        }
        guard !proposal.replacementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProposalValidationError.emptyReplacement
        }
        guard let original = document.pages.flatMap(\.segments).first(where: { $0.id == proposal.segmentID }) else {
            throw ProposalValidationError.segmentNotFound(proposal.segmentID)
        }

        if proposal.category != .translation,
           (proposal.meaningChange || proposal.compositionChange || isAggressiveRewrite(original: original.text, replacement: proposal.replacementText)) {
            throw ProposalValidationError.overreachingProofreadingProposal
        }
    }

    public func validateTranslationProposal(
        _ proposal: AIDocumentProposal,
        against document: CanonicalDocument,
        glossary: Glossary
    ) throws {
        guard !proposal.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProposalValidationError.missingReason
        }
        guard (0...1).contains(proposal.uncertainty) else {
            throw ProposalValidationError.uncertaintyOutOfRange
        }
        guard !proposal.replacementText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProposalValidationError.emptyReplacement
        }
        guard let original = document.pages.flatMap(\.segments).first(where: { $0.id == proposal.segmentID }) else {
            throw ProposalValidationError.segmentNotFound(proposal.segmentID)
        }

        for entry in glossary.entries where original.text.localizedCaseInsensitiveContains(entry.sourceTerm) {
            if !proposal.replacementText.localizedCaseInsensitiveContains(entry.approvedTargetTerm) {
                throw ProposalValidationError.glossaryViolation(
                    sourceTerm: entry.sourceTerm,
                    expectedTarget: entry.approvedTargetTerm
                )
            }
        }
    }

    private func isAggressiveRewrite(original: String, replacement: String) -> Bool {
        let originalWords = original.split(whereSeparator: \.isWhitespace)
        let replacementWords = replacement.split(whereSeparator: \.isWhitespace)
        let difference = abs(originalWords.count - replacementWords.count)
        return difference > max(3, originalWords.count / 2)
    }
}
