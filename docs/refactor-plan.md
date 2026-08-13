# countdownApp — Refactor Plan

## Státusz: TELJES — minden finding lezárva ✅

Az összes 16 audit elolvasva (Session Y, 2026-08-12). Minden finding implementálva és commitolva.

Audit forrás: `docs/audit_files/` (16 fájl)
Döntési elv: `Claude.md`

---

## A — KRITIKUS: Adatvesztés (Codable + Storage)

### A-1: `Snippet` és `NamedDeadline` — synthesized Codable — ✅ KÉSZ (Session Z)
- custom `init(from decoder:)` + `CodingKeys` + `decodeIfPresent` — commit `0844aa2`

### A-2: `try?` → silent data loss — ✅ KÉSZ (Sessions AA-a, AA-b, AB)
- Per-item partial recovery minden load path-on
- `AppKeys.appendCorruptFragments` akkumuláló helper
- Corruption banner mindhárom érintett view-ban (SnippetsView, CalculateView, CountdownView)
- `CountdownItem`: notes-alapú elágazás (notes→dump, nincs notes→csendes eldobás)
- commit `2dd8900` + AB session commitok

### A-3: `CountdownItem.id` — `decode()` → `decodeIfPresent` — ✅ KÉSZ (Session Z)
- `decodeIfPresent(UUID.self, forKey: .id) ?? UUID()` — commit `0844aa2`

### A-4: `SnippetEditSheet` — nincs auto-save — ✅ KÉSZ (Session AE)
- `.onDisappear { commitSave() }` hozzáadva — commit `f7f774d`

### A-5: Nincs lifecycle hook — ✅ KÉSZ (Session AB)
- `AppDelegate` + `applicationWillTerminate` → `UserDefaults.standard.synchronize()`

### A-6: `enum AppKeys` hiányzik — ✅ KÉSZ (Session Z)
- Centralizált `enum AppKeys` minden UserDefaults kulcshoz — commit `0844aa2`

---

## B — MAGAS: Memory Leak és Concurrency

### B-1: `FocusedNSTextField.Coordinator` — NC observer leak — ✅ KÉSZ (Session AB)
- `deinit { NotificationCenter.default.removeObserver(self) }` hozzáadva a Coordinator-hoz

### B-2: `copyFeedback` timer — DispatchQueue → Task — ✅ KÉSZ (Sessions AE, AJ, AF)
- `SnippetEditSheet`: AE session — commit `f7f774d`
- `CountdownRowView`: AJ session — commit `cb76608`
- `SnippetsView`: AF session — commit `5c7760b`
- `CountdownDetailView` + `NotesSheet`: AJ session (CopyButton-ba migrálva)

### B-3: `hoverTask: DispatchWorkItem` → `Task<Void, Never>` — ✅ KÉSZ (Session AE)
- cooperative `Task.isCancelled` check — commit `f7f774d`

---

## C — MAGAS: Performance

### C-1: `MarkdownWebView.updateNSView` — feltétel nélküli reload — ✅ KÉSZ (Session AF)
- `guard markdown != context.coordinator.lastMarkdown else { return }` — commit `5c7760b`

### C-2: UserDefaults write per-keystroke — ✅ KÉSZ (Session AF)
- `NotesSheet`: 500ms debounce, lokális `draft` buffer — commit `5c7760b`

### C-3: `orderedFreeItems` — O(n²) → O(n) — ✅ KÉSZ (Session AF)
- `Dictionary(uniqueKeysWithValues:)` lookup — commit `5c7760b`

### C-4: `DateFormatter` ad-hoc példányosítás — ✅ KÉSZ (Session AF)
- `Formatters.swift` új fájl: `monthAbbrev`, `deadline`, `deadlineCompact`, `time` — commit `5c7760b`

---

## D — KÖZEPES: SRP / God Views

### D-1: `CalculateView` god view — ✅ KÉSZ (Sessions AP, AQ, AM)
- D-4: `DeadlineDetailSheet.swift` új struct — commit `d46824d`
- D-3: static load/save `CountdownItem` + `NamedDeadline` — commit `c2570aa`
- E-1: `CalculationModal` enum — commit `dc656e3`

### D-2: `CountdownView` god view — ✅ NEM SZÜKSÉGES (Session AW)
- D-3+D-5+D-1 után domain logika nincs a View-ban
- Maradó felelősségek mind View-természetűek — ViewModel két használati hely nélkül AI slop lenne

### D-3: Persistence metódusok View-ban — ✅ KÉSZ (Session AQ)
- Static load/save: `CountdownItem.swift` + `NamedDeadline.swift` (`extension Persistence`)
- `CountdownView` + `CalculateView`: View-szintű metódusok eltávolítva — commit `c2570aa`

### D-4: `deadlineDetailContent()` @ViewBuilder — ✅ KÉSZ (Session AP)
- `struct DeadlineDetailSheet: View` saját `@State`-tel — commit `d46824d`

### D-5: Business logic view metódusokban — ✅ KÉSZ (Session AS)
- `CountdownItem`: `mutating func resetIfExpired(at:)` + `mutating func adjustDeadline(_:by:)`
- `Snippet`: `static func committed(from:title:body:project:) -> Snippet?` factory
- commit `37b1674`

---

## E — KÖZEPES: State Management

