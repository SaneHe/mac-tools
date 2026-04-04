import AppKit
import ApplicationServices

enum SelectionReadFailure: Equatable {
    case noSelection
    case unsupportedApplication
    case permissionDenied
}

enum SelectionReadResult: Equatable {
    case success(String)
    case failure(SelectionReadFailure)
}

/// 读取当前前台应用选中文本的协议
protocol SelectionReading {
    func readSelectedTextResult() -> SelectionReadResult
    func readSelectedText() -> String?
}

final class AccessibilityBridge: SelectionReading {
    static let shared = AccessibilityBridge()

    private init() {}

    func readSelectedTextResult() -> SelectionReadResult {
        guard AXIsProcessTrusted() else {
            return .failure(.permissionDenied)
        }

        let systemWide = AXUIElementCreateSystemWide()

        guard let app = focusedApplication(from: systemWide),
              let element = focusedElement(from: app) else {
            return .failure(.unsupportedApplication)
        }

        if let text = readDirectSelection(from: element) {
            return .success(text)
        }

        if let text = readSelectionUsingRange(from: element) {
            return .success(text)
        }

        if hasCollapsedSelection(in: element) {
            return .failure(.noSelection)
        }

        return .failure(.unsupportedApplication)
    }

    func readSelectedText() -> String? {
        guard case let .success(text) = readSelectedTextResult() else {
            return nil
        }
        return text
    }

    func replaceSelectedText(with newText: String) {
        let systemWide = AXUIElementCreateSystemWide()

        // 获取聚焦的应用程序
        var focusedApp: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success,
              let app = focusedApp else {
            return
        }

        // 获取应用程序中聚焦的元素
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else {
            return
        }

        // 替换选中的文本
        AXUIElementSetAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, newText as CFTypeRef)
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
}
