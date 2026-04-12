import AppKit
import MacTextActionsCore
import SwiftUI

private enum UIPreviewLayout {
    static let contentWidth: CGFloat = 1320
    static let outerPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 20
    static let previewCornerRadius: CGFloat = 24
}

private struct PreviewSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }

            content
        }
        .padding(20)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: UIPreviewLayout.previewCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UIPreviewLayout.previewCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .shadow(color: SettingsChrome.shadowColor, radius: 16, x: 0, y: 8)
    }
}

private struct PreviewCanvas<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: UIPreviewLayout.previewCornerRadius, style: .continuous)
                    .fill(SettingsChrome.windowBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIPreviewLayout.previewCornerRadius, style: .continuous)
                    .stroke(SettingsChrome.cardBorder.opacity(0.85), lineWidth: SettingsChrome.borderWidth)
            )
    }
}

private struct PreviewPopoverPanel: View {
    let title: String
    let result: TransformResult
    let selectedText: String
    let contentSource: SelectionContentSource
    let sourceMessage: String?
    let executionMode: ExecutionMode
    let transformContext: TransformContext

    var body: some View {
        LiquidGlassPopover(
            title: title,
            result: result,
            selectedText: selectedText,
            contentSource: contentSource,
            executionMode: executionMode,
            transformContext: transformContext,
            sourceMessage: sourceMessage,
            onCopy: { _ in },
            onReplace: { _ in false },
            onClose: {},
            layout: LiquidGlassPopoverLayout.make(result: result, selectedText: selectedText)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PreviewPermissionStatusProvider: PermissionStatusProviding {
    let accessibilityAuthorized: Bool
    let inputMonitoringAuthorized: Bool

    func isAccessibilityAuthorized() -> Bool {
        accessibilityAuthorized
    }

    func isInputMonitoringAuthorized() -> Bool {
        inputMonitoringAuthorized
    }
}

private struct PreviewPermissionPrompter: PermissionPrompting {
    func requestAccessibilityPermission() {}
    func requestInputMonitoringPermission() {}
}

@MainActor
private enum UIPreviewFactory {
    static func toolWorkspaceViewModel() -> ToolWorkspaceViewModel {
        let contentViewModel = ToolContentViewModel(outputCopyWriter: PreviewOutputCopyWriter())
        contentViewModel.inputText = "{\"name\":\"Mac Text Actions\",\"enabled\":true,\"items\":[1,2,3]}"
        contentViewModel.performTransform(for: .json)

        let viewModel = ToolWorkspaceViewModel(contentViewModel: contentViewModel)
        viewModel.selectedTool = .json
        return viewModel
    }

    static func settingsViewModel() -> AppSettingsViewModel {
        let viewModel = AppSettingsViewModel(
            permissionStatusProvider: PreviewPermissionStatusProvider(
                accessibilityAuthorized: true,
                inputMonitoringAuthorized: false
            ),
            permissionPrompter: PreviewPermissionPrompter()
        )
        viewModel.shortcutConfiguration = ShortcutConfiguration(
            keyCode: 49,
            modifiers: [.option]
        )
        return viewModel
    }

    static func onboardingViewModel() -> PermissionOnboardingViewModel {
        PermissionOnboardingViewModel(
            permissionStatusProvider: PreviewPermissionStatusProvider(
                accessibilityAuthorized: true,
                inputMonitoringAuthorized: false
            ),
            permissionPrompter: PreviewPermissionPrompter()
        )
    }

    static func jsonPreview() -> PreviewPopoverPanel {
        let input = "{\"name\":\"Mac Text Actions\",\"enabled\":true,\"items\":[1,2,3]}"
        let engine = TransformEngine()
        let result = engine.transform(
            input: input,
            detection: DetectionResult(kind: .json, normalizedInput: input)
        )
        return PreviewPopoverPanel(
            title: "自动识别 · JSON",
            result: result,
            selectedText: input,
            contentSource: .selection,
            sourceMessage: nil,
            executionMode: .automatic,
            transformContext: TransformContext()
        )
    }

    static func timestampPreview() -> PreviewPopoverPanel {
        let input = "2024-03-08T12:34:56Z"
        let context = TransformContext(timestampPrecision: .seconds)
        let engine = TransformEngine()
        let result = engine.transform(
            input: input,
            detection: DetectionResult(kind: .dateString, normalizedInput: input),
            context: context
        )
        return PreviewPopoverPanel(
            title: "自动识别 · 日期",
            result: result,
            selectedText: input,
            contentSource: .selection,
            sourceMessage: nil,
            executionMode: .automatic,
            transformContext: context
        )
    }

    static func errorPreview() -> PreviewPopoverPanel {
        PreviewPopoverPanel(
            title: "自动识别 · 执行失败",
            result: TransformResult(
                primaryOutput: nil,
                secondaryActions: [],
                displayMode: .error,
                errorMessage: "当前应用暂不支持读取选中文本"
            ),
            selectedText: "",
            contentSource: .clipboardFallback,
            sourceMessage: "已改用剪贴板内容，不是当前实时选区",
            executionMode: .automatic,
            transformContext: TransformContext()
        )
    }
}

private struct PreviewOutputCopyWriter: OutputCopyWriting {
    func write(_ text: String) {}
}

@MainActor
struct UIPreviewCatalogView: View {
    private let workspaceViewModel = UIPreviewFactory.toolWorkspaceViewModel()
    private let settingsViewModel = UIPreviewFactory.settingsViewModel()
    private let onboardingViewModel = UIPreviewFactory.onboardingViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: UIPreviewLayout.sectionSpacing) {
                headerSection

                PreviewSectionCard(
                    title: "工作区预览",
                    subtitle: "复用当前工具页组件，使用 mock 输入展示信息密度和层次。"
                ) {
                    PreviewCanvas {
                        ToolWorkspaceView(viewModel: workspaceViewModel)
                            .frame(height: 760)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: UIPreviewLayout.previewCornerRadius,
                                    style: .continuous
                                )
                            )
                    }
                }

                PreviewSectionCard(
                    title: "设置页预览",
                    subtitle: "保留快捷键与权限主结构，用预设权限状态观察层级和冗余文案。"
                ) {
                    PreviewCanvas {
                        AppSettingsView(viewModel: settingsViewModel)
                            .frame(height: 640)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: UIPreviewLayout.previewCornerRadius,
                                    style: .continuous
                                )
                            )
                    }
                }

                PreviewSectionCard(
                    title: "权限引导预览",
                    subtitle: "保持双栏结构，只用静态状态展示当前视觉重量和按钮密度。"
                ) {
                    PreviewCanvas {
                        PermissionOnboardingView(viewModel: onboardingViewModel)
                            .frame(height: 540)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: UIPreviewLayout.previewCornerRadius,
                                    style: .continuous
                                )
                            )
                    }
                }

                PreviewSectionCard(
                    title: "Result Panel 预览",
                    subtitle: "并排展示 JSON、时间转换和错误态，便于确认 title、边框、按钮与字级。"
                ) {
                    HStack(alignment: .top, spacing: UIPreviewLayout.cardSpacing) {
                        UIPreviewFactory.jsonPreview()
                        UIPreviewFactory.timestampPreview()
                        UIPreviewFactory.errorPreview()
                    }
                }
            }
            .frame(maxWidth: UIPreviewLayout.contentWidth)
            .padding(UIPreviewLayout.outerPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(
            LinearGradient(
                colors: [
                    SettingsChrome.windowBackground,
                    SettingsChrome.workspaceBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UI 预览")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(SettingsChrome.titleColor)

            Text("这个页面只用于确认视觉方向，不接真实权限、选区读取或替换动作。后续正式修改会在这些组件上直接收敛。")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(SettingsChrome.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: UIPreviewLayout.previewCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: UIPreviewLayout.previewCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .shadow(color: SettingsChrome.shadowColor, radius: 16, x: 0, y: 8)
    }
}

@MainActor
final class UIPreviewWindowController: NSWindowController {
    convenience init() {
        let contentView = UIPreviewCatalogView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "UI 预览"
        window.setContentSize(NSSize(width: 1360, height: 900))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("uiPreviewWindow")

        self.init(window: window)
    }
}
