import AppKit

private enum AppIconMetrics {
    static let applicationSize: CGFloat = 512
    static let statusBarSize: CGFloat = 18
    static let canvasInsetRatio: CGFloat = 0.086
    static let cornerRadiusRatio: CGFloat = 0.24
    static let shadowBlurRatio: CGFloat = 0.048
    static let shadowYOffsetRatio: CGFloat = 0.032
    static let panelWidthRatio: CGFloat = 0.49
    static let panelHeightRatio: CGFloat = 0.43
    static let panelOffsetRatio: CGFloat = 0.09
    static let cursorScale: CGFloat = 0.42
    static let sparkleScale: CGFloat = 0.20
}

private enum AppIconPalette {
    static let backgroundTop = NSColor(calibratedRed: 0.32, green: 0.76, blue: 1.00, alpha: 1)
    static let backgroundMiddle = NSColor(calibratedRed: 0.16, green: 0.48, blue: 1.00, alpha: 1)
    static let backgroundBottom = NSColor(calibratedRed: 0.07, green: 0.22, blue: 0.73, alpha: 1)
    static let cardFront = NSColor(calibratedRed: 0.98, green: 0.99, blue: 1.00, alpha: 0.88)
    static let cardBack = NSColor(calibratedRed: 1.00, green: 1.00, blue: 1.00, alpha: 0.12)
    static let cardStroke = NSColor(calibratedRed: 1.00, green: 1.00, blue: 1.00, alpha: 0.24)
    static let lineFront = NSColor(calibratedRed: 0.81, green: 0.89, blue: 1.00, alpha: 1)
    static let lineBack = NSColor(calibratedRed: 0.85, green: 0.91, blue: 1.00, alpha: 0.72)
    static let cursorFront = NSColor(calibratedRed: 0.05, green: 0.32, blue: 0.88, alpha: 1)
    static let cursorLeft = NSColor(calibratedRed: 0.18, green: 0.44, blue: 0.96, alpha: 1)
    static let cursorRight = NSColor(calibratedRed: 0.03, green: 0.22, blue: 0.73, alpha: 1)
    static let sparklePrimary = NSColor(calibratedRed: 1.00, green: 0.91, blue: 0.48, alpha: 1)
    static let sparkleSecondary = NSColor(calibratedRed: 1.00, green: 0.98, blue: 0.96, alpha: 1)
    static let statusTemplate = NSColor.black
}

enum AppIconFactory {
    static let iconsetSizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
    static let iconsetEntries: [IconsetEntry] = [
        IconsetEntry(fileName: "icon_16x16.png", pixelSize: 16),
        IconsetEntry(fileName: "icon_16x16@2x.png", pixelSize: 32),
        IconsetEntry(fileName: "icon_32x32.png", pixelSize: 32),
        IconsetEntry(fileName: "icon_32x32@2x.png", pixelSize: 64),
        IconsetEntry(fileName: "icon_128x128.png", pixelSize: 128),
        IconsetEntry(fileName: "icon_128x128@2x.png", pixelSize: 256),
        IconsetEntry(fileName: "icon_256x256.png", pixelSize: 256),
        IconsetEntry(fileName: "icon_256x256@2x.png", pixelSize: 512),
        IconsetEntry(fileName: "icon_512x512.png", pixelSize: 512),
        IconsetEntry(fileName: "icon_512x512@2x.png", pixelSize: 1024)
    ]

    static func makeApplicationIcon(size: CGFloat = AppIconMetrics.applicationSize) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let canvas = NSRect(origin: .zero, size: image.size)
        drawApplicationBackground(in: canvas)
        drawTextCards(in: canvas)
        drawCursor(in: canvas)
        drawSparkles(in: canvas)

