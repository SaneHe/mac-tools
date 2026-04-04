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

    init(contentViewModel: ToolContentViewModel) {
        self.contentViewModel = contentViewModel
    }

    convenience init(contentViewModel: ToolContentViewModel? = nil) {
        self.init(contentViewModel: contentViewModel ?? ToolContentViewModel())
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
        contentViewModel.copyOutput()
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
    }

    private var workspaceSurface: some View {
        SplitWorkspaceSurface {
            ToolContentView(
                tool: viewModel.selectedTool,
                viewModel: viewModel.contentViewModel
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SettingsChrome.workspaceBackground)
        }
    }
}
