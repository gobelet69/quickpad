import AppKit

public protocol TabBarDelegate: AnyObject {
    func tabSelected(at index: Int)
    func tabClosed(at index: Int)
    func newTabRequested()
}

public final class TabBarView: NSView {
    public weak var delegate: TabBarDelegate?

    private var scrollView: NSScrollView!
    private var tabsContainer: NSView!
    private var newTabButton: NSButton!

    private var documents: [Document] = []
    private var activeIndex: Int = 0

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

        newTabButton = NSButton(title: "+", target: self, action: #selector(newTabClicked))
        newTabButton.bezelStyle = .inline
        newTabButton.isBordered = false
        newTabButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        newTabButton.frame = NSRect(x: bounds.width - 32, y: 3, width: 28, height: 26)
        newTabButton.autoresizingMask = [.minXMargin]
        addSubview(newTabButton)

        scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: bounds.width - 36, height: bounds.height))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        tabsContainer = NSView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        scrollView.documentView = tabsContainer
        addSubview(scrollView)
    }

    public func update(documents: [Document], activeIndex: Int) {
        self.documents = documents
        self.activeIndex = activeIndex
        rebuildTabs()
    }

    private func rebuildTabs() {
        tabsContainer.subviews.removeAll()

        var currentX: CGFloat = 8.0
        let tabHeight: CGFloat = bounds.height - 4.0
        let maxTabWidth: CGFloat = 180.0
        let minTabWidth: CGFloat = 90.0

        for (index, doc) in documents.enumerated() {
            let isActive = index == activeIndex
            let title = doc.displayName
            let dirty = doc.isModified ? " •" : ""
            let fullText = title + dirty

            let titleWidth = (fullText as NSString).size(withAttributes: [.font: Theme.uiFont]).width
            let tabWidth = min(maxTabWidth, max(minTabWidth, titleWidth + 40.0))

            let tabView = TabItemView(
                frame: NSRect(x: currentX, y: 2, width: tabWidth, height: tabHeight),
                title: fullText,
                isActive: isActive,
                index: index
            )
            tabView.onSelect = { [weak self] idx in
                self?.delegate?.tabSelected(at: idx)
            }
            tabView.onClose = { [weak self] idx in
                self?.delegate?.tabClosed(at: idx)
            }
            tabsContainer.addSubview(tabView)
            currentX += tabWidth + 4.0
        }

        tabsContainer.frame.size.width = max(bounds.width - 36, currentX + 8.0)
    }

    @objc private func newTabClicked() {
        delegate?.newTabRequested()
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

private final class TabItemView: NSView {
    var onSelect: ((Int) -> Void)?
    var onClose: ((Int) -> Void)?

    private let index: Int
    private let isActive: Bool

    init(frame frameRect: NSRect, title: String, isActive: Bool, index: Int) {
        self.isActive = isActive
        self.index = index
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.cornerRadius = 5.0
        self.layer?.masksToBounds = true
        self.layer?.backgroundColor = isActive ? Theme.surface.cgColor : NSColor.clear.cgColor

        let label = NSTextField(labelWithString: title)
        label.font = isActive ? Theme.uiBoldFont : Theme.uiFont
        label.textColor = isActive ? Theme.foreground : Theme.textMuted
        label.lineBreakMode = .byTruncatingTail
        label.frame = NSRect(x: 10, y: (frame.height - 18) / 2, width: frame.width - 32, height: 18)
        addSubview(label)

        let closeBtn = NSButton(title: "✕", target: self, action: #selector(closeClicked))
        closeBtn.bezelStyle = .inline
        closeBtn.isBordered = false
        closeBtn.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        closeBtn.frame = NSRect(x: frame.width - 22, y: (frame.height - 18) / 2, width: 16, height: 16)
        addSubview(closeBtn)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func mouseDown(with event: NSEvent) {
        onSelect?(index)
    }

    @objc private func closeClicked() {
        onClose?(index)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if isActive {
            Theme.border.setStroke()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 5.0, yRadius: 5.0)
            path.lineWidth = 1.0
            path.stroke()
        }
    }
}
