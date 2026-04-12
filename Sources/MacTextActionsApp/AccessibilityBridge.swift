import AppKit
import ApplicationServices

protocol PasteboardReading {
    var changeCount: Int { get }
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func replaceContents(with text: String?)
}

protocol SelectionCopying {
    func copyCurrentSelection()
}

protocol ClipboardFallbackWaiting {
    func waitForClipboardUpdate(onObservedClipboardUpdate: (() -> Void)?)
}

enum SelectionContentSource: Equatable {
    case selection
    case clipboardFallback

    var displayLabel: String {
        switch self {
        case .selection:
            return "来源：当前选中文本"
        case .clipboardFallback:
            return "来源：剪贴板回退"
        }
    }
}

enum SelectionReadFailure: Equatable {
    case noSelection
    case unsupportedApplication
    case permissionDenied
}

enum SelectionReadResult: Equatable {
    case success(SelectionCapture)
    case fallbackSuccess(text: String, failure: SelectionReadFailure)
    case failure(SelectionReadFailure)
}

final class SelectionReplaceTarget {
    private let applyReplacement: (String) -> Bool

    init(applyReplacement: @escaping (String) -> Bool) {
        self.applyReplacement = applyReplacement
    }

    func replace(with newText: String) -> Bool {
        applyReplacement(newText)
    }
}

struct SelectionCapture: Equatable {
    let text: String
    let replaceTarget: SelectionReplaceTarget?

    var canReplaceSelection: Bool {
        replaceTarget != nil
    }

    static func == (lhs: SelectionCapture, rhs: SelectionCapture) -> Bool {
        lhs.text == rhs.text && lhs.canReplaceSelection == rhs.canReplaceSelection
    }
}

/// 读取当前前台应用选中文本的协议
protocol SelectionReading {
    func readSelectedTextResult() -> SelectionReadResult
    func readSelectedText() -> String?
}

struct SelectionCopyFallbackResolver {
    private let pasteboard: PasteboardReading
    private let selectionCopier: SelectionCopying
    private let waitStrategy: ClipboardFallbackWaiting

    init(
        pasteboard: PasteboardReading,
        selectionCopier: SelectionCopying,
        waitStrategy: ClipboardFallbackWaiting
    ) {
        self.pasteboard = pasteboard
        self.selectionCopier = selectionCopier
        self.waitStrategy = waitStrategy
    }

    func resolve(failure: SelectionReadFailure) -> SelectionReadResult {
        let initialChangeCount = pasteboard.changeCount
        let originalClipboardText = pasteboard.string(forType: .string)
        selectionCopier.copyCurrentSelection()
        var observedFallbackText: String?

        let captureObservedClipboardText = {
            guard observedFallbackText == nil,
                  pasteboard.changeCount != initialChangeCount,
                  let clipboardText = pasteboard.string(forType: .string)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !clipboardText.isEmpty else {
                return
            }

            observedFallbackText = clipboardText
        }

        waitStrategy.waitForClipboardUpdate(
            onObservedClipboardUpdate: captureObservedClipboardText
        )
        captureObservedClipboardText()

        guard let fallbackText = observedFallbackText else {
            return .failure(failure)
        }

        restoreClipboardIfStillShowingFallbackText(
            fallbackText: fallbackText,
            originalClipboardText: originalClipboardText
        )

        return .fallbackSuccess(text: fallbackText, failure: failure)
    }

    private func restoreClipboardIfStillShowingFallbackText(
        fallbackText: String,
        originalClipboardText: String?
    ) {
        let currentClipboardText = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard currentClipboardText == fallbackText else {
            return
        }

        pasteboard.replaceContents(with: originalClipboardText)
    }
}

extension NSPasteboard: PasteboardReading {
    func replaceContents(with text: String?) {
        clearContents()

        if let text {
            setString(text, forType: .string)
        }
    }
}

struct SystemClipboardWaiter: ClipboardFallbackWaiting {
    private enum Delay {
        static let microseconds: useconds_t = 150_000
    }

    func waitForClipboardUpdate(onObservedClipboardUpdate: (() -> Void)?) {
        usleep(Delay.microseconds)
        onObservedClipboardUpdate?()
    }
}

struct SystemSelectionCopier: SelectionCopying {
    private enum KeyCode {
        static let command: CGKeyCode = 0x37
        static let c: CGKeyCode = 0x08
    }

