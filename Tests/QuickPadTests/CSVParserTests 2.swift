import XCTest
@testable import QuickPad

final class CSVParserTests: XCTestCase {
    func testSimpleCSV() {
        let text = "id,name,role\n1,Alice,Engineer\n2,Bob,Designer"
        let doc = CSVDocument.parse(text: text)

        XCTAssertEqual(doc.headers, ["id", "name", "role"])
        XCTAssertEqual(doc.rows.count, 2)
        XCTAssertEqual(doc.rows[0], ["1", "Alice", "Engineer"])
        XCTAssertEqual(doc.rows[1], ["2", "Bob", "Designer"])
    }

    func testQuotedFieldsWithCommas() {
        let text = "name,location,note\n\"Doe, John\",\"Zurich, Switzerland\",\"Swiss precision\""
        let doc = CSVDocument.parse(text: text)

        XCTAssertEqual(doc.headers, ["name", "location", "note"])
        XCTAssertEqual(doc.rows.count, 1)
        XCTAssertEqual(doc.rows[0], ["Doe, John", "Zurich, Switzerland", "Swiss precision"])
    }

    func testEscapedQuotes() {
        let text = "title,quote\nBook,\"He said \"\"Hello\"\" to her\""
        let doc = CSVDocument.parse(text: text)

        XCTAssertEqual(doc.headers, ["title", "quote"])
        XCTAssertEqual(doc.rows.count, 1)
        XCTAssertEqual(doc.rows[0], ["Book", "He said \"Hello\" to her"])
    }

    func testTSVParsing() {
        let text = "id\tcode\tstatus\n101\tSW-01\tActive\n102\tSW-02\tPending"
        let doc = CSVDocument.parse(text: text, delimiter: "\t")

        XCTAssertEqual(doc.headers, ["id", "code", "status"])
        XCTAssertEqual(doc.rows.count, 2)
        XCTAssertEqual(doc.rows[0], ["101", "SW-01", "Active"])
        XCTAssertEqual(doc.rows[1], ["102", "SW-02", "Pending"])
    }
}
