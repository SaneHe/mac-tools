import SwiftUI

struct SettingsView: View {
    @State private var selectedTool: ToolType = .timestamp

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTool: $selectedTool)
                .frame(minWidth: 180)
        } detail: {
            ToolContentView(tool: selectedTool)
                .frame(minWidth: 400)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
