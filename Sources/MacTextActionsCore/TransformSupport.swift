import Foundation

/// Shared date parsing helpers used by both detection and transformation paths.
enum DateParsers {
    static let localDateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    static func makeDate(from input: String) -> Date? {
        for formatter in supportedDateParsers() {
            if let date = formatter.date(from: input) {
                return date
            }
        }

        return nil
    }

    static func makeDateFromTimestamp(_ input: String) -> Date? {
        guard let numericValue = Double(input) else {
            return nil
        }

        // Treat 13-digit input as milliseconds to match common Unix timestamp exports.
        let interval: TimeInterval = input.count == 13 ? numericValue / 1000.0 : numericValue
        return Date(timeIntervalSince1970: interval)
    }

    private static func supportedDateParsers() -> [DateParsing] {
        // Keep the accepted formats conservative so plain text does not get over-detected as a date.
        [
            ISO8601DateParser(includeFractionalSeconds: true),
            ISO8601DateParser(includeFractionalSeconds: false),
            FixedFormatDateParser(format: "yyyy-MM-dd HH:mm:ss"),
            FixedFormatDateParser(format: "yyyy-MM-dd")
        ]
    }
}

private protocol DateParsing {
    func date(from input: String) -> Date?
}

private struct ISO8601DateParser: DateParsing {
    let formatter: ISO8601DateFormatter

    init(includeFractionalSeconds: Bool) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = includeFractionalSeconds
            ? [.withInternetDateTime, .withFractionalSeconds]
            : [.withInternetDateTime]
        self.formatter = formatter
    }

    func date(from input: String) -> Date? {
        formatter.date(from: input)
    }
}

private struct FixedFormatDateParser: DateParsing {
    let formatter: DateFormatter

    init(format: String) {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = format
        self.formatter = formatter
    }

    func date(from input: String) -> Date? {
        formatter.date(from: input)
    }
}
