import SequencerCore
import SwiftUI

struct ChordBlockCard: View {
    var positionedBlock: PositionedChordBlock
    var pattern: SequencerCore.Pattern
    var isSelected: Bool
    var isActive: Bool
    var width: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                Text(startLabel)
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(NestChordTheme.textSecondary)
                    .padding(.horizontal, 7)
                    .frame(height: 20)
                    .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 5, style: .continuous))

                Spacer(minLength: 8)

                if isActive {
                    Circle()
                        .fill(NestChordTheme.green)
                        .frame(width: 8, height: 8)
                        .shadow(color: NestChordTheme.green.opacity(0.8), radius: 6)
                }
            }

            Spacer(minLength: 0)

            Text(title)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(NestChordTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            HStack(alignment: .lastTextBaseline) {
                Text(nestDurationLabel(for: positionedBlock.block, in: pattern.timeSignature))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestChordTheme.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(kindLabel)
                    .font(.caption2.weight(.bold))
                    .tracking(0.8)
                    .foregroundStyle(kindTint)
            }
        }
        .frame(width: width, height: 104)
        .padding(12)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected || isActive ? 2 : 1)
        }
        .overlay(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(isActive ? NestChordTheme.green : (isSelected ? NestChordTheme.accent : Color.white.opacity(0.12)))
                .frame(height: 3)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .shadow(color: isActive ? NestChordTheme.green.opacity(0.22) : Color.black.opacity(0.22), radius: isActive ? 13 : 8, y: 4)
    }

    private var title: String {
        nestChordTitle(for: positionedBlock.block, pattern: pattern)
    }

    private var startLabel: String {
        "+\(nestFormatted(positionedBlock.start.beats))"
    }

    private var kindLabel: String {
        switch positionedBlock.block.kind {
        case .chord: "CHORD"
        case .rest: "REST"
        case .hold: "HOLD"
        }
    }

    private var kindTint: Color {
        switch positionedBlock.block.kind {
        case .chord: NestChordTheme.accent
        case .rest: NestChordTheme.textSecondary
        case .hold: NestChordTheme.warning
        }
    }

    private var cardBackground: LinearGradient {
        let base: Color
        switch positionedBlock.block.kind {
        case .chord:
            base = isActive ? NestChordTheme.chordActive : NestChordTheme.chord
        case .rest:
            base = NestChordTheme.rest
        case .hold:
            base = NestChordTheme.hold
        }

        return LinearGradient(
            colors: [base.opacity(1.12), base.opacity(0.78)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var borderColor: Color {
        if isActive { return NestChordTheme.green }
        if isSelected { return NestChordTheme.accent }
        return NestChordTheme.stroke
    }
}
