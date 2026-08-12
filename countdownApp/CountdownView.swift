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
//  BUG-19 fix: .navigationDestination closure uses binding(for:) helper instead of
//  $items[idx] direct subscript. The idx captured at navigation time becomes stale
//  when items mutate (deadline change → active/free reclassification); binding(for:)
//  always resolves against the live items array by ID.
//
//  BUG-20 fix: RowEntry wrapper carries a slotKind ("a" / "f") alongside the item.
//  ForEach uses RowEntry.listID (= "a-UUID" / "f-UUID") as identity. Without the
//  prefix both ForEach loops share the same UUID identity space — SwiftUI recycles
//  the view when an item moves free→active (same UUID, different list), so
//  CountdownRowView keeps the stale free appearance. The prefix forces a new view
//  identity on reclassification.
//
//  SOUND-1: Per-slot expiry sound.
//  rebuildCache tracks previousActiveIDs (Set<UUID>). The crossingTask calls
//  rebuildCache(playExpirySounds: true) exactly when nextDeadline passes —
//  items that just left the active set and have soundEnabled=true trigger
//  NSSound(named: "Funk")?.play().
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - RowEntry

private struct RowEntry: Identifiable {
    let item:     CountdownItem
    let slotKind: String        // "a" = active, "f" = free
    var id: String { "\(slotKind)-\(item.id)" }
}

struct CountdownView: View {

    @State private var items:        [CountdownItem] = []
    @State private var showAddSheet: Bool = false
    @State private var freeOrder:    [UUID] = []
    @State private var draggingID:   UUID?  = nil

    // 23-C: stable ForEach data — rebuilt only on structural changes, not every tick.
    @State private var cachedEntries:   [RowEntry]           = []
    @State private var cachedFreeItems: [CountdownItem]      = []
    @State private var nextDeadline:    Date?                = nil
    @State private var crossingTask:    Task<Void, Never>?   = nil

    // SOUND-1: snapshot of active item IDs from the previous rebuildCache call.
    // Used to detect which items just expired when crossingTask fires.
    @State private var previousActiveIDs: Set<UUID> = []

    private let storageKey   = AppKeys.countdownItems
    private let freeOrderKey = AppKeys.freeSlotOrder

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
                CountdownDetailView(item: binding(for: item)) {
                    let id = item.id
                    items.removeAll { $0.id == id }
                    freeOrder.removeAll { $0 == id }
                    save()
                    saveFreeOrder()
                }
            }
        }
        .onAppear {
            load()
            loadFreeOrder()
            rebuildCache()
        }
        .onChange(of: items)     { save(); rebuildCache() }
        .onChange(of: freeOrder) { rebuildCache() }
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

    private func rowEntries(at now: Date) -> [RowEntry] {
        let active = activeItems(at: now).map { RowEntry(item: $0, slotKind: "a") }
        let free   = orderedFreeItems(at: now).map { RowEntry(item: $0, slotKind: "f") }
        return active + free
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

    // MARK: - Cache rebuild

    // 23-C fix: decouples ForEach identity from the TimelineView tick.
    // Called only on structural changes: items/freeOrder mutation, or deadline crossing.
    // Sets nextDeadline = earliest active deadline, then arms a Task that fires exactly
    // when the first active item expires (active→free reclassification needed).
    //
    // SOUND-1: playExpirySounds=true is passed only from the crossingTask (deadline crossing).
    // At that point, items that were in previousActiveIDs but are now expired AND have
    // soundEnabled=true will trigger NSSound(named: "Funk")?.play().
    // previousActiveIDs is always updated to the current active set at the end.
    private func rebuildCache(now: Date = Date(), playExpirySounds: Bool = false) {
        let newActiveIDs = Set(items.filter { !$0.isExpired(at: now) }.map { $0.id })

        if playExpirySounds {
            let justExpired = items.filter {
                previousActiveIDs.contains($0.id) && !newActiveIDs.contains($0.id)
            }
            for item in justExpired where item.soundEnabled {
                NSSound(named: "Funk")?.play()
            }
        }
        previousActiveIDs = newActiveIDs

        cachedEntries   = rowEntries(at: now)
        cachedFreeItems = orderedFreeItems(at: now)
        nextDeadline    = items
            .filter { !$0.isExpired(at: now) }
            .map    { $0.deadline }
            .min()
        crossingTask?.cancel()
        if let nd = nextDeadline {
            crossingTask = Task {
                let delay = nd.timeIntervalSinceNow
                if delay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                guard !Task.isCancelled else { return }
                await MainActor.run { rebuildCache(now: Date(), playExpirySounds: true) }
            }
        }
    }

    // MARK: - Subviews

    // 23-B fix (confirmed Session 23, 2026-08-08): LazyVStack replaced with VStack.
    // LazyLayoutViewCache.updateItemPhases() triggered by scroll caused
    // AG::Subgraph::foreach_ancestor walk → Severe Hang after active↔free
    // reclassification cycles. VStack has no lazy phase tracking; no ancestor walk.
    // 23-C: TimelineView tick at 1.0s; cachedEntries decouples ForEach from tick.
    private var itemList: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { ctx in
            let now = ctx.date
            // 23-C: cachedEntries is stable between structural changes.
            // ForEach diff is O(0) per tick; LazyLayoutViewCache sees no identity churn.
            ScrollView {
                VStack(spacing: 10) { // 23-B fix: LazyVStack causes LazyLayoutViewCache.updateItemPhases() scroll-triggered ancestor walk → Severe Hang. VStack is permanent fix.

                    Text("ACCOUNT COOLDOWN")
                        .font(AppTheme.alienLeagueBold(32))
                        .foregroundStyle(AppTheme.dark)
                        .kerning(4)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                    ForEach(cachedEntries) { entry in
                        let item = entry.item
                        let isFree = entry.slotKind == "f"

                        if isFree {
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
                                    freeItems:  cachedFreeItems,
                                    freeOrder:  $freeOrder,
                                    draggingID: $draggingID,
                                    onCommit:   saveFreeOrder
                                )
                            )
                        } else {
                            NavigationLink(value: item) {
                                CountdownRowView(item: binding(for: item), now: now)
                            }
                            .buttonStyle(.plain)
                            .focusable(false)
                        }
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
    let onCommit: () -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool {
        draggingID = nil
        onCommit()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard
            let from = draggingID,
            from != targetItem.id,
            let fi = freeItems.firstIndex(where: { $0.id == from }),
            let ti = freeItems.firstIndex(where: { $0.id == targetItem.id })
        else { return }
        var ids = freeItems.map { $0.id }
        ids.move(fromOffsets: IndexSet(integer: fi), toOffset: ti > fi ? ti + 1 : ti)
        // 23-A fix: skip mutation if order unchanged (avoids ForEach diff on every hover event)
        if ids != freeOrder { freeOrder = ids }
    }
}

#Preview { CountdownView() }
