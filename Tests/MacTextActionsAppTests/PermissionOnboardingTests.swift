import XCTest
@testable import MacTextActionsApp

@MainActor
final class PermissionOnboardingViewModelTests: XCTestCase {
    func testContinueIsDisabledWhenAccessibilityPermissionIsMissing() {
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: false
            ),
            permissionPrompter: PermissionPrompterSpy()
        )

        XCTAssertFalse(viewModel.canContinue)
        XCTAssertEqual(viewModel.continueButtonTitle, "请先完成全部系统授权")
    }

    func testContinueIsEnabledWhenAccessibilityPermissionIsReady() {
        let viewModel = PermissionOnboardingViewModel(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true
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
    }

    func testContinueRefreshesPermissionStatusBeforeCompleting() {
        let permissionStatusProvider = MutablePermissionStatusProviderStub(
            accessibilityAuthorized: false
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

        let didContinue = viewModel.completeOnboarding()

        XCTAssertTrue(didContinue)
        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(viewModel.canContinue)
    }
}

@MainActor
final class AppPermissionGateTests: XCTestCase {
    func testLaunchDecisionBlocksNormalUsageWhenAccessibilityPermissionMissing() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: false
            )
        )

        let decision = gate.makeLaunchDecision()

        XCTAssertEqual(decision.route, .permissionOnboarding)
        XCTAssertFalse(decision.shouldStartKeyboardMonitor)
    }

    func testLaunchDecisionAllowsNormalUsageWhenAccessibilityPermissionReady() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true
            )
        )

        let decision = gate.makeLaunchDecision()

        XCTAssertEqual(decision.route, .normalUsage)
        XCTAssertTrue(decision.shouldStartKeyboardMonitor)
    }

    func testWorkspaceRouteFallsBackToPermissionOnboardingUntilReady() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: false
            )
        )

        XCTAssertEqual(gate.routeForWorkspaceEntry(), .permissionOnboarding)
    }

    func testSettingsRouteBecomesAvailableAfterPermissionComplete() {
        let gate = AppPermissionGate(
            permissionStatusProvider: MutablePermissionStatusProviderStub(
                accessibilityAuthorized: true
            )
        )

        XCTAssertEqual(gate.routeForSettingsEntry(), .settings)
    }
}

private final class MutablePermissionStatusProviderStub: PermissionStatusProviding {
    var accessibilityAuthorized: Bool

    init(accessibilityAuthorized: Bool = false) {
        self.accessibilityAuthorized = accessibilityAuthorized
    }

    func isAccessibilityAuthorized() -> Bool {
        accessibilityAuthorized
    }
}

private final class PermissionPrompterSpy: PermissionPrompting {
    private(set) var accessibilityRequestCount = 0

    func requestAccessibilityPermission() {
        accessibilityRequestCount += 1
    }
}
