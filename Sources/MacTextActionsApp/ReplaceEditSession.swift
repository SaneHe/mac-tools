import MacTextActionsCore

enum ReplaceEditMode: Equatable {
    case preview
    case editing
}

struct ReplaceEditSession: Equatable {
    let mode: ReplaceEditMode
    let originalSelectedText: String
    let editableText: String
    let transformContext: TransformContext

    static func begin(selectedText: String, result: TransformResult) -> ReplaceEditSession? {
        guard let editableText = result.primaryOutput, !editableText.isEmpty else {
            return nil
        }

        return ReplaceEditSession(
            mode: .editing,
            originalSelectedText: selectedText,
            editableText: editableText,
            transformContext: makeTransformContext(from: selectedText)
        )
    }

    func makeLiveResult(for editableText: String) -> TransformResult {
        let detector = ContentDetector()
        let detection = detector.detect(editableText)
        let engine = TransformEngine()
        return engine.transformForEditing(
            input: editableText,
            detection: detection,
            context: transformContext
        )
    }

    private static func makeTransformContext(from selectedText: String) -> TransformContext {
        let trimmed = selectedText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.allSatisfy(\.isNumber) {
            if trimmed.count == 10 {
                return TransformContext(timestampPrecision: .seconds)
            }

            if trimmed.count == 13 {
                return TransformContext(timestampPrecision: .milliseconds)
            }
        }

        return TransformContext()
    }
}
