import XCTest
@testable import MacTextActionsApp

@MainActor
final class KeyboardMonitorTests: XCTestCase {
    func testStartRegistersCurrentShortcutConfiguration() {
        let hotKeyController = HotKeyControllerSpy()
        let configuration = ShortcutConfiguration(keyCode: 0, modifiers: [.command])
        let monitor = KeyboardMonitor(
            configuration: configuration,
            hotKeyController: hotKeyController
        )

        monitor.start()

        XCTAssertEqual(hotKeyController.registerCallCount, 1)
        XCTAssertEqual(hotKeyController.lastConfiguration, configuration)
    }

    func testEnsureActiveStartsRegistrationWhenMonitorIsIdle() {
        let hotKeyController = HotKeyControllerSpy()
        let monitor = KeyboardMonitor(hotKeyController: hotKeyController)

        monitor.ensureActive()

        XCTAssertEqual(hotKeyController.registerCallCount, 1)
    }

    func testEnsureActiveReRegistersWhenControllerIsPaused() {
        let hotKeyController = HotKeyControllerSpy()
        let monitor = KeyboardMonitor(hotKeyController: hotKeyController)

        monitor.start()
        hotKeyController.isPaused = true

        monitor.ensureActive()

        XCTAssertEqual(hotKeyController.registerCallCount, 2)
        XCTAssertEqual(hotKeyController.unregisterCallCount, 1)
    }

    func testUpdateConfigurationReRegistersWhenAlreadyMonitoring() {
        let hotKeyController = HotKeyControllerSpy()
        let monitor = KeyboardMonitor(hotKeyController: hotKeyController)
        let updatedConfiguration = ShortcutConfiguration(keyCode: 1, modifiers: [.control])

        monitor.start()
        monitor.updateConfiguration(updatedConfiguration)

        XCTAssertEqual(hotKeyController.registerCallCount, 2)
        XCTAssertEqual(hotKeyController.lastConfiguration, updatedConfiguration)
    }

    func testUnsupportedConfigurationDoesNotRegisterHotKey() {
        let hotKeyController = HotKeyControllerSpy()
        let configuration = ShortcutConfiguration(
            keyCode: ShortcutConfiguration.KeyCode.space,
            modifiers: [.function]
        )
        let monitor = KeyboardMonitor(
            configuration: configuration,
            hotKeyController: hotKeyController
        )

        monitor.start()

        XCTAssertEqual(hotKeyController.registerCallCount, 0)
    }

    func testRegisteredShortcutDispatchesCallback() {
        let hotKeyController = HotKeyControllerSpy()
        let monitor = KeyboardMonitor(hotKeyController: hotKeyController)
        let expectation = expectation(description: "shortcut callback")

        monitor.onShortcutTriggered = {
            expectation.fulfill()
        }

        monitor.start()
        hotKeyController.trigger()

        wait(for: [expectation], timeout: 1)
    }
}

private final class HotKeyControllerSpy: HotKeyControlling {
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    private(set) var lastConfiguration: ShortcutConfiguration?
    var isRegistered = false
    var isPaused = false

    private var handler: (() -> Void)?

    func register(
        configuration: ShortcutConfiguration,
        handler: @escaping () -> Void
    ) {
        registerCallCount += 1
        lastConfiguration = configuration
        isRegistered = true
        isPaused = false
        self.handler = handler
    }

    func unregister() {
        if isRegistered {
            unregisterCallCount += 1
        }

        isRegistered = false
        isPaused = false
        handler = nil
    }

    func trigger() {
        handler?()
    }
}
