//
//  NotesSheet.swift
//  countdownApp
//
//  Per-slot notes modal with VIEW (WKWebView markdown render) and EDIT (PlainTextEditor) modes.
//  Triggered from CountdownDetailView via a notes button.
//
//  MarkdownWebView and PlainTextEditor live in SharedEditorComponents.swift.
//
//  EDIT mode uses a local `draft` @State buffer. Changes are flushed to the `notes`
//  @Binding (and thus to UserDefaults) with a ~500 ms debounce to avoid per-keystroke
//  JSON encode + disk write of the entire items array. See SharedEditorComponents for editor details.
//  Copy button: copies raw markdown to NSPasteboard, 1 s checkmark feedback.
//  Trash button: clears notes string after confirmation alert.
//
//  DESIGN (Session H): Sheet is fixed height, no JS-driven resize.
//  Empty / EDIT mode: 360pt. VIEW mode with content: 520pt.
//  MarkdownWebView fills available area and scrolls internally.
//

import SwiftUI
import AppKit

struct NotesSheet: View {

    let slotLabel: String
    @Binding var notes: String
    @Environment(\.dismiss) private var dismiss

    /// Local buffer for EDIT mode. Flushed to the `notes` @Binding with a debounce.
    @State private var draft:            String = ""
    @State private var debounceTask:     Task<Void, Never>? = nil
    @State private var isEditing         = false
    @State private var showDeleteConfirm = false
    // FIX (Session N, ported from SnippetEditSheet): sheet width now tracks
    // the real window width instead of a static maxWidth: 900, so it can
    // never overhang the window edges when the window is narrower than 900pt.
    @State private var sheetWidth: CGFloat = 700

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Rectangle().fill(Color.white.opacity(AppTheme.alpha08)).frame(height: 1).padding(.horizontal, 24)
                contentArea
            }
        }
        // Always 520pt — does not change on VIEW/EDIT toggle.
        // FIX: width now tracks the real window width (computed on appear),
        // clamped between 450 (usable floor) and 900 (design ceiling), and
        // always at least `windowMargin` narrower than the window itself.
        // minWidth/maxWidth set to the same value rather than the `width:`
        // fixed-size overload, because that overload can't take `minHeight:`
        // in the same call.
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth, minHeight: 520)
        .onAppear {
            draft = notes
            updateSheetWidth()
        }
        .onChange(of: draft) { _, newValue in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }
                notes = newValue
            }
        }
        .alert("Delete all notes?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { notes = ""; draft = "" }
        } message: {
            Text("This clears the notes for this slot. This cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("NOTES")
                .font(AppTheme.alienLeagueBold(24))
                .foregroundStyle(AppTheme.dark)
                .kerning(2)
            Spacer()
            HStack(spacing: 8) {
                CopyButton(
                    value: draft,
                    defaultAccessibilityLabel: "Copy notes",
                    copiedAccessibilityLabel: "Notes copied"
                ) { isCopied in
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isCopied ? AppTheme.background : Color.white.opacity(AppTheme.alpha75))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(AppTheme.alpha12))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                }
                headerButton(icon: isEditing ? "checkmark" : "pencil",
                             label: isEditing ? "Done editing" : "Edit notes") { isEditing.toggle() }
                headerButton(icon: "trash", label: "Delete notes") { showDeleteConfirm = true }
            }
            Rectangle().fill(Color.white.opacity(AppTheme.alpha12)).frame(width: 1, height: 22).padding(.horizontal, 6)
            headerButton(icon: "xmark", label: "Close") { dismiss() }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func headerButton(icon: String,
                              tint: Color = Color.white.opacity(AppTheme.alpha75),
                              label: String,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(AppTheme.alpha12))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .accessibilityLabel(label)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if isEditing {
            PlainTextEditor(
                text: $draft,
                font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                textColor: NSColor(AppTheme.background),
                inset: NSSize(width: 24, height: 20),
                lineSpacing: 5
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.calculateBackground)
        } else if notes.isEmpty {
            Button { isEditing = true } label: {
                VStack(spacing: 12) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text("No notes yet.\nTap to start writing.")
                        .font(AppTheme.alienLeague(13))
                        .foregroundStyle(Color.white.opacity(AppTheme.alpha60))
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

    // MARK: - Sizing

    /// Reads the presenting (main) window's current width and derives the
    /// sheet width from it: window width minus `windowMargin`, clamped to
    /// [450, AppTheme.windowMaxWidth]. `NSApp.mainWindow` is used rather than `keyWindow`
    /// because once the sheet is presented, the sheet's own child window
    /// can become key — the underlying content window stays main.
    private func updateSheetWidth() {
        sheetWidth = WindowHelpers.windowConstrainedWidth(min: 450, max: AppTheme.windowMaxWidth)
    }
}
