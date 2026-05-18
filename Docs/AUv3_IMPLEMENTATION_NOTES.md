# AUv3 Implementation Notes

NestChord is scaffolded as a MIDI processor AUv3 component (`aumi`) with a SwiftUI view controller and an `AUAudioUnit` subclass.

The render path is intentionally thin:

1. Read tempo, beat position, and time signature from `musicalContextBlock` when the host provides it.
2. Read transport movement/change flags from `transportStateBlock`.
3. Convert host beat position and block duration into `MusicalTime`.
4. Call `SequencerEngine.render(pattern:transport:)`.
5. Send note events through the AU `midiOutputEventBlock`.

The engine flushes active notes when transport stops, jumps, or reports a discontinuity. This is the first guard against stuck notes in hosts.

Chord Block starts are derived from accumulated duration, so host timing only needs to resolve the current loop position and block boundaries.

The current MIDI bridge is deliberately simple and should be validated in Loopy Pro, AUM, Logic Pro for iPad, Cubasis, and Drambo before advanced timing features are layered on top.

## Shared AUv3 State

`NestChordAudioUnit` owns the render pattern in the AUv3 extension. `AudioUnitViewController` connects the SwiftUI `PatternStore` to the created audio unit:

- UI edits publish the updated `Pattern` into the audio unit.
- Host `fullState` restoration replaces the audio unit pattern and pushes the restored pattern back into the visible store.
- The AU render block reads the current pattern through a locked snapshot boundary at render time.
- Pattern changes request a note flush on the next render block so deleted or changed active blocks do not leave old notes hanging.

This is an MVP-safe bridge for first host testing. Before release, the render path should be audited further for lock contention and allocation behavior under heavy host load.

## MIDI Channel Scope

NestChord currently outputs MIDI note-on and note-off events only. Each Chord Block exposes a MIDI channel from 1 to 16. The engine stores the user-facing channel on `MIDINoteEvent`, and the AU bridge maps it to the zero-based MIDI channel bits in the status byte.

Not implemented yet:

- MIDI CC output
- program change
- MIDI input processing
- AU parameter automation
- channel/global routing presets

These should wait until note output, host sync, and state save/restore pass real AUv3 host testing.

## First Host Validation Checklist

Use AUM or Loopy Pro first, then repeat in Logic Pro for iPad, Cubasis, and Drambo:

- Confirm `NestChord: Harmonic Blocks` appears as an AUv3 MIDI component.
- Route NestChord MIDI output into a synth and confirm chords sound.
- Edit Chord Blocks while the plugin is loaded and confirm playback follows the UI edits.
- Change a block's MIDI channel and confirm the target synth receives the expected channel.
- Test host play, stop, tempo changes, loop jumps, and session reload.
- Watch for stuck notes after stop, jump, block delete, duration edit, and session restore.
- Save and reopen a host session and confirm the progression restores correctly.

## macOS Debug MIDI

The `NestChordMacDebug` target is a local-only macOS app for fast iteration before iPad/AUv3 host testing.

- It reuses the SwiftUI Chord Blocks editor.
- It creates a CoreMIDI virtual source named `NestChord Debug Source`.
- It can also send directly to any visible CoreMIDI destination.
- Debug playback is immediate and manual; it does not replace host-synced AUv3 timing.
- It intentionally does not contain a built-in synth. Audio should come from an external app, plugin host, or hardware instrument.
