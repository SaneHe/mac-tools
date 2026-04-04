import Foundation

/// Fixed content categories that mirror the documented detection priority.
public enum ContentKind: Equatable {
    case json
    case invalidJSON
    case timestamp
    case dateString
    case url
    case plainText
}

/// Output of the detection stage before any user-facing transformation happens.
public struct DetectionResult: Equatable {
    public let kind: ContentKind
    public let normalizedInput: String
    public let errorMessage: String?

    public init(kind: ContentKind, normalizedInput: String, errorMessage: String? = nil) {
        self.kind = kind
        self.normalizedInput = normalizedInput
        self.errorMessage = errorMessage
    }
}

/// Explicit user-triggered actions that can be shown alongside a primary result.
public enum SecondaryAction: String, Equatable, CaseIterable {
    case copyResult
    case replaceSelection
    case compressJSON
    case generateMD5
    case createReminder
    case urlEncode
    case urlDecode
}

/// Describes how the primary result should be rendered in the result panel.
public enum DisplayMode: Equatable {
    case code
    case text
    case error
    case actionsOnly
}

/// Output of the transform stage that feeds the result panel UI.
public struct TransformResult: Equatable {
    public let primaryOutput: String?
    public let secondaryActions: [SecondaryAction]
    public let displayMode: DisplayMode
    public let errorMessage: String?

    public init(
        primaryOutput: String?,
        secondaryActions: [SecondaryAction],
        displayMode: DisplayMode,
        errorMessage: String? = nil
    ) {
        self.primaryOutput = primaryOutput
        self.secondaryActions = secondaryActions
        self.displayMode = displayMode
        self.errorMessage = errorMessage
    }
}
