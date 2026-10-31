import AppKit

public final class EditorSplitViewController: NSViewController, NSSplitViewDelegate {
    private var splitView: NSSplitView!
    public private(set) var editorView: EditorView!
    public private(set) var previewContainerView: PreviewContainerView!

    public var document: Document? {
        didSet {
            loadDocument()
        }
    }

    public override func loadView() {
        splitView = NSSplitView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = self
        splitView.wantsLayer = true

        editorView = EditorView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
        previewContainerView = PreviewContainerView(frame: NSRect(x: 400, y: 0, width: 400, height: 600))

        previewContainerView.onFormatJSONRequested = { [weak self] in
            self?.formatCurrentJSON()
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
            editorView.isHidden = false
            previewContainerView.isHidden = true
            splitView.adjustSubviews()

        case .split:
            editorView.isHidden = false
            previewContainerView.isHidden = false
            splitView.adjustSubviews()
            if let doc = document {
                previewContainerView.update(document: doc)
            }

        case .preview:
            editorView.isHidden = true
            previewContainerView.isHidden = false
            splitView.adjustSubviews()
            if let doc = document {
                previewContainerView.update(document: doc)
            }
        }
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

    public func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return 200
    }

    public func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return splitView.bounds.width - 200
    }
}
