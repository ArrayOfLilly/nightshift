# countdownApp — Progress

## Session BN — 2026-08-14 (BUG-SNIPPEDITBEACHBALL-1 vizsgálat + BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1 root cause megerősítve — FOLYAMATBAN, implementáció NEM történt)

### Session BN — FOLYAMATBAN (kódolvasás + dokumentálás, implementáció még nem)
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] `SnippetEditSheet.swift`, `Snippet.swift`, `SnippetsView.swift` elolvasva
- [x] **BUG-SNIPPETSAVE-1** — root cause MEGERŐSÍTVE: `showDismissConfirm` alert "Save and quit" ága
  (`commitSave(); dismiss()`) nem állítja `shouldSaveOnDisappear = false`-ra → `.onDisappear` a `dismiss()`
  után még egyszer lefuttatja `commitSave()`-t. Fix: egy sor, `shouldSaveOnDisappear = false` hozzáadása
  a "Save and quit" ágban, `commitSave()` elé (minta: "Quit without saving" ág). NEM implementálva.
- [x] **BUG-SNIPPETDUP-1** — újraértelmezve: NEM flaky/gyors-kattintás hiba, hanem determinisztikus.
  Root cause: `SnippetEditSheet.snippet` egy `let Snippet?`, új snippetnél `nil`, soha nem frissül a sheet
  élettartama alatt → minden `commitSave()` új UUID-t generál (`Snippet.committed(from: nil, ...)`) →
  `SnippetsView` `showNewSheet` `onSave` mindig `append`-el (nincs id-alapú upsert) → minden checkmark egy
  ÚJ, külön snippetet hoz létre update helyett. Összeadódik BUG-SNIPPETSAVE-1 double-call hibájával.
  Felhasználó által jelentett konkrét eset ("Új snippet, check, módosítás után újra check, 2-t ment
  belőle") pontosan ez. Javasolt fix: `snippet` `let` → `@State private var`, `commitSave()` sikeres
  mentés után `self.snippet = s`. NEM implementálva, egyeztetésre vár.
- [x] **BUG-SNIPPEDITBEACHBALL-1** — a korábbi 3 elméletből 2 CÁFOLVA kódolvasással (nincs load()-hurok,
  nincs concurrency-isolation gyanús kód), 1 RÉSZBEN MEGERŐSÍTVE (`.onDisappear` double-call — lásd
  BUG-SNIPPETSAVE-1). Felhasználó ÚJ reprodukálást jelentett: app inaktív→aktív váltás közben a snippet
  sheet már nyitva volt, görgetés előtt egy kattintásra azonnali beachball — ez egyik elmélettel sem
  magyarázható közvetlenül, gyanús terület (még nem ellenőrzött): `MarkdownWebView` /
  `SharedEditorComponents.swift` (WKWebView JS-bridge állapot ablak-aktiválás után). NYITOTT, külön
  vizsgálat szükséges.
- [x] **BUG-SNIPPEDITBEACHBALL-1 — HARMADIK repró** (felhasználó jelentése, session folytatás): meglévő
  snippet szerkesztése → checkmark → X (sheet bezárva) → átváltás böngészőre (app inaktívvá vált) →
  vissza az app ablakára kattintva → azonnali beachball. Különbség az előző reprótól: itt a sheet
  MÁR zárva volt, tehát nem kizárólag a nyitva hagyott MarkdownWebView gyanús — app-szintű
  (NSApplication activate) úton futó/befejezetlen munka is szóba jöhet. `docs/buglist.md`-be rögzítve.
- [ ] Fix implementáció (BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1) — felhasználói jóváhagyásra vár
- [x] `SharedEditorComponents.swift` elolvasva — nincs benne hurok/blokkoló hívás; a HARMADIK reprónál
  (sheet már zárva) ez a fájl önmagában nem lehet ok, mert a WKWebView már nincs életben. Gyanú
  áthelyezve WKWebView deinit időzítésére és/vagy `countdownAppApp.swift` AppDelegate lifecycle hookra.
- [ ] `countdownAppApp.swift` (AppDelegate + WindowGroup lifecycle hook) elolvasása — következő lépés
- [ ] Build, teszt, git commit — még nem történt
- [x] `docs/buglist.md` frissítve (mindhárom bug root cause / repró szekciója)
- [ ] `docs/countdownApp-handoff.md` frissítése — folyamatban

**Következő lépés (session belül vagy session-határ után):** 1) felhasználói jóváhagyás a
 BUG-SNIPPETSAVE-1 + BUG-SNIPPETDUP-1 fixekre (mindkettő javasolt megoldással fent, buglist.md-ben
 részletezve), 2) `SharedEditorComponents.swift` elolvasása a beachball új reprodukálási módjának
 vizsgálatához, 3) implementáció + build + git commit.

