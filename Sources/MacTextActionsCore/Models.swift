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

public enum TimestampPrecision: Equatable {
    case seconds
    case milliseconds
    case none
}

public enum MD5LetterCase: Equatable {
    case lowercase
    case uppercase
}

public struct OptionAction: Equatable {
    public let buttonTitle: String
    public let nextContext: TransformContext

    public init(buttonTitle: String, nextContext: TransformContext) {
        self.buttonTitle = buttonTitle
        self.nextContext = nextContext
    }
}

public struct TransformContext: Equatable {
    public let timestampPrecision: TimestampPrecision
    public let md5LetterCase: MD5LetterCase

    public init(
        timestampPrecision: TimestampPrecision = .none,
        md5LetterCase: MD5LetterCase = .lowercase
    ) {
        self.timestampPrecision = timestampPrecision
        self.md5LetterCase = md5LetterCase
    }
}

/// Output of the transform stage that feeds the result panel UI.
public struct TransformResult: Equatable {
    public let primaryOutput: String?
    public let secondaryActions: [SecondaryAction]
    public let optionAction: OptionAction?
    public let actionsHintTitle: String?
    public let actionsHintMessage: String?
    public let displayMode: DisplayMode
    public let errorMessage: String?

    public init(
        primaryOutput: String?,
        secondaryActions: [SecondaryAction],
        optionAction: OptionAction? = nil,
        actionsHintTitle: String? = nil,
        actionsHintMessage: String? = nil,
        displayMode: DisplayMode,
        errorMessage: String? = nil
    ) {
        self.primaryOutput = primaryOutput
        self.secondaryActions = secondaryActions
        self.optionAction = optionAction
        self.actionsHintTitle = actionsHintTitle
        self.actionsHintMessage = actionsHintMessage
        self.displayMode = displayMode
        self.errorMessage = errorMessage
    }
}
