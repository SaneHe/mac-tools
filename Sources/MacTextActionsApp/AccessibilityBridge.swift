import AppKit
import ApplicationServices

final class AccessibilityBridge {
    static let shared = AccessibilityBridge()

    private init() {}

    func readSelectedText() -> String? {
        guard let focusedElement = AXUIElementCreateSystemWide() as AXUIElement? else {
            return nil
        }

        var selectedTextValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextValue
        )

        guard result == .success,
              let text = selectedTextValue as? String,
              !text.isEmpty else {
            return nil
        }

        return text
    }

    func replaceSelectedText(with newText: String) {
        guard let focusedElement = AXUIElementCreateSystemWide() as AXUIElement? else {
            return
        }

        AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            newText as CFTypeRef
        )
    }
}
