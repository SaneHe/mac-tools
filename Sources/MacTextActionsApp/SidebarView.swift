import SwiftUI

enum ToolType: String, CaseIterable, Identifiable {
    case timestamp = "时间戳转换"
    case json = "JSON 格式化"
    case md5 = "MD5 加密"
    case url = "URL 编解码"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timestamp: return "clock.arrow.circlepath"
        case .json: return "curlybraces"
        case .md5: return "number"
        case .url: return "link"
        }
    }

    var shortTitle: String {
        switch self {
        case .timestamp: return "时间"
        case .json: return "JSON"
        case .md5: return "MD5"
        case .url: return "URL"
        }
    }

    var summary: String {
        switch self {
        case .timestamp: return "时间戳与日期互转"
        case .json: return "格式化与校验结构化文本"
        case .md5: return "快速生成固定长度摘要"
        case .url: return "编码与解码链接文本"
        }
    }

    var actionTitle: String {
        switch self {
        case .timestamp: return "开始转换"
        case .json: return "格式化结果"
        case .md5: return "生成 MD5"
        case .url: return "处理 URL"
        }
    }

    var placeholder: String {
        switch self {
        case .timestamp:
            return "输入时间戳或日期"
        case .json:
            return "粘贴 JSON 文本"
        case .md5:
            return "输入任意文本"
        case .url:
            return "输入 URL 或文本"
        }
    }

    var resultTitle: String {
        switch self {
        case .timestamp: return "转换结果"
        case .json: return "格式化结果"
        case .md5: return "摘要结果"
        case .url: return "编码结果"
        }
    }

    var supportNotes: [String] {
        switch self {
        case .timestamp:
            return ["自动识别秒级与毫秒级输入", "结果栏可切换秒级与毫秒级", "适合排查接口时间字段"]
        case .json:
            return ["保留结构层级", "无效 JSON 显示错误", "结果适合直接复制"]
        case .md5:
            return ["默认输出 32 位小写摘要", "结果栏可切换大小写输出", "不用于密码学安全场景"]
        case .url:
            return ["默认执行编码", "适合参数调试", "避免手工转义遗漏"]
        }
    }

    /// 输入框推荐高度
    var inputHeight: CGFloat {
        switch self {
        case .json: return 220
        case .timestamp: return 60
        case .md5, .url: return 120
        }
    }

    /// 结果区域推荐高度
    var resultHeight: CGFloat {
        switch self {
        case .json: return 300
        case .timestamp: return 80
        case .md5, .url: return 120
        }
    }

    /// 是否需要宽输入框
    var needsWideInput: Bool {
        switch self {
        case .json: return true
        case .md5, .url, .timestamp: return false
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTool: ToolType

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            shortcutHeader

            Divider()
                .background(SettingsChrome.dividerColor)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(ToolType.allCases.enumerated()), id: \.element.id) { index, tool in
                    navigationButton(for: tool, shortcutIndex: index + 1)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 12)

            Spacer()

            bottomStatus
        }
        .padding(.top, 32) // 避开系统按钮区域
        .padding(.bottom, 18)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(SettingsChrome.sidebarBackground)
    }

    private var shortcutHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SettingsChrome.sidebarIconActive)
                .frame(width: 30, height: 30)
                .background(SettingsChrome.sidebarOverlay)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: SettingsChrome.compactCornerRadius,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Mac Text Actions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SettingsChrome.sidebarTextActive)

                Text("文本动作工作区")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SettingsChrome.tertiaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private var bottomStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)

                Text("就绪")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SettingsChrome.sidebarTextActive)

                Spacer()

                Text("v1.0")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SettingsChrome.tertiaryText)
            }

            Text("保持当前选中文本语义不变，只在右侧工作区查看和执行动作。")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(SettingsChrome.sidebarText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(SettingsChrome.sidebarItemActive)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .padding(.horizontal, 12)
    }

    private func navigationButton(for tool: ToolType, shortcutIndex: Int) -> some View {
        Button {
            selectedTool = tool
        } label: {
            HStack(spacing: 10) {
                Image(systemName: tool.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        selectedTool == tool ? SettingsChrome.sidebarIconActive : SettingsChrome.sidebarIcon
                    )
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(
                            selectedTool == tool ? SettingsChrome.sidebarTextActive : SettingsChrome.sidebarText
                        )

                    Text(tool.summary)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(
                            selectedTool == tool ? SettingsChrome.sidebarText : SettingsChrome.tertiaryText
                        )
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text("⌃\(shortcutIndex)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        selectedTool == tool ? SettingsChrome.sidebarTextActive : SettingsChrome.tertiaryText
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(selectedTool == tool ? SettingsChrome.sidebarOverlay : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                selectedTool == tool ? SettingsChrome.sidebarItemActive : SettingsChrome.sidebarItemHover.opacity(0.001)
            )
            .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                    .stroke(
                        selectedTool == tool ? SettingsChrome.cardBorder : Color.clear,
                        lineWidth: SettingsChrome.borderWidth
                    )
            )
        }
        .buttonStyle(.plain)
        .focusable(false)
        .keyboardShortcut(
            KeyEquivalent(Character(String(shortcutIndex))),
            modifiers: [.control]
        )
    }
}
