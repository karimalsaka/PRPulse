import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

enum AppTheme {
    // Soft, airy theme with dark mode support
    static let accent = dynamic(
        light: NSColor(calibratedRed: 0.55, green: 0.53, blue: 0.78, alpha: 1),
        dark: NSColor(calibratedRed: 0.62, green: 0.60, blue: 0.84, alpha: 1)
    )
    static let accentStrong = dynamic(
        light: NSColor(calibratedRed: 0.40, green: 0.38, blue: 0.62, alpha: 1),
        dark: NSColor(calibratedRed: 0.48, green: 0.46, blue: 0.70, alpha: 1)
    )
    static let success = dynamic(
        light: NSColor(calibratedRed: 0.42, green: 0.70, blue: 0.56, alpha: 1),
        dark: NSColor(calibratedRed: 0.46, green: 0.74, blue: 0.60, alpha: 1)
    )
    static let danger = dynamic(
        light: NSColor(calibratedRed: 0.76, green: 0.46, blue: 0.52, alpha: 1),
        dark: NSColor(calibratedRed: 0.80, green: 0.50, blue: 0.56, alpha: 1)
    )
    static let warning = dynamic(
        light: NSColor(calibratedRed: 0.78, green: 0.65, blue: 0.42, alpha: 1),
        dark: NSColor(calibratedRed: 0.82, green: 0.70, blue: 0.48, alpha: 1)
    )
    static let info = dynamic(
        light: NSColor(calibratedRed: 0.50, green: 0.62, blue: 0.82, alpha: 1),
        dark: NSColor(calibratedRed: 0.54, green: 0.66, blue: 0.86, alpha: 1)
    )

    static let accentSoft = accent.opacity(0.14)
    static let successSoft = success.opacity(0.12)
    static let dangerSoft = danger.opacity(0.12)
    static let warningSoft = warning.opacity(0.12)
    static let infoSoft = info.opacity(0.12)

    static let canvas = dynamic(
        light: NSColor(calibratedWhite: 0.98, alpha: 1),
        dark: NSColor(calibratedWhite: 0.08, alpha: 1)
    )
    static let surface = dynamic(
        light: NSColor(calibratedWhite: 0.97, alpha: 1),
        dark: NSColor(calibratedWhite: 0.12, alpha: 1)
    )
    static let elevatedSurface = dynamic(
        light: NSColor(calibratedWhite: 0.96, alpha: 1),
        dark: NSColor(calibratedWhite: 0.1, alpha: 1)
    )
    static let stroke = dynamic(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.06),
        dark: NSColor(calibratedWhite: 1.0, alpha: 0.08)
    )
    static let strokeStrong = dynamic(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.12),
        dark: NSColor(calibratedWhite: 1.0, alpha: 0.16)
    )
    static let muted = dynamic(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.55),
        dark: NSColor(calibratedWhite: 1.0, alpha: 0.60)
    )
    static let hoverOverlay = dynamic(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.02),
        dark: NSColor(calibratedWhite: 1.0, alpha: 0.04)
    )
    static let cardShadow = dynamic(
        light: NSColor(calibratedWhite: 0.0, alpha: 0.08),
        dark: NSColor(calibratedWhite: 0.0, alpha: 0.45)
    )

    static let heroGradient = LinearGradient(
        colors: [
            dynamic(
                light: NSColor(calibratedWhite: 0.98, alpha: 1),
                dark: NSColor(calibratedWhite: 0.10, alpha: 1)
            ),
            dynamic(
                light: NSColor(calibratedWhite: 0.95, alpha: 1),
                dark: NSColor(calibratedWhite: 0.06, alpha: 1)
            )
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let badgeGradient = LinearGradient(
        colors: [accent.opacity(0.95), accentStrong.opacity(0.9)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    #if canImport(AppKit)
    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return dark
            }
            return light
        })
    }
    #else
    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
    #endif
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            AppTheme.heroGradient
            RadialGradient(
                colors: [
                    AppTheme.accent.opacity(0.12),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 360
            )
            RadialGradient(
                colors: [
                    AppTheme.info.opacity(0.08),
                    Color.clear
                ],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

struct AppCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.cardShadow, radius: 20, x: 0, y: 12)
            )
    }
}

struct AppTag: View {
    let text: String
    let icon: String?
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12))
        .foregroundColor(tint)
        .cornerRadius(999)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.badgeGradient)
                    .shadow(color: AppTheme.accent.opacity(0.22), radius: 12, x: 0, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct AppPrimaryButtonStrongStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppTheme.accentStrong)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct AppSoftButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.18 : 0.12))
            )
    }
}
