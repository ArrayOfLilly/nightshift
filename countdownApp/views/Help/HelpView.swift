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
                    .fontWeight(.bold)
                    .padding(.horizontal, 16)) {
                    ForEach(section.items) { item in
                        HelpItemRow(item: item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchQuery, prompt: Text("Search help…"))
        .navigationTitle("NightShift Help")
        // Min/max range (not locked to one value) so the window behaves like the main
        // window (AppTheme.windowMinWidth/windowMaxWidth) — resizable within bounds —
        // just wider, since Help content benefits from more room on large displays.
        // The 560pt-wide screenshots and 20pt HelpItemRow padding still line up correctly
        // at any width in this range since they don't depend on the window's exact size.
        .frame(minWidth: AppTheme.helpWindowMinWidth, maxWidth: AppTheme.helpWindowMaxWidth, minHeight: 560)
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

            if !item.imageNames.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(item.imageNames, id: \.self) { imageName in
                        HelpScreenshot(imageName: imageName, maxWidth: 560 * item.imageScale)
                    }
                }
                .padding(.leading, 28)
                .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }
}
