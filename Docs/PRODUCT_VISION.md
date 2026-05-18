# Product Vision

NestChord is not a piano roll. It is a harmonic block sequencer for musicians who think in bars, keys, modes, degrees, and tension rather than individual MIDI note rectangles.

The core workflow is:

- Choose a key and mode.
- Set a loop length, including odd lengths such as 3, 5, 7, or 9 bars.
- Arrange Chord Blocks on a horizontal harmonic timeline.
- Let the engine turn scale degrees, inversions, voicings, and durations into MIDI chords.

The first product promise is speed: a user can express "ii for one and a half bars, rest, V, I" directly. The longer-term promise is compositional intelligence: borrowed chords, substitutions, voice leading, generative variation, and natural language pattern generation should all operate on Chord Blocks, not raw MIDI notes.

## Interaction Model

Build chord progressions like arranging clips, not drawing notes.

- Tap a Chord Block to edit it.
- Drag a Chord Block to reorder playback.
- Drag the right edge to resize its musical duration.
- Double tap to audition.
- Use the plus button to append a new block at the end.

Playback order is array order. Timing is accumulated from each block duration, so reordering harmony never requires manually editing note positions.
