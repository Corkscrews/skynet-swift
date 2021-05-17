// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skynet",
    platforms: [
        .macOS(.v10_12),
        .iOS("11.4")
    ],
    products: [
        .library(
            name: "Skynet",
            targets: ["Skynet"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.0")),
        .package(url: "https://github.com/pebble8888/ed25519swift.git", from: "1.2.8"),
        .package(name: "TweetNacl", url: "https://github.com/bitmark-inc/tweetnacl-swiftwrap", .upToNextMajor(from: "1.0.0")),
        .package(name: "Mockingjay", url: "https://github.com/saltzmanjoelh/Mockingjay.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Skynet",
            dependencies: ["CryptoSwift", "ed25519swift", "Blake2b", "TweetNacl"]),
        .target(
            name: "Blake2b"),
        .testTarget(
            name: "Skynet_Tests",
            dependencies: ["Skynet", "Blake2b", "Mockingjay"])
    ]
)
