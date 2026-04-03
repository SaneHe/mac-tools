import AppKit
import ApplicationServices

final class AccessibilityBridge {
    static let shared = AccessibilityBridge()

    private init() {}

    func readSelectedText() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        // 获取聚焦的应用程序
        var focusedApp: CFTypeRef?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success,
              let app = focusedApp else {
            return nil
        }

        // 获取应用程序中聚焦的元素
        var focusedElement: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app as! AXUIElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
              let element = focusedElement else {
            return nil
        }

        // 获取选中的文本
        var selectedText: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)

        guard result == .success,
              let text = selectedText as? String,
              !text.isEmpty else {
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
}
