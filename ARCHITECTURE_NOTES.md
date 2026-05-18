# NestChord Architecture Notes: Native Swift vs JUCE

Reviewed: 2026-05-18

## Recommendation

Do not migrate NestChord to JUCE right now.

The ultimate product goal is an AUv3 plugin release, with iPad as the primary target. That makes the current native implementation a good fit: it is already using Apple's AUv3 extension model directly, it keeps the iPad UI in SwiftUI, and it avoids adding a C++ framework before the AUv3 behavior has been validated in real hosts.

The best practical path is to continue the current native Swift/SwiftUI AUv3 implementation while keeping the core sequencing contract portable enough that a JUCE processor can be prototyped later. JUCE should be adopted later only if desktop plugin formats, especially VST3/AU on macOS or Windows, become a near-term product requirement, or if real AUv3 host testing shows that the native shell is too costly to harden.

In short:

- Native Swift is the right near-term path for iPad-first product discovery and the tactile Chord Blocks UI.
- JUCE is the right long-term option to keep warm if NestChord becomes a multi-format desktop plugin.
- A full rewrite today would slow the project down before the actual AUv3 host risks have been measured.

## Current Repository Assessment

The project is currently native Swift:

- `project.yml` defines an iOS app target, an iOS AUv3 app-extension target, an iOS unit-test target, and a macOS debug app target.
- `Package.swift` defines pure Swift modules: `CoreMusicTheory`, `VoicingEngine`, `SequencerCore`, and `PluginUI`.
- `PluginUI` is SwiftUI.
- `NestChordAUv3Extension` uses UIKit for the AU view controller, SwiftUI via `UIHostingController`, and `AUAudioUnit`/AudioToolbox for the plugin shell.
- There is no JUCE dependency.
- There is no AudioKit dependency.

The AUv3 target is configured and has a plausible shell:

- `NestChordAudioUnit` subclasses `AUAudioUnit`.
- The extension has empty audio input/output bus arrays, which matches the current MIDI-generator/MIDI-processor direction.
- Host musical context is read through `musicalContextBlock`.
- Transport state is read through `transportStateBlock`.
- MIDI note events are emitted through `midiOutputEventBlock` when available.
- Pattern state is saved/restored through `fullState` and `fullStateForDocument`.

The MIDI and host-sync implementation should be considered partially implemented, not proven:

- The render path converts host beat position and block duration into `MusicalTime`.
- `SequencerEngine` handles loop wrap, discontinuities, transport stops, note-offs, and active-note flushing.
- The macOS debug app has CoreMIDI output through a virtual source named `NestChord Debug Source`.
- Real AUv3 MIDI output still needs validation in hosts such as AUM, Loopy Pro, Logic Pro for iPad, Cubasis, and Drambo.
- The AU render path still needs a real-time-safety audit before this is treated as production-grade.

State/persistence is already reasonably separated:

- `Pattern`, `ChordBlock`, `MusicalTime`, voicing settings, and related domain objects are Codable.
- `PatternStateEnvelope` provides a schema version.
- The AU shell stores JSON data under the stable `NestChordPatternState` key.

Most of the current code is reusable:

- Highly reusable: music theory, voicing, musical time, pattern model, timeline ordering, MIDI event generation, tests, JSON persistence format.
- Native-specific: SwiftUI editor, `PatternStore`, UIKit AU view controller, `AUAudioUnit` shell, CoreMIDI macOS debug sender.
- Not yet reusable across languages: the Swift implementation itself. JUCE would require either a C++ port of the engine or a stable JSON/MIDI contract between Swift and a future C++ implementation.

## JUCE Fit

JUCE is a serious candidate for NestChord's long-term plugin architecture if the product expands beyond iPad AUv3. Official JUCE documentation describes support for building VST, VST3, AU, AUv3, AAX, and LV2 plugins from a single codebase, with CMake or Projucer integration, native IDE support, and MIDI/MPE support.

Relevant official references:

- JUCE features: https://juce.com/features/
- `juce_audio_plugin_client`: https://docs.juce.com/master/group__juce__audio__plugin__client.html
- `juce::AudioProcessor`: https://docs.juce.com/master/classjuce_1_1AudioProcessor.html
- `juce::AudioProcessorValueTreeState`: https://docs.juce.com/master/classjuce_1_1AudioProcessorValueTreeState.html

JUCE would help most with:

