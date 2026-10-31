import AppKit

public final class PreviewContainerView: NSView {
    private var markdownView: MarkdownPreviewView?
    private var jsonView: JSONInspectorView?
    private var csvView: CSVTableView?
    private var structuredView: StructuredTreePreviewView?
    private var htmlView: HTMLPreviewView?
    private var emptyPlaceholderLabel: NSTextField!

    public var onFormatJSONRequested: (() -> Void)?
    public var onTextSelected: ((String) -> Void)?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = Theme.background.cgColor

        emptyPlaceholderLabel = NSTextField(labelWithString: "No preview available for this file type.")
        emptyPlaceholderLabel.font = Theme.uiFont
        emptyPlaceholderLabel.textColor = Theme.textMuted
        emptyPlaceholderLabel.alignment = .center
        emptyPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(emptyPlaceholderLabel)

        NSLayoutConstraint.activate([
            emptyPlaceholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emptyPlaceholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    public func update(document: Document) {
        guard let kind = document.language.previewKind else {
            showView(nil)
            emptyPlaceholderLabel.isHidden = false
            return
        }

        emptyPlaceholderLabel.isHidden = true

        switch kind {
        case .markdown:
            if markdownView == nil {
                let mv = MarkdownPreviewView(frame: bounds)
                mv.autoresizingMask = [.width, .height]
                mv.onTextSelected = { [weak self] text in
                    self?.onTextSelected?(text)
                }
                markdownView = mv
            }
            showView(markdownView)
            markdownView?.update(markdown: document.content)

        case .json:
            if jsonView == nil {
                let jv = JSONInspectorView(frame: bounds)
                jv.autoresizingMask = [.width, .height]
                jv.onFormatRequested = { [weak self] in
                    self?.onFormatJSONRequested?()
                }
                jsonView = jv
            }
            showView(jsonView)
            jsonView?.update(jsonText: document.content)

        case .csv(let isTSV):
            if csvView == nil {
                let cv = CSVTableView(frame: bounds)
                cv.autoresizingMask = [.width, .height]
                csvView = cv
            }
            showView(csvView)
            csvView?.update(csvText: document.content, isTSV: isTSV)

        case .structured(let format):
            if structuredView == nil {
                let sv = StructuredTreePreviewView(frame: bounds)
                sv.autoresizingMask = [.width, .height]
                structuredView = sv
            }
            showView(structuredView)
            structuredView?.update(text: document.content, format: format)

        case .html:
            if htmlView == nil {
                let hv = HTMLPreviewView(frame: bounds)
                hv.autoresizingMask = [.width, .height]
                hv.onTextSelected = { [weak self] text in
                    self?.onTextSelected?(text)
                }
                htmlView = hv
            }
            showView(htmlView)
            htmlView?.update(html: document.content)
        }
    }

    private func showView(_ targetView: NSView?) {
        let allViews: [NSView?] = [markdownView, jsonView, csvView, structuredView, htmlView]
        for v in allViews {
            guard let v = v else { continue }
            if v === targetView {
                if v.superview == nil {
                    addSubview(v)
                }
                v.isHidden = false
                v.frame = bounds
            } else {
                v.isHidden = true
            }
        }
    }
}
