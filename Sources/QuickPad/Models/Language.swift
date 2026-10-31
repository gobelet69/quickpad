import Foundation

public enum PreviewKind: Sendable {
    case markdown
    case json
    case csv(isTSV: Bool)
    case structured(format: StructuredFormat)
    case html
}

public enum StructuredFormat: String, Sendable {
    case yaml = "YAML"
    case toml = "TOML"
    case xml = "XML"
}

public enum Language: String, CaseIterable, Sendable {
    case plainText = "Plain Text"
    case markdown = "Markdown"
    case json = "JSON"
    case yaml = "YAML"
    case toml = "TOML"
    case xml = "XML"
    case csv = "CSV"
    case tsv = "TSV"
    case html = "HTML"
    case css = "CSS"
    case swift = "Swift"
    case python = "Python"
    case rust = "Rust"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case c = "C"
    case cpp = "C++"
    case java = "Java"
    case go = "Go"
    case sql = "SQL"
    case shell = "Shell"
    case config = "Config"

    public var previewKind: PreviewKind? {
        switch self {
        case .markdown:
            return .markdown
        case .json:
            return .json
        case .csv:
            return .csv(isTSV: false)
        case .tsv:
            return .csv(isTSV: true)
        case .yaml:
            return .structured(format: .yaml)
        case .toml:
            return .structured(format: .toml)
        case .xml:
            return .structured(format: .xml)
        case .html:
            return .html
        default:
            return nil
        }
    }

    public var hasPreview: Bool {
        return previewKind != nil
    }

    public static func detect(for url: URL) -> Language {
        let filename = url.lastPathComponent.lowercased()
        let ext = url.pathExtension.lowercased()

        // Known filenames
        switch filename {
        case "dockerfile": return .shell
        case "makefile": return .shell
        case "cargo.lock", "cargo.toml": return .toml
        case ".gitignore", ".env", ".editorconfig": return .config
        default: break
        }

        switch ext {
        case "md", "markdown", "mdown", "mkd": return .markdown
        case "json", "jsonl", "geojson": return .json
        case "yaml", "yml": return .yaml
        case "toml": return .toml
        case "xml", "plist", "svg", "xaml", "rss", "atom": return .xml
        case "csv": return .csv
        case "tsv": return .tsv
        case "html", "htm", "xhtml": return .html
        case "css", "scss", "sass", "less": return .css
        case "swift": return .swift
        case "py", "pyw", "wsgi": return .python
        case "rs": return .rust
        case "js", "mjs", "cjs": return .javascript
        case "ts", "tsx", "jsx": return .typescript
        case "c", "h": return .c
        case "cpp", "hpp", "cc", "cxx": return .cpp
        case "java": return .java
        case "go": return .go
        case "sql": return .sql
        case "sh", "bash", "zsh", "fish": return .shell
        case "ini", "conf", "cfg", "env", "properties": return .config
        default: return .plainText
        }
    }
}
