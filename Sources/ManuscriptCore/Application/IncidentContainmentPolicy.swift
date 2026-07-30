import Foundation

public enum AppFeature: String, Codable, CaseIterable, Hashable, Sendable {
    case aiProcessing
    case proofreading
    case translation
    case modelInstallation
    case plainTextImport
    case appleNotesImport
    case textFileImport
    case docxFileImport
    case pdfFileImport
    case decryptedExport
    case archiveRestore
}

public enum IncidentContainmentError: Error, Equatable, Sendable {
    case featureDisabled(AppFeature)
}

public struct IncidentContainmentPolicy: Codable, Equatable, Sendable {
    public let disabledFeatures: Set<AppFeature>

    public init(disabledFeatures: Set<AppFeature> = []) {
        self.disabledFeatures = disabledFeatures
    }

    public static let allEnabled = IncidentContainmentPolicy()

    public func isEnabled(_ feature: AppFeature) -> Bool {
        !disabledFeatures.contains(feature)
    }

    public func requireEnabled(_ feature: AppFeature) throws {
        guard isEnabled(feature) else {
            throw IncidentContainmentError.featureDisabled(feature)
        }
    }

    public func requireAllEnabled(_ features: [AppFeature]) throws {
        for feature in features {
            try requireEnabled(feature)
        }
    }
}

