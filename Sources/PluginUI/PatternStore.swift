import Combine
import CoreMusicTheory
import Foundation
import SequencerCore
import VoicingEngine

@MainActor
public final class PatternStore: ObservableObject {
    @Published public var pattern: Pattern {
        didSet {
            guard publishesPatternChanges else { return }
            patternDidChange?(pattern)
        }
    }
    @Published public var currentBeat: MusicalTime
    @Published public var isPlaying: Bool
    @Published public var debugEvents: [MIDINoteEvent]
    @Published public var selectedBlockID: UUID?
    @Published public var tempo: Double

    public weak var midiOutputSink: MIDIOutputSink?
    public var patternDidChange: ((Pattern) -> Void)?

    private var engine: SequencerEngine
    private var playbackTimer: Timer?
    private var publishesPatternChanges = true
    private let debugTickDuration = MusicalTime.beats(numerator: 1, denominator: 4)

    public init(
        pattern: Pattern = Pattern.defaultProgression(),
        currentBeat: MusicalTime = .zero,
        isPlaying: Bool = false,
        tempo: Double = 120,
        debugEvents: [MIDINoteEvent] = []
    ) {
        self.pattern = pattern
        self.currentBeat = currentBeat
        self.isPlaying = isPlaying
        self.tempo = tempo
        self.debugEvents = debugEvents
        selectedBlockID = pattern.blocks.first?.id
        engine = SequencerEngine()
    }

    public var selectedBlockIndex: Int? {
        guard let selectedBlockID else { return nil }
        return pattern.blocks.firstIndex { $0.id == selectedBlockID }
    }

    public var loopPosition: MusicalTime {
        Timeline(pattern: pattern).loopPosition(for: currentBeat)
    }

    public var loopProgress: Double {
        guard pattern.loopDuration.ticks > 0 else { return 0 }
        return max(0, min(1, Double(loopPosition.ticks) / Double(pattern.loopDuration.ticks)))
    }

    public var currentBlockID: UUID? {
        Timeline(pattern: pattern).blockCovering(loopPosition: loopPosition)?.id
    }

    public func addChordBlock() {
        let duration = pattern.gridResolution.duration(in: pattern.timeSignature)
        let newBlock = ChordBlock(
            duration: duration,
            kind: .chord,
            degree: .one
        )
        pattern.blocks.append(newBlock)
        selectedBlockID = newBlock.id
    }

    public func duplicateBlock(id: UUID) {
        guard let index = pattern.blocks.firstIndex(where: { $0.id == id }) else { return }
        var duplicate = pattern.blocks[index]
        duplicate.id = UUID()
        pattern.blocks.insert(duplicate, at: index + 1)
        selectedBlockID = duplicate.id
    }

    public func deleteBlock(id: UUID) {
        guard pattern.blocks.count > 1,
              let index = pattern.blocks.firstIndex(where: { $0.id == id }) else {
            return
        }
        pattern.blocks.remove(at: index)
        selectedBlockID = pattern.blocks[min(index, pattern.blocks.count - 1)].id
    }

    public func moveBlock(id sourceID: UUID, before targetID: UUID) {
        guard sourceID != targetID,
              let sourceIndex = pattern.blocks.firstIndex(where: { $0.id == sourceID }),
              let targetIndex = pattern.blocks.firstIndex(where: { $0.id == targetID }) else {
            return
        }

        let moved = pattern.blocks.remove(at: sourceIndex)
        let adjustedTargetIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        pattern.blocks.insert(moved, at: adjustedTargetIndex)
        selectedBlockID = sourceID
    }

    public func resizeBlock(id: UUID, beatDelta: Double) {
        guard let index = pattern.blocks.firstIndex(where: { $0.id == id }) else { return }

        let gridTicks = max(pattern.gridResolution.duration(in: pattern.timeSignature).ticks, MusicalTime.ticksPerQuarterNote / 4)
        let deltaTicks = Int64((beatDelta * Double(MusicalTime.ticksPerQuarterNote)).rounded())
        let snappedDelta = (deltaTicks / gridTicks) * gridTicks
        let minimumDuration = MusicalTime.ticksPerQuarterNote / 4
        let nextTicks = max(minimumDuration, pattern.blocks[index].duration.ticks + snappedDelta)
        pattern.blocks[index].duration = MusicalTime(ticks: nextTicks)
    }

