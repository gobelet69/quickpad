import AppKit

public enum AppMenu {
    public static func build() -> NSMenu {
        let mainMenu = NSMenu()

        // 1. QuickPad Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenuItem.submenu = appMenu

        appMenu.addItem(NSMenuItem(title: "About QuickPad", action: #selector(AppDelegate.showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Hide QuickPad", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthers = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit QuickPad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // 2. File Menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu

        fileMenu.addItem(NSMenuItem(title: "New", action: #selector(AppDelegate.menuNewDocument), keyEquivalent: "n"))
        fileMenu.addItem(NSMenuItem(title: "Open…", action: #selector(AppDelegate.menuOpenDocument), keyEquivalent: "o"))

        let openRecentItem = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        let openRecentMenu = NSMenu(title: "Open Recent")
        openRecentMenu.perform(NSSelectorFromString("_setMenuName:"), with: "NSRecentDocumentsMenu")
        openRecentItem.submenu = openRecentMenu
        fileMenu.addItem(openRecentItem)

        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Save", action: #selector(AppDelegate.menuSaveDocument), keyEquivalent: "s"))
        let saveAsItem = NSMenuItem(title: "Save As…", action: #selector(AppDelegate.menuSaveDocumentAs), keyEquivalent: "S")
        saveAsItem.keyEquivalentModifierMask = [.command, .shift]
        fileMenu.addItem(saveAsItem)
        fileMenu.addItem(NSMenuItem.separator())
        fileMenu.addItem(NSMenuItem(title: "Close Tab", action: #selector(AppDelegate.menuCloseTab), keyEquivalent: "w"))

        // 3. Edit Menu
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu

        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenu.addItem(NSMenuItem.separator())

        editMenu.addItem(NSMenuItem(title: "Find…", action: #selector(AppDelegate.menuFind), keyEquivalent: "f"))
        editMenu.addItem(NSMenuItem(title: "Find Next", action: #selector(AppDelegate.menuFindNext), keyEquivalent: "g"))
        let findPrevItem = NSMenuItem(title: "Find Previous", action: #selector(AppDelegate.menuFindPrevious), keyEquivalent: "G")
        findPrevItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(findPrevItem)
        editMenu.addItem(NSMenuItem(title: "Go to Line…", action: #selector(AppDelegate.menuGoToLine), keyEquivalent: "l"))

        // 4. View Menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu

        let togglePreviewItem = NSMenuItem(title: "Toggle Preview", action: #selector(AppDelegate.menuTogglePreview), keyEquivalent: "p")
        togglePreviewItem.keyEquivalentModifierMask = [.command, .shift]
        viewMenu.addItem(togglePreviewItem)

        let toggleSplitItem = NSMenuItem(title: "Toggle Split View", action: #selector(AppDelegate.menuToggleSplitView), keyEquivalent: "s")
        toggleSplitItem.keyEquivalentModifierMask = [.command, .option]
        viewMenu.addItem(toggleSplitItem)

        viewMenu.addItem(NSMenuItem.separator())
        let toggleWordWrapItem = NSMenuItem(title: "Toggle Word Wrap", action: #selector(AppDelegate.menuToggleWordWrap), keyEquivalent: "w")
        toggleWordWrapItem.keyEquivalentModifierMask = [.command, .option]
        viewMenu.addItem(toggleWordWrapItem)

        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = NSMenu(title: "Window")
        windowMenuItem.submenu = windowMenu

        windowMenu.addItem(NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: ""))
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: ""))

        // 6. Help Menu
        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        let helpMenu = NSMenu(title: "Help")
        helpMenuItem.submenu = helpMenu
        helpMenu.addItem(NSMenuItem(title: "QuickPad Help", action: #selector(AppDelegate.showHelp), keyEquivalent: "?"))

        return mainMenu
    }
}
