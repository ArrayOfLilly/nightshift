//
//  SnippetsView.swift
//  countdownApp
//
//  Master-prompt snippet library, grouped alphabetically by project tag.
//  Row: title + body preview (72 chars) + inline Copy button.
//  Tap row → SnippetEditSheet (edit/delete existing).
//  "+" button → SnippetEditSheet (new, empty).
//  Section header: pencil (rename project) + x (delete all in project, with confirm).
//

import SwiftUI
import AppKit

struct SnippetsView: View {

    // BUG-PROJECTRENAME-1: editTarget stores the snippet's UUID only, not a Snippet value snapshot.
    // The sheet closure looks up the current Snippet from snippets state by ID, so a rename that
    // runs between tap and sheet-open is reflected correctly.
    private struct EditTarget: Identifiable { let id: UUID }

    // ENH-SETTINGS-2 dynamic resize: unused directly, but the @AppStorage subscription
    // forces SwiftUI to recompute this view's body when fontSizeStep changes, so the
    // AppTheme.alienLeague()/alienLeagueBold() calls below re-evaluate with the new fontScale.
    @AppStorage(AppKeys.fontSizeStep) private var fontSizeStep: Int = 0

    @State private var snippets:    [Snippet] = []
    @State private var editTarget:  EditTarget?    // sheet for editing — ID only
    @State private var showNewSheet = false
    @State private var copiedID:    UUID?          // per-row copy feedback

    // Project rename
    @State private var projectToRename:  ProjectCategory = .general
    @State private var renameText:       String = ""
    @State private var showRenameAlert  = false

    // Project delete
    @State private var projectToDelete:  ProjectCategory = .general
    @State private var showDeleteProjectConfirm = false

    // Recovery banner
    @State private var corruptedFragments: [String] = []

    private var deleteProjectMessage: String {
        String(format: String(localized: "All snippets in \"%@\" will be moved to General."), projectToDelete.localizedName)
    }

    private var projectKeys: [ProjectCategory] {
        // Case-insensitive alpha sort by localizedName; .general always last.
        // The enum's Equatable/Hashable conformance makes Set deduplication type-safe.
        let all = Array(Set(snippets.map { $0.project }))
            .sorted { $0.localizedName.lowercased() < $1.localizedName.lowercased() }
        return all.filter { $0 != .general } + all.filter { $0 == .general }
    }

