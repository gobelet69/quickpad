import AppKit

public protocol FindBarDelegate: AnyObject {
    func findNext(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool)
    func findPrevious(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool)
    func replaceCurrent(with replacement: String)
    func replaceAll(query: String, replacement: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool)
    func closeFindBar()
}

public final class FindBarView: NSView, NSTextFieldDelegate {
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

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Theme.surface.cgColor

        // Top line: Find row
        let findLabel = NSTextField(labelWithString: "Find:")
        findLabel.font = Theme.uiFont
        findLabel.textColor = Theme.textMuted
        findLabel.frame = NSRect(x: 12, y: 38, width: 40, height: 20)
        addSubview(findLabel)

        findField = NSTextField(frame: NSRect(x: 55, y: 36, width: 220, height: 24))
        findField.font = Theme.uiFont
        findField.delegate = self
        findField.target = self
        findField.action = #selector(findFieldSubmitted)
        addSubview(findField)

        let prevBtn = NSButton(title: "◀", target: self, action: #selector(prevClicked))
        prevBtn.bezelStyle = .roundRect
        prevBtn.frame = NSRect(x: 280, y: 36, width: 32, height: 24)
        addSubview(prevBtn)

        let nextBtn = NSButton(title: "▶", target: self, action: #selector(nextClicked))
        nextBtn.bezelStyle = .roundRect
        nextBtn.frame = NSRect(x: 316, y: 36, width: 32, height: 24)
        addSubview(nextBtn)

        countLabel = NSTextField(labelWithString: "")
        countLabel.font = Theme.uiSmallFont
        countLabel.textColor = Theme.textMuted
        countLabel.frame = NSRect(x: 355, y: 38, width: 100, height: 20)
        addSubview(countLabel)

        caseCheckbox = NSButton(checkboxWithTitle: "Aa", target: self, action: #selector(optionChanged))
        caseCheckbox.toolTip = "Match Case"
        caseCheckbox.font = Theme.uiSmallFont
        caseCheckbox.frame = NSRect(x: 460, y: 38, width: 45, height: 20)
        addSubview(caseCheckbox)

        wordCheckbox = NSButton(checkboxWithTitle: "Word", target: self, action: #selector(optionChanged))
        wordCheckbox.toolTip = "Match Whole Word"
        wordCheckbox.font = Theme.uiSmallFont
        wordCheckbox.frame = NSRect(x: 510, y: 38, width: 60, height: 20)
        addSubview(wordCheckbox)

        regexCheckbox = NSButton(checkboxWithTitle: ".*", target: self, action: #selector(optionChanged))
        regexCheckbox.toolTip = "Regular Expression"
        regexCheckbox.font = Theme.uiSmallFont
        regexCheckbox.frame = NSRect(x: 575, y: 38, width: 45, height: 20)
        addSubview(regexCheckbox)

        let closeBtn = NSButton(title: "✕", target: self, action: #selector(closeClicked))
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = Theme.uiBoldFont
        closeBtn.frame = NSRect(x: bounds.width - 28, y: 38, width: 20, height: 20)
        closeBtn.autoresizingMask = [.minXMargin]
        addSubview(closeBtn)

        // Bottom line: Replace row
        let replaceLabel = NSTextField(labelWithString: "Replace:")
        replaceLabel.font = Theme.uiFont
        replaceLabel.textColor = Theme.textMuted
        replaceLabel.frame = NSRect(x: 12, y: 8, width: 55, height: 20)
        addSubview(replaceLabel)

        replaceField = NSTextField(frame: NSRect(x: 70, y: 6, width: 205, height: 24))
        replaceField.font = Theme.uiFont
        addSubview(replaceField)

        let replaceBtn = NSButton(title: "Replace", target: self, action: #selector(replaceClicked))
        replaceBtn.bezelStyle = .roundRect
        replaceBtn.font = Theme.uiSmallFont
        replaceBtn.frame = NSRect(x: 280, y: 6, width: 70, height: 24)
        addSubview(replaceBtn)

        let replaceAllBtn = NSButton(title: "All", target: self, action: #selector(replaceAllClicked))
        replaceAllBtn.bezelStyle = .roundRect
        replaceAllBtn.font = Theme.uiSmallFont
        replaceAllBtn.frame = NSRect(x: 355, y: 6, width: 50, height: 24)
        addSubview(replaceAllBtn)
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
        path.move(to: NSPoint(x: 0, y: 0.5))
        path.line(to: NSPoint(x: bounds.width, y: 0.5))
        path.lineWidth = 1.0
        path.stroke()
    }
}
