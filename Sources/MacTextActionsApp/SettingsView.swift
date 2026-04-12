import AppKit
import SwiftUI

enum SettingsChrome {
    static let sidebarWidth: CGFloat = 236
    static let outerPadding: CGFloat = 24
    static let topSafeAreaPadding: CGFloat = 24
    static let sectionSpacing: CGFloat = 20
    static let cardCornerRadius: CGFloat = 22
    static let panelCornerRadius: CGFloat = 0
    static let compactCornerRadius: CGFloat = 14
    static let borderWidth: CGFloat = 1

    // 统一为接近 Codex 的浅色桌面工作区风格。
    static let sidebarBackground = Color(red: 0.91, green: 0.95, blue: 0.98)
    static let sidebarOverlay = Color.white.opacity(0.18)
    static let sidebarItemHover = Color.white.opacity(0.20)
    static let sidebarItemActive = Color.white.opacity(0.56)
    static let sidebarText = Color(red: 0.28, green: 0.33, blue: 0.38)
    static let sidebarTextActive = Color(red: 0.14, green: 0.19, blue: 0.24)
    static let sidebarIcon = Color(red: 0.38, green: 0.46, blue: 0.52)
    static let sidebarIconActive = Color(red: 0.18, green: 0.26, blue: 0.34)

    static let windowBackground = Color(red: 0.97, green: 0.975, blue: 0.985)
    static let workspaceBackground = Color(red: 0.985, green: 0.988, blue: 0.993)
    static let surface = Color(red: 0.972, green: 0.976, blue: 0.992)
    static let cardSurface = Color.white.opacity(0.90)
    static let mutedSurface = Color.white.opacity(0.70)
    static let accent = Color(red: 0.000, green: 0.478, blue: 1.000)
    static let accentSoft = accent.opacity(0.12)
    static let titleColor = Color(red: 0.18, green: 0.18, blue: 0.20)
    static let secondaryText = Color(red: 0.50, green: 0.50, blue: 0.52)
    static let tertiaryText = Color(red: 0.60, green: 0.63, blue: 0.67)
    static let shadowColor = Color.black.opacity(0.018)
    static let dividerColor = Color(red: 0.84, green: 0.88, blue: 0.91)
    static let cardBorder = Color.white.opacity(0.44)
    static let editorBorder = Color(red: 0.84, green: 0.88, blue: 0.92)
}

struct SplitWorkspaceSurfaceStyle {
    let outerPadding: CGFloat
    let contentPadding: CGFloat
    let contentCornerRadius: CGFloat
    let contentBorderOpacity: Double
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat

    static let codexLike = SplitWorkspaceSurfaceStyle(
        outerPadding: 18,
        contentPadding: 18,
        contentCornerRadius: 28,
        contentBorderOpacity: 0.72,
        shadowOpacity: 0.05,
        shadowRadius: 14,
        shadowYOffset: 4
    )
}

struct SplitWorkspaceSurface<Content: View>: View {
    private let style: SplitWorkspaceSurfaceStyle
    private let content: Content

