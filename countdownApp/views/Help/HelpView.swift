// HelpView.swift
// countdownApp
//
// Help window root view. Lists all HelpSection / HelpItem entries from
// HelpContent.sections. Supports id-based keyword search via .searchable —
// filters items whose id contains the lowercased search query (IconKeeper pattern).
// Screenshots (HelpScreenshot) wired in ENH-HELP-1-S3.
// Real string content is filled in ENH-HELP-1-S4 through S6.
//
// Architectural role:
// - Pure presentation layer; no store or service access
// - Opened via WindowGroup(id: HelpWindowID.id) in countdownAppApp.swift
//
// ENH-HELP-1-S2, ENH-HELP-1-S3

import SwiftUI

// MARK: - HelpView

struct HelpView: View {

    @State private var searchQuery = ""

    private var filteredSections: [HelpSection] {
        if searchQuery.isEmpty { return HelpContent.sections }
        let q = searchQuery.lowercased()
        return HelpContent.sections.compactMap { section in
            let matched = section.items.filter { $0.id.localizedCaseInsensitiveContains(q) }
            guard !matched.isEmpty else { return nil }
            return HelpSection(id: section.id, titleKey: section.titleKey, items: matched)
        }
    }

    var body: some View {
        List {
            ForEach(filteredSections) { section in
                Section(header: Text(section.titleKey).font(.headline)) {
                    ForEach(section.items) { item in
                        HelpItemRow(item: item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchQuery, prompt: Text("Search help…"))
        .navigationTitle("NightShift Help")
        .frame(minWidth: 520, minHeight: 480)
    }
}

// MARK: - HelpItemRow

private struct HelpItemRow: View {
    let item: HelpItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(item.titleKey)
                    .font(.system(.body, weight: .semibold))
            } icon: {
                Image(systemName: item.icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
            }

            Text(item.bodyKey)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let imageName = item.imageName, let focusRect = item.focusRect {
                HelpScreenshot(
                    imageName: imageName,
                    focusRect: focusRect,
                    targetSize: CGSize(width: 460, height: 220)
                )
            }
        }
        .padding(.vertical, 4)
    }
}
