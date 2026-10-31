import Foundation
import AppKit

@main
struct BenchmarkRunner {
    static func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    static func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        let kerr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }

    static func main() {
        let benchDir = URL(fileURLWithPath: "/tmp/quickpad_benchmarks")
        try? FileManager.default.removeItem(at: benchDir)
        try? FileManager.default.createDirectory(at: benchDir, withIntermediateDirectories: true)

        print("================================================================================")
        print("  111iridescence QuickPad — Engineering Performance & Benchmark Suite")
        print("================================================================================")

        let initialRAM = getMemoryUsage()
        print("Baseline Memory RSS: \(Double(initialRAM) / 1024.0 / 1024.0) MB")

        // 1. Generate Test Fixtures
        print("\n[Phase 1] Generating Test Fixtures...")

        // 1 KB plain text
        let tinyURL = benchDir.appendingPathComponent("1KB.txt")
        let tinyText = String(repeating: "The quick brown fox jumps over the lazy dog. 111iridescence precision.\n", count: 14)
        try! tinyText.write(to: tinyURL, atomically: true, encoding: .utf8)

        // 100 KB Markdown
        let smallURL = benchDir.appendingPathComponent("100KB.md")
        var mdContent = "# QuickPad Prismatic Atelier\n\n"
        for i in 1...1000 {
            mdContent += "## Section \(i)\n\n"
            mdContent += "- [x] Ultra-fast performance metric \(i)\n"
            mdContent += "Paragraph with **bold text** and `inline_code` for line \(i).\n\n"
        }
        try! mdContent.write(to: smallURL, atomically: true, encoding: .utf8)

        // 1 MB JSON
        let mediumURL = benchDir.appendingPathComponent("1MB.json")
        var jsonItems: [[String: Any]] = []
        for i in 1...10000 {
            jsonItems.append([
                "id": i,
                "uuid": UUID().uuidString,
                "title": "Item \(i)",
                "active": i % 2 == 0,
                "score": Double(i) * 1.5
            ])
        }
        let jsonData = try! JSONSerialization.data(withJSONObject: ["count": 10000, "items": jsonItems], options: [.prettyPrinted])
        try! jsonData.write(to: mediumURL)

        // 10 MB CSV
        let largeURL = benchDir.appendingPathComponent("10MB.csv")
        var csvString = "id,uuid,name,category,price,in_stock\n"
        let csvLine = "101,550e8400-e29b-41d4-a716-446655440000,\"Product Name, Swiss Edition\",Hardware,499.99,true\n"
        let csvRepeatCount = 10 * 1024 * 1024 / csvLine.utf8.count
        for i in 1...csvRepeatCount {
            csvString += "\(i),\(UUID().uuidString),\"Prismatic Editor \(i)\",macOS,\(Double(i) * 0.99),true\n"
        }
        try! csvString.write(to: largeURL, atomically: true, encoding: .utf8)

        // 50 MB Plain Text
        let hugeURL = benchDir.appendingPathComponent("50MB.txt")
        let sampleChunk = String(repeating: "QuickPad ultra-fast native editor for macOS. Zero latency, local-first. 111iridescence.\n", count: 1000)
        let hugeFileHandle = OutputStream(url: hugeURL, append: false)!
        hugeFileHandle.open()
        let chunkData = [UInt8](sampleChunk.utf8)
        for _ in 1...(50 * 1024 * 1024 / chunkData.count) {
            _ = hugeFileHandle.write(chunkData, maxLength: chunkData.count)
        }
        hugeFileHandle.close()

        // 100 MB Plain Text
        let massiveURL = benchDir.appendingPathComponent("100MB.txt")
        let massiveHandle = OutputStream(url: massiveURL, append: false)!
        massiveHandle.open()
        for _ in 1...(100 * 1024 * 1024 / chunkData.count) {
            _ = massiveHandle.write(chunkData, maxLength: chunkData.count)
        }
        massiveHandle.close()

        print("✓ Created test fixtures:")
        for file in try! FileManager.default.contentsOfDirectory(at: benchDir, includingPropertiesForKeys: [.fileSizeKey]) {
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            print("  - \(file.lastPathComponent): \(formattedBytes(Int64(size)))")
        }

        // 2. Benchmark Document Opening & Encoding Detection
        print("\n[Phase 2] Benchmarking Document Opening & Encoding Detection...")

        let filesToTest: [(String, URL)] = [
            ("1 KB Plain Text", tinyURL),
            ("100 KB Markdown", smallURL),
            ("1 MB JSON", mediumURL),
            ("10 MB CSV", largeURL),
            ("50 MB Plain Text", hugeURL),
            ("100 MB Plain Text", massiveURL)
        ]

        for (name, url) in filesToTest {
            let t0 = CFAbsoluteTimeGetCurrent()
            let doc = try! Document.open(url: url)
            let t1 = CFAbsoluteTimeGetCurrent()
            let duration = (t1 - t0) * 1000.0
            let ram = Double(getMemoryUsage()) / 1024.0 / 1024.0

            let namePad = name.padding(toLength: 20, withPad: " ", startingAt: 0)
            print(String(format: "  • Open %@: %8.2f ms | RAM: %6.1f MB | Encoding: %@", namePad, duration, ram, doc.encodingName))
        }

        // 3. Benchmark Smart Previews
        print("\n[Phase 3] Benchmarking Smart Preview Generation...")

        // Markdown
        let mdT0 = CFAbsoluteTimeGetCurrent()
        let parsedMD = MarkdownParser.toHTML(markdown: mdContent, isDark: true)
        let mdDuration = (CFAbsoluteTimeGetCurrent() - mdT0) * 1000.0
        print(String(format: "  • Markdown GFM Parser (100 KB, 1,000 sections) : %8.2f ms (HTML: %d bytes)", mdDuration, parsedMD.utf8.count))

        // JSON
        let jsonDoc = try! Document.open(url: mediumURL)
        let jsonT0 = CFAbsoluteTimeGetCurrent()
        let parsedJSON = try! JSONSerialization.jsonObject(with: jsonDoc.content.data(using: .utf8)!, options: [])
        let jsonNode = JSONNode(key: nil, value: parsedJSON, jsonPath: "")
        let jsonDuration = (CFAbsoluteTimeGetCurrent() - jsonT0) * 1000.0
        print(String(format: "  • JSON Tree Inspector (1 MB, 10,000 items)     : %8.2f ms (Root nodes: %d)", jsonDuration, jsonNode.children.count))

        // CSV
        let csvDocTest = try! Document.open(url: largeURL)
        let csvT0 = CFAbsoluteTimeGetCurrent()
        let parsedCSV = CSVDocument.parse(text: csvDocTest.content)
        let csvDuration = (CFAbsoluteTimeGetCurrent() - csvT0) * 1000.0
        print(String(format: "  • CSV Table Parser (10 MB, %d rows)         : %8.2f ms (Columns: %d)", parsedCSV.rows.count, csvDuration, parsedCSV.headers.count))

        // 4. Benchmark Atomic Save Fidelity
        print("\n[Phase 4] Benchmarking Safe Atomic Writes...")
        let saveTestDoc = try! Document.open(url: smallURL)
        saveTestDoc.content += "\n\n<!-- QuickPad Atomic Verification -->\n"
        let saveT0 = CFAbsoluteTimeGetCurrent()
        try! saveTestDoc.save()
        let saveDuration = (CFAbsoluteTimeGetCurrent() - saveT0) * 1000.0
        print(String(format: "  • Safe Atomic Write (100 KB)                    : %8.2f ms", saveDuration))

        // 5. Benchmark Syntax Highlighting
        print("\n[Phase 5] Benchmarking Incremental Syntax Highlighting...")
        let hlStorage = NSTextStorage(string: String(repeating: "import Foundation\nclass Node {\n    let val: Int = 100\n    func run() -> Bool { return true }\n}\n", count: 1000))
        let hl = SyntaxHighlighter(language: .swift)
        let hlT0 = CFAbsoluteTimeGetCurrent()
        hl.highlight(storage: hlStorage, in: NSRange(location: 0, length: hlStorage.length))
        let hlDuration = (CFAbsoluteTimeGetCurrent() - hlT0) * 1000.0
        print(String(format: "  • Syntax Highlighting (1,000 lines Swift)       : %8.2f ms", hlDuration))

        print("\n================================================================================")
        print("  Benchmark Suite Completed Successfully")
        print("================================================================================")
    }
}
