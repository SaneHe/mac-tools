import XCTest
@testable import MacTextActionsApp

@MainActor
final class ToolWorkspaceViewModelTests: XCTestCase {
    func testChangingSelectedToolClearsInputAndOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.contentViewModel.inputText = "1711111111"
        viewModel.contentViewModel.outputText = "2024-03-22 10:38:31"

        viewModel.selectedTool = .md5

        XCTAssertEqual(viewModel.contentViewModel.inputText, "")
        XCTAssertEqual(viewModel.contentViewModel.outputText, "")
    }

    func testSelectingToolByShortcutClearsInputAndOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.contentViewModel.inputText = "{\"name\":\"mac\"}"
        viewModel.contentViewModel.outputText = "formatted"

        viewModel.selectTool(usingShortcut: 4)

        XCTAssertEqual(viewModel.selectedTool, .url)
        XCTAssertEqual(viewModel.contentViewModel.inputText, "")
        XCTAssertEqual(viewModel.contentViewModel.outputText, "")
    }

    func testPerformPrimaryActionUsesSelectedTool() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.selectedTool = .md5
        viewModel.contentViewModel.inputText = "hello"

        viewModel.performPrimaryAction()

        XCTAssertEqual(
            viewModel.contentViewModel.outputText,
            "5d41402abc4b2a76b9719d911017c592"
        )
    }

    func testClearCurrentToolContentClearsInputAndOutput() {
        let viewModel = ToolWorkspaceViewModel()
        viewModel.contentViewModel.inputText = "1711111111"
        viewModel.contentViewModel.outputText = "2024-03-22 10:38:31"

        viewModel.clearCurrentToolContent()

        XCTAssertEqual(viewModel.contentViewModel.inputText, "")
        XCTAssertEqual(viewModel.contentViewModel.outputText, "")
    }

    func testCopyCurrentOutputWritesOutputText() {
        let outputCopyWriter = OutputCopyWriterSpy()
        let toolContentViewModel = ToolContentViewModel(outputCopyWriter: outputCopyWriter)
        let viewModel = ToolWorkspaceViewModel(contentViewModel: toolContentViewModel)
        viewModel.contentViewModel.outputText = "copied-value"

        let didCopy = viewModel.copyCurrentOutput()

        XCTAssertTrue(didCopy)
        XCTAssertEqual(outputCopyWriter.copiedTexts, ["copied-value"])
    }
}

@MainActor
final class AppSettingsViewModelTests: XCTestCase {
    func testShortcutRecorderStatusMessageUsesBoundShortcutAfterSuccess() {
        let feedback = ShortcutRecorderFeedback.success(
            ShortcutConfiguration(keyCode: 49, modifiers: [.option])
        )

        XCTAssertEqual(feedback.message, "快捷键已绑定为 ⌥+Space")
    }

    func testShortcutDisplayStringUsesModifierSymbolsAndReadableKeyName() {
        let configuration = ShortcutConfiguration(
            keyCode: 49,
            modifiers: [.option, .shift]
        )

        XCTAssertEqual(configuration.displayString, "⌥+⇧+Space")
    }

    func testShortcutDisplayStringUsesReadableLetterKeyName() {
        let configuration = ShortcutConfiguration(
            keyCode: 0,
            modifiers: [.command]
        )

        XCTAssertEqual(configuration.displayString, "⌘+A")
    }

    func testShortcutSummaryUsesMenuCommandShortcuts() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: true,
            inputMonitoringAuthorized: true
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(viewModel.globalShortcutDisplayTitle, "全局触发")
        XCTAssertEqual(viewModel.globalShortcutDisplayValue, "⌥+Space")
        XCTAssertEqual(
            viewModel.toolSwitchShortcutDisplayValue,
            "⌘1 自动识别 / ⌘2 创建提醒事项 / ⌘3 JSON 格式化 / ⌘4 JSON Compress / ⌘5 时间戳转本地时间 / ⌘6 日期转时间戳 / ⌘7 MD5；菜单顺序中创建提醒事项位于最后（菜单展开时切换模式）"
        )
    }

    func testPermissionSummaryUsesGrantedCopyWhenAllPermissionsAreReady() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: true,
            inputMonitoringAuthorized: true
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(viewModel.accessibilityPermissionText, "已授权")
        XCTAssertEqual(viewModel.inputMonitoringPermissionText, "已授权")
    }

    func testPermissionSummaryUsesGuidanceCopyWhenPermissionMissing() {
        let permissionStatusProvider = PermissionStatusProviderStub(
            accessibilityAuthorized: false,
            inputMonitoringAuthorized: false
        )
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: permissionStatusProvider
        )

        XCTAssertEqual(viewModel.accessibilityPermissionText, "需要在系统设置中开启")
        XCTAssertEqual(viewModel.inputMonitoringPermissionText, "需要在系统设置中开启")
    }
}

private final class OutputCopyWriterSpy: OutputCopyWriting {
    private(set) var copiedTexts: [String] = []

    func write(_ text: String) {
        copiedTexts.append(text)
    }
}

private struct PermissionStatusProviderStub: PermissionStatusProviding {
    let accessibilityAuthorized: Bool
    let inputMonitoringAuthorized: Bool

    func isAccessibilityAuthorized() -> Bool {
        accessibilityAuthorized
    }

    func isInputMonitoringAuthorized() -> Bool {
        inputMonitoringAuthorized
    }
}
