import Foundation

public struct FileEncodingResult: Sendable {
    public let text: String
    public let encoding: String.Encoding
    public let hasBOM: Bool
    public let isBinary: Bool
    public let encodingName: String
}

public enum FileEncodingDetector {
    /// Detects encoding, BOM, and binary characteristics of data.
    public static func detect(data: Data) -> FileEncodingResult {
        guard !data.isEmpty else {
            return FileEncodingResult(
                text: "",
                encoding: .utf8,
                hasBOM: false,
                isBinary: false,
                encodingName: "UTF-8"
            )
        }

        // 1. Check for BOMs
        if data.starts(with: [0xEF, 0xBB, 0xBF]) {
            // UTF-8 with BOM
            let textData = data.subdata(in: 3..<data.count)
            let text = String(data: textData, encoding: .utf8) ?? ""
            return FileEncodingResult(
                text: text,
                encoding: .utf8,
                hasBOM: true,
                isBinary: false,
                encodingName: "UTF-8 with BOM"
            )
        }

        if data.starts(with: [0xFF, 0xFE]) {
            // UTF-16 LE with BOM
            let textData = data.subdata(in: 2..<data.count)
            let text = String(data: textData, encoding: .utf16LittleEndian) ?? ""
            return FileEncodingResult(
                text: text,
                encoding: .utf16LittleEndian,
                hasBOM: true,
                isBinary: false,
                encodingName: "UTF-16 LE BOM"
            )
        }

        if data.starts(with: [0xFE, 0xFF]) {
            // UTF-16 BE with BOM
            let textData = data.subdata(in: 2..<data.count)
            let text = String(data: textData, encoding: .utf16BigEndian) ?? ""
            return FileEncodingResult(
                text: text,
                encoding: .utf16BigEndian,
                hasBOM: true,
                isBinary: false,
                encodingName: "UTF-16 BE BOM"
            )
        }

        // 2. Binary check heuristic on sample (first 4096 bytes)
        let sampleSize = min(data.count, 4096)
        let sample = data.subdata(in: 0..<sampleSize)
        var nullCount = 0
        var controlCount = 0

        for byte in sample {
            if byte == 0 {
                nullCount += 1
            } else if byte < 32 && byte != 9 && byte != 10 && byte != 13 {
                // Non-standard ASCII control characters
                controlCount += 1
            }
        }

        // Null bytes strongly indicate binary files (executables, images, etc.)
        if nullCount > 0 || (Double(controlCount) / Double(sampleSize) > 0.15) {
            return FileEncodingResult(
                text: "[Binary file detected - editing binary files as plain text is disabled to prevent corruption]",
                encoding: .utf8,
                hasBOM: false,
                isBinary: true,
                encodingName: "Binary"
            )
        }

        // 3. Try UTF-8
        if let utf8String = String(data: data, encoding: .utf8) {
            return FileEncodingResult(
                text: utf8String,
                encoding: .utf8,
                hasBOM: false,
                isBinary: false,
                encodingName: "UTF-8"
            )
        }

        // 4. Try UTF-16 without BOM
        if let utf16LE = String(data: data, encoding: .utf16LittleEndian) {
            return FileEncodingResult(
                text: utf16LE,
                encoding: .utf16LittleEndian,
                hasBOM: false,
                isBinary: false,
                encodingName: "UTF-16 LE"
            )
        }

        // 5. Try Legacy Encodings
        let legacyCandidates: [(String.Encoding, String)] = [
            (.windowsCP1252, "Windows-1252"),
            (.isoLatin1, "ISO-8859-1 (Latin 1)"),
            (.macOSRoman, "Mac Roman"),
            (.shiftJIS, "Shift-JIS"),
            (.japaneseEUC, "EUC-JP")
        ]

        for (enc, name) in legacyCandidates {
            if let decoded = String(data: data, encoding: enc) {
                return FileEncodingResult(
                    text: decoded,
                    encoding: enc,
                    hasBOM: false,
                    isBinary: false,
                    encodingName: name
                )
            }
        }

        // Fallback: Lossy UTF-8 conversion
        let lossy = String(decoding: data, as: UTF8.self)
        return FileEncodingResult(
            text: lossy,
            encoding: .utf8,
            hasBOM: false,
            isBinary: false,
            encodingName: "UTF-8 (Lossy)"
        )
    }

    /// Prepares data for writing to disk with BOM if needed
    public static func data(for text: String, encoding: String.Encoding, hasBOM: Bool) -> Data? {
        guard var data = text.data(using: encoding) else { return nil }
        if hasBOM {
            if encoding == .utf8 {
                data.insert(contentsOf: [0xEF, 0xBB, 0xBF], at: 0)
            } else if encoding == .utf16LittleEndian {
                data.insert(contentsOf: [0xFF, 0xFE], at: 0)
            } else if encoding == .utf16BigEndian {
                data.insert(contentsOf: [0xFE, 0xFF], at: 0)
            }
        }
        return data
    }
}
