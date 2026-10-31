import AppKit

public final class SyntaxHighlighter {
    private let rules: [HighlightRule]
    private static var cache: [Language: [HighlightRule]] = [:]
    private static let lock = NSLock()

    public static let maxHighlightLength = 2_000_000

    public init(language: Language) {
        Self.lock.lock()
        if let cached = Self.cache[language] {
            self.rules = cached
        } else {
            let built = LanguageDefinitions.rules(for: language)
            Self.cache[language] = built
            self.rules = built
        }
        Self.lock.unlock()
    }

    public func highlight(
        storage: NSTextStorage,
        in editedRange: NSRange,
        font: NSFont = Theme.editorFont,
        textColor: NSColor = Theme.foreground
    ) {
        let string = storage.string as NSString
        let totalLength = string.length
        guard totalLength > 0 else { return }

        // If file is very large (> 2MB), clamp range to prevent freezing
        let effectiveRange: NSRange
        if totalLength > Self.maxHighlightLength {
            let start = max(0, editedRange.location - 5_000)
            let end = min(totalLength, NSMaxRange(editedRange) + 5_000)
            effectiveRange = NSRange(location: start, length: end - start)
        } else {
            // Expand range to line boundaries
            let start = string.lineRange(for: NSRange(location: min(editedRange.location, totalLength - 1), length: 0)).location
            let endClamped = min(NSMaxRange(editedRange), totalLength)
            let end = NSMaxRange(string.lineRange(for: NSRange(location: max(endClamped - 1, 0), length: 0)))
            effectiveRange = NSRange(location: start, length: end - start)
        }

        guard effectiveRange.length > 0 && NSMaxRange(effectiveRange) <= totalLength else { return }

        // Reset default foreground and font
        storage.addAttributes([
            .foregroundColor: textColor,
            .font: font
        ], range: effectiveRange)

        guard !rules.isEmpty else { return }

        let fullString = storage.string
        for rule in rules {
            rule.regex.enumerateMatches(in: fullString, options: [], range: effectiveRange) { match, _, _ in
                guard let matchRange = match?.range, matchRange.location != NSNotFound else { return }
                storage.addAttribute(.foregroundColor, value: rule.color, range: matchRange)
            }
        }
    }
}
