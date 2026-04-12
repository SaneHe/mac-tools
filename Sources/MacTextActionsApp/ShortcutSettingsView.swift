import SwiftUI
import CoreGraphics

struct ShortcutRecorderFeedback: Equatable {
    let message: String

    static func success(_ configuration: ShortcutConfiguration) -> Self {
        ShortcutRecorderFeedback(message: "快捷键已绑定为 \(configuration.displayString)")
    }
}

enum ShortcutRecorderControlAction: Equatable {
    case cancel
}

enum ShortcutRecorderLogic {
    static func capture(
        keyCode: Int64,
        modifierFlags: NSEvent.ModifierFlags
    ) -> ShortcutConfiguration? {
        guard !isModifierKey(keyCode) else {
            return nil
        }

        var modifiers: ShortcutConfiguration.ModifierFlags = []
        if modifierFlags.contains(.command) { modifiers.insert(.command) }
        if modifierFlags.contains(.option) { modifiers.insert(.option) }
        if modifierFlags.contains(.control) { modifiers.insert(.control) }
        if modifierFlags.contains(.shift) { modifiers.insert(.shift) }
        if modifierFlags.contains(.function) { modifiers.insert(.function) }

        guard !modifiers.isEmpty else {
            return nil
        }

        return ShortcutConfiguration(
            keyCode: keyCode,
            modifiers: modifiers
        )
    }

    static func interpretControlKey(keyCode: Int64) -> ShortcutRecorderControlAction? {
        keyCode == 53 ? .cancel : nil
    }

    static func isModifierKey(_ keyCode: Int64) -> Bool {
        let modifierKeys: Set<Int64> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        return modifierKeys.contains(keyCode)
    }
}

/// 快捷键录制行（简化版，用于设置卡片）
struct ShortcutRecorderRow: View {
    @Binding var configuration: ShortcutConfiguration
    @State private var isRecording = false
    @State private var recordingPreview: ShortcutConfiguration?
    @State private var feedback: ShortcutRecorderFeedback?
    @State private var feedbackDismissWorkItem: DispatchWorkItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recorderPrimaryText)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundStyle(SettingsChrome.titleColor)
                        .frame(minWidth: 160, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isRecording ? SettingsChrome.accentSoft : SettingsChrome.mutedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                                .stroke(
                                    isRecording ? SettingsChrome.accent : SettingsChrome.editorBorder,
                                    lineWidth: SettingsChrome.borderWidth
                                )
                        )

                    if let feedback {
                        Text(feedback.message)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SettingsChrome.accent)
                    } else if isRecording {
                        Text("录制期间按 Esc 可取消")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(SettingsChrome.secondaryText)
                    }
                }

                Spacer()

                Button(action: {
                    if isRecording {
                        cancelRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isRecording ? "xmark.circle" : "pencil.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text(isRecording ? "取消" : "修改")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .surfaceButtonStyle(isRecording ? .destructive : .primary)

                if configuration != .default {
                    Button(action: {
                        dismissFeedback()
                        configuration = .default
                    }) {
                        Text("重置")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .surfaceButtonStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(isRecording ? SettingsChrome.accent.opacity(0.05) : SettingsChrome.mutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                .stroke(isRecording ? SettingsChrome.accent : SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
        )
        .onAppear {
            setupRecordingMonitor()
        }
        .onDisappear {
            feedbackDismissWorkItem?.cancel()
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                setupRecordingMonitor()
            }
        }
    }

    private var recorderPrimaryText: String {
        if let preview = recordingPreview {
            return preview.displayString
        }

        if isRecording {
            return "请按下新的快捷键"
        }

        return configuration.displayString
    }

    private func startRecording() {
        dismissFeedback()
        recordingPreview = nil
        isRecording = true
    }

    private func cancelRecording() {
        recordingPreview = nil
        isRecording = false
    }

    private func setupRecordingMonitor() {
        // 使用局部监控来捕获快捷键
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else { return event }

            let keyCode = Int64(event.keyCode)

            if ShortcutRecorderLogic.interpretControlKey(keyCode: keyCode) == .cancel {
                cancelRecording()
                return nil
            }

            guard let newConfiguration = ShortcutRecorderLogic.capture(
                keyCode: keyCode,
                modifierFlags: event.modifierFlags
            ) else {
                return event
            }

            recordingPreview = newConfiguration
            configuration = newConfiguration
            showSuccessFeedback(for: newConfiguration)
            isRecording = false
            return nil // 消费掉这个事件
        }
    }

    private func showSuccessFeedback(for configuration: ShortcutConfiguration) {
        feedbackDismissWorkItem?.cancel()
        feedback = .success(configuration)

        let workItem = DispatchWorkItem {
            feedback = nil
        }
        feedbackDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    private func dismissFeedback() {
        feedbackDismissWorkItem?.cancel()
        feedbackDismissWorkItem = nil
        feedback = nil
    }
}

/// 快捷键设置视图
struct ShortcutSettingsPanel: View {
    @StateObject private var settingsManager = ShortcutSettingsManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            VStack(alignment: .leading, spacing: 4) {
                Text("快捷键设置")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text("自定义全局触发快捷键")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }

            // 当前快捷键
            VStack(alignment: .leading, spacing: 8) {
                Text("全局触发快捷键")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.titleColor)

                ShortcutRecorderRow(configuration: $settingsManager.configuration)
            }

            // 说明文字
            VStack(alignment: .leading, spacing: 6) {
                Text("使用说明：")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SettingsChrome.titleColor)

                Text("• 选中任意文本后按下此快捷键，即可触发转换")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(SettingsChrome.secondaryText)

                Text("• 避免与系统或其他应用快捷键冲突")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(SettingsChrome.secondaryText)

                Text("• 推荐使用 Option+Space、Ctrl+Space 等组合")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(SettingsChrome.secondaryText)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
