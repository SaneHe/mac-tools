import AppKit
import SwiftUI

/// Presentational shell for loading, content, and error states of the result panel.
struct ResultPanelView: View {
    let state: ResultPanelState
    let onActionSelected: (ResultActionKind) -> Void
    let onRefreshSelected: () -> Void

    // MARK: - View

    var body: some View {
        Group {
            switch state {
            case .loading(let title, let subtitle):
                panelContainer {
                    loadingView(title: title, subtitle: subtitle)
                }
            case .content(let content):
                panelContainer {
                    contentView(content)
                }
            case .error(let error):
                panelContainer {
                    errorView(error)
                }
            }
        }
    }

    // MARK: - Layout

    // Keep the glassy card treatment in one place so all panel states share the same chrome.
    private func panelContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private func loadingView(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            panelHeader(title: title, subtitle: subtitle, tint: .secondary)

            HStack(spacing: 12) {
                ProgressView()
                Text("等待加载选中文本预览或演示状态。")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Button("刷新") {
                onRefreshSelected()
            }
            .buttonStyle(.bordered)
        }
    }

    private func contentView(_ content: ResultPanelContent) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            panelHeader(title: content.title, subtitle: content.subtitle, tint: .accentColor)

            ScrollView {
                Text(content.primaryResult)
                    .font(primaryResultFont(for: content.presentationStyle))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.black.opacity(0.08))
                    )
            }
            .frame(minHeight: 160)

            if let footerNote = content.footerNote {
                Text(footerNote)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            actionList(content.actions)
        }
    }

    private func errorView(_ error: ResultPanelError) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            panelHeader(title: error.title, subtitle: "错误状态", tint: .red)

            Text(error.message)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.red.opacity(0.08))
                )

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Button("刷新") {
                onRefreshSelected()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Shared Components

    private func panelHeader(title: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Capsule()
                    .fill(tint.opacity(0.18))
                    .frame(width: 10, height: 10)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private func actionList(_ actions: [ResultActionKind]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("动作")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)

            WrapButtons(actions: actions, onActionSelected: onActionSelected)
        }
    }

    // MARK: - Styling

    private func primaryResultFont(for style: PanelPresentationStyle) -> Font {
        switch style {
        case .code:
            return .system(.body, design: .monospaced)
        case .text:
            return .system(size: 16, weight: .regular, design: .default)
        case .error:
            return .system(size: 14, weight: .regular, design: .default)
        }
    }
}

private struct WrapButtons: View {
    let actions: [ResultActionKind]
    let onActionSelected: (ResultActionKind) -> Void

    // MARK: - View

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 140), spacing: 10, alignment: .leading)]

        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(actions) { action in
                // Copy is treated as the most common follow-up action in the panel scaffold.
                if action == .copyResult {
                    Button {
                        onActionSelected(action)
                    } label: {
                        Label(action.title, systemImage: action.systemImageName)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        onActionSelected(action)
                    } label: {
                        Label(action.title, systemImage: action.systemImageName)
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.regular)
            }
        }
    }
}