### E-1: `@State` Boolean sprawl (`CalculateView`) — ✅ KÉSZ (Session AM)
- `private enum CalculationModal: Identifiable` (nested); `activeModal: CalculationModal?`
- commit `dc656e3`

### E-2: `CalculateView.namedDeadlines` stale read — ✅ KÉSZ (Session AK)
- `onDismiss: loadDeadlines` mindkét sheet-en — commit `550afe9`

### E-3: `SnippetEditSheet.onDisappear` — ✅ KÉSZ (Session AE)
- `.onDisappear { commitSave() }` — commit `f7f774d`

### E-4: `FocusedNSTextField.updateNSView` font recreation per-second — ✅ KÉSZ (Session AK)
- Font+textColor → `makeNSView`; `updateNSView` csak stringValue — commit `550afe9`

---

## F — ALACSONY: Duplication és Magic Numbers

### F-1: `updateSheetWidth()` — 5 impl → shared helper — ✅ KÉSZ (Session AL)
- `WindowHelpers.swift`: `windowConstrainedWidth` + `windowConstrainedHeight`
- Mind az 5 call site migrálva — commit `ca4445a`
- Magic number tokenek (`windowSheetMargin`, `windowFallbackWidth/Height`) — commit `4bbe75e`

### F-2: Copy-to-clipboard duplikáció — ✅ KÉSZ (Session AJ)
- `CopyButton.swift` shared komponens — commit `cb76608`

### F-3: `componentStepper` — 3 impl → shared — ✅ KÉSZ (Session AN)
- `ComponentStepper.swift` shared struct; `AddCountdownSheet` bugfix: plain Button → `LongPressStepperButton`
- commit `f09bd0c`

### F-4: `monthAbbrev()` — 3 impl → `Formatters.monthAbbrev` — ✅ KÉSZ (Session AK)
- commit `550afe9`

### F-5: `headerButton()` opacity eltérés — ✅ KÉSZ (Session AJ side-fix)
- `NotesSheet.headerButton` bg 0.07 → 0.12 — commit `cb76608`

### F-6: `markdownCSS` amber szín eltérés — ✅ KÉSZ (Session AA-a)
- `AppTheme.background` → `#F5A623`, `amberHex` szinkron kulcs, `markdownCSS` computed var
- commit `2dd8900`

### F-7: `#593C73` purple gradient hardcode — ✅ KÉSZ (Session AL)
- `AppTheme.calcSaveGradient` token — commit `ca4445a`

### F-8: `SnippetEditSheet` ProjectField/popover hardcoded colors — ✅ KÉSZ (Session AL)
- `AppTheme.freeColors[10]` + `freeColors[6]` — commit `ca4445a`

### F-9: Magic corner radii + opacity → `AppTheme` tokenek — ✅ KÉSZ (Session AO)
- `radiusSmall/Medium/Large`, `alpha08`…`alpha90`; 14 fájl érintett — commit `822f154`

### F-10: Delete-confirm alert flag nevek — ✅ KÉSZ (Session AK)
- `showDeleteConfirm` konvenció wszerte — commit `550afe9`

---

## G — LAYOUT / Accessibility

### G-1: `CountdownDetailView` — nincs ScrollView — ✅ KÉSZ (Session AG)
- GeometryReader + ScrollView; Spacer-centerozás megőrizve

### G-2: `SnippetEditSheet` — 680pt fix minHeight — ✅ KÉSZ (Session AG)
- dinamikus `sheetHeight` clamp (400–680)

### G-3: `SunPanel` — edge clipping kockázat — ✅ KÉSZ (Session AG)
- ScrollView + `.frame(minWidth: 360, maxHeight: 600)`

### G-4: `CalculateView` deadline popover — nincs ScrollView — ✅ KÉSZ (Session AG)
- Lista ScrollView + `.frame(maxHeight: 320)`

### G-5: Accessibility — icon-only gombok `.accessibilityLabel` nélkül — ✅ KÉSZ (Sessions AH, AI)
- Csoport 1: `LongPressStepperButton`, `CountdownDetailView`, `ColorPickerSheet`, `AddCountdownSheet` — commit `0fd05b0`
- Csoport 2: `SnippetEditSheet`, `NotesSheet` — commit `b5a046d`
- Csoport 3: `CalculateView`, `CountdownRowView`, `SnippetsView`, `CountdownView` — commit `963f387`

---

## Egyéb lezárt findingek

### UX-1: Főablak max szélesség hiánya — ✅ KÉSZ (Session AU)
- `AppTheme.windowMinWidth = 460`, `windowMaxWidth = 520`; `ContentView` frame frissítve — commit `bc725a2`

### D-1 (SRP): `FocusedNSTextField` kiemelés — ✅ KÉSZ (Session AV)
- `FocusedNSTextField.swift` új fájl; `CountdownDetailView` ~110 sor eltávolítva — commit `01e652f`

---

## Tervezési kérdések — lezárva

- **T1** (partial recovery scope): per-item recovery, notes-alapú elágazás — implementálva
- **T2** (CountdownViewModel): nem szükséges — D-2 döntés AW session
- **T3** (CalculationModal enum): implementálva `CalculateView`-ban önállóan — AM session
- **T4** (markdownCSS computed): implementálva, kockázat minimális — AA-a session
- **T5** (session bontás): elvégezve a tényleges session sorrendben
