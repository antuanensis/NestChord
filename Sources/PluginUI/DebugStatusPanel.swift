import SequencerCore
import SwiftUI

struct DebugStatusPanel: View {
    @ObservedObject var store: PatternStore
    var showsLocalControls: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SectionHeader(title: "Debug I/O", detail: "Beat \(nestFormatted(store.currentBeat.beats))")

                StatusIndicator(title: "Play", isActive: store.isPlaying)
                StatusIndicator(title: "MIDI", isActive: lastEventIsNoteOn, activeColor: NestChordTheme.accent)
            }

            if showsLocalControls {
                localControls
            } else {
                Text("AUv3 trace subsystem: com.nestchord.NestChord")
                    .font(.caption2.monospaced().weight(.semibold))
                    .foregroundStyle(NestChordTheme.textSecondary)
                hostSyncStrip
            }

            VStack(alignment: .leading, spacing: 6) {
                if store.debugEvents.isEmpty {
                    Text("No MIDI events yet")
                        .font(.caption.monospaced())
                        .foregroundStyle(NestChordTheme.textSecondary)
                } else {
                    ForEach(store.debugEvents.suffix(12)) { event in
                        Text(debugDescription(for: event))
                            .font(.caption.monospaced())
                            .foregroundStyle(event.kind == .noteOn ? NestChordTheme.green : NestChordTheme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
        }
        .nestPanel()
    }

    private var localControls: some View {
        HStack(spacing: 10) {
            Button(action: store.toggleLocalPlayback) {
                Label(store.isPlaying ? "Pause" : "Play", systemImage: store.isPlaying ? "pause.fill" : "play.fill")
            }
            .buttonStyle(TonalButtonStyle())

            Button(action: store.renderDebugStep) {
                Label("Step", systemImage: "forward.frame.fill")
            }
            .buttonStyle(TonalButtonStyle())

            Button(action: store.stopAndFlush) {
                Label("Stop", systemImage: "stop.fill")
            }
            .buttonStyle(TonalButtonStyle())
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        store.resetDebugTransport()
                    }
            )

            Button(action: store.resetDebugTransport) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(TonalButtonStyle())

            Spacer(minLength: 0)
        }
    }

    private var hostSyncStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                HostDiagnosticCell(
                    title: "State",
                    value: hostDiagnostics.map { $0.isPlaying ? "Playing" : "Stopped" } ?? "Waiting",
                    isActive: hostDiagnostics?.isPlaying == true
                )
                HostDiagnosticCell(
                    title: "Tempo",
                    value: hostDiagnostics.map { "\(Int($0.tempo.rounded()))" } ?? "--"
                )
                HostDiagnosticCell(
                    title: "Beat",
                    value: hostDiagnostics.map { nestFormatted($0.beatPosition.beats) } ?? "--"
                )
                HostDiagnosticCell(
                    title: "Meter",
                    value: hostDiagnostics.map { "\($0.timeSignature.numerator)/\($0.timeSignature.denominator)" } ?? "--"
                )
                HostDiagnosticCell(
                    title: "Frames",
                    value: hostDiagnostics.map { "\($0.frameCount)" } ?? "--"
                )
                HostDiagnosticCell(
                    title: "Rate",
                    value: hostDiagnostics.map { "\(Int($0.sampleRate.rounded()))" } ?? "--"
                )
                HostDiagnosticCell(
                    title: "MIDI",
                    value: hostDiagnostics.map { "\($0.lastMIDIEventCount)" } ?? "--",
                    isActive: (hostDiagnostics?.lastMIDIEventCount ?? 0) > 0
                )
                HostDiagnosticCell(
                    title: "Jump",
                    value: hostDiagnostics?.isDiscontinuous == true ? "Yes" : "No",
                    isActive: hostDiagnostics?.isDiscontinuous == true
                )
            }
        }
    }

    private var hostDiagnostics: HostDiagnostics? {
        store.hostDiagnostics
    }

    private var lastEventIsNoteOn: Bool {
        store.debugEvents.last?.kind == .noteOn
    }

    private func debugDescription(for event: MIDINoteEvent) -> String {
        "\(event.kind.rawValue)  ch\(event.channel)  note \(event.noteNumber)  vel \(event.velocity)  +\(nestFormatted(event.offset.beats))"
    }
}

private struct HostDiagnosticCell: View {
    var title: String
    var value: String
    var isActive = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isActive ? NestChordTheme.green : Color.white.opacity(0.18))
                    .frame(width: 6, height: 6)
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(NestChordTheme.textSecondary)
            }
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(NestChordTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(minWidth: 64, alignment: .leading)
        .padding(.horizontal, 9)
        .frame(height: 46)
        .background(Color.black.opacity(0.2), in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                .stroke(isActive ? NestChordTheme.green.opacity(0.35) : NestChordTheme.stroke, lineWidth: 1)
        }
    }
}
