import AppKit

private enum AppIconMetrics {
    static let applicationSize: CGFloat = 512
    static let statusBarSize: CGFloat = 18
    static let cornerRadiusRatio: CGFloat = 0.24
    static let mainSymbolScale: CGFloat = 0.42
    static let accentBadgeScale: CGFloat = 0.22
    static let accentInsetScale: CGFloat = 0.12
    static let shadowBlurScale: CGFloat = 0.05
    static let shadowYOffsetScale: CGFloat = 0.02
}

enum AppIconFactory {
    static func makeApplicationIcon(size: CGFloat = AppIconMetrics.applicationSize) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: image.size)
        drawApplicationBackground(in: rect)
        drawApplicationSymbols(in: rect)

        image.unlockFocus()
        return image
    }

    static func makeStatusBarIcon(size: CGFloat = AppIconMetrics.statusBarSize) -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: size, weight: .semibold)
        let image = NSImage(
            systemSymbolName: "arrow.left.arrow.right",
            accessibilityDescription: "MacT"
        )?.withSymbolConfiguration(configuration) ?? NSImage(size: NSSize(width: size, height: size))
        image.isTemplate = true
        return image
    }

    private static func drawApplicationBackground(in rect: NSRect) {
        let radius = rect.width * AppIconMetrics.cornerRadiusRatio
        let path = NSBezierPath(
            roundedRect: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.04),
            xRadius: radius,
            yRadius: radius
        )

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.18)
        shadow.shadowBlurRadius = rect.width * AppIconMetrics.shadowBlurScale
        shadow.shadowOffset = NSSize(width: 0, height: -(rect.height * AppIconMetrics.shadowYOffsetScale))
        shadow.set()

        let gradient = NSGradient(
            colors: [
                NSColor(calibratedRed: 0.18, green: 0.56, blue: 0.99, alpha: 1),
                NSColor(calibratedRed: 0.09, green: 0.36, blue: 0.93, alpha: 1)
            ]
        )
        gradient?.draw(in: path, angle: -45)
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawApplicationSymbols(in rect: NSRect) {
        let mainSymbolSize = rect.width * AppIconMetrics.mainSymbolScale
        let mainSymbolRect = centeredRect(side: mainSymbolSize, in: rect)
        drawSymbol(
            named: "arrow.triangle.2.circlepath",
            color: .white,
            pointSize: mainSymbolSize,
            in: mainSymbolRect
        )

        let badgeSide = rect.width * AppIconMetrics.accentBadgeScale
        let badgeInset = rect.width * AppIconMetrics.accentInsetScale
        let badgeRect = NSRect(
            x: rect.maxX - badgeInset - badgeSide,
            y: rect.maxY - badgeInset - badgeSide,
            width: badgeSide,
            height: badgeSide
        )

        NSColor.white.withAlphaComponent(0.96).setFill()
        NSBezierPath(ovalIn: badgeRect).fill()

        drawSymbol(
            named: "text.quote",
            color: NSColor(calibratedRed: 0.10, green: 0.40, blue: 0.93, alpha: 1),
            pointSize: badgeSide * 0.62,
            in: badgeRect.insetBy(dx: badgeSide * 0.16, dy: badgeSide * 0.16)
        )
    }

    private static func centeredRect(side: CGFloat, in rect: NSRect) -> NSRect {
        NSRect(
            x: rect.midX - (side / 2),
            y: rect.midY - (side / 2),
            width: side,
            height: side
        )
    }

    private static func drawSymbol(
        named name: String,
        color: NSColor,
        pointSize: CGFloat,
        in rect: NSRect
    ) {
        let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration)?
            .tinted(with: color) else {
            return
        }

        symbol.draw(in: rect)
    }
}

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        draw(in: rect)
        color.set()
        rect.fill(using: .sourceAtop)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
