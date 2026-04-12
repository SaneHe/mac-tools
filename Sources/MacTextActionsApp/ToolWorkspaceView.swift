import SwiftUI

@MainActor
final class ToolWorkspaceViewModel: ObservableObject {
    @Published var selectedTool: ToolType = .timestamp {
        didSet {
            guard oldValue != selectedTool else { return }
            contentViewModel.clear()
        }
    }

    let contentViewModel: ToolContentViewModel
    let copyFeedbackState: CopyFeedbackState

    init(
        contentViewModel: ToolContentViewModel,
        copyFeedbackState: CopyFeedbackState
    ) {
        self.contentViewModel = contentViewModel
        self.copyFeedbackState = copyFeedbackState
    }

    convenience init(contentViewModel: ToolContentViewModel? = nil) {
        self.init(
            contentViewModel: contentViewModel ?? ToolContentViewModel(),
            copyFeedbackState: CopyFeedbackState()
        )
    }

    func selectTool(usingShortcut shortcut: Int) {
        guard ToolType.allCases.indices.contains(shortcut - 1) else { return }
        selectedTool = ToolType.allCases[shortcut - 1]
    }

    func performPrimaryAction() {
        contentViewModel.performTransform(for: selectedTool)
    }

    func clearCurrentToolContent() {
        contentViewModel.clear()
    }

    @discardableResult
    func copyCurrentOutput() -> Bool {
        let didCopy = contentViewModel.copyOutput()
        if didCopy {
            copyFeedbackState.show()
        }
        return didCopy
    }
}

@MainActor
struct ToolWorkspaceView: View {
    @StateObject private var viewModel: ToolWorkspaceViewModel

    init(viewModel: ToolWorkspaceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        _viewModel = StateObject(wrappedValue: ToolWorkspaceViewModel())
    }

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                selectedTool: $viewModel.selectedTool
            )
            .frame(width: SettingsChrome.sidebarWidth)

            workspaceSurface
        }
        .background(SettingsChrome.windowBackground)
        .ignoresSafeArea(.container, edges: .top)
        .overlay {
            CopyFeedbackHUD(
                isVisible: viewModel.copyFeedbackState.isVisible,
                replayToken: viewModel.copyFeedbackState.replayToken
            )
        }
    }

    private var workspaceSurface: some View {
        SplitWorkspaceSurface {
            ToolContentView(
                tool: viewModel.selectedTool,
                viewModel: viewModel.contentViewModel,
                onCopyOutput: {
                    viewModel.copyCurrentOutput()
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SettingsChrome.workspaceBackground)
        }
    }
}
