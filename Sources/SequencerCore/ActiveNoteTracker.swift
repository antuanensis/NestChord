import Foundation

public struct ActiveNote: Hashable, Sendable {
    public var noteNumber: UInt8
    public var channel: UInt8
    public var sourceBlockID: UUID?

    public init(noteNumber: UInt8, channel: UInt8, sourceBlockID: UUID?) {
        self.noteNumber = noteNumber
        self.channel = channel
        self.sourceBlockID = sourceBlockID
    }
}

public struct ActiveNoteTracker: Sendable {
    private var activeNotes: Set<ActiveNote> = []

    public init() {}

    public var notes: [ActiveNote] {
        activeNotes.sorted {
            if $0.channel == $1.channel {
                return $0.noteNumber < $1.noteNumber
            }
            return $0.channel < $1.channel
        }
    }

    public var isEmpty: Bool {
        activeNotes.isEmpty
    }

    public mutating func noteOnEvents(
        notes: [Int],
        velocity: UInt8,
        channel: UInt8,
        offset: MusicalTime,
        sourceBlockID: UUID?
    ) -> [MIDINoteEvent] {
        notes.compactMap { noteNumber in
            guard (0...127).contains(noteNumber) else { return nil }
            let note = UInt8(noteNumber)
            let activeNote = ActiveNote(noteNumber: note, channel: channel, sourceBlockID: sourceBlockID)
            activeNotes.insert(activeNote)
            return MIDINoteEvent(
                kind: .noteOn,
                noteNumber: note,
                velocity: velocity,
                channel: channel,
                offset: offset,
                sourceBlockID: sourceBlockID
            )
        }
    }

    public mutating func noteOffEvents(
        for sourceBlockID: UUID,
        offset: MusicalTime
    ) -> [MIDINoteEvent] {
        let matching = notes.filter { $0.sourceBlockID == sourceBlockID }
        for note in matching {
            activeNotes.remove(note)
        }
        return matching.map {
            MIDINoteEvent(
                kind: .noteOff,
                noteNumber: $0.noteNumber,
                velocity: 0,
                channel: $0.channel,
                offset: offset,
                sourceBlockID: $0.sourceBlockID
            )
        }
    }

    public mutating func flushAll(offset: MusicalTime) -> [MIDINoteEvent] {
        let flushed = notes.map {
            MIDINoteEvent(
                kind: .noteOff,
                noteNumber: $0.noteNumber,
                velocity: 0,
                channel: $0.channel,
                offset: offset,
                sourceBlockID: $0.sourceBlockID
            )
        }
        activeNotes.removeAll()
        return flushed
    }
}