---

## Session BL — 2026-08-14 (BUG-PROJECTDELETE-1)

### Session BL — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md, buglist.md elolvasva
- [x] Snippet.swift + SnippetsView.swift elolvasva — root cause azonosítva
- [x] **BUG-PROJECTDELETE-1** — `SnippetsView.deleteProject(_:)`:
  - Volt: `snippets.removeAll { $0.project == project }` (törlés, adatvesztés)
  - Javítva: `snippets.map { s in ... s.project = "General" }` (`renameProject` mintája, target = "General")
  - Adatvesztés nélkül, összes snippet "General" kategóriába kerül
- [x] Build OK
- [x] `docs/buglist.md` — BUG-PROJECTDELETE-1 ✅ KÉSZ státuszra frissítve
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Git commit: PENDING

**Következő session:** BUG-PROJECTRENAME-1 🔴 (snippet project mező nem frissül átnevezéskor) vagy BUG-SNIPPETSAVE-1 🔴 (save-and-quit nem őrzi meg a legutóbbi módosítást)

---

## Session BM — 2026-08-14 (BUG-PROJECTRENAME-1 + BUG-DISPLAYNAME-1)

### Session BM — LEZÁRVA
- [x] Claude.md, progress.md, countdownApp-handoff.md, buglist.md elolvasva
- [x] SnippetsView.swift elolvasva — root cause azonosítva
- [x] **BUG-PROJECTRENAME-1** — `SnippetsView.renameProject(_:to:)`:
  - Volt: editTarget ID-only snapshot helyett `Snippet` value snapshot
  - Javítva: `editTarget: EditTarget?` (ID-only struct); `renameProject(_:to:)` map-pel frissíti a snippetek `project` mezőjét az új névre
  - Sheet a sheet-open közben történő projekt átnevezés után is helyesen tükrözi az új projektnevet
- [x] **BUG-DISPLAYNAME-1** — macOS title bar Display Name-ek összekeveredtek
  - Calculate Tab: `.navigationTitle("Calculate")` CalculateView gyökerébe
  - Snippets Tab: `.navigationTitle("Snippets")` SnippetsView gyökerébe
  - Countdown Tab: már volt `.navigationTitle("Countdown")` (érintetlen)
  - `CFBundleName` = `"NightShift"` fallback már nem jelenik meg helyesen ahol van explicit navigationTitle
- [x] Build OK
- [x] `docs/buglist.md` — BUG-PROJECTRENAME-1 + BUG-DISPLAYNAME-1 ✅ KÉSZ státuszra frissítve
- [x] `docs/progress.md` + `docs/countdownApp-handoff.md` frissítve
- Git commit: PENDING

**Következő session:** BUG-SNIPPETSAVE-1 🔴 (save-and-quit) — root cause már azonosított, dokumentálás szükséges

---

## Session BK — 2026-08-14 (5 új bug dokumentálása, ENH-HELP-1 előkészítés)

