# countdownApp — Progress

## Session I — 2026-08-11 (fix magasság toggle-álló, háttérszín, divider)

### Elvégzett változások

**SnippetEditSheet.swift — állandó magasság**
- `sheetMinHeight` egyszerűsítve: `680` fix (többé nem függ `isEditing`-től)
- EDIT/VIEW toggle-kor nem változik az ablak mérete
- EDIT mód `PlainTextEditor` háttér: `AppTheme.dark` → `AppTheme.calculateBackground` (#060503)

**NotesSheet.swift — állandó magasság**
- `.frame(minWidth: 480, minHeight: 520)` fix (többé nem függ `isEditing`/`notes.isEmpty`-től)
- EDIT mód `PlainTextEditor` háttér: `AppTheme.dark` → `AppTheme.calculateBackground` (#060503)

**SharedEditorComponents.swift — CSS**
- `body { background: #2A2015; }` → `#060503`
- `pre { background: rgba(0,0,0,0.45) }` → `rgba(255,255,255,0.07)` (code blokk: gyengén látható fehéres kiemelés a near-black háttéren)

**SnippetsView.swift — divider + levegő**
- Sor `padding(.vertical, 11)` → `14`
- Divider `white.opacity(0.08)` → `0.15`

### Session I — NYITOTT
- [ ] Build ellenőrzés
- [ ] Git commit (Session E–I összes változás)

---

## Session H — 2026-08-11 (fix magasság NotesSheet, QoS fix, title kijelölés)

### Elvégzett változások

**NotesSheet.swift — fix magasság (Session F dinamikus megközelítés lezárva)**
- `webHeight` state és `clampedWebHeight` computed property eltávolítva (JS-driven resize ejtve)
- `.frame(minWidth: 480, minHeight: nil)` → `.frame(minWidth: 480, minHeight: 360/520)`:  
  EDIT mód / üres: 360pt; VIEW mód + tartalom: 520pt (azonos logika mint SnippetEditSheet-ben)
- VIEW mód `MarkdownWebView` frame: `onHeightChange` callback eltávolítva → `.frame(maxWidth: .infinity, maxHeight: .infinity)` (kitölti a fix sheet területet, belül scrollol)
- Fejléc komment frissítve: DESIGN (Session H)

**SnippetEditSheet.swift — QoS priority inversion végleges fix (H-2)**
- `onAppear` + `makeFirstResponder(nil)` teljesen eltávolítva — ez volt a warning forrása (AppKit Default-QoS szálat blokkolt a User-Interactive main thread-en)
- `@FocusState private var titleFocused: Bool` hozzáadva (mindig `false`)
- Title TextField: `.focused($titleFocused)` — SwiftUI sosem aktiválja, auto-focus nem érvényesül
- `import AppKit` marad (NSPasteboard és NSFont miatt szükséges)

### Snippet sor szín — nem implementálva (2. feladat)
- A sor háttere jelenleg `AppTheme.calculateBackground` (#060503, near-black)
- A `snippetRow` HStack-ben `.background()` nincs — ott kellene implementálni ha szín kell
- Lehetséges opciók a palettából:
  - `#51422E` (freeColors[1], lighter brown) — meleg, de a fekete háttértől eléggé elkülönül
  - `#403873` (freeColors[5], dark purple) — hűvösebb, erősen elkülönül
  - `#3D3222` — nem paletta szín, közbülső barna (ha barna marad a szándék)
- Implementáció helye: `SnippetsView.swift` `snippetRow()` függvény, HStack-en `.background(Color(...))` vagy `Color(...).opacity(0.X)` a near-black háttérre rétegezve

**SnippetsView.swift — lista finomhangolás**
- Divider: `opacity(0.05)` → `0.08`, `padding(.leading, 20)` → `padding(.horizontal, 20)` (szimmetrikus, nem ér ki a szélig)
- Preview szöveg: `prefix(72)` → `prefix(140)`, `lineLimit(1)` → `lineLimit(2)`
- Editor háttérszín: `#060503` = `calculateBackground` marad (belesimuló, mégsem azonos a lista háttérrel vizuálisan — a sheet modal kontextusa elkülöníti)

### Session H — NYITOTT
- [ ] Build ellenőrzés
- [ ] Git commit (Session E + F + G + H összes változás)

---

## Session G — 2026-08-11 (SnippetEditSheet VIEW mód compile fix)

### Elvégzett változások

**SnippetEditSheet.swift — VIEW mód MarkdownWebView frame compile fix**
- Root cause: `NSViewRepresentable`-re alkalmazott `.frame(maxWidth:, height:)` és
  `.frame(maxWidth:, maxHeight:)` is compile error-t okoz egyes Xcode verziókban,
  mert a kompiler nem tudja egyértelműen feloldani melyik `.frame()` overloadot kell
  hívni (SwiftUI View protokoll vs NSViewRepresentable wrapper saját frame metódusa).
- Fix: `MarkdownWebView(...)` köré `VStack(spacing: 0)` wrapper, és a `.frame()`
  a VStack-re kerül (ami tisztán SwiftUI View, nem NSViewRepresentable):
  ```swift
  VStack(spacing: 0) {
      MarkdownWebView(markdown: snippetBody, onHeightChange: { h in webHeight = h })
  }
  .frame(maxWidth: .infinity, minHeight: clampedWebHeight, maxHeight: clampedWebHeight)
  ```
  `minHeight + maxHeight` együtt fix magasságot ad, mint a korábbi `height:` szándéka volt.
- Fájl header komment frissítve a fix dokumentálásával.

### Session G — NYITOTT
- [ ] Build ellenőrzés
- [ ] Snippet szín döntés és implementáció (ha user úgy dönt)
- [ ] Git commit (Session E + F + G összes változás)

---

## Session F — 2026-08-11 (ColorPicker + VIEW-mode auto-height + snippet szín javaslat)

### Elvégzett változások

**ColorPickerSheet.swift — két vizuális finomhangolás**
- Active stroke vastagság: `lineWidth: isSelected ? 3 : 1.5` → `2 : 1.5`
  (a 3px aktív kör túl vastag volt, a 2px elegánsabb)
- Auto swatch: `Color.white` → `Color.white.opacity(0.70)`
  (az amber háttéren a teli fehér kör túl kirívóan vakított)

**SharedEditorComponents.swift — MarkdownWebView auto-height callback**
- Új `var onHeightChange: ((CGFloat) -> Void)? = nil` paraméter
- `makeCoordinator()` + `Coordinator: NSObject, WKNavigationDelegate` hozzáadva
- `didFinish`: `evaluateJavaScript("document.body.scrollHeight")` → callback-en
  visszaadja a renderelt tartalom magasságát (CGFloat)
- Backward-compatible: a callback opcionális, meglévő hívók változatlanul fordulnak

**NotesSheet.swift — VIEW mód tartalom-méret szerinti magasság**
- `@State private var webHeight: CGFloat = 280` hozzáadva
- `clampedWebHeight` computed property: `min(max(webHeight, 160), screenH - 54)`
  (minimum 160pt; maximum screen magassága - 54pt ≈ 1.5 cm-rel kisebb)
- `.frame(minWidth: 480, minHeight: 360)` →
  `.frame(minWidth: 480, minHeight: (isEditing || notes.isEmpty) ? 360 : nil)`
  EDIT módban és üres állapotban marad a 360pt minimum.
  VIEW módban nem üres tartalommal: nincs fix minimum, a sheet a content méretéhez alkalmazkodik.
- VIEW ág: `MarkdownWebView(markdown: notes, onHeightChange: { h in webHeight = h })`
  `.frame(maxWidth: .infinity, maxHeight: clampedWebHeight)`

**SnippetEditSheet.swift — VIEW mód tartalom-méret szerinti magasság**
- Ugyanaz a megközelítés mint NotesSheet-ben
- `@State private var webHeight: CGFloat = 280`
- `clampedWebHeight` (azonos logika)
- `.frame(minWidth: 480, minHeight: (isEditing || snippetBody.isEmpty) ? 520 : nil)`
- VIEW ág: `MarkdownWebView(markdown: snippetBody, onHeightChange: ...)` + `clampedWebHeight`
- MEGJEGYZÉS: ez a verzió compile error-t adott (ld. Session G fix)

**Snippet szín — csak javaslat, nem implementálva**
- `#51422E` (freeColors[1], light brown) → potenciális alternatívák:
  - `#403873` (freeColors[5], sötét lila) — hidegebb, jól elkülönül
  - `#3D3222` (közbülső barna, `#51422E` és `#30271B` között) — ha barna maradna
  - `#30271B` (freeColors[0], legsötétebb barna a palettán)
- Nem írtuk át, user dönt.

### Session F — LEZÁRT
- [x] `ColorPickerSheet.swift` — active stroke 3→2, Auto opacity 1.0→0.70
- [x] `SharedEditorComponents.swift` — MarkdownWebView Coordinator + onHeightChange
- [x] `NotesSheet.swift` — webHeight state + clampedWebHeight + VIEW mód dinamikus frame
- [x] `SnippetEditSheet.swift` — ugyanaz (compile error volt, Session G javította)
- [ ] Build ellenőrzés
- [ ] Git commit

---

## Session E — 2026-08-11 (SNIPPETS UI polish)

### Elvégzett változások

**SnippetEditSheet.swift — compile fix**
- `ProjectComboBox` → `ProjectField` névjavítás (a fájlban dupla header + rossz
  típusnév maradt bent az újraírásból; compile error volt).
- Dupla import blokk + dupla fejléckomment eltávolítva.
- `minHeight: 360` → `minHeight: 520` (tágasabb szövegterület).

**SnippetsView.swift — szekciófejléc cleanup**
- Volt: minden projektnévnél pencil + xmark gomb (2 ikon, mindig látható) —
  vizuálisan elnyomta a sorok Copy gombját.
- Fix: egyetlen chevron (`˅`) közvetlenül a projektnév után, `white.opacity(0.45)`;
  kattintásra natív macOS `Menu` nyílik: "Rename project…" / "Delete project" (destructive).
- `.menuIndicator(.hidden)` — megakadályozza, hogy a `.borderlessButton` style
  saját extra chevront adjon hozzá (dupla nyíl bug fix).

### Session E — LEZÁRT
- [x] `SnippetEditSheet.swift` — `ProjectComboBox` → `ProjectField` compile fix
- [x] `SnippetEditSheet.swift` — dupla header cleanup, `minHeight` 360→520
- [x] `SnippetsView.swift` — pencil+xmark → egyetlen chevron Menu
- [ ] Git commit

---

## Session D — 2026-08-11 (SNIPPETS sort fix)

### Elvégzett változások

**SnippetsView.swift — `projectKeys` sort fix**
- Root cause: `Array(Set(...)).sorted()` — a `Set` Swift-ben hash-alapú véletlenszerű
  sorrendű; a default `.sorted()` case-sensitive (nagybetűs nevek hamarabb jönnek
  mint kisbetűsek ASCII sorrendben), ezért a megjelenített sorrend nem volt ABC.
- Fix: `localizedCaseInsensitiveCompare` a sortban + `caseInsensitiveCompare("General")`
  a General-check-ben (robusztusabb: "general"/"GENERAL" is utolsó lesz).
- Eredmény: book-identifier → countdown app → fotomuveszet-ocr-test → iconkeeper → General ✅

**Snippet.swift — `load()` whitespace migration**
- Root cause: a tárolt project (és title) stringekben vezető szóköz volt, ezért
  a sort az eredeti, nem-ABC sorrendet adta vissza (space ASCII 32 < 'b' ASCII 98).
- `load()` mostantól minden snippet project + title stringjét `.trimmingCharacters(in: .whitespaces)`-szel
  tisztítja betöltéskor, ÉS visszamenti a javított adatot UserDefaults-ba —
  egyszeri indítás után az összes régi rossz adat automatikusan javul.

**SnippetEditSheet.swift — `commitSave()` trim**
- Jövőbeli mentéseknél is trim, hogy a whitespace hiba ne tudjon visszatérni.

### Session D — LEZÁRT
- [x] `SnippetsView.swift` — `projectKeys` case-insensitive sort + General-last fix
- [x] `Snippet.swift` — `load()` whitespace migration (trim + re-save)
- [x] `SnippetEditSheet.swift` — `commitSave()` trim

**SnippetsView.swift — projekt rename + delete**
- Szekciófejlécben pencil (rename) + x (delete) gombok, 22×22, white 5% bg, white 35% ikon
- Rename: `.alert` TextField-del; az összes érintett snippet `project` mezője frissül,
  trim + üres/azonos név guard; `Snippet.save()` hívódik
- Delete: `.alert` destructive gombbal; üzenetben snippet-számlálás ("N snippet");
  `snippets.removeAll` + `Snippet.save()`
- `renameProject(from:to:)` + `deleteProject(_:)` private helper függvények
- [ ] Git commit

---

## Session C — 2026-08-11 (SNIPPETS implementáció)

### Elvégzett változások

**Architektúra: editor duplikáció megszüntetve**
- `MarkdownWebView` és `PlainTextEditor` kiemelve `SharedEditorComponents.swift`-be
  (internal hozzáférhetőség — mindkét sheet használja)
- `NotesSheet.swift` újraírva: a private verziók törölve, shared komponenseket használja;
  logika/viselkedés azonos (live $notes binding, copy/trash/toggle gombok)
- `markdownCSS` konstans szintén a shared fájlban — egyetlen forrás

**Új fájlok**
- `SharedEditorComponents.swift` — MarkdownWebView + PlainTextEditor + markdownCSS
- `Snippet.swift` — data model: id/title/body/project/createdAt/updatedAt;
  Snippet.load() / Snippet.save() persistence (UserDefaults "snippets" kulcs, JSON)
- `SnippetEditSheet.swift` — ugyanaz a VIEW/EDIT toggle struktúra mint NotesSheet,
  plusz editable Title (TextField, alienLeagueBold 22) + Project tag mező (alienLeague 13);
  onSave + onDelete callback (nil → new snippet, non-nil → edit existing);
  checkmark toggle: ha isEditing→false, commitSave() hívódik automatikusan;
  új snipetnél EDIT módban nyílik, meglévő (nem üres) snipetnél VIEW módban
- `SnippetsView.swift` — 3. tab főnézete: SNIPPETS fejléc (alienLeagueBold 20, amber),
  projekt szerint csoportosított lista (alphabetically sorted project keys),
  szekciófej: uppercase projekt név, amber; sor: title + 72 char body preview + Copy gomb;
  per-row copy feedback (1s checkmark); + gomb → SnippetEditSheet (új)

**Módosított fájlok**
- `ContentView.swift` — 3. mode: `case snippets = "Snippets"`, SF Symbol `doc.plaintext`,
  switch branch `SnippetsView()`
- `NotesSheet.swift` — private MarkdownWebView + PlainTextEditor törölve (shared-ből jön);
  header refaktorálva `headerButton()` helper-rel (DRY); funkcionalitás változatlan

### Session C — NYITOTT
- [ ] Xcode: mind az 5 fájl hozzáadása a projekthez (drag-and-drop navigátorba)
  (SharedEditorComponents.swift, Snippet.swift, SnippetEditSheet.swift, SnippetsView.swift
   — ContentView.swift és NotesSheet.swift már a projektben van, csak felülírtuk)
- [ ] Build ellenőrzés — compile hibák lehetnek ha a shared komponensek névütköznek
  (pl. ha Xcode-ban volt már MarkdownWebView a NotesSheet scope-ján kívül)
- [ ] Git commit
- [ ] Roboto Flex Light / marked.min.js (előző sessionből áthúzódó nyitott pontok)

---

## Session B — 2026-08-11 (SLOT-NOTES: EDIT mód padding fix)

### Session B — LEZÁRT
- [x] NotesSheet.swift — PlainTextEditor inset paraméter + hívói oldal fix
- [ ] Build + EDIT mód ellenőrzés
- [x] Git commit — `7f47511`

---

## Session 37 — 2026-08-11 (SLOT-NOTES horror bug diagnózis + fixek)

### Session 37 — NYITOTT
- [x] NotesSheet.swift — Bundle URL keresés bővítve (marked.min + marked.umd)
- [x] NotesSheet.swift — fallbackHTML(): <pre> → <p> tag, sortörés fix
- [x] ColorPickerSheet.swift — AUTO label: 9pt → 12pt, opacity 0.75 → 0.85
- [ ] **USER TEENDŐ**: marked.min.js berakása resources/ mappába (Terminal + Xcode)
- [ ] Roboto Flex Light Info.plist + CSS
- [ ] Git commit (Session 36 + 37 összes változás)
