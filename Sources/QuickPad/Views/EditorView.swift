import AppKit

public protocol EditorViewDelegate: AnyObject {
    func editorTextDidChange(_ editor: EditorView)
    func editorCursorMoved(_ editor: EditorView, line: Int, col: Int, selectionLength: Int)
}

public final class EditorView: NSView, NSTextViewDelegate, FindBarDelegate, GoToLineDelegate {
    public weak var delegate: EditorViewDelegate?

    public override var isFlipped: Bool { true }

    private(set) var scrollView: NSScrollView!
    private(set) var textView: NSTextView!
    private(set) var gutterView: LineNumberGutterView!
    private(set) var findBarView: FindBarView!
    private(set) var goToLineView: GoToLineView!

    public var document: Document? {
        didSet {
            loadDocument()
        }
    }

    private var highlighter: SyntaxHighlighter?
    private var highlightWorkItem: DispatchWorkItem?
    private var suppressChangeNotification = false

    public var isLineWrappingEnabled: Bool = true {
        didSet {
            configureLineWrapping()
        }
    }

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
        layer?.masksToBounds = true
        layer?.backgroundColor = Theme.background.cgColor

        // 1. Text View & Scroll View
        scrollView = NSTextView.scrollableTextView()
        scrollView.frame = bounds
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true

        textView = scrollView.documentView as? NSTextView
        textView.delegate = self
        textView.font = Theme.editorFont
        textView.textColor = Theme.foreground
        textView.backgroundColor = Theme.background
        textView.insertionPointColor = Theme.foreground
        textView.selectedTextAttributes = [
            .backgroundColor: Theme.selection
        ]
        textView.typingAttributes = [
            .font: Theme.editorFont,
            .foregroundColor: Theme.foreground
        ]
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true

        // 2. Line Number Gutter
        gutterView = LineNumberGutterView(textView: textView)
        gutterView.frame = NSRect(x: 0, y: 0, width: 45, height: bounds.height)
        gutterView.autoresizingMask = [.height]

