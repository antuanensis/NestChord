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
