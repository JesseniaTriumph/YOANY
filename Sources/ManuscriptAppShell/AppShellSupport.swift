#if canImport(SwiftUI)
import Foundation
import ManuscriptCore

struct AppShellEnvironment {
    let repository: ProjectVaultRepository
    let workspaceService: ProjectWorkspaceService
    let exportService: LocalPublishingExportService
    let importCoordinator: DocumentImportCoordinator
    let aiReviewService: DocumentAIReviewService
    let onDeviceAIGateway: any OnDeviceAIGateway
    let modelInstaller: LocalModelBundleInstaller
    let authenticator: any Authenticator
    let deleteConfirmationValidator: DeleteConfirmationValidator
    let archiveDirectoryURL: URL
    let modelsDirectoryURL: URL
    let containmentPolicy: IncidentContainmentPolicy

    init(
        repository: ProjectVaultRepository,
        workspaceService: ProjectWorkspaceService,
        exportService: LocalPublishingExportService,
        importCoordinator: DocumentImportCoordinator,
        aiReviewService: DocumentAIReviewService,
        onDeviceAIGateway: any OnDeviceAIGateway = AppleOnDeviceAIAdapter(),
        modelInstaller: LocalModelBundleInstaller,
        authenticator: any Authenticator,
        deleteConfirmationValidator: DeleteConfirmationValidator,
        archiveDirectoryURL: URL,
        modelsDirectoryURL: URL,
        containmentPolicy: IncidentContainmentPolicy
    ) {
        self.repository = repository
        self.workspaceService = workspaceService
        self.exportService = exportService
        self.importCoordinator = importCoordinator
        self.aiReviewService = aiReviewService
        self.onDeviceAIGateway = onDeviceAIGateway
        self.modelInstaller = modelInstaller
        self.authenticator = authenticator
        self.deleteConfirmationValidator = deleteConfirmationValidator
        self.archiveDirectoryURL = archiveDirectoryURL
        self.modelsDirectoryURL = modelsDirectoryURL
        self.containmentPolicy = containmentPolicy
    }

    static func live() throws -> AppShellEnvironment {
        let fileManager = FileManager.default
        let appSupportRoot =
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let rootURL = appSupportRoot
            .appendingPathComponent("YoanTranslator", isDirectory: true)
        let vaultURL = rootURL.appendingPathComponent("Vault", isDirectory: true)
        let keyURL = rootURL.appendingPathComponent("Keys", isDirectory: true)
        let modelsURL = rootURL.appendingPathComponent("Models", isDirectory: true)
        let quarantineURL = rootURL.appendingPathComponent("Quarantine", isDirectory: true)
        let exportURL = rootURL.appendingPathComponent("Exports", isDirectory: true)
        let repository = try ProjectVaultRepository(
            rootURL: vaultURL,
            keyWrapping: try FileSystemKeyWrappingService(rootURL: keyURL)
        )

        return try AppShellEnvironment(
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
            onDeviceAIGateway: AppleOnDeviceAIAdapter(),
            modelInstaller: LocalModelBundleInstaller(modelsRootURL: modelsURL),
            authenticator: defaultAuthenticator(),
            deleteConfirmationValidator: DeleteConfirmationValidator(),
            archiveDirectoryURL: exportURL,
            modelsDirectoryURL: modelsURL,
            containmentPolicy: .allEnabled
        )
    }

    private static func defaultAuthenticator() -> any Authenticator {
        #if canImport(LocalAuthentication)
        DeviceOwnerAuthenticator()
        #else
        LocalOnlyAuthenticator()
        #endif
    }
}

struct ProjectListRow: Identifiable {
    let id: ProjectID
    let createdAt: Date
    let updatedAt: Date
    let isUnlocked: Bool
    let hasImportedDocument: Bool
    let revisionCount: Int

    init(
        summary: ProjectSummary,
        isUnlocked: Bool,
        hasImportedDocument: Bool = false,
        revisionCount: Int = 0
    ) {
        id = summary.id
        createdAt = summary.createdAt
        updatedAt = summary.updatedAt
        self.isUnlocked = isUnlocked
        self.hasImportedDocument = hasImportedDocument
        self.revisionCount = revisionCount
    }
}

struct DocumentPageViewData: Identifiable {
    let id: PageID
    let pageIndex: Int
    let sourceLabel: String
    let segments: [DocumentSegment]
}

struct PendingProposalViewData: Identifiable {
    let id: String
    let segmentID: SegmentID
    let pageID: PageID?
    let pageLabel: String
    let proposalKind: ProposalKind
    let category: ProposalCategory
    let originalText: String
    let replacementText: String
    let reason: String
    let meaningChange: Bool
    let compositionChange: Bool
}

extension SupportedLanguage {
    var title: String {
        switch self {
        case .french:
            "French"
        case .english:
            "English"
        case .spanish:
            "Spanish"
        case .portuguese:
            "Portuguese"
        case .arabic:
            "Arabic"
        }
    }

    var isRightToLeft: Bool {
        self == .arabic
    }
}

enum DraftImportMode: String, CaseIterable, Identifiable {
    case plainText
    case appleNotes
    case localFile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plainText:
            "Plain Text"
        case .appleNotes:
            "Apple Notes"
        case .localFile:
            "Local File"
        }
    }
}
#endif
