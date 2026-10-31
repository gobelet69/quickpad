import AppKit

public protocol StatusBarDelegate: AnyObject {
    func previewModeChanged(to mode: PreviewMode)
}

public final class StatusBarView: NSView {
    public weak var delegate: StatusBarDelegate?

    private var cursorLabel: NSTextField!
    private var statsLabel: NSTextField!
    private var encodingLabel: NSTextField!
    private var lineEndingLabel: NSTextField!
    private var languageLabel: NSTextField!
    private var previewSegment: NSSegmentedControl!

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
        layer?.backgroundColor = Theme.gutterBackground.cgColor

        // Left items: Cursor & stats
        cursorLabel = NSTextField(labelWithString: "Ln 1, Col 1")
        cursorLabel.font = Theme.uiSmallFont
        cursorLabel.textColor = Theme.textMuted
        cursorLabel.frame = NSRect(x: 14, y: 3, width: 140, height: 18)
        addSubview(cursorLabel)

        statsLabel = NSTextField(labelWithString: "")
        statsLabel.font = Theme.uiSmallFont
        statsLabel.textColor = Theme.textMuted
        statsLabel.frame = NSRect(x: 160, y: 3, width: 220, height: 18)
        addSubview(statsLabel)

        // Right items
        let rightStack = NSStackView()
        rightStack.orientation = .horizontal
        rightStack.spacing = 16
        rightStack.alignment = .centerY
        rightStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightStack)

        languageLabel = NSTextField(labelWithString: "Plain Text")
        languageLabel.font = Theme.uiSmallFont
        languageLabel.textColor = Theme.textMuted
        rightStack.addArrangedSubview(languageLabel)

        encodingLabel = NSTextField(labelWithString: "UTF-8")
        encodingLabel.font = Theme.uiSmallFont
        encodingLabel.textColor = Theme.textMuted
        rightStack.addArrangedSubview(encodingLabel)

        lineEndingLabel = NSTextField(labelWithString: "LF")
        lineEndingLabel.font = Theme.uiSmallFont
        lineEndingLabel.textColor = Theme.textMuted
        rightStack.addArrangedSubview(lineEndingLabel)

        previewSegment = NSSegmentedControl(labels: ["Source", "Split", "Preview"], trackingMode: .selectOne, target: self, action: #selector(segmentChanged))
        previewSegment.selectedSegment = 0
        previewSegment.font = Theme.uiSmallFont
        rightStack.addArrangedSubview(previewSegment)

        NSLayoutConstraint.activate([
            rightStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            rightStack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public func update(document: Document, line: Int, col: Int, selectionLength: Int) {
        if selectionLength > 0 {
            cursorLabel.stringValue = "Ln \(line), Col \(col) (\(selectionLength) sel)"
        } else {
            cursorLabel.stringValue = "Ln \(line), Col \(col)"
        }

        let totalLines = document.content.reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
        let charCount = document.content.count
        statsLabel.stringValue = "\(totalLines) lines, \(charCount) chars"

        languageLabel.stringValue = document.language.rawValue
        encodingLabel.stringValue = document.encodingName
        lineEndingLabel.stringValue = document.lineEnding.displayName

        if document.language.hasPreview && !document.isBinary {
            previewSegment.isEnabled = true
            switch document.previewMode {
            case .source: previewSegment.selectedSegment = 0
            case .split: previewSegment.selectedSegment = 1
            case .preview: previewSegment.selectedSegment = 2
            }
        } else {
            previewSegment.isEnabled = false
            previewSegment.selectedSegment = 0
        }
    }

    @objc private func segmentChanged() {
        let mode: PreviewMode
        switch previewSegment.selectedSegment {
        case 0: mode = .source
        case 1: mode = .split
        case 2: mode = .preview
        default: mode = .source
        }
        delegate?.previewModeChanged(to: mode)
    }

    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Top border
        Theme.border.setStroke()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 0, y: bounds.height - 0.5))
        path.line(to: NSPoint(x: bounds.width, y: bounds.height - 0.5))
        path.lineWidth = 1.0
        path.stroke()
    }
}
