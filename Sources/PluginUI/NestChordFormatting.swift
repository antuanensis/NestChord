import CoreMusicTheory
import Foundation
import SequencerCore

func nestFormatted(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)))
}

func nestModeShortName(_ mode: Mode) -> String {
    switch mode {
    case .ionian: "Ionian"
    case .dorian: "Dorian"
    case .phrygian: "Phrygian"
    case .lydian: "Lydian"
    case .mixolydian: "Mixolydian"
    case .aeolian: "Aeolian"
    case .locrian: "Locrian"
    }
}

func nestDurationLabel(for block: ChordBlock, in timeSignature: TimeSignature) -> String {
    nestDurationLabel(for: block.duration, in: timeSignature)
}

func nestDurationLabel(for duration: MusicalTime, in timeSignature: TimeSignature) -> String {
    let bars = Double(duration.ticks) / Double(timeSignature.ticksPerBar)
    if abs(bars - 1) < 0.001 {
        return "1 bar"
    }
    return "\(nestFormatted(bars)) bars"
}

func nestChordTitle(for block: ChordBlock, pattern: SequencerCore.Pattern) -> String {
    switch block.kind {
    case .rest:
        return "rest"
    case .hold:
        return "hold"
    case .chord:
        guard let degree = block.degree else { return "chord" }
        let chord = ChordBuilder.diatonicChord(
            in: pattern.scale,
            degree: degree,
            extension: block.chordExtension
        )
        return "\(degree.romanNumeral(for: chord.quality))\(nestQualitySuffix(for: chord, block: block))"
    }
}

func nestQualitySuffix(for chord: Chord, block: ChordBlock) -> String {
    switch block.chordExtension {
    case .triad:
        switch chord.quality {
        case .major: return ""
        case .minor: return "-"
        case .diminished: return "°"
        case .augmented: return "+"
        default: return ""
        }
    case .seventh:
        switch chord.quality {
        case .majorSeventh: return "maj7"
        case .dominantSeventh: return "7"
        case .minorSeventh: return "-7"
        case .halfDiminished: return "ø7"
        case .diminishedSeventh: return "°7"
        default: return "7"
        }
    case .ninth:
        return "9"
    case .eleventh:
        return "11"
    case .thirteenth:
        return "13"
    }
}
