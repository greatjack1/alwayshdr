// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AlwaysHDR",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "AlwaysHDR",
            path: "Sources/AlwaysHDR"
        )
    ]
)
