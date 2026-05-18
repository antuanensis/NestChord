# Music Theory Engine

The MVP theory engine supports:

- Pitch classes and MIDI note conversion.
- Keys with a pitch-class root.
- Modes: Ionian, Dorian, Phrygian, Lydian, Mixolydian, Aeolian, and Locrian.
- Major as Ionian and natural minor as Aeolian.
- Scale degrees I through VII.
- Diatonic triads and seventh chords derived by stacking scale thirds.

`ChordBuilder` derives chord quality from the pitch-class intervals above the root:

- Major, minor, diminished, augmented triads.
- Major seventh, dominant seventh, minor seventh, half-diminished, and diminished seventh chords.

Extensions up to ninths, elevenths, and thirteenths are represented in the model now. The MVP still treats the seventh quality as the chord-quality basis for extended diatonic chords.
