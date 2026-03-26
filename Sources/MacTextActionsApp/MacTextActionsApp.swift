import SwiftUI

@main
/// Entry point for the current preview-oriented macOS app shell.
struct MacTextActionsApp: App {
    @StateObject private var viewModel = AppShellViewModel.preview()

    var body: some Scene {
        WindowGroup("Mac 文本动作") {
            AppShellView(viewModel: viewModel)
        }
    }
}
