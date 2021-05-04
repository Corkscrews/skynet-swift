// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skynet",
    platforms: [
        .macOS(.v10_12), 
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "Skynet",
            targets: ["Skynet"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.0")),
        .package(url: "https://github.com/pebble8888/ed25519swift.git", from: "1.2.7"),
    ],
    targets: [
        .target(
            name: "Skynet",
            dependencies: ["CryptoSwift", "ed25519swift"]),
        .target(
            name: "Blake2b"),
        .testTarget(
            name: "Skynet_Tests",
            dependencies: ["Skynet"])
    ]
)
