import SwiftUI

enum SurfaceButtonRole {
    case primary
    case secondary
    case destructive
}

struct SurfaceButtonPalette {
    let backgroundColor: Color
    let pressedBackgroundColor: Color
    let foregroundColor: Color
    let shadowColor: Color
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let cornerRadius: CGFloat
    let minimumHeight: CGFloat
    let horizontalPadding: CGFloat
    let showsBorder: Bool

    static func make(
        role: SurfaceButtonRole,
        isEnabled: Bool
    ) -> SurfaceButtonPalette {
        let enabledOpacity = isEnabled ? 1.0 : 0.5

        switch role {
        case .primary:
            return SurfaceButtonPalette(
                backgroundColor: Color(red: 0.85, green: 0.93, blue: 1.00).opacity(enabledOpacity),
                pressedBackgroundColor: Color(red: 0.78, green: 0.89, blue: 0.99).opacity(enabledOpacity),
                foregroundColor: Color(red: 0.12, green: 0.36, blue: 0.68).opacity(isEnabled ? 1 : 0.75),
                shadowColor: Color(red: 0.45, green: 0.67, blue: 0.96).opacity(isEnabled ? 0.16 : 0.08),
                shadowRadius: 10,
                shadowYOffset: 3,
                cornerRadius: 14,
                minimumHeight: 30,
                horizontalPadding: 12,
                showsBorder: false
            )

        case .secondary:
            return SurfaceButtonPalette(
                backgroundColor: Color.white.opacity(0.86 * enabledOpacity),
                pressedBackgroundColor: Color.white.opacity(0.76 * enabledOpacity),
                foregroundColor: SettingsChrome.titleColor.opacity(isEnabled ? 1 : 0.72),
                shadowColor: Color.black.opacity(isEnabled ? 0.05 : 0.02),
                shadowRadius: 8,
                shadowYOffset: 2,
                cornerRadius: 14,
                minimumHeight: 30,
                horizontalPadding: 12,
                showsBorder: false
            )

        case .destructive:
            return SurfaceButtonPalette(
                backgroundColor: Color(red: 1.00, green: 0.92, blue: 0.92).opacity(enabledOpacity),
                pressedBackgroundColor: Color(red: 0.99, green: 0.86, blue: 0.86).opacity(enabledOpacity),
                foregroundColor: Color(red: 0.73, green: 0.20, blue: 0.18).opacity(isEnabled ? 1 : 0.75),
                shadowColor: Color(red: 0.85, green: 0.42, blue: 0.38).opacity(isEnabled ? 0.14 : 0.07),
                shadowRadius: 8,
                shadowYOffset: 2,
                cornerRadius: 14,
                minimumHeight: 30,
                horizontalPadding: 12,
                showsBorder: false
            )
        }
    }
}

struct SurfaceButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    let role: SurfaceButtonRole

    func makeBody(configuration: Configuration) -> some View {
        let palette = SurfaceButtonPalette.make(
            role: role,
            isEnabled: isEnabled
        )

        configuration.label
            .foregroundStyle(palette.foregroundColor)
            .contentShape(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous))
            .frame(minHeight: palette.minimumHeight)
            .padding(.horizontal, palette.horizontalPadding)
            .background(
                RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous)
                    .fill(configuration.isPressed ? palette.pressedBackgroundColor : palette.backgroundColor)
                    .shadow(
                        color: palette.shadowColor,
                        radius: configuration.isPressed ? palette.shadowRadius * 0.55 : palette.shadowRadius,
                        x: 0,
                        y: configuration.isPressed ? 1 : palette.shadowYOffset
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.84)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension View {
    func surfaceButtonStyle(_ role: SurfaceButtonRole) -> some View {
        buttonStyle(SurfaceButtonStyle(role: role))
    }
}
