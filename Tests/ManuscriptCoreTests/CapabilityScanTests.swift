import Foundation
import Testing

struct CapabilityScanTests {
    @Test func forbiddenCapabilityScanPassesForRepository() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let scriptURL = repositoryRoot.appendingPathComponent("scripts/scan_forbidden_capabilities.sh")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path, repositoryRoot.path]

        try process.run()
        process.waitUntilExit()

        #expect(process.terminationStatus == 0)
    }
}
