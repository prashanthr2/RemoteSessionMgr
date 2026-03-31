// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RemoteSessionMgr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "RemoteSessionMgr", targets: ["RemoteSessionMgr"])
    ],
    dependencies: [
        .package(path: "Vendor/SwiftTerm")
    ],
    targets: [
        .executableTarget(
            name: "RemoteSessionMgr",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "Sources/RemoteSessionMgr"
        ),
        .testTarget(
            name: "RemoteSessionMgrTests",
            dependencies: ["RemoteSessionMgr"],
            path: "Tests/RemoteSessionMgrTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
