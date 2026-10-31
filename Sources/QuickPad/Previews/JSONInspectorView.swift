import AppKit

public final class JSONNode: NSObject {
    public let key: String?
    public let value: Any
    public let jsonPath: String
    public let children: [JSONNode]
    public let isLeaf: Bool

    public init(key: String?, value: Any, jsonPath: String) {
        self.key = key
        self.value = value
        self.jsonPath = jsonPath

        if let dict = value as? [String: Any] {
            self.isLeaf = false
            // Sort keys alphabetically for clean inspection
            let sortedKeys = dict.keys.sorted()
            self.children = sortedKeys.map { k in
                let childPath = jsonPath.isEmpty ? k : "\(jsonPath).\(k)"
                return JSONNode(key: k, value: dict[k]!, jsonPath: childPath)
            }
        } else if let array = value as? [Any] {
            self.isLeaf = false
            self.children = array.enumerated().map { (idx, item) in
                let childPath = "\(jsonPath)[\(idx)]"
                return JSONNode(key: "[\(idx)]", value: item, jsonPath: childPath)
            }
        } else {
            self.isLeaf = true
            self.children = []
        }
    }

    public var displayTitle: String {
        if let key = key {
            return key
        }
        return "Root"
    }

    public var displayValue: String {
        if let dict = value as? [String: Any] {
            return "{\(dict.count) items}"
        } else if let array = value as? [Any] {
            return "[\(array.count) items]"
        } else if let str = value as? String {
            return "\"\(str)\""
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return num.boolValue ? "true" : "false"
            }
            return num.stringValue
        } else if value is NSNull {
            return "null"
        }
        return "\(value)"
    }

    public var valueColor: NSColor {
        if value is [String: Any] || value is [Any] {
            return Theme.textMuted
        } else if value is String {
            return Theme.syntaxString
        } else if let num = value as? NSNumber {
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return Theme.syntaxKeyword
            }
            return Theme.syntaxNumber
        } else if value is NSNull {
            return Theme.textMuted
        }
        return Theme.foreground
    }

    public func matches(filter: String) -> Bool {
        if filter.isEmpty { return true }
        let lower = filter.lowercased()
        if let key = key, key.lowercased().contains(lower) { return true }
        if displayValue.lowercased().contains(lower) { return true }
        return children.contains { $0.matches(filter: filter) }
    }
}

public final class JSONInspectorView: NSView, NSOutlineViewDataSource, NSOutlineViewDelegate {
    private var scrollView: NSScrollView!
    private var outlineView: NSOutlineView!
    private var searchField: NSSearchField!
    private var errorBanner: NSTextField!
    private var toolbarView: NSView!

    private var rootNode: JSONNode?
    private var filterQuery: String = ""
    private var lastRawJSON: String = ""

    public var onFormatRequested: (() -> Void)?

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

        // Toolbar
        toolbarView = NSView(frame: NSRect(x: 0, y: bounds.height - 36, width: bounds.width, height: 36))
        toolbarView.autoresizingMask = [.width, .minYMargin]
        addSubview(toolbarView)

        searchField = NSSearchField(frame: NSRect(x: 12, y: 6, width: 220, height: 24))
        searchField.placeholderString = "Filter keys and values..."
        searchField.target = self
        searchField.action = #selector(searchChanged)
        toolbarView.addSubview(searchField)

        let expandBtn = NSButton(title: "Expand All", target: self, action: #selector(expandAll))
        expandBtn.bezelStyle = .roundRect
        expandBtn.font = Theme.uiSmallFont
        expandBtn.frame = NSRect(x: 240, y: 6, width: 85, height: 24)
        toolbarView.addSubview(expandBtn)

        let collapseBtn = NSButton(title: "Collapse All", target: self, action: #selector(collapseAll))
        collapseBtn.bezelStyle = .roundRect
        collapseBtn.font = Theme.uiSmallFont
        collapseBtn.frame = NSRect(x: 330, y: 6, width: 90, height: 24)
        toolbarView.addSubview(collapseBtn)

        let formatBtn = NSButton(title: "Format JSON", target: self, action: #selector(formatAction))
        formatBtn.bezelStyle = .roundRect
        formatBtn.font = Theme.uiSmallFont
        formatBtn.frame = NSRect(x: 425, y: 6, width: 95, height: 24)
        toolbarView.addSubview(formatBtn)

        // Error banner
        errorBanner = NSTextField(frame: NSRect(x: 0, y: bounds.height - 70, width: bounds.width, height: 34))
        errorBanner.autoresizingMask = [.width, .minYMargin]
        errorBanner.isEditable = false
        errorBanner.isBordered = false
        errorBanner.backgroundColor = NSColor.systemRed.withAlphaComponent(0.15)
        errorBanner.textColor = NSColor.systemRed
        errorBanner.font = Theme.uiFont
        errorBanner.alignment = .left
        errorBanner.isHidden = true
        addSubview(errorBanner)

        // Outline view inside scrollview
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 36))
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
        outlineView.selectionHighlightStyle = .regular

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("JSONColumn"))
        col.resizingMask = .autoresizingMask
        outlineView.addTableColumn(col)
        outlineView.outlineTableColumn = col

