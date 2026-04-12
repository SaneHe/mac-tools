import AppKit
import SwiftUI

private enum PermissionOnboardingChrome {
    static let windowWidth: CGFloat = 860
    static let windowHeight: CGFloat = 540
    static let minWidth: CGFloat = 860
    static let minHeight: CGFloat = 540
    static let primaryPadding: CGFloat = 22
    static let primarySpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 4
    static let cardSpacing: CGFloat = 8
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 18
    static let trustColumnWidth: CGFloat = 320
    static let trustCardWidth: CGFloat = 284
    static let trustCardPadding: CGFloat = 16
    static let trustCardCornerRadius: CGFloat = 22
    static let trustCardShadowRadius: CGFloat = 10
    static let trustCardShadowYOffset: CGFloat = 4
    static let trustColumnOuterPadding: CGFloat = 20
    static let stepSpacing: CGFloat = 10
    static let buttonCornerRadius: CGFloat = 12
    static let buttonHorizontalPadding: CGFloat = 10
    static let buttonVerticalPadding: CGFloat = 7
    static let iconBoxSize: CGFloat = 32
    static let iconCornerRadius: CGFloat = 9
    static let statusIconSize: CGFloat = 18
}

enum PermissionRequirementKind: CaseIterable, Equatable {
    case accessibility
    case inputMonitoring

    var title: String {
        switch self {
        case .accessibility:
            return "辅助功能"
        case .inputMonitoring:
            return "输入监听"
        }
    }

    var summary: String {
        switch self {
        case .accessibility:
            return "用于读取当前 selected text，并在你确认后执行 Replace Selection。"
        case .inputMonitoring:
            return "用于监听 global shortcut，否则无法在任意应用中触发。"
        }
    }

    var systemActionTitle: String {
        switch self {
        case .accessibility:
            return "申请授权"
        case .inputMonitoring:
            return "申请授权"
        }
    }

    var symbolName: String {
        switch self {
        case .accessibility:
            return "hand.tap"
        case .inputMonitoring:
            return "keyboard"
        }
    }
}

enum PermissionOnboardingRoute: Equatable {
    case permissionOnboarding
    case normalUsage
    case settings
    case workspace
}

struct PermissionLaunchDecision: Equatable {
    let route: PermissionOnboardingRoute
    let shouldStartKeyboardMonitor: Bool
}

struct PermissionRequirementStatus: Equatable {
    let kind: PermissionRequirementKind
    let isAuthorized: Bool

    var title: String {
        kind.title
    }

    var summary: String {
        kind.summary
    }

    var statusText: String {
        isAuthorized ? "已授权" : "待开启"
    }

    var buttonTitle: String {
        isAuthorized ? "重新检查" : kind.systemActionTitle
    }

    var symbolName: String {
        isAuthorized ? "checkmark.circle.fill" : kind.symbolName
    }
}

struct AppPermissionGate {
    private let permissionStatusProvider: PermissionStatusProviding

    init(permissionStatusProvider: PermissionStatusProviding = SystemPermissionStatusProvider()) {
        self.permissionStatusProvider = permissionStatusProvider
    }

    func makeLaunchDecision() -> PermissionLaunchDecision {
        if isReadyForNormalUsage {
            return PermissionLaunchDecision(route: .normalUsage, shouldStartKeyboardMonitor: true)
        }

        return PermissionLaunchDecision(route: .permissionOnboarding, shouldStartKeyboardMonitor: false)
    }

    func routeForSettingsEntry() -> PermissionOnboardingRoute {
        isReadyForNormalUsage ? .settings : .permissionOnboarding
    }

    func routeForWorkspaceEntry() -> PermissionOnboardingRoute {
        isReadyForNormalUsage ? .workspace : .permissionOnboarding
    }

    var isReadyForNormalUsage: Bool {
        permissionStatusProvider.isAccessibilityAuthorized()
        && permissionStatusProvider.isInputMonitoringAuthorized()
    }
}

@MainActor
final class PermissionOnboardingViewModel: ObservableObject {
    @Published private(set) var statuses: [PermissionRequirementStatus] = []
    @Published private(set) var footerMessage: String?

    var onContinueApproved: (() -> Void)?

    private let permissionStatusProvider: PermissionStatusProviding
    private let permissionPrompter: PermissionPrompting

