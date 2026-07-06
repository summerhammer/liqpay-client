// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LiqPayClient",
    // Vapor's own manifest requires macOS 10.15+ when built on Apple platforms. This entry only
    // constrains Apple-platform deployment targets — SwiftPM's `platforms` list doesn't include
    // Linux at all, so it has no effect on Linux builds (which always target the host toolchain).
    platforms: [.macOS(.v10_15)],
    products: [
        .library(
            name: "LiqPayClient",
            targets: ["LiqPayClient"]
        ),
        .library(
            name: "LiqPayClientVapor",
            targets: ["LiqPayClientVapor"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "4.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.10.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.121.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LiqPayClient",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "LiqPayClientVapor",
            dependencies: [
                "LiqPayClient",
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .testTarget(
            name: "LiqPayClientTests",
            dependencies: ["LiqPayClient"]
        ),
        .testTarget(
            name: "LiqPayClientVaporTests",
            dependencies: [
                "LiqPayClientVapor",
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
