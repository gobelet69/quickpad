import AppKit

public final class StructuredNode: NSObject {
    public let title: String
    public let detail: String?
    public let children: [StructuredNode]
    public let isLeaf: Bool

    public init(title: String, detail: String? = nil, children: [StructuredNode] = []) {
        self.title = title
        self.detail = detail
        self.children = children
        self.isLeaf = children.isEmpty
    }
}

// MARK: - Safe XML Parser Delegate
final class SafeXMLTreeParser: NSObject, XMLParserDelegate {
    var rootNodes: [StructuredNode] = []
    private var nodeStack: [([StructuredNode], String, [String: String], String)] = []
    private var currentText = ""
    var parseError: Error?

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        nodeStack.append(([], elementName, attributeDict, ""))
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText.append(string)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        guard let popped = nodeStack.popLast() else { return }
        let trimmedText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        var childNodes = popped.0
        // Add attributes as child items if present
        for (k, v) in popped.2 {
            childNodes.insert(StructuredNode(title: "@\(k)", detail: "\"\(v)\""), at: 0)
        }

        let detailStr = trimmedText.isEmpty ? (childNodes.isEmpty ? nil : "<\(childNodes.count) items>") : trimmedText
        let newNode = StructuredNode(title: "<" + popped.1 + ">", detail: detailStr, children: childNodes)

        if nodeStack.isEmpty {
            rootNodes.append(newNode)
        } else {
            var top = nodeStack.removeLast()
            top.0.append(newNode)
            nodeStack.append(top)
        }
        currentText = ""
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}