    init(
        style: SplitWorkspaceSurfaceStyle = .codexLike,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(
                RoundedRectangle(
                    cornerRadius: style.contentCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: style.contentCornerRadius,
                    style: .continuous
                )
                .stroke(
                    Color.white.opacity(style.contentBorderOpacity),
                    lineWidth: SettingsChrome.borderWidth
                )
            )
            .shadow(
                color: Color.black.opacity(style.shadowOpacity),
                radius: style.shadowRadius,
                x: 0,
                y: style.shadowYOffset
            )
            .padding(style.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private enum SettingsLayout {
    static let contentWidth: CGFloat = 820
    static let cardSpacing: CGFloat = 20
    static let cardPadding: CGFloat = 22
    static let sidebarTopPadding: CGFloat = 22
    static let sidebarInnerPadding: CGFloat = 14
}

@MainActor
final class AppSettingsViewModel: ObservableObject {
    @Published private(set) var accessibilityPermissionState: PermissionDisplayState = .needsAttention
    @Published private(set) var inputMonitoringPermissionState: PermissionDisplayState = .needsAttention
    @Published var shortcutConfiguration: ShortcutConfiguration
    @Published var dockIconVisible: Bool
    @Published var menuBarIconVisible: Bool

    private let permissionStatusProvider: PermissionStatusProviding
    private let permissionPrompter: PermissionPrompting

    init(
        permissionStatusProvider: PermissionStatusProviding = SystemPermissionStatusProvider(),
        permissionPrompter: PermissionPrompting = SystemPermissionPrompter()
    ) {
        self.permissionStatusProvider = permissionStatusProvider
        self.permissionPrompter = permissionPrompter
        self.shortcutConfiguration = ShortcutSettingsManager.shared.configuration
        self.dockIconVisible = AppAppearanceSettings.shared.dockIconVisible
        self.menuBarIconVisible = AppAppearanceSettings.shared.menuBarIconVisible
        refreshPermissionStatus()
    }

    func refreshPermissionStatus() {
        accessibilityPermissionState = permissionStatusProvider.isAccessibilityAuthorized()
        ? .granted
        : .needsAttention
        inputMonitoringPermissionState = permissionStatusProvider.isInputMonitoringAuthorized()
        ? .granted
        : .needsAttention
    }

    func requestAccessibilityPermission() {
        permissionPrompter.requestAccessibilityPermission()
        refreshPermissionStatus()
    }

    func requestInputMonitoringPermission() {
        permissionPrompter.requestInputMonitoringPermission()
        refreshPermissionStatus()
    }

    func updateDockIconVisible(_ visible: Bool) {
        dockIconVisible = visible
        AppAppearanceSettings.shared.dockIconVisible = visible
    }

    func updateMenuBarIconVisible(_ visible: Bool) {
        menuBarIconVisible = visible
        AppAppearanceSettings.shared.menuBarIconVisible = visible
    }

    var globalShortcutDisplayTitle: String { AppShortcutConfiguration.globalShortcutTitle }
    var globalShortcutDisplayValue: String { shortcutConfiguration.displayString }
    var toolSwitchShortcutDisplayTitle: String { AppShortcutConfiguration.toolSwitchShortcutTitle }
    var toolSwitchShortcutDisplayValue: String { AppShortcutConfiguration.toolSwitchShortcutValue }
    var accessibilityPermissionText: String { accessibilityPermissionState.text }
    var inputMonitoringPermissionText: String { inputMonitoringPermissionState.text }

    var globalShortcutHint: String {
        guard accessibilityPermissionState == .granted,
              inputMonitoringPermissionState == .granted else {
            return "需要同时开启辅助功能与输入监听权限，快捷键才能全局生效。"
        }

        return "已就绪，在任意应用选中文本后按 \(shortcutConfiguration.displayString) 即可触发。"
    }
}

@MainActor
struct AppSettingsView: View {
    @StateObject private var viewModel: AppSettingsViewModel

    init(viewModel: AppSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    init() {
        _viewModel = StateObject(wrappedValue: AppSettingsViewModel())
    }

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar

            SplitWorkspaceSurface {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: SettingsLayout.cardSpacing) {
                        headerSection
                        AppearanceSettingsCard(viewModel: viewModel)
                        ShortcutSettingsCard(viewModel: viewModel)
                    }
                    .frame(maxWidth: SettingsLayout.contentWidth)
                    .padding(SettingsChrome.outerPadding)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(SettingsChrome.workspaceBackground)
            }
        }
        .background(SettingsChrome.windowBackground)
        .onAppear {
            viewModel.refreshPermissionStatus()
        }
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Mac Text Actions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SettingsChrome.sidebarTextActive)

                Text("统一管理全局快捷键、工具切换和权限状态。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.sidebarText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.top, SettingsLayout.sidebarTopPadding)
            .padding(.bottom, 18)

            Divider()
                .background(SettingsChrome.dividerColor.opacity(0.9))

            VStack(alignment: .leading, spacing: 6) {
                settingsSidebarItem(
                    title: "快捷键与权限",
                    subtitle: "Space / Ctrl+1-4 / 授权入口",
                    symbol: "gearshape"
                )
            }
            .padding(.horizontal, SettingsLayout.sidebarInnerPadding)
            .padding(.vertical, 16)

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("当前状态")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(SettingsChrome.tertiaryText)

                Text(viewModel.globalShortcutHint)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.sidebarText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(SettingsChrome.sidebarOverlay)
            .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                    .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
            )
            .padding(.horizontal, SettingsLayout.sidebarInnerPadding)
            .padding(.bottom, 18)
        }
        .frame(width: SettingsChrome.sidebarWidth)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(SettingsChrome.sidebarBackground)
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: SettingsChrome.cardCornerRadius,
                    bottomLeading: SettingsChrome.cardCornerRadius,
                    bottomTrailing: 0,
                    topTrailing: 0
                ),
                style: .continuous
            )
        )
    }

    private func settingsSidebarItem(title: String, subtitle: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SettingsChrome.sidebarIconActive)
                .frame(width: 28, height: 28)
                .background(SettingsChrome.sidebarOverlay)
                .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SettingsChrome.sidebarTextActive)

                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SettingsChrome.sidebarText)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SettingsChrome.sidebarItemActive)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("设置")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(SettingsChrome.titleColor)

            Text("只保留快捷键、权限状态和必要的授权入口。")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(SettingsChrome.secondaryText)
        }
        .padding(SettingsLayout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .shadow(color: SettingsChrome.shadowColor, radius: 12, x: 0, y: 5)
    }
}

