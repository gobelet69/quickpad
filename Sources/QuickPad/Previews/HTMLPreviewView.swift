import AppKit
import WebKit

public final class HTMLPreviewView: NSView {
    private var webView: WKWebView!
    private var lastRawHTML: String = ""

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
        prefs.allowsContentJavaScript = false // JavaScript strictly disabled
        config.defaultWebpagePreferences = prefs

        webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        addSubview(webView)
    }

    public func update(html: String) {
        guard html != lastRawHTML else { return }
        lastRawHTML = html

        // Safe rendering with sandbox base URL
        webView.loadHTMLString(html, baseURL: nil)
    }
}
