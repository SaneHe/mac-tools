import XCTest
import AppKit
@testable import MacTextActionsApp

final class AppIconFactoryTests: XCTestCase {
    func testApplicationIconUsesRequestedSize() {
        let icon = AppIconFactory.makeApplicationIcon(size: 256)

        XCTAssertEqual(icon.size.width, 256)
        XCTAssertEqual(icon.size.height, 256)
    }

    func testStatusBarIconUsesTemplateRendering() {
        let icon = AppIconFactory.makeStatusBarIcon(size: 18)

        XCTAssertTrue(icon.isTemplate)
    }

    func testApplicationIconContainsBlueCursorAccent() throws {
        let color = try sampleApplicationIconColor(at: CGPoint(x: 0.5, y: 0.53))

        XCTAssertGreaterThan(color.blueComponent, 0.70)
        XCTAssertGreaterThan(color.blueComponent, color.redComponent)
        XCTAssertGreaterThan(color.blueComponent, color.greenComponent)
    }

    func testApplicationIconContainsWarmSparkleAccent() throws {
        XCTAssertTrue(try containsWarmSparkleAccent())
    }

    func testApplicationIconSupportsStandardIconsetSizes() {
        let expectedSizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
        let actualSizes = AppIconFactory.iconsetSizes

        XCTAssertEqual(actualSizes, expectedSizes)
        for size in actualSizes {
            let icon = AppIconFactory.makeApplicationIcon(size: size)
            XCTAssertEqual(icon.size.width, size)
            XCTAssertEqual(icon.size.height, size)
        }
    }

    func testApplicationIconExportsStandardIconsetEntries() {
        let entries = AppIconFactory.iconsetEntries

        XCTAssertEqual(
            entries.map(\.fileName),
            [
                "icon_16x16.png",
                "icon_16x16@2x.png",
                "icon_32x32.png",
                "icon_32x32@2x.png",
                "icon_128x128.png",
                "icon_128x128@2x.png",
                "icon_256x256.png",
                "icon_256x256@2x.png",
                "icon_512x512.png",
                "icon_512x512@2x.png"
            ]
        )
        XCTAssertEqual(
            entries.map(\.pixelSize),
            [16, 32, 32, 64, 128, 256, 256, 512, 512, 1024]
        )
    }
}

private extension AppIconFactoryTests {
    func containsWarmSparkleAccent() throws -> Bool {
        let iconSize: CGFloat = 256
        let icon = AppIconFactory.makeApplicationIcon(size: iconSize)
        guard let tiffData = icon.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw SamplingError.bitmapUnavailable
        }

        for y in stride(from: 0, to: bitmap.pixelsHigh, by: 4) {
            for x in stride(from: 0, to: bitmap.pixelsWide, by: 4) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    continue
                }
                if isWarmSparkleColor(color) {
                    return true
                }
            }
        }

        return false
    }

    func sampleApplicationIconColor(at normalizedPoint: CGPoint) throws -> NSColor {
        let iconSize: CGFloat = 256
        let icon = AppIconFactory.makeApplicationIcon(size: iconSize)
        let point = CGPoint(
            x: normalizedPoint.x * iconSize,
            y: normalizedPoint.y * iconSize
        )
        return try sampleColor(from: icon, at: point)
    }

    func sampleColor(from image: NSImage, at point: CGPoint) throws -> NSColor {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw SamplingError.bitmapUnavailable
        }

        let pixelX = clampPixelIndex(Int(point.x.rounded(.down)), limit: bitmap.pixelsWide)
        let pixelY = clampPixelIndex(Int(point.y.rounded(.down)), limit: bitmap.pixelsHigh)

        guard let color = bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB) else {
            throw SamplingError.colorUnavailable
        }

        return color
    }

    func clampPixelIndex(_ value: Int, limit: Int) -> Int {
        max(0, min(limit - 1, value))
    }

    func isWarmSparkleColor(_ color: NSColor) -> Bool {
        color.redComponent > 0.80 &&
        color.greenComponent > 0.72 &&
        color.redComponent > color.blueComponent &&
        color.greenComponent > color.blueComponent
    }
}

private enum SamplingError: Error {
    case bitmapUnavailable
    case colorUnavailable
}
