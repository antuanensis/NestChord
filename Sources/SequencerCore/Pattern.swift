import CoreMusicTheory
import Foundation
import VoicingEngine

public enum ChordBlockKind: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case chord
    case rest
    case hold

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chord: "Chord"
        case .rest: "Rest"
        case .hold: "Hold"
        }
    }
}

public struct ChordBlock: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var duration: MusicalTime
    public var kind: ChordBlockKind
    public var degree: ScaleDegree?
    public var chordExtension: ChordExtension
    public var voicing: VoicingSettings
    public var velocity: UInt8
    public var midiChannel: UInt8
    public var probability: Double
    public var tags: [String]

    public init(
        id: UUID = UUID(),
        duration: MusicalTime,
        kind: ChordBlockKind,
        degree: ScaleDegree? = nil,
        chordExtension: ChordExtension = .triad,
        voicing: VoicingSettings = VoicingSettings(),
        velocity: UInt8 = 96,
        midiChannel: UInt8 = 1,
        probability: Double = 1,
        tags: [String] = []
    ) {
        self.id = id
        self.duration = duration
        self.kind = kind
        self.degree = degree
        self.chordExtension = chordExtension
        self.voicing = voicing
        self.velocity = velocity
        self.midiChannel = midiChannel
        self.probability = probability
        self.tags = tags
    }

    public var isRest: Bool {
        get { kind == .rest }
        set { kind = newValue ? .rest : .chord }
    }
}

public struct PositionedChordBlock: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID { block.id }
    public var block: ChordBlock
    public var index: Int
    public var start: MusicalTime

    public init(block: ChordBlock, index: Int, start: MusicalTime) {
        self.block = block
        self.index = index
        self.start = start
    }

    public var end: MusicalTime {
        start + block.duration
    }
}

public struct Pattern: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var key: Key
    public var mode: Mode
    public var timeSignature: TimeSignature
    public var loopLengthBars: Int
    public var gridResolution: GridResolution
    public var blocks: [ChordBlock]

    public init(
        id: UUID = UUID(),
        name: String,
        key: Key,
        mode: Mode,
        timeSignature: TimeSignature = .fourFour,
        loopLengthBars: Int,
        gridResolution: GridResolution,
        blocks: [ChordBlock]
    ) {
        self.id = id
        self.name = name
        self.key = key
        self.mode = mode
        self.timeSignature = timeSignature
        self.loopLengthBars = loopLengthBars
        self.gridResolution = gridResolution
        self.blocks = blocks
    }

    public var scale: Scale {
        Scale(key: key, mode: mode)
    }

    public var loopDuration: MusicalTime {
        MusicalTime.bars(Int64(loopLengthBars), timeSignature: timeSignature)
    }

    public var totalBlockDuration: MusicalTime {
        blocks.reduce(.zero) { $0 + $1.duration }
    }

    public var positionedBlocks: [PositionedChordBlock] {
        var start = MusicalTime.zero
        return blocks.enumerated().map { index, block in
            let positioned = PositionedChordBlock(block: block, index: index, start: start)
            start = start + block.duration
            return positioned
        }
    }

    public static func defaultProgression() -> Pattern {
        let timeSignature = TimeSignature.fourFour
        let bar = MusicalTime.bars(1, timeSignature: timeSignature)

        let one = ChordBlock(
            duration: bar,
            kind: .chord,
            degree: .one,
            chordExtension: .triad
        )
        let six = ChordBlock(
            duration: bar,
            kind: .chord,
            degree: .six,
            chordExtension: .triad
        )
        let four = ChordBlock(
            duration: bar,
            kind: .chord,
            degree: .four,
            chordExtension: .triad
        )
        let five = ChordBlock(
            duration: bar,
            kind: .chord,
            degree: .five,
            chordExtension: .triad
        )

        return Pattern(
            name: "NestChord 4-Bar Seed",
            key: .cMajor,
            mode: .ionian,
            timeSignature: timeSignature,
            loopLengthBars: 4,
            gridResolution: .quarterBar,
            blocks: [one, six, four, five]
        )
    }

    public static func defaultFiveBarProgression() -> Pattern {
        let timeSignature = TimeSignature.fourFour
        let bar = MusicalTime.bars(1, timeSignature: timeSignature)
        let halfBar = MusicalTime.bars(numerator: 1, denominator: 2, timeSignature: timeSignature)
        let oneAndHalfBars = MusicalTime.bars(numerator: 3, denominator: 2, timeSignature: timeSignature)

        return Pattern(
            name: "NestChord 5-Bar Example",
            key: .cMajor,
            mode: .ionian,
            timeSignature: timeSignature,
            loopLengthBars: 5,
            gridResolution: .halfBar,
            blocks: [
                ChordBlock(duration: oneAndHalfBars, kind: .chord, degree: .two, chordExtension: .triad),
                ChordBlock(duration: bar, kind: .rest),
                ChordBlock(duration: halfBar, kind: .chord, degree: .five, chordExtension: .triad),
                ChordBlock(duration: MusicalTime.bars(2, timeSignature: timeSignature), kind: .chord, degree: .one, chordExtension: .triad)
            ]
        )
    }
}
