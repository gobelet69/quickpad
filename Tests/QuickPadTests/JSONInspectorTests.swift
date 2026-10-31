import XCTest
@testable import QuickPadCore

final class JSONInspectorTests: XCTestCase {
    func testJSONNodeHierarchy() throws {
        let jsonString = """
        {
          "name": "QuickPad",
          "version": 1.0,
          "features": ["smart_preview", "sub_millisecond_launch"],
          "author": {
            "studio": "111iridescence"
          }
        }
        """

        let data = jsonString.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data, options: [])
        let root = JSONNode(key: nil, value: parsed, jsonPath: "")

        XCTAssertFalse(root.isLeaf)
        XCTAssertEqual(root.children.count, 4)

        let keys = root.children.compactMap { $0.key }
        XCTAssertTrue(keys.contains("name"))
        XCTAssertTrue(keys.contains("version"))
        XCTAssertTrue(keys.contains("features"))
        XCTAssertTrue(keys.contains("author"))

        if let featuresNode = root.children.first(where: { $0.key == "features" }) {
            XCTAssertFalse(featuresNode.isLeaf)
            XCTAssertEqual(featuresNode.children.count, 2)
            XCTAssertEqual(featuresNode.children[0].jsonPath, "features[0]")
        }
    }

    func testMarkdownParserBasic() {
        let md = "# Title\n\n- [x] Task 1\n- [ ] Task 2\n\n```swift\nlet x = 42\n```"
        let html = MarkdownParser.toHTML(markdown: md, isDark: false)

        XCTAssertTrue(html.contains("<h1>Title</h1>"))
        XCTAssertTrue(html.contains("<li class=\"task-list-item\">"))
        XCTAssertTrue(html.contains("<pre><code class=\"language-swift\">let x = 42</code></pre>"))
    }
}
