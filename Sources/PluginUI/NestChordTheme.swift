import SwiftUI

enum NestChordTheme {
    static let radius: CGFloat = 8
    static let outerPadding: CGFloat = 18
    static let panelPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 14
    static let controlHeight: CGFloat = 34
    static let iconButtonSize: CGFloat = 34
    static let beatWidth: CGFloat = 42

    static let background = Color(red: 0.035, green: 0.039, blue: 0.046)
    static let surface = Color(red: 0.075, green: 0.083, blue: 0.096)
    static let surfaceRaised = Color(red: 0.105, green: 0.116, blue: 0.134)
    static let surfaceControl = Color.white.opacity(0.075)
    static let stroke = Color.white.opacity(0.095)
    static let strokeStrong = Color.white.opacity(0.18)
    static let textPrimary = Color.white.opacity(0.94)
    static let textSecondary = Color.white.opacity(0.58)
    static let accent = Color(red: 0.13, green: 0.62, blue: 0.94)
    static let accentSoft = Color(red: 0.09, green: 0.31, blue: 0.43)
    static let green = Color(red: 0.36, green: 0.88, blue: 0.58)
    static let warning = Color(red: 1.0, green: 0.66, blue: 0.34)
    static let chord = Color(red: 0.15, green: 0.22, blue: 0.27)
    static let chordActive = Color(red: 0.12, green: 0.33, blue: 0.29)
    static let rest = Color(red: 0.095, green: 0.101, blue: 0.116)
    static let hold = Color(red: 0.17, green: 0.13, blue: 0.21)
}

extension View {
    func nestPanel(padding: CGFloat = NestChordTheme.panelPadding) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [NestChordTheme.surfaceRaised, NestChordTheme.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay {
                RoundedRectangle(cornerRadius: NestChordTheme.radius, style: .continuous)
                    .stroke(NestChordTheme.stroke, lineWidth: 1)
            }
    }
}
