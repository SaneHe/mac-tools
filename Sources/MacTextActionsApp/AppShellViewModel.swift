import Foundation

@MainActor
/// Coordinates preview data sources with the result panel state shown by the demo app shell.
final class AppShellViewModel: ObservableObject {
    @Published var demoScenario: DemoScenario
    @Published private(set) var panelState: ResultPanelState
    @Published private(set) var activityMessage: String

    private let services: AppServices
    private let contentFactory: PanelContentFactory
    private let previewSelectionReader: MockSelectionReader?

    init(
        services: AppServices,
        initialScenario: DemoScenario = .json,
        contentFactory: PanelContentFactory = PanelContentFactory()
    ) {
        self.services = services
        self.contentFactory = contentFactory
        self.demoScenario = initialScenario
        self.panelState = .loading(title: "Mac 文本动作", subtitle: "等待读取选中文本")
        self.activityMessage = "当前处于演示模式。"
        self.previewSelectionReader = services.selectionReader as? MockSelectionReader
        loadDemoScenario(initialScenario)
    }

    convenience init() {
        self.init(services: .preview())
    }

    static func preview() -> AppShellViewModel {
        AppShellViewModel()
    }

    // MARK: - Demo State

    func loadDemoScenario(_ scenario: DemoScenario) {
        demoScenario = scenario
        previewSelectionReader?.selectedText = scenario.sampleSelectionText
        refreshFromSelection()
        activityMessage = "已加载 \(scenario.title) 演示内容。"
    }

    // MARK: - Panel Updates

    func refreshFromSelection() {
        // Follow the product rule: show an explicit error when selected text cannot be read.
        guard let selectedText = services.selectionReader.readSelectedText() else {
            panelState = .error(
                ResultPanelError(
                    title: "未检测到选中文本",
                    message: "无法读取当前选中的文本。",
                    recoverySuggestion: "请在受支持的应用中选中文本后重试。"
                )
            )
            return
        }

        panelState = contentFactory.makeState(from: selectedText)
    }

    // MARK: - Actions

    func performAction(_ action: ResultActionKind) {
        guard case let .content(content) = panelState else {
            activityMessage = "当前没有可执行的动作。"
            return
        }

        activityMessage = services.actionExecutor.execute(action, content: content)
    }
}
