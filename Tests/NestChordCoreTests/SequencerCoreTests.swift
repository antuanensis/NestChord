import CoreMusicTheory
import SequencerCore
import Testing
import VoicingEngine

struct SequencerCoreTests {
    @Test
    func testTimelineAccumulatesPlaybackOrder() {
        let timeSignature = TimeSignature.fourFour
        let first = ChordBlock(
            duration: MusicalTime.bars(1, timeSignature: timeSignature),
            kind: .chord,
            degree: .one
        )
        let second = ChordBlock(
            duration: MusicalTime.bars(1, timeSignature: timeSignature),
            kind: .chord,
            degree: .two
        )
        let pattern = Pattern(
            name: "Overlap",
            key: .cMajor,
            mode: .ionian,
            timeSignature: timeSignature,
            loopLengthBars: 2,
            gridResolution: .quarterNote,
            blocks: [second, first]
        )

        #expect(pattern.positionedBlocks.map(\.id) == [second.id, first.id])
        #expect(pattern.positionedBlocks.map(\.start) == [.zero, .beats(4)])
        #expect(PatternValidator.validate(pattern).isEmpty)
    }

    @Test
    func testDefaultPatternHasFiveBarLoopAndOnePointFiveBarEvent() {
        let pattern = Pattern.defaultFiveBarProgression()

        #expect(pattern.loopLengthBars == 5)
        #expect(pattern.loopDuration == .beats(20))
        #expect(pattern.positionedBlocks.first?.block.duration == .beats(6))
    }

