import CoreMusicTheory
import Foundation
import VoicingEngine

public struct TransportSnapshot: Sendable {
    public var hostBeatPosition: MusicalTime
    public var tempo: Double
    public var isPlaying: Bool
    public var timeSignature: TimeSignature
    public var blockDuration: MusicalTime
    public var isTransportDiscontinuous: Bool

    public init(
        hostBeatPosition: MusicalTime,
        tempo: Double = 120,
        isPlaying: Bool,
        timeSignature: TimeSignature = .fourFour,
        blockDuration: MusicalTime = .beats(1),
        isTransportDiscontinuous: Bool = false
    ) {
        self.hostBeatPosition = hostBeatPosition
        self.tempo = tempo
        self.isPlaying = isPlaying
        self.timeSignature = timeSignature
        self.blockDuration = blockDuration
        self.isTransportDiscontinuous = isTransportDiscontinuous
    }

    public static func blockDuration(frameCount: Int, sampleRate: Double, tempo: Double) -> MusicalTime {
        guard sampleRate > 0, tempo > 0 else { return .zero }
        let seconds = Double(frameCount) / sampleRate
        let beats = seconds * tempo / 60
        return MusicalTime(beats: beats)
    }
}

public struct SequencerEngine: Sendable {
    private enum BoundaryKind: Int {
        case noteOff = 0
        case noteOn = 1
    }

    private struct Boundary {
        var absoluteTime: MusicalTime
        var block: ChordBlock
        var kind: BoundaryKind
    }

    public private(set) var activeNoteTracker: ActiveNoteTracker
    private var previousBlockEnd: MusicalTime?
    private var wasPlaying: Bool

    public init(
        activeNoteTracker: ActiveNoteTracker = ActiveNoteTracker()
    ) {
        self.activeNoteTracker = activeNoteTracker
        previousBlockEnd = nil
        wasPlaying = false
    }

    public mutating func render(
        pattern: Pattern,
        transport: TransportSnapshot,
        output: MIDIOutputSink? = nil
    ) -> [MIDINoteEvent] {
        var renderedEvents: [MIDINoteEvent] = []

        guard transport.isPlaying else {
            renderedEvents.append(contentsOf: activeNoteTracker.flushAll(offset: .zero))
            previousBlockEnd = nil
            wasPlaying = false
            output?.send(renderedEvents)
            return renderedEvents
        }

        let blockStart = transport.hostBeatPosition
        let blockEnd = blockStart + transport.blockDuration
        let expectedStart = previousBlockEnd
        let discontinuous = transport.isTransportDiscontinuous ||
            expectedStart.map { abs($0.ticks - blockStart.ticks) > 1 } == true

        if discontinuous {
            renderedEvents.append(contentsOf: activeNoteTracker.flushAll(offset: .zero))
        }

        if discontinuous || !wasPlaying {
            renderedEvents.append(contentsOf: activateCoveringChordIfNeeded(
                pattern: pattern,
                absoluteTime: blockStart
            ))
        }

        let boundaries = scheduledBoundaries(
            pattern: pattern,
            blockStart: blockStart,
            blockEnd: blockEnd
        )

        for boundary in boundaries {
            let offset = boundary.absoluteTime - blockStart
            switch boundary.kind {
            case .noteOff:
                renderedEvents.append(contentsOf: activeNoteTracker.noteOffEvents(
                    for: boundary.block.id,
                    offset: offset
                ))
            case .noteOn:
                renderedEvents.append(contentsOf: activeNoteTracker.noteOffEvents(
                    for: boundary.block.id,
                    offset: offset
                ))
                renderedEvents.append(contentsOf: noteOnEvents(for: boundary.block, pattern: pattern, offset: offset))
            }
        }

        previousBlockEnd = blockEnd
        wasPlaying = true
        output?.send(renderedEvents)
        return renderedEvents
    }

    public mutating func reset() -> [MIDINoteEvent] {
        previousBlockEnd = nil
        wasPlaying = false
        return activeNoteTracker.flushAll(offset: .zero)
    }

    private mutating func activateCoveringChordIfNeeded(
        pattern: Pattern,
        absoluteTime: MusicalTime
    ) -> [MIDINoteEvent] {
        let timeline = Timeline(pattern: pattern)
        let loopPosition = timeline.loopPosition(for: absoluteTime)
        guard let positioned = timeline.blockCovering(loopPosition: loopPosition),
              positioned.block.kind == .chord else {
            return []
        }
        return noteOnEvents(for: positioned.block, pattern: pattern, offset: .zero)
    }

    private mutating func noteOnEvents(
        for block: ChordBlock,
        pattern: Pattern,
        offset: MusicalTime
    ) -> [MIDINoteEvent] {
        guard block.kind == .chord,
              block.probability > 0,
              let degree = block.degree else {
            return []
        }

        let chord = ChordBuilder.diatonicChord(
            in: pattern.scale,
            degree: degree,
            extension: block.chordExtension
        )
        let midiNotes = ChordVoicer.midiNotes(for: chord, settings: block.voicing)

        return activeNoteTracker.noteOnEvents(
            notes: midiNotes,
            velocity: block.velocity,
            channel: block.midiChannel,
            offset: offset,
            sourceBlockID: block.id
        )
    }

    private func scheduledBoundaries(
        pattern: Pattern,
        blockStart: MusicalTime,
        blockEnd: MusicalTime
    ) -> [Boundary] {
        guard pattern.loopDuration.ticks > 0 else { return [] }

        var boundaries: [Boundary] = []
        for positioned in pattern.positionedBlocks where positioned.block.kind == .chord {
            boundaries.append(contentsOf: occurrences(
                loopBoundary: positioned.start,
                block: positioned.block,
                kind: .noteOn,
                pattern: pattern,
                blockStart: blockStart,
                blockEnd: blockEnd
            ))
            boundaries.append(contentsOf: occurrences(
                loopBoundary: positioned.end,
                block: positioned.block,
                kind: .noteOff,
                pattern: pattern,
                blockStart: blockStart,
                blockEnd: blockEnd
            ))
        }

        return boundaries.sorted {
            if $0.absoluteTime == $1.absoluteTime {
                return $0.kind.rawValue < $1.kind.rawValue
            }
            return $0.absoluteTime < $1.absoluteTime
        }
    }

    private func occurrences(
        loopBoundary: MusicalTime,
        block: ChordBlock,
        kind: BoundaryKind,
        pattern: Pattern,
        blockStart: MusicalTime,
        blockEnd: MusicalTime
    ) -> [Boundary] {
        let loopTicks = pattern.loopDuration.ticks
        guard loopTicks > 0 else { return [] }

        var occurrenceTick = loopBoundary.ticks + ((blockStart.ticks - loopBoundary.ticks) / loopTicks - 1) * loopTicks
        var result: [Boundary] = []

        while occurrenceTick < blockEnd.ticks {
            if occurrenceTick >= blockStart.ticks {
                result.append(Boundary(
                    absoluteTime: MusicalTime(ticks: occurrenceTick),
                    block: block,
                    kind: kind
                ))
            }
            occurrenceTick += loopTicks
        }

        return result
    }
}
