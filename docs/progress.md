# countdownApp — Progress

## Session BH — 2026-08-14 (ENH-ABOUT-1 + Display Name + verzió)

### Session BH — LEZÁRVA
- [x] iconKeeper `AboutView.swift` + `IconKeeperApp.swift` elolvasva (referencia)
- [x] **Display Name:** `INFOPLIST_KEY_CFBundleDisplayName = NightShift` — Debug + Release blokkban
- [x] **Verzió:** `MARKETING_VERSION = 0.9.2`, `CURRENT_PROJECT_VERSION = 2` — Debug + Release
- [x] **ENH-ABOUT-1** — `AboutView.swift` új fájl (`Views/AboutView.swift`):
  - `AboutWindowID` enum (`nightshift-about`)
  - `AboutCommands` struct (`CommandGroup(replacing: .appInfo)`)
  - `AboutView`: app ikon (`NSApp.applicationIconImage`), név, verzió/build,
    tagline, Developer (mailto link), Images → Freepik (link), footer © 2026
- [x] **countdownAppApp.swift** frissítve:
  - `AboutCommands()` a fő `WindowGroup` `.commands` blokkjában
  - `#if DEBUG CommandMenu` átkerült ugyanabba a `.commands` blokkba
  - `WindowGroup(id: AboutWindowID.id)` új scene az About ablakhoz
- [x] Build OK (icon group hiba javítva — Icon Composer-ben)
- [x] Git commit: `7ab7b65`

**Következő session:** ENH-HELP-1 🟡

---

## Session BG — 2026-08-14 (BUG-SUNPANEL-1 + buglist bővítés)

### Session BG — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md, buglist.md elolvasva
- [x] `SunPanel.swift` + `CalculateView.swift` elolvasva
- [x] **BUG-SUNPANEL-1** — hover trigger → click trigger:
  - `hoverTask: Task<Void, Never>?` `@State` eltávolítva
  - `.onHover` blokk eltávolítva
  - Középső hold (index 4) `Button` wrappérbe csomagolva: `showSunPopover.toggle()`
  - `.popover(isPresented: $showSunPopover)` a `Button`-ra kerül
  - `.accessibilityLabel("Sun times")` hozzáadva
  - Komment frissítve: SUN-1-B hivatkozás + BUG-SUNPANEL-1 magyarázat
- [x] **Buglist bővítve** — 6 új bejegyzés: BUG-SUNPANEL-1 ✅, ENH-ABOUT-1 🟡,
  ENH-HELP-1 🟡, ENH-L10N-1 🟢, ENH-SETTINGS-1 🟢, ENH-DEVDOCS-2 🟡
