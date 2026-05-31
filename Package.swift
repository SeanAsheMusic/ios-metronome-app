// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "iOSMetronomeApp",
    products: [
        .library(name: "RhythmModel", targets: ["RhythmModel"]),
        .library(name: "AudioEngine", targets: ["AudioEngine"])
    ],
    targets: [
        .target(name: "RhythmModel"),
        .target(name: "AudioEngine", dependencies: ["RhythmModel"]),
        .testTarget(name: "RhythmModelTests", dependencies: ["RhythmModel"]),
        .testTarget(name: "AudioEngineTests", dependencies: ["AudioEngine", "RhythmModel"])
    ]
)
