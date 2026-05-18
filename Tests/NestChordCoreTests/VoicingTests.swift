import CoreMusicTheory
import Testing
import VoicingEngine

struct VoicingTests {
    @Test
    func testCloseVoicing() {
        let chord = ChordBuilder.diatonicChord(
            in: Scale(key: Key(root: .c), mode: .ionian),
            degree: .one,
            extension: .triad
        )

        let notes = ChordVoicer.midiNotes(for: chord, settings: VoicingSettings(register: .middle))

        #expect(notes == [48, 52, 55])
    }

    @Test
    func testOpenVoicingHasWiderSpan() {
        let chord = ChordBuilder.diatonicChord(
            in: Scale(key: Key(root: .c), mode: .ionian),
            degree: .one,
            extension: .triad
        )

        let close = ChordVoicer.midiNotes(for: chord, settings: VoicingSettings(preset: .close, register: .middle))
        let open = ChordVoicer.midiNotes(for: chord, settings: VoicingSettings(preset: .open, register: .middle))

        #expect(open.last! - open.first! > close.last! - close.first!)
        #expect(open == [48, 55, 64])
    }

    @Test
    func testTriadInversions() {
        let chord = ChordBuilder.diatonicChord(
            in: Scale(key: Key(root: .c), mode: .ionian),
            degree: .one,
            extension: .triad
        )

        #expect(ChordVoicer.midiNotes(
            for: chord,
            settings: VoicingSettings(inversion: .first, register: .middle)
        ) == [52, 55, 60])
        #expect(ChordVoicer.midiNotes(
            for: chord,
            settings: VoicingSettings(inversion: .second, register: .middle)
        ) == [55, 60, 64])
    }

    @Test
    func testSeventhChordThirdInversion() {
        let chord = ChordBuilder.diatonicChord(
            in: Scale(key: Key(root: .c), mode: .ionian),
            degree: .one,
            extension: .seventh
        )

        let notes = ChordVoicer.midiNotes(
            for: chord,
            settings: VoicingSettings(inversion: .third, register: .middle)
        )

        #expect(notes == [59, 60, 64, 67])
    }
}
