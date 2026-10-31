import AppKit
import WebKit

private final class HTMLSelectionBridge: NSObject, WKScriptMessageHandler {
    weak var owner: HTMLPreviewView?

    init(owner: HTMLPreviewView) {
        self.owner = owner
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "quickpadSelection", let text = message.body as? String {
            owner?.onTextSelected?(text)
        }
    }
}

public final class HTMLPreviewView: NSView {
    private var webView: WKWebView!
    private var lastRawHTML: String = ""

    public var onTextSelected: ((String) -> Void)?

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
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let contentController = WKUserContentController()
        let bridge = HTMLSelectionBridge(owner: self)
        contentController.add(bridge, name: "quickpadSelection")

        let script = """
        document.addEventListener('selectionchange', function() {
            clearTimeout(window.__qpSelTimer);
            window.__qpSelTimer = setTimeout(function() {
                var sel = window.getSelection();
                var text = sel ? sel.toString().trim() : '';
                if (text.length > 0 && window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.quickpadSelection) {
                    window.webkit.messageHandlers.quickpadSelection.postMessage(text);
                }
            }, 60);
        });
        """
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        config.userContentController = contentController

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
