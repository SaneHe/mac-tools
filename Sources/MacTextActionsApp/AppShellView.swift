import SwiftUI

/// Demo host view for the floating result panel scaffold.
struct AppShellView: View {
    @ObservedObject var viewModel: AppShellViewModel

    var body: some View {
        VStack(spacing: 16) {
            header

            ResultPanelView(
                state: viewModel.panelState,
                onActionSelected: viewModel.performAction(_:),
                onRefreshSelected: viewModel.refreshFromSelection
            )

            footer
        }
        .padding(20)
        .frame(minWidth: 620, minHeight: 460)
        .background(windowBackdrop)
        .macTextActionsWindowStyle()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mac 文本动作")
                    .font(.system(size: 22, weight: .semibold, design: .default))

                Text("以结果面板为核心的演示界面骨架。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Picker("演示场景", selection: $viewModel.demoScenario) {
                ForEach(DemoScenario.allCases) { scenario in
                    Text(scenario.title).tag(scenario)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: 180)

            Button("加载") {
                viewModel.loadDemoScenario(viewModel.demoScenario)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var footer: some View {
        HStack {
            Text(viewModel.activityMessage)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Spacer()

            Button("从选中文本刷新") {
                viewModel.refreshFromSelection()
            }
            .buttonStyle(.bordered)
        }
    }

    private var windowBackdrop: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
    }
}
