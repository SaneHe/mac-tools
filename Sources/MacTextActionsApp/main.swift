import AppKit
import Foundation
import SwiftUI

private var appDelegate: AppDelegate?

if let exportDirectory = IconExportCommand.exportDirectory(from: CommandLine.arguments) {
    do {
        try AppIconExporter.exportIconset(to: exportDirectory)
        exit(EXIT_SUCCESS)
    } catch {
        fputs("导出应用图标失败: \(error.localizedDescription)\n", stderr)
        exit(EXIT_FAILURE)
    }
}

let app = NSApplication.shared
appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()

private enum IconExportCommand {
    private static let flag = "--export-app-iconset"

    static func exportDirectory(from arguments: [String]) -> URL? {
        guard let flagIndex = arguments.firstIndex(of: flag),
              arguments.indices.contains(flagIndex + 1) else {
            return nil
        }

        return URL(fileURLWithPath: arguments[flagIndex + 1], isDirectory: true)
    }
}

private enum AppIconExporter {
    static func exportIconset(to directoryURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        for entry in AppIconFactory.iconsetEntries {
            let fileURL = directoryURL.appendingPathComponent(entry.fileName)
            let image = AppIconFactory.makeApplicationIcon(size: entry.pixelSize)
            let pngData = try pngData(from: image)
            try pngData.write(to: fileURL)
        }
    }

    private static func pngData(from image: NSImage) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw IconExportError.pngEncodingFailed
        }

        return pngData
    }
}

private enum IconExportError: LocalizedError {
    case pngEncodingFailed

    var errorDescription: String? {
        switch self {
        case .pngEncodingFailed:
            return "无法将图标编码为 PNG"
        }
    }
}
