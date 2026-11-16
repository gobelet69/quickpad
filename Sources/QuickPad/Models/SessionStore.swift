import Foundation

/// Recovery copies are separate from the user's documents and are replaced atomically.
struct SessionStore {
    struct Entry: Codable {
        var path: String?
        var content: String
        var savedContent: String
        var encoding: UInt
        var encodingName: String
        var hasBOM: Bool
        var lineEnding: String
        var language: String
        var isBinary: Bool
        var previewMode: String
    }
    struct Session: Codable {
        var entries: [Entry]
        var activeIndex: Int
    }

    let url: URL
    static var standard: SessionStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SessionStore(url: base.appendingPathComponent("QuickPad/session.json"))
    }

    func save(documents: [Document], activeIndex: Int) throws {
        let entries = documents.map { doc in
            Entry(path: doc.fileURL?.path, content: doc.content, savedContent: doc.savedContent,
                  encoding: doc.encoding.rawValue, encodingName: doc.encodingName, hasBOM: doc.hasBOM,
                  lineEnding: doc.lineEnding.rawValue, language: doc.language.rawValue,
                  isBinary: doc.isBinary, previewMode: doc.previewMode.rawValue)
        }
        let data = try JSONEncoder().encode(Session(entries: entries, activeIndex: activeIndex))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    func load() throws -> (documents: [Document], activeIndex: Int)? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let session = try JSONDecoder().decode(Session.self, from: Data(contentsOf: url))
        let documents = session.entries.map { entry -> Document in
            let url = entry.path.map { URL(fileURLWithPath: $0) }
            // Clean files should reflect current disk contents; dirty or missing files use the recovery copy.
            if entry.content == entry.savedContent, let url = url, let disk = try? Document.open(url: url) {
                disk.previewMode = PreviewMode(rawValue: entry.previewMode) ?? disk.previewMode
                return disk
            }
            let doc = Document(fileURL: url, content: entry.savedContent,
                encoding: String.Encoding(rawValue: entry.encoding), encodingName: entry.encodingName,
                hasBOM: entry.hasBOM, lineEnding: LineEnding(rawValue: entry.lineEnding) ?? .lf,
                language: Language(rawValue: entry.language) ?? .plainText, isBinary: entry.isBinary)
            doc.content = entry.content
            if entry.content != entry.savedContent, let url = url {
                doc.recoveryDiskConflict = (try? Document.open(url: url).content) != entry.savedContent
            }
            doc.previewMode = PreviewMode(rawValue: entry.previewMode) ?? .source
            return doc
        }
        return (documents, min(max(0, session.activeIndex), max(0, documents.count - 1)))
    }
}
