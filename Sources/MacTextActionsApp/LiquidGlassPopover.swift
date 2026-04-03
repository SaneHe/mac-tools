import SwiftUI
import MacTextActionsCore

struct LiquidGlassPopover: View {
    let result: TransformResult
    let selectedText: String
    let onCopy: (String) -> Void
    let onReplace: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(detectionTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Input preview
            Text(selectedText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(8)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)

            // Result
            if let output = result.primaryOutput {
                Text(output)
                    .font(.system(size: 14, design: .monospaced))
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            }

            // Error
            if result.displayMode == .error {
                Text(result.errorMessage ?? "未知错误")
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }

            // Action buttons
            HStack(spacing: 8) {
                if let output = result.primaryOutput {
                    Button("复制") {
                        onCopy(output)
                    }
                    .buttonStyle(.borderedProminent)

                    if result.secondaryActions.contains(.replaceSelection) {
                        Button("替换") {
                            onReplace(output)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var detectionTitle: String {
        switch result.displayMode {
        case .code: return "JSON 格式化"
        case .text: return "文本转换"
        case .error: return "转换失败"
        case .actionsOnly: return "可用操作"
        }
    }
}
