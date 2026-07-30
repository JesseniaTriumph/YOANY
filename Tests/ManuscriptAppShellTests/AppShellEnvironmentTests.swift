import Foundation
import CryptoKit
@testable import ManuscriptAppShell
import ManuscriptCore
import SwiftUI
import Testing

private struct NoChangeModelRuntime: OnDeviceModelRuntime {
    let descriptor: OnDeviceModelDescriptor

    init(
        descriptor: OnDeviceModelDescriptor = OnDeviceModelDescriptor(
            id: ModelID(rawValue: "model_no_change"),
            displayName: "No Change Runtime",
            proofreadingLanguages: [.french],
            translationRoutes: [LanguageRoute(source: .french, target: .english)]
        )
    ) {
        self.descriptor = descriptor
    }

    func activeDescriptor() throws -> OnDeviceModelDescriptor {
        descriptor
    }

    func proofreadingProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        language: SupportedLanguage
    ) throws -> AIDocumentProposal {
        AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .grammar,
            replacementText: segment.text,
            reason: "no-change",
            uncertainty: 0,
            meaningChange: false,
            compositionChange: false
        )
    }

    func translationProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) throws -> AIDocumentProposal {
        AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .translation,
            replacementText: segment.text,
            reason: "no-change",
            uncertainty: 0,
            meaningChange: false,
            compositionChange: false
        )
    }
}

private struct ReplacementModelRuntime: OnDeviceModelRuntime {
    let descriptor = OnDeviceModelDescriptor(
        id: ModelID(rawValue: "model_replacement"),
        displayName: "Replacement Runtime",
        proofreadingLanguages: [.french],
        translationRoutes: [LanguageRoute(source: .french, target: .english)]
    )

    func activeDescriptor() throws -> OnDeviceModelDescriptor {
        descriptor
    }

    func proofreadingProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        language: SupportedLanguage
    ) throws -> AIDocumentProposal {
        AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .grammar,
            replacementText: segment.text.replacingOccurrences(of: " .", with: "."),
            reason: "replacement",
            uncertainty: 0,
            meaningChange: false,
            compositionChange: false
        )
    }

    func translationProposal(
        for segment: DocumentSegment,
        in document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) throws -> AIDocumentProposal {
        AIDocumentProposal(
            segmentID: segment.id,
            pageID: segment.pageID,
            category: .translation,
            replacementText: segment.text
                .replacingOccurrences(of: "Bonjour", with: "Hello")
                .replacingOccurrences(of: "monde", with: "world"),
            reason: "replacement",
            uncertainty: 0,
            meaningChange: false,
            compositionChange: false
        )
    }
}

private struct StubOnDeviceAIGateway: OnDeviceAIGateway {
    var proofreadingResult: Result<[AIDocumentProposal], Error> = .failure(AppleOnDeviceAIError.proofreadingFrameworkUnavailable)
    var translationResult: Result<[AIDocumentProposal], Error> = .failure(AppleOnDeviceAIError.translationFrameworkUnavailable)

    func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal] {
        try proofreadingResult.get()
    }

    func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal] {
        try translationResult.get()
    }
}

private struct AppleSuccessTranslationGateway: OnDeviceAIGateway {
    func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal] {
        throw AppleOnDeviceAIError.proofreadingFrameworkUnavailable
    }

    func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal] {
        guard let segment = document.pages.first?.segments.first else {
            return []
        }

        return [
            AIDocumentProposal(
                segmentID: segment.id,
                pageID: segment.pageID,
                category: .translation,
                replacementText: "Hello from Apple.",
                reason: "apple",
                uncertainty: 0,
                meaningChange: false,
                compositionChange: false
            )
        ]
    }
}

private struct AppleSuccessProofreadingGateway: OnDeviceAIGateway {
    func proofreadingProposals(
        for document: CanonicalDocument,
        language: SupportedLanguage
    ) async throws -> [AIDocumentProposal] {
        guard let segment = document.pages.first?.segments.first else {
            return []
        }

        return [
            AIDocumentProposal(
                segmentID: segment.id,
                pageID: segment.pageID,
                category: .grammar,
                replacementText: "Bonjour monde.",
                reason: "apple-proofreading",
                uncertainty: 0,
                meaningChange: false,
                compositionChange: false
            )
        ]
    }

