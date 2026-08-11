//
//  NotesSheet.swift
//  countdownApp
//
//  Per-slot notes modal with VIEW (WKWebView markdown render) and EDIT (TextEditor) modes.
//  Triggered from CountdownDetailView via a notes button.
//
//  VIEW mode  : WKWebView renders markdown via bundled marked.min.js; custom CSS matches
//               the app's spooky-tomato theme (dark bg, amber headings, code blocks).
//  EDIT mode  : Plain TextEditor bound DIRECTLY to the `notes` @Binding (no draft/commit
//               buffer). Every keystroke writes straight through to the caller's source
//               of truth (item.notes in CountdownDetailView). This is intentional: an
//               earlier draft-buffer design only committed on explicit pencil/eye-toggle
//               or the in-sheet X button, so closing the sheet via macOS system gestures
//               (Escape, red traffic-light button) bypassed the commit and silently
//               dropped typed text — and left the outer notes-indicator icon
//               (note.text.badge.plus ↔ note.text) permanently stuck on its initial state.
//  Copy button: Always copies the raw markdown string to NSPasteboard (not the HTML).
//               Provides 1 s checkmark feedback.
//  Trash button: Clears the entire notes string, gated behind a confirmation
//               alert ("Delete all notes?" / Cancel / Delete-destructive).
//
//  Markdown support:
//    headings (#/##/###), bullet/numbered lists, inline code, fenced code blocks,
//    tables, and ==highlight== (pre-processed to <mark> before marked.js parse).
//
//  marked.min.js must be added to the Xcode project as a bundled resource.
//  It is loaded from Bundle.main — never from a CDN (App Sandbox safety).
//

import SwiftUI
import WebKit
import AppKit

// MARK: - WKWebView representable

/// Renders a markdown string as HTML inside a WKWebView.
/// The view re-loads whenever `markdown` changes.
private struct MarkdownWebView: NSViewRepresentable {

