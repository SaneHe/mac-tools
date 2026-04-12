import SwiftUI

struct SurfaceIconBadgePalette {
    let backgroundColor: Color
    let borderColor: Color
    let iconColor: Color
    let sideLength: CGFloat
    let cornerRadius: CGFloat
    let borderWidth: CGFloat

    static let neutral = SurfaceIconBadgePalette(
        backgroundColor: SettingsChrome.mutedSurface,
        borderColor: SettingsChrome.cardBorder.opacity(0.56),
        iconColor: SettingsChrome.sidebarIcon,
        sideLength: 28,
        cornerRadius: SettingsChrome.compactCornerRadius,
        borderWidth: SettingsChrome.borderWidth
    )

    static func tinted(
        tintColor: Color,
        sideLength: CGFloat = 30
    ) -> SurfaceIconBadgePalette {
        SurfaceIconBadgePalette(
            backgroundColor: tintColor.opacity(0.10),
            borderColor: tintColor.opacity(0.16),
            iconColor: tintColor,
            sideLength: sideLength,
            cornerRadius: 12,
            borderWidth: SettingsChrome.borderWidth
        )
    }
}

struct SurfaceIconBadge: View {
    let systemName: String
    let palette: SurfaceIconBadgePalette
    let font: Font

    init(
        systemName: String,
        palette: SurfaceIconBadgePalette = .neutral,
        font: Font = .system(size: 12, weight: .semibold)
    ) {
        self.systemName = systemName
        self.palette = palette
        self.font = font
    }

    var body: some View {
        Image(systemName: systemName)
            .font(font)
            .foregroundStyle(palette.iconColor)
            .frame(width: palette.sideLength, height: palette.sideLength)
            .background(palette.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: palette.cornerRadius, style: .continuous)
                    .stroke(palette.borderColor, lineWidth: palette.borderWidth)
            )
    }
}
