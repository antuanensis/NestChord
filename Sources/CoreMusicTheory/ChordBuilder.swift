import Foundation

public enum ChordBuilder {
    public static func diatonicChord(
        in scale: Scale,
        degree: ScaleDegree,
        extension chordExtension: ChordExtension = .triad
    ) -> Chord {
        let scalePitchClasses = scale.pitchClasses
        let root = scale.pitchClass(for: degree)
        let pitchClasses = (0..<chordExtension.noteCount).map { stackIndex in
            let scaleIndex = (degree.zeroBasedIndex + stackIndex * 2) % scalePitchClasses.count
            return scalePitchClasses[scaleIndex]
        }
        let intervals = pitchClasses.map { interval(from: root, to: $0) }
        let quality = inferQuality(intervals: intervals, extension: chordExtension)

        return Chord(
            root: root,
            degree: degree,
            quality: quality,
            chordExtension: chordExtension,
            pitchClasses: pitchClasses
        )
    }

    public static func diatonicChords(
        in scale: Scale,
        extension chordExtension: ChordExtension = .triad
    ) -> [Chord] {
        ScaleDegree.allCases.map {
            diatonicChord(in: scale, degree: $0, extension: chordExtension)
        }
    }

    private static func inferQuality(intervals: [Int], extension chordExtension: ChordExtension) -> ChordQuality {
        let triad = Array(intervals.prefix(3))
        let seventh = Array(intervals.prefix(4))

        if chordExtension != .triad, seventh.count == 4 {
            switch seventh {
            case [0, 4, 7, 11]:
                return .majorSeventh
            case [0, 4, 7, 10]:
                return .dominantSeventh
            case [0, 3, 7, 10]:
                return .minorSeventh
            case [0, 3, 6, 10]:
                return .halfDiminished
            case [0, 3, 6, 9]:
                return .diminishedSeventh
            default:
                break
            }
        }

        switch triad {
        case [0, 4, 7]:
            return .major
        case [0, 3, 7]:
            return .minor
        case [0, 3, 6]:
            return .diminished
        case [0, 4, 8]:
            return .augmented
        default:
            return .major
        }
    }

    private static func interval(from root: PitchClass, to pitchClass: PitchClass) -> Int {
        let raw = pitchClass.rawValue - root.rawValue
        return raw >= 0 ? raw : raw + 12
    }
}