    let markdown: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        load(markdown, into: wv)
        return wv
    }

    func updateNSView(_ wv: WKWebView, context: Context) {
        load(markdown, into: wv)
    }

    private func load(_ raw: String, into wv: WKWebView) {
        let markedURL = Bundle.main.url(forResource: "marked.min", withExtension: "js")
                     ?? Bundle.main.url(forResource: "marked.umd", withExtension: "js")
        guard let markedURL,
              let markedJS = try? String(contentsOf: markedURL, encoding: .utf8)
        else {
            let escaped = raw
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: "\n", with: "<br>")
            wv.loadHTMLString(fallbackHTML(escaped), baseURL: nil)
            return
        }

        let highlighted = applyHighlight(raw)
        let escaped = highlighted
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")

        let html = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>\(css)</style></head><body>
        <script>\(markedJS)</script>
        <script>
          var raw = `\(escaped)`;
          document.body.innerHTML = marked.parse(raw);
        </script>
        </body></html>
        """
        wv.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    private func applyHighlight(_ s: String) -> String {
        guard let rx = try? NSRegularExpression(pattern: "==(.+?)==", options: []) else { return s }
        let ns = s as NSString
        let range = NSRange(location: 0, length: ns.length)
        return rx.stringByReplacingMatches(in: s, options: [], range: range,
                                           withTemplate: "<mark>$1</mark>")
    }

    private func fallbackHTML(_ body: String) -> String {
        // NOTE: called only when marked.min.js / marked.umd.js is absent from the bundle.
        // The caller already HTML-escapes the body and converts \n → <br>.
        "<html><head><style>\(css)</style></head><body><p>\(body)</p></body></html>"
    }

    private var css: String { """
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            background: #2A2015;
            color: rgba(255,255,255,0.85);
            font-family: 'Roboto Flex', 'Menlo', monospace;
            font-size: 13px;
            line-height: 1.65;
            padding: 20px 24px 40px;
        }
        h1, h2, h3 {
            color: #F5A623;
            font-family: 'AlienLeagueBold', 'Alien League Bold', system-ui;
            margin-top: 1.2em;
            margin-bottom: 0.4em;
            letter-spacing: 1px;
        }
        h1 { font-size: 20px; }
        h2 { font-size: 16px; }
        h3 { font-size: 14px; }
        p  { margin-bottom: 0.8em; }
        ul, ol { padding-left: 1.4em; margin-bottom: 0.8em; }
        li { margin-bottom: 0.2em; }
        code {
            background: rgba(255,255,255,0.08);
            border-radius: 4px;
            padding: 1px 5px;
            font-size: 12px;
        }
        pre {
            background: rgba(0,0,0,0.45);
            border-left: 3px solid #F5A623;
            border-radius: 6px;
            padding: 12px 14px;
            overflow-x: auto;
            margin-bottom: 0.9em;
        }
        pre code { background: none; padding: 0; }
        mark {
            background: rgba(245,166,35,0.35);
            color: #fff;
            border-radius: 3px;
            padding: 0 3px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 0.9em;
        }
        th, td {
            border: 1px solid rgba(255,255,255,0.18);
            padding: 6px 10px;
            text-align: left;
        }
        tr:nth-child(even) { background: rgba(255,255,255,0.04); }
        a { color: #F5A623; }
    """ }
}

// MARK: - Plain text editor (zero inset)

/// A minimal NSTextView wrapper with `textContainerInset` and line-fragment
/// padding zeroed out. SwiftUI's built-in `TextEditor` cannot have its
/// internal NSTextView inset removed — it always adds a few extra points of
/// padding beyond whatever `.padding()` is applied outside it, which made
/// EDIT mode text start further right/down than VIEW mode's WKWebView
/// (which we fully control via CSS `padding`). This wrapper gives pixel-exact
/// alignment: all spacing comes from the SwiftUI `.padding()` calls at the
/// call site, none from the text view itself.
private struct PlainTextEditor: NSViewRepresentable {

    @Binding var text: String
    var font: NSFont
    var textColor: NSColor
    /// Internal padding for the text view — mirrors the CSS `padding` used in the
    /// VIEW-mode WKWebView. SwiftUI `.padding()` only shifts the outer frame; it
    /// cannot push text away from the NSTextView's own edges. Setting
    /// `textContainerInset` here gives pixel-accurate alignment between EDIT and
    /// VIEW modes. NSSize(width:height:) is symmetric (left/right = width,
    /// top/bottom = height); the scroll view naturally handles bottom overscroll.
    var inset: NSSize = .zero

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = font
        textView.textColor = textColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isRichText = false
        textView.allowsUndo = true
        textView.textContainerInset = inset
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        init(_ parent: PlainTextEditor) { self.parent = parent }
        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}

// MARK: - NotesSheet

struct NotesSheet: View {

    let slotLabel: String
    @Binding var notes: String
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing: Bool = false
    @State private var copyFeedback: Bool = false
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ──────────────────────────────────────────────
                HStack(alignment: .center, spacing: 0) {
                    Text("NOTES")
                        .font(AppTheme.alienLeagueBold(24))
                        .foregroundStyle(AppTheme.dark.opacity(1.0))
                        .kerning(2)

                    Spacer()

                    HStack(spacing: 14) {
                        HStack(spacing: 8) {
                            // Copy raw markdown
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(notes, forType: .string)
                                copyFeedback = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    copyFeedback = false
                                }
                            } label: {
                                Image(systemName: copyFeedback ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(copyFeedback ? AppTheme.background : Color.white.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                                .buttonStyle(.plain)
                                .focusable(false)

                            // VIEW / EDIT toggle
                            Button {
                                isEditing.toggle()
                            } label: {
                                Image(systemName: isEditing ? "checkmark" : "pencil")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                                .buttonStyle(.plain)
                                .focusable(false)

                            // Delete all notes (with confirmation)
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                    .frame(width: 36, height: 36)
                                    .background(Color.white.opacity(0.07))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                                .buttonStyle(.plain)
                                .focusable(false)
                        }

                        // Separator — Dismiss is a different kind of action
                        // (leaves the sheet, doesn't touch note content) so it's
                        // visually cut off from the content-action cluster above.
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1, height: 22)

                        // Dismiss
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.5))
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                            .buttonStyle(.plain)
                            .focusable(false)
                    }
                }
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 14)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 24)

                // ── Content ─────────────────────────────────────────────
                if isEditing {
                    PlainTextEditor(
                        text: $notes,
                        font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                        textColor: NSColor(AppTheme.background),
                        inset: NSSize(width: 24, height: 20) // mirrors CSS body { padding: 20px 24px 40px }
                    )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppTheme.dark)
                } else {
                    if notes.isEmpty {
                        Button {
                            isEditing = true
                        } label: {
                            VStack(spacing: 12) {
                                Image(systemName: "note.text.badge.plus")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.white.opacity(0.4))
                                Text("No notes yet.\nTap to start writing.")
                                    .font(AppTheme.alienLeague(13))
                                    .foregroundStyle(Color.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                            .buttonStyle(.plain)
                            .focusable(false)
                    } else {
                        MarkdownWebView(markdown: notes)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
            .frame(minWidth: 480, minHeight: 360)
            .alert("Delete all notes?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                notes = ""
            }
        } message: {
            Text("This clears the notes for this slot. This cannot be undone.")
        }
    }
}
