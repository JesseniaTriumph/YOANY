// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "YoanTranslator",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ManuscriptCore",
            targets: ["ManuscriptCore"]
        ),
        .library(
            name: "ManuscriptAppShell",
            targets: ["ManuscriptAppShell"]
        ),
    ],
    targets: [
        .target(
            name: "ManuscriptCore"
        ),
        .target(
            name: "ManuscriptAppShell",
            dependencies: ["ManuscriptCore"]
        ),
        .testTarget(
            name: "ManuscriptCoreTests",
            dependencies: ["ManuscriptCore"]
        ),
        .testTarget(
            name: "ManuscriptAppShellTests",
            dependencies: ["ManuscriptAppShell", "ManuscriptCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
