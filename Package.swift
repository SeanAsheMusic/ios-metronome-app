// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "iOSMetronomeApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RhythmModel", targets: ["RhythmModel"]),
        .library(name: "AudioEngine", targets: ["AudioEngine"]),
        .library(name: "BeatCoach", targets: ["BeatCoach"]),
        .library(name: "MIDIConnectivity", targets: ["MIDIConnectivity"]),
        .library(name: "Persistence", targets: ["Persistence"])
    ],
    targets: [
        .target(name: "RhythmModel"),
        .target(name: "AudioEngine", dependencies: ["RhythmModel"]),
        .target(name: "BeatCoach"),
        .target(name: "MIDIConnectivity", dependencies: ["RhythmModel"]),
        .target(name: "Persistence", dependencies: ["AudioEngine", "RhythmModel"]),
        .testTarget(name: "RhythmModelTests", dependencies: ["RhythmModel"]),
        .testTarget(name: "AudioEngineTests", dependencies: ["AudioEngine", "RhythmModel"]),
        .testTarget(name: "BeatCoachTests", dependencies: ["BeatCoach"]),
        .testTarget(name: "MIDIConnectivityTests", dependencies: ["MIDIConnectivity", "RhythmModel"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "RhythmModel"])
    ]
)
