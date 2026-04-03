import SwiftUI
import CryptoKit
import MacTextActionsCore

struct ToolContentView: View {
    let tool: ToolType

    @State private var inputText: String = ""
    @State private var outputText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(tool.rawValue)
                .font(.system(size: 20, weight: .semibold))

            TextField("输入内容...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 100)

            HStack {
                Button("转换") {
                    performTransform()
                }
                .buttonStyle(.borderedProminent)

                Button("清空") {
                    inputText = ""
                    outputText = ""
                }

                Spacer()
            }

            if !outputText.isEmpty {
                Text("结果")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                Text(outputText)
                    .font(.system(size: 13, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }

    private func performTransform() {
        switch tool {
        case .timestamp, .json:
            let detector = ContentDetector()
            let detection = detector.detect(inputText)
            let engine = TransformEngine()
            let result = engine.transform(input: inputText, detection: detection)
            outputText = result.primaryOutput ?? result.errorMessage ?? ""

        case .md5:
            if let data = inputText.data(using: .utf8) {
                let digest = Insecure.MD5.hash(data: data)
                outputText = digest.map { String(format: "%02x", $0) }.joined()
            } else {
                outputText = "MD5 转换失败"
            }

        case .url:
            outputText = UrlTransform.encode(inputText) ?? "URL 编码失败"
        }
    }
}
