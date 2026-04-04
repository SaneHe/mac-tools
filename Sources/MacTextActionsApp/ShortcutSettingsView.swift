import SwiftUI
import CoreGraphics

/// 快捷键录制行（简化版，用于设置卡片）
struct ShortcutRecorderRow: View {
    @Binding var configuration: ShortcutConfiguration
    @State private var isRecording = false

    var body: some View {
        HStack(spacing: 12) {
            // 显示当前快捷键
            Text(configuration.displayString)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(SettingsChrome.titleColor)
                .frame(minWidth: 100, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SettingsChrome.mutedSurface)
                .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous)
                        .stroke(SettingsChrome.editorBorder, lineWidth: SettingsChrome.borderWidth)
                )

            Spacer()

            // 录制按钮
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
                .foregroundStyle(isRecording ? Color.red : SettingsChrome.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(isRecording ? Color.red.opacity(0.1) : SettingsChrome.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))

            // 重置按钮
            if configuration != .default {
                Button(action: {
                    configuration = .default
                }) {
                    Text("重置")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SettingsChrome.secondaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .background(SettingsChrome.mutedSurface)
                .clipShape(RoundedRectangle(cornerRadius: SettingsChrome.compactCornerRadius, style: .continuous))
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
        .onChange(of: isRecording) { newValue in
            if newValue {
                setupRecordingMonitor()
            }
        }
    }

    private func startRecording() {
        isRecording = true
    }

    private func cancelRecording() {
        isRecording = false
    }

    private func setupRecordingMonitor() {
        // 使用局部监控来捕获快捷键
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else { return event }

            let keyCode = Int64(event.keyCode)

            // 忽略单独的修饰键
            if isModifierKey(keyCode) {
                return event
            }

            // 构建修饰键标志
            var modifiers: ShortcutConfiguration.ModifierFlags = []
            if event.modifierFlags.contains(.command) { modifiers.insert(.command) }
            if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
            if event.modifierFlags.contains(.control) { modifiers.insert(.control) }
            if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
            if event.modifierFlags.contains(.function) { modifiers.insert(.function) }

            // 至少需要有一个修饰键
            guard !modifiers.isEmpty else {
                return event
            }

            // 保存配置
            configuration = ShortcutConfiguration(
                keyCode: keyCode,
                modifiers: modifiers
            )

            isRecording = false
            return nil // 消费掉这个事件
        }
    }

    private func isModifierKey(_ keyCode: Int64) -> Bool {
        // 修饰键的 keyCode
        let modifierKeys: [Int64] = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
        return modifierKeys.contains(keyCode)
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
