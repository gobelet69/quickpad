import AppKit

public struct CSVDocument: Sendable {
    public let headers: [String]
    public let rows: [[String]]

    public static func parse(text: String, delimiter: Character = ",") -> CSVDocument {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        let chars = Array(text)
        var i = 0
        let len = chars.count

        while i < len {
            let ch = chars[i]

            if inQuotes {
                if ch == "\"" {
                    if i + 1 < len && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 1 // Skip escaped quote
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(ch)
                }
            } else {
                if ch == "\"" {
                    inQuotes = true
                } else if ch == delimiter {
                    currentRow.append(currentField)
                    currentField = ""
                } else if ch == "\r" {
                    if i + 1 < len && chars[i + 1] == "\n" {
                        i += 1
                    }
                    currentRow.append(currentField)
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else if ch == "\n" {
                    currentRow.append(currentField)
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else {
                    currentField.append(ch)
                }
            }
            i += 1
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                rows.append(currentRow)
            }
        }

        guard !rows.isEmpty else {
            return CSVDocument(headers: [], rows: [])
        }

        let headers = rows[0]
        let dataRows = Array(rows.dropFirst())
        return CSVDocument(headers: headers, rows: dataRows)
    }
}

public final class CSVTableView: NSView, NSTableViewDataSource, NSTableViewDelegate {
    private var scrollView: NSScrollView!
    private var tableView: NSTableView!
    private var infoLabel: NSTextField!

    private var parsedCSV: CSVDocument?
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

        // Info bar
        infoLabel = NSTextField(frame: NSRect(x: 16, y: bounds.height - 28, width: bounds.width - 32, height: 20))
        infoLabel.autoresizingMask = [.width, .minYMargin]
        infoLabel.isEditable = false
        infoLabel.isBordered = false
        infoLabel.drawsBackground = false
        infoLabel.textColor = Theme.textMuted
        infoLabel.font = Theme.uiSmallFont
        addSubview(infoLabel)

        // Scrollview and TableView
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 32))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        tableView = NSTableView(frame: scrollView.bounds)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 24
        tableView.gridStyleMask = [.solidVerticalGridLineMask, .solidHorizontalGridLineMask]
        tableView.backgroundColor = Theme.background

        // Copy menu
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Copy Cell", action: #selector(copyCellAction), keyEquivalent: "c"))
        menu.addItem(NSMenuItem(title: "Copy Row", action: #selector(copyRowAction), keyEquivalent: "r"))
        tableView.menu = menu

        scrollView.documentView = tableView
        addSubview(scrollView)
    }

    public func update(csvText: String, isTSV: Bool) {
        guard csvText != lastRawText else { return }
        lastRawText = csvText

        let delimiter: Character = isTSV ? "\t" : (csvText.contains(";") && !csvText.contains(",") ? ";" : ",")
        let parsed = CSVDocument.parse(text: csvText, delimiter: delimiter)
        self.parsedCSV = parsed

        // Remove old columns
        while let col = tableView.tableColumns.first {
            tableView.removeTableColumn(col)
        }

        // Add index column
        let indexCol = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("#"))
        indexCol.title = "#"
        indexCol.width = 45
        indexCol.minWidth = 35
        tableView.addTableColumn(indexCol)

        // Add headers
        for (i, header) in parsed.headers.enumerated() {
            let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("col_\(i)"))
            col.title = header.isEmpty ? "Col \(i + 1)" : header
            col.width = max(100, min(240, CGFloat(col.title.count * 10 + 30)))
            col.resizingMask = [.userResizingMask, .autoresizingMask]
            tableView.addTableColumn(col)
        }

        infoLabel.stringValue = "\(parsed.rows.count) rows, \(parsed.headers.count) columns (Delimiter: '\(delimiter)')"
        tableView.reloadData()
    }

    @objc private func copyCellAction() {
        let row = tableView.clickedRow != -1 ? tableView.clickedRow : tableView.selectedRow
        let col = tableView.clickedColumn != -1 ? tableView.clickedColumn : tableView.selectedColumn
        guard let parsed = parsedCSV, row >= 0, row < parsed.rows.count else { return }
        if col == 0 {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("\(row + 1)", forType: .string)
            return
        }
        let dataCol = col - 1
        if dataCol >= 0, dataCol < parsed.rows[row].count {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(parsed.rows[row][dataCol], forType: .string)
        }
    }

    @objc private func copyRowAction() {
        let row = tableView.clickedRow != -1 ? tableView.clickedRow : tableView.selectedRow
        guard let parsed = parsedCSV, row >= 0, row < parsed.rows.count else { return }
        let rowText = parsed.rows[row].joined(separator: "\t")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(rowText, forType: .string)
    }

    // MARK: - NSTableViewDataSource

    public func numberOfRows(in tableView: NSTableView) -> Int {
        return parsedCSV?.rows.count ?? 0
    }

    // MARK: - NSTableViewDelegate

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let parsed = parsedCSV, row < parsed.rows.count else { return nil }
        guard let colIdentifier = tableColumn?.identifier.rawValue else { return nil }

        let identifier = NSUserInterfaceItemIdentifier("CSVCell")
        var cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView
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
                textField.leadingAnchor.constraint(equalTo: cellView!.leadingAnchor, constant: 6),
                textField.trailingAnchor.constraint(equalTo: cellView!.trailingAnchor, constant: -6),
                textField.centerYAnchor.constraint(equalTo: cellView!.centerYAnchor)
            ])
        }

        if colIdentifier == "#" {
            cellView?.textField?.stringValue = "\(row + 1)"
            cellView?.textField?.textColor = Theme.textMuted
            cellView?.textField?.alignment = .right
        } else if colIdentifier.hasPrefix("col_") {
            let colIndexStr = colIdentifier.dropFirst(4)
            if let colIndex = Int(colIndexStr), colIndex < parsed.rows[row].count {
                cellView?.textField?.stringValue = parsed.rows[row][colIndex]
                cellView?.textField?.textColor = Theme.foreground
                cellView?.textField?.alignment = .left
            } else {
                cellView?.textField?.stringValue = ""
            }
        }

        return cellView
    }
}
