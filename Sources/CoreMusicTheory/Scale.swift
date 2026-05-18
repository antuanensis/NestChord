import Foundation

public struct Key: Codable, Hashable, Sendable {
    public var root: PitchClass

    public init(root: PitchClass) {
        self.root = root
    }

    public static let cMajor = Key(root: .c)
}

public enum Mode: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case ionian
    case dorian
    case phrygian
    case lydian
    case mixolydian
    case aeolian
    case locrian

    public static let major: Mode = .ionian
    public static let naturalMinor: Mode = .aeolian

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .ionian: "Ionian / Major"
        case .dorian: "Dorian"
        case .phrygian: "Phrygian"
        case .lydian: "Lydian"
        case .mixolydian: "Mixolydian"
        case .aeolian: "Aeolian / Natural Minor"
        case .locrian: "Locrian"
        }
    }

    public var semitonePattern: [Int] {
        switch self {
        case .ionian: [0, 2, 4, 5, 7, 9, 11]
        case .dorian: [0, 2, 3, 5, 7, 9, 10]
        case .phrygian: [0, 1, 3, 5, 7, 8, 10]
        case .lydian: [0, 2, 4, 6, 7, 9, 11]
        case .mixolydian: [0, 2, 4, 5, 7, 9, 10]
        case .aeolian: [0, 2, 3, 5, 7, 8, 10]
        case .locrian: [0, 1, 3, 5, 6, 8, 10]
        }
    }
}

public struct Scale: Codable, Hashable, Sendable {
    public var key: Key
    public var mode: Mode

    public init(key: Key, mode: Mode) {
        self.key = key
        self.mode = mode
    }

    public var pitchClasses: [PitchClass] {
        mode.semitonePattern.map { key.root.transposed(by: $0) }
    }

    public func pitchClass(for degree: ScaleDegree) -> PitchClass {
        pitchClasses[degree.zeroBasedIndex]
    }
}

public enum ScaleDegree: Int, CaseIterable, Codable, Hashable, Identifiable, Comparable, Sendable {
    case one = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7

    public var id: Int { rawValue }
    public var zeroBasedIndex: Int { rawValue - 1 }

    public static func < (lhs: ScaleDegree, rhs: ScaleDegree) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var plainRomanNumeral: String {
        switch self {
        case .one: "I"
        case .two: "II"
        case .three: "III"
        case .four: "IV"
        case .five: "V"
        case .six: "VI"
        case .seven: "VII"
        }
    }

    public func romanNumeral(for quality: ChordQuality) -> String {
        let base = plainRomanNumeral
        switch quality {
        case .major, .augmented, .dominantSeventh, .majorSeventh:
            return quality == .augmented ? "\(base)+" : base
        case .minor, .minorSeventh:
            return base.lowercased()
        case .diminished, .halfDiminished, .diminishedSeventh:
            let suffix = quality == .halfDiminished ? "ø" : "°"
            return "\(base.lowercased())\(suffix)"
        }
    }
}
