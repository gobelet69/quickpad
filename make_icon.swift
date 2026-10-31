import AppKit

func makeIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.2237 // Apple squircle radius

    // 1. Clip squircle
    let path = CGPath(roundedRect: rect.insetBy(dx: size * 0.04, dy: size * 0.04), cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(path)
    ctx.clip()

    // 2. Obsidian background (#16101D)
    ctx.setFillColor(red: 0x16/255.0, green: 0x10/255.0, blue: 0x1D/255.0, alpha: 1.0)
    ctx.fill(rect)

    // 3. Subtle iridescent diagonal caustic / gradient
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradColors = [
        NSColor(srgbRed: 0x2A/255.0, green: 0x1E/255.0, blue: 0x38/255.0, alpha: 1.0).cgColor,
        NSColor(srgbRed: 0x16/255.0, green: 0x10/255.0, blue: 0x1D/255.0, alpha: 1.0).cgColor
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    }

    // 4. Editor Titlebar & Traffic Lights
    let barRect = CGRect(x: size * 0.04, y: size * 0.82, width: size * 0.92, height: size * 0.14)
    ctx.setFillColor(red: 0x1D/255.0, green: 0x16/255.0, blue: 0x27/255.0, alpha: 1.0)
    ctx.fill(barRect)

    let dotRadius = size * 0.022
    let dotY = size * 0.89
    let dotColors: [(CGFloat, CGFloat, CGFloat)] = [
        (0xEE/255.0, 0x76/255.0, 0x6A/255.0), // Coral
        (0xF5/255.0, 0x9E/255.0, 0x0B/255.0), // Amber
        (0x34/255.0, 0xD3/255.0, 0x99/255.0)  // Emerald
    ]
    for (i, c) in dotColors.enumerated() {
        let dotX = size * 0.12 + CGFloat(i) * size * 0.065
        ctx.setFillColor(red: c.0, green: c.1, blue: c.2, alpha: 1.0)
        ctx.fillEllipse(in: CGRect(x: dotX - dotRadius, y: dotY - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
    }

    // 5. Active Tab
    let tabRect = CGRect(x: size * 0.35, y: size * 0.82, width: size * 0.38, height: size * 0.12)
    ctx.setFillColor(red: 0x24/255.0, green: 0x1C/255.0, blue: 0x30/255.0, alpha: 1.0)
    ctx.fill(tabRect)

    // Prismatic accent line on active tab (111iridescence violet & emerald)
    let tabAccent = CGRect(x: size * 0.35, y: size * 0.93, width: size * 0.38, height: size * 0.01)
    ctx.setFillColor(red: 0xA8/255.0, green: 0x55/255.0, blue: 0xF7/255.0, alpha: 1.0)
    ctx.fill(tabAccent)

    // 6. Gutter & Separator
    let gutterLine = CGRect(x: size * 0.22, y: size * 0.08, width: 2, height: size * 0.72)
    ctx.setFillColor(red: 0x35/255.0, green: 0x2C/255.0, blue: 0x40/255.0, alpha: 1.0)
    ctx.fill(gutterLine)

    // 7. Prismatic Code Lines
    let codeLines: [(x: CGFloat, y: CGFloat, w: CGFloat, color: (CGFloat, CGFloat, CGFloat))] = [
        (0.26, 0.72, 0.18, (0xA8/255.0, 0x55/255.0, 0xF7/255.0)), // Violet (keyword)
        (0.48, 0.72, 0.26, (0x34/255.0, 0xD3/255.0, 0x99/255.0)), // Emerald (type/fn)
        (0.30, 0.62, 0.14, (0xEE/255.0, 0x76/255.0, 0x6A/255.0)), // Coral (let)
        (0.47, 0.62, 0.32, (0xED/255.0, 0xE8/255.0, 0xF3/255.0)), // Text
        (0.30, 0.52, 0.44, (0x38/255.0, 0x80/255.0, 0xDC/255.0)), // Blue (call)
        (0.30, 0.42, 0.22, (0xA8/255.0, 0x55/255.0, 0xF7/255.0)), // Violet
        (0.55, 0.42, 0.28, (0xF5/255.0, 0x9E/255.0, 0x0B/255.0)), // Orange
        (0.26, 0.32, 0.08, (0xED/255.0, 0xE8/255.0, 0xF3/255.0)), // }
    ]

    let lineH = size * 0.038
    for line in codeLines {
        let lr = CGRect(x: size * line.x, y: size * line.y, width: size * line.w, height: lineH)
        ctx.setFillColor(red: line.color.0, green: line.color.1, blue: line.color.2, alpha: 1.0)
        let lp = CGPath(roundedRect: lr, cornerWidth: lineH * 0.4, cornerHeight: lineH * 0.4, transform: nil)
        ctx.addPath(lp)
        ctx.fillPath()
    }

    // 8. Prismatic Rim Border (Specular crystal glass)
    ctx.resetClip()
    ctx.addPath(path)
    ctx.setStrokeColor(red: 0xA8/255.0, green: 0x55/255.0, blue: 0xF7/255.0, alpha: 0.35)
    ctx.setLineWidth(size * 0.01)
    ctx.strokePath()

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
