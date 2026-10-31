import XCTest
@testable import QuickPadCore

final class SyntaxHighlighterTests: XCTestCase {
    func testLanguageDetection() {
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "test.swift")), .swift)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "script.py")), .python)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "main.rs")), .rust)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "doc.md")), .markdown)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "data.json")), .json)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "config.yaml")), .yaml)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "Cargo.toml")), .toml)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "data.csv")), .csv)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "index.html")), .html)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "Dockerfile")), .shell)
        XCTAssertEqual(Language.detect(for: URL(fileURLWithPath: "unknown.xyz123")), .plainText)
    }

    func testHighlighterExecution() {
        let storage = NSTextStorage(string: "import Foundation\nlet count: Int = 42\n// A swift comment")
        let highlighter = SyntaxHighlighter(language: .swift)
        highlighter.highlight(storage: storage, in: NSRange(location: 0, length: storage.length))

        // Check that attributes were applied
        var hasColors = false
        storage.enumerateAttributes(in: NSRange(location: 0, length: storage.length)) { attrs, _, _ in
            if attrs[.foregroundColor] != nil {
                hasColors = true
            }
        }
        XCTAssertTrue(hasColors)
    }
}
