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
// ENH-HELP-1-S2, ENH-HELP-1-S3, ENH-HELP-1-S4

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
                Section(header: Text(section.titleKey)
                    .font(.title2)
                    .fontWeight(.bold)) {
                    ForEach(section.items) { item in
                        HelpItemRow(item: item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchQuery, prompt: Text("Search help…"))
        .navigationTitle("NightShift Help")
        // Width is locked (not just a minimum) so the fixed-width
        // screenshots and the wrapped body text always line up the same
        // way; only height is free to grow as content is added.
        .frame(minWidth: 640, maxWidth: 640, minHeight: 560)
    }
}

// MARK: - HelpItemRow

private struct HelpItemRow: View {
    let item: HelpItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(item.titleKey)
                    .font(.title3)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: item.icon)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 20)
            }

            Text(item.bodyKey)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 28)

            if let imageName = item.imageName {
                HelpScreenshot(imageName: imageName, maxWidth: 560)
                    .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}
