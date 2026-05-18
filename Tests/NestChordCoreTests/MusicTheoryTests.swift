import CoreMusicTheory
import Testing

struct MusicTheoryTests {
    @Test
    func testMajorScalePitchClasses() {
        let scale = Scale(key: Key(root: .c), mode: .ionian)

        #expect(scale.pitchClasses == [.c, .d, .e, .f, .g, .a, .b])
    }

    @Test
    func testModeGeneration() {
        let scale = Scale(key: Key(root: .d), mode: .dorian)

        #expect(scale.pitchClasses == [.d, .e, .f, .g, .a, .b, .c])
    }

    @Test
    func testDiatonicTriadsInMajor() {
        let scale = Scale(key: Key(root: .c), mode: .ionian)
        let chords = ChordBuilder.diatonicChords(in: scale, extension: .triad)

        #expect(chords.map(\.quality) == [
            .major,
            .minor,
            .minor,
            .major,
            .major,
            .minor,
            .diminished
        ])
    }

    @Test
    func testDiatonicSeventhChordsInMajor() {
        let scale = Scale(key: Key(root: .c), mode: .ionian)
        let chords = ChordBuilder.diatonicChords(in: scale, extension: .seventh)

        #expect(chords.map(\.quality) == [
            .majorSeventh,
            .minorSeventh,
            .minorSeventh,
            .majorSeventh,
            .dominantSeventh,
            .minorSeventh,
            .halfDiminished
        ])
    }

    @Test
    func testDegreeToChordMapping() {
        let scale = Scale(key: Key(root: .c), mode: .ionian)
        let chord = ChordBuilder.diatonicChord(in: scale, degree: .two, extension: .triad)

        #expect(chord.root == .d)
        #expect(chord.quality == .minor)
        #expect(chord.pitchClasses == [.d, .f, .a])
    }
}