    @Test
    func testNoteGenerationAtChordStart() {
        let pattern = Pattern.defaultFiveBarProgression()
        var engine = SequencerEngine()

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true)
        )

        #expect(events.map(\.kind) == [.noteOn, .noteOn, .noteOn])
        #expect(events.map(\.noteNumber) == [50, 53, 57])
    }

    @Test
    func testNoteOffAtChordEnd() {
        let pattern = Pattern.defaultFiveBarProgression()
        var engine = SequencerEngine()
        _ = engine.render(pattern: pattern, transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true))

        for beat in 1...5 {
            _ = engine.render(
                pattern: pattern,
                transport: TransportSnapshot(hostBeatPosition: .beats(Int64(beat)), isPlaying: true)
            )
        }

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .beats(6), isPlaying: true)
        )

        #expect(events.map(\.kind) == [.noteOff, .noteOff, .noteOff])
        #expect(Set(events.map(\.noteNumber)) == Set([50, 53, 57]))
    }

    @Test
    func testRestProducesNoNoteOn() {
        let pattern = Pattern.defaultFiveBarProgression()
        var engine = SequencerEngine()
        _ = engine.render(pattern: pattern, transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true))
        _ = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .beats(6), isPlaying: true, isTransportDiscontinuous: true)
        )

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .beats(7), isPlaying: true)
        )

        #expect(events.filter { $0.kind == .noteOn }.isEmpty)
    }

    @Test
    func testOddLengthLoopWraparound() {
        let pattern = Pattern.defaultFiveBarProgression()
        var engine = SequencerEngine()

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(
                hostBeatPosition: .beats(19),
                isPlaying: true,
                blockDuration: .beats(2),
                isTransportDiscontinuous: true
            )
        )

        let offsetOneBeat = events.filter { $0.offset == .beats(1) }
        #expect(offsetOneBeat.filter { $0.kind == .noteOff }.count == 3)
        #expect(offsetOneBeat.filter { $0.kind == .noteOn }.map(\.noteNumber) == [50, 53, 57])
    }

    @Test
    func testTransportStopFlushesActiveNotes() {
        let pattern = Pattern.defaultFiveBarProgression()
        var engine = SequencerEngine()
        _ = engine.render(pattern: pattern, transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true))

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .beats(1), isPlaying: false)
        )

        #expect(events.map(\.kind) == [.noteOff, .noteOff, .noteOff])
    }

    @Test
    func testTransportJumpFlushesAndStartsNewChord() {
        let pattern = Pattern.defaultFiveBarProgression()
        var engine = SequencerEngine()
        _ = engine.render(pattern: pattern, transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true))

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(
                hostBeatPosition: .beats(10),
                isPlaying: true,
                isTransportDiscontinuous: true
            )
        )

        #expect(events.filter { $0.kind == .noteOff }.count == 3)
        #expect(events.filter { $0.kind == .noteOn }.map(\.noteNumber) == [55, 59, 62])
    }

    @Test
    func testMockOutputSinkReceivesRenderedEvents() {
        let pattern = Pattern.defaultFiveBarProgression()
        let sink = MockMIDIOutputSink()
        var engine = SequencerEngine()

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true),
            output: sink
        )

        #expect(sink.sentEvents == events)
    }

    @Test
    func testPatternJSONRoundTripPreservesMIDIChannel() throws {
        var pattern = Pattern.defaultProgression()
        pattern.blocks[0].midiChannel = 7

        let data = try PatternStateEnvelope(pattern: pattern).encodedJSON()
        let restored = try PatternStateEnvelope.decodeJSON(data).pattern

        #expect(restored.blocks[0].midiChannel == 7)
    }

    @Test
    func testNoteGenerationUsesConfiguredMIDIChannel() {
        var pattern = Pattern.defaultProgression()
        pattern.blocks[0].midiChannel = 11
        var engine = SequencerEngine()

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true)
        )

        #expect(events.filter { $0.kind == .noteOn }.map(\.channel) == [11, 11, 11])
    }

    @Test
    func testTransportStopFlushesNotesOnConfiguredMIDIChannel() {
        var pattern = Pattern.defaultProgression()
        pattern.blocks[0].midiChannel = 3
        var engine = SequencerEngine()
        _ = engine.render(pattern: pattern, transport: TransportSnapshot(hostBeatPosition: .zero, isPlaying: true))

        let events = engine.render(
            pattern: pattern,
            transport: TransportSnapshot(hostBeatPosition: .beats(1), isPlaying: false)
        )

        #expect(events.map(\.kind) == [.noteOff, .noteOff, .noteOff])
        #expect(events.map(\.channel) == [3, 3, 3])
    }

    @Test
    func testMIDISampleOffsetClamping() {
        let samplesPerTick = 0.5

        #expect(MIDISampleOffsetMapper.clampedSampleOffset(
            eventOffset: MusicalTime(ticks: -10),
            samplesPerTick: samplesPerTick,
            frameCount: 128
        ) == 0)

        #expect(MIDISampleOffsetMapper.clampedSampleOffset(
            eventOffset: MusicalTime(ticks: 20),
            samplesPerTick: samplesPerTick,
            frameCount: 128
        ) == 10)

        #expect(MIDISampleOffsetMapper.clampedSampleOffset(
            eventOffset: MusicalTime(ticks: 1_000),
            samplesPerTick: samplesPerTick,
            frameCount: 128
        ) == 127)
    }

    @Test
    func testBlockDurationUsesSampleRateAndTempo() {
        let duration = TransportSnapshot.blockDuration(
            frameCount: 48_000,
            sampleRate: 48_000,
            tempo: 120
        )

        #expect(duration == .beats(2))
    }

    @Test
    func testHostDiagnosticsDeriveFromTransportSnapshot() {
        let transport = TransportSnapshot(
            hostBeatPosition: .beats(9),
            tempo: 132,
            isPlaying: true,
            timeSignature: TimeSignature(numerator: 7, denominator: 8),
            blockDuration: .beats(numerator: 1, denominator: 2),
            isTransportDiscontinuous: true
        )

        let diagnostics = HostDiagnostics(
            transport: transport,
            frameCount: 256,
            sampleRate: 48_000,
            lastMIDIEventCount: 3
        )

        #expect(diagnostics.tempo == 132)
        #expect(diagnostics.beatPosition == .beats(9))
        #expect(diagnostics.timeSignature == TimeSignature(numerator: 7, denominator: 8))
        #expect(diagnostics.isPlaying)
        #expect(diagnostics.isDiscontinuous)
        #expect(diagnostics.frameCount == 256)
        #expect(diagnostics.sampleRate == 48_000)
        #expect(diagnostics.lastMIDIEventCount == 3)
    }
}
