import XCTest
@testable import MacTextActionsApp

@MainActor
final class PermissionOnboardingViewModelTests: XCTestCase {
    func testContinueIsDisabledWhenAnyRequiredPermissionIsMissing() {
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: false,
                inputMonitoringAuthorized: true
            ),
            permissionPrompter: PermissionPrompterSpy()
        )

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(viewModel.continueButtonTitle, "请先完成全部系统授权")
    }

    func testContinueIsEnabledWhenAllRequiredPermissionsAreReady() {
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true,
                inputMonitoringAuthorized: true
            ),
            permissionPrompter: PermissionPrompterSpy()
        )

        XCTAssertTrue(viewModel.canContinue)
        XCTAssertEqual(viewModel.continueButtonTitle, "继续使用 Mac Text Actions")
    }

    func testRequestAccessibilityPermissionUsesPrompter() {
        let prompter = PermissionPrompterSpy()
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: MutablePermissionStatusProviderStub(),
            permissionPrompter: prompter
        )

        viewModel.requestAuthorization(for: .accessibility)

        XCTAssertEqual(prompter.accessibilityRequestCount, 1)
        XCTAssertEqual(prompter.inputMonitoringRequestCount, 0)
    }

    func testRequestInputMonitoringPermissionUsesPrompter() {
        let prompter = PermissionPrompterSpy()
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: MutablePermissionStatusProviderStub(),
            permissionPrompter: prompter
        )

        viewModel.requestAuthorization(for: .inputMonitoring)

        XCTAssertEqual(prompter.accessibilityRequestCount, 0)
        XCTAssertEqual(prompter.inputMonitoringRequestCount, 1)
    }

    func testContinueRefreshesPermissionStatusBeforeCompleting() {
        let permissionStatusProvider = MutablePermissionStatusProviderStub(
            accessibilityAuthorized: false,
            inputMonitoringAuthorized: false
        )
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: permissionStatusProvider,
            permissionPrompter: PermissionPrompterSpy()
        )
        var completionCount = 0
        viewModel.onContinueApproved = {
            completionCount += 1
        }

        permissionStatusProvider.accessibilityAuthorized = true
        permissionStatusProvider.inputMonitoringAuthorized = true

        let didContinue = viewModel.completeOnboarding()

        XCTAssertTrue(didContinue)
        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(viewModel.canContinue)
    }
}

@MainActor
final class AppPermissionGateTests: XCTestCase {
    func testLaunchDecisionBlocksNormalUsageWhenPermissionMissing() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: false,
                inputMonitoringAuthorized: true
            )
        )

        let decision = gate.makeLaunchDecision()

        XCTAssertEqual(decision.route, .permissionOnboarding)
        XCTAssertFalse(decision.shouldStartKeyboardMonitor)
    }

    func testLaunchDecisionAllowsNormalUsageWhenAllPermissionsReady() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true,
                inputMonitoringAuthorized: true
            )
        )

        let decision = gate.makeLaunchDecision()

        XCTAssertEqual(decision.route, .normalUsage)
        XCTAssertTrue(decision.shouldStartKeyboardMonitor)
    }

    func testWorkspaceRouteFallsBackToPermissionOnboardingUntilReady() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true,
                inputMonitoringAuthorized: false
            )
        )

        XCTAssertEqual(gate.routeForWorkspaceEntry(), .permissionOnboarding)
    }

    func testSettingsRouteBecomesAvailableAfterPermissionsComplete() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true,
                inputMonitoringAuthorized: true
            )
        )

        XCTAssertEqual(gate.routeForSettingsEntry(), .settings)
    }
}

private final class MutablePermissionStatusProviderStub: PermissionStatusProviding {
    var accessibilityAuthorized: Bool
    var inputMonitoringAuthorized: Bool

    init(
        accessibilityAuthorized: Bool = false,
        inputMonitoringAuthorized: Bool = false
    ) {
        self.accessibilityAuthorized = accessibilityAuthorized
        self.inputMonitoringAuthorized = inputMonitoringAuthorized
    }

    func isAccessibilityAuthorized() -> Bool {
        accessibilityAuthorized
    }

    func isInputMonitoringAuthorized() -> Bool {
        inputMonitoringAuthorized
    }
}

private final class PermissionPrompterSpy: PermissionPrompting {
    private(set) var accessibilityRequestCount = 0
    private(set) var inputMonitoringRequestCount = 0

    func requestAccessibilityPermission() {
        accessibilityRequestCount += 1
    }

    func requestInputMonitoringPermission() {
        inputMonitoringRequestCount += 1
    }
}