    init(
        permissionStatusProvider: PermissionStatusProviding = SystemPermissionStatusProvider(),
        permissionPrompter: PermissionPrompting = SystemPermissionPrompter()
    ) {
        self.permissionStatusProvider = permissionStatusProvider
        self.permissionPrompter = permissionPrompter
        refreshStatuses()
    }

    var canContinue: Bool {
        statuses.allSatisfy(\.isAuthorized)
    }

    var continueButtonTitle: String {
        canContinue ? "继续使用 Mac Text Actions" : "请先完成全部系统授权"
    }

    var accessibilityStatus: PermissionRequirementStatus {
        status(for: .accessibility)
    }

    var inputMonitoringStatus: PermissionRequirementStatus {
        status(for: .inputMonitoring)
    }

    func refreshStatuses() {
        statuses = [
            PermissionRequirementStatus(
                kind: .accessibility,
                isAuthorized: permissionStatusProvider.isAccessibilityAuthorized()
            ),
            PermissionRequirementStatus(
                kind: .inputMonitoring,
                isAuthorized: permissionStatusProvider.isInputMonitoringAuthorized()
            )
        ]

        footerMessage = canContinue
        ? "两项权限都已完成，继续后即可开始使用。"
        : "完成辅助功能与输入监听授权后，应用才会开始正常工作。"
    }

    func requestAuthorization(for kind: PermissionRequirementKind) {
        switch kind {
        case .accessibility:
            permissionPrompter.requestAccessibilityPermission()
            footerMessage = "请在系统设置中完成辅助功能授权，然后回到这里重新检查。"
        case .inputMonitoring:
            permissionPrompter.requestInputMonitoringPermission()
            footerMessage = "请在系统设置中完成输入监听授权，然后回到这里重新检查。"
        }
    }

    @discardableResult
    func completeOnboarding() -> Bool {
        refreshStatuses()

        guard canContinue else {
            footerMessage = "仍有权限未完成，请先完成全部系统授权。"
            return false
        }

        onContinueApproved?()
        return true
    }

    private func status(for kind: PermissionRequirementKind) -> PermissionRequirementStatus {
        statuses.first(where: { $0.kind == kind })
        ?? PermissionRequirementStatus(kind: kind, isAuthorized: false)
    }
}

@MainActor
struct PermissionOnboardingView: View {
    @StateObject private var viewModel: PermissionOnboardingViewModel