    public func setBlockDuration(id: UUID, duration: MusicalTime) {
        guard let index = pattern.blocks.firstIndex(where: { $0.id == id }) else { return }
        pattern.blocks[index].duration = MusicalTime(ticks: max(1, duration.ticks))
    }

    public func renderDebugStep() {
        let transport = TransportSnapshot(
            hostBeatPosition: currentBeat,
            tempo: tempo,
            isPlaying: isPlaying,
            timeSignature: pattern.timeSignature,
            blockDuration: isPlaying ? debugTickDuration : .beats(1)
        )
        let events = engine.render(pattern: pattern, transport: transport, output: midiOutputSink)
        debugEvents.append(contentsOf: events)
        if isPlaying {
            currentBeat = wrapIfNeeded(currentBeat + transport.blockDuration)
        }
    }

    public func auditionSelectedBlock() {
        guard let index = selectedBlockIndex else { return }

        let blockStart = pattern.positionedBlocks[index].start
        let transport = TransportSnapshot(
            hostBeatPosition: blockStart,
            tempo: tempo,
            isPlaying: true,
            timeSignature: pattern.timeSignature,
            blockDuration: .beats(1),
            isTransportDiscontinuous: true
        )
        debugEvents.append(contentsOf: engine.render(pattern: pattern, transport: transport, output: midiOutputSink))
    }

    public func stopAndFlush() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        let transport = TransportSnapshot(
            hostBeatPosition: currentBeat,
            isPlaying: false,
            timeSignature: pattern.timeSignature,
            blockDuration: .beats(1)
        )
        debugEvents.append(contentsOf: engine.render(pattern: pattern, transport: transport, output: midiOutputSink))
    }

    public func resetDebugTransport() {
        debugEvents.removeAll()
        currentBeat = .zero
        _ = engine.reset()
    }

    public func toggleLocalPlayback() {
        isPlaying ? stopAndFlush() : startLocalPlayback()
    }

    public func startLocalPlayback() {
        playbackTimer?.invalidate()
        isPlaying = true

        let interval = max(0.015, debugTickDuration.beats * 60 / max(tempo, 1))
        playbackTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.renderDebugStep()
            }
        }
        renderDebugStep()
    }

    public func loadDefaultProgression() {
        stopAndFlush()
        pattern = .defaultProgression()
        currentBeat = .zero
        selectedBlockID = pattern.blocks.first?.id
        debugEvents.removeAll()
        _ = engine.reset()
    }

    public func loadFiveBarExample() {
        stopAndFlush()
        pattern = .defaultFiveBarProgression()
        currentBeat = .zero
        selectedBlockID = pattern.blocks.first?.id
        debugEvents.removeAll()
        _ = engine.reset()
    }

    public func encodeState() throws -> Data {
        try PatternStateEnvelope(pattern: pattern).encodedJSON()
    }

    public func restoreState(from data: Data) throws {
        replacePatternFromExternalState(try PatternStateEnvelope.decodeJSON(data).pattern)
    }

    public func replacePatternFromExternalState(_ pattern: Pattern) {
        publishesPatternChanges = false
        self.pattern = pattern
        publishesPatternChanges = true
        currentBeat = .zero
        selectedBlockID = pattern.blocks.first?.id
        debugEvents.removeAll()
        _ = engine.reset()
    }

    private func wrapIfNeeded(_ beat: MusicalTime) -> MusicalTime {
        guard pattern.loopDuration.ticks > 0 else { return beat }
        if beat.ticks >= pattern.loopDuration.ticks {
            return MusicalTime(ticks: beat.ticks % pattern.loopDuration.ticks)
        }
        return beat
    }
}