        // Context menu for copy
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Copy Value", action: #selector(copyValueAction), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Copy JSON Path", action: #selector(copyPathAction), keyEquivalent: "p"))
        outlineView.menu = menu

        scrollView.documentView = outlineView
        addSubview(scrollView)
    }

    public func update(jsonText: String) {
        guard jsonText != lastRawJSON else { return }
        lastRawJSON = jsonText

        guard !jsonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            rootNode = nil
            errorBanner.isHidden = true
            outlineView.reloadData()
            return
        }

        guard let data = jsonText.data(using: .utf8) else {
            showError("Unable to decode UTF-8 data")
            return
        }

        do {
            let parsed = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            rootNode = JSONNode(key: nil, value: parsed, jsonPath: "")
            errorBanner.isHidden = true
            scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 36)
            outlineView.reloadData()
            // Auto-expand first level
            if let root = rootNode {
                outlineView.expandItem(root)
            }
        } catch {
            showError("Syntax Error: \(error.localizedDescription)")
        }
    }

    private func showError(_ msg: String) {
        errorBanner.stringValue = "  ⚠️ \(msg)"
        errorBanner.isHidden = false
        scrollView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 70)
    }

    @objc private func searchChanged() {
        filterQuery = searchField.stringValue.trimmingCharacters(in: .whitespaces)
        outlineView.reloadData()
        if !filterQuery.isEmpty {
            outlineView.expandItem(nil, expandChildren: true)
        }
    }

    @objc private func expandAll() {
        outlineView.expandItem(nil, expandChildren: true)
    }

    @objc private func collapseAll() {
        outlineView.collapseItem(nil, collapseChildren: true)
        if let root = rootNode {
            outlineView.expandItem(root)
        }
    }

    @objc private func formatAction() {
        onFormatRequested?()
    }

    @objc private func copyValueAction() {
        let row = outlineView.clickedRow != -1 ? outlineView.clickedRow : outlineView.selectedRow
        guard row >= 0, let node = outlineView.item(atRow: row) as? JSONNode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(node.displayValue, forType: .string)
    }

    @objc private func copyPathAction() {
        let row = outlineView.clickedRow != -1 ? outlineView.clickedRow : outlineView.selectedRow
        guard row >= 0, let node = outlineView.item(atRow: row) as? JSONNode else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(node.jsonPath, forType: .string)
    }

    // MARK: - NSOutlineViewDataSource

    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            guard let root = rootNode else { return 0 }
            if !filterQuery.isEmpty && !root.matches(filter: filterQuery) { return 0 }
            return 1
        }
        guard let node = item as? JSONNode else { return 0 }
        if filterQuery.isEmpty {
            return node.children.count
        } else {
            return node.children.filter { $0.matches(filter: filterQuery) }.count
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return rootNode!
        }
        let node = item as! JSONNode
        if filterQuery.isEmpty {
            return node.children[index]
        } else {
            let filtered = node.children.filter { $0.matches(filter: filterQuery) }
            return filtered[index]
        }
    }

    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? JSONNode else { return false }
        return !node.isLeaf
    }

    // MARK: - NSOutlineViewDelegate

    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? JSONNode else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("JSONCell")
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
        // Key
        let keyAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: Theme.syntaxKeyword,
            .font: Theme.editorFont
        ]
        attrStr.append(NSAttributedString(string: "\(node.displayTitle): ", attributes: keyAttrs))

        // Value
        let valAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: node.valueColor,
            .font: Theme.editorFont
        ]
        attrStr.append(NSAttributedString(string: node.displayValue, attributes: valAttrs))

        cellView?.textField?.attributedStringValue = attrStr
        return cellView
    }
}
