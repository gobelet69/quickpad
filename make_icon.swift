import AppKit

/// Generates the 111iridescence v2.1 QuickPad application icon:
/// Luminous Pearl squircle + Obsidian drafting pad + '111.' pixel header + syntax bars + pixel-grid block caret + cross-5 star.
func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let scale = size / 1024.0

    // 1. Luminous Pearl macOS Squircle (824x824 at 100,100, rx=185)
    let sqRect = CGRect(x: 100 * scale, y: 100 * scale, width: 824 * scale, height: 824 * scale)
    let sqRadius = 185 * scale
    let sqPath = CGPath(roundedRect: sqRect, cornerWidth: sqRadius, cornerHeight: sqRadius, transform: nil)
    ctx.saveGState()
    ctx.addPath(sqPath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let pearlColors = [
        NSColor(srgbRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor,
        NSColor(srgbRed: 0.925, green: 0.902, blue: 0.961, alpha: 1.0).cgColor
    ] as CFArray
    if let grad = CGGradient(colorsSpace: colorSpace, colors: pearlColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(grad, start: CGPoint(x: size * 0.5, y: sqRect.maxY), end: CGPoint(x: size * 0.5, y: sqRect.minY), options: [])
    }

    // 2. Main Obsidian Code/Text Drafting Pad (616x644 at x=204, svgY=186 -> appKitY=194)
    let padRect = CGRect(x: 204 * scale, y: (1024 - 186 - 644) * scale, width: 616 * scale, height: 644 * scale)
    let padPath = CGPath(roundedRect: padRect, cornerWidth: 110 * scale, cornerHeight: 110 * scale, transform: nil)
    ctx.setFillColor(red: 0x16/255.0, green: 0x10/255.0, blue: 0x1D/255.0, alpha: 1.0)
    ctx.addPath(padPath)
    ctx.fillPath()

    // 3. Structured Code / Markdown Syntax Bars
    func drawSvgRect(_ x: CGFloat, _ svgY: CGFloat, _ w: CGFloat, _ h: CGFloat, _ rx: CGFloat, _ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        let appY = (1024.0 - svgY - h) * scale
        let rect = CGRect(x: x * scale, y: appY, width: w * scale, height: h * scale)
        let p = CGPath(roundedRect: rect, cornerWidth: rx * scale, cornerHeight: rx * scale, transform: nil)
        ctx.setFillColor(red: r, green: g, blue: b, alpha: 1.0)
        ctx.addPath(p)
        ctx.fillPath()
    }

    // '111.' Pixel Numerals in Header
    drawSvgRect(276, 232, 22, 48, 4, 0x0C/255.0, 0xC0/255.0, 0xE8/255.0)
    drawSvgRect(308, 232, 22, 48, 4, 0x22/255.0, 0x66/255.0, 0xF2/255.0)
    drawSvgRect(340, 232, 22, 48, 4, 0x8A/255.0, 0x38/255.0, 0xF5/255.0)
    drawSvgRect(374, 258, 22, 22, 4, 0x12/255.0, 0xCC/255.0, 0xB8/255.0)

    // Syntax rows
    drawSvgRect(276, 378, 136, 36, 9, 0xDC/255.0, 0x3E/255.0, 0xA0/255.0)
    drawSvgRect(432, 378, 268, 36, 9, 0xED/255.0, 0xE8/255.0, 0xF3/255.0)
    drawSvgRect(324, 458, 184, 36, 9, 0x0C/255.0, 0xC0/255.0, 0xE8/255.0)
    drawSvgRect(528, 458, 212, 36, 9, 0xA3/255.0, 0x99/255.0, 0xB2/255.0)
    drawSvgRect(324, 544, 212, 36, 9, 0x22/255.0, 0x66/255.0, 0xF2/255.0)
    drawSvgRect(276, 698, 148, 34, 9, 0x70/255.0, 0x2E/255.0, 0xE4/255.0)

    // 2x4 Pixel-Grid Block Caret
    for r in 0..<4 {
        for c in 0..<2 {
            let cx = 564.0 + CGFloat(c) * 34.0
            let cy = 540.0 + CGFloat(r) * 34.0
            if r == 0 {
                drawSvgRect(cx, cy, 28, 28, 5, 0x0C/255.0, 0xC0/255.0, 0xE8/255.0)
            } else if r == 3 {
                drawSvgRect(cx, cy, 28, 28, 5, 0x70/255.0, 0x2E/255.0, 0xE4/255.0)
            } else {
                drawSvgRect(cx, cy, 28, 28, 5, 0x8A/255.0, 0x38/255.0, 0xF5/255.0)
            }
        }
    }

    // Signature 5-Cell Pixel Cross Star (`cross-5`) at (716, 252)
    drawSvgRect(706, 242, 20, 20, 4, 0xE0/255.0, 0xFA/255.0, 0xFF/255.0)
    drawSvgRect(706, 218, 20, 20, 4, 0xDC/255.0, 0x3E/255.0, 0xA0/255.0)
    drawSvgRect(682, 242, 20, 20, 4, 0x8A/255.0, 0x38/255.0, 0xF5/255.0)
    drawSvgRect(730, 242, 20, 20, 4, 0x0C/255.0, 0xC0/255.0, 0xE8/255.0)
    drawSvgRect(706, 266, 20, 20, 4, 0x70/255.0, 0x2E/255.0, 0xE4/255.0)

    ctx.restoreGState()
    image.unlockFocus()
    return image
}

let iconsetURL = URL(fileURLWithPath: "/tmp/QuickPad.iconset")
try? FileManager.default.removeItem(at: iconsetURL)
try? FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(Int, Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2)
]

for (pt, scale) in sizes {
    let px = pt * scale
    let img = makeIcon(size: CGFloat(px))
    guard let tiff = img.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        continue
    }
    let filename = scale == 1 ? "icon_\(pt)x\(pt).png" : "icon_\(pt)x\(pt)@2x.png"
    try? png.write(to: iconsetURL.appendingPathComponent(filename))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetURL.path, "-o", "Resources/AppIcon.icns"]
try? task.run()
task.waitUntilExit()
print("AppIcon.icns created successfully!")
