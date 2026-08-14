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
//  FIX (Session K): Title TextField gets .focusable(false) — AppKit will not make it first
//  responder on open, so no auto-selection occurs. @FocusState titleFocused removed (was
//  always false and did nothing). Previous onAppear/asyncAfter workaround also removed.
//
//  DESIGN (Session G-3): Sheet height does not change on VIEW/EDIT toggle,
//  no JS-driven resize. MarkdownWebView fills available area and scrolls
//  internally.
//  UPDATE (refactor G-2): height is no longer hardcoded 680 — it's derived
//  from the main window's height at presentation time (updateSheetSize()),
//  capped at 680 and floored at 400, so short displays scroll/fit instead
//  of clipping.
//
//  Save/dismiss logic (Session AZ + BUG-CHECKMARKDIRTY-1 fix):
//    Checkmark (EDIT mode): commitSave() + refreshes dirty baseline + switches to VIEW mode.
//    Pencil (VIEW mode): switches to EDIT mode.
//    X button — clean state (no field differs from original): dismisses immediately.
//    X button — dirty state (any field differs): confirm alert with three options:
//      "Cancel" stays in sheet; "Quit without saving" discards and dismisses;
//      "Save and quit" calls commitSave() then dismisses.
//    Dirty baseline: originalTitle/originalProject/originalBody — var so commitEdit() can
//    refresh them after saving, ensuring a subsequent X sees clean state.
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
                    .foregroundStyle(Color.white.opacity(AppTheme.alpha50))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .frame(width: 36)
            .buttonStyle(.plain)
            .focusable(false)
            .accessibilityLabel("Show project suggestions")
            .popover(isPresented: $showSuggestions, arrowEdge: .bottom) {
                suggestionList
            }
        }
        .frame(height: 28)
        .background(AppTheme.freeColors[10])
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall))
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
                        .foregroundStyle(Color.white.opacity(AppTheme.alpha90))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                if s != suggestions.last {
                    Rectangle().fill(Color.white.opacity(AppTheme.alpha08)).frame(height: 1)
                }
            }
        }
        .frame(minWidth: 320)
        .background(AppTheme.freeColors[6])
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

    @State private var isEditing              = true
    @State private var showDeleteConfirm      = false
    @State private var showDismissConfirm     = false
    /// Set to false before a discard-dismiss so .onDisappear does not auto-save.
    @State private var shouldSaveOnDisappear  = true
    // FIX: sheet width was a fixed maxWidth: 900, which could exceed the
    // actual window width when the window is narrower than 900pt (the
    // sheet then visibly overhangs both edges). Now computed from the
    // real main window width at presentation time, always kept a small
    // margin narrower than the window.
    @State private var sheetWidth: CGFloat = 700

    /// Baseline values captured at init time; @State so commitEdit() can refresh them after an
    /// explicit save (checkmark), ensuring a subsequent X sees a clean state.
    @State private var originalTitle:   String
    @State private var originalProject: String
    @State private var originalBody:    String

    init(snippet: Snippet?,
         existingProjects: [String],
         onSave: @escaping (Snippet) -> Void,
         onDelete: ((UUID) -> Void)?) {
        self.snippet          = snippet
        self.existingProjects = existingProjects
        self.onSave           = onSave
        self.onDelete         = onDelete
        let t = snippet?.title   ?? ""
        let p = snippet?.project ?? ""
        let b = snippet?.body    ?? ""
        _title       = State(initialValue: t)
        _project     = State(initialValue: p)
        _snippetBody = State(initialValue: b)
        _isEditing   = State(initialValue: snippet == nil || b.isEmpty)
        originalTitle   = t
        originalProject = p
        originalBody    = b
    }

    private var isDirty: Bool {
        title != originalTitle || project != originalProject || snippetBody != originalBody
    }

    // G-2: sheet height was a fixed 680, which clipped on short displays.
    // Now computed from the main window's height at presentation time,
    // capped at 680 (design ceiling) and floored at 400 (usable minimum
    // for header + content), same clamp pattern as sheetWidth below.
    @State private var sheetHeight: CGFloat = 680

    /// Margin the sheet stays inside the window edges by, on each side is
    /// implied (this value is the *total* width subtracted, i.e. applied
    /// once against the full window width — window is always wider than
    /// the sheet by at least this much).
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                Rectangle().fill(Color.white.opacity(AppTheme.alpha08)).frame(height: 1).padding(.horizontal, 24)
                contentArea
            }
        }
        // FIX: width now tracks the real window width (computed on appear),
        // clamped between 450 (usable floor) and 900 (design ceiling), and
        // always at least `windowMargin` narrower than the window itself —
        // it can never overhang the window edges anymore.
        // NOTE: minWidth/maxWidth set to the same value (rather than the
        // `width:` fixed-size overload) because that overload doesn't
        // accept `minHeight:` in the same call.
        .frame(minWidth: sheetWidth, maxWidth: sheetWidth, minHeight: sheetHeight)
        .onAppear { updateSheetSize() }
        .onDisappear { if shouldSaveOnDisappear { commitSave() } }
        .focusable(false)
        .alert("Delete snippet?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                shouldSaveOnDisappear = false
                if let id = snippet?.id { onDelete?(id) }
                dismiss()
            }
        } message: {
            Text("This cannot be undone.")
        }
        .alert("Unsaved changes", isPresented: $showDismissConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Quit without saving", role: .destructive) {
                shouldSaveOnDisappear = false
                dismiss()
            }
            Button("Save and quit") { commitSave(); dismiss() }
        } message: {
            Text("You have unsaved changes. What would you like to do?")
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
                Spacer()
                HStack(spacing: 8) {
                    CopyButton(
                        value: snippetBody,
                        defaultAccessibilityLabel: "Copy snippet",
                        copiedAccessibilityLabel: "Snippet copied"
                    ) { isCopied in
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(isCopied ? AppTheme.background : Color.white.opacity(AppTheme.alpha75))
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(AppTheme.alpha12))
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
                    }
                    headerButton(icon: isEditing ? "checkmark" : "pencil",
                                 label: isEditing ? "Done editing" : "Edit snippet") { commitEdit() }
                    if onDelete != nil {
                        headerButton(icon: "trash", label: "Delete snippet") { showDeleteConfirm = true }
                    }
                }
                Rectangle().fill(Color.white.opacity(AppTheme.alpha12)).frame(width: 1, height: 22).padding(.horizontal, 6)
                headerButton(icon: "xmark", label: "Close") { handleDismiss() }
            }
            .padding(.bottom, 12)

            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.system(size: 10))
                    .foregroundStyle(AppTheme.dark.opacity(AppTheme.alpha60))
                ProjectField(text: $project, suggestions: existingProjects)
                    .frame(height: 28)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func headerButton(icon: String,
                              tint: Color = Color.white,
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
                text: $snippetBody,
                font: .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
                textColor: NSColor(AppTheme.background),
                inset: NSSize(width: 24, height: 20),
                lineSpacing: 5
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
                        .foregroundStyle(Color.white.opacity(AppTheme.alpha60))
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

    // MARK: - Sizing

    /// Reads the presenting (main) window's current width and derives the
    /// sheet width from it: window width minus `windowMargin`, clamped to
    /// [450, AppTheme.windowMaxWidth]. `NSApp.mainWindow` is used rather than `keyWindow`
    /// because once the sheet is presented, the sheet's own child window
    /// can become key — the underlying content window stays main.
    private func updateSheetSize() {
        sheetWidth = WindowHelpers.windowConstrainedWidth(min: 450, max: AppTheme.windowMaxWidth)
        sheetHeight = WindowHelpers.windowConstrainedHeight(min: 400, max: 600)
    }

    // MARK: - Actions

    /// Checkmark button (EDIT mode): save current state, refresh dirty baseline, switch to VIEW mode.
    /// Refreshing the baseline ensures a subsequent X sees clean state (BUG-CHECKMARKDIRTY-1).
    /// Pencil button (VIEW mode): switch to EDIT mode.
    private func commitEdit() {
        guard isEditing else {
            isEditing = true
            return
        }
        commitSave()
        originalTitle   = title
        originalProject = project
        originalBody    = snippetBody
        isEditing = false
    }

    /// X button: dismiss immediately if clean, show confirm alert if dirty.
    /// Clean path sets shouldSaveOnDisappear = false — the user explicitly
    /// chose to close without requesting a save, so .onDisappear should not
    /// auto-save either (though in the clean case there is nothing to save anyway).
    private func handleDismiss() {
        if isDirty {
            showDismissConfirm = true
        } else {
            shouldSaveOnDisappear = false
            dismiss()
        }
    }

    // MARK: - Persistence

    private func commitSave() {
        if let s = Snippet.committed(from: snippet, title: title, body: snippetBody, project: project) {
            onSave(s)
        }
    }
}