    private func rows(for project: ProjectCategory) -> [Snippet] {
        snippets
            .filter { $0.project == project }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            AppTheme.calculateBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                if !corruptedFragments.isEmpty {
                    corruptionBanner
                }
                headerBar
                Divider().opacity(0.3)
                listArea
            }
        }
        .onAppear {
            snippets = Snippet.load()
            corruptedFragments = (UserDefaults.standard.array(forKey: AppKeys.corruptedDump) as? [String]) ?? []
        }
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: DebugNotifications.injectCorruptBanner)) { _ in
            corruptedFragments = (UserDefaults.standard.array(forKey: AppKeys.corruptedDump) as? [String]) ?? []
        }
        #endif
        .alert("Rename project", isPresented: $showRenameAlert) {
            TextField("Project name", text: $renameText)
            Button("Rename") { renameProject(from: projectToRename, to: renameText) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(String(format: String(localized: "All snippets in \"%@\" will be moved to the new name."), projectToRename.localizedName))
        }
        .alert("Delete project?", isPresented: $showDeleteProjectConfirm) {
            Button("Delete", role: .destructive) { deleteProject(projectToDelete) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(deleteProjectMessage)
        }
        .navigationTitle("Snippets")
        .sheet(isPresented: $showNewSheet, onDismiss: { snippets = Snippet.load() }) {
            // FIX (BUG-SNIPPETDUP-1): id-based upsert instead of unconditional append.
            // With the SnippetEditSheet fix, a second commitSave() during the same new-snippet
            // session now reuses the same id — without this upsert it would still append a
            // second array entry with that id.
            SnippetEditSheet(snippet: nil, existingProjects: projectKeys, onSave: { new in
                if let i = snippets.firstIndex(where: { $0.id == new.id }) {
                    snippets[i] = new
                } else {
                    snippets.append(new)
                }
                Snippet.save(snippets)
            }, onDelete: nil)
        }
        .sheet(item: $editTarget, onDismiss: {
            snippets = Snippet.load()
        }) { target in
            // Look up the current Snippet by ID so that any rename that happened between
            // the tap and the sheet presentation is reflected in the initial state.
            if let snippet = snippets.first(where: { $0.id == target.id }) {
                SnippetEditSheet(snippet: snippet, existingProjects: projectKeys, onSave: { updated in
                    if let i = snippets.firstIndex(where: { $0.id == updated.id }) {
                        snippets[i] = updated
                    } else {
                        snippets.append(updated)
                    }
                    Snippet.save(snippets)
                }, onDelete: { id in
                    snippets.removeAll { $0.id == id }
                    Snippet.save(snippets)
                })
            } else {
                // Snippet was deleted between tap and sheet open — dismiss immediately.
                Color.clear.onAppear { editTarget = nil }
            }
        }
    }

    // MARK: - Corruption banner

    private var corruptionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.background)
                .font(.system(size: 14, weight: .semibold))

            Text(String(format: String(localized: "%lld item%@ could not be loaded"), corruptedFragments.count, corruptedFragments.count == 1 ? "" : "s"))
                .font(AppTheme.alienLeague(13))
                .foregroundStyle(AppTheme.background)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Copy raw data") {
                let json = "[\(corruptedFragments.joined(separator: ",\n"))]"
                if let prettyData = try? JSONSerialization.data(
                    withJSONObject: JSONSerialization.jsonObject(with: Data(json.utf8)),
                    options: [.prettyPrinted, .sortedKeys]
                ), let prettyString = String(data: prettyData, encoding: .utf8) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(prettyString, forType: .string)
                } else {
                    // Fallback: copy raw fragments as-is
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(json, forType: .string)
                }
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .font(AppTheme.alienLeague(12))
            .foregroundStyle(AppTheme.calculateBackground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.background.opacity(AppTheme.alpha90))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall))

            Button("Dismiss") {
                UserDefaults.standard.removeObject(forKey: AppKeys.corruptedDump)
                corruptedFragments = []
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .font(AppTheme.alienLeague(12))
            .foregroundStyle(AppTheme.background.opacity(AppTheme.alpha75))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(AppTheme.alpha08))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0x8B/255, green: 0x0/255, blue: 0x0/255).opacity(AppTheme.alpha75))
    }

    // MARK: - Header bar

    private var headerBar: some View {
        HStack {
            Text("SNIPPETS")
                .font(AppTheme.alienLeagueBold(20))
                .foregroundStyle(AppTheme.background)
            Spacer()
            Button { showNewSheet = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(AppTheme.alpha75))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(AppTheme.alpha08))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .accessibilityLabel(Text("New snippet"))
            .help(String(localized: "Create a new snippet in the library"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - List

    @ViewBuilder
    private var listArea: some View {
        if snippets.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "doc.plaintext")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.background.opacity(0.4))
                Text("Tap + to add a snippet.")
                    .font(AppTheme.alienLeague(14))
                    .foregroundStyle(Color.white.opacity(AppTheme.alpha35))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(projectKeys, id: \.self) { project in
                        sectionHeader(project)
                        ForEach(rows(for: project)) { snippet in
                            snippetRow(snippet)
                            Rectangle()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }

    private func sectionHeader(_ project: ProjectCategory) -> some View {
        // localizedName handles both .general (localized display) and .custom (verbatim).
        // .general is a system category: no rename allowed, only delete.
        let displayLabel = project.localizedName
        return HStack(spacing: 6) {
            Text(displayLabel.uppercased())
                .font(AppTheme.alienLeagueBold(11))
                .foregroundStyle(AppTheme.background)
                .kerning(2)
            if project != .general {
                // Custom projects: rename + delete available
                Menu {
                    Button("Rename project\u{2026}") {
                        projectToRename = project
                        renameText      = project.localizedName
                        showRenameAlert = true
                    }
                    Divider()
                    Button("Delete project", role: .destructive) {
                        projectToDelete          = project
                        showDeleteProjectConfirm = true
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.white.opacity(AppTheme.alpha50))
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .focusEffectDisabled()
                .accessibilityLabel(Text("Project options"))
                .help(String(localized: "Rename or delete this project group"))
            } else {
                // General is a system category: only delete (move all to General is N/A),
                // but since deleting General would leave no fallback bucket, we hide the
                // chevron entirely — the system category cannot be renamed or deleted.
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    // MARK: - Project actions

    private func renameProject(from old: ProjectCategory, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let newCategory = ProjectCategory(userEnteredName: trimmed)
        guard newCategory != old else { return }
        snippets = snippets.map { s in
            guard s.project == old else { return s }
            var updated = s
            updated.project = newCategory
            return updated
        }
        Snippet.save(snippets)
    }

    private func deleteProject(_ project: ProjectCategory) {
        snippets = snippets.map { s in
            guard s.project == project else { return s }
            var updated = s
            updated.project = .general
            return updated
        }
        Snippet.save(snippets)
    }

    private func snippetRow(_ snippet: Snippet) -> some View {
        HStack(spacing: 12) {
            // Tap area → edit sheet (store ID only; sheet resolves fresh Snippet from state)
            Button { editTarget = EditTarget(id: snippet.id) } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snippet.title.isEmpty ? String(localized: "Untitled") : snippet.title)
                        .font(AppTheme.alienLeague(14))
                        .foregroundStyle(Color.white.opacity(AppTheme.alpha90))
                        .lineLimit(1)
                    if !snippet.body.isEmpty {
                        Text(String(snippet.body.prefix(140)).replacingOccurrences(of: "\n", with: " "))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(AppTheme.alpha35))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .help(String(localized: "Open this snippet to view or edit its content"))

            // Copy body
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(snippet.body, forType: .string)
                copiedID = snippet.id
                Task {
                    try? await Task.sleep(for: .milliseconds(1000))
                    if copiedID == snippet.id { copiedID = nil }
                }
            } label: {
                let copied = copiedID == snippet.id
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(copied ? AppTheme.background : Color.white.opacity(AppTheme.alpha50))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall))
            }
            .buttonStyle(.plain)
            .focusEffectDisabled()
            .accessibilityLabel(Text("Copy snippet"))
            .help(String(localized: "Copy the full snippet text to the clipboard"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
