import AppKit
import WebKit

private final class MarkdownSelectionBridge: NSObject, WKScriptMessageHandler {
    weak var owner: MarkdownPreviewView?

    init(owner: MarkdownPreviewView) {
        self.owner = owner
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "quickpadSelection", let text = message.body as? String {
            owner?.onTextSelected?(text)
        }
    }
}

public final class MarkdownPreviewView: NSView {
    private var webView: WKWebView!
    private var lastRenderedMarkdown: String = ""
    private var renderWorkItem: DispatchWorkItem?

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
        let bridge = MarkdownSelectionBridge(owner: self)
        contentController.add(bridge, name: "quickpadSelection")
        config.userContentController = contentController

        webView = WKWebView(frame: bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground") // Transparent background until loaded
        webView.navigationDelegate = self
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

extension MarkdownPreviewView: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            let scheme = url.scheme?.lowercased()
            if scheme == "http" || scheme == "https" || scheme == "mailto" {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}
