import SwiftUI

enum CopyFeedbackHUDMetrics {
    static let minimumWidth: CGFloat = 88
    static let height: CGFloat = 32
    static let horizontalPadding: CGFloat = 14
    static let contentSpacing: CGFloat = 6
    static let cornerRadius: CGFloat = 16
    static let bottomInset: CGFloat = 18
    static let autoHideDelay: TimeInterval = 1.0
}

@MainActor
final class CopyFeedbackState: ObservableObject {
    @Published private(set) var isVisible = false
    @Published private(set) var replayToken = 0
    private let autoHideDelay: TimeInterval
    private var pendingHideWorkItem: DispatchWorkItem?

    init(autoHideDelay: TimeInterval = CopyFeedbackHUDMetrics.autoHideDelay) {
        self.autoHideDelay = autoHideDelay
    }

    func show() {
        pendingHideWorkItem?.cancel()
        replayToken += 1
        isVisible = true
        scheduleAutoHide()
    }

    func hide() {
        pendingHideWorkItem?.cancel()
        pendingHideWorkItem = nil
        isVisible = false
    }

    private func scheduleAutoHide() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.isVisible = false
            self?.pendingHideWorkItem = nil
        }
        pendingHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoHideDelay, execute: workItem)
    }
}

struct CopyFeedbackHUD: View {
    let isVisible: Bool
    let replayToken: Int
    let bottomInset: CGFloat

    init(
        isVisible: Bool,
        replayToken: Int = 0,
        bottomInset: CGFloat = CopyFeedbackHUDMetrics.bottomInset
    ) {
        self.isVisible = isVisible
        self.replayToken = replayToken
        self.bottomInset = bottomInset
    }

    var body: some View {
        Group {
            if isVisible {
                hudBody
                    .id(replayToken)
                    .padding(.bottom, bottomInset)
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.98)),
                            removal: .opacity
                        )
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(!isVisible)
    }

    private var hudBody: some View {
        HStack(spacing: CopyFeedbackHUDMetrics.contentSpacing) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))

            Text("已复制")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(Color.primary.opacity(0.92))
        .padding(.horizontal, CopyFeedbackHUDMetrics.horizontalPadding)
        .frame(minWidth: CopyFeedbackHUDMetrics.minimumWidth)
        .frame(height: CopyFeedbackHUDMetrics.height)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: CopyFeedbackHUDMetrics.cornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: CopyFeedbackHUDMetrics.cornerRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.28), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}