        // Listen for scroll and frame notifications to redraw gutter
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textViewFrameDidChange),
            name: NSView.frameDidChangeNotification,
            object: textView
        )

        addSubview(scrollView)
        addSubview(gutterView)

        // 3. Find Bar (hidden by default)
        findBarView = FindBarView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: 70))
        findBarView.autoresizingMask = [.width, .maxYMargin]
        findBarView.delegate = self
        findBarView.isHidden = true
        addSubview(findBarView)

        // 4. Go To Line View (hidden by default)
        goToLineView = GoToLineView(frame: NSRect(x: 0, y: 0, width: bounds.width, height: 36))
        goToLineView.autoresizingMask = [.width, .maxYMargin]
        goToLineView.delegate = self
        goToLineView.isHidden = true
        addSubview(goToLineView)

        configureLineWrapping()
        updateGutterLayout()
    }

    private func configureLineWrapping() {
        guard let textContainer = textView?.textContainer else { return }
        if isLineWrappingEnabled {
            scrollView.hasHorizontalScroller = false
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
            textView.isHorizontallyResizable = false
        } else {
            scrollView.hasHorizontalScroller = true
            textContainer.widthTracksTextView = false
            textContainer.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.isHorizontallyResizable = true
        }
    }

    public override func layout() {
        super.layout()
        updateGutterLayout()
    }

    private func updateGutterLayout() {
        gutterView.updateWidth()
        let gutterWidth = gutterView.frame.width
        let topInset: CGFloat = (findBarView.isHidden ? 0 : 70) + (goToLineView.isHidden ? 0 : 36)

        gutterView.frame = NSRect(x: 0, y: topInset, width: gutterWidth, height: max(0, bounds.height - topInset))
        scrollView.frame = NSRect(x: gutterWidth, y: topInset, width: max(0, bounds.width - gutterWidth), height: max(0, bounds.height - topInset))

        if !findBarView.isHidden {
            findBarView.frame = NSRect(x: 0, y: 0, width: bounds.width, height: 70)
        }
        if !goToLineView.isHidden {
            let y: CGFloat = findBarView.isHidden ? 0 : 70
            goToLineView.frame = NSRect(x: 0, y: y, width: bounds.width, height: 36)
        }
    }

    private func loadDocument() {
        guard let doc = document else {
            suppressChangeNotification = true
            textView.string = ""
            suppressChangeNotification = false
            gutterView.needsDisplay = true
            return
        }

        suppressChangeNotification = true
        if let cachedStorage = doc.cachedTextStorage {
            textView.layoutManager?.replaceTextStorage(cachedStorage)
        } else {
            textView.string = doc.content
        }

        highlighter = SyntaxHighlighter(language: doc.language)

        // Restore scroll and cursor
        if doc.cursorPosition <= (textView.string as NSString).length {
            textView.setSelectedRange(NSRange(location: doc.cursorPosition, length: 0))
        }

        suppressChangeNotification = false
        updateGutterLayout()
        triggerHighlight(full: true)
        textView.needsDisplay = true
        gutterView.needsDisplay = true
        updateCursorStats()
    }

    @objc private func scrollViewDidScroll() {
        gutterView.needsDisplay = true
    }

    @objc private func textViewFrameDidChange() {
        gutterView.updateWidth()
        gutterView.needsDisplay = true
    }

    // MARK: - NSTextViewDelegate

    public func textDidChange(_ notification: Notification) {
        guard !suppressChangeNotification else { return }
        document?.content = textView.string
        gutterView.updateWidth()
        gutterView.needsDisplay = true
        triggerHighlight(full: false)
        updateCursorStats()
        delegate?.editorTextDidChange(self)
    }

    public func textViewDidChangeSelection(_ notification: Notification) {
        guard !suppressChangeNotification else { return }
        document?.cursorPosition = textView.selectedRange().location
        gutterView.needsDisplay = true
        updateCursorStats()
    }

    private func updateCursorStats() {
        let string = textView.string as NSString
        let selectedRange = textView.selectedRange()
        guard selectedRange.location != NSNotFound && selectedRange.location <= string.length else {
            delegate?.editorCursorMoved(self, line: 1, col: 1, selectionLength: 0)
            return
        }

        var line = 1
        var col = 1
        string.enumerateSubstrings(in: NSRange(location: 0, length: selectedRange.location), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            line += 1
        }
        let lineRange = string.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        col = selectedRange.location - lineRange.location + 1

        delegate?.editorCursorMoved(self, line: line, col: col, selectionLength: selectedRange.length)
    }

    // MARK: - Syntax Highlighting

    private func triggerHighlight(full: Bool) {
        guard let storage = textView.textStorage, highlighter != nil else { return }
        highlightWorkItem?.cancel()

        let totalLen = (storage.string as NSString).length
        if totalLen > 5_000_000 {
            // Very large file: skip continuous highlighting for 60fps typing
            return
        }

        let range = full ? NSRange(location: 0, length: totalLen) : textView.selectedRange()
        let delay: TimeInterval = full ? 0.0 : 0.05

        let workItem = DispatchWorkItem { [weak self, weak storage] in
            guard let self = self, let storage = storage, let highlighter = self.highlighter else { return }
            highlighter.highlight(
                storage: storage,
                in: range,
                font: Theme.editorFont,
                textColor: Theme.foreground
            )
            self.textView.needsDisplay = true
        }
        highlightWorkItem = workItem
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        } else {
            workItem.perform()
        }
    }

    // MARK: - Find / Replace Actions

    public func showFind() {
        findBarView.isHidden = false
        updateGutterLayout()
        findBarView.focusFind()
    }

    public func showGoToLine() {
        goToLineView.isHidden = false
        updateGutterLayout()
        goToLineView.focus()
    }

    public func closeFindBar() {
        findBarView.isHidden = true
        updateGutterLayout()
        window?.makeFirstResponder(textView)
    }

    public func closeGoToLine() {
        goToLineView.isHidden = true
        updateGutterLayout()
        window?.makeFirstResponder(textView)
    }

    public func jumpTo(line: Int) {
        let string = textView.string as NSString
        var currentLine = 1
        var targetLocation = 0

        string.enumerateSubstrings(in: NSRange(location: 0, length: string.length), options: [.byLines, .substringNotRequired]) { _, substringRange, _, stop in
            if currentLine == line {
                targetLocation = substringRange.location
                stop.pointee = true
            }
            currentLine += 1
        }

        if targetLocation < string.length {
            textView.setSelectedRange(NSRange(location: targetLocation, length: 0))
            textView.scrollRangeToVisible(NSRange(location: targetLocation, length: 0))
        }
    }

    public func findNext(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool) {
        performSearch(query: query, matchCase: matchCase, wholeWord: wholeWord, isRegex: isRegex, forward: true)
    }

    public func findPrevious(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool) {
        performSearch(query: query, matchCase: matchCase, wholeWord: wholeWord, isRegex: isRegex, forward: false)
    }

    private func performSearch(query: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool, forward: Bool) {
        guard !query.isEmpty else {
            findBarView.updateMatchCount(current: 0, total: 0)
            return
        }

        let text = textView.string
        var pattern = isRegex ? query : NSRegularExpression.escapedPattern(for: query)
        if wholeWord {
            pattern = "\\b\(pattern)\\b"
        }

        var options: NSRegularExpression.Options = []
        if !matchCase { options.insert(.caseInsensitive) }

        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            findBarView.updateMatchCount(current: 0, total: 0)
            return
        }

        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let matches = regex.matches(in: text, options: [], range: fullRange)

        guard !matches.isEmpty else {
            findBarView.updateMatchCount(current: 0, total: 0)
            return
        }

        let currentSelection = textView.selectedRange()
        var targetIndex = 0

        if forward {
            if let idx = matches.firstIndex(where: { $0.range.location > currentSelection.location }) {
                targetIndex = idx
            } else {
                targetIndex = 0 // Wrap around
            }
        } else {
            if let idx = matches.lastIndex(where: { $0.range.location < currentSelection.location }) {
                targetIndex = idx
            } else {
                targetIndex = matches.count - 1 // Wrap around
            }
        }

        let matchRange = matches[targetIndex].range
        textView.setSelectedRange(matchRange)
        textView.scrollRangeToVisible(matchRange)
        findBarView.updateMatchCount(current: targetIndex + 1, total: matches.count)
    }

    public func replaceCurrent(with replacement: String) {
        let sel = textView.selectedRange()
        guard sel.length > 0 else { return }
        textView.insertText(replacement, replacementRange: sel)
    }

    public func replaceAll(query: String, replacement: String, matchCase: Bool, wholeWord: Bool, isRegex: Bool) {
        guard !query.isEmpty else { return }
        let text = textView.string
        var pattern = isRegex ? query : NSRegularExpression.escapedPattern(for: query)
        if wholeWord { pattern = "\\b\(pattern)\\b" }

        var options: NSRegularExpression.Options = []
        if !matchCase { options.insert(.caseInsensitive) }

        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        let replaced = regex.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: (text as NSString).length), withTemplate: replacement)

        textView.string = replaced
        textDidChange(Notification(name: NSText.didChangeNotification))
    }
}