### Session BK — LEZÁRVA (dokumentáció only, implementáció nem történt)
- [x] Claude.md elolvasva
- [x] Felhasználó 5 új bugot jelentett, mind felvéve `buglist.md`-be (root cause hipotézisekkel, ahol volt):
  - **BUG-PROJECTRENAME-1** 🔴 — project átnevezéskor a hozzá tartozó snippetek `project` mezője nem frissül
  - **BUG-PROJECTDELETE-1** 🔴 — project törléskor a snippetek nem kerülnek át General alá (viselkedésváltás igény, korábbi döntés visszavonása)
  - **BUG-SNIPPETSAVE-1** 🔴 — snippet save and quit csak a korábbi checkmarkolt állapotot őrzi meg, a legutóbbi módosítás elvész; gyanú: `BUG-CHECKMARKDIRTY-1`-hez hasonló baseline-frissítési hiba
  - **BUG-SNIPPETDUP-1** 🟡 — új snippet néha duplikáltan jön létre, nem reprodukálható determinisztikusan; gyanú: hiányzó double-submit védelem gyors/ismételt checkmark kattintásnál
  - **BUG-DISPLAYNAME-1** 🔴 — 3 tab közül 2 ugyanazt a Display Name-et ("NightShift") mutatja Snippets és Calculate tabon; feltehetően megosztott/nem tab-specifikus name forrás. Megjegyzés: az előző (BJ) sessionben történt PRODUCT_NAME → "NightShift" átnevezés (menüsor/Bundle ID) kontextusként releváns lehet, de a hiba az app-on belüli tab címekben van, nem a Bundle/menüsor szinten
- [x] Egyik bug sem implementálva ebben a sessionben — mind NYITOTT, root cause ellenőrzés + egyeztetés a következő session(ek) feladata

**Következő session:** felhasználói döntés szükséges a sorrendről — az 5 új bug egyike (javasolt: BUG-DISPLAYNAME-1
vagy BUG-SNIPPETSAVE-1, mindkettő 🔴 és gyanítható root cause-szal rendelkezik) VAGY a help rendszer tervezésének
folytatása (ENH-HELP-1, ld. BJ session hagyatéka). A felhasználó jelezte, hogy a bugok dokumentálása után a help
rendszer tervezésére szeretne áttérni — ez legyen a következő fókusz, hacsak nincs sürgősebb bugfix igény.

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
  Q–Y sessionok `progress.md`-ben "Git commit: PENDING/TODO" jelziként szerepeltek, de a kód valójában már
  commitolva volt — mind a 9 hely frissítve tényleges hash-ekkel (`f09bd0c`, `dc656e3`, `822f154`, `ca4445a`,
  `37b1674`, `ebe890a`, `678bea6`, `25f7591`)
- [x] `countdownApp-handoff.md` — AL session tévesen `4fd8eef`-et mutatott (az AK docs commit, nem AL) →
  javítva `ca4445a`-ra; AN/AM/AO "TODO" jelzések frissítve; AS "PENDING" frissítve
- [x] Uncommitted doc-only változások (BA sessionből maradt, AY commit hash + "Következő session feladata"
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
- [x] `countdownApp-handoff.md` "Következő session feladata" listája bővítve 7. pontként

**Következő session:** prioritás felülvizsgálva — `BUG-TRASH-1`, `BUG-DETAILDELETE-1`, `BUG-NOTESDISMISS-1`
mind 🔴 kritikus használhatósági hibák, elsőként ezek közül érdemes választani

**További utólagos kiegészítés:**
- [x] `ENH-NOTEBADGE-1` 🟢 felvéve `docs/buglist.md`-be — vizuális jelzés (pl. pink dot badge a név mellett)
  a countdown itemen, ha van hozzá note; részletek (pozíció, szín, hol jelenjen meg) egyeztetendők
- [x] `countdownApp-handoff.md` "Következő session feladata" listája bővítve 8. pontként

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

---
