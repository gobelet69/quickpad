import AppKit

public enum Theme {
    // 111iridescence Brand Tokens
    public static let ink = NSColor(srgbRed: 0x16/255.0, green: 0x10/255.0, blue: 0x1D/255.0, alpha: 1.0)
    public static let paper = NSColor(srgbRed: 0xFA/255.0, green: 0xF9/255.0, blue: 0xFC/255.0, alpha: 1.0)
    public static let darkBackground = NSColor(srgbRed: 0x18/255.0, green: 0x13/255.0, blue: 0x1E/255.0, alpha: 1.0)
    public static let darkSurface = NSColor(srgbRed: 0x21/255.0, green: 0x1B/255.0, blue: 0x28/255.0, alpha: 1.0)

    public static let violet = NSColor(srgbRed: 0xA8/255.0, green: 0x55/255.0, blue: 0xF7/255.0, alpha: 1.0)
    public static let coral = NSColor(srgbRed: 0xEE/255.0, green: 0x76/255.0, blue: 0x6A/255.0, alpha: 1.0)
    public static let presence = NSColor(srgbRed: 0x34/255.0, green: 0xD3/255.0, blue: 0x99/255.0, alpha: 1.0)
    public static let blue = NSColor(srgbRed: 0x38/255.0, green: 0x80/255.0, blue: 0xDC/255.0, alpha: 1.0)
    public static let amber = NSColor(srgbRed: 0xF5/255.0, green: 0x9E/255.0, blue: 0x0B/255.0, alpha: 1.0)

    // Dynamic UI Colors
    public static let background: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? Theme.darkBackground
            : Theme.paper
    }

    public static let surface: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? Theme.darkSurface
            : NSColor.white
    }

    public static let foreground: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0xED/255.0, green: 0xE8/255.0, blue: 0xF3/255.0, alpha: 1.0)
            : Theme.ink
    }

    public static let textMuted: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x9D/255.0, green: 0x94/255.0, blue: 0xA7/255.0, alpha: 1.0)
            : NSColor(srgbRed: 0x6C/255.0, green: 0x62/255.0, blue: 0x74/255.0, alpha: 1.0)
    }

    public static let border: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x35/255.0, green: 0x2C/255.0, blue: 0x40/255.0, alpha: 1.0)
            : NSColor(srgbRed: 0xE2/255.0, green: 0xDD/255.0, blue: 0xE7/255.0, alpha: 1.0)
    }

    public static let gutterBackground: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x15/255.0, green: 0x11/255.0, blue: 0x1A/255.0, alpha: 1.0)
            : NSColor(srgbRed: 0xF4/255.0, green: 0xF2/255.0, blue: 0xF7/255.0, alpha: 1.0)
    }

    public static let gutterText: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x65/255.0, green: 0x5D/255.0, blue: 0x70/255.0, alpha: 1.0)
            : NSColor(srgbRed: 0xA2/255.0, green: 0x9A/255.0, blue: 0xAA/255.0, alpha: 1.0)
    }

    public static let activeLineHighlight: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 1.0, alpha: 0.04)
            : NSColor(white: 0.0, alpha: 0.03)
    }

    public static let selection: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x63/255.0, green: 0x66/255.0, blue: 0xF1/255.0, alpha: 0.35)
            : NSColor(srgbRed: 0x4F/255.0, green: 0x46/255.0, blue: 0xE5/255.0, alpha: 0.20)
    }

    // Syntax Highlighting Palette
    public static let syntaxKeyword: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0xC0/255.0, green: 0x84/255.0, blue: 0xFC/255.0, alpha: 1.0) // violet-400
            : NSColor(srgbRed: 0x7E/255.0, green: 0x22/255.0, blue: 0xCE/255.0, alpha: 1.0) // violet-700
    }

    public static let syntaxString: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x34/255.0, green: 0xD3/255.0, blue: 0x99/255.0, alpha: 1.0) // emerald-400
            : NSColor(srgbRed: 0x05/255.0, green: 0x96/255.0, blue: 0x69/255.0, alpha: 1.0) // emerald-600
    }

    public static let syntaxComment: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x76/255.0, green: 0x6E/255.0, blue: 0x82/255.0, alpha: 1.0)
            : NSColor(srgbRed: 0x8E/255.0, green: 0x85/255.0, blue: 0x96/255.0, alpha: 1.0)
    }

    public static let syntaxNumber: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0xFB/255.0, green: 0x92/255.0, blue: 0x3C/255.0, alpha: 1.0) // orange-400
            : NSColor(srgbRed: 0xEA/255.0, green: 0x58/255.0, blue: 0x0C/255.0, alpha: 1.0) // orange-600
    }

    public static let syntaxType: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x60/255.0, green: 0xA5/255.0, blue: 0xFA/255.0, alpha: 1.0) // blue-400
            : NSColor(srgbRed: 0x25/255.0, green: 0x63/255.0, blue: 0xEB/255.0, alpha: 1.0) // blue-600
    }

    public static let syntaxFunction: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0xF4/255.0, green: 0x72/255.0, blue: 0xB6/255.0, alpha: 1.0) // pink-400
            : NSColor(srgbRed: 0xDB/255.0, green: 0x27/255.0, blue: 0x77/255.0, alpha: 1.0) // pink-600
    }

    public static let syntaxTag: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x2D/255.0, green: 0xD4/255.0, blue: 0xBF/255.0, alpha: 1.0) // teal-400
            : NSColor(srgbRed: 0x0D/255.0, green: 0x94/255.0, blue: 0x88/255.0, alpha: 1.0) // teal-600
    }

    public static let syntaxAttribute: NSColor = NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0xFA/255.0, green: 0xCC/255.0, blue: 0x15/255.0, alpha: 1.0) // yellow-400
            : NSColor(srgbRed: 0xCA/255.0, green: 0x8A/255.0, blue: 0x04/255.0, alpha: 1.0) // yellow-600
    }

    // Typography
    public static var editorFont: NSFont {
        if #available(macOS 10.15, *) {
            return NSFont.monospacedSystemFont(ofSize: 13.0, weight: .regular)
        } else {
            return NSFont(name: "Menlo", size: 13.0) ?? NSFont.userFixedPitchFont(ofSize: 13.0)!
        }
    }

    public static var gutterFont: NSFont {
        if #available(macOS 10.15, *) {
            return NSFont.monospacedSystemFont(ofSize: 11.0, weight: .regular)
        } else {
            return NSFont(name: "Menlo", size: 11.0) ?? NSFont.userFixedPitchFont(ofSize: 11.0)!
        }
    }

    public static var uiFont: NSFont {
        return NSFont.systemFont(ofSize: 12.0, weight: .regular)
    }

    public static var uiBoldFont: NSFont {
        return NSFont.systemFont(ofSize: 12.0, weight: .semibold)
    }

    public static var uiSmallFont: NSFont {
        return NSFont.systemFont(ofSize: 11.0, weight: .regular)
    }
}
