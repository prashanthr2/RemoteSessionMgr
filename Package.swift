// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RemoteDeskMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RemoteDeskMac", targets: ["RemoteDeskMac"])
    ],
    dependencies: [
        .package(path: "Vendor/SwiftTerm")
    ],
    targets: [
        .executableTarget(
            name: "RemoteDeskMac",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ]
        ),
        .testTarget(
            name: "RemoteDeskMacTests",
            dependencies: ["RemoteDeskMac"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
