import Foundation

public enum MIDINoteEventKind: String, Codable, Hashable, Sendable {
    case noteOn
    case noteOff
}

public struct MIDINoteEvent: Codable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var kind: MIDINoteEventKind
    public var noteNumber: UInt8
    public var velocity: UInt8
    public var channel: UInt8
    public var offset: MusicalTime
    public var sourceBlockID: UUID?

    public init(
        id: UUID = UUID(),
        kind: MIDINoteEventKind,
        noteNumber: UInt8,
        velocity: UInt8,
        channel: UInt8,
        offset: MusicalTime,
        sourceBlockID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.noteNumber = noteNumber
        self.velocity = velocity
        self.channel = channel
        self.offset = offset
        self.sourceBlockID = sourceBlockID
    }
}

public protocol MIDIOutputSink: AnyObject {
    func send(_ events: [MIDINoteEvent])
}

public final class MockMIDIOutputSink: MIDIOutputSink {
    public private(set) var sentEvents: [MIDINoteEvent]

    public init(sentEvents: [MIDINoteEvent] = []) {
        self.sentEvents = sentEvents
    }

    public func send(_ events: [MIDINoteEvent]) {
        sentEvents.append(contentsOf: events)
    }

    public func reset() {
        sentEvents.removeAll()
    }
}

public enum MIDISampleOffsetMapper: Sendable {
    public static func clampedSampleOffset(
        eventOffset: MusicalTime,
        samplesPerTick: Double,
        frameCount: Int
    ) -> Int64 {
        guard frameCount > 0,
              samplesPerTick.isFinite,
              samplesPerTick > 0 else {
            return 0
        }

        let rawOffset = (Double(eventOffset.ticks) * samplesPerTick).rounded()
        let maximumOffset = Double(max(0, frameCount - 1))
        return Int64(max(0, min(maximumOffset, rawOffset)))
    }
}

public struct HostDiagnostics: Codable, Hashable, Sendable {
    public var tempo: Double
    public var beatPosition: MusicalTime
    public var timeSignature: TimeSignature
    public var isPlaying: Bool
    public var isDiscontinuous: Bool
    public var frameCount: Int
    public var sampleRate: Double
    public var lastMIDIEventCount: Int

    public init(
        tempo: Double,
        beatPosition: MusicalTime,
        timeSignature: TimeSignature,
        isPlaying: Bool,
        isDiscontinuous: Bool,
        frameCount: Int,
        sampleRate: Double,
        lastMIDIEventCount: Int
    ) {
        self.tempo = tempo
        self.beatPosition = beatPosition
        self.timeSignature = timeSignature
        self.isPlaying = isPlaying
        self.isDiscontinuous = isDiscontinuous
        self.frameCount = frameCount
        self.sampleRate = sampleRate
        self.lastMIDIEventCount = lastMIDIEventCount
    }

    public init(
        transport: TransportSnapshot,
        frameCount: Int,
        sampleRate: Double,
        lastMIDIEventCount: Int
    ) {
        self.init(
            tempo: transport.tempo,
            beatPosition: transport.hostBeatPosition,
            timeSignature: transport.timeSignature,
            isPlaying: transport.isPlaying,
            isDiscontinuous: transport.isTransportDiscontinuous,
            frameCount: frameCount,
            sampleRate: sampleRate,
            lastMIDIEventCount: lastMIDIEventCount
        )
    }
}