    func translationProposals(
        for document: CanonicalDocument,
        route: LanguageRoute,
        glossary: Glossary
    ) async throws -> [AIDocumentProposal] {
        throw AppleOnDeviceAIError.translationFrameworkUnavailable
    }
}

struct AppShellEnvironmentTests {
    @Test
    func liveAppEnvironmentUsesFileSystemKeyWrapping() throws {
        let rootURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let wrapping = try FileSystemKeyWrappingService(rootURL: rootURL)
        let projectID = ProjectID.make()
        let key = SymmetricKey(size: .bits256)
        let wrapped = try wrapping.wrap(projectID: projectID, key: key)
        let unwrapped = try wrapping.unwrap(projectID: projectID, wrappedKey: wrapped)

        #expect(key.withUnsafeBytes { Data($0) } == unwrapped.withUnsafeBytes { Data($0) })
    }

    @Test
    @MainActor
    func scenePhaseChangeUpdatesPrivacyObscuringState() async throws {
        let coordinator = AppLifecycleSecurityCoordinator()
        let viewModel = AppShellViewModel(
            environment: nil,
            lifecycleCoordinator: coordinator
        )

        try await Task.sleep(for: .milliseconds(50))
        #expect(viewModel.lifecycleSecurityState.shouldObscureSnapshots == false)
        #expect(viewModel.lifecycleSecurityState.scenePhase == .active)

        viewModel.handleScenePhaseChange(.inactive)
        try await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.lifecycleSecurityState.shouldObscureSnapshots == true)
        #expect(viewModel.lifecycleSecurityState.scenePhase == .inactive)
    }

    @Test
    @MainActor
    func exportEncryptedArchiveWritesBackupArtifact() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: NoChangeModelRuntime()),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.exportEncryptedArchive()

        let archiveURL = try #require(viewModel.lastEncryptedArchiveURL)
        #expect(FileManager.default.fileExists(atPath: archiveURL.path))
    }

    @Test
    @MainActor
    func beginBackupRestoreImportPresentsPicker() {
        let viewModel = AppShellViewModel(environment: nil)

        #expect(viewModel.isBackupRestoreImporterPresented == false)
        viewModel.beginBackupRestoreImport()
        #expect(viewModel.isBackupRestoreImporterPresented == true)
    }

    @Test
    @MainActor
    func bundledStarterModelInstallUpdatesVisibleModelStatus() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(
                runtime: InstalledModelManifestRuntime(modelsRootURL: modelsURL)
            ),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.installBundledStarterModel()

        #expect(viewModel.activeModelDescriptor?.displayName == "Bundled Starter Rules")
        #expect(viewModel.activeModelBackend == "bundle-rules-v1")
        #expect(viewModel.activeModelLicense == "Bundled local starter ruleset")
        #expect(viewModel.activeModelProvenance == "Repository bundled offline starter asset")
    }

    @Test
    @MainActor
    func plainTextExportMustBeArmedBeforeExporting() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: NoChangeModelRuntime()),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        await viewModel.exportPlainText()

        #expect(viewModel.lastExportURL == nil)
        #expect(viewModel.isPlainTextExportArmed == false)

        viewModel.armPlainTextExport()
        #expect(viewModel.isPlainTextExportArmed == true)

        await viewModel.exportPlainText()

        #expect(viewModel.lastExportURL != nil)
        #expect(viewModel.isPlainTextExportArmed == false)
    }

    @Test
    @MainActor
    func translationPassStagesPendingProposalUntilAccepted() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: ReplacementModelRuntime()),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        await viewModel.runTranslationDraft()

        #expect(viewModel.pendingProposals.count == 1)
        #expect(viewModel.currentPages.first?.segments.first?.text == "Bonjour monde.")

        await viewModel.acceptAllPendingProposals()

        #expect(viewModel.pendingProposals.isEmpty)
        #expect(viewModel.currentPages.first?.segments.first?.text == "Hello world.")
    }

    @Test
    @MainActor
    func translationPassPrefersAppleOnDeviceGatewayWhenAvailable() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: ReplacementModelRuntime()),
            onDeviceAIGateway: AppleSuccessTranslationGateway(),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        await viewModel.runTranslationDraft()

        #expect(viewModel.pendingProposals.count == 1)
        #expect(viewModel.pendingProposals.first?.replacementText == "Hello from Apple.")
    }

    @Test
    @MainActor
    func translationPassFallsBackToBundledRuntimeWhenAppleGatewayUnavailable() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: ReplacementModelRuntime()),
            onDeviceAIGateway: StubOnDeviceAIGateway(
                translationResult: .failure(AppleOnDeviceAIError.translationFrameworkUnavailable)
            ),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        await viewModel.runTranslationDraft()

        #expect(viewModel.pendingProposals.count == 1)
        #expect(viewModel.pendingProposals.first?.replacementText == "Hello world.")
    }

    @Test
    @MainActor
    func proofreadingPassPrefersAppleOnDeviceGatewayWhenAvailable() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: ReplacementModelRuntime()),
            onDeviceAIGateway: AppleSuccessProofreadingGateway(),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        await viewModel.runProofreadingPass()

        #expect(viewModel.pendingProposals.count == 1)
        #expect(viewModel.pendingProposals.first?.replacementText == "Bonjour monde.")
    }

    @Test
    @MainActor
    func proofreadingPassFallsBackToBundledRuntimeWhenAppleGatewayUnavailable() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: ReplacementModelRuntime()),
            onDeviceAIGateway: StubOnDeviceAIGateway(
                proofreadingResult: .failure(AppleOnDeviceAIError.proofreadingFrameworkUnavailable)
            ),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        viewModel.draftText = "Bonjour monde ."
        await viewModel.importDraft()
        await viewModel.runProofreadingPass()

        #expect(viewModel.pendingProposals.count == 1)
        #expect(viewModel.pendingProposals.first?.replacementText == "Bonjour monde.")
    }

    @Test
    @MainActor
    func containmentPolicyCanDisableBundledModelInstallation() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(
                runtime: InstalledModelManifestRuntime(modelsRootURL: modelsURL)
            ),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: IncidentContainmentPolicy(disabledFeatures: [.modelInstallation])
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.installBundledStarterModel()

        #expect(viewModel.activeModelDescriptor == nil)
        #expect(viewModel.statusMessage == "Local model installation is currently disabled by containment policy.")
    }

    @Test
    @MainActor
    func containmentPolicyCanDisableTranslationPass() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: ReplacementModelRuntime()),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: IncidentContainmentPolicy(disabledFeatures: [.translation])
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        await viewModel.runTranslationDraft()

        #expect(viewModel.pendingProposals.isEmpty)
        #expect(viewModel.statusMessage == "Local translation is currently disabled by containment policy.")
    }

    @Test
    @MainActor
    func containmentPolicyCanDisableDecryptedExport() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: NoChangeModelRuntime()),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: IncidentContainmentPolicy(disabledFeatures: [.decryptedExport])
        )
        let viewModel = AppShellViewModel(environment: environment)

        await viewModel.createProject()
        await viewModel.unlockSelectedProject()
        await viewModel.importDraft()
        viewModel.armPlainTextExport()
        await viewModel.exportPlainText()

        #expect(viewModel.lastExportURL == nil)
        #expect(viewModel.statusMessage == "Decrypted export is currently disabled by containment policy.")
    }

    @Test
    @MainActor
    func containmentPolicyCanDisableArchiveRestorePicker() async throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
        let environment = try AppShellEnvironment(
            repository: repository,
            workspaceService: ProjectWorkspaceService(repository: repository),
            exportService: LocalPublishingExportService(
                repository: repository,
                stagingRootURL: exportURL
            ),
            importCoordinator: DocumentImportCoordinator(
                quarantine: ImportQuarantine(rootURL: quarantineURL)
            ),
            aiReviewService: DocumentAIReviewService(runtime: NoChangeModelRuntime()),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: LocalOnlyAuthenticator(sessionDuration: 120),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: IncidentContainmentPolicy(disabledFeatures: [.archiveRestore])
        )
        let viewModel = AppShellViewModel(environment: environment)

        viewModel.beginBackupRestoreImport()

        #expect(viewModel.isBackupRestoreImporterPresented == false)
        #expect(viewModel.statusMessage == "Archive restore is currently disabled by containment policy.")
    }
}
