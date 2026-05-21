# NestChord

NestChord is a harmonic block sequencer for AUv3 hosts.

Traditional sequencers ask the user to draw notes.
This plugin asks the user to compose with harmonic intention:

- What key am I in?
- What mode am I using?
- Which degree should play?
- For how many bars?
- Should there be silence?
- Which inversion or voicing should express the chord?

The result is a fast, scale-aware, bar-based chord sequencer designed for iPad musicians who want to create complex chord progressions without fighting a piano roll.

## Current Foundation

This repository contains the first MVP foundation:

- Pure Swift music theory, voicing, and sequencing modules.
- Tick-based musical time using 960 ticks per quarter note.
- A default 4-bar C major progression, with the original 5-bar progression available as an example seed.
- A modern SwiftUI Chord Blocks timeline/debug UI shared by the app and AUv3 extension.
- AUv3 MIDI processor shell with host sync, shared editor/processor pattern state, state serialization, and a MIDI output block path.
- Per-block MIDI channel support for generated note events. MIDI CC, program change, and MIDI input are intentionally deferred.
- macOS debug app target with CoreMIDI output for fast external sound-source testing.
- Unit tests for the pure engine.
- XcodeGen `project.yml` as the source of truth for the iOS app and extension project.

## Development

Run pure logic tests with:

```sh
swift test
```

The tests use Swift's built-in test support. On a fresh Mac, install/select full Xcode if the Command Line Tools toolchain cannot import `Testing` or `XCTest`.

Generate the Xcode project with XcodeGen:

```sh
xcodegen generate
```

The local machine must have full Xcode selected, not only Command Line Tools, before `xcodebuild` can build the app or AUv3 extension.

## macOS MIDI Debug App

Build and run the local macOS debug app:

```sh
xcodegen generate
xcodebuild -project NestChord.xcodeproj -scheme NestChordMacDebug -derivedDataPath .derivedData build
open .derivedData/Build/Products/Debug/NestChordMacDebug.app
```

By default it creates a virtual MIDI source named `NestChord Debug Source`. Choose that as a MIDI input in a standalone synth, hardware-routing tool, or DAW, then press `Play` or double-tap a Chord Block in NestChord.

## AUv3 Host Testing

The AUv3 extension is ready for first host validation. Install the iOS app on an iPad, then load `NestChord` as an AUv3 MIDI plugin in a host such as AUM, Loopy Pro, Logic Pro for iPad, Cubasis, or Drambo. Route its MIDI output into an instrument plugin or external synth.

See [Docs/HOST_VALIDATION.md](Docs/HOST_VALIDATION.md) for the full setup, expected results, and troubleshooting checklist.

First host checks:

- edit Chord Blocks in the plugin UI and confirm playback follows the edits
- change a block's MIDI channel and route that channel to a sound source
- test host play, stop, tempo changes, loop jumps, and session save/reopen
- watch for stuck notes when stopping, editing, or jumping transport