        image.unlockFocus()
        return image
    }

    static func makeStatusBarIcon(size: CGFloat = AppIconMetrics.statusBarSize) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()

        let canvas = NSRect(origin: .zero, size: image.size)
        drawStatusCursor(in: canvas)
        drawStatusSparkle(in: canvas)

        image.unlockFocus()
        image.isTemplate = true
        return image
    }

    private static func drawApplicationBackground(in canvas: NSRect) {
        let inset = canvas.width * AppIconMetrics.canvasInsetRatio
        let drawingRect = canvas.insetBy(dx: inset, dy: inset)
        let cornerRadius = drawingRect.width * AppIconMetrics.cornerRadiusRatio
        let path = NSBezierPath(roundedRect: drawingRect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
        shadow.shadowBlurRadius = canvas.width * AppIconMetrics.shadowBlurRatio
        shadow.shadowOffset = NSSize(width: 0, height: -(canvas.height * AppIconMetrics.shadowYOffsetRatio))
        shadow.set()

        let gradient = NSGradient(colors: [
            AppIconPalette.backgroundTop,
            AppIconPalette.backgroundMiddle,
            AppIconPalette.backgroundBottom
        ])
        gradient?.draw(in: path, angle: -48)
        NSGraphicsContext.restoreGraphicsState()

        drawTopHighlight(in: drawingRect, cornerRadius: cornerRadius)
    }

    private static func drawTopHighlight(in rect: NSRect, cornerRadius: CGFloat) {
        let highlight = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        NSGraphicsContext.saveGraphicsState()
        highlight.addClip()

        let bandHeight = rect.height * 0.30
        let bandRect = NSRect(x: rect.minX, y: rect.maxY - bandHeight, width: rect.width, height: bandHeight)
        NSColor.white.withAlphaComponent(0.14).setFill()
        bandRect.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private static func drawTextCards(in canvas: NSRect) {
        let frontCard = makeFrontCardRect(in: canvas)
        let backCard = frontCard.offsetBy(dx: canvas.width * AppIconMetrics.panelOffsetRatio, dy: -canvas.height * 0.045)

        drawCard(in: backCard, fillColor: AppIconPalette.cardBack)
        drawCardLines(in: backCard, lineColor: AppIconPalette.lineBack)
        drawCard(in: frontCard, fillColor: AppIconPalette.cardFront)
        drawCardLines(in: frontCard, lineColor: AppIconPalette.lineFront)
    }

    private static func makeFrontCardRect(in canvas: NSRect) -> NSRect {
        let width = canvas.width * AppIconMetrics.panelWidthRatio
        let height = canvas.height * AppIconMetrics.panelHeightRatio
        return NSRect(
            x: canvas.minX + canvas.width * 0.21,
            y: canvas.minY + canvas.height * 0.29,
            width: width,
            height: height
        )
    }

    private static func drawCard(in rect: NSRect, fillColor: NSColor) {
        let cornerRadius = rect.width * 0.18
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        fillColor.setFill()
        path.fill()

        AppIconPalette.cardStroke.setStroke()
        path.lineWidth = max(2, rect.width * 0.018)
        path.stroke()
    }

    private static func drawCardLines(in rect: NSRect, lineColor: NSColor) {
        let lineHeight = rect.height * 0.085
        let spacing = rect.height * 0.12
        let startX = rect.minX + rect.width * 0.12
        let widths = [0.72, 0.58, 0.49, 0.40]

        for (index, widthRatio) in widths.enumerated() {
            let lineRect = NSRect(
                x: startX,
                y: rect.maxY - rect.height * 0.22 - CGFloat(index) * spacing,
                width: rect.width * widthRatio,
                height: lineHeight
            )
            let path = NSBezierPath(roundedRect: lineRect, xRadius: lineHeight / 2, yRadius: lineHeight / 2)
            lineColor.setFill()
            path.fill()
        }
    }

    private static func drawCursor(in canvas: NSRect) {
        let side = canvas.width * AppIconMetrics.cursorScale
        let rect = NSRect(
            x: canvas.midX - side / 2,
            y: canvas.midY - side / 2 - canvas.height * 0.01,
            width: side,
            height: side
        )

        drawCursorCenter(in: rect)
        drawCursorWing(in: rect, side: .left)
        drawCursorWing(in: rect, side: .right)
    }

    private static func drawCursorCenter(in rect: NSRect) {
        let centerRect = NSRect(
            x: rect.midX - rect.width * 0.07,
            y: rect.minY,
            width: rect.width * 0.14,
            height: rect.height
        )
        AppIconPalette.cursorFront.setFill()
        NSBezierPath(rect: centerRect).fill()
    }

    private static func drawCursorWing(in rect: NSRect, side: CursorWingSide) {
        let path = NSBezierPath()
        let inset = rect.width * 0.17
        let tipInset = rect.width * 0.04

        if side == .left {
            path.move(to: CGPoint(x: rect.midX - rect.width * 0.07, y: rect.minY))
            path.line(to: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.08))
            path.line(to: CGPoint(x: rect.minX + tipInset, y: rect.minY + rect.height * 0.18))
            path.line(to: CGPoint(x: rect.minX + tipInset, y: rect.maxY - rect.height * 0.18))
            path.line(to: CGPoint(x: rect.minX + inset, y: rect.maxY - rect.height * 0.08))
            path.line(to: CGPoint(x: rect.midX - rect.width * 0.07, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.midX + rect.width * 0.07, y: rect.minY))
            path.line(to: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.08))
            path.line(to: CGPoint(x: rect.maxX - tipInset, y: rect.minY + rect.height * 0.18))
            path.line(to: CGPoint(x: rect.maxX - tipInset, y: rect.maxY - rect.height * 0.18))
            path.line(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - rect.height * 0.08))
            path.line(to: CGPoint(x: rect.midX + rect.width * 0.07, y: rect.maxY))
        }

        path.close()
        let fillColor = side == .left ? AppIconPalette.cursorLeft : AppIconPalette.cursorRight
        fillColor.setFill()
        path.fill()
    }

    private static func drawSparkles(in canvas: NSRect) {
        let primarySide = canvas.width * AppIconMetrics.sparkleScale
        let primaryRect = NSRect(
            x: canvas.minX + canvas.width * 0.60,
            y: canvas.minY + canvas.height * 0.38,
            width: primarySide,
            height: primarySide
        )
        drawSparkle(in: primaryRect, color: AppIconPalette.sparklePrimary)

        let secondarySide = primarySide * 0.48
        let secondaryRect = NSRect(
            x: primaryRect.maxX - secondarySide * 0.10,
            y: primaryRect.midY + secondarySide * 0.18,
            width: secondarySide,
            height: secondarySide
        )
        drawSparkle(in: secondaryRect, color: AppIconPalette.sparkleSecondary)
    }

    private static func drawSparkle(in rect: NSRect, color: NSColor) {
        let path = NSBezierPath()
        let midX = rect.midX
        let midY = rect.midY

        path.move(to: CGPoint(x: midX, y: rect.maxY))
        path.line(to: CGPoint(x: midX + rect.width * 0.14, y: midY + rect.height * 0.14))
        path.line(to: CGPoint(x: rect.maxX, y: midY))
        path.line(to: CGPoint(x: midX + rect.width * 0.14, y: midY - rect.height * 0.14))
        path.line(to: CGPoint(x: midX, y: rect.minY))
        path.line(to: CGPoint(x: midX - rect.width * 0.14, y: midY - rect.height * 0.14))
        path.line(to: CGPoint(x: rect.minX, y: midY))
        path.line(to: CGPoint(x: midX - rect.width * 0.14, y: midY + rect.height * 0.14))
        path.close()

        color.setFill()
        path.fill()
    }

    private static func drawStatusCursor(in canvas: NSRect) {
        let height = canvas.height * 0.84
        let rect = NSRect(
            x: canvas.minX + canvas.width * 0.20,
            y: canvas.midY - height / 2,
            width: canvas.width * 0.32,
            height: height
        )

        drawStatusCursorCenter(in: rect)
        drawStatusCursorWing(in: rect, side: .left)
        drawStatusCursorWing(in: rect, side: .right)
    }

    private static func drawStatusCursorCenter(in rect: NSRect) {
        let centerRect = NSRect(
            x: rect.midX - rect.width * 0.11,
            y: rect.minY,
            width: rect.width * 0.22,
            height: rect.height
        )
        AppIconPalette.statusTemplate.setFill()
        NSBezierPath(rect: centerRect).fill()
    }

    private static func drawStatusCursorWing(in rect: NSRect, side: CursorWingSide) {
        let path = NSBezierPath()
        let outerInset = rect.width * 0.18

        if side == .left {
            path.move(to: CGPoint(x: rect.midX - rect.width * 0.11, y: rect.minY))
            path.line(to: CGPoint(x: rect.minX + outerInset, y: rect.minY + rect.height * 0.12))
            path.line(to: CGPoint(x: rect.minX, y: rect.midY))
            path.line(to: CGPoint(x: rect.minX + outerInset, y: rect.maxY - rect.height * 0.12))
            path.line(to: CGPoint(x: rect.midX - rect.width * 0.11, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.midX + rect.width * 0.11, y: rect.minY))
            path.line(to: CGPoint(x: rect.maxX - outerInset, y: rect.minY + rect.height * 0.12))
            path.line(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.line(to: CGPoint(x: rect.maxX - outerInset, y: rect.maxY - rect.height * 0.12))
            path.line(to: CGPoint(x: rect.midX + rect.width * 0.11, y: rect.maxY))
        }

        path.close()
        AppIconPalette.statusTemplate.setFill()
        path.fill()
    }

    private static func drawStatusSparkle(in canvas: NSRect) {
        let rect = NSRect(
            x: canvas.minX + canvas.width * 0.58,
            y: canvas.minY + canvas.height * 0.56,
            width: canvas.width * 0.24,
            height: canvas.height * 0.24
        )
        drawSparkle(in: rect, color: AppIconPalette.statusTemplate)
    }
}

struct IconsetEntry: Equatable {
    let fileName: String
    let pixelSize: CGFloat
}

private enum CursorWingSide {
    case left
    case right
}
