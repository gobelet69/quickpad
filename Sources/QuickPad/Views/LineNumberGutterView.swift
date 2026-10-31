import AppKit

public final class LineNumberGutterView: NSView {
    public weak var textView: NSTextView?
    private var digitCount: Int = 1

    public override var isFlipped: Bool { true }

    public init(textView: NSTextView) {
        self.textView = textView
        super.init(frame: .zero)
        self.wantsLayer = true
        self.layer?.masksToBounds = true
        self.layer?.backgroundColor = Theme.gutterBackground.cgColor
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func updateWidth() {
        guard let text = textView?.string else { return }
        let lineCount = text.reduce(1) { $1 == "\n" ? $0 + 1 : $0 }
        let digits = max(3, "\(lineCount)".count)
        if digits != digitCount {
            digitCount = digits
            let charWidth: CGFloat = 7.5
            let newWidth = max(36.0, CGFloat(digits) * charWidth + 18.0)
            if frame.width != newWidth {
                frame.size.width = newWidth
                needsDisplay = true
            }
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let textView = textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let scrollView = textView.enclosingScrollView else {
            return
        }

        let gutterRect = bounds.intersection(dirtyRect)
        guard !gutterRect.isEmpty else { return }

        // Draw gutter background within bounds only
        Theme.gutterBackground.setFill()
        gutterRect.fill()

        // Draw separator border within bounds
        Theme.border.setStroke()
        let borderPath = NSBezierPath()
        borderPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
        borderPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
        borderPath.lineWidth = 1.0
        borderPath.stroke()

        let visibleRect = scrollView.contentView.bounds
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let textNSString = textView.string as NSString

        guard glyphRange.length > 0 && glyphRange.location != NSNotFound else { return }

        // Find active line number
        let selectedRange = textView.selectedRange()
        let activeLineNumber: Int
        if selectedRange.location != NSNotFound && selectedRange.location <= textNSString.length {
            var activeLine = 1
            textNSString.enumerateSubstrings(in: NSRange(location: 0, length: selectedRange.location), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
                activeLine += 1
            }
            activeLineNumber = activeLine
        } else {
            activeLineNumber = 1
        }

        // Count lines up to visible start
        let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        var lineNumber = 1
        textNSString.enumerateSubstrings(in: NSRange(location: 0, length: characterRange.location), options: [.byLines, .substringNotRequired]) { _, _, _, _ in
            lineNumber += 1
        }

        let font = Theme.gutterFont
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: Theme.gutterText
        ]
        let activeAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: Theme.foreground
        ]

        var glyphIndex = glyphRange.location
        while glyphIndex < NSMaxRange(glyphRange) {
            var lineRange = NSRange()
            let rect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &lineRange)
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

            // Draw line number at the start of actual lines (not wrapped continuations)
            if charIndex == 0 || textNSString.character(at: charIndex - 1) == 0x0A {
                let isActive = lineNumber == activeLineNumber
                let numStr = "\(lineNumber)"
                let attrs = isActive ? activeAttrs : normalAttrs
                let size = (numStr as NSString).size(withAttributes: attrs)

                let y = rect.minY + (rect.height - size.height) / 2.0 - visibleRect.minY + textView.textContainerInset.height
                let x = bounds.width - size.width - 8.0

                if y >= bounds.minY - size.height && y <= bounds.maxY {
                    (numStr as NSString).draw(at: NSPoint(x: x, y: y), withAttributes: attrs)
                }
                lineNumber += 1
            }

            glyphIndex = NSMaxRange(lineRange)
        }
    }
}
