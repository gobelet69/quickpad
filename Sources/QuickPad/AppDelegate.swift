import AppKit
import UniformTypeIdentifiers

@objc public final class AppDelegate: NSObject, NSApplicationDelegate {
    public var windowController: MainWindowController?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.mainMenu = AppMenu.build()

        let wc = ensureWindowController()
        wc.showWindow(nil)
        if !UserDefaults.standard.bool(forKey: "askedDefaultEditor") {
            UserDefaults.standard.set(true, forKey: "askedDefaultEditor")
            DispatchQueue.main.async { [weak self] in self?.offerDefaultEditor() }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func ensureWindowController() -> MainWindowController {
        if let wc = windowController { return wc }
        let wc = MainWindowController()
        windowController = wc
        return wc
    }

    public func application(_ sender: NSApplication, openFiles filenames: [String]) {
        let wc = ensureWindowController()
        wc.openURLs(filenames.map { URL(fileURLWithPath: $0) })
        wc.showWindow(nil)
        sender.reply(toOpenOrPrint: .success)
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { ensureWindowController().showWindow(nil) }
        return true
    }

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let wc = windowController else { return .terminateNow }
        return wc.persistSession() ? .terminateNow : .terminateCancel
    }

    @objc public func offerDefaultEditor() {
        let alert = NSAlert()
        alert.messageText = "Make QuickPad your default text editor?"
        alert.informativeText = "macOS will ask you to confirm QuickPad as the default app for plain text files. Other file types keep their current app."
        alert.addButton(withTitle: "Use QuickPad")
        alert.addButton(withTitle: "Not Now")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { @MainActor in
            do {
                try await NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: UTType.plainText)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
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
