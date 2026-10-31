import AppKit

final class EditorSplitView: NSSplitView {
    var isDividerHidden: Bool = false

    override var dividerColor: NSColor {
        isDividerHidden ? .clear : Theme.border
    }

    override func drawDivider(in rect: NSRect) {
        guard !isDividerHidden else { return }
        Theme.border.setFill()
        rect.fill()
    }
}

public final class EditorSplitViewController: NSViewController, NSSplitViewDelegate {
    private var splitView: EditorSplitView!
    public private(set) var editorView: EditorView!
    public private(set) var previewContainerView: PreviewContainerView!
    private var lastSplitFraction: CGFloat = 0.55

    public var document: Document? {
        didSet {
            loadDocument()
        }
    }

    public override func loadView() {
        splitView = EditorSplitView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.wantsLayer = true

        editorView = EditorView(frame: NSRect(x: 0, y: 0, width: 440, height: 600))
        previewContainerView = PreviewContainerView(frame: NSRect(x: 441, y: 0, width: 359, height: 600))

        previewContainerView.onFormatJSONRequested = { [weak self] in
            self?.formatCurrentJSON()
        }
        previewContainerView.onTextSelected = { [weak self] selectedText in
            self?.editorView.selectText(matching: selectedText)
        }

        splitView.addSubview(editorView)
        splitView.addSubview(previewContainerView)

        self.view = splitView
    }

    private func loadDocument() {
        guard let doc = document else {
            editorView.document = nil
            return
        }
        editorView.document = doc
        updateMode(doc.previewMode)
        if doc.previewMode != .source {
            previewContainerView.update(document: doc)
        }
    }

    public func updateMode(_ mode: PreviewMode) {
        document?.previewMode = mode
        switch mode {
        case .source:
            splitView.isDividerHidden = true
            editorView.isHidden = false
            previewContainerView.isHidden = true
            editorView.frame = splitView.bounds
            previewContainerView.frame = NSRect(x: splitView.bounds.width, y: 0, width: 0, height: splitView.bounds.height)
            splitView.adjustSubviews()

        case .split:
            splitView.isDividerHidden = false
            editorView.isHidden = false
            previewContainerView.isHidden = false
            let splitPos = max(200, min(splitView.bounds.width - 200, splitView.bounds.width * lastSplitFraction))
            splitView.setPosition(splitPos, ofDividerAt: 0)
            splitView.adjustSubviews()
            if let doc = document {
                previewContainerView.update(document: doc)
            }

        case .preview:
            splitView.isDividerHidden = true
            editorView.isHidden = true
            previewContainerView.isHidden = false
            editorView.frame = NSRect(x: 0, y: 0, width: 0, height: splitView.bounds.height)
            previewContainerView.frame = splitView.bounds
            splitView.adjustSubviews()
            if let doc = document {
                previewContainerView.update(document: doc)
            }
        }
        splitView.needsDisplay = true
    }

    public func editorContentChanged() {
        guard let doc = document else { return }
        if doc.previewMode != .source {
            previewContainerView.update(document: doc)
        }
    }

    private func formatCurrentJSON() {
        guard let doc = document, doc.language == .json else { return }
        guard let data = doc.content.data(using: .utf8) else { return }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let formattedData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            if let formattedString = String(data: formattedData, encoding: .utf8) {
                editorView.textView.string = formattedString
                editorView.textDidChange(Notification(name: NSText.didChangeNotification))
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Cannot Format JSON"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    // MARK: - NSSplitViewDelegate

    public func splitView(_ splitView: NSSplitView, isSubviewCollapsed subview: NSView) -> Bool {
        return subview.isHidden
    }

    public func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        return editorView.isHidden || previewContainerView.isHidden
    }

    public func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if editorView.isHidden || previewContainerView.isHidden {
            return 0
        }
        return 200
    }

    public func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if editorView.isHidden || previewContainerView.isHidden {
            return splitView.bounds.width
        }
        return splitView.bounds.width - 200
    }

    public func splitViewDidResizeSubviews(_ notification: Notification) {
        if !editorView.isHidden && !previewContainerView.isHidden && splitView.bounds.width > 0 {
            lastSplitFraction = max(0.15, min(0.85, editorView.frame.width / splitView.bounds.width))
        }
    }
}
