//
//  CountdownView.swift
//  countdownApp
//
//  Countdown list screen.
//  Each row taps through to CountdownDetailView (full Spooky Tomato design).
//  The tomato image lives only in CountdownDetailView — this view stays clean.
//  Persistence: UserDefaults, key "countdownItems", JSON-encoded [CountdownItem].
//

import SwiftUI

struct CountdownView: View {

    @State private var items:        [CountdownItem] = []
    @State private var showAddSheet: Bool = false

    private let storageKey = "countdownItems"

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    itemList
                    addButton
                }
            }
            .navigationTitle("Countdown")
            .sheet(isPresented: $showAddSheet) {
                AddCountdownSheet { newItem in
                    items.append(newItem)
                }
            }
        }
        .onAppear(perform: load)
        .onChange(of: items) { save() }
    }

    // MARK: - Subviews

    private var sortedIndices: [Int] {
        items.indices.sorted { i, j in
            let a = items[i], b = items[j]
            let now = Date()
            let aExp = a.isExpired(at: now), bExp = b.isExpired(at: now)
            if aExp != bExp { return !aExp }  // expired a végére
            return a.deadline < b.deadline    // ASC: leghamarabb lejáró felül
        }
    }

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(sortedIndices, id: \.self) { i in
                    // NavigationLink wraps the row. Buttons inside the row
                    // (toggle, delete) have their own tap targets and do NOT
                    // trigger navigation — this is standard SwiftUI behaviour.
                    NavigationLink {
                        CountdownDetailView(item: $items[i]) {
                            let id = items[i].id
                            items.removeAll { $0.id == id }
                            save()
                        }
                    } label: {
                        CountdownRowView(item: $items[i])
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
    }

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Text("+ ADD")
                .font(AppTheme.alienLeagueBold(15))
                .foregroundStyle(AppTheme.background)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(AppTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .focusable(false)
        .padding(.vertical, 18)
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data)
        else { return }
        items = decoded
    }
}

#Preview { CountdownView() }
