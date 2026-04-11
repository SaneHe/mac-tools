import SwiftUI

enum CopyFeedbackHUDMetrics {
    static let minimumWidth: CGFloat = 88
    static let height: CGFloat = 32
    static let horizontalPadding: CGFloat = 14
    static let contentSpacing: CGFloat = 6
    static let cornerRadius: CGFloat = 16
    static let bottomInset: CGFloat = 18
}

@MainActor
final class CopyFeedbackState: ObservableObject {
    @Published private(set) var isVisible = false
    @Published private(set) var replayToken = 0

    func show() {
        replayToken += 1
        isVisible = true
    }

    func hide() {
        isVisible = false
    }
}

struct CopyFeedbackHUD: View {
    let isVisible: Bool
    let bottomInset: CGFloat

    init(
        isVisible: Bool,
        bottomInset: CGFloat = CopyFeedbackHUDMetrics.bottomInset
    ) {
        self.isVisible = isVisible
        self.bottomInset = bottomInset
    }

    var body: some View {
        Group {
            if isVisible {
                hudBody
                    .padding(.bottom, bottomInset)
                    .transition(.opacity)
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
