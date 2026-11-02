import Foundation

/// Fast, safe GitHub Flavored Markdown (GFM) parser producing clean HTML with 111iridescence styling.
public struct MarkdownParser {
    public static func toHTML(markdown: String, isDark: Bool) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var htmlLines: [String] = []

        var inCodeFence = false
        var codeFenceLang = ""
        var codeFenceContent: [String] = []

        var inTable = false
        var tableRows: [String] = []

        var inUl = false
        var inOl = false

        func closeLists() {
            if inUl {
                htmlLines.append("</ul>")
                inUl = false
            }
            if inOl {
                htmlLines.append("</ol>")
                inOl = false
            }
        }

        func flushTable() {
            guard inTable, !tableRows.isEmpty else { inTable = false; tableRows.removeAll(); return }
            var tableHTML = "<table>\n"
            for (idx, row) in tableRows.enumerated() {
                // Ignore delimiter row |---|---|
                let trimmed = row.trimmingCharacters(in: .whitespaces)
                if trimmed.contains("---") { continue }

                let cells = row.split(separator: "|", omittingEmptySubsequences: false)
                let filteredCells = cells.map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty || cells.count <= 2 }

                let tag = idx == 0 ? "th" : "td"
                tableHTML += "  <tr>\n"
                for cell in filteredCells {
                    tableHTML += "    <\(tag)>\(parseInline(cell))</\(tag)>\n"
                }
                tableHTML += "  </tr>\n"
            }
            tableHTML += "</table>\n"
            htmlLines.append(tableHTML)
            tableRows.removeAll()
            inTable = false
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 1. Code Fence
            if trimmed.hasPrefix("```") {
                if inCodeFence {
                    // Close code block
                    let escaped = escapeHTML(codeFenceContent.joined(separator: "\n"))
                    htmlLines.append("<pre><code class=\"language-\(escapeHTML(codeFenceLang))\">\(escaped)</code></pre>")
                    codeFenceContent.removeAll()
                    inCodeFence = false
                } else {
                    closeLists()
                    flushTable()
                    inCodeFence = true
                    codeFenceLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                continue
            }

            if inCodeFence {
                codeFenceContent.append(line)
                continue
            }

            // 2. Table row
            if trimmed.hasPrefix("|") && trimmed.hasSuffix("|") && trimmed.count > 1 {
                closeLists()
                inTable = true
                tableRows.append(trimmed)
                continue
            } else if inTable {
                flushTable()
            }

            // 3. Horizontal Rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                closeLists()
                htmlLines.append("<hr/>")
                continue
            }

            // 4. Headings
            if trimmed.hasPrefix("#") {
                closeLists()
                var level = 0
                for char in trimmed {
                    if char == "#" { level += 1 } else { break }
                }
                if level <= 6 {
                    let title = trimmed.dropFirst(level).trimmingCharacters(in: .whitespaces)
                    let parsed = parseInline(String(title))
                    htmlLines.append("<h\(level)>\(parsed)</h\(level)>")
                    continue
                }
            }

            // 5. Blockquote
            if trimmed.hasPrefix(">") {
                closeLists()
                let quoteText = trimmed.dropFirst(1).trimmingCharacters(in: .whitespaces)
                htmlLines.append("<blockquote>\(parseInline(String(quoteText)))</blockquote>")
                continue
            }

            // 6. Task List or Bullet list
            if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("* [ ] ") || trimmed.hasPrefix("* [x] ") {
                if !inUl {
                    closeLists()
                    htmlLines.append("<ul class=\"task-list\">")
                    inUl = true
                }
                let checked = trimmed.contains("[x]")
                let itemText = trimmed.dropFirst(6)
                let checkbox = "<input type=\"checkbox\" disabled \(checked ? "checked" : "") /> "
                htmlLines.append("<li class=\"task-list-item\">\(checkbox)\(parseInline(String(itemText)))</li>")
                continue
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                if inOl { closeLists() }
                if !inUl {
                    htmlLines.append("<ul>")
                    inUl = true
                }
                let itemText = trimmed.dropFirst(2)
                htmlLines.append("<li>\(parseInline(String(itemText)))</li>")
                continue
            }

