import Foundation

public enum ChordQuality: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case major
    case minor
    case diminished
    case augmented
    case dominantSeventh
    case majorSeventh
    case minorSeventh
    case halfDiminished
    case diminishedSeventh

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .major: "Major"
        case .minor: "Minor"
        case .diminished: "Diminished"
        case .augmented: "Augmented"
        case .dominantSeventh: "Dominant 7"
        case .majorSeventh: "Major 7"
        case .minorSeventh: "Minor 7"
        case .halfDiminished: "Half-diminished"
        case .diminishedSeventh: "Diminished 7"
        }
    }
}

public enum ChordExtension: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case triad
    case seventh
    case ninth
    case eleventh
    case thirteenth

    public var id: String { rawValue }

    public var noteCount: Int {
        switch self {
        case .triad: 3
        case .seventh: 4
        case .ninth: 5
        case .eleventh: 6
        case .thirteenth: 7
        }
    }

    public var displayName: String {
        switch self {
        case .triad: "Triad"
        case .seventh: "Seventh"
        case .ninth: "Ninth"
        case .eleventh: "Eleventh"
        case .thirteenth: "Thirteenth"
        }
    }
}

public struct Chord: Codable, Hashable, Identifiable, Sendable {
    public var id: String {
        "\(degree.rawValue)-\(root.rawValue)-\(quality.rawValue)-\(chordExtension.rawValue)"
    }

    public var root: PitchClass
    public var degree: ScaleDegree
    public var quality: ChordQuality
    public var chordExtension: ChordExtension
    public var pitchClasses: [PitchClass]

    public init(
        root: PitchClass,
        degree: ScaleDegree,
        quality: ChordQuality,
        chordExtension: ChordExtension,
        pitchClasses: [PitchClass]
    ) {
        self.root = root
        self.degree = degree
        self.quality = quality
        self.chordExtension = chordExtension
        self.pitchClasses = pitchClasses
    }

    public var displayName: String {
        "\(degree.romanNumeral(for: quality)) \(quality.displayName)"
    }
}
