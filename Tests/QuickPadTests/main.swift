import Foundation
import AppKit

var testsPassed = 0
var testsFailed = 0

func assertEqual<T: Equatable>(_ a: T, _ b: T, _ message: String = "", file: String = #file, line: Int = #line) {
    if a == b {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)]: expected \(b), got \(a) \(message)")
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    if condition {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("❌ FAIL [\(URL(fileURLWithPath: file).lastPathComponent):\(line)]: condition was false \(message)")
    }
}

func assertFalse(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    assertTrue(!condition, message, file: file, line: line)
}

print("▸ Running QuickPad Test Suite...")

// 1. Encoding Tests
print("  • Testing Encoding Detection & BOM...")
let text = "Hello, 111iridescence! Prismatic Atelier 🌈"
let data = text.data(using: .utf8)!
let r1 = FileEncodingDetector.detect(data: data)
assertEqual(r1.text, text)
assertEqual(r1.encoding, .utf8)
assertFalse(r1.hasBOM)
assertFalse(r1.isBinary)
assertEqual(r1.encodingName, "UTF-8")

var bomData = Data([0xEF, 0xBB, 0xBF])
bomData.append(text.data(using: .utf8)!)
let r2 = FileEncodingDetector.detect(data: bomData)
assertEqual(r2.text, text)
assertTrue(r2.hasBOM)
assertEqual(r2.encodingName, "UTF-8 with BOM")

var utf16LE = Data([0xFF, 0xFE])
utf16LE.append(text.data(using: .utf16LittleEndian)!)
let r3 = FileEncodingDetector.detect(data: utf16LE)
assertEqual(r3.text, text)
assertEqual(r3.encoding, .utf16LittleEndian)
assertTrue(r3.hasBOM)

var utf16BE = Data([0xFE, 0xFF])
utf16BE.append(text.data(using: .utf16BigEndian)!)
let r4 = FileEncodingDetector.detect(data: utf16BE)
assertEqual(r4.text, text)
assertEqual(r4.encoding, .utf16BigEndian)
assertTrue(r4.hasBOM)

// Binary Detection
let binBytes: [UInt8] = [0x7F, 0x45, 0x4C, 0x46, 0x00, 0x00, 0x01]
let rBin = FileEncodingDetector.detect(data: Data(binBytes))
assertTrue(rBin.isBinary)
assertEqual(rBin.encodingName, "Binary")

// Line Endings
print("  • Testing Line Ending Detection & Normalization...")
let unix = "A\nB\nC"
let win = "A\r\nB\r\nC"
let mac = "A\rB\rC"
assertEqual(LineEnding.detect(in: unix), .lf)
assertEqual(LineEnding.detect(in: win), .crlf)
assertEqual(LineEnding.detect(in: mac), .cr)
assertEqual(LineEnding.crlf.normalize(text: unix), win)
assertEqual(LineEnding.lf.normalize(text: win), unix)

// 2. CSV Parser Tests
print("  • Testing CSV / TSV Parsing...")
let csvText = "id,name,role\n1,Alice,Engineer\n2,\"Bob, Jr.\",\"\"\"Designer\"\"\""
let csvDoc = CSVDocument.parse(text: csvText)
assertEqual(csvDoc.headers, ["id", "name", "role"])
assertEqual(csvDoc.rows.count, 2)
assertEqual(csvDoc.rows[0], ["1", "Alice", "Engineer"])
assertEqual(csvDoc.rows[1], ["2", "Bob, Jr.", "\"Designer\""])

let tsvText = "a\tb\tc\n1\t2\t3"
let tsvDoc = CSVDocument.parse(text: tsvText, delimiter: "\t")
assertEqual(tsvDoc.headers, ["a", "b", "c"])
assertEqual(tsvDoc.rows.count, 1)
assertEqual(tsvDoc.rows[0], ["1", "2", "3"])

// 3. JSON Node Hierarchy Tests
print("  • Testing JSON Tree & Path Extraction...")
let jsonSample = """
{
  "product": "QuickPad",
  "version": 1.0,
  "features": ["preview", "native_speed"],
  "meta": { "studio": "111iridescence" }
}
"""
let jData = jsonSample.data(using: .utf8)!
let jObj = try! JSONSerialization.jsonObject(with: jData, options: [])
let jRoot = JSONNode(key: nil, value: jObj, jsonPath: "")
assertFalse(jRoot.isLeaf)
assertEqual(jRoot.children.count, 4)
if let featNode = jRoot.children.first(where: { $0.key == "features" }) {
    assertEqual(featNode.children.count, 2)
    assertEqual(featNode.children[0].jsonPath, "features[0]")
}

// 4. Markdown Parser Tests
print("  • Testing Markdown (GFM) Parsing...")
let mdSample = """
# QuickPad

- [x] Fast launch
- [ ] Legacy overhead

| Feature | Status |
| --- | --- |
| **Bold Feature** | *Italic Status* |
| Previews | Supported |

```swift
let editor = "ultra-fast"
```
"""
let html = MarkdownParser.toHTML(markdown: mdSample, isDark: true)
assertTrue(html.contains("<h1>QuickPad</h1>"))
assertTrue(html.contains("<li class=\"task-list-item\">"))
assertTrue(html.contains("<table>"))
assertTrue(html.contains("<td><strong>Bold Feature</strong></td>"))
assertTrue(html.contains("<td><em>Italic Status</em></td>"))
assertTrue(html.contains("<code class=\"language-swift\">let editor = &quot;ultra-fast&quot;</code>"))

