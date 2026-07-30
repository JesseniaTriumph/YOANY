#if canImport(SwiftUI)
import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif
import ManuscriptCore
import SwiftUI
#if canImport(Translation)
import Translation
#endif
import UniformTypeIdentifiers

@MainActor
final class AppShellViewModel: ObservableObject {
    @Published private(set) var privacyStatement =
        "All manuscript processing stays local to the device. Network-backed manuscript processing is out of scope."
    @Published private(set) var projects: [ProjectListRow] = []
    @Published private(set) var currentPages: [DocumentPageViewData] = []
    @Published private(set) var pendingProposals: [PendingProposalViewData] = []
    @Published private(set) var statusMessage =
        "Create a project, unlock it locally, then import manuscript pages for review."
    @Published private(set) var importedSourceFormat: SourceDocumentFormat?
    @Published private(set) var lastExportURL: URL?
    @Published private(set) var lastEncryptedArchiveURL: URL?
    @Published private(set) var bootError: String?
    @Published private(set) var activeRevisionID: RevisionID?
    @Published private(set) var activeModelDescriptor: OnDeviceModelDescriptor?
    @Published private(set) var activeModelBackend: String?
    @Published private(set) var activeModelLicense: String?
    @Published private(set) var activeModelProvenance: String?
    @Published private(set) var isPlainTextExportArmed = false
    @Published private(set) var lifecycleSecurityState = AppLifecycleSecurityState(
        scenePhase: .active,
        shouldObscureSnapshots: false,
        activeProjectID: nil,
        lastLockReason: nil
    )
    @Published var selectedProjectID: ProjectID?
    @Published var draftTitle = "Untitled Manuscript"
    @Published var draftText =
        "Bonjour monde.\n\nCeci est un manuscrit prive en cours de revision."
    @Published var importMode: DraftImportMode = .plainText
    @Published var isFileImporterPresented = false
    @Published var isBackupRestoreImporterPresented = false
    @Published var isModelImporterPresented = false
    @Published var translationSourceLanguage: SupportedLanguage = .french
    @Published var translationTargetLanguage: SupportedLanguage = .english

    private let environment: AppShellEnvironment?
    private let lifecycleCoordinator: AppLifecycleSecurityCoordinator
    private var unlockedProjectID: ProjectID?
    private var deleteConfirmation: DeleteConfirmation?
    private var unlockedHasImportedDocument = false
    private var unlockedRevisionCount = 0

    private var containmentPolicy: IncidentContainmentPolicy {
        environment?.containmentPolicy ?? .allEnabled
    }

    init(
        environment: AppShellEnvironment? = nil,
        lifecycleCoordinator: AppLifecycleSecurityCoordinator = AppLifecycleSecurityCoordinator()
    ) {
        self.lifecycleCoordinator = lifecycleCoordinator
        if let environment {
            self.environment = environment
        } else {
            do {
                self.environment = try AppShellEnvironment.live()
            } catch {
                self.environment = nil
                bootError = "Failed to initialize local storage: \(error.localizedDescription)"
            }
        }

        Task {
            await refreshLifecycleSecurityState()
            refreshInstalledModelStatus()
            await refreshProjects()
        }
    }

    func beginModelBundleImport() {
        guard isFeatureEnabled(.modelInstallation) else {
            statusMessage = containmentMessage(for: .modelInstallation)
            return
        }
        isModelImporterPresented = true
    }

    func reportModelSelectionFailure(_ error: Error) {
        statusMessage = "Model selection failed: \(error.localizedDescription)"
    }

    func importModelBundle(from sourceURL: URL) async {
        guard let environment else {
            return
        }
        guard isFeatureEnabled(.modelInstallation) else {
            statusMessage = containmentMessage(for: .modelInstallation)
            return
        }

        let accessedSecurityScopedResource = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScopedResource {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let installedModel = try environment.modelInstaller.installBundle(from: sourceURL)
            activeModelDescriptor = installedModel.descriptor
            activeModelBackend = installedModel.backend
            activeModelLicense = installedModel.license
            activeModelProvenance = installedModel.provenance
            statusMessage = "Installed local model \(installedModel.descriptor.displayName)."
        } catch let error as LocalModelBundleInstallerError {
            statusMessage = modelInstallerMessage(error)
        } catch {
            statusMessage = "Model install failed: \(error.localizedDescription)"
        }
    }

    func installBundledStarterModel() async {
        guard let environment else {
            return
        }
        guard isFeatureEnabled(.modelInstallation) else {
            statusMessage = containmentMessage(for: .modelInstallation)
            return
        }

        do {
            let installedModel = try environment.modelInstaller.installBuiltInStarterBundle()
            activeModelDescriptor = installedModel.descriptor
            activeModelBackend = installedModel.backend
            activeModelLicense = installedModel.license
            activeModelProvenance = installedModel.provenance
            statusMessage = "Installed bundled offline starter model \(installedModel.descriptor.displayName)."
        } catch let error as LocalModelBundleInstallerError {
            statusMessage = modelInstallerMessage(error)
        } catch {
            statusMessage = "Bundled model install failed: \(error.localizedDescription)"
        }
    }

