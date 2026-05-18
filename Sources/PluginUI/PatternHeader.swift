import CoreMusicTheory
import SequencerCore
import SwiftUI

struct PatternHeader: View {
    @ObservedObject var store: PatternStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("NestChord")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(NestChordTheme.textPrimary)

                    TextField("Progression name", text: $store.pattern.name)
                        .font(.subheadline.weight(.medium))
                        .textFieldStyle(.plain)
                        .foregroundStyle(NestChordTheme.textSecondary)
                }

                Spacer(minLength: 16)

                HStack(spacing: 8) {
                    StatusIndicator(title: "AUv3 MIDI", isActive: true, activeColor: NestChordTheme.accent)
                    StatusIndicator(title: "Blocks", isActive: !store.pattern.blocks.isEmpty)
                }
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(PitchClass.allCases) { pitchClass in
                        Button(pitchClass.displayName) {
                            store.pattern.key.root = pitchClass
                        }
                    }
                } label: {
                    SettingPill(title: "Scale", value: "\(store.pattern.key.root.displayName) \(nestModeShortName(store.pattern.mode))")
                }
                .buttonStyle(.plain)

                Menu {
                    ForEach(Mode.allCases) { mode in
                        Button(mode.displayName) {
                            store.pattern.mode = mode
                        }
                    }
                } label: {
                    SettingPill(title: "Mode", value: nestModeShortName(store.pattern.mode))
                }
                .buttonStyle(.plain)

                ValueStepper(
                    title: "Loop",
                    value: "\(store.pattern.loopLengthBars) bars",
                    decrement: decrementLoop,
                    increment: incrementLoop
                )

                Menu {
                    ForEach(GridResolution.allCases) { resolution in
                        Button(resolution.displayName) {
                            store.pattern.gridResolution = resolution
                        }
                    }
                } label: {
                    SettingPill(title: "Quant", value: store.pattern.gridResolution.displayName)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Menu {
                    Button("4-Bar Default") {
                        store.loadDefaultProgression()
                    }
                    Button("5-Bar Example") {
                        store.loadFiveBarExample()
                    }
                } label: {
                    SettingPill(title: "Seed", value: "Load")
                }
                .buttonStyle(.plain)
            }
        }
        .nestPanel(padding: 16)
    }

    private func decrementLoop() {
        store.pattern.loopLengthBars = max(1, store.pattern.loopLengthBars - 1)
    }

    private func incrementLoop() {
        store.pattern.loopLengthBars = min(64, store.pattern.loopLengthBars + 1)
    }
}
