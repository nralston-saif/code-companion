// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CodeCompanion",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CodeCompanion", targets: ["CodeCompanion"])
    ],
    targets: [
        .executableTarget(
            name: "CodeCompanion",
            path: "CodeCompanion"
        )
    ]
)