- [x] Build OK
- [x] `docs/buglist.md` + `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Git commit: `b0967ce`

**Következő session:** ENH-ABOUT-1 🟡 (iconKeeper About forráskódja referencia) vagy ENH-HELP-1 🟡

---

## Session BF — 2026-08-13 (ENH-NOTEBADGE-1 + UX-2 + BUG-MANUAL-1)

### Session BF — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md elolvasva
- [x] `CountdownRowView.swift` + `AppTheme.swift` + `CountdownItem.swift` elolvasva
- [x] **ENH-NOTEBADGE-1** — `AppTheme.noteIndicator` token (orangered → polish: narancssárgára);
  `CountdownRowView` label box `HStack`-jébe `eye.fill` SF Symbol ikon (`system(size: 10, weight: .medium)`,
  `AppTheme.noteIndicator`), `!copyFeedback && !item.notes.isEmpty` feltétellel, `.accessibilityHidden(true)`
- [x] **UX-2** — `AppTheme.windowMaxWidth` 520 → 600; comment frissítve; `ContentView` érintetlen
- [x] **Badge polish** — `note.text` → `eye.fill`; szín `green: 0.27 → 0.45` (narancsosabb); copy alatt eltűnik
- [x] **BUG-MANUAL-1** — manual frissítve:
  - `05e` + eye badge leírás az "Active entry row" szekcióba
  - `11b` + "Closing with unsaved changes" szekció a Notes részbe
  - `17 Snippet Edtor - Exit.png` + "Closing with unsaved changes" szekció a Snippets részbe
  - `manual_build.py` újrafuttatva → HTML regenerálva
- [x] `docs/buglist.md` — ENH-NOTEBADGE-1 és UX-2 ✅ KÉSZ státuszra frissítve
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Git commit: `e6aa819` (badge+UX-2) + `d1ce48c` (badge polish) + `515aa7e` (manual)

**Következő session:** ENH-DEVDOCS-1 🟡 vagy ENH-DEFERRED-1 🟢 — buglist tiszta, csak ezek maradtak

---

## Session BC — 2026-08-13 (BUG-CHECKMARKDIRTY-1 + BUG-NOTESDISMISS-1)

### Session BC — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md, buglist.md elolvasva
- [x] `SnippetEditSheet.swift` + `NotesSheet.swift` elolvasva — root cause megerősítve
- [x] **BUG-CHECKMARKDIRTY-1** — `SnippetEditSheet`: `let` → `var` az `originalTitle/Project/Body`
  property-ken; `commitEdit()` checkmark ágában `originalTitle = title` / `originalProject = project` /
  `originalBody = snippetBody` refresh a `commitSave()` után — X ezután clean state-et lát, nem mutat
  felesleges confirm alertet
- [x] **BUG-NOTESDISMISS-1 + NotesSheet UX egységesítés** — `NotesSheet`: debounce (`debounceTask` state +
  `.onChange(of: draft)` blokk) eltávolítva; `originalNotes: String` state hozzáadva; `.onAppear`
  `originalNotes = notes` baseline; `commitEdit()` checkmark ágában `originalNotes = draft` refresh;
  `handleDismiss()` `draft == originalNotes` check (volt: `draft == notes`); "Quit without saving"
  `notes = originalNotes` visszaállítással; delete alert `originalNotes = ""` reset
- [x] `docs/buglist.md` — BUG-CHECKMARKDIRTY-1 és BUG-NOTESDISMISS-1 ✅ KÉSZ státuszra frissítve
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Git commit: `3b78104`

**Következő session:** BUG-TRASH-1 🔴 (editor trash visszateszi a törölt snippetet) vagy
BUG-DETAILDELETE-1 🔴 (CountdownDetailView törlés után nem navigál vissza) — egyeztetés alapján

---

## Session BB — 2026-08-13 (pending commit hash-ek rendezése + mappastruktúra ellenőrzés + buglist bővítés)

### Session BB — LEZÁRVA
- [x] `git log` alapján ellenőrizve: AN (F-3), AM (E-1), AO (F-9), AL (F-1/F-7/F-8), AS (D-5), Z+AA-b+AB,
  Q–Y sessionok `progress.md`-ben “Git commit: PENDING/TODO” jelziként szerepeltek, de a kód valójában már
  commitolva volt — mind a 9 hely frissítve tényleges hash-ekkel (`f09bd0c`, `dc656e3`, `822f154`, `ca4445a`,
  `37b1674`, `ebe890a`, `678bea6`, `25f7591`)
- [x] `countdownApp-handoff.md` — AL session tévesen `4fd8eef`-et mutatott (az AK docs commit, nem AL) →
  javítva `ca4445a`-ra; AN/AM/AO “TODO” jelzések frissítve; AS “PENDING” frissítve
- [x] Uncommitted doc-only változások (BA sessionből maradt, AY commit hash + “Következő session feladata”
  szinkronizálás) — beleépítve ebbe a session commitba
- [x] Mappastruktúra (Nyitott teendők #2) ellenőrizve `find` paranccsal: mind a 27 Swift fájl már
  végleges alkönyvtárban van (`App/`, `Components/`, `Models/`, `Services/`, `Theme/`, `Views/` +
  `Views/Calculate/`, `Views/Countdown/`, `Views/Snippets/`) — **nincs hátralévő munka**, csak dokumentáció
  frissítés volt szükséges (handoff.md fájllista frissítve, `CopyButton.swift` + `DeadlineDetailSheet.swift`
  hozzáadva a listához — korábban hiányoztak)
- [x] `docs/buglist.md` — 6 új bejegyzés felhasználói visszajelzés alapján (mind csak dokumentálva,
  implementáció nem történt): `BUG-MANUAL-1` (manual frissítés bezárási metódus miatt),
  `ENH-DEVDOCS-1` (fejlesztői dokumentáció hiányzik), `BUG-TRASH-1` (editor trash visszateszi a törölt
  snippetet), `BUG-DETAILDELETE-1` (CountdownDetailView törlés után nem navigál vissza), `UX-2` (max
  ablakszélesség 520→600pt felülvizsgálat, alternatíva fix 500pt), `ENH-DEFERRED-1` (lokalizáció +
  Settings/About/Help menü deferred dokumentálása); `UX-1` státusz ✅ KÉSZ-re javítva (ténylegesen
  implementálva volt AU sessionben, buglist.md ezt nem tükrözte)
- Git commit: `d612afe`, `9c9010f`

**Utólagos kiegészítés (ugyanaz a session, folytatás a felhasználó újabb visszajelzése után):**
- [x] `BUG-NOTESDISMISS-1` 🔴 felvéve `docs/buglist.md`-be — a `NotesSheet` X gombja továbbra is szó
  nélkül ment+dismiss, NEM követi a `SnippetEditSheet` (AZ session) dirty-check + confirm alert mintáját.
  Ez ellentmond a BA session bejegyzésének, amely tévesen állította, hogy a `NotesSheet` már helyes —
  a következő sessionben a tényleges kódot kell ellenőrizni, nem a korábbi feljegyzést készpénznek venni
- [x] `countdownApp-handoff.md` “Következő session feladata” listája bővítve 7. pontként

**Következő session:** prioritás felülvizsgálva — `BUG-TRASH-1`, `BUG-DETAILDELETE-1`, `BUG-NOTESDISMISS-1`
mind 🔴 kritikus használhatósági hibák, elsőként ezek közül érdemes választani

**További utólagos kiegészítés:**
- [x] `ENH-NOTEBADGE-1` 🟢 felvéve `docs/buglist.md`-be — vizuális jelzés (pl. pink dot badge a név mellett)
  a countdown itemen, ha van hozzá note; részletek (pozíció, szín, hol jelenjen meg) egyeztetendők
- [x] `countdownApp-handoff.md` “Következő session feladata” listája bővítve 8. pontként

---
## Session BD — 2026-08-13 (BUG-DETAILDELETE-1)

### Session BD — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md, buglist.md elolvasva
- [x] `CountdownDetailView.swift` + `CountdownView.swift` elolvasva — root cause megerősítve:
  `onDelete()` eltávolítja az itemet az `items`-ből és ment, de `dismiss()` nem lett hívva —
  a view bent maradt a törölt itemen
- [x] **BUG-DETAILDELETE-1** — `CountdownDetailView`: `@Environment(\.dismiss) private var dismiss`
  hozzáadva; delete alert destructive ágában `onDelete()` mellé `dismiss()` hívás — navigáció
  visszaugrik `CountdownView`-ra a törlés után
- [x] Build OK, git commit: `485e363`
- [x] `docs/buglist.md` — BUG-DETAILDELETE-1 ✅ KÉSZ státuszra frissítendő (külön lépés)

**Következő session:** BUG-TRASH-1 🔴 (editor trash visszateszi a törölt snippetet) vagy
ENH-NOTEBADGE-1 🟢 (note badge a countdown itemen) — egyeztetés alapján

---

## Session BE — 2026-08-13 (BUG-TRASH-1)

### Session BE — LEZÁRVA
- [x] `SnippetEditSheet.swift` elolvasva — root cause azonnal megvolt
- [x] **BUG-TRASH-1** — delete alert destructive ágában `shouldSaveOnDisappear = false` hozzáadva
  a `onDelete?(id)` + `dismiss()` elé; `.onDisappear` így nem hívja `commitSave()`-t törlés után
  (azonos minta mint a "Quit without saving" ág)
- [x] Build OK, git commit: `6dfb0ab`
- [x] docs frissítve

**Következő session:** ENH-NOTEBADGE-1 🟢 vagy UX-2 🟡 — egyeztetés alapján

---

## Session BJ — 2026-08-14 (Distribution előkészítés: PRODUCT_NAME + Bundle ID)

### Session BJ — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md elolvasva (előző session token-limitben megszakadt,
  ez a folytatás/lezárás)
- [x] Root cause: menüsorban "countdownApp" jelent meg NightShift helyett — `INFOPLIST_KEY_CFBundleDisplayName`
  csak a Finder/Launchpad nevet állítja, a menüsort a `CFBundleName` (= `PRODUCT_NAME`, alapból `$(TARGET_NAME)`) adja
- [x] **Bundle ID + PRODUCT_NAME** — `project.pbxproj`, fő target (`countdownApp`) Debug (AB699A2E) és
  Release (AB699A2F) build config blokkjában: `PRODUCT_BUNDLE_IDENTIFIER` `com.arrayoflilly.countdownApp` →
  `com.arrayoflilly.nightshift`; `PRODUCT_NAME` `$(TARGET_NAME)` → `NightShift`. Tests/UITests target blokkok
  (AB699A31/32/34/35) érintetlenek — bundle ID-juk `com.arrayoflilly.countdownAppTests` /
  `com.arrayoflilly.countdownAppUITests` marad, `PRODUCT_NAME` marad `$(TARGET_NAME)`
- [x] Ellenőrzés: `git diff` — csak 4 sor változott (2 blokk × 2 kulcs), Tests blokkok nem szerepelnek a diffben
- [x] Build ellenőrzés: `xcodebuild -scheme countdownApp -configuration Debug build` → **BUILD SUCCEEDED**,
  termék `NightShift.app`, `CFBundleIdentifier` = `com.arrayoflilly.nightshift` (PlistBuddy-vel megerősítve)
- [x] Git commit: `e5e771a`

**Következő session:** ENH-HELP-1 🟡 — Help menü/ablak implementáció, IconKeeper mintája alapján;
  3 egyeztetési pont (HelpItem data model, .searchable keresés, szekciók: Overview/Countdown/Calculate/
  Snippets/Recovery) a felhasználó előzetes üzenetében már felvetve, jóváhagyás a következő session elején
