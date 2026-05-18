import CoreMusicTheory
import Foundation

public enum Inversion: Int, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case rootPosition = 0
    case first = 1
    case second = 2
    case third = 3

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .rootPosition: "Root"
        case .first: "1st"
        case .second: "2nd"
        case .third: "3rd"
        }
    }
}

public enum VoicingPreset: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case close
    case open
    case drop2Stub

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .close: "Close"
        case .open: "Open"
        case .drop2Stub: "Drop 2"
        }
    }
}

public enum Register: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case low
    case middle
    case high

    public var id: String { rawValue }

    public var rootOctave: Int {
        switch self {
        case .low: 2
        case .middle: 3
        case .high: 4
        }
    }

    public var displayName: String {
        switch self {
        case .low: "Low"
        case .middle: "Middle"
        case .high: "High"
        }
    }
}

public struct VoicingSettings: Codable, Hashable, Sendable {
    public var inversion: Inversion
    public var preset: VoicingPreset
    public var register: Register

    public init(
        inversion: Inversion = .rootPosition,
        preset: VoicingPreset = .close,
        register: Register = .middle
    ) {
        self.inversion = inversion
        self.preset = preset
        self.register = register
    }
}

public protocol VoiceLeadingStrategy {
    func voice(
        chord: Chord,
        settings: VoicingSettings,
        previousNotes: [Int]?
    ) -> [Int]
}
