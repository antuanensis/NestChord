import SequencerCore
import SwiftUI

struct SectionHeader: View {
    var title: String
    var detail: String?
    var tint: Color = NestChordTheme.textSecondary

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(NestChordTheme.textSecondary)

            Spacer(minLength: 12)

            if let detail {
                Text(detail)
                    .font(.caption.monospacedDigit().weight(.medium))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }
}

struct SettingPill: View {
    var title: String
    var value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NestChordTheme.textSecondary)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NestChordTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 12)
        .frame(height: NestChordTheme.controlHeight)
        .background(NestChordTheme.surfaceControl, in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                .stroke(NestChordTheme.stroke, lineWidth: 1)
        }
    }
}

struct ValueStepper: View {
    var title: String
    var value: String
    var decrement: () -> Void
    var increment: () -> Void

    var body: some View {
        HStack(spacing: 7) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NestChordTheme.textSecondary)

            Text(value)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(NestChordTheme.textPrimary)
                .frame(minWidth: 54)

            Button(action: decrement) {
                Image(systemName: "minus")
            }
            .buttonStyle(MiniIconButtonStyle())

            Button(action: increment) {
                Image(systemName: "plus")
            }
            .buttonStyle(MiniIconButtonStyle())
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .frame(height: NestChordTheme.controlHeight)
        .background(NestChordTheme.surfaceControl, in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                .stroke(NestChordTheme.stroke, lineWidth: 1)
        }
    }
}

struct PluginMenuControl<Content: View>: View {
    var title: String
    var value: String
    @ViewBuilder var content: Content

    var body: some View {
        Menu {
            content
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(NestChordTheme.textSecondary)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NestChordTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(NestChordTheme.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(NestChordTheme.surfaceControl, in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .stroke(NestChordTheme.stroke, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct DurationChip: View {
    var title: String
    var duration: MusicalTime
    var action: (MusicalTime) -> Void

    init(_ title: String, duration: MusicalTime, action: @escaping (MusicalTime) -> Void) {
        self.title = title
        self.duration = duration
        self.action = action
    }

    var body: some View {
        Button(title) {
            action(duration)
        }
        .buttonStyle(TonalButtonStyle())
    }
}

struct ResizeHandle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.white.opacity(0.46))
            .frame(width: 5, height: 54)
            .padding(.trailing, 6)
    }
}

struct LoopProgressBar: View {
    var progress: Double
    var isActive: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.black.opacity(0.34))

                Capsule()
                    .fill(isActive ? NestChordTheme.green : NestChordTheme.accent)
                    .frame(width: max(5, proxy.size.width * max(0, min(1, progress))))
                    .shadow(color: (isActive ? NestChordTheme.green : NestChordTheme.accent).opacity(0.35), radius: 8)
            }
        }
        .frame(height: 5)
    }
}

struct StatusIndicator: View {
    var title: String
    var isActive: Bool
    var activeColor: Color = NestChordTheme.green

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isActive ? activeColor : Color.white.opacity(0.18))
                .frame(width: 7, height: 7)
                .shadow(color: isActive ? activeColor.opacity(0.6) : .clear, radius: 5)
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(0.8)
                .foregroundStyle(NestChordTheme.textSecondary)
        }
    }
}

struct TonalButtonStyle: ButtonStyle {
    var tint: Color = NestChordTheme.surfaceControl

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .frame(height: NestChordTheme.controlHeight)
            .foregroundStyle(NestChordTheme.textPrimary)
            .background(
                (configuration.isPressed ? NestChordTheme.accent.opacity(0.55) : tint),
                in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .stroke(NestChordTheme.stroke, lineWidth: 1)
            }
    }
}

struct IconButtonStyle: ButtonStyle {
    var tint: Color = NestChordTheme.surfaceControl
    var size: CGFloat = NestChordTheme.iconButtonSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(width: size, height: size)
            .foregroundStyle(NestChordTheme.textPrimary)
            .background(
                (configuration.isPressed ? NestChordTheme.accent.opacity(0.65) : tint),
                in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .stroke(NestChordTheme.stroke, lineWidth: 1)
            }
    }
}

struct PrimaryTransportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(width: 42, height: 42)
            .foregroundStyle(.white)
            .background(
                (configuration.isPressed ? NestChordTheme.accent.opacity(0.75) : NestChordTheme.accent),
                in: RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
            .shadow(color: NestChordTheme.accent.opacity(configuration.isPressed ? 0.16 : 0.3), radius: 10)
    }
}

private struct MiniIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .frame(width: 24, height: 24)
            .foregroundStyle(NestChordTheme.textPrimary)
            .background(
                (configuration.isPressed ? NestChordTheme.accent.opacity(0.65) : Color.black.opacity(0.22)),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }
}
