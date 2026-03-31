// swift-tools-version:5.9

import PackageDescription
#if os(Linux) || os(Windows)
let platformExcludes = ["Apple", "Mac", "iOS"]
#else
let platformExcludes: [String] = []
#endif

#if os(Windows)
let products: [Product] = [
    .library(
        name: "SwiftTerm",
        targets: ["SwiftTerm"]
    ),
]

let targets: [Target] = [
    .target(
        name: "SwiftTerm",
        dependencies: [],
        path: "Sources/SwiftTerm",
        exclude: platformExcludes + ["Mac/README.md"]
    )
]
#else
let products: [Product] = [
    .library(
        name: "SwiftTerm",
        targets: ["SwiftTerm"]
    ),
]

let targets: [Target] = [
    .target(
        name: "SwiftTerm",
        //
        // We can not use Swift Subprocess, because there is no way of configuring the child process to
        // be a controlling terminal, as it is posix-spawn based.
//        dependencies: [
//            .product(name: "Subprocess", package: "swift-subprocess", condition: .when(platforms: [.macOS, .linux]))
//        ],
        path: "Sources/SwiftTerm",
        exclude: platformExcludes + ["Mac/README.md"],
        resources: [
            .process("Apple/Metal/Shaders.metal")
        ]
    )
]
#endif

let package = Package(
    name: "SwiftTerm",
    platforms: [
        .iOS(.v14),
        .macOS(.v13),
        .tvOS(.v13),
        .visionOS(.v1)
    ],
    products: products,
    dependencies: [],
    targets: targets,
    swiftLanguageVersions: [.v5]
)
