import AppKit

public enum PreviewMode: String, CaseIterable, Sendable {
    case source = "Source"
    case split = "Split"
    case preview = "Preview"
}

public final class Document {
    public let id: UUID = UUID()
    public var fileURL: URL?
    public var content: String {
        didSet {
            markModified()
        }
    }
    public private(set) var savedContent: String
    public private(set) var isModified: Bool = false

    public var encoding: String.Encoding
    public var encodingName: String
    public var hasBOM: Bool
    public var lineEnding: LineEnding
    public var language: Language
    public var isBinary: Bool
    public var previewMode: PreviewMode = .source

    public var cursorPosition: Int = 0
    public var scrollOffset: NSPoint = .zero
    public var cachedTextStorage: NSTextStorage?
    public private(set) var fileModificationDate: Date?

    public init(
        fileURL: URL? = nil,
        content: String = "",
        encoding: String.Encoding = .utf8,
        encodingName: String = "UTF-8",
        hasBOM: Bool = false,
        lineEnding: LineEnding = .lf,
        language: Language = .plainText,
        isBinary: Bool = false
    ) {
        self.fileURL = fileURL
        self.content = content
        self.savedContent = content
        self.encoding = encoding
        self.encodingName = encodingName
        self.hasBOM = hasBOM
        self.lineEnding = lineEnding
        self.language = language
        self.isBinary = isBinary

        if let fileURL = fileURL {
            self.fileModificationDate = Self.modificationDate(for: fileURL)
        }
    }

    public var displayName: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }

    public var title: String {
        isModified ? "\(displayName) •" : displayName
    }

    public func markModified() {
        isModified = content != savedContent
    }

    public func markSaved() {
        savedContent = content
        isModified = false
        if let fileURL = fileURL {
            fileModificationDate = Self.modificationDate(for: fileURL)
        }
    }

    public static func open(url: URL) throws -> Document {
        let data = try Data(contentsOf: url)
        let result = FileEncodingDetector.detect(data: data)
        let lineEnding = LineEnding.detect(in: result.text)
        let language = Language.detect(for: url)

        let doc = Document(
            fileURL: url,
            content: result.text,
            encoding: result.encoding,
            encodingName: result.encodingName,
            hasBOM: result.hasBOM,
            lineEnding: lineEnding,
            language: language,
            isBinary: result.isBinary
        )
        // If file supports preview by default, we can initialize mode according to format or keep source
        return doc
    }

    public func reload() throws {
        guard let url = fileURL else { return }
        let data = try Data(contentsOf: url)
        let result = FileEncodingDetector.detect(data: data)
        self.content = result.text
        self.encoding = result.encoding
        self.encodingName = result.encodingName
        self.hasBOM = result.hasBOM
        self.lineEnding = LineEnding.detect(in: result.text)
        self.isBinary = result.isBinary
        self.savedContent = result.text
        self.isModified = false
        self.fileModificationDate = Self.modificationDate(for: url)
    }

    public func checkExternalModification() -> Bool {
        guard let url = fileURL, let lastKnown = fileModificationDate else { return false }
        guard let currentMod = Self.modificationDate(for: url) else { return false }
        return currentMod > lastKnown
    }

    public func save() throws {
        guard let url = fileURL else {
            throw NSError(domain: "QuickPad", code: 400, userInfo: [NSLocalizedDescriptionKey: "No file URL specified for save"])
        }
        guard !isBinary else {
            throw NSError(domain: "QuickPad", code: 403, userInfo: [NSLocalizedDescriptionKey: "Saving binary files is prevented to avoid file corruption"])
        }

        // Apply line ending normalization if needed
        let textToWrite = lineEnding.normalize(text: content)

        guard let data = FileEncodingDetector.data(for: textToWrite, encoding: encoding, hasBOM: hasBOM) else {
            throw NSError(domain: "QuickPad", code: 422, userInfo: [NSLocalizedDescriptionKey: "Failed to encode document in \(encodingName)"])
        }

        // Safe atomic write
        try data.write(to: url, options: .atomic)
        markSaved()
    }

    public func save(to url: URL, encoding: String.Encoding? = nil) throws {
        self.fileURL = url
        self.language = Language.detect(for: url)
        if let enc = encoding {
            self.encoding = enc
            self.encodingName = enc == .utf8 ? (hasBOM ? "UTF-8 with BOM" : "UTF-8") : "Custom"
        }
        try save()
    }

    private static func modificationDate(for url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
    }
}
