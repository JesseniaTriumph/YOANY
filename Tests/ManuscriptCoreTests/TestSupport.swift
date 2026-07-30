import Foundation
@testable import ManuscriptCore

struct RepositoryFixture {
    let rootURL: URL
    let repository: ProjectVaultRepository

    init() throws {
        rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        repository = try ProjectVaultRepository(
            rootURL: rootURL,
            keyWrapping: InMemoryKeyWrappingService()
        )
    }

    func packageURL(for projectID: ProjectID) -> URL {
        rootURL.appendingPathComponent(projectID.rawValue).appendingPathExtension("projectvault")
    }
}
