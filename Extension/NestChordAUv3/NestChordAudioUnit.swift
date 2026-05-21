import AudioToolbox
import AVFAudio
import Foundation
import SequencerCore

public final class NestChordAudioUnit: AUAudioUnit {
    public static let patternStateKey = "NestChordPatternState"

    public var patternDidChange: ((Pattern) -> Void)?
    public var diagnosticsDidChange: ((HostDiagnostics, [MIDINoteEvent]) -> Void)?

    private var pattern = Pattern.defaultProgression()
    private var engine = SequencerEngine()
    private let renderStateLock = NSLock()
    private var shouldFlushOnNextRender = false
    private var diagnosticsFrameAccumulator = 0
    private var renderSampleRate = 44_100.0
    private let inputBus: AUAudioUnitBus
    private let outputBus: AUAudioUnitBus

    private lazy var inputBusArray = AUAudioUnitBusArray(
        audioUnit: self,
        busType: .input,
        busses: [inputBus]
    )
    private lazy var outputBusArray = AUAudioUnitBusArray(
        audioUnit: self,
        busType: .output,
        busses: [outputBus]
    )

    public override init(
        componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) throws {
        guard let defaultFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2) else {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: -50,
                userInfo: [NSLocalizedDescriptionKey: "Unable to create default AUv3 bus format."]
            )
        }
        inputBus = try AUAudioUnitBus(format: defaultFormat)
        outputBus = try AUAudioUnitBus(format: defaultFormat)
        inputBus.name = "Input"
        outputBus.name = "Output"
        try super.init(componentDescription: componentDescription, options: options)
    }

    public override var inputBusses: AUAudioUnitBusArray {
        inputBusArray
    }

    public override var outputBusses: AUAudioUnitBusArray {
        outputBusArray
    }

    public override var isMusicDeviceOrEffect: Bool {
        true
    }

    public override var virtualMIDICableCount: Int {
        1
    }

    public override var midiOutputNames: [String] {
        ["NestChord"]
    }

    public override var fullState: [String: Any]? {
        get { encodedStateDictionary() }
        set { restoreState(from: newValue) }
    }

    public override var fullStateForDocument: [String: Any]? {
        get { encodedStateDictionary() }
        set { restoreState(from: newValue) }
    }

    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()

        if let sampleRate = firstAvailableRenderSampleRate() {
            renderStateLock.withLock {
                renderSampleRate = sampleRate
            }
        }
    }

    public override var internalRenderBlock: AUInternalRenderBlock {
        { [weak self] actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in
            guard let self else { return noErr }

            let audioStatus = self.renderAudioPassthrough(
                actionFlags: actionFlags,
                timestamp: timestamp,
                frameCount: frameCount,
                outputBusNumber: outputBusNumber,
                outputData: outputData,
                realtimeEventListHead: realtimeEventListHead,
                pullInputBlock: pullInputBlock
            )
            guard audioStatus == noErr else { return audioStatus }

            let renderResult = self.renderStateLock.withLock {
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

                let diagnostics = HostDiagnostics(
                    transport: hostContext.transport,
                    frameCount: Int(frameCount),
                    sampleRate: hostContext.sampleRate,
                    lastMIDIEventCount: events.count
                )
                let shouldReportDiagnostics = self.shouldReportDiagnostics(
                    frameCount: Int(frameCount),
                    sampleRate: hostContext.sampleRate,
                    events: events,
                    isDiscontinuous: hostContext.transport.isTransportDiscontinuous
                )

                return (hostContext, events, diagnostics, shouldReportDiagnostics)
            }

            let hostContext = renderResult.0
            let events = renderResult.1
            let diagnostics = renderResult.2
            let shouldReportDiagnostics = renderResult.3
            self.emitMIDI(
                events,
                samplesPerTick: hostContext.samplesPerTick,
                frameCount: Int(frameCount)
            )

            if shouldReportDiagnostics {
                self.diagnosticsDidChange?(diagnostics, events)
            }

            return noErr
        }
    }

    private func renderAudioPassthrough(
        actionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        timestamp: UnsafePointer<AudioTimeStamp>,
        frameCount: AUAudioFrameCount,
        outputBusNumber: Int,
        outputData: UnsafeMutablePointer<AudioBufferList>?,
        realtimeEventListHead: UnsafePointer<AURenderEvent>?,
        pullInputBlock: AURenderPullInputBlock?
    ) -> AUAudioUnitStatus {
        if let pullInputBlock,
           let outputData {
            return pullInputBlock(
                actionFlags,
                timestamp,
                frameCount,
                outputBusNumber,
                outputData
            )
        }

        clearAudioBuffers(outputData, frameCount: frameCount)
        return noErr
    }

    private func clearAudioBuffers(
        _ outputData: UnsafeMutablePointer<AudioBufferList>?,
        frameCount: AUAudioFrameCount
    ) {
        guard let outputData else { return }

        let bufferList = UnsafeMutableAudioBufferListPointer(outputData)
        for buffer in bufferList {
            guard let data = buffer.mData else { continue }
            memset(data, 0, Int(buffer.mDataByteSize))
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

    private func hostContext(frameCount: Int, pattern: Pattern) -> (transport: TransportSnapshot, samplesPerTick: Double, sampleRate: Double) {
        let sampleRate = renderSampleRate
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
            sampleRate: sampleRate,
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
        let samplesPerBeat = sampleRate * 60 / max(tempo, 1)

        return (transport, samplesPerBeat / ticksPerBeat, sampleRate)
    }

    private func firstAvailableRenderSampleRate() -> Double? {
        let busArrays = [outputBusses, inputBusses]
        for busArray in busArrays {
            for index in 0..<busArray.count {
                let sampleRate = busArray[index].format.sampleRate
                if sampleRate > 0 {
                    return sampleRate
                }
            }
        }
        return nil
    }

    private func shouldReportDiagnostics(
        frameCount: Int,
        sampleRate: Double,
        events: [MIDINoteEvent],
        isDiscontinuous: Bool
    ) -> Bool {
        diagnosticsFrameAccumulator += max(0, frameCount)
        let reportFrameInterval = max(1, Int(sampleRate / 10))
        if diagnosticsFrameAccumulator >= reportFrameInterval || !events.isEmpty || isDiscontinuous {
            diagnosticsFrameAccumulator = 0
            return true
        }
        return false
    }

    private func emitMIDI(_ events: [MIDINoteEvent], samplesPerTick: Double, frameCount: Int) {
        guard let outputBlock = midiOutputEventBlock else { return }

        for event in events {
            let statusBase: UInt8 = event.kind == .noteOn ? 0x90 : 0x80
            let channel = UInt8(max(0, min(15, Int(event.channel) - 1)))
            let status = statusBase | channel
            let velocity = event.kind == .noteOn ? event.velocity : 0
            let sampleOffset = MIDISampleOffsetMapper.clampedSampleOffset(
                eventOffset: event.offset,
                samplesPerTick: samplesPerTick,
                frameCount: frameCount
            )
            let sampleTime = AUEventSampleTime(sampleOffset)
            let bytes = [status, event.noteNumber, velocity]
            bytes.withUnsafeBufferPointer { buffer in
                guard let baseAddress = buffer.baseAddress else { return }
                _ = outputBlock(sampleTime, 0, buffer.count, baseAddress)
            }
        }
    }
}