            // 7. Numbered list
            if let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if inUl { closeLists() }
                if !inOl {
                    htmlLines.append("<ol>")
                    inOl = true
                }
                let itemText = trimmed[match.upperBound...]
                htmlLines.append("<li>\(parseInline(String(itemText)))</li>")
                continue
            }

            // Empty line
            if trimmed.isEmpty {
                closeLists()
                continue
            }

            // Regular paragraph
            closeLists()
            htmlLines.append("<p>\(parseInline(line))</p>")
        }

        if inCodeFence {
            let escaped = escapeHTML(codeFenceContent.joined(separator: "\n"))
            htmlLines.append("<pre><code>\(escaped)</code></pre>")
        }
        flushTable()
        closeLists()

        let bodyContent = htmlLines.joined(separator: "\n")
        return wrapDocument(body: bodyContent, isDark: isDark)
    }

    private static func parseInline(_ text: String) -> String {
        var str = escapeHTML(text)

        // Inline code `code`
        str = str.replacingOccurrences(
            of: #"`([^`\n]+)`"#,
            with: "<code>$1</code>",
            options: .regularExpression
        )

        // Bold **text**
        str = str.replacingOccurrences(
            of: #"\*\*([^\*]+)\*\*"#,
            with: "<strong>$1</strong>",
            options: .regularExpression
        )

        // Italic *text*
        str = str.replacingOccurrences(
            of: #"(?<!\*)\*([^\*]+)\*(?!\*)"#,
            with: "<em>$1</em>",
            options: .regularExpression
        )

        // Strikethrough ~~text~~
        str = str.replacingOccurrences(
            of: #"~~([^~]+)~~"#,
            with: "<del>$1</del>",
            options: .regularExpression
        )

        // Links [title](url) - sanitize schemes to prevent XSS (block javascript:, data:, etc.)
        let linkRegex = try? NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#)
        if let linkRegex = linkRegex {
            let nsStr = str as NSString
            let matches = linkRegex.matches(in: str, range: NSRange(location: 0, length: nsStr.length))
            for match in matches.reversed() {
                let title = nsStr.substring(with: match.range(at: 1))
                let rawUrl = nsStr.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                let lowerUrl = rawUrl.lowercased()
                let isSafe = !lowerUrl.hasPrefix("javascript:") && !lowerUrl.hasPrefix("vbscript:") && !lowerUrl.hasPrefix("data:")
                let replacement: String
                if isSafe {
                    replacement = "<a href=\"\(rawUrl)\" target=\"_blank\" rel=\"noopener noreferrer\">\(title)</a>"
                } else {
                    replacement = "\(title) [unsafe link]"
                }
                let fullRange = match.range(at: 0)
                str = (str as NSString).replacingCharacters(in: fullRange, with: replacement)
            }
        }

        return str
    }

    private static func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private static func wrapDocument(body: String, isDark: Bool) -> String {
        let bg = isDark ? "#18131E" : "#FAF9FC"
        let fg = isDark ? "#EDE8F3" : "#16101D"
        let muted = isDark ? "#9D94A7" : "#6C6274"
        let border = isDark ? "#352C40" : "#E2DDE7"
        let codeBg = isDark ? "#211B28" : "#F0EDF5"
        let linkColor = isDark ? "#C084FC" : "#7E22CE"
        let thBg = isDark ? "#251E2E" : "#F4F2F7"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <style>
          :root {
            color-scheme: \(isDark ? "dark" : "light");
          }
          body {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Helvetica, Arial, sans-serif;
            font-size: 14px;
            line-height: 1.65;
            color: \(fg);
            background-color: \(bg);
            margin: 0;
            padding: 24px 32px;
            word-wrap: break-word;
          }
          h1, h2, h3, h4, h5, h6 {
            color: \(fg);
            font-weight: 600;
            margin-top: 1.4em;
            margin-bottom: 0.6em;
            line-height: 1.25;
          }
          h1 { font-size: 2em; border-bottom: 1px solid \(border); padding-bottom: 0.3em; }
          h2 { font-size: 1.5em; border-bottom: 1px solid \(border); padding-bottom: 0.25em; }
          h3 { font-size: 1.25em; }
          p { margin: 0.8em 0; }
          a { color: \(linkColor); text-decoration: none; }
          a:hover { text-decoration: underline; }
          hr { height: 1px; border: 0; background-color: \(border); margin: 24px 0; }
          blockquote {
            margin: 1em 0;
            padding: 0.4em 1em;
            color: \(muted);
            border-left: 3px solid \(border);
            background: \(codeBg)33;
          }
          code {
            font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
            font-size: 12.5px;
            background-color: \(codeBg);
            padding: 0.2em 0.4em;
            border-radius: 4px;
          }
          pre {
            background-color: \(codeBg);
            border: 1px solid \(border);
            border-radius: 6px;
            padding: 12px 16px;
            overflow-x: auto;
            line-height: 1.45;
          }
          pre code {
            background-color: transparent;
            padding: 0;
            border-radius: 0;
          }
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 1em 0;
          }
          th, td {
            border: 1px solid \(border);
            padding: 8px 12px;
            text-align: left;
          }
          th {
            background-color: \(thBg);
            font-weight: 600;
          }
          ul, ol {
            padding-left: 24px;
            margin: 0.6em 0;
          }
          li { margin: 0.3em 0; }
          strong, b {
            font-weight: 700;
            color: \(fg);
          }
          em, i {
            font-style: italic;
          }
          .task-list { list-style: none; padding-left: 4px; }
          .task-list-item { display: flex; align-items: baseline; gap: 8px; }
        </style>
        <script>
          document.addEventListener('selectionchange', function() {
            clearTimeout(window.__qpSelTimer);
            window.__qpSelTimer = setTimeout(function() {
              var sel = window.getSelection();
              var text = sel ? sel.toString().trim() : '';
              if (text.length > 0 && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.quickpadSelection) {
                window.webkit.messageHandlers.quickpadSelection.postMessage(text);
              }
            }, 60);
          });
        </script>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