// 5. Language Detection & Syntax Highlighter
print("  • Testing Language Detection & Syntax Highlighting...")
assertEqual(Language.detect(for: URL(fileURLWithPath: "main.swift")), .swift)
assertEqual(Language.detect(for: URL(fileURLWithPath: "script.py")), .python)
assertEqual(Language.detect(for: URL(fileURLWithPath: "lib.rs")), .rust)
assertEqual(Language.detect(for: URL(fileURLWithPath: "data.json")), .json)
assertEqual(Language.detect(for: URL(fileURLWithPath: "doc.md")), .markdown)
assertEqual(Language.detect(for: URL(fileURLWithPath: "config.yaml")), .yaml)
assertEqual(Language.detect(for: URL(fileURLWithPath: "app.toml")), .toml)
assertEqual(Language.detect(for: URL(fileURLWithPath: "data.csv")), .csv)
assertEqual(Language.detect(for: URL(fileURLWithPath: "index.html")), .html)

let storage = NSTextStorage(string: "import Foundation\nlet count: Int = 42\n// comment")
let hl = SyntaxHighlighter(language: .swift)
hl.highlight(storage: storage, in: NSRange(location: 0, length: storage.length))
var colorCount = 0
storage.enumerateAttributes(in: NSRange(location: 0, length: storage.length)) { attrs, _, _ in
    if attrs[.foregroundColor] != nil { colorCount += 1 }
}
assertTrue(colorCount > 0)

// 6. Document Safety & Roundtrip
print("  • Testing Document Safety & Atomic Writes...")
let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("quickpad_test_\(UUID().uuidString).txt")
let docContent = "Hello 111iridescence\nLine 2 with UTF-8: 💎\nLine 3"
let testDoc = Document(fileURL: tempFile, content: docContent, encoding: .utf8, lineEnding: .lf)
try! testDoc.save()
assertFalse(testDoc.isModified)

let openedDoc = try! Document.open(url: tempFile)
assertEqual(openedDoc.content, docContent)
assertEqual(openedDoc.encoding, .utf8)
assertEqual(openedDoc.lineEnding, .lf)

// Verify binary file write protection
let binDoc = Document(fileURL: tempFile, content: "malicious binary write", isBinary: true)
var caughtError = false
do {
    try binDoc.save()
} catch {
    caughtError = true
}
assertTrue(caughtError, "Binary document write should be safely blocked")

// Verify MASTER directory safety protection (including case variations and relative paths)
let homeURL = FileManager.default.homeDirectoryForCurrentUser
let masterProtectedURL = homeURL.appendingPathComponent("Documents/MASTER/forbidden.txt")
let masterDoc = Document(fileURL: masterProtectedURL, content: "prohibited write")
var caughtMasterError = false
do {
    try masterDoc.save()
} catch {
    caughtMasterError = true
}
assertTrue(caughtMasterError, "Saving to /Documents/MASTER must be strictly prohibited")

// Case-insensitive and relative path boundary checks
assertTrue(Document.isProtectedDirectory(url: homeURL.appendingPathComponent("documents/master/secret.txt")), "Lowercase documents/master must be blocked")
assertTrue(Document.isProtectedDirectory(url: homeURL.appendingPathComponent("Documents/Master/nested/file.txt")), "Mixed-case Documents/Master must be blocked")
assertTrue(Document.isProtectedDirectory(url: homeURL.appendingPathComponent("Documents/Other/../MASTER/file.txt")), "Relative /../MASTER must be blocked")
assertTrue(Document.isProtectedDirectory(url: homeURL.appendingPathComponent("Documents/MASTER")), "Direct directory path must be blocked")
assertFalse(Document.isProtectedDirectory(url: homeURL.appendingPathComponent("Documents/Masterpiece/safe.txt")), "Non-master prefixes must be allowed")

// Verify Markdown XSS link sanitization and CSP protection
let maliciousMarkdown = "[Click me](javascript:alert(1)) and [Safe Link](https://111iridescence.org)"
let sanitizedHTML = MarkdownParser.toHTML(markdown: maliciousMarkdown, isDark: false)
assertFalse(sanitizedHTML.contains("href=\"javascript:"), "javascript: URIs must be sanitized")
assertTrue(sanitizedHTML.contains("href=\"https://111iridescence.org\""), "https URLs must be preserved")
assertTrue(sanitizedHTML.contains("Content-Security-Policy"), "Strict Content Security Policy meta tag must be present")

try? FileManager.default.removeItem(at: tempFile)

print("--------------------------------------------------")
print("All checks finished: \(testsPassed) assertions passed, \(testsFailed) failed.")
if testsFailed > 0 {
    exit(1)
} else {
    print("✓ TEST SUITE PASSED")
}
