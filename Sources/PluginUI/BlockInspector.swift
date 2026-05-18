import CoreMusicTheory
import SequencerCore
import SwiftUI
import VoicingEngine

struct BlockInspector: View {
    @Binding var block: ChordBlock
    var pattern: SequencerCore.Pattern
    var onDurationPreset: (MusicalTime) -> Void
    var onAudition: () -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            HStack(spacing: 10) {
                Picker("Kind", selection: $block.kind) {
                    ForEach(ChordBlockKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .tint(NestChordTheme.accent)

                Toggle("Rest", isOn: Binding(
                    get: { block.kind == .rest },
                    set: { block.kind = $0 ? .rest : .chord }
                ))
                .toggleStyle(.switch)
                .tint(NestChordTheme.accent)
                .frame(width: 112)
            }

            if block.kind == .chord {
                chordControls
            }

            durationControls
        }
        .nestPanel(padding: 16)
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Selected Block")
                    .font(.caption2.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(NestChordTheme.textSecondary)
                Text(selectedTitle)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(NestChordTheme.textPrimary)
            }

            Spacer()

            Button(action: onAudition) {
                Image(systemName: "speaker.wave.2.fill")
            }
            .buttonStyle(IconButtonStyle())

            Button(action: onDuplicate) {
                Image(systemName: "plus.square.on.square")
            }
            .buttonStyle(IconButtonStyle())

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(IconButtonStyle())
        }
    }

    private var chordControls: some View {
        VStack(alignment: .leading, spacing: 13) {
            degreeControl

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                PluginMenuControl(title: "Extension", value: block.chordExtension.displayName) {
                    ForEach(ChordExtension.allCases) { chordExtension in
                        Button(chordExtension.displayName) {
                            block.chordExtension = chordExtension
                        }
                    }
                }

                PluginMenuControl(title: "Inversion", value: block.voicing.inversion.displayName) {
                    ForEach(Inversion.allCases) { inversion in
                        Button(inversion.displayName) {
                            block.voicing.inversion = inversion
                        }
                    }
                }

                PluginMenuControl(title: "Voicing", value: block.voicing.preset.displayName) {
                    ForEach(VoicingPreset.allCases) { preset in
                        Button(preset.displayName) {
                            block.voicing.preset = preset
                        }
                    }
                }

                PluginMenuControl(title: "Range", value: block.voicing.register.displayName) {
                    ForEach(Register.allCases) { register in
                        Button(register.displayName) {
                            block.voicing.register = register
                        }
                    }
                }

                PluginMenuControl(title: "MIDI Ch", value: "\(block.midiChannel)") {
                    ForEach(Array(1...16), id: \.self) { channel in
                        Button("Channel \(channel)") {
                            block.midiChannel = UInt8(channel)
                        }
                    }
                }
            }

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Velocity")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NestChordTheme.textSecondary)
                        Spacer()
                        Text("\(block.velocity)")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(NestChordTheme.textPrimary)
                    }
                    Slider(value: Binding(
                        get: { Double(block.velocity) },
                        set: { block.velocity = UInt8(clamping: Int($0.rounded())) }
                    ), in: 1...127, step: 1)
                    .tint(NestChordTheme.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Probability")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(NestChordTheme.textSecondary)
                        Spacer()
                        Text("\(Int(block.probability * 100))%")
                            .font(.caption.monospacedDigit().weight(.bold))
                            .foregroundStyle(NestChordTheme.textPrimary)
                    }
                    Slider(value: $block.probability, in: 0...1)
                        .tint(NestChordTheme.green)
                }
            }
        }
    }

    private var degreeControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ScaleDegree.allCases) { degree in
                    Button {
                        block.degree = degree
                    } label: {
                        Text(degree.plainRomanNumeral)
                            .font(.subheadline.weight(.bold))
                            .frame(width: 48, height: 34)
                    }
                    .buttonStyle(DegreeButtonStyle(isSelected: (block.degree ?? .one) == degree))
                }
            }
        }
    }

    private var durationControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Duration")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestChordTheme.textSecondary)
                Text(nestDurationLabel(for: block, in: pattern.timeSignature))
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(NestChordTheme.textPrimary)
                Spacer()
            }

            HStack(spacing: 8) {
                DurationChip("1/4", duration: .bars(numerator: 1, denominator: 4, timeSignature: pattern.timeSignature), action: onDurationPreset)
                DurationChip("1/2", duration: .bars(numerator: 1, denominator: 2, timeSignature: pattern.timeSignature), action: onDurationPreset)
                DurationChip("1 bar", duration: .bars(1, timeSignature: pattern.timeSignature), action: onDurationPreset)
                DurationChip("1.5", duration: .bars(numerator: 3, denominator: 2, timeSignature: pattern.timeSignature), action: onDurationPreset)
                DurationChip("2 bars", duration: .bars(2, timeSignature: pattern.timeSignature), action: onDurationPreset)
            }
        }
    }

    private var selectedTitle: String {
        switch block.kind {
        case .rest:
            return "rest"
        case .hold:
            return "hold"
        case .chord:
            return nestChordTitle(for: block, pattern: pattern)
        }
    }
}

private struct DegreeButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? .white : NestChordTheme.textSecondary)
            .background(
                (isSelected ? NestChordTheme.accent : (configuration.isPressed ? NestChordTheme.accentSoft : NestChordTheme.surfaceControl)),
                in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.18) : NestChordTheme.stroke, lineWidth: 1)
            }
    }
}
