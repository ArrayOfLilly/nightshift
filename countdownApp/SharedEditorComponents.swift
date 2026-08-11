//
//  SharedEditorComponents.swift
//  countdownApp
//
//  MarkdownWebView and PlainTextEditor are used by both NotesSheet (slot notes)
//  and SnippetEditSheet (snippets). Keeping them here avoids duplication.
//
//  MarkdownWebView: renders markdown via bundled marked.min.js inside WKWebView.
//  PlainTextEditor: zero-inset NSTextView wrapper — all spacing from call-site padding.
//

import SwiftUI
import WebKit
import AppKit

// MARK: - MarkdownWebView

/// Renders a markdown string as HTML inside a WKWebView.
/// Reloads whenever `markdown` changes.
/// marked.min.js (or marked.umd.js) must be in Copy Bundle Resources.
struct MarkdownWebView: NSViewRepresentable {

    let markdown: String
    /// Called after each page load with the rendered content height (pts).
    /// Used by NotesSheet and SnippetEditSheet to size the VIEW-mode frame.
    var onHeightChange: ((CGFloat) -> Void)? = nil

    func makeNSView(context: Context) -> WKWebView {
        let wv = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        wv.setValue(false, forKey: "drawsBackground")
        wv.navigationDelegate = context.coordinator
        reload(markdown, into: wv)
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        reload(markdown, into: wv)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: MarkdownWebView
        init(_ p: MarkdownWebView) { parent = p }
        func webView(_ wv: WKWebView, didFinish navigation: WKNavigation!) {
            wv.evaluateJavaScript("document.body.scrollHeight") { val, _ in
                guard let raw = val, let h = (raw as? NSNumber)?.doubleValue else { return }
                DispatchQueue.main.async { self.parent.onHeightChange?(CGFloat(h)) }
            }
        }
    }

    private func reload(_ raw: String, into wv: WKWebView) {
        let markedURL = Bundle.main.url(forResource: "marked.min", withExtension: "js")
                     ?? Bundle.main.url(forResource: "marked.umd", withExtension: "js")
        let fontFaceCSS = mozillaHeadlineFontFaceCSS() + robotoFlexFontFaceCSS()
        guard let markedURL,
              let markedJS = try? String(contentsOf: markedURL, encoding: .utf8)
        else {
            let escaped = raw
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: "\n", with: "<br>")
            wv.loadHTMLString(fallbackHTML(escaped, fontFaceCSS: fontFaceCSS),
                              baseURL: Bundle.main.bundleURL)
            return
        }
        let highlighted = applyHighlight(raw)
        let escaped = highlighted
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
        let html = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>\(fontFaceCSS)\(markdownCSS)</style></head><body>
        <script>\(markedJS)</script>
        <script>document.body.innerHTML = marked.parse(`\(escaped)`);</script>
        </body></html>
        """
        wv.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    /// Builds a @font-face block for Mozilla Headline using the bundled variable font file.
    /// Returns an empty string if the font is not found in the app bundle.
    private func mozillaHeadlineFontFaceCSS() -> String {
        guard let resources = Bundle.main.resourceURL else { return "" }
        let fontName = "MozillaHeadline-VariableFont_wdth,wght.ttf"
        let fontURL = resources.appendingPathComponent(fontName)
        guard FileManager.default.fileExists(atPath: fontURL.path) else { return "" }
        return """
        @font-face {
            font-family: 'Mozilla Headline';
            src: url('\(fontURL.absoluteString)') format('truetype');
            font-weight: 100 900;
            font-style: normal;
        }
        """
    }

    /// Builds a @font-face block for Roboto Flex using the bundled variable font file.
    /// Returns an empty string if the font is not found in the app bundle.
    private func robotoFlexFontFaceCSS() -> String {
        guard let resources = Bundle.main.resourceURL else { return "" }
        let fontName = "RobotoFlex-VariableFont_GRAD,XOPQ,XTRA,YOPQ,YTAS,YTDE,YTFI,YTLC,YTUC,opsz,slnt,wdth,wght.ttf"
        let fontURL = resources.appendingPathComponent(fontName)
        guard FileManager.default.fileExists(atPath: fontURL.path) else { return "" }
        return """
        @font-face {
            font-family: 'Roboto Flex';
            src: url('\(fontURL.absoluteString)') format('truetype');
            font-weight: 100 900;
            font-style: normal;
        }
        """
    }

    private func applyHighlight(_ s: String) -> String {
        guard let rx = try? NSRegularExpression(pattern: "==(.+?)==") else { return s }
        return rx.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s),
                                           withTemplate: "<mark>$1</mark>")
    }

    private func fallbackHTML(_ body: String, fontFaceCSS: String = "") -> String {
        "<html><head><style>\(fontFaceCSS)\(markdownCSS)</style></head><body><p>\(body)</p></body></html>"
    }
}

// MARK: - Shared CSS (used by both NotesSheet and SnippetEditSheet)

let markdownCSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
    background: #060503;
    color: rgba(255,255,255,0.85);
    font-family: 'Mozilla Headline', 'Helvetica Neue', sans-serif;
    font-size: 14px;
    line-height: 1.65;
    padding: 20px 24px 40px;
}
h1, h2, h3 {
    color: #F5A623;
    font-family: 'AlienLeagueBold', 'Alien League Bold', system-ui;
    margin-top: 1.2em; margin-bottom: 0.4em; letter-spacing: 1px;
}
h1 { font-size: 20px; } h2 { font-size: 16px; } h3 { font-size: 14px; }
p { margin-bottom: 0.8em; }
ul, ol { padding-left: 1.4em; margin-bottom: 0.8em; }
li { margin-bottom: 0.2em; }
code { background: rgba(255,255,255,0.08); border-radius: 4px; padding: 1px 5px; font-size: 12px; color: #F5A623; font-family: 'Menlo', 'Monaco', 'Courier New', monospace; }
pre { background: rgba(255,255,255,0.07); border-left: 3px solid #F5A623; border-radius: 6px;
      padding: 12px 14px; overflow-x: auto; margin-bottom: 0.9em; }
pre code { background: none; padding: 0; color: #F5A623; font-family: 'Menlo', 'Monaco', 'Courier New', monospace; }
mark { background: rgba(245,166,35,0.35); color: #fff; border-radius: 3px; padding: 0 3px; }
table { border-collapse: collapse; width: 100%; margin-bottom: 0.9em; }
th, td { border: 1px solid rgba(255,255,255,0.18); padding: 6px 10px; text-align: left; }
tr:nth-child(even) { background: rgba(255,255,255,0.04); }
a { color: #F5A623; }
"""

// MARK: - PlainTextEditor

/// Zero-inset NSTextView wrapper. SwiftUI's TextEditor cannot zero its internal
/// textContainerInset, causing misalignment vs WKWebView padding.
/// All spacing must come from SwiftUI .padding() at the call site.
struct PlainTextEditor: NSViewRepresentable {