    func refreshProjects() async {
        guard let environment else {
            return
        }

        do {
            let summaries = try await environment.repository.listProjects()
            let activeProjectID = unlockedProjectID
            let rows = summaries.map { summary in
                if summary.id == activeProjectID {
                    return ProjectListRow(
                        summary: summary,
                        isUnlocked: true,
                        hasImportedDocument: unlockedHasImportedDocument,
                        revisionCount: unlockedRevisionCount
                    )
                }
                return ProjectListRow(summary: summary, isUnlocked: false)
            }

            projects = rows
            if selectedProjectID == nil {
                selectedProjectID = projects.first?.id
            }
        } catch {
            statusMessage = "Failed to refresh projects: \(error.localizedDescription)"
        }
    }

    func createProject() async {
        guard let environment else {
            return
        }

        let trimmedTitle = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            statusMessage = "Enter a local project title before creating a project."
            return
        }

        do {
            let summary = try await environment.repository.createProject(title: trimmedTitle)
            selectedProjectID = summary.id
            statusMessage = "Created local encrypted project \(summary.id.rawValue)."
            await refreshProjects()
        } catch {
            statusMessage = "Project creation failed: \(error.localizedDescription)"
        }
    }

    func unlockSelectedProject() async {
        guard let environment, let projectID = selectedProjectID else {
            return
        }

        do {
            let snapshot = try await environment.repository.unlockProject(
                projectID: projectID,
                authenticator: environment.authenticator
            )
            unlockedProjectID = projectID
            unlockedHasImportedDocument = snapshot.sourceSnapshotHash != nil
            unlockedRevisionCount = snapshot.revisionIDs.count
            deleteConfirmation = nil
            statusMessage = "Unlocked \(projectID.rawValue) on-device."
            await loadDocument(projectID: projectID)
            await refreshProjects()
        } catch {
            statusMessage = "Unlock failed: \(error.localizedDescription)"
        }
    }

    func lockActiveProject() async {
        guard let environment, let projectID = unlockedProjectID else {
            return
        }

        await environment.repository.lockProject(projectID: projectID)
        await lifecycleCoordinator.lockManually()
        unlockedProjectID = nil
        unlockedHasImportedDocument = false
        unlockedRevisionCount = 0
        currentPages = []
        pendingProposals = []
        activeRevisionID = nil
        deleteConfirmation = nil
        lastExportURL = nil
        lastEncryptedArchiveURL = nil
        isPlainTextExportArmed = false
        statusMessage = "Locked local project \(projectID.rawValue)."
        await refreshLifecycleSecurityState()
        await refreshProjects()
    }

    func importDraft() async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before importing manuscript pages."
            return
        }

        let trimmedText = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            statusMessage = "Paste manuscript content before importing."
            return
        }

        do {
            switch importMode {
            case .plainText:
                try containmentPolicy.requireEnabled(.plainTextImport)
                _ = try await environment.workspaceService.importPlainText(
                    projectID: projectID,
                    text: trimmedText
                )
            case .appleNotes:
                try containmentPolicy.requireEnabled(.appleNotesImport)
                _ = try await environment.workspaceService.importNoteText(
                    projectID: projectID,
                    noteText: trimmedText
                )
                importedSourceFormat = .plainText
            case .localFile:
                statusMessage = "Choose a local TXT, DOCX, or PDF file to import."
                return
            }
            if importMode != .localFile {
                importedSourceFormat = .plainText
            }
            statusMessage = "Imported manuscript pages into \(projectID.rawValue)."
            await loadDocument(projectID: projectID)
            await refreshProjects()
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    func beginFileImport() {
        guard fileImportEnabled else {
            statusMessage = "All local file imports are currently disabled for containment."
            return
        }
        isFileImporterPresented = true
    }

    func beginBackupRestoreImport() {
        guard isFeatureEnabled(.archiveRestore) else {
            statusMessage = containmentMessage(for: .archiveRestore)
            return
        }
        isBackupRestoreImporterPresented = true
    }

    func reportFileSelectionFailure(_ error: Error) {
        statusMessage = "File selection failed: \(error.localizedDescription)"
    }

    func reportBackupSelectionFailure(_ error: Error) {
        statusMessage = "Backup selection failed: \(error.localizedDescription)"
    }

    func importDocumentFile(from sourceURL: URL) async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before importing manuscript files."
            return
        }
        do {
            try containmentPolicy.requireEnabled(importFeature(for: sourceURL))
        } catch let error as IncidentContainmentError {
            statusMessage = containmentMessage(for: error)
            return
        } catch {
            statusMessage = "File import failed: \(error.localizedDescription)"
            return
        }

        let accessedSecurityScopedResource = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScopedResource {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let result = try environment.importCoordinator.import(
                request: DocumentImportRequest(sourceURL: sourceURL)
            )
            defer {
                environment.importCoordinator.cleanup(result: result)
            }

            _ = try await environment.repository.importSourceDocument(
                projectID: projectID,
                document: result.document
            )
            importedSourceFormat = result.format
            statusMessage = "Imported \(result.format.rawValue) manuscript file into \(projectID.rawValue)."
            await loadDocument(projectID: projectID)
            await refreshProjects()
        } catch {
            statusMessage = "File import failed: \(error.localizedDescription)"
        }
    }

    func runProofreadingPass() async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before running proofreading."
            return
        }
        guard isFeatureEnabled(.aiProcessing), isFeatureEnabled(.proofreading) else {
            statusMessage = containmentMessage(for: disabledAIProcessingFeature(for: .proofreading))
            return
        }

        do {
            guard let document = try await environment.workspaceService.currentDocument(projectID: projectID) else {
                statusMessage = "Import a manuscript before running proofreading."
                return
            }

            let proposals = try await proofreadingProposals(
                for: document,
                language: translationSourceLanguage
            )
            pendingProposals = proposalViewData(
                for: proposals,
                in: document,
                proposalKind: .proofreading
            )
            statusMessage = pendingProposals.isEmpty
                ? "No local proofreading revisions were produced for \(translationSourceLanguage.title)."
                : "Prepared \(pendingProposals.count) proofreading revisions for review."
        } catch let error as OnDeviceModelRuntimeError {
            statusMessage = modelRuntimeMessage(error)
        } catch {
            statusMessage = "Proofreading failed: \(error.localizedDescription)"
        }
    }

    func runTranslationDraft() async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before running translation."
            return
        }
        guard isFeatureEnabled(.aiProcessing), isFeatureEnabled(.translation) else {
            statusMessage = containmentMessage(for: disabledAIProcessingFeature(for: .translation))
            return
        }

        do {
            guard let document = try await environment.workspaceService.currentDocument(projectID: projectID) else {
                statusMessage = "Import a manuscript before running translation."
                return
            }

            guard translationSourceLanguage != translationTargetLanguage else {
                statusMessage = "Choose different source and target languages for translation."
                return
            }

            let route = LanguageRoute(
                source: translationSourceLanguage,
                target: translationTargetLanguage
            )
            let proposals = try await translationProposals(
                for: document,
                route: route,
                glossary: Glossary()
            )
            pendingProposals = proposalViewData(
                for: proposals,
                in: document,
                proposalKind: .translation
            )
            statusMessage = pendingProposals.isEmpty
                ? "No local translation revisions were produced for \(route.source.title) to \(route.target.title)."
                : "Prepared \(pendingProposals.count) translation revisions for review."
        } catch let error as OnDeviceModelRuntimeError {
            statusMessage = modelRuntimeMessage(error)
        } catch {
            statusMessage = "Translation failed: \(error.localizedDescription)"
        }
    }

    private func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal] {
        guard let environment else {
            return []
        }

        do {
            return try await environment.onDeviceAIGateway.proofreadingProposals(
                for: document,
                language: language
            )
        } catch let error as AppleOnDeviceAIError {
            guard error.canFallbackToBundledModel else {
                throw error
            }

            do {
                return try environment.aiReviewService.proofreadingProposals(
                    for: document,
                    language: language
                )
            } catch let fallbackError as OnDeviceModelRuntimeError {
                throw error.preferringBundledFallbackFailure(fallbackError)
            }
        }
    }

    private func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal] {
        guard let environment else {
            return []
        }

        do {
            return try await environment.onDeviceAIGateway.translationProposals(
                for: document,
                route: route,
                glossary: glossary
            )
        } catch let error as AppleOnDeviceAIError {
            guard error.canFallbackToBundledModel else {
                throw error
            }

            do {
                return try environment.aiReviewService.translationProposals(
                    for: document,
                    route: route,
                    glossary: glossary
                )
            } catch let fallbackError as OnDeviceModelRuntimeError {
                throw error.preferringBundledFallbackFailure(fallbackError)
            }
        }
    }

    func acceptPendingProposal(_ proposalID: String) async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before accepting revisions."
            return
        }
        guard let proposal = pendingProposals.first(where: { $0.id == proposalID }) else {
            statusMessage = "The selected revision proposal is no longer available."
            return
        }
        guard acceptanceEnabled(for: [proposal]) else {
            statusMessage = containmentMessage(for: disabledAcceptanceFeature(for: [proposal]))
            return
        }

        do {
            _ = try await environment.repository.acceptRevision(
                proposal: AcceptedRevisionProposal(
                    projectID: projectID,
                    segmentID: proposal.segmentID,
                    replacementText: proposal.replacementText,
                    proposalKind: proposal.proposalKind,
                    meaningChange: proposal.meaningChange,
                    compositionChange: proposal.compositionChange
                )
            )
            pendingProposals.removeAll { $0.id == proposalID }
            statusMessage = "Accepted 1 \(proposal.proposalKind.rawValue) revision."
            await loadDocument(projectID: projectID)
            await refreshProjects()
        } catch {
            statusMessage = "Revision acceptance failed: \(error.localizedDescription)"
        }
    }

    func acceptAllPendingProposals() async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before accepting revisions."
            return
        }
        guard !pendingProposals.isEmpty else {
            statusMessage = "There are no pending revisions to accept."
            return
        }
        guard acceptanceEnabled(for: pendingProposals) else {
            statusMessage = containmentMessage(for: disabledAcceptanceFeature(for: pendingProposals))
            return
        }

        do {
            for proposal in pendingProposals {
                _ = try await environment.repository.acceptRevision(
                    proposal: AcceptedRevisionProposal(
                        projectID: projectID,
                        segmentID: proposal.segmentID,
                        replacementText: proposal.replacementText,
                        proposalKind: proposal.proposalKind,
                        meaningChange: proposal.meaningChange,
                        compositionChange: proposal.compositionChange
                    )
                )
            }
            let acceptedCount = pendingProposals.count
            pendingProposals = []
            statusMessage = "Accepted \(acceptedCount) pending revisions."
            await loadDocument(projectID: projectID)
            await refreshProjects()
        } catch {
            statusMessage = "Revision acceptance failed: \(error.localizedDescription)"
        }
    }

    func clearPendingProposals() {
        let clearedCount = pendingProposals.count
        pendingProposals = []
        statusMessage = clearedCount == 0
            ? "There are no pending revisions to clear."
            : "Cleared \(clearedCount) pending revisions without applying them."
    }

    private func modelRuntimeMessage(_ error: OnDeviceModelRuntimeError) -> String {
        switch error {
        case .noInstalledModelBundle(let modelsRootURL):
            return "No local model bundle is installed yet. Add an offline model manifest and weights under \(modelsRootURL.path)."
        case .invalidManifest:
            return "The installed local model manifest is invalid."
        case .unsupportedBackend(let backend):
            return "The installed local model backend \(backend) is not supported by this app build."
        case .unsupportedProofreadingLanguage(let language):
            return "The installed local model does not support proofreading for \(language.title)."
        case .unsupportedTranslationRoute(let route):
            return "The installed local model does not support \(route.source.title) to \(route.target.title) translation."
        case .missingRequiredAsset(let assetName):
            return "The installed local model is missing required asset \(assetName)."
        case .assetDigestMismatch(let assetName):
            return "The installed local model asset digest failed validation for \(assetName)."
        case .invalidBundleData(let assetName):
            return "The installed local model asset \(assetName) could not be decoded."
        case .installRequired(let message):
            return message
        }
    }

    private func proposalViewData(
        for proposals: [AIDocumentProposal],
        in document: CanonicalDocument,
        proposalKind: ProposalKind
    ) -> [PendingProposalViewData] {
        let pageLookup = Dictionary(uniqueKeysWithValues: document.pages.map { ($0.id, $0) })
        let segmentLookup = Dictionary(
            uniqueKeysWithValues: document.pages
                .flatMap(\.segments)
                .map { ($0.id, $0) }
        )

        return proposals.compactMap { proposal in
            guard let segment = segmentLookup[proposal.segmentID] else {
                return nil
            }
            let pageLabel = proposal.pageID
                .flatMap { pageLookup[$0] }
                .map { "Page \($0.pageIndex + 1) • \($0.sourceLabel)" }
                ?? "Unknown Page"
            return PendingProposalViewData(
                id: proposal.segmentID.rawValue + "-" + proposalKind.rawValue,
                segmentID: proposal.segmentID,
                pageID: proposal.pageID,
                pageLabel: pageLabel,
                proposalKind: proposalKind,
                category: proposal.category,
                originalText: segment.text,
                replacementText: proposal.replacementText,
                reason: proposal.reason,
                meaningChange: proposal.meaningChange,
                compositionChange: proposal.compositionChange
            )
        }
    }

    private func isFeatureEnabled(_ feature: AppFeature) -> Bool {
        containmentPolicy.isEnabled(feature)
    }

    private var fileImportEnabled: Bool {
        isFeatureEnabled(.textFileImport)
            || isFeatureEnabled(.docxFileImport)
            || isFeatureEnabled(.pdfFileImport)
    }

    private func importFeature(for sourceURL: URL) -> AppFeature {
        switch sourceURL.pathExtension.lowercased() {
        case "docx":
            return .docxFileImport
        case "pdf":
            return .pdfFileImport
        default:
            return .textFileImport
        }
    }

    private func disabledAIProcessingFeature(for proposalKind: ProposalKind) -> IncidentContainmentError {
        if !isFeatureEnabled(.aiProcessing) {
            return .featureDisabled(.aiProcessing)
        }
        return .featureDisabled(proposalKind.containmentFeature)
    }

    private func acceptanceEnabled(for proposals: [PendingProposalViewData]) -> Bool {
        guard isFeatureEnabled(.aiProcessing) else {
            return false
        }
        return proposals.allSatisfy { proposal in
            isFeatureEnabled(proposal.proposalKind.containmentFeature)
        }
    }

    private func disabledAcceptanceFeature(for proposals: [PendingProposalViewData]) -> IncidentContainmentError {
        if proposals.contains(where: { $0.proposalKind == .translation }) && !isFeatureEnabled(.translation) {
            return .featureDisabled(.translation)
        }
        if proposals.contains(where: { $0.proposalKind == .proofreading }) && !isFeatureEnabled(.proofreading) {
            return .featureDisabled(.proofreading)
        }
        return .featureDisabled(.aiProcessing)
    }

    private func containmentMessage(for feature: AppFeature) -> String {
        containmentMessage(for: IncidentContainmentError.featureDisabled(feature))
    }

    private func containmentMessage(for error: IncidentContainmentError) -> String {
        switch error {
        case .featureDisabled(let feature):
            switch feature {
            case .aiProcessing:
                return "Local AI processing is currently disabled by containment policy."
            case .proofreading:
                return "Local proofreading is currently disabled by containment policy."
            case .translation:
                return "Local translation is currently disabled by containment policy."
            case .modelInstallation:
                return "Local model installation is currently disabled by containment policy."
            case .plainTextImport:
                return "Plain-text import is currently disabled by containment policy."
            case .appleNotesImport:
                return "Apple Notes import is currently disabled by containment policy."
            case .textFileImport:
                return "Text-file import is currently disabled by containment policy."
            case .docxFileImport:
                return "DOCX import is currently disabled by containment policy."
            case .pdfFileImport:
                return "PDF import is currently disabled by containment policy."
            case .decryptedExport:
                return "Decrypted export is currently disabled by containment policy."
            case .archiveRestore:
                return "Archive restore is currently disabled by containment policy."
            }
        }
    }

    private func modelInstallerMessage(_ error: LocalModelBundleInstallerError) -> String {
        switch error {
        case .unsupportedSource:
            return "Choose a signed local model bundle folder."
        case .missingManifest:
            return "The selected local model bundle is missing manifest.json."
        case .invalidManifest:
            return "The selected local model manifest is invalid."
        case .missingLicenseDeclaration:
            return "The selected local model manifest must declare a license before install."
        case .missingProvenanceDeclaration:
            return "The selected local model manifest must declare provenance before install."
        case .missingSignatureDeclaration:
            return "The selected local model manifest is missing required signing metadata."
        case .missingRequiredDigest(let assetName):
            return "The selected local model manifest is missing a required digest for \(assetName)."
        case .unsupportedSignatureAlgorithm(let algorithm):
            return "The selected local model signature algorithm \(algorithm) is not supported by this app build."
        case .untrustedSigner(let signerKeyID):
            return "The selected local model signer \(signerKeyID) is not trusted by this app build."
        case .revokedSigner(let signerKeyID):
            return "The selected local model signer \(signerKeyID) has been revoked by this app build."
        case .invalidSignatureEncoding:
            return "The selected local model signature encoding is invalid."
        case .signatureDigestMismatch:
            return "The selected local model signature digest does not match the signed manifest payload."
        case .signatureVerificationFailed:
            return "The selected local model signature failed verification."
        case .unsupportedBackend(let backend):
            return "The selected local model backend \(backend) is not supported by this app build."
        case .missingRequiredAsset(let assetName):
            return "The selected local model bundle is missing required asset \(assetName)."
        case .invalidProvenanceDocument:
            return "The selected local model provenance document does not match the manifest."
        case .assetDigestMismatch(let assetName):
            return "The selected local model asset digest failed validation for \(assetName)."
        case .undeclaredBundleAsset(let assetName):
            return "The selected local model bundle contains undeclared asset \(assetName)."
        }
    }

    func exportPlainText() async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before exporting."
            return
        }
        guard isFeatureEnabled(.decryptedExport) else {
            statusMessage = containmentMessage(for: .decryptedExport)
            return
        }
        guard isPlainTextExportArmed else {
            statusMessage = "Arm plain-text export first. Decrypted exports leave the encrypted vault."
            return
        }

        do {
            let revisionID = try await environment.workspaceService.latestRevisionID(projectID: projectID)
            let intent = ExportIntent(
                kind: .publishingPlainText,
                projectID: projectID,
                revisionID: revisionID,
                destinationLabel: "Local Files"
            )
            let confirmation = ExportConfirmation(
                exportKind: .publishingPlainText,
                projectID: projectID,
                revisionID: revisionID,
                destinationLabel: "Local Files"
            )
            let artifact = try await environment.exportService.materializeExport(
                intent: intent,
                confirmation: confirmation
            )
            lastExportURL = artifact.fileURL
            isPlainTextExportArmed = false
            statusMessage = "Prepared local export at \(artifact.fileURL.path)."
        } catch {
            statusMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    func armPlainTextExport() {
        guard unlockedProjectID != nil else {
            statusMessage = "Unlock a project before arming plain-text export."
            return
        }

        isPlainTextExportArmed = true
        statusMessage =
            "Plain-text export is armed for a local handoff. Confirm only when you intend to move decrypted text outside the encrypted vault."
    }

    func exportEncryptedArchive() async {
        guard let environment, let projectID = unlockedProjectID else {
            statusMessage = "Unlock a project before exporting an encrypted archive."
            return
        }

        do {
            let data = try await environment.repository.exportEncryptedArchive(projectID: projectID)
            try FileManager.default.createDirectory(
                at: environment.archiveDirectoryURL,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            let fileURL = environment.archiveDirectoryURL
                .appendingPathComponent(projectID.rawValue)
                .appendingPathExtension("yoanbackup")
            try data.write(to: fileURL, options: .atomic)
            lastEncryptedArchiveURL = fileURL
            statusMessage = "Prepared encrypted archive at \(fileURL.path)."
        } catch {
            statusMessage = "Encrypted archive export failed: \(error.localizedDescription)"
        }
    }

    func restoreLastEncryptedArchive() async {
        guard let environment else {
            return
        }
        guard isFeatureEnabled(.archiveRestore) else {
            statusMessage = containmentMessage(for: .archiveRestore)
            return
        }
        guard let archiveURL = lastEncryptedArchiveURL else {
            statusMessage = "Export an encrypted archive before attempting restore."
            return
        }

        do {
            let data = try Data(contentsOf: archiveURL)
            let summary = try await environment.repository.restoreEncryptedArchive(data: data)
            selectedProjectID = summary.id
            statusMessage = "Restored encrypted archive for \(summary.id.rawValue)."
            await refreshProjects()
        } catch {
            statusMessage = "Encrypted archive restore failed: \(error.localizedDescription)"
        }
    }

    func restoreEncryptedArchive(from sourceURL: URL) async {
        guard let environment else {
            return
        }
        guard isFeatureEnabled(.archiveRestore) else {
            statusMessage = containmentMessage(for: .archiveRestore)
            return
        }

        let accessedSecurityScopedResource = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScopedResource {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: sourceURL)
            let summary = try await environment.repository.restoreEncryptedArchive(data: data)
            selectedProjectID = summary.id
            lastEncryptedArchiveURL = sourceURL
            statusMessage = "Restored encrypted archive from \(sourceURL.lastPathComponent)."
            await refreshProjects()
        } catch {
            statusMessage = "Encrypted archive restore failed: \(error.localizedDescription)"
        }
    }

    func armDeleteSelectedProject() {
        guard let environment, let projectID = selectedProjectID else {
            return
        }

        deleteConfirmation = environment.deleteConfirmationValidator.issue(projectID: projectID)
        statusMessage = "Delete is armed for \(projectID.rawValue). Press Delete Again within five minutes to confirm."
    }

    func deleteSelectedProject() async {
        guard let environment, let projectID = selectedProjectID, let deleteConfirmation else {
            statusMessage = "Arm delete before confirming project deletion."
            return
        }

        do {
            try await environment.repository.deleteProject(
                projectID: projectID,
                confirmation: deleteConfirmation,
                authenticator: environment.authenticator
            )
            if unlockedProjectID == projectID {
                unlockedProjectID = nil
                unlockedHasImportedDocument = false
                unlockedRevisionCount = 0
                currentPages = []
                activeRevisionID = nil
            }
            self.deleteConfirmation = nil
            selectedProjectID = nil
            lastExportURL = nil
            isPlainTextExportArmed = false
            if lastEncryptedArchiveURL?.deletingPathExtension().lastPathComponent == projectID.rawValue {
                lastEncryptedArchiveURL = nil
            }
            statusMessage = "Deleted local project \(projectID.rawValue)."
            await refreshProjects()
        } catch {
            statusMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    func handleScenePhaseChange(_ scenePhase: ScenePhase) {
        Task {
            await lifecycleCoordinator.scenePhaseChanged(appScenePhase(for: scenePhase))
            if scenePhase != .active {
                await lockActiveProjectForLifecycle()
            }
            await refreshLifecycleSecurityState()
        }
    }

    private func refreshLifecycleSecurityState() async {
        lifecycleSecurityState = await lifecycleCoordinator.state()
    }

    private func lockActiveProjectForLifecycle() async {
        guard let environment, let projectID = unlockedProjectID else {
            return
        }

        await environment.repository.lockProject(projectID: projectID)
        unlockedProjectID = nil
        unlockedHasImportedDocument = false
        unlockedRevisionCount = 0
        currentPages = []
        pendingProposals = []
        activeRevisionID = nil
        deleteConfirmation = nil
        lastExportURL = nil
        lastEncryptedArchiveURL = nil
        isPlainTextExportArmed = false
        statusMessage = "Locked local project \(projectID.rawValue)."
        await refreshProjects()
    }

    private func appScenePhase(for scenePhase: ScenePhase) -> AppScenePhaseState {
        switch scenePhase {
        case .active:
            .active
        case .inactive:
            .inactive
        case .background:
            .background
        @unknown default:
            .inactive
        }
    }

    private func loadDocument(projectID: ProjectID) async {
        guard let environment else {
            return
        }

        do {
            guard let document = try await environment.workspaceService.currentDocument(projectID: projectID) else {
                currentPages = []
                pendingProposals = []
                activeRevisionID = nil
                return
            }

            currentPages = document.pages.map {
                DocumentPageViewData(
                    id: $0.id,
                    pageIndex: $0.pageIndex,
                    sourceLabel: $0.sourceLabel,
                    segments: $0.segments
                )
            }
            let revisions = try await environment.repository.revisionEvents(projectID: projectID)
            activeRevisionID = revisions.last?.id
            unlockedHasImportedDocument = true
            unlockedRevisionCount = revisions.count
        } catch {
            statusMessage = "Document reload failed: \(error.localizedDescription)"
        }
    }

    private func refreshInstalledModelStatus() {
        guard let environment else {
            return
        }

        do {
            let installedModel = try environment.modelInstaller.installedModel()
            activeModelDescriptor = installedModel.descriptor
            activeModelBackend = installedModel.backend
            activeModelLicense = installedModel.license
            activeModelProvenance = installedModel.provenance
        } catch {
            activeModelDescriptor = nil
            activeModelBackend = nil
            activeModelLicense = nil
            activeModelProvenance = nil
        }
    }

    var currentReviewAlignment: Alignment {
        translationTargetLanguage.isRightToLeft ? .trailing : .leading
    }

    var currentReviewTextAlignment: TextAlignment {
        translationTargetLanguage.isRightToLeft ? .trailing : .leading
    }
}

private extension ProposalKind {
    var containmentFeature: AppFeature {
        switch self {
        case .proofreading:
            return .proofreading
        case .translation:
            return .translation
        case .userEdit:
            return .aiProcessing
        }
    }
}

public struct AppShellView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AppShellViewModel()

    public init() {}

    public var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Projects")
                    .font(.title2.weight(.semibold))
                List(selection: $viewModel.selectedProjectID) {
                    ForEach(viewModel.projects) { project in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(project.id.rawValue)
                                    .font(.headline)
                                if project.isUnlocked {
                                    Text("Unlocked")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.green.opacity(0.15), in: Capsule())
                                }
                            }
                            Text(project.hasImportedDocument ? "Source imported" : "No source imported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Revisions: \(project.revisionCount)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Project title", text: $viewModel.draftTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("Create Project") {
                        Task {
                            await viewModel.createProject()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .navigationTitle("Yoan Translator")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Private On-Device Manuscript Editor")
                        .font(.largeTitle.weight(.bold))
                    Text(viewModel.privacyStatement)
                        .foregroundStyle(.secondary)

                    if let bootError = viewModel.bootError {
                        Text(bootError)
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workspace")
                            .font(.title3.weight(.semibold))
                        Picker("Import Source", selection: $viewModel.importMode) {
                            Text("Plain Text").tag(DraftImportMode.plainText)
                            Text("Apple Notes").tag(DraftImportMode.appleNotes)
                            Text("Local File").tag(DraftImportMode.localFile)
                        }
                        .pickerStyle(.segmented)

                        if viewModel.importMode == .localFile {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Import local manuscript files with the existing offline parser pipeline.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Button("Choose TXT, DOCX, or PDF") {
                                    viewModel.beginFileImport()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        } else {
                            TextEditor(text: $viewModel.draftText)
                                .frame(minHeight: 180)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.quaternary, lineWidth: 1)
                                }
                        }

                        HStack {
                            Button("Unlock", action: unlockSelectedProject)
                            .buttonStyle(.borderedProminent)

                            Button("Lock", action: lockActiveProject)
                            .buttonStyle(.bordered)

                            Button("Import Pages", action: importPages)
                            .buttonStyle(.bordered)
                        }

                        HStack {
                            Button("Proofread French", action: runProofreadingPass)
                            .buttonStyle(.bordered)

                            Button("Translate Draft", action: runTranslationDraft)
                            .buttonStyle(.bordered)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Translation Route")
                                .font(.subheadline.weight(.semibold))
                            HStack {
                                Picker("Source", selection: $viewModel.translationSourceLanguage) {
                                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                                        Text(language.title).tag(language)
                                    }
                                }
                                .pickerStyle(.menu)

                                Picker("Target", selection: $viewModel.translationTargetLanguage) {
                                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                                        Text(language.title).tag(language)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Offline Model")
                                .font(.subheadline.weight(.semibold))
                            if let activeModelDescriptor = viewModel.activeModelDescriptor {
                                Text(activeModelDescriptor.displayName)
                                    .font(.subheadline.weight(.medium))
                                Text("Routes: \(activeModelDescriptor.translationRoutes.count) • Proofreading: \(activeModelDescriptor.proofreadingLanguages.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let backend = viewModel.activeModelBackend {
                                    Text("Backend: \(backend)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if let license = viewModel.activeModelLicense {
                                    Text("License: \(license)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                if let provenance = viewModel.activeModelProvenance {
                                    Text("Provenance: \(provenance)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            } else {
                                Text("No offline model installed.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Button("Install Bundled Starter Model", action: installBundledStarterModel)
                                    .buttonStyle(.borderedProminent)
                                Button("Import External Model Bundle", action: installLocalModel)
                                    .buttonStyle(.bordered)
                            }
                        }

                        HStack {
                            Button("Arm Plain-Text Export", action: armPlainTextExport)
                            .buttonStyle(.bordered)

                            Button("Export Plain Text", action: exportPlainText)
                            .buttonStyle(.bordered)

                            Button("Export Encrypted Backup", action: exportEncryptedBackup)
                            .buttonStyle(.bordered)

                            Button("Restore Backup File", action: restoreBackupFile)
                            .buttonStyle(.bordered)

                            Button("Restore Last Backup", action: restoreLastBackup)
                            .buttonStyle(.bordered)

                            Button("Arm Delete") {
                                viewModel.armDeleteSelectedProject()
                            }
                            .buttonStyle(.bordered)

                            Button("Delete Again", action: deleteSelectedProject)
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Status")
                            .font(.title3.weight(.semibold))
                        Text(viewModel.statusMessage)
                        if let importedSourceFormat = viewModel.importedSourceFormat {
                            Text("Imported source: \(importedSourceFormat.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let revisionID = viewModel.activeRevisionID {
                            Text("Latest revision: \(revisionID.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if viewModel.isPlainTextExportArmed {
                            Text("Plain-text export armed for local handoff only.")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        if let lastExportURL = viewModel.lastExportURL {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastExportURL.path)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                ShareLink(item: lastExportURL) {
                                    Label("Share Plain Text Export", systemImage: "square.and.arrow.up")
                                }
                                .font(.caption)
                            }
                        }
                        if let lastEncryptedArchiveURL = viewModel.lastEncryptedArchiveURL {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastEncryptedArchiveURL.path)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                ShareLink(item: lastEncryptedArchiveURL) {
                                    Label("Share Encrypted Backup", systemImage: "square.and.arrow.up")
                                }
                                .font(.caption)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Pending Review")
                                .font(.title3.weight(.semibold))
                            Spacer()
                            Button("Accept All", action: acceptAllPendingProposals)
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.pendingProposals.isEmpty)
                            Button("Clear", action: clearPendingProposals)
                                .buttonStyle(.bordered)
                                .disabled(viewModel.pendingProposals.isEmpty)
                        }
                        if viewModel.pendingProposals.isEmpty {
                            Text("No pending proofreading or translation revisions.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.pendingProposals) { proposal in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(proposal.pageLabel)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(proposal.proposalKind.rawValue.capitalized) • \(proposal.category.rawValue.capitalized)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Original")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(proposal.originalText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                    Text("Proposed")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(proposal.replacementText)
                                        .multilineTextAlignment(viewModel.currentReviewTextAlignment)
                                        .frame(maxWidth: .infinity, alignment: viewModel.currentReviewAlignment)
                                        .padding(10)
                                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                    Text(proposal.reason)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    HStack {
                                        Button("Accept") {
                                            acceptPendingProposal(proposal.id)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        if proposal.meaningChange || proposal.compositionChange {
                                            Text("Flagged for manual review")
                                                .font(.caption2)
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(.quaternary.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Page Review")
                            .font(.title3.weight(.semibold))
                        if viewModel.currentPages.isEmpty {
                            Text("No manuscript pages loaded.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(viewModel.currentPages) { page in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Page \(page.pageIndex + 1) • \(page.sourceLabel)")
                                        .font(.headline)
                                    ForEach(page.segments, id: \.id) { segment in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(segment.kind.rawValue.capitalized)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(.secondary)
                                            Text(segment.text)
                                                .multilineTextAlignment(viewModel.currentReviewTextAlignment)
                                                .frame(maxWidth: .infinity, alignment: viewModel.currentReviewAlignment)
                                                .padding(12)
                                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Workspace")
        }
        .onChange(of: scenePhase) { _, newValue in
            viewModel.handleScenePhaseChange(newValue)
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.plainText, .pdf, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else {
                    return
                }
                Task {
                    await viewModel.importDocumentFile(from: url)
                }
            case let .failure(error):
                viewModel.reportFileSelectionFailure(error)
            }
        }
        .fileImporter(
            isPresented: $viewModel.isBackupRestoreImporterPresented,
            allowedContentTypes: backupImportContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else {
                    return
                }
                Task {
                    await viewModel.restoreEncryptedArchive(from: url)
                }
            case let .failure(error):
                viewModel.reportBackupSelectionFailure(error)
            }
        }
        .fileImporter(
            isPresented: $viewModel.isModelImporterPresented,
            allowedContentTypes: modelImportContentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else {
                    return
                }
                Task {
                    await viewModel.importModelBundle(from: url)
                }
            case let .failure(error):
                viewModel.reportModelSelectionFailure(error)
            }
        }
        .overlay {
            if viewModel.lifecycleSecurityState.shouldObscureSnapshots {
                ZStack {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    VStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 32))
                        Text("Project Locked")
                            .font(.title3.weight(.semibold))
                        if let reason = viewModel.lifecycleSecurityState.lastLockReason {
                            Text(lockReasonText(reason))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func lockReasonText(_ reason: AppLockReason) -> String {
        switch reason {
        case .backgrounded:
            "Locked after entering the background."
        case .inactivityTimeout:
            "Locked after inactivity."
        case .authenticationInvalidated:
            "Locked after authentication invalidation."
        case .deviceLocked:
            "Locked after device lock."
        case .manualLock:
            "Locked manually."
        }
    }

    private var backupImportContentTypes: [UTType] {
        if let backupType = UTType(filenameExtension: "yoanbackup") {
            return [backupType, .data]
        }
        return [.data]
    }

    private var modelImportContentTypes: [UTType] {
        var types: [UTType] = [.folder]
        if let manifestType = UTType(filenameExtension: "yoanmodel") {
            types.insert(manifestType, at: 0)
        }
        return types
    }

    private func unlockSelectedProject() {
        Task {
            await viewModel.unlockSelectedProject()
        }
    }

    private func lockActiveProject() {
        Task {
            await viewModel.lockActiveProject()
        }
    }

    private func importPages() {
        if viewModel.importMode == .localFile {
            viewModel.beginFileImport()
            return
        }

        Task {
            await viewModel.importDraft()
        }
    }

    private func runProofreadingPass() {
        Task {
            await viewModel.runProofreadingPass()
        }
    }

    private func runTranslationDraft() {
        Task {
            await viewModel.runTranslationDraft()
        }
    }

    private func exportPlainText() {
        Task {
            await viewModel.exportPlainText()
        }
    }

    private func armPlainTextExport() {
        viewModel.armPlainTextExport()
    }

    private func exportEncryptedBackup() {
        Task {
            await viewModel.exportEncryptedArchive()
        }
    }

    private func restoreLastBackup() {
        Task {
            await viewModel.restoreLastEncryptedArchive()
        }
    }

    private func restoreBackupFile() {
        viewModel.beginBackupRestoreImport()
    }

    private func installBundledStarterModel() {
        Task {
            await viewModel.installBundledStarterModel()
        }
    }

    private func installLocalModel() {
        viewModel.beginModelBundleImport()
    }

    private func acceptPendingProposal(_ proposalID: String) {
        Task {
            await viewModel.acceptPendingProposal(proposalID)
        }
    }

    private func acceptAllPendingProposals() {
        Task {
            await viewModel.acceptAllPendingProposals()
        }
    }

    private func clearPendingProposals() {
        viewModel.clearPendingProposals()
    }

    private func deleteSelectedProject() {
        Task {
            await viewModel.deleteSelectedProject()
        }
    }
}
#endif
