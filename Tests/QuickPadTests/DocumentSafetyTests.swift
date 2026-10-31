import XCTest
@testable import QuickPadCore

final class DocumentSafetyTests: XCTestCase {
    func testDocumentSaveAndReloadRoundtrip() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("QuickPadSafetyTest_\(UUID().uuidString).txt")

        let originalContent = "First line\nSecond line with unicode: 111iridescence ✨\nThird line"
        let doc = Document(fileURL: fileURL, content: originalContent, encoding: .utf8, lineEnding: .lf)

        try doc.save()
        XCTAssertFalse(doc.isModified)

        let reloadedDoc = try Document.open(url: fileURL)
        XCTAssertEqual(reloadedDoc.content, originalContent)
        XCTAssertEqual(reloadedDoc.encoding, .utf8)
        XCTAssertEqual(reloadedDoc.lineEnding, .lf)

        // Modify content
        reloadedDoc.content = originalContent + "\nModified line"
        XCTAssertTrue(reloadedDoc.isModified)

        try reloadedDoc.save()
        XCTAssertFalse(reloadedDoc.isModified)

        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }

    func testBinarySaveBlocked() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("binary_test_\(UUID().uuidString).bin")

        let doc = Document(fileURL: fileURL, content: "Binary content", isBinary: true)
        XCTAssertThrowsError(try doc.save())
    }
}