    func copyCurrentSelection() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return
        }

        let commandDown = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.command, keyDown: true)
        let cDown = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.c, keyDown: true)
        let cUp = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.c, keyDown: false)
        let commandUp = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.command, keyDown: false)

        cDown?.flags = .maskCommand
        cUp?.flags = .maskCommand

        commandDown?.post(tap: .cghidEventTap)
        cDown?.post(tap: .cghidEventTap)
        cUp?.post(tap: .cghidEventTap)
        commandUp?.post(tap: .cghidEventTap)
    }
}

final class AccessibilityBridge: SelectionReading {
    static let shared = AccessibilityBridge()
    private static let pasteboard = NSPasteboard.general
    private let fallbackResolver: SelectionCopyFallbackResolver

    private init(
        pasteboard: PasteboardReading = NSPasteboard.general,
        selectionCopier: SelectionCopying = SystemSelectionCopier(),
        waitStrategy: ClipboardFallbackWaiting = SystemClipboardWaiter()
    ) {
        self.fallbackResolver = SelectionCopyFallbackResolver(
            pasteboard: pasteboard,
            selectionCopier: selectionCopier,
            waitStrategy: waitStrategy
        )
    }

    func readSelectedTextResult() -> SelectionReadResult {
        guard AXIsProcessTrusted() else {
            return .failure(.permissionDenied)
        }

        let systemWide = AXUIElementCreateSystemWide()

        guard let app = focusedApplication(from: systemWide),
              let element = focusedElement(from: app) else {
            return fallbackResolver.resolve(failure: .unsupportedApplication)
        }

        if let text = readDirectSelection(from: element) {
            return .success(
                SelectionCapture(
                    text: text,
                    replaceTarget: makeReplaceTarget(for: element)
                )
            )
        }

        if let text = readSelectionUsingRange(from: element) {
            return .success(
                SelectionCapture(
                    text: text,
                    replaceTarget: makeReplaceTarget(for: element)
                )
            )
        }

        if hasCollapsedSelection(in: element) {
            return fallbackResolver.resolve(failure: .noSelection)
        }

        return fallbackResolver.resolve(failure: .unsupportedApplication)
    }

    func readSelectedText() -> String? {
        guard case let .success(capture) = readSelectedTextResult() else {
            return nil
        }
        return capture.text
    }

    @discardableResult
    func replaceSelectedText(with newText: String, using target: SelectionReplaceTarget?) -> Bool {
        guard let target else {
            return false
        }

        return target.replace(with: newText)
    }

    private func focusedApplication(from systemWide: AXUIElement) -> AXUIElement? {
        var focusedApp: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedApp
        )
        guard result == .success, let app = focusedApp else {
            return nil
        }
        return (app as! AXUIElement)
    }

    private func focusedElement(from app: AXUIElement) -> AXUIElement? {
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            app,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard result == .success, let element = focusedElement else {
            return nil
        }
        return (element as! AXUIElement)
    }

    private func readDirectSelection(from element: AXUIElement) -> String? {
        var selectedText: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        guard result == .success,
              let text = selectedText as? String,
              !text.isEmpty else {
            return nil
        }
        return text
    }

    private func readSelectionUsingRange(from element: AXUIElement) -> String? {
        guard let selectedRange = selectedRange(from: element),
              selectedRange.length > 0,
              let fullText = fullTextValue(from: element) else {
            return nil
        }

        let nsText = fullText as NSString
        guard NSMaxRange(selectedRange) <= nsText.length else {
            return nil
        }
        return nsText.substring(with: selectedRange)
    }

    private func hasCollapsedSelection(in element: AXUIElement) -> Bool {
        guard let selectedRange = selectedRange(from: element) else {
            return false
        }
        return selectedRange.length == 0
    }

    private func selectedRange(from element: AXUIElement) -> NSRange? {
        var selectedRangeValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeValue
        )
        guard result == .success,
              let value = selectedRangeValue,
              CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = value as! AXValue
        guard AXValueGetType(axValue) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(axValue, .cfRange, &range) else {
            return nil
        }
        return NSRange(location: range.location, length: range.length)
    }

    private func fullTextValue(from element: AXUIElement) -> String? {
        var textValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXValueAttribute as CFString,
            &textValue
        )
        guard result == .success, let text = textValue as? String, !text.isEmpty else {
            return nil
        }
        return text
    }

    private func makeReplaceTarget(for element: AXUIElement) -> SelectionReplaceTarget {
        SelectionReplaceTarget { newText in
            AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextAttribute as CFString,
                newText as CFTypeRef
            ) == .success
        }
    }
}