    @Binding var text: String
    var font: NSFont
    var textColor: NSColor
    var inset: NSSize = .zero
    /// Extra vertical spacing added between lines, on top of the font's
    /// natural line height (NSParagraphStyle.lineSpacing). 0 = unchanged
    /// default NSTextView spacing. Since this is a plain-text editor (raw
    /// markdown source, no paragraph/line distinction the way rendered
    /// markdown has), this applies uniformly to every line break — there's
    /// no way to target only blank-line-separated "paragraphs" without
    /// also affecting single line breaks, since NSTextView treats every
    /// line as its own paragraph in plain-text mode.
    var lineSpacing: CGFloat = 0

    private var paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        return style
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tv = NSTextView()
        tv.delegate = context.coordinator
        tv.font = font
        tv.textColor = textColor
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        tv.isRichText = false
        tv.allowsUndo = true
        tv.textContainerInset = inset
        tv.textContainer?.lineFragmentPadding = 0
        tv.selectedTextAttributes = [
            .backgroundColor: NSColor.white.withAlphaComponent(0.18),
            .foregroundColor: NSColor(AppTheme.background)
        ]
        tv.textContainer?.widthTracksTextView = true
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]

        // Apply lineSpacing to future typed text (typingAttributes /
        // defaultParagraphStyle), then set the initial string and
        // re-apply the same paragraph style across its full range —
        // `tv.string =` does not retroactively pick up typingAttributes
        // for characters that already existed in the assigned string.
        tv.defaultParagraphStyle = paragraphStyle
        tv.typingAttributes[.paragraphStyle] = paragraphStyle
        tv.string = text
        if let storage = tv.textStorage, storage.length > 0 {
            storage.addAttribute(.paragraphStyle, value: paragraphStyle,
                                  range: NSRange(location: 0, length: storage.length))
        }

        let sv = NSScrollView()
        sv.documentView = tv
        sv.hasVerticalScroller = true
        sv.drawsBackground = false
        sv.borderType = .noBorder
        return sv
    }

    func updateNSView(_ sv: NSScrollView, context: Context) {
        guard let tv = sv.documentView as? NSTextView, tv.string != text else { return }
        tv.string = text
        if let storage = tv.textStorage, storage.length > 0 {
            storage.addAttribute(.paragraphStyle, value: paragraphStyle,
                                  range: NSRange(location: 0, length: storage.length))
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        init(_ p: PlainTextEditor) { self.parent = p }
        func textDidChange(_ n: Notification) {
            guard let tv = n.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}
