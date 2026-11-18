import AppKit

public protocol FindBarDelegate: AnyObject {
    func findNext(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool)
    func findPrevious(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool)
    func replaceCurrent(with replacement: String)
    func replaceAll(query: String, replacement: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool)
    func closeFindBar()
}

public final class FindBarView: ThemeBackgroundView, NSTextFieldDelegate {
    public weak var delegate: FindBarDelegate?

    private var findField: NSTextField!
    private var replaceField: NSTextField!
    private var countLabel: NSTextField!

    private var caseCheckbox: NSButton!
    private var wordCheckbox: NSButton!
    private var regexCheckbox: NSButton!

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private let rows = NSStackView()
    public override var isFlipped: Bool { true }
    public override var themeBackgroundColor: NSColor { Theme.surface }
    public var preferredHeight: CGFloat { rows.fittingSize.height + 16 }

    private func setupUI() {
        wantsLayer = true
        findField = NSTextField()
        findField.placeholderString = "Find"
        findField.setAccessibilityLabel("Find")
        findField.font = Theme.uiFont
        findField.delegate = self
        findField.target = self
        findField.action = #selector(findFieldSubmitted)
        replaceField = NSTextField()
        replaceField.placeholderString = "Replace"
        replaceField.setAccessibilityLabel("Replace with")
        replaceField.font = Theme.uiFont
        replaceField.delegate = self

        func iconButton(_ symbol: String, _ name: String, _ action: Selector) -> NSButton {
            let button = NSButton(title: "", target: self, action: action)
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: name)
            button.bezelStyle = .rounded
            button.toolTip = name
            button.setAccessibilityLabel(name)
            button.widthAnchor.constraint(equalToConstant: 28).isActive = true
            return button
        }
        let previous = iconButton("chevron.left", "Previous Match", #selector(prevClicked))
        let next = iconButton("chevron.right", "Next Match", #selector(nextClicked))
        let close = iconButton("xmark", "Close Find", #selector(closeClicked))
        let replace = NSButton(title: "Replace", target: self, action: #selector(replaceClicked))
        let replaceAll = NSButton(title: "All", target: self, action: #selector(replaceAllClicked))
        replaceAll.setAccessibilityLabel("Replace All")
        replaceAll.toolTip = "Replace All"
        for button in [replace, replaceAll] { button.bezelStyle = .rounded; button.font = Theme.uiSmallFont }

        countLabel = NSTextField(labelWithString: "")
        countLabel.font = Theme.uiSmallFont
        countLabel.textColor = Theme.textMuted
        countLabel.lineBreakMode = .byTruncatingTail
        countLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        caseCheckbox = NSButton(checkboxWithTitle: "Aa", target: self, action: #selector(optionChanged))
        wordCheckbox = NSButton(checkboxWithTitle: "Word", target: self, action: #selector(optionChanged))
        regexCheckbox = NSButton(checkboxWithTitle: "Regex", target: self, action: #selector(optionChanged))
        for (button, name) in [(caseCheckbox!, "Match Case"), (wordCheckbox!, "Match Whole Word"), (regexCheckbox!, "Regular Expression")] {
            button.font = Theme.uiSmallFont
            button.toolTip = name
            button.setAccessibilityLabel(name)
        }
        rows.orientation = .vertical
        rows.spacing = 8
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rows)
        for controls in [[findField!, previous, next, close], [replaceField!, replace, replaceAll], [caseCheckbox!, wordCheckbox!, regexCheckbox!, countLabel!]] {
            let row = NSStackView(views: controls)
            row.orientation = .horizontal
            row.alignment = .centerY
            row.spacing = 4
            rows.addArrangedSubview(row)
            row.widthAnchor.constraint(equalTo: rows.widthAnchor).isActive = true
            row.heightAnchor.constraint(equalToConstant: 24).isActive = true
        }
        for field in [findField!, replaceField!] {
            field.setContentHuggingPriority(.defaultLow, for: .horizontal)
            field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            rows.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rows.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        ])
    }

    public func focusFind() {
        window?.makeFirstResponder(findField)
        findField.selectText(nil)
    }

    public func updateMatchCount(current: Int, total: Int) {
        if total == 0 {
            countLabel.stringValue = findField.stringValue.isEmpty ? "" : "No results"
        } else {
            countLabel.stringValue = "\(current) of \(total)"
        }
    }

    @objc private func findFieldSubmitted() {
        nextClicked()
    }

    @objc private func nextClicked() {
        delegate?.findNext(
            query: findField.stringValue,
            matchCase: caseCheckbox.state == .on,
            wholeWord: wordCheckbox.state == .on,
            isRegex: regexCheckbox.state == .on
        )
    }

    @objc private func prevClicked() {
        delegate?.findPrevious(
            query: findField.stringValue,
            matchCase: caseCheckbox.state == .on,
            wholeWord: wordCheckbox.state == .on,
            isRegex: regexCheckbox.state == .on
        )
    }

    @objc private func replaceClicked() {
        delegate?.replaceCurrent(with: replaceField.stringValue)
        nextClicked()
    }

    @objc private func replaceAllClicked() {
        delegate?.replaceAll(
            query: findField.stringValue,
            replacement: replaceField.stringValue,
            matchCase: caseCheckbox.state == .on,
            wholeWord: wordCheckbox.state == .on,
            isRegex: regexCheckbox.state == .on
        )
    }

    @objc private func optionChanged() {
        nextClicked()
    }

    @objc private func closeClicked() {
        delegate?.closeFindBar()
    }

    public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            closeClicked()
            return true
        }
        return false
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Bottom border
        Theme.border.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: bounds.maxY - 0.5))
        path.line(to: NSPoint(x: bounds.width, y: bounds.maxY - 0.5))
        path.lineWidth = 1.0
        path.stroke()
    }
}
