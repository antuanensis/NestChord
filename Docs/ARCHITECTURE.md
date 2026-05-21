# Architecture

NestChord is split into pure logic modules and host-facing shells.

## Modules

- `CoreMusicTheory`: pitch classes, keys, modes, scale degrees, chord qualities, chord extensions, and diatonic chord derivation.
- `VoicingEngine`: inversions, close/open voicings, register selection, and the `VoiceLeadingStrategy` extension point.
- `SequencerCore`: tick-based musical time, ordered Chord Blocks, validation, transport snapshots, note tracking, and MIDI note event generation.
- `PluginUI`: SwiftUI pattern editor, event editor, validation display, and debug render controls.
- `NestChordApp`: a small iOS container for local editing/debugging.
- `NestChordAUv3Extension`: AUv3 MIDI processor shell, host sync, state persistence, and MIDI output bridge.

The sequencing engine has no dependency on AUv3 APIs. It receives a `Pattern` and `TransportSnapshot`, then returns deterministic `MIDINoteEvent` values. This keeps timing behavior testable without launching a host.

Chord Blocks are stored in playback order. The engine computes each block start by accumulating durations from the beginning of the progression. This keeps the UI simple: drag-reordering changes array order, not absolute MIDI positions.

## State

`PatternStateEnvelope` wraps Codable pattern state with a schema version. The AUv3 extension stores encoded JSON under the stable `NestChordPatternState` key in `fullState` and `fullStateForDocument`.

In the standalone app and macOS debug app, `PatternStore` owns the editable pattern and drives local debug rendering. In the AUv3 extension, `NestChordAudioUnit` owns the render pattern. The SwiftUI `PatternStore` is connected to that audio unit and publishes UI edits back into the AU instance, while host-restored state is pushed from the AU instance back into the visible store.

The AUv3 render block reads the current pattern through a small locked snapshot boundary. UI and host state writes replace the stored pattern outside the musical decision code. This is suitable for the MVP host-validation pass, but the render path still needs a dedicated real-time-safety audit before release.

For host validation, the AUv3 render path also publishes lightweight `HostDiagnostics` snapshots back to the UI. These are read-only observations of host tempo, beat, meter, transport state, frame count, sample rate, discontinuity state, and recent MIDI output count. They are intended for debugging host behavior, not for musical decision-making.

## MIDI Scope

The MVP outputs MIDI note-on and note-off events only. Each `ChordBlock` has a `midiChannel` value in the user-facing 1...16 range; generated `MIDINoteEvent` values preserve that channel, and the AU MIDI bridge converts it to the zero-based channel bits required by MIDI status bytes.

MIDI CC, program change, MIDI input processing, AU parameters, and host automation are intentionally deferred until basic AUv3 note output, host sync, and state restoration are validated in real hosts.
