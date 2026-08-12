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

    @State private var snippets:    [Snippet] = []
    @State private var editTarget:  Snippet?       // sheet for editing
    @State private var showNewSheet = false
    @State private var copiedID:    UUID?          // per-row copy feedback

    // Project rename
    @State private var projectToRename:  String = ""
    @State private var renameText:       String = ""
    @State private var showRenameAlert  = false

    // Project delete
    @State private var projectToDelete:  String = ""
    @State private var showDeleteProjectAlert = false

    // Recovery banner
    @State private var corruptedFragments: [String] = []

    private var projectKeys: [String] {
        // Case-insensitive alpha sort; "General" (any casing) always last.
        let all = Array(Set(snippets.map { $0.project }))
            .sorted { $0.lowercased() < $1.lowercased() }
        let isGeneral: (String) -> Bool = { $0.lowercased() == "general" }
        return all.filter { !isGeneral($0) } + all.filter { isGeneral($0) }
    }

    private func rows(for project: String) -> [Snippet] {
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
        .alert("Rename project", isPresented: $showRenameAlert) {
            TextField("Project name", text: $renameText)
            Button("Rename") { renameProject(from: projectToRename, to: renameText) }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All snippets in “\(projectToRename)” will be moved to the new name.")
        }
        .alert("Delete project?", isPresented: $showDeleteProjectAlert) {
            Button("Delete", role: .destructive) { deleteProject(projectToDelete) }
            Button("Cancel", role: .cancel) { }
        } message: {
            let count = snippets.filter { $0.project == projectToDelete }.count
            Text("This will permanently delete all \(count) snippet\(count == 1 ? "" : "s") in “\(projectToDelete)”.")
        }
        .sheet(isPresented: $showNewSheet, onDismiss: { snippets = Snippet.load() }) {
            SnippetEditSheet(snippet: nil, existingProjects: projectKeys, onSave: { new in
                snippets.append(new)
                Snippet.save(snippets)
            }, onDelete: nil)
        }
        .sheet(item: $editTarget, onDismiss: { snippets = Snippet.load() }) { target in
            SnippetEditSheet(snippet: target, existingProjects: projectKeys, onSave: { updated in
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
        }
    }

    // MARK: - Corruption banner

    private var corruptionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.background)
                .font(.system(size: 14, weight: .semibold))

            Text("\(corruptedFragments.count) item\(corruptedFragments.count == 1 ? "" : "s") could not be loaded")
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
            .focusable(false)
            .font(AppTheme.alienLeague(12))
            .foregroundStyle(AppTheme.calculateBackground)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppTheme.background.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Button("Dismiss") {
                UserDefaults.standard.removeObject(forKey: AppKeys.corruptedDump)
                corruptedFragments = []
            }
            .buttonStyle(.plain)
            .focusable(false)
            .font(AppTheme.alienLeague(12))
            .foregroundStyle(AppTheme.background.opacity(0.7))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0x8B/255, green: 0x0/255, blue: 0x0/255).opacity(0.75))
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
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .focusable(false)
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
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
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

    private func sectionHeader(_ project: String) -> some View {
        HStack(spacing: 6) {
            Text(project.uppercased())
                .font(AppTheme.alienLeagueBold(11))
                .foregroundStyle(AppTheme.background)
                .kerning(2)
            Menu {
                Button("Rename project\u{2026}") {
                    projectToRename = project
                    renameText      = project
                    showRenameAlert = true
                }
                Divider()
                Button("Delete project", role: .destructive) {
                    projectToDelete       = project
                    showDeleteProjectAlert = true
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(width: 22, height: 22)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .focusable(false)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 6)
    }

    // MARK: - Project actions

    private func renameProject(from old: String, to new: String) {
        let trimmed = new.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != old else { return }
        snippets = snippets.map { s in
            guard s.project == old else { return s }
            var updated = s
            updated.project = trimmed
            return updated
        }
        Snippet.save(snippets)
    }

    private func deleteProject(_ project: String) {
        snippets.removeAll { $0.project == project }
        Snippet.save(snippets)
    }

    private func snippetRow(_ snippet: Snippet) -> some View {
        HStack(spacing: 12) {
            // Tap area → edit sheet
            Button { editTarget = snippet } label: {
                VStack(alignment: .leading, spacing: 3) {
                    Text(snippet.title.isEmpty ? "Untitled" : snippet.title)
                        .font(AppTheme.alienLeague(14))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .lineLimit(1)
                    if !snippet.body.isEmpty {
                        Text(String(snippet.body.prefix(140)).replacingOccurrences(of: "\n", with: " "))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.35))
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)

            // Copy body
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(snippet.body, forType: .string)
                copiedID = snippet.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if copiedID == snippet.id { copiedID = nil }
                }
            } label: {
                let copied = copiedID == snippet.id
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(copied ? AppTheme.background : Color.white.opacity(0.45))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
