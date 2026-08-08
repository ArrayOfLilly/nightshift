//
//  CountdownView.swift
//  countdownApp
//
//  Countdown list screen.
//  Single TimelineView ticks every second at the top level;
//  `now` is passed down to each CountdownRowView — no per-row timers.
//  Active rows: sorted by deadline ASC (automatic).
//  Free (expired) rows: manually reorderable via drag-to-reorder;
//    freeOrder [UUID] drives render order, persisted to UserDefaults "freeSlotOrder".
//
//  BUG-18 fix: NavigationLink(value:) + .navigationDestination(for:) pattern.
//  CountdownDetailView is only constructed on navigation, not on every TimelineView tick.
//

import SwiftUI
import UniformTypeIdentifiers

struct CountdownView: View {

    @State private var items:        [CountdownItem] = []
    @State private var showAddSheet: Bool = false
    @State private var freeOrder:    [UUID] = []
    @State private var draggingID:   UUID?  = nil

    private let storageKey   = "countdownItems"
    private let freeOrderKey = "freeSlotOrder"

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
            .navigationDestination(for: CountdownItem.self) { item in
                if let idx = items.firstIndex(where: { $0.id == item.id }) {
                    CountdownDetailView(item: $items[idx]) {
                        let id = items[idx].id
                        items.removeAll { $0.id == id }
                        freeOrder.removeAll { $0 == id }
                        save()
                    }
                }
            }
        }
        .onAppear {
            load()
            loadFreeOrder()
        }
        .onChange(of: items)     { save() }
        .onChange(of: freeOrder) { saveFreeOrder() }
    }

    // MARK: - Sorted item lists

    private func activeItems(at now: Date) -> [CountdownItem] {
        items
            .filter { !$0.isExpired(at: now) }
            .sorted { $0.deadline < $1.deadline }
    }

    private func orderedFreeItems(at now: Date) -> [CountdownItem] {
        let expired = items.filter { $0.isExpired(at: now) }
        var result: [CountdownItem] = []
        for id in freeOrder {
            if let item = expired.first(where: { $0.id == id }) {
                result.append(item)
            }
        }
        let positioned = Set(result.map { $0.id })
        let remaining = expired
            .filter { !positioned.contains($0.id) }
            .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        result.append(contentsOf: remaining)
        return result
    }

    // MARK: - Binding helper

    private func binding(for item: CountdownItem) -> Binding<CountdownItem> {
        Binding(
            get: { self.items.first { $0.id == item.id } ?? item },
            set: { updated in
                if let idx = self.items.firstIndex(where: { $0.id == updated.id }) {
                    self.items[idx] = updated
                }
            }
        )
    }

    // MARK: - Subviews

    private var itemList: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
            let now    = ctx.date
            let active = activeItems(at: now)
            let free   = orderedFreeItems(at: now)

            ScrollView {
                LazyVStack(spacing: 10) {

                    Text("ACCOUNT COOLDOWN")
                        .font(AppTheme.alienLeagueBold(32))
                        .foregroundStyle(AppTheme.dark)
                        .kerning(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    ForEach(active, id: \.id) { item in
                        NavigationLink(value: item) {
                            CountdownRowView(item: binding(for: item), now: now)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                    }

                    ForEach(free, id: \.id) { item in
                        NavigationLink(value: item) {
                            CountdownRowView(item: binding(for: item), now: now)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .onDrag {
                            draggingID = item.id
                            return NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.plainText],
                            delegate: FreeSlotDropDelegate(
                                targetItem: item,
                                freeItems:  free,
                                freeOrder:  $freeOrder,
                                draggingID: $draggingID
                            )
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
            }
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

    private func saveFreeOrder() {
        let strings = freeOrder.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: freeOrderKey)
    }

    private func loadFreeOrder() {
        guard let strings = UserDefaults.standard.stringArray(forKey: freeOrderKey) else { return }
        let validIDs = Set(items.map { $0.id })
        freeOrder = strings.compactMap { UUID(uuidString: $0) }.filter { validIDs.contains($0) }
    }
}

// MARK: - Drop delegate

private struct FreeSlotDropDelegate: DropDelegate {

    let targetItem: CountdownItem
    let freeItems:  [CountdownItem]
    @Binding var freeOrder:  [UUID]
    @Binding var draggingID: UUID?

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool { draggingID = nil; return true }

    func dropEntered(info: DropInfo) {
        guard
            let from = draggingID,
            from != targetItem.id,
            let fi = freeItems.firstIndex(where: { $0.id == from }),
            let ti = freeItems.firstIndex(where: { $0.id == targetItem.id })
        else { return }
        var ids = freeItems.map { $0.id }
        ids.move(fromOffsets: IndexSet(integer: fi), toOffset: ti > fi ? ti + 1 : ti)
        freeOrder = ids
    }
}

#Preview { CountdownView() }
