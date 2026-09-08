// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Fantasy",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FantasyKit", targets: ["FantasyKit"]),
        .library(name: "FantasyApp", targets: ["FantasyApp"])
    ],
    targets: [
        .target(
            name: "FantasyKit",
            dependencies: [],
            path: "Sources/FantasyKit"
        ),
        .target(
            name: "FantasyApp",
            dependencies: ["FantasyKit"],
            path: "Sources/FantasyApp"
        )
    ]
)
