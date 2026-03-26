import AppKit
import SwiftUI

/// SwiftUI bridge that exposes the backing NSWindow once it exists.
struct MacTextActionsWindowConfigurator: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> WindowAccessorView {
        WindowAccessorView(configure: configure)
    }

    func updateNSView(_ nsView: WindowAccessorView, context: Context) {
        nsView.configure = configure
        nsView.applyConfigurationIfNeeded()
    }

    final class WindowAccessorView: NSView {
        var configure: (NSWindow) -> Void
        private var didConfigure = false

        init(configure: @escaping (NSWindow) -> Void) {
            self.configure = configure
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            applyConfigurationIfNeeded()
        }

        func applyConfigurationIfNeeded() {
            guard !didConfigure, let window = window else {
                return
            }

            didConfigure = true
            configure(window)
        }
    }
}

extension View {
    func macTextActionsWindowStyle() -> some View {
        background(
            MacTextActionsWindowConfigurator { window in
                // Match the docs' floating utility-panel direction without introducing a custom window controller yet.
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = true
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
                window.styleMask.insert(.fullSizeContentView)
            }
        )
    }
}
