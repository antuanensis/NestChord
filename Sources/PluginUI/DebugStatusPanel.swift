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

    private var lastEventIsNoteOn: Bool {
        store.debugEvents.last?.kind == .noteOn
    }

    private func debugDescription(for event: MIDINoteEvent) -> String {
        "\(event.kind.rawValue)  ch\(event.channel)  note \(event.noteNumber)  vel \(event.velocity)  +\(nestFormatted(event.offset.beats))"
    }
}
