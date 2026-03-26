import XCTest
@testable import MacTextActionsApp

@MainActor
final class AppShellViewModelTests: XCTestCase {
    func testRefreshFromSelectionUsesChineseReadFailureMessage() {
        let services = AppServices(
            selectionReader: MockSelectionReader(),
            actionExecutor: MockActionExecutor()
        )
        let viewModel = AppShellViewModel(services: services)

        viewModel.refreshFromSelection()

        guard case let .error(error) = viewModel.panelState else {
            return XCTFail("Expected error state")
        }

        XCTAssertEqual(error.title, "未检测到选中文本")
        XCTAssertEqual(error.message, "无法读取当前选中的文本。")
        XCTAssertEqual(error.recoverySuggestion, "请在受支持的应用中选中文本后重试。")
    }
}