private struct ShortcutSettingsCard: View {
    @ObservedObject var viewModel: AppSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("快捷键与权限")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text(viewModel.globalShortcutHint)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }

            // 快捷键录制区域
            VStack(alignment: .leading, spacing: 8) {
                Text("全局触发快捷键")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SettingsChrome.titleColor)

                ShortcutRecorderRow(configuration: $viewModel.shortcutConfiguration)
            }

            Divider()
                .background(SettingsChrome.dividerColor)
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                shortcutPill(
                    title: viewModel.globalShortcutDisplayTitle,
                    value: viewModel.globalShortcutDisplayValue
                )
                shortcutPill(
                    title: viewModel.toolSwitchShortcutDisplayTitle,
                    value: viewModel.toolSwitchShortcutDisplayValue
                )
                shortcutPill(
                    title: AppShortcutConfiguration.primaryActionTitle,
                    value: AppShortcutConfiguration.primaryActionValue
                )
                shortcutPill(
                    title: AppShortcutConfiguration.clearActionTitle,
                    value: AppShortcutConfiguration.clearActionValue
                )
            }

            HStack(spacing: 12) {
                permissionRow(
                    title: "辅助功能",
                    value: viewModel.accessibilityPermissionText,
                    state: viewModel.accessibilityPermissionState
                )
                permissionRow(
                    title: "输入监听",
                    value: viewModel.inputMonitoringPermissionText,
                    state: viewModel.inputMonitoringPermissionState
                )
            }

            HStack(spacing: 10) {
                settingsButton(title: "申请辅助功能权限") {
                    viewModel.requestAccessibilityPermission()
                }
                settingsButton(title: "申请输入监听权限") {
                    viewModel.requestInputMonitoringPermission()
                }
                settingsButton(title: "重新检查权限") {
                    viewModel.refreshPermissionStatus()
                }
            }
        }
        .padding(20)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .shadow(color: SettingsChrome.shadowColor, radius: 12, x: 0, y: 5)
    }

    private func shortcutPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(SettingsChrome.secondaryText)
                .textCase(.uppercase)
                .tracking(1.0)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SettingsChrome.titleColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SettingsChrome.mutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                .stroke(SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
        )
    }

    private func permissionRow(
        title: String,
        value: String,
        state: PermissionDisplayState
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: state.symbolName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(state == .granted ? SettingsChrome.accent : Color.orange)
                .frame(width: 26, height: 26)
                .background(SettingsChrome.mutedSurface)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text(value)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(SettingsChrome.mutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                .stroke(SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
        )
    }

    private func settingsButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .surfaceButtonStyle(.secondary)
    }
}

private struct AppearanceSettingsCard: View {
    @ObservedObject var viewModel: AppSettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("外观")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text("控制应用在 Dock 和菜单栏中的显示方式。")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }

            VStack(spacing: 16) {
                Toggle(isOn: Binding(
                    get: { viewModel.dockIconVisible },
                    set: { viewModel.updateDockIconVisible($0) }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "dock.rectangle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SettingsChrome.accent)
                            .frame(width: 28, height: 28)
                            .background(SettingsChrome.mutedSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("在 Dock 中显示")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(SettingsChrome.titleColor)

                            Text("关闭后应用将不会出现在 Dock 栏")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(SettingsChrome.secondaryText)
                        }

                        Spacer()
                    }
                }
                .toggleStyle(.switch)

                Divider()
                    .background(SettingsChrome.dividerColor)

                Toggle(isOn: Binding(
                    get: { viewModel.menuBarIconVisible },
                    set: { viewModel.updateMenuBarIconVisible($0) }
                )) {
                    HStack(spacing: 12) {
                        Image(systemName: "menubar.rectangle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(SettingsChrome.accent)
                            .frame(width: 28, height: 28)
                            .background(SettingsChrome.mutedSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("在菜单栏中显示")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(SettingsChrome.titleColor)

                            Text("关闭后将无法在菜单栏访问设置，需使用全局快捷键")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(SettingsChrome.secondaryText)
                        }

                        Spacer()
                    }
                }
                .toggleStyle(.switch)
            }
        }
        .padding(20)
        .background(SettingsChrome.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.cardCornerRadius, style: .continuous)
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .shadow(color: SettingsChrome.shadowColor, radius: 12, x: 0, y: 5)
    }
}
