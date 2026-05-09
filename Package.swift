// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MUZIP",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MUZIP", targets: ["MUZIP"])
    ],
    targets: [
        .executableTarget(
            name: "MUZIP",
            path: "Sources"
        )
    ]
)
