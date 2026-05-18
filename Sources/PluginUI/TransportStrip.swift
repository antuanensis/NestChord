import SwiftUI

struct TransportStrip: View {
    @ObservedObject var store: PatternStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: store.toggleLocalPlayback) {
                    Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(PrimaryTransportButtonStyle())

                Button(action: store.stopAndFlush) {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(IconButtonStyle())
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            store.resetDebugTransport()
                        }
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("LOCAL DEBUG TRANSPORT")
                        .font(.caption2.weight(.bold))
                        .tracking(1)
                        .foregroundStyle(NestChordTheme.textSecondary)
                    Text("Beat \(nestFormatted(store.loopPosition.beats)) / \(nestFormatted(store.pattern.loopDuration.beats))")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(NestChordTheme.textPrimary)
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Text("Tempo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NestChordTheme.textSecondary)
                    Slider(value: $store.tempo, in: 40...220, step: 1)
                        .tint(NestChordTheme.accent)
                        .frame(width: 180)
                    Text("\(Int(store.tempo))")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(NestChordTheme.textPrimary)
                        .frame(width: 38, alignment: .trailing)
                }
            }

            LoopProgressBar(progress: store.loopProgress, isActive: store.isPlaying)
        }
        .nestPanel()
    }
}
