// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NoStart",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NoStart", targets: ["NoStart"])
    ],
    targets: [
        .executableTarget(
            name: "NoStart",
            path: "Sources/NoStart"
        )
    ]
)
