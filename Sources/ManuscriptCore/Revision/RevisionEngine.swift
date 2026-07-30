import Foundation

public enum RevisionEngineError: Error, Equatable, Sendable {
    case missingSourceSnapshot
    case segmentNotFound(SegmentID)
    case priorHashMismatch
    case revisionProjectMismatch
}

public struct AcceptedRevisionProposal: Sendable, Equatable {
    public let projectID: ProjectID
    public let segmentID: SegmentID
    public let replacementText: String
    public let proposalKind: ProposalKind
    public let meaningChange: Bool
    public let compositionChange: Bool

    public init(
        projectID: ProjectID,
        segmentID: SegmentID,
        replacementText: String,
        proposalKind: ProposalKind,
        meaningChange: Bool,
        compositionChange: Bool
    ) {
        self.projectID = projectID
        self.segmentID = segmentID
        self.replacementText = replacementText
        self.proposalKind = proposalKind
        self.meaningChange = meaningChange
        self.compositionChange = compositionChange
    }
}

public struct RevisionEngine: Sendable {
    public init() {}

    public func applyAcceptedRevision(
        proposal: AcceptedRevisionProposal,
        sourceSnapshot: SourceSnapshot?,
        existingRevisions: [RevisionEvent]
    ) throws -> RevisionEvent {
        guard let sourceSnapshot else {
            throw RevisionEngineError.missingSourceSnapshot
        }
        guard let sourceSegment = sourceSnapshot.document.pages
            .flatMap(\.segments)
            .first(where: { $0.id == proposal.segmentID }) else {
            throw RevisionEngineError.segmentNotFound(proposal.segmentID)
        }

        let latestText = existingRevisions
            .last(where: { $0.segmentID == proposal.segmentID })?
            .replacementText ?? sourceSegment.text
        let priorHash = RevisionEvent.textHash(latestText)
        let newHash = RevisionEvent.textHash(proposal.replacementText)

        return RevisionEvent(
            projectID: proposal.projectID,
            segmentID: proposal.segmentID,
            priorHash: priorHash,
            newHash: newHash,
            proposalKind: proposal.proposalKind,
            meaningChange: proposal.meaningChange,
            compositionChange: proposal.compositionChange,
            acceptedByUser: true,
            replacementText: proposal.replacementText
        )
    }

    public func materializeCurrentDocument(
        sourceSnapshot: SourceSnapshot?,
        revisions: [RevisionEvent]
    ) throws -> CanonicalDocument {
        guard let sourceSnapshot else {
            throw RevisionEngineError.missingSourceSnapshot
        }

        let latestRevisionBySegment = Dictionary(
            grouping: revisions,
            by: \.segmentID
        ).compactMapValues { $0.last }

        let pages = sourceSnapshot.document.pages.map { page in
            let segments = page.segments.map { segment in
                guard let revision = latestRevisionBySegment[segment.id] else {
                    return segment
                }
                return DocumentSegment(
                    id: segment.id,
                    pageID: segment.pageID,
                    orderIndex: segment.orderIndex,
                    kind: segment.kind,
                    text: revision.replacementText,
                    sourceRange: segment.sourceRange
                )
            }
            return DocumentPage(
                id: page.id,
                pageIndex: page.pageIndex,
                sourceLabel: page.sourceLabel,
                segments: segments
            )
        }

        return CanonicalDocument(
            format: sourceSnapshot.document.format,
            contentHash: sourceSnapshot.document.contentHash,
            importedAt: sourceSnapshot.document.importedAt,
            pages: pages,
            warnings: sourceSnapshot.document.warnings
        )
    }
}
