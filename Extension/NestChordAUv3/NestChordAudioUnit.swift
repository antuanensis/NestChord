import AudioToolbox
import Foundation
import SequencerCore

public final class NestChordAudioUnit: AUAudioUnit {
    public static let patternStateKey = "NestChordPatternState"

    public var patternDidChange: ((Pattern) -> Void)?

    private var pattern = Pattern.defaultProgression()
    private var engine = SequencerEngine()
    private let renderStateLock = NSLock()
    private var shouldFlushOnNextRender = false
    private var renderSampleRate = 44_100.0

    private lazy var inputBusArray = AUAudioUnitBusArray(
        audioUnit: self,
        busType: .input,
        busses: []
    )
    private lazy var outputBusArray = AUAudioUnitBusArray(
        audioUnit: self,
        busType: .output,
        busses: []
    )

    public override init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {
        try super.init(componentDescription: componentDescription, options: options)
    }

    public override var inputBusses: AUAudioUnitBusArray {
        inputBusArray
    }

    public override var outputBusses: AUAudioUnitBusArray {
        outputBusArray
    }

    public override var fullState: [String: Any]? {
        get { encodedStateDictionary() }
        set { restoreState(from: newValue) }
    }

    public override var fullStateForDocument: [String: Any]? {
        get { encodedStateDictionary() }
        set { restoreState(from: newValue) }
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        { [weak self] _, _, frameCount, _, _, _, _ in
            guard let self else { return noErr }

            let hostContextAndEvents = self.renderStateLock.withLock {
                let currentPattern = self.pattern
                let hostContext = self.hostContext(frameCount: Int(frameCount), pattern: currentPattern)
                var events: [MIDINoteEvent] = []

                if self.shouldFlushOnNextRender {
                    events.append(contentsOf: self.engine.reset())
                    self.shouldFlushOnNextRender = false
                }

                events.append(contentsOf: self.engine.render(
                    pattern: currentPattern,
                    transport: hostContext.transport
                ))

                return (hostContext, events)
            }

            let events = hostContextAndEvents.1
            let samplesPerTick = hostContextAndEvents.0.samplesPerTick
            self.emitMIDI(events, samplesPerTick: samplesPerTick)

            return noErr
        }
    }

    public func currentPattern() -> Pattern {
        renderStateLock.withLock {
            pattern
        }
    }

    public func setPatternFromUI(_ pattern: Pattern) {
        setPattern(pattern, notifyUI: false, flushOnNextRender: true)
    }

    public func setPatternFromHost(_ pattern: Pattern) {
        setPattern(pattern, notifyUI: true, flushOnNextRender: true)
    }

    private func encodedStateDictionary() -> [String: Any] {
        guard let data = try? PatternStateEnvelope(pattern: currentPattern()).encodedJSON() else {
            return [:]
        }
        return [Self.patternStateKey: data]
    }

    private func restoreState(from dictionary: [String: Any]?) {
        guard let data = dictionary?[Self.patternStateKey] as? Data,
              let envelope = try? PatternStateEnvelope.decodeJSON(data) else {
            return
        }
        setPatternFromHost(envelope.pattern)
    }

    private func setPattern(_ nextPattern: Pattern, notifyUI: Bool, flushOnNextRender: Bool) {
        renderStateLock.withLock {
            pattern = nextPattern
            shouldFlushOnNextRender = shouldFlushOnNextRender || flushOnNextRender
        }

        if notifyUI {
            patternDidChange?(nextPattern)
        }
    }

    private func hostContext(frameCount: Int, pattern: Pattern) -> (transport: TransportSnapshot, samplesPerTick: Double) {
        var tempo = 120.0
        var numerator = Double(pattern.timeSignature.numerator)
        var denominator = pattern.timeSignature.denominator
        var beatPosition = 0.0
        var sampleOffsetToNextBeat = 0
        var measureDownbeat = 0.0
        _ = musicalContextBlock?(
            &tempo,
            &numerator,
            &denominator,
            &beatPosition,
            &sampleOffsetToNextBeat,
            &measureDownbeat
        )

        var flags = AUHostTransportStateFlags()
        _ = transportStateBlock?(&flags, nil, nil, nil)
        let isTransportMoving = flags.contains(.moving)
        let transportChanged = flags.contains(.changed)

        let blockDuration = TransportSnapshot.blockDuration(
            frameCount: frameCount,
            sampleRate: renderSampleRate,
            tempo: tempo
        )
        let timeSignature = TimeSignature(
            numerator: max(1, Int(numerator.rounded())),
            denominator: max(1, denominator)
        )
        let transport = TransportSnapshot(
            hostBeatPosition: MusicalTime(beats: beatPosition),
            tempo: tempo,
            isPlaying: isTransportMoving,
            timeSignature: timeSignature,
            blockDuration: blockDuration,
            isTransportDiscontinuous: transportChanged
        )
        let ticksPerBeat = Double(MusicalTime.ticksPerQuarterNote)
        let samplesPerBeat = renderSampleRate * 60 / max(tempo, 1)

        return (transport, samplesPerBeat / ticksPerBeat)
    }

    private func emitMIDI(_ events: [MIDINoteEvent], samplesPerTick: Double) {
        guard let outputBlock = midiOutputEventBlock else { return }

        for event in events {
            let statusBase: UInt8 = event.kind == .noteOn ? 0x90 : 0x80
            let channel = UInt8(max(0, min(15, Int(event.channel) - 1)))
            let status = statusBase | channel
            let velocity = event.kind == .noteOn ? event.velocity : 0
            let sampleTime = AUEventSampleTime((Double(event.offset.ticks) * samplesPerTick).rounded())
            let bytes = [status, event.noteNumber, velocity]
            bytes.withUnsafeBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                _ = outputBlock(sampleTime, 0, buffer.count, baseAddress)
            }
        }
    }
}
