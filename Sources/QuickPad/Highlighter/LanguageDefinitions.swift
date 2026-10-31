import AppKit

public struct HighlightRule {
    public let regex: NSRegularExpression
    public let color: NSColor

    public init(pattern: String, color: NSColor, options: NSRegularExpression.Options = []) {
        // Safe regex initialization with empty pattern fallback
        self.regex = (try? NSRegularExpression(pattern: pattern, options: options)) ?? NSRegularExpression()
        self.color = color
    }
}

public enum LanguageDefinitions {
    public static func rules(for language: Language) -> [HighlightRule] {
        var rules: [HighlightRule] = []

        switch language {
        case .swift:
            rules = [
                HighlightRule(pattern: "//.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "\"\"\"[\\s\\S]*?\"\"\"", color: Theme.syntaxString),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(import|class|struct|enum|protocol|extension|func|var|let|if|else|guard|switch|case|default|for|while|repeat|return|break|continue|throw|throws|try|catch|do|in|as|is|self|Self|super|init|deinit|static|override|private|public|internal|fileprivate|open|final|lazy|weak|unowned|mutating|nonmutating|async|await|actor|some|any|where|typealias|defer|indirect|isolated|nonisolated)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(String|Int|Double|Float|Bool|Array|Dictionary|Set|Optional|Result|Error|Void|Any|AnyObject|Never|Data|Date|URL|UUID|Character|UInt|Int64|Int32|CGFloat)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b(true|false|nil)\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b|\\b0b[01]+\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "@[a-zA-Z_]\\w*", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .python:
            rules = [
                HighlightRule(pattern: "\"\"\"[\\s\\S]*?\"\"\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'''[\\s\\S]*?'''", color: Theme.syntaxString),
                HighlightRule(pattern: "#.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(import|from|class|def|return|if|elif|else|for|while|break|continue|pass|raise|try|except|finally|with|as|yield|lambda|global|nonlocal|assert|del|in|not|and|or|is|async|await|match|case)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(int|float|str|bool|list|dict|set|tuple|bytes|object|type|None|True|False)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "@[a-zA-Z_]\\w*", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .rust:
            rules = [
                HighlightRule(pattern: "//.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "r#\"[\\s\\S]*?\"#", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(fn|let|mut|const|static|struct|enum|trait|impl|type|where|for|while|loop|if|else|match|return|break|continue|mod|use|pub|crate|super|self|Self|unsafe|async|await|move|ref|as|in|dyn|extern)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(i8|i16|i32|i64|i128|isize|u8|u16|u32|u64|u128|usize|f32|f64|bool|char|str|String|Vec|Option|Result|Box|Rc|Arc)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b(true|false|Some|None|Ok|Err)\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b\\d+(_\\d+)*(\\.\\d+)?\\b|\\b0x[0-9a-fA-F_]+\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "#\\[.*?\\]", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .javascript, .typescript:
            rules = [
                HighlightRule(pattern: "//.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "`[\\s\\S]*?`", color: Theme.syntaxString),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(const|let|var|function|class|interface|type|enum|extends|implements|return|if|else|switch|case|default|for|while|do|break|continue|throw|try|catch|finally|new|delete|typeof|instanceof|void|this|super|import|export|from|as|default|async|await|yield)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(string|number|boolean|symbol|any|void|never|unknown|object|Array|Promise|Record|Map|Set)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b(true|false|null|undefined|NaN|Infinity)\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .json:
            rules = [
                HighlightRule(pattern: "\"([^\"]+)\"\\s*:", color: Theme.syntaxKeyword), // Keys
                HighlightRule(pattern: ":\\s*(\"(?:[^\"\\\\]|\\\\.)*\")", color: Theme.syntaxString), // String values
                HighlightRule(pattern: "\\b(true|false|null)\\b", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "-?\\b\\d+(\\.\\d+)?([eE][+-]?\\d+)?\\b", color: Theme.syntaxNumber),
            ]

        case .yaml:
            rules = [
                HighlightRule(pattern: "#.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "^\\s*([a-zA-Z0-9_-]+):", color: Theme.syntaxKeyword, options: .anchorsMatchLines),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(true|false|yes|no|null|~)\\b", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b", color: Theme.syntaxNumber),
            ]

        case .toml:
            rules = [
                HighlightRule(pattern: "#.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "^\\[.*?\\]", color: Theme.syntaxKeyword, options: .anchorsMatchLines),
                HighlightRule(pattern: "^\\s*([a-zA-Z0-9_-]+)\\s*=", color: Theme.syntaxType, options: .anchorsMatchLines),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(true|false)\\b", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b", color: Theme.syntaxNumber),
            ]

        case .html, .xml:
            rules = [
                HighlightRule(pattern: "<!--[\\s\\S]*?-->", color: Theme.syntaxComment),
                HighlightRule(pattern: "<!DOCTYPE[^>]*>", color: Theme.syntaxComment),
                HighlightRule(pattern: "</?[a-zA-Z0-9:-]+", color: Theme.syntaxTag),
                HighlightRule(pattern: ">|/>", color: Theme.syntaxTag),
                HighlightRule(pattern: "\\b([a-zA-Z0-9:-]+)(?=\\=)", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
            ]

        case .css:
            rules = [
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "([a-zA-Z0-9_.-]+)(?=\\s*\\{)", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "([a-zA-Z-]+)(?=\\s*:)", color: Theme.syntaxType),
                HighlightRule(pattern: ":\\s*([^;]+);", color: Theme.syntaxString),
                HighlightRule(pattern: "#[0-9a-fA-F]{3,8}\\b", color: Theme.syntaxNumber),
            ]

        case .sql:
            rules = [
                HighlightRule(pattern: "--.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(SELECT|FROM|WHERE|INSERT|INTO|UPDATE|DELETE|JOIN|LEFT|RIGHT|INNER|OUTER|FULL|GROUP|BY|ORDER|HAVING|LIMIT|OFFSET|CREATE|TABLE|DROP|ALTER|ADD|INDEX|PRIMARY|KEY|FOREIGN|REFERENCES|NOT|NULL|DEFAULT|AS|AND|OR|IN|BETWEEN|LIKE|IS|EXISTS|CASE|WHEN|THEN|ELSE|END|UNION|ALL)\\b", color: Theme.syntaxKeyword, options: .caseInsensitive),
                HighlightRule(pattern: "\\b(INTEGER|VARCHAR|TEXT|BOOLEAN|DATE|TIMESTAMP|FLOAT|DOUBLE|BLOB)\\b", color: Theme.syntaxType, options: .caseInsensitive),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b", color: Theme.syntaxNumber),
            ]

        case .shell:
            rules = [
                HighlightRule(pattern: "#.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(if|then|else|elif|fi|case|esac|for|while|until|do|done|in|function|return|exit|export|local|source|alias)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\$[a-zA-Z_0-9]+|\\$\\{.*?\\}", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b(echo|cd|ls|mkdir|rm|cp|mv|cat|grep|sed|awk|find|curl|git|ssh|sudo|brew)\\b", color: Theme.syntaxFunction),
            ]

        case .c, .cpp:
            rules = [
                HighlightRule(pattern: "//.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "#\\s*(include|define|ifdef|ifndef|endif|pragma|if|else|elif)[^\\n]*", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "'(?:[^'\\\\]|\\\\.)*'", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(int|char|float|double|void|bool|long|short|unsigned|signed|struct|class|enum|union|typedef|auto|const|static|volatile|extern|inline|virtual|override|public|protected|private|template|typename|namespace|using)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b(if|else|for|while|do|switch|case|default|break|continue|return|goto|try|catch|throw|new|delete|sizeof)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(true|false|nullptr|NULL)\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .java:
            rules = [
                HighlightRule(pattern: "//.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(public|private|protected|class|interface|enum|extends|implements|static|final|abstract|synchronized|volatile|transient|native|strictfp|return|if|else|switch|case|default|for|while|do|break|continue|throw|throws|try|catch|finally|new|this|super|package|import|instanceof)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(int|boolean|char|byte|short|long|float|double|void|String|Integer|Boolean|List|Map|Set|Object)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b(true|false|null)\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "@[a-zA-Z_]\\w*", color: Theme.syntaxAttribute),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .go:
            rules = [
                HighlightRule(pattern: "//.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
                HighlightRule(pattern: "/\\*[\\s\\S]*?\\*/", color: Theme.syntaxComment),
                HighlightRule(pattern: "`[\\s\\S]*?`", color: Theme.syntaxString),
                HighlightRule(pattern: "\"(?:[^\"\\\\]|\\\\.)*\"", color: Theme.syntaxString),
                HighlightRule(pattern: "\\b(package|import|func|return|defer|go|select|chan|struct|interface|type|map|const|var|if|else|switch|case|default|for|range|break|continue|fallthrough)\\b", color: Theme.syntaxKeyword),
                HighlightRule(pattern: "\\b(int|int8|int16|int32|int64|uint|uint8|uint16|uint32|uint64|float32|float64|complex64|complex128|string|bool|byte|rune|error|any)\\b", color: Theme.syntaxType),
                HighlightRule(pattern: "\\b(true|false|nil|iota)\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b\\d+(\\.\\d+)?\\b|\\b0x[0-9a-fA-F]+\\b", color: Theme.syntaxNumber),
                HighlightRule(pattern: "\\b([a-zA-Z_]\\w*)\\s*(?=\\()", color: Theme.syntaxFunction),
            ]

        case .markdown:
            rules = [
                HighlightRule(pattern: "^#{1,6}\\s.*$", color: Theme.syntaxKeyword, options: .anchorsMatchLines),
                HighlightRule(pattern: "```[\\s\\S]*?```", color: Theme.syntaxString),
                HighlightRule(pattern: "`[^`\\n]+`", color: Theme.syntaxString),
                HighlightRule(pattern: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", color: Theme.syntaxType),
                HighlightRule(pattern: "^\\s*[-*+]\\s", color: Theme.syntaxAttribute, options: .anchorsMatchLines),
                HighlightRule(pattern: "^\\s*\\d+\\.\\s", color: Theme.syntaxAttribute, options: .anchorsMatchLines),
                HighlightRule(pattern: "^>\\s.*$", color: Theme.syntaxComment, options: .anchorsMatchLines),
            ]

        default:
            rules = []
        }

        return rules
    }
}