- One processor architecture for AUv3, AU, VST3, standalone, and possibly AAX/LV2.
- A familiar professional plugin structure: processor, editor, parameters, state, and MIDI/audio buffers.
- Long-term desktop distribution.
- A C++ real-time processing environment that many plugin engineers already understand.
- Shared validation behavior across plugin wrappers.

JUCE would hurt right now because:

- The most important current product risk is UX, not cross-format distribution.
- The SwiftUI Chord Blocks editor is a strong fit for iPad.
- A JUCE migration means rewriting or porting the already-tested Swift domain modules.
- iPad AUv3 still requires Apple signing, app-extension packaging, host validation, and App Store constraints even with JUCE.
- JUCE does not remove the need to design NestChord's harmonic engine, timing rules, note tracking, or persistence schema.

## Native Architecture Risks To Harden

Before making a framework decision based on fear, the native shell should be tested and tightened:

1. Validate AUv3 discovery and loading in real hosts.
2. Verify that `midiOutputEventBlock` timing works as expected for note-ons and note-offs.
3. Replace the fixed render sample rate with host-provided sample-rate handling.
4. Confirm `transportStateBlock` flag interpretation across multiple hosts.
5. Add handling for host loop/cycle information if available.
6. Connect AU processor state and SwiftUI editor state cleanly so the UI edits the actual AU instance state.
7. Avoid allocations, JSON work, Combine/SwiftUI interaction, and other non-real-time-safe behavior on the render path.
8. Add stress tests for jumps, stops, loop wrap, short blocks, and stuck-note prevention.

These are necessary even if the project later moves to JUCE. JUCE changes the plugin framework, not the musical correctness requirements.

## Decision

Adopt JUCE later, not now.

Continue with the native Swift foundation through the first host-tested iPad AUv3 milestone. The current code is not a throwaway prototype: the pure Swift modules are cleanly isolated, tested, and aligned with the product idea. The AUv3 shell is early, but it is thin enough to harden without a rewrite.

Revisit JUCE after one of these triggers:

- VST3 or desktop standalone becomes part of the next release, not just a future possibility.
- Real AUv3 host testing shows persistent native wrapper problems.
- The project needs a shared macOS/Windows plugin processor.
- The team decides that C++/JUCE is the long-term implementation language for the whole plugin.

Avoid JUCE if:

- The product remains iPad-first for the next several milestones.
- The native AUv3 shell validates cleanly in target hosts.
- Most upcoming work is Chord Blocks UX, music theory, composition workflow, and SwiftUI interaction polish.

## Smallest Safe JUCE Migration Path

If JUCE becomes necessary, do not replace the current project in one move.

1. Freeze the portable domain contract.
   - Keep `PatternStateEnvelope` JSON stable.
   - Add fixture files for representative progressions, including the 4-bar seed and 5-bar odd-loop example.
   - Add golden MIDI-event outputs for known transport windows.

2. Create a separate JUCE spike.
   - Put it under `JUCEPrototype/` or in a sibling repository.
   - Build the smallest MIDI-effect processor that loads a JSON pattern and emits MIDI chord events.
   - Do not port the SwiftUI editor yet.

3. Port only the pure engine surface first.
   - `MusicalTime`
   - `Pattern`/`ChordBlock`
   - Scale and chord derivation
   - Voicing
   - Active-note tracking
   - Sequencer render contract

4. Compare behavior with fixtures.
   - Swift tests remain the reference until the JUCE/C++ engine matches them.
   - The C++ version should produce the same note-ons/note-offs for the same pattern and transport snapshots.

5. Validate plugin behavior in hosts.
   - Test JUCE AUv3 against the same iPad hosts as the native AUv3.
   - Test VST3/AU standalone only after the AUv3 processor proves useful.

6. Decide whether to move the UI.
   - If iPad remains primary, consider keeping a native SwiftUI app/editor and sharing pattern files.
   - If desktop plugins become primary, implement a JUCE editor or a web/native hybrid later.

This path keeps migration reversible. It also makes the decision evidence-based: JUCE wins only if it demonstrably improves host behavior or unlocks formats that matter soon.

## Near-Term Engineering Priority

The next architecture milestone should be host validation, not framework migration:

- Make the AU processor and UI share the same pattern state.
- Verify real MIDI output in at least one iPad host.
- Audit the render path for real-time safety.
- Add host-transport regression tests around the existing `SequencerEngine`.
- Keep the JSON pattern format stable enough that a future JUCE spike can consume it.

That gives NestChord the best chance of becoming a stable professional AUv3 MIDI plugin without prematurely giving up the speed and quality of the native iPad experience.
