import Foundation

public struct MusicalTime: Codable, Hashable, Comparable, Sendable {
    public static let ticksPerQuarterNote: Int64 = 960
    public static let zero = MusicalTime(ticks: 0)

    public var ticks: Int64

    public init(ticks: Int64) {
        self.ticks = ticks
    }

    public init(beats: Double) {
        ticks = Int64((beats * Double(Self.ticksPerQuarterNote)).rounded())
    }

    public init(beatsNumerator: Int64, beatsDenominator: Int64 = 1) {
        precondition(beatsDenominator != 0, "MusicalTime denominator cannot be zero.")
        ticks = beatsNumerator * Self.ticksPerQuarterNote / beatsDenominator
    }

    public var beats: Double {
        Double(ticks) / Double(Self.ticksPerQuarterNote)
    }

    public static func beats(_ value: Int64) -> MusicalTime {
        MusicalTime(beatsNumerator: value)
    }

    public static func beats(numerator: Int64, denominator: Int64) -> MusicalTime {
        MusicalTime(beatsNumerator: numerator, beatsDenominator: denominator)
    }

    public static func bars(
        _ value: Int64,
        timeSignature: TimeSignature
    ) -> MusicalTime {
        MusicalTime(ticks: value * timeSignature.ticksPerBar)
    }

    public static func bars(
        numerator: Int64,
        denominator: Int64,
        timeSignature: TimeSignature
    ) -> MusicalTime {
        precondition(denominator != 0, "MusicalTime denominator cannot be zero.")
        return MusicalTime(ticks: numerator * timeSignature.ticksPerBar / denominator)
    }

    public static func < (lhs: MusicalTime, rhs: MusicalTime) -> Bool {
        lhs.ticks < rhs.ticks
    }

    public static func + (lhs: MusicalTime, rhs: MusicalTime) -> MusicalTime {
        MusicalTime(ticks: lhs.ticks + rhs.ticks)
    }

    public static func - (lhs: MusicalTime, rhs: MusicalTime) -> MusicalTime {
        MusicalTime(ticks: lhs.ticks - rhs.ticks)
    }
}

public struct TimeSignature: Codable, Hashable, Sendable {
    public var numerator: Int
    public var denominator: Int

    public init(numerator: Int = 4, denominator: Int = 4) {
        self.numerator = numerator
        self.denominator = denominator
    }

    public static let fourFour = TimeSignature(numerator: 4, denominator: 4)

    public var ticksPerBar: Int64 {
        Int64(numerator) * MusicalTime.ticksPerQuarterNote * 4 / Int64(denominator)
    }

    public var beatsPerBar: Double {
        Double(ticksPerBar) / Double(MusicalTime.ticksPerQuarterNote)
    }
}

public enum GridResolution: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case bar
    case halfBar
    case quarterBar
    case quarterNote
    case eighthNote
    case sixteenthNote
    case quarterTriplet
    case eighthTriplet

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bar: "Bar"
        case .halfBar: "1/2 Bar"
        case .quarterBar: "1/4 Bar"
        case .quarterNote: "1/4 Note"
        case .eighthNote: "1/8 Note"
        case .sixteenthNote: "1/16 Note"
        case .quarterTriplet: "1/4 Triplet"
        case .eighthTriplet: "1/8 Triplet"
        }
    }

    public func duration(in timeSignature: TimeSignature) -> MusicalTime {
        switch self {
        case .bar:
            MusicalTime(ticks: timeSignature.ticksPerBar)
        case .halfBar:
            MusicalTime(ticks: timeSignature.ticksPerBar / 2)
        case .quarterBar:
            MusicalTime(ticks: timeSignature.ticksPerBar / 4)
        case .quarterNote:
            .beats(1)
        case .eighthNote:
            .beats(numerator: 1, denominator: 2)
        case .sixteenthNote:
            .beats(numerator: 1, denominator: 4)
        case .quarterTriplet:
            .beats(numerator: 2, denominator: 3)
        case .eighthTriplet:
            .beats(numerator: 1, denominator: 3)
        }
    }
}
