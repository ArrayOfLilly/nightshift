# countdownApp — handoff a következő chat-hez

## Working setup
- Filesystem MCP-n keresztül dolgozunk a Mac-emen. Munkarend:
  1. Szerializáltan dolgozz (egy fájl olvasás → értelmezés → döntés, ne párhuzamosan).
  2. Header/komment: angolul, semmi magyar szöveg a kódban.
  3. spec.md, progress.md, manual frissítése + git commit minden session végén.
- Két külön git repo:
  - Outer: `/Users/ArrayOfLilly/tools/countdownApp/` (docs/, images/, screenshots/, colors/ — külön, remote nélküli repo)
  - **Inner (ez a releváns kódrepo)**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/` — itt van `spec.md`, `progress.md`, és a Swift forrás `countdownApp/countdownApp/countdownApp/` alatt.
- **Olvasd el először a `progress.md`-t** (Session 17–23 bejegyzések) — az a teljes debug-történet.

## ⚠️ TEMP DEBUG még aktív
`CountdownView.swift`-ben `TimelineView(.periodic(from: .now, by: 0.01))` — 100× gyorsítva.
Normál érték `1.0`. Keresd a "TEMP DEBUG" kommentet. **NE állítsd vissza**, amíg a
23-A/B/C fixek tesztelve nincsenek — a gyors tick kell a reprodukáláshoz.

## A beachball-nyomozás állása (session 17→23)

**Már javítva és commitolva:**
- Session 17: N per-row timer → 1 közös TimelineView.
- BUG-18/19/20 (session 18–20): NavigationLink eager construction, stale binding index,
  stale row identity (RowEntry `"a-UUID"`/`"f-UUID"` identitással).
- Session 21: font bundling + CTFontManagerRegisterFontsForURL. saveFreeOrder() csak
  performDrop-kor fut (nem minden hover-eventnél).

**Diagnosztika eredménye (Session 23):**
- Backtrace: `AG::Subgraph::foreach_ancestor` → `LazyLayoutViewCache.updateItemPhases`
  → scroll váltja ki, nem közvetlenül a drag/váltás.
- Allocations: monoton felhalmozódás NEM igazolódott — nem AG-leak, hanem
  pathológikus invalidáció/reconciliation pattern.
- Gemini + ChatGPT (teljes kód) statikus elemzés konszenzusa:
  1. `dropEntered` — `freeOrder = ids` minden hover-eventnél, felesleges mutation
     ha az order nem változott. **Legerősebb egyedi találat.**
  2. `rowEntries()` + `orderedFreeItems()` minden TimelineView ticknél újraszámolva →
     ForEach minden ticknél diff-et futtat → LazyVStack folyamatos reconciliation.
  3. RowEntry identity csere (`a-UUID`/`f-UUID`) drága struktúrális diff, de nem leak.
  4. `binding(for:)` — nem probléma (closure capture normális, nincs cycle).
  5. `CountdownDetailView` — tiszta, nincs Timer/Combine/Task/observer.

## Következő lépés — ELSŐ dolog az új chatben

Implementáld a fixeket ebben a sorrendben (részletes terv: progress.md "Session 23 — végleges terv"):

**23-A (1 perc):** `CountdownView.swift`, `FreeSlotDropDelegate.dropEntered`:
```swift
// ELŐTTE:
freeOrder = ids
// UTÁNA:
if ids != freeOrder { freeOrder = ids }
```

**23-B (diagnosztika):** `CountdownView.swift`, `itemList`-ben:
```swift
// LazyVStack → VStack (TEMP DIAG)
VStack(spacing: 10) {
```
Build + teszt: ha eltűnik a beachball → LazyLayoutViewCache igazolt → 23-C indokolt.
Ha nem → más az ok.

**23-C (ha 23-B igazolja):** cachedEntries szétválasztás — részletes terv a
progress.md "Session 23-A terv" bejegyzésben.

**23-D (önálló):** `LongPressStepperButton.swift` — Timer double-add fix:
`RunLoop.main.add(t, forMode: .common)` sor törlendő.

**Session végén:** TimelineView tick visszaállítása `1.0`-ra + progress.md frissítés + commit.

## Összes érintett fájl
- `CountdownView.swift` — fő lista, TimelineView, drag/drop delegate, RowEntry. FŐ CÉL.
- `LongPressStepperButton.swift` — 23-D fix.
- `CountdownRowView.swift` — átnézve, tiszta.
- `CountdownDetailView.swift` — átnézve, tiszta.
- `countdownAppApp.swift` — font regisztráció, nem érintett.
