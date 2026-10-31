import XCTest
@testable import QuickPad

final class EncodingTests: XCTestCase {
    func testUTF8Detection() {
        let text = "Hello, 111iridescence! Prismatic Atelier 🌈"
        let data = text.data(using: .utf8)!
        let result = FileEncodingDetector.detect(data: data)

        XCTAssertEqual(result.text, text)
        XCTAssertEqual(result.encoding, .utf8)
        XCTAssertFalse(result.hasBOM)
        XCTAssertFalse(result.isBinary)
        XCTAssertEqual(result.encodingName, "UTF-8")
    }

    func testUTF8WithBOMDetection() {
        let text = "Text with UTF-8 BOM"
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(text.data(using: .utf8)!)

        let result = FileEncodingDetector.detect(data: data)
        XCTAssertEqual(result.text, text)
        XCTAssertEqual(result.encoding, .utf8)
        XCTAssertTrue(result.hasBOM)
        XCTAssertFalse(result.isBinary)
        XCTAssertEqual(result.encodingName, "UTF-8 with BOM")
    }

    func testUTF16LEWithBOMDetection() {
        let text = "Text in UTF-16 Little Endian"
        var data = Data([0xFF, 0xFE])
        data.append(text.data(using: .utf16LittleEndian)!)

        let result = FileEncodingDetector.detect(data: data)
        XCTAssertEqual(result.text, text)
        XCTAssertEqual(result.encoding, .utf16LittleEndian)
        XCTAssertTrue(result.hasBOM)
        XCTAssertFalse(result.isBinary)
    }

    func testUTF16BEWithBOMDetection() {
        let text = "Text in UTF-16 Big Endian"
        var data = Data([0xFE, 0xFF])
        data.append(text.data(using: .utf16BigEndian)!)

        let result = FileEncodingDetector.detect(data: data)
        XCTAssertEqual(result.text, text)
        XCTAssertEqual(result.encoding, .utf16BigEndian)
        XCTAssertTrue(result.hasBOM)
        XCTAssertFalse(result.isBinary)
    }

    func testBinaryDetection() {
        let binaryBytes: [UInt8] = [0x7F, 0x45, 0x4C, 0x46, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00]
        let data = Data(binaryBytes)
        let result = FileEncodingDetector.detect(data: data)

        XCTAssertTrue(result.isBinary)
        XCTAssertEqual(result.encodingName, "Binary")
    }

    func testLineEndingDetectionAndNormalization() {
        let unixText = "Line 1\nLine 2\nLine 3"
        XCTAssertEqual(LineEnding.detect(in: unixText), .lf)

        let windowsText = "Line 1\r\nLine 2\r\nLine 3"
        XCTAssertEqual(LineEnding.detect(in: windowsText), .crlf)

        let classicMacText = "Line 1\rLine 2\rLine 3"
        XCTAssertEqual(LineEnding.detect(in: classicMacText), .cr)

        let normalizedToWindows = LineEnding.crlf.normalize(text: unixText)
        XCTAssertEqual(normalizedToWindows, windowsText)

        let normalizedToUnix = LineEnding.lf.normalize(text: windowsText)
        XCTAssertEqual(normalizedToUnix, unixText)
    }
}
