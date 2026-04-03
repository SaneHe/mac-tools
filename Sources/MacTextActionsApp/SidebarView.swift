import SwiftUI

enum ToolType: String, CaseIterable, Identifiable {
    case timestamp = "时间戳转换"
    case json = "JSON 格式化"
    case md5 = "MD5 加密"
    case url = "URL 编解码"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .timestamp: return "clock"
        case .json: return "curlybraces"
        case .md5: return "lock"
        case .url: return "link"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTool: ToolType

    var body: some View {
        List(ToolType.allCases) { tool in
            Button {
                selectedTool = tool
            } label: {
                Label(tool.rawValue, systemImage: tool.icon)
                    .foregroundColor(selectedTool == tool ? .accentColor : .primary)
            }
            .buttonStyle(.plain)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selectedTool == tool ? Color.accentColor.opacity(0.15) : Color.clear)
            .cornerRadius(8)
        }
        .listStyle(.sidebar)
        .padding(8)
    }
}
