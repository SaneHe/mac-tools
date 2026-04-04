import SwiftUI
import MacTextActionsCore

struct LiquidGlassPopover: View {
    let result: TransformResult
    let selectedText: String
    let onCopy: (String) -> Void
    let onReplace: (String) -> Void
    let onClose: () -> Void

    // 最大宽度限制
    private let maxPopoverWidth: CGFloat = 480
    private let minPopoverWidth: CGFloat = 280
    private let popoverHeight: CGFloat = 400

    // 窗帘展开动画状态
    @State private var curtainProgress: CGFloat = 0

    var body: some View {
        ZStack {
            // 内容容器（带窗帘动画）
            contentView
                // 窗帘效果：从顶部开始向下展开
                .mask(
                    VStack(spacing: 0) {
                        Rectangle()
                            .frame(height: popoverHeight * curtainProgress)
                        Spacer()
                    }
                    .frame(height: popoverHeight)
                )
                // 同时添加轻微的向下位移，增强"放下"的感觉
                .offset(y: (1 - curtainProgress) * (-20))
                .opacity(curtainProgress > 0.01 ? 1 : 0)
        }
        .frame(minWidth: minPopoverWidth, maxWidth: maxPopoverWidth, minHeight: 200, maxHeight: popoverHeight)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Material.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 30, x: 0, y: 15)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            curtainProgress = 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.2)) {
                curtainProgress = 1.0
            }
        }
    }

    // MARK: - Content View
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerView

            Divider()
                .background(Color.white.opacity(0.2))

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    // 输入预览
                    inputPreviewSection

                    // 转换结果
                    if let output = result.primaryOutput {
                        resultSection(output: output)
                    }

                    // 错误信息
                    if result.displayMode == .error {
                        errorSection
                    }
                }
                .padding(16)
            }
            .frame(maxHeight: 480)

            Divider()
                .background(Color.white.opacity(0.2))

            // Action buttons
            actionBar
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: detectionIcon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(detectionColor)
                .frame(width: 32, height: 32)
                .background(detectionColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // 标题
            Text(detectionTitle)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primary)

            Spacer()

            // 关闭按钮
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondary.opacity(0.7))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Input Preview
    private var inputPreviewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("原始文本")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            Text(selectedText)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.secondary)
                .lineLimit(3)
                .truncationMode(.tail)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Result Section
    private func resultSection(output: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("转换结果")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.secondary)
                .tracking(0.5)

            Text(output)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(Color.primary)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        }
    }

    // MARK: - Error Section
    private var errorSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.orange)

            Text(result.errorMessage ?? "转换失败")
                .font(.system(size: 13))
                .foregroundStyle(Color.orange)
                .lineLimit(2)

            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Action Bar
    private var actionBar: some View {
        HStack(spacing: 8) {
            if let output = result.primaryOutput {
                Button {
                    onCopy(output)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 11, weight: .medium))
                        Text("复制")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                if result.secondaryActions.contains(.replaceSelection) {
                    Button {
                        onReplace(output)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.2.circlepath")
                                .font(.system(size: 11, weight: .medium))
                            Text("替换")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Color.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Helpers
    private var detectionTitle: String {
        switch result.displayMode {
        case .code: return "JSON 格式化"
        case .text: return contentTypeTitle
        case .error: return "转换失败"
        case .actionsOnly: return "文本工具"
        }
    }

    private var contentTypeTitle: String {
        // 根据 primaryOutput 的内容判断类型
        if let output = result.primaryOutput {
            if output.contains("-") && output.count == 10 {
                return "时间戳转换"
            }
            if output.hasPrefix("http") || output.contains("://") {
                return "URL 解码"
            }
        }
        return "文本转换"
    }

    private var detectionIcon: String {
        switch result.displayMode {
        case .code: return "curlybraces"
        case .text:
            if contentTypeTitle == "时间戳转换" { return "clock" }
            if contentTypeTitle == "URL 解码" { return "link" }
            return "text.alignleft"
        case .error: return "exclamationmark.triangle"
        case .actionsOnly: return "wand.and.stars"
        }
    }

    private var detectionColor: Color {
        switch result.displayMode {
        case .code: return .purple
        case .text:
            if contentTypeTitle == "时间戳转换" { return .orange }
            if contentTypeTitle == "URL 解码" { return .green }
            return .blue
        case .error: return .red
        case .actionsOnly: return .gray
        }
    }
}