    init(viewModel: PermissionOnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 0) {
            onboardingPrimaryColumn
            onboardingTrustColumn
        }
        .background(SettingsChrome.windowBackground)
        .frame(
            minWidth: PermissionOnboardingChrome.minWidth,
            minHeight: PermissionOnboardingChrome.minHeight
        )
        .onAppear {
            viewModel.refreshStatuses()
        }
    }

    private var onboardingPrimaryColumn: some View {
        VStack(alignment: .leading, spacing: PermissionOnboardingChrome.primarySpacing) {
            onboardingStepHeader

            VStack(alignment: .leading, spacing: PermissionOnboardingChrome.sectionSpacing) {
                Text("完成权限授权后即可开始使用")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text("Mac Text Actions 需要先获得系统授权，才能读取 selected text 并响应 global shortcut。")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: PermissionOnboardingChrome.cardSpacing) {
                permissionRequirementCard(viewModel.accessibilityStatus)
                permissionRequirementCard(viewModel.inputMonitoringStatus)
            }

            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    _ = viewModel.completeOnboarding()
                }) {
                    Text(viewModel.continueButtonTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .surfaceButtonStyle(viewModel.canContinue ? .primary : .secondary)
                .disabled(!viewModel.canContinue)

                if let footerMessage = viewModel.footerMessage {
                    Text(footerMessage)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(SettingsChrome.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()
        }
        .padding(PermissionOnboardingChrome.primaryPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.88))
    }

    private var onboardingTrustColumn: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.34),
                    SettingsChrome.workspaceBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 16) {
                trustRow(
                    symbol: "sparkles.rectangle.stack",
                    title: "只在主动触发时读取选区",
                    description: "只有当你按下 global shortcut 时，应用才会尝试读取当前 selected text。"
                )
                trustRow(
                    symbol: "arrow.left.arrow.right.square",
                    title: "不会静默修改文本",
                    description: "Replace Selection 只会在你明确点击后执行，不会自动回写。"
                )
                trustRow(
                    symbol: "checkmark.shield",
                    title: "权限缺失会明确提示",
                    description: "如果系统授权缺失，应用会停留在当前引导页，而不是静默失效。"
                )
            }
            .padding(PermissionOnboardingChrome.trustCardPadding)
            .frame(maxWidth: PermissionOnboardingChrome.trustCardWidth)
            .background(Color.white.opacity(0.74))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: PermissionOnboardingChrome.trustCardCornerRadius,
                    style: .continuous
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: PermissionOnboardingChrome.trustCardCornerRadius,
                    style: .continuous
                )
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.04),
                radius: PermissionOnboardingChrome.trustCardShadowRadius,
                x: 0,
                y: PermissionOnboardingChrome.trustCardShadowYOffset
            )
            .padding(PermissionOnboardingChrome.trustColumnOuterPadding)
        }
        .frame(width: PermissionOnboardingChrome.trustColumnWidth)
    }

    private var onboardingStepHeader: some View {
        HStack(spacing: PermissionOnboardingChrome.stepSpacing) {
            stepChip(title: "欢迎", isActive: false)
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(SettingsChrome.tertiaryText)
            stepChip(title: "授权", isActive: true)
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(SettingsChrome.tertiaryText)
            stepChip(title: "开始使用", isActive: false)
        }
    }

    private func stepChip(title: String, isActive: Bool) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(isActive ? SettingsChrome.titleColor : SettingsChrome.tertiaryText)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(isActive ? SettingsChrome.cardSurface : SettingsChrome.mutedSurface)
            .clipShape(Capsule())
    }

    private func permissionRequirementCard(_ status: PermissionRequirementStatus) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status.symbolName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(status.isAuthorized ? SettingsChrome.accent : SettingsChrome.titleColor)
                .frame(
                    width: PermissionOnboardingChrome.iconBoxSize,
                    height: PermissionOnboardingChrome.iconBoxSize
                )
                .background(SettingsChrome.mutedSurface)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: PermissionOnboardingChrome.iconCornerRadius,
                        style: .continuous
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(status.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(SettingsChrome.titleColor)

                    Text(status.statusText)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(status.isAuthorized ? SettingsChrome.accent : Color.orange)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background((status.isAuthorized ? SettingsChrome.accent : Color.orange).opacity(0.12))
                        .clipShape(Capsule())
                }

                Text(status.summary)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    if !status.isAuthorized {
                        onboardingButton(title: status.buttonTitle) {
                            viewModel.requestAuthorization(for: status.kind)
                        }
                    }

                    onboardingButton(title: "重新检查") {
                        viewModel.refreshStatuses()
                    }
                }
            }

            Spacer(minLength: 0)

            if status.isAuthorized {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: PermissionOnboardingChrome.statusIconSize, weight: .semibold))
                    .foregroundStyle(SettingsChrome.titleColor)
            }
        }
        .padding(PermissionOnboardingChrome.cardPadding)
        .background(SettingsChrome.cardSurface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: PermissionOnboardingChrome.cardCornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: PermissionOnboardingChrome.cardCornerRadius,
                style: .continuous
            )
                .stroke(SettingsChrome.cardBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .shadow(color: SettingsChrome.shadowColor, radius: 8, x: 0, y: 4)
    }

    private func onboardingButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, PermissionOnboardingChrome.buttonHorizontalPadding)
                .padding(.vertical, PermissionOnboardingChrome.buttonVerticalPadding)
        }
        .surfaceButtonStyle(.secondary)
    }

    private func trustRow(symbol: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SettingsChrome.accent)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(SettingsChrome.accent)

                Text(description)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(SettingsChrome.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

final class PermissionOnboardingWindowController: NSWindowController {
    convenience init() {
        self.init(viewModel: PermissionOnboardingViewModel())
    }

    convenience init(viewModel: PermissionOnboardingViewModel) {
        let contentView = PermissionOnboardingView(viewModel: viewModel)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "权限引导"
        window.setContentSize(
            NSSize(
                width: PermissionOnboardingChrome.windowWidth,
                height: PermissionOnboardingChrome.windowHeight
            )
        )
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.isMovableByWindowBackground = true
        window.toolbarStyle = .unifiedCompact
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("permissionOnboardingWindow")

        self.init(window: window)
    }
}
