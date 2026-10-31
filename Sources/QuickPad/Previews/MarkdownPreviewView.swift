import AppKit
import WebKit

public final class MarkdownPreviewView: NSView {
    private var webView: WKWebView!
    private var lastRenderedMarkdown: String = ""
    private var renderWorkItem: DispatchWorkItem?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupWebView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false // Strictly disable JS for security
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground") // Transparent background until loaded
        addSubview(webView)
    }

    public func update(markdown: String, debounce: Bool = true) {
        guard markdown != lastRenderedMarkdown else { return }

        renderWorkItem?.cancel()

        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let delay: TimeInterval = debounce ? 0.15 : 0.0

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.lastRenderedMarkdown = markdown
            let html = MarkdownParser.toHTML(markdown: markdown, isDark: isDark)
            DispatchQueue.main.async {
                self.webView.loadHTMLString(html, baseURL: nil)
            }
        }

        renderWorkItem = workItem
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        } else {
            workItem.perform()
        }
    }

    public override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        // Re-render when switching between dark and light modes
        let current = lastRenderedMarkdown
        lastRenderedMarkdown = ""
        update(markdown: current, debounce: false)
    }
}
