import AppKit

public final class MainWindowController: NSWindowController, NSWindowDelegate, TabBarDelegate, StatusBarDelegate, EditorViewDelegate {
    public private(set) var tabBar: TabBarView!
    public private(set) var splitVC: EditorSplitViewController!
    public private(set) var statusBar: StatusBarView!

    public private(set) var documents: [Document] = []
    public private(set) var activeIndex: Int = 0

    public var currentDocument: Document? {
        guard activeIndex >= 0 && activeIndex < documents.count else { return nil }
        return documents[activeIndex]
    }

    public convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 960, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "QuickPad"
        window.minSize = NSSize(width: 580, height: 380)
        window.backgroundColor = Theme.background
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("QuickPadMainWindow")

        self.init(window: window)
        window.delegate = self
        setupLayout()
    }

    private func setupLayout() {
        guard let window = window else { return }
        let contentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = Theme.background.cgColor
        window.contentView = contentView

        // 1. Tab Bar (height 34)
        tabBar = TabBarView(frame: NSRect(x: 0, y: contentView.bounds.height - 34, width: contentView.bounds.width, height: 34))
        tabBar.autoresizingMask = [.width, .minYMargin]
        tabBar.delegate = self
        contentView.addSubview(tabBar)

        // 2. Status Bar (height 26)
        statusBar = StatusBarView(frame: NSRect(x: 0, y: 0, width: contentView.bounds.width, height: 26))
        statusBar.autoresizingMask = [.width, .maxYMargin]
        statusBar.delegate = self
        contentView.addSubview(statusBar)

        // 3. Center Split VC
        splitVC = EditorSplitViewController()
        splitVC.loadView()
        splitVC.view.frame = NSRect(x: 0, y: 26, width: contentView.bounds.width, height: contentView.bounds.height - 60)
        splitVC.view.autoresizingMask = [.width, .height]
        splitVC.editorView.delegate = self
        contentView.addSubview(splitVC.view)

        // Register drag & drop
        window.registerForDraggedTypes([.fileURL])

        // Add initial empty untitled document if none exists
        if documents.isEmpty {
            let doc = Document()
            documents.append(doc)
            activeIndex = 0
            switchToDocument(at: 0)
        }
    }

    public func switchToDocument(at index: Int) {
        guard index >= 0 && index < documents.count else { return }
        activeIndex = index
        let doc = documents[index]
        splitVC.document = doc
        tabBar.update(documents: documents, activeIndex: activeIndex)
        updateWindowTitle()
        updateStatusBar()
        window?.makeFirstResponder(splitVC.editorView.textView)
    }

    public func updateWindowTitle() {
        guard let doc = currentDocument else {
            window?.title = "QuickPad"
            return
        }
        window?.title = "\(doc.title) — QuickPad"
        window?.isDocumentEdited = doc.isModified
    }

    public func updateStatusBar() {
        guard let doc = currentDocument else { return }
        statusBar.update(document: doc, line: 1, col: 1, selectionLength: 0)
    }

    // MARK: - Document Actions

    public func newDocument() {
        let doc = Document()
        documents.append(doc)
        switchToDocument(at: documents.count - 1)
    }

    public func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Open"

        panel.beginSheetModal(for: window!) { [weak self] response in
            if response == .OK {
                self?.openURLs(panel.urls)
            }
        }
    }

    public func openURLs(_ urls: [URL]) {
        for url in urls {
            // Check if already open
            if let existingIndex = documents.firstIndex(where: { $0.fileURL == url }) {
                switchToDocument(at: existingIndex)
                continue
            }

            do {
                let doc = try Document.open(url: url)
                // If only document is untitled and clean, replace it
                if documents.count == 1 && documents[0].fileURL == nil && !documents[0].isModified && documents[0].content.isEmpty {
                    documents[0] = doc
                    switchToDocument(at: 0)
                } else {
                    documents.append(doc)
                    switchToDocument(at: documents.count - 1)
                }
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Cannot Open File"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }

    public func saveDocument() {
        guard let doc = currentDocument else { return }
        if doc.fileURL == nil {
            saveDocumentAs()
        } else {
            do {
                try doc.save()
                tabBar.update(documents: documents, activeIndex: activeIndex)
                updateWindowTitle()
            } catch {
                let alert = NSAlert()
                alert.messageText = "Cannot Save File"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }

    public func saveDocumentAs() {
        guard let doc = currentDocument else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = doc.displayName == "Untitled" ? "Untitled.txt" : doc.displayName
        panel.prompt = "Save"

        panel.beginSheetModal(for: window!) { [weak self] response in
            guard let self = self, response == .OK, let url = panel.url else { return }
            do {
                try doc.save(to: url)
                self.tabBar.update(documents: self.documents, activeIndex: self.activeIndex)
                self.updateWindowTitle()
                self.updateStatusBar()
                self.splitVC.editorContentChanged()
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
            } catch {
                let alert = NSAlert()
                alert.messageText = "Cannot Save File"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .critical
                alert.runModal()
            }
        }
    }

    public func closeTab(at index: Int) {
        guard index >= 0 && index < documents.count else { return }
        let doc = documents[index]

        if doc.isModified {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes to \"\(doc.displayName)\"?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Cancel")
            alert.addButton(withTitle: "Don't Save")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn { // Save
                saveDocument()
                if doc.isModified { return } // Save cancelled or failed
            } else if response == .alertSecondButtonReturn { // Cancel
                return
            }
        }

        documents.remove(at: index)

        if documents.isEmpty {
            // Keep at least one empty document
            let newDoc = Document()
            documents.append(newDoc)
            activeIndex = 0
        } else if activeIndex >= documents.count {
            activeIndex = documents.count - 1
        }

        switchToDocument(at: activeIndex)
    }

    // MARK: - TabBarDelegate

    public func tabSelected(at index: Int) {
        switchToDocument(at: index)
    }

    public func tabClosed(at index: Int) {
        closeTab(at: index)
    }

    public func newTabRequested() {
        newDocument()
    }

    // MARK: - StatusBarDelegate

    public func previewModeChanged(to mode: PreviewMode) {
        splitVC.updateMode(mode)
    }

    // MARK: - EditorViewDelegate

    public func editorTextDidChange(_ editor: EditorView) {
        tabBar.update(documents: documents, activeIndex: activeIndex)
        updateWindowTitle()
        splitVC.editorContentChanged()
    }

    public func editorCursorMoved(_ editor: EditorView, line: Int, col: Int, selectionLength: Int) {
        guard let doc = currentDocument else { return }
        statusBar.update(document: doc, line: line, col: col, selectionLength: selectionLength)
    }

    // MARK: - Menu Actions

    public func togglePreview() {
        guard let doc = currentDocument, doc.language.hasPreview else { return }
        let nextMode: PreviewMode = doc.previewMode == .source ? .preview : .source
        splitVC.updateMode(nextMode)
        updateStatusBar()
    }

    public func toggleSplitView() {
        guard let doc = currentDocument, doc.language.hasPreview else { return }
        let nextMode: PreviewMode = doc.previewMode == .split ? .source : .split
        splitVC.updateMode(nextMode)
        updateStatusBar()
    }

    public func showFind() {
        splitVC.editorView.showFind()
    }

    public func showGoToLine() {
        splitVC.editorView.showGoToLine()
    }

    public func toggleWordWrap() {
        splitVC.editorView.isLineWrappingEnabled.toggle()
    }

    // MARK: - NSWindowDelegate

    public func windowShouldClose(_ sender: NSWindow) -> Bool {
        for (i, doc) in documents.enumerated() {
            if doc.isModified {
                switchToDocument(at: i)
                closeTab(at: i)
                if documents.contains(where: { $0.id == doc.id && $0.isModified }) {
                    return false // User cancelled
                }
            }
        }
        return true
    }

    public func windowDidBecomeKey(_ notification: Notification) {
        // Check for external file modifications
        for doc in documents {
            if doc.checkExternalModification() {
                let alert = NSAlert()
                alert.messageText = "\"\(doc.displayName)\" was modified externally."
                alert.informativeText = "Would you like to reload it from disk?"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "Reload")
                alert.addButton(withTitle: "Keep My Changes")

                if alert.runModal() == .alertFirstButtonReturn {
                    try? doc.reload()
                    if doc.id == currentDocument?.id {
                        splitVC.document = doc
                        tabBar.update(documents: documents, activeIndex: activeIndex)
                        updateWindowTitle()
                        updateStatusBar()
                    }
                }
            }
        }
    }
}