public final class StructuredTreePreviewView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private var scrollView: NSScrollView!
    private var outlineView: NSOutlineView!
    private var formatLabel: NSTextField!
    private var errorBanner: NSTextField!

    private var rootNodes: [StructuredNode] = []
    private var lastRawText: String = ""

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Theme.background.cgColor

        // Header bar
        formatLabel = NSTextField(frame: NSRect(x: 16, y: bounds.height - 28, width: bounds.width - 32, height: 20))
        formatLabel.autoresizingMask = [.width, .minYMargin]
        formatLabel.isEditable = false
        formatLabel.isBordered = false
        formatLabel.drawsBackground = false
        formatLabel.textColor = Theme.textMuted
        formatLabel.font = Theme.uiSmallFont
        addSubview(formatLabel)

        // Error banner
        errorBanner = NSTextField(frame: NSRect(x: 0, y: bounds.height - 64, width: bounds.width, height: 32))
        errorBanner.autoresizingMask = [.width, .minYMargin]
        errorBanner.isEditable = false
        errorBanner.isBordered = false
        errorBanner.backgroundColor = NSColor.systemRed.withAlphaComponent(0.15)
        errorBanner.textColor = NSColor.systemRed
        errorBanner.font = Theme.uiFont
        errorBanner.isHidden = true
        addSubview(errorBanner)

        // Outline view
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 32))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        outlineView = NSOutlineView(frame: scrollView.bounds)
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.headerView = nil
        outlineView.rowHeight = 24
        outlineView.backgroundColor = Theme.background

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("StructuredCol"))
        col.resizingMask = .autoresizingMask
        outlineView.addTableColumn(col)
        outlineView.outlineTableColumn = col

        scrollView.documentView = outlineView
        addSubview(scrollView)
    }

    public func update(text: String, format: StructuredFormat) {
        guard text != lastRawText else { return }
        lastRawText = text
        formatLabel.stringValue = "\(format.rawValue) Structure Inspector"

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            rootNodes = []
            errorBanner.isHidden = true
            outlineView.reloadData()
            return
        }

        switch format {
        case .xml:
            parseXML(text: text)
        case .yaml:
            parseYAML(text: text)
        case .toml:
            parseTOML(text: text)
        }
    }

    private func parseXML(text: String) {
        guard let data = text.data(using: .utf8) else {
            showError("Unable to decode UTF-8 data")
            return
        }
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false // Strict security
        let delegate = SafeXMLTreeParser()
        parser.delegate = delegate

        if parser.parse() {
            rootNodes = delegate.rootNodes
            errorBanner.isHidden = true
            scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 32)
            outlineView.reloadData()
            outlineView.expandItem(nil, expandChildren: true)
        } else if let err = delegate.parseError {
            showError("XML Parse Error at line \(parser.lineNumber): \(err.localizedDescription)")
        } else {
            showError("XML Parse Error at line \(parser.lineNumber)")
        }
    }

    private func parseYAML(text: String) {
        // Fast line-based indent parser for YAML tree
        var stack: [(indent: Int, node: StructuredNode, children: [StructuredNode])] = []
        var roots: [StructuredNode] = []

        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            let indent = line.prefix { $0 == " " || $0 == "\t" }.count
            let parts = trimmed.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let val = parts.count > 1 ? String(parts[1]).trimmingCharacters(in: .whitespaces) : nil

            let node = StructuredNode(title: key, detail: val?.isEmpty == true ? nil : val)

            while let last = stack.last, last.indent >= indent {
                let finished = stack.removeLast()
                let completedNode = StructuredNode(title: finished.node.title, detail: finished.node.detail, children: finished.children)
                if var parent = stack.popLast() {
                    parent.children.append(completedNode)
                    stack.append(parent)
                } else {
                    roots.append(completedNode)
                }
            }

            stack.append((indent: indent, node: node, children: []))
        }

        while !stack.isEmpty {
            let finished = stack.removeLast()
            let completedNode = StructuredNode(title: finished.node.title, detail: finished.node.detail, children: finished.children)
            if var parent = stack.popLast() {
                parent.children.append(completedNode)
                stack.append(parent)
            } else {
                roots.append(completedNode)
            }
        }

        self.rootNodes = roots
        errorBanner.isHidden = true
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 32)
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }

    private func parseTOML(text: String) {
        var sections: [String: [StructuredNode]] = [:]
        var currentSection = "General"
        sections[currentSection] = []

        let lines = text.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                let sectionName = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                currentSection = sectionName
                if sections[currentSection] == nil { sections[currentSection] = [] }
                continue
            }

            let parts = trimmed.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count == 2 {
                let k = String(parts[0]).trimmingCharacters(in: .whitespaces)
                let v = String(parts[1]).trimmingCharacters(in: .whitespaces)
                sections[currentSection]?.append(StructuredNode(title: k, detail: v))
            }
        }

        var roots: [StructuredNode] = []
        for (sec, items) in sections.sorted(by: { $0.key < $1.key }) {
            roots.append(StructuredNode(title: "[\(sec)]", detail: "(\(items.count) entries)", children: items))
        }

        self.rootNodes = roots
        errorBanner.isHidden = true
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 32)
        outlineView.reloadData()
        outlineView.expandItem(nil, expandChildren: true)
    }

    private func showError(_ msg: String) {
        errorBanner.stringValue = "  ⚠️ \(msg)"
        errorBanner.isHidden = false
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 64)
    }

    // MARK: - NSOutlineViewDataSource

    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return rootNodes.count
        }
        guard let node = item as? StructuredNode else { return 0 }
        return node.children.count
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return rootNodes[index]
        }
        let node = item as! StructuredNode
        return node.children[index]
    }

    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? StructuredNode else { return false }
        return !node.isLeaf
    }

    // MARK: - NSOutlineViewDelegate

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? StructuredNode else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("StructuredCell")
        var cellView = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
        if cellView == nil {
            cellView = NSTableCellView()
            cellView?.identifier = identifier

            let textField = NSTextField(labelWithString: "")
            textField.font = Theme.editorFont
            textField.isEditable = false
            textField.isBordered = false
            textField.drawsBackground = false
            textField.translatesAutoresizingMaskIntoConstraints = false

            cellView?.addSubview(textField)
            cellView?.textField = textField

            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 4),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -4),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        let attrStr = NSMutableAttributedString()
        attrStr.append(NSAttributedString(string: node.title, attributes: [
            .foregroundColor: Theme.syntaxKeyword,
            .font: Theme.editorFont
        ]))

        if let detail = node.detail {
            attrStr.append(NSAttributedString(string: ": \(detail)", attributes: [
                .foregroundColor: Theme.syntaxString,
                .font: Theme.editorFont
            ]))
        }

        cellView?.textField?.attributedStringValue = attrStr
        return cellView
    }
}
