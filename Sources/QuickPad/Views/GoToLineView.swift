import AppKit

public protocol GoToLineDelegate: AnyObject {
    func jumpTo(line: Int)
    func closeGoToLine()
}

public final class GoToLineView: NSView, NSTextFieldDelegate {
    public weak var delegate: GoToLineDelegate?
    private var inputField: NSTextField!

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

        let label = NSTextField(labelWithString: "Go to Line:")
        label.font = Theme.uiFont
        label.textColor = Theme.textMuted
        label.frame = NSRect(x: 12, y: 7, width: 80, height: 20)
        addSubview(label)

        inputField = NSTextField(frame: NSRect(x: 95, y: 5, width: 100, height: 24))
        inputField.font = Theme.uiFont
        inputField.placeholderString = "Line number"
        inputField.delegate = self
        inputField.target = self
        inputField.action = #selector(goClicked)
        addSubview(inputField)

        let goBtn = NSButton(title: "Go", target: self, action: #selector(goClicked))
        goBtn.bezelStyle = .roundRect
        goBtn.font = Theme.uiSmallFont
        goBtn.frame = NSRect(x: 205, y: 5, width: 50, height: 24)
        addSubview(goBtn)

        let closeBtn = NSButton(title: "✕", target: self, action: #selector(closeClicked))
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = Theme.uiBoldFont
        closeBtn.frame = NSRect(x: 265, y: 7, width: 20, height: 20)
        addSubview(closeBtn)
    }

    public func focus() {
        inputField.stringValue = ""
        window?.makeFirstResponder(inputField)
    }

    @objc private func goClicked() {
        if let line = Int(inputField.stringValue.trimmingCharacters(in: .whitespaces)), line > 0 {
            delegate?.jumpTo(line: line)
        }
        delegate?.closeGoToLine()
    }

    @objc private func closeClicked() {
        delegate?.closeGoToLine()
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
        Theme.border.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: 0.5))
        path.line(to: NSPoint(x: bounds.width, y: 0.5))
        path.lineWidth = 1.0
        path.stroke()
    }
}
