import Foundation

public enum PitchClass: Int, CaseIterable, Codable, Hashable, Identifiable, Comparable, Sendable {
    case c = 0
    case cSharp = 1
    case d = 2
    case dSharp = 3
    case e = 4
    case f = 5
    case fSharp = 6
    case g = 7
    case gSharp = 8
    case a = 9
    case aSharp = 10
    case b = 11

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .c: "C"
        case .cSharp: "C#"
        case .d: "D"
        case .dSharp: "D#"
        case .e: "E"
        case .f: "F"
        case .fSharp: "F#"
        case .g: "G"
        case .gSharp: "G#"
        case .a: "A"
        case .aSharp: "A#"
        case .b: "B"
        }
    }

    public static func < (lhs: PitchClass, rhs: PitchClass) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public init(midiNoteNumber: Int) {
        self = PitchClass(rawValue: Self.modulo(midiNoteNumber, 12)) ?? .c
    }

    public func transposed(by semitones: Int) -> PitchClass {
        PitchClass(rawValue: Self.modulo(rawValue + semitones, 12)) ?? .c
    }

    public func midiNoteNumber(octave: Int) -> Int {
        ((octave + 1) * 12) + rawValue
    }

    private static func modulo(_ value: Int, _ modulus: Int) -> Int {
        let result = value % modulus
        return result >= 0 ? result : result + modulus
    }
}
