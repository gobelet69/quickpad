import AppKit

@objc public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var windowController: MainWindowController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.mainMenu = AppMenu.build()

        let wc = MainWindowController()
        self.windowController = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let urls = filenames.map { URL(fileURLWithPath: $0) }
        if let wc = windowController {
            wc.openURLs(urls)
        } else {
            let wc = MainWindowController()
            self.windowController = wc
            wc.openURLs(urls)
            wc.showWindow(nil)
        }
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let wc = windowController else { return .terminateNow }
        for (i, doc) in wc.documents.enumerated() {
            if doc.isModified {
                wc.switchToDocument(at: i)
                let alert = NSAlert()
                alert.messageText = "Do you want to save changes to \"\(doc.displayName)\"?"
                alert.informativeText = "Your changes will be lost if you quit without saving."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Save")
                alert.addButton(withTitle: "Cancel")
                alert.addButton(withTitle: "Don't Save")

                let res = alert.runModal()
                if res == .alertFirstButtonReturn {
                    wc.saveDocument()
                    if doc.isModified { return .terminateCancel }
                } else if res == .alertSecondButtonReturn {
                    return .terminateCancel
                }
            }
        }
        return .terminateNow
    }

    // MARK: - Menu Actions

    @objc public func menuNewDocument() {
        windowController?.newDocument()
    }

    @objc public func menuOpenDocument() {
        windowController?.openFile()
    }

    @objc public func menuSaveDocument() {
        windowController?.saveDocument()
    }

    @objc public func menuSaveDocumentAs() {
        windowController?.saveDocumentAs()
    }

    @objc public func menuCloseTab() {
        if let wc = windowController {
            wc.closeTab(at: wc.activeIndex)
        }
    }

    @objc public func menuFind() {
        windowController?.showFind()
    }

    @objc public func menuFindNext() {
        windowController?.splitVC.editorView.findNext(query: "", matchCase: false, wholeWord: false, isRegex: false)
    }

    @objc public func menuFindPrevious() {
        windowController?.splitVC.editorView.findPrevious(query: "", matchCase: false, wholeWord: false, isRegex: false)
    }

    @objc public func menuGoToLine() {
        windowController?.showGoToLine()
    }

    @objc public func menuTogglePreview() {
        windowController?.togglePreview()
    }

    @objc public func menuToggleSplitView() {
        windowController?.toggleSplitView()
    }

    @objc public func menuToggleWordWrap() {
        windowController?.toggleWordWrap()
    }

    @objc public func showAbout() {
        let alert = NSAlert()
        alert.messageText = "QuickPad"
        alert.informativeText = "Version 1.0.0\n\nUltra-fast native text editor with intelligent previews.\n\nCrafted by 111iridescence — The Prismatic Atelier."
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc public func showHelp() {
        if let url = URL(string: "https://111iridescence.org") {
            NSWorkspace.shared.open(url)
        }
    }
}
