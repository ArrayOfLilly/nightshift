//
//  SnippetEditSheet.swift
//  countdownApp
//
//  Snippet editor — identical structure to NotesSheet:
//    VIEW mode (MarkdownWebView) / EDIT mode (PlainTextEditor) toggle,
//    Copy / Edit-toggle / Trash / Dismiss header buttons.
//  Extra vs NotesSheet: editable Title + Project field (custom SwiftUI
//  TextField + popover dropdown, fully themed to AppTheme.dark).
//
//  MarkdownWebView and PlainTextEditor come from SharedEditorComponents.swift.
//  Snippet is nil for new entries; non-nil for editing an existing one.
//  onSave is called with the final Snippet; onDelete (if provided) with its id.
//
//  FIX (Session G): VIEW mode MarkdownWebView wrapped in VStack to resolve
//  NSViewRepresentable .frame() overload ambiguity.
//
//  FIX (Session G-2): Title TextField auto-focus suppressed via FocusState (never activated).
//  FIX (Session H-2): onAppear makeFirstResponder removed — it caused a QoS priority inversion
//  warning (AppKit internals block User-Interactive main thread on Default-QoS work).
//  Using .focused($titleFocused) with titleFocused always false suppresses auto-focus cleanly.
//
//  DESIGN (Session G-3): Sheet is fixed height, no JS-driven resize.
//  Empty / EDIT mode: 520pt. VIEW mode with content: 680pt.
//  MarkdownWebView fills available area and scrolls internally.
//

import SwiftUI
import AppKit

// MARK: - Project field (custom themed TextField + suggestion popover)

private struct ProjectField: View {

    @Binding var text: String
    let suggestions: [String]
    @State private var showSuggestions = false

    var body: some View {
        HStack(spacing: 0) {
            TextField("Project", text: $text)
                .font(AppTheme.alienLeague(13))
                .foregroundStyle(Color.white)
                .textFieldStyle(.plain)
                .padding(.leading, 8)
            Button {
                showSuggestions.toggle()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .popover(isPresented: $showSuggestions, arrowEdge: .bottom) {
                suggestionList
            }
        }
        .frame(height: 28)
        .background(AppTheme.dark)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggestions, id: \.self) { s in
                Button {
                    text = s
                    showSuggestions = false
                } label: {
                    Text(s)
                        .font(AppTheme.alienLeague(13))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                if s != suggestions.last {
                    Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1)
                }
            }
        }
        .frame(minWidth: 220)
        .background(AppTheme.calculateBackground)
    }
}

// MARK: - SnippetEditSheet

struct SnippetEditSheet: View {

    let snippet: Snippet?
    let existingProjects: [String]
    let onSave: (Snippet) -> Void
    let onDelete: ((UUID) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var title:       String
    @State private var project:     String
    @State private var snippetBody: String

    @State private var isEditing       = true
    @State private var copyFeedback    = false
    @State private var showDeleteAlert = false
    @FocusState private var titleFocused: Bool

    init(snippet: Snippet?,
         existingProjects: [String],
         onSave: @escaping (Snippet) -> Void,
         onDelete: ((UUID) -> Void)?) {
        self.snippet          = snippet
        self.existingProjects = existingProjects
        self.onSave           = onSave
        self.onDelete         = onDelete
        _title       = State(initialValue: snippet?.title   ?? "")
        _project     = State(initialValue: snippet?.project ?? "")
        _snippetBody = State(initialValue: snippet?.body    ?? "")
        _isEditing   = State(initialValue: snippet == nil || (snippet?.body ?? "").isEmpty)
    }

    /// Sheet height: always 680 — does not change on VIEW/EDIT toggle.
    private var sheetMinHeight: CGFloat { 680 }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.horizontal, 24)
                contentArea
            }
        }
        .frame(minWidth: 480, minHeight: sheetMinHeight)
        .alert("Delete snippet?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = snippet?.id { onDelete?(id) }
                dismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 0) {
                TextField("Title", text: $title)
                    .font(AppTheme.alienLeagueBold(22))
                    .foregroundStyle(AppTheme.dark)
                    .textFieldStyle(.plain)
                    .focused($titleFocused)
                Spacer()
                HStack(spacing: 8) {
                    headerButton(icon: copyFeedback ? "checkmark" : "doc.on.doc",
                                 tint: copyFeedback ? AppTheme.background : Color.white.opacity(0.7)) {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(snippetBody, forType: .string)
                        copyFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { copyFeedback = false }
                    }
                    headerButton(icon: isEditing ? "checkmark" : "pencil") { isEditing.toggle() }
                    if onDelete != nil {
                        headerButton(icon: "trash") { showDeleteAlert = true }
                    }
                }
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 22).padding(.horizontal, 6)
                headerButton(icon: "xmark") { commitSave(); dismiss() }
            }

            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.dark.opacity(0.55))
                ProjectField(text: $project, suggestions: existingProjects)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 22)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private func headerButton(icon: String,
                              tint: Color = Color.white.opacity(0.7),
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        if isEditing {
            PlainTextEditor(
                text: $snippetBody,
                font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                textColor: NSColor(AppTheme.background),
                inset: NSSize(width: 24, height: 20)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.calculateBackground)
        } else if snippetBody.isEmpty {
            Button { isEditing = true } label: {
                VStack(spacing: 12) {
                    Image(systemName: "doc.plaintext.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.white.opacity(0.4))
                    Text("Tap to start writing.")
                        .font(AppTheme.alienLeague(13))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
        } else {
            VStack(spacing: 0) {
                MarkdownWebView(markdown: snippetBody)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Persistence

    private func commitSave() {
        guard !title.isEmpty || !snippetBody.isEmpty else { return }
        var s = snippet ?? Snippet(title: "", body: "", project: "")
        s.title     = title.trimmingCharacters(in: .whitespaces)
        s.body      = snippetBody
        s.project   = project.trimmingCharacters(in: .whitespaces).isEmpty ? "General" : project.trimmingCharacters(in: .whitespaces)
        s.updatedAt = Date()
        onSave(s)
    }
}
