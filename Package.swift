// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NestChord",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "CoreMusicTheory", targets: ["CoreMusicTheory"]),
        .library(name: "VoicingEngine", targets: ["VoicingEngine"]),
        .library(name: "SequencerCore", targets: ["SequencerCore"]),
        .library(name: "PluginUI", targets: ["PluginUI"])
    ],
    targets: [
        .target(name: "CoreMusicTheory"),
        .target(
            name: "VoicingEngine",
            dependencies: ["CoreMusicTheory"]
        ),
        .target(
            name: "SequencerCore",
            dependencies: ["CoreMusicTheory", "VoicingEngine"]
        ),
        .target(
            name: "PluginUI",
            dependencies: ["CoreMusicTheory", "VoicingEngine", "SequencerCore"]
        ),
        .testTarget(
            name: "NestChordCoreTests",
            dependencies: ["CoreMusicTheory", "VoicingEngine", "SequencerCore"]
        )
    ]
)
