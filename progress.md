# countdownApp — Progress

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

### Diagnózis (screenshotokkal igazolva)

Két screenshot érkezett a build utáni állapotról:
- **VIEW mód**: marked.js MŰKÖDIK, markdown helyesen renderel (headingek amberrel,
  inline code formázva, normál bekezdések) — RENDBEN VAN, nem kell hozzányúlni.
- **EDIT mód**: szöveg közvetlenül a sötét doboz bal-felső sarkán ül, belső
  padding nélkül — ez a textContainerInset = .zero mellékhatása.

### Root cause

A PlainTextEditor textContainerInset = .zero volt hardcode-olva. A hívási oldalon
SwiftUI .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 40) modifier-ek
KÜLSŐ margókat adnak (a sötétbarna doboz körül), de a szöveg maga az NSTextView
zero-inset szélén marad — a belső tér hiányzik.

### Fix (NotesSheet.swift)

- PlainTextEditor: új var inset: NSSize = .zero paraméter
- makeNSView: textView.textContainerInset = inset (volt: .zero hardcode)
- Hívói oldal: inset: NSSize(width: 24, height: 20) átadva
  (megfelel a CSS padding: 20px 24px 40px-nek)
- SwiftUI .padding(.horizontal, 24)/.padding(.top, 20)/.padding(.bottom, 40)
  eltávolítva az EDIT ágból (az inset veszi át belső paddingként)

### Session B — LEZÁRT
- [x] NotesSheet.swift — PlainTextEditor inset paraméter + hívói oldal fix
- [ ] Build + EDIT mód ellenőrzés (szöveg 24px balra, 20px fentről beljebb)
- [x] Git commit — `7f47511`

---

## Session 37 — 2026-08-11 (SLOT-NOTES horror bug diagnózis + fixek)

### Root cause azonosítva: marked.js HIÁNYZIK a bundleből

A `resources/` mappában nem volt `marked.min.js` (és `marked.umd.js` sem).
Ezért `Bundle.main.url(forResource: "marked.min", ...)` mindig `nil`-t adott vissza,
a `guard` elbukott, és a `fallbackHTML()` futott le — ami `<pre>` tagbe rakta
a szöveget. A CSS `pre` stílusa: amber bal-szegély (3px solid #F5A623) +
border-radius: 6px + sötét háttér → ez volt a "lekerekített sarkú amber doboz".

### Kódfixek (alkalmazva)

**NotesSheet.swift** — két javítás:
1. Bundle URL keresés bővítve: `marked.min` ÉS `marked.umd` névvel keres
   (fallback sorrendben), így a user bármelyik névvel berakhatja a fájlt.
2. `fallbackHTML()`: `<pre>` → `<p>` tag, plusz `\n → <br>` konverzió a callernél —
   ha valaha is lefut a fallback, a szöveg normálisan, olvashatóan jelenik meg
   (nem kódblokk stílusban).

**ColorPickerSheet.swift** — AUTO label méret: 9pt → 12pt, opacity 0.75 → 0.85
(az eredeti 9pt olvashatatlan volt a 52pt körben).

### User teendő: marked.js berakása (KÖTELEZŐ a VIEW mód javításához)

Terminálból (user gépen):
```bash
cd /Users/ArrayOfLilly/tools/countdownApp/countdownApp/countdownApp/resources
curl -s "https://registry.npmjs.org/marked/-/marked-18.0.9.tgz" -o marked.tgz \
  && tar -xzf marked.tgz \
  && cp package/lib/marked.umd.js marked.min.js \
  && rm -rf package marked.tgz
```

Xcode-ban:
- `resources/marked.min.js` drag-and-drop a projekt navigátorba
- "Copy Bundle Resources" build phase-be kell kerülnie
- Build és teszt

### EDIT mód (Image 2, nem_jo_.png) — külön elemzés

A screenshoton az EDIT mód (checkmark ikon a fejlécben) látható: a PlainTextEditor
amber szöveget mutat fekete dobozban. Vizuálisan ez rendben tűnik a leírás alapján,
de a felhasználó mindkét képet "horror"-nak minősítette — a kontextusból
valószínű, hogy a VIEW mód látványa volt a fő probléma, az EDIT mód megoldódik
a VIEW mód javításával (ha jól néz ki a VIEW, a felhasználó elfogadja az EDIT-et is).
Build után ellenőrizendő mindkét mód.

### Session 37 — NYITOTT
- [x] NotesSheet.swift — Bundle URL keresés bővítve (marked.min + marked.umd)
- [x] NotesSheet.swift — fallbackHTML(): <pre> → <p>, sortörés fix
- [x] ColorPickerSheet.swift — AUTO label: 9pt → 12pt, opacity 0.75 → 0.85
- [ ] **USER TEENDŐ**: marked.min.js berakása resources/ mappába (Terminal + Xcode)
- [ ] **KRITIKUS RETEST**: build után VIEW mód ellenőrzése — most már <p> tagot
  kell kapjon a szöveg, rendesen, sortörésekkel (ha a marked.js be van rakva: teljes
  markdown rendering; ha nincs: legalább nem kódblokk-stílusban jelenik meg)
- [ ] Roboto Flex Light — a user mondta, hogy BENNE VAN a Font mappában;
  Info.plist regisztráció + CSS frissítés MÉG HIÁNYZIK (következő lépés)
- [ ] Git commit

---

## Session 36 — 2026-08-10 (LEZÁRATLAN, session ~90%+ token limitnél — ÚJ HORROR BUG screenshotokkal)

### KRITIKUS: a két mód MÉG MINDIG rosszul néz ki a `PlainTextEditor` +
gomb-konzisztencia fix UTÁN is (2 friss screenshot, 2026-08-11 10:02)

**Screenshot 1 (VIEW mód, header pencil ikon látszik → isEditing=false)**:
a szöveg ("sdcadcdsacascdsa") NEM normál bekezdésként jelenik meg a
MarkdownWebView-ban. Ehelyett egy KICSI, lekerekített sarkú, amber
bal-szegélyes dobozában úszó fehér szövegként látszik, a bal felső sarok
közelében, a doboz alatt/mellett pedig hatalmas üres sötétbarna terület.
Ez NEM egyezik a várt CSS-sel (a `body` egyszerű `<p>`-ként kellene
renderelje, semmilyen border/rounded-corner/highlight nem lenne rajta).
Gyanú: valamilyen selection-highlight vagy WKWebView render hiba, ESETLEG
a `MarkdownWebView` és a `PlainTextEditor` állapotok összekeverednek
(pl. WKWebView még a régi NSTextView selection-highlight stílusát örökli
valahogy, vagy ez ténylegesen egy marked.js/CSS anomália).

**Screenshot 2 (EDIT mód, header checkmark ikon látszik → isEditing=true)**:
a szöveg amber színnel látszik a sötétbarna dobozban, ez tűnik rendben
lévőnek (a doboz kitölti a területet, ahogy vártuk a `PlainTextEditor`
fixtől) — DE nem egészen biztos, user "horror"-nak minősítette mindkét
képet együtt, tehát lehet, hogy itt is van vizuális probléma, ami a
screenshot leírásból nem egértelmű.

### User instrukció

A user a session token limitjének ~90%+-án van, ezért KIFEJEZETTEN
csak dokumentálást kért, TOVÁBBI KÓD-VÁLTOZTATÁS NÉLKÜL ebben a
sessionben. **Ez a bug NINCS javítva.**

### Következő session teendői

1. **Első lépés**: kérd meg a usert, mutasson friss screenshotot MINDKéT
   módról újra, hogy pontosan lehessen látni, mi történik most.
2. Vizsgáld meg a `MarkdownWebView.load()` függvényt — lehet, hogy a
   marked.js valamilyen inline elemként (pl. `<code>` vagy list item)
   értelmezi az egyszerű szöveget, vagy a HTML template hibás.
3. Ellenőrizd, hogy a `PlainTextEditor` (új NSViewRepresentable, előző
   session végén írva) tényleg helyesen viselkedik-e — lehet hogy maga
   az új komponens hibás (pl. `textContainerInset` vagy `frame`
   kombinációja még mindig rossz).
4. Ha bizonytalan a diagnózis, KÉRJ screenshot-ot ELSŐ lépésként, mint
   a mostani számos session során bevált megoldás — build nélkül
  csak kódolvasásból többször téves diagnózist adtunk (ld. Session 36
  BUG#1/#2/#3 története).

### Session 36 — EDDIGI ÖSSZES változás (LEZÁRATLAN, git commit MÉG NEM történt meg)
- Cím statikus "NOTES", `alienLeagueBold(24)`, `AppTheme.dark`
- slotLabel/accountname sor eltávolítva a fejlécből
- Gomb dimmelés eltávolítva `CountdownDetailView.swift`-ben
- NotesSheet üres állapot: `note.text.badge.plus` ikon, kattintható
  (isEditing = true-t állít)
- Trash gomb hozzáadva, sorrend: Copy → Edit/View toggle → Trash → Dismiss
- `draftNotes` puffer kiiktatva (BUG #1: sosem commitolt Escape-re)
- Toggle gomb ikon: eye → checkmark, szín/opacitás EGYSÉGESÍTVE a
  Copy/Trash gombokkal (nincs több isEditing-függő színváltozás)
- MarkdownWebView CSS body háttér: #0d0d0d → #2A2015
- Új `PlainTextEditor: NSViewRepresentable` (zero `textContainerInset`)
  váltotta le a SwiftUI `TextEditor`-t
- **DE**: a legfrissebb screenshotok szerint MOST IS rosszul néz ki —
  ld. fenti "KRITIKUS" szekció

### NYITOTT
- [ ] **ELSŐDLEGES**: a fenti "horror" bug diagnózisa és javítása — friss
  screenshotokkal indítsd a következő sessiont
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Git commit — MÉG NEM történt meg, sok kis változás vár commitra

---

## Session 36 — 2026-08-10 (SLOT-NOTES: gomb-konzisztencia + valódi padding-fix)

### User visszajelzés

1. "padding ugyanott van" — a korábbi SwiftUI `.padding()` egyeztetés NEM
   oldotta meg teljesen: a `TextEditor` belső `NSTextView`-jának van egy
   SwiftUI-ból nem nullázható saját `textContainerInset`-je, ami továbbra is
   eltérést okozott a VIEW mód (WKWebView, CSS-ből teljesen kontrollált
   padding) és az EDIT mód között.
2. "a pipa alatt miért nem ugyanolyan a transparency, ha 3 gomb van, legyenek
   egyformák" — a VIEW/EDIT toggle gomb `isEditing`-től függően más
   foreground/background opacitást használt, mint a Copy és Trash gombok
   (állandó `white.opacity(0.7)` fg / `white.opacity(0.07)` bg).

### Fix 1 — gomb-konzisztencia

`NotesSheet.swift` VIEW/EDIT toggle gomb: eltávolítva az `isEditing`-függő
színváltozás. Mostantól **mindhárom** header-gomb (Copy, toggle, Trash)
pontosan ugyanazt a stílust használja: `foregroundStyle(Color.white.opacity(0.7))`,
`background(Color.white.opacity(0.07))`. Csak az ikon változik állapot
szerint (pencil↔checkmark), a szín/opacitás nem.

### Fix 2 — valódi zero-inset text editor

Új privát `PlainTextEditor: NSViewRepresentable` struct (`NotesSheet.swift`
tetején, a `MarkdownWebView` után) — saját `NSTextView` + `NSScrollView`
wrapper:
- `textContainerInset = .zero`
- `textContainer.lineFragmentPadding = 0`
- `drawsBackground = false`, `backgroundColor = .clear` (a külső SwiftUI
  `.background(AppTheme.dark)` adja a színt)
- `NSTextViewDelegate.textDidChange` írja vissza a `@Binding var text: String`-et
  — továbbra is élő binding, nincs draft-puffer (a korábbi BUG #1 fix elve
  megőrizve).

`TextEditor(text: $notes)` lecserélve `PlainTextEditor(text: $notes, font:
NSFont.monospacedSystemFont(...), textColor: NSColor(AppTheme.background))`-re.
Ezzel MINDEN térköz a hívási oldal SwiftUI `.padding()`-jéből jön, a
text view magától nullát ad hozzá — pixelre egyezik a VIEW móddal.

### Session 36 — NYITOTT
- [x] Header 3 gomb (Copy/toggle/Trash) egységes stílus, nincs több
  állapot-függő opacitás-változás
- [x] `PlainTextEditor` új NSViewRepresentable, zero `textContainerInset`
- [x] EDIT tartalom `TextEditor` → `PlainTextEditor` csere
- [ ] **KRITIKUS RETEST**: buildelés után ellenőrizendő, hogy a szöveg
  most már pontosan ugyanott kezdődik-e EDIT és VIEW módban is, és hogy
  a 3 header-gomb vizuálisan azonosnak tűnik-e (csak az ikon változik).
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Git commit (Session 36 teljes — sok kis fix, érdemes egyben commitolni)

---

## Session 36 — 2026-08-10 (SLOT-NOTES: üres állapot is EDIT-be visz)

### User kérés

A jól működő üres állapot placeholder (screenshot igazolta, hogy már jól
néz ki) intuíció szerint kattintható kellene legyen — ugyanaz történjen,
mint a ceruza gombra kattintva (EDIT módba vinni).

### Fix

Az üres-állapot `VStack` (ikon + szöveg) `Button`-ba wrapelve,
`isEditing = true` action-nel. `.contentShape(Rectangle())` a teljes
`.frame(maxWidth: .infinity, maxHeight: .infinity)` területre, hogy ne
csak az ikon/szöveg pixelei legyenek kattinthatók, hanem a teljes doboz
(ugyanaz a mintázat, mint a CalculateView chevron hit-area fixnél).
Szöveg frissítve: "Tap the pencil to start writing." → "Tap to start
writing." (már nem csak a ceruzaval működik).

### Session 36 — NYITOTT
- [x] Üres állapot placeholder kattintható, `isEditing = true`-t állít
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Git commit (Session 36 teljes)

---

## Session 36 — 2026-08-10 (SLOT-NOTES BUG #3: EDIT doboz nem tölti ki a területet)

### Bug report (user, screenshotokkal)

Két screenshot: VIEW módban a sötétbarna doboz szépen kitölti a
rendelkezésre álló területet. EDIT módban viszont a sötétbarna doboz csak
egy vékony, egy sornyi magas sáv a tetején — a maradék terület amber
(a sheet háttere látszik át). "A fél szerkesztő felület padding."

### Root cause

A `TextEditor`-ról hiányzott a `.frame(maxWidth: .infinity, maxHeight: .infinity)`
(amit a VIEW mód MarkdownWebView és az üres-állapot placeholder mindkettő
megkap) — ennélkül a `TextEditor` intrinsic (tartalom szerinti) méretre
húzódott össze, a padding pedig körülötte hatalmas üres amber területet
hagyott.

**Második csapda ugyanitt**: a `.background(AppTheme.dark)` a `.frame(...)`
ELŐTT állt a modifier láncban — SwiftUI-ban a sorrend számít: ha a
háttér a frame-bővítés ELŐTT kerül fel, csak az EREDETI (kicsi) méretet
színezi be, a frame által hozzáadott extra terület transzparens marad.
Ezért cserélni kellett a sorrendet is: előbb `.frame(maxWidth: .infinity,
maxHeight: .infinity)`, UTÁNA `.background(AppTheme.dark)`.

### Fix

```swift
TextEditor(text: $notes)
    .font(.system(.body, design: .monospaced))
    .foregroundStyle(AppTheme.background)
    .scrollContentBackground(.hidden)
    .frame(maxWidth: .infinity, maxHeight: .infinity)   // ← hozzáadva, ELSŐKÉNT
    .background(AppTheme.dark)                           // ← a frame UTÁN
    .padding(.horizontal, 24)
    .padding(.top, 20)
    .padding(.bottom, 40)
```

### Session 36 — NYITOTT
- [x] TextEditor `.frame(maxWidth: .infinity, maxHeight: .infinity)` hozzáadva
- [x] `.background`/`.frame` sorrend javítva (frame előbb, background utána)
- [ ] **KRITIKUS RETEST**: buildelés után ellenőrizendő, hogy a sötétbarna
  doboz most már kitölti-e a teljes területet EDIT módban is, ugyanúgy mint
  VIEW módban.
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Git commit (Session 36 teljes)

---

## Session 36 — 2026-08-10 (SLOT-NOTES BUG #2: láthatatlan EDIT→VIEW gomb)

### Bug report (user)

A felhasználó újra visszajelezte, hogy a badge/mentés-probléma "továbbra is
fennáll", plusz: "bemegyek edit módba, de vissza nem váltok, nincsen ott gomb,
csak egy lyuk."

### Root cause — UGYANAZ A HIBAOSZTÁLY, MÁS HELYEN

NEM a `draftNotes` bug tért vissza (az valóban javítva van). Új
amber-on-amber láthatósági bug a VIEW/EDIT toggle gombon:
```swift
.foregroundStyle(isEditing ? AppTheme.background : ...)   // amber ikon
.background(isEditing ? AppTheme.background.opacity(0.18) : ...) // amber tint háttér
```
Ez EDIT módban amber ikont rajzolt amber-tint háttérre, a sheet TELJES
háttere pedig szintén amber (`AppTheme.background.ignoresSafeArea()`) —
**a gomb látszólag eltűnt** (létezik, kattintható, csak nem látszik). A user
ezért sosem tudott visszaváltani VIEW módba, tehát sosem látta a
renderelt jegyzetet vagy a külső badge helyes váltását — érthetően úgy
tűnt, mintha semmi nem menne életbe, holott a `$notes` live-binding valójában
helyesen írt végig.

### Fix

`NotesSheet.swift`, EDIT/VIEW toggle gomb aktiv (isEditing=true) állapota:
`AppTheme.background` (amber) → először `AppTheme.dark`-ra javítva, DE a user
visszajelezte, hogy a sötétbarna kilóg a többi (fehér alapú) gomb közül —
"zavaró, hogy sok fehér között dark". **Végleges fix**: maradt a fehér
családon belül, csak erősebb: `Color.white` (teljes opacitás ikon) +
`Color.white.opacity(0.18)` háttér (a többi gomb `white.opacity(0.7)` fg /
`white.opacity(0.07)` bg inaktív állapotához képest látványosan
felderítettebb/telibb, de színcsaládon belül marad).

### Plusz user-kérés: szövegterület színvilága

1. **EDIT mód** (`TextEditor`): háttér `Color.clear` (áttűnt, amber szűrődött
   át) → `AppTheme.dark` (sötétbarna "kártya"). Szöveg szín `Color.white.opacity(0.85)`
   → `AppTheme.background` (amber) — a fahér szöveg zavaró volt az amber
   háttér-átszűrődés miatt.
2. **VIEW mód** (`MarkdownWebView` CSS `body`): háttér `#0d0d0d` (majdnem
   fekete) → `#2A2015` (`AppTheme.dark` pontos hex megfelelője) — hogy a
   két mód vizuálisan egységes legyen, ne legyen "fekete" terület.

### Session 36 — NYITOTT
- [x] EDIT/VIEW toggle gomb láthatósági fix (amber→dark aktiv állapotban)
- [x] TextEditor háttér/szöveg szín: dark bg + amber text
- [x] MarkdownWebView CSS body háttér: #0d0d0d → #2A2015
- [x] **EDIT/VIEW padding egységesítve**: `TextEditor` külső paddingja
  (`horizontal 20, vertical 16`) NEM egyezett a `MarkdownWebView` CSS
  `body { padding: 20px 24px 40px; }` értékeivel — a két mód ezért másként
  nézett ki. Most mindkettő `top 20 / horizontal 24 / bottom 40`.
  **Megjegyzés**: a SwiftUI `TextEditor` NSTextView-nak van saját belső
  `textContainerInset`-je is (néhány pixel, SwiftUI API-ból nem nullázható
  közvetlenül) — ha build után még mindig érezhető kis eltérés van a két
  mód között, ez az oka, és NSViewRepresentable-es TextEditor szükséges a
  teljes 1:1 igazításhoz.
- [ ] **KRITIKUS RETEST**: buildelés után ellenőrizd, hogy most már
  látszik-e és működik-e a VIEW/EDIT toggle gomb, és hogy a badge helyesen
  vált-e edit→view→dismiss után. Ha még mindig gond van, az már nem
  szín-láthatósági, hanem tényleges logikai hiba lenne.
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Git commit (Session 36 teljes)

---

## Session 36 — 2026-08-10 (SLOT-NOTES BUG: draft-buffer bypass — GYÖKÉROK javítva)

### Bug report (user)

"Az ikon látszik, de sose vált badge-es ↔ sima note.text között." A külső
gomb (`CountdownDetailView`) sosem reagált arra, hogy írtak-e notes-t vagy sem.

### Root cause

`NotesSheet.swift` EDIT módja egy külön `@State private var draftNotes: String`
puffert használt: a `TextEditor` a `draftNotes`-ra volt kötve, és csak KIFEJEZETT
interakciókor írta vissza a valódi `notes` @Binding-ba (`notes = draftNotes`):
- ceruza→szem toggle megnyomásakor, VAGY
- a sheet fejlécében levő X (dismiss) gomb megnyomásakor.

macOS-en viszont a sheet **Escape billentyűvel vagy az ablak bezárásával**
is bezárható — ez a rendszerszintű dismiss ki hagyja a mi X-gombunk
commit-logikáját. Ha a user így zárta be a sheetet gépelés után, a
`draftNotes` SOHA nem íródott vissza `item.notes`-ba — a valódi adat üres
maradt, ezért a külső gomb ikonja (`item.notes.isEmpty` alapján) örökre
ragadt az eredeti (üres) állapotban.

### Fix

`NotesSheet.swift` — a `draftNotes` puffer **teljesen kiiktatva**:
- `TextEditor(text: $draftNotes)` → `TextEditor(text: $notes)` (közvetlen
  írás a valós bindingba minden billentyűleutéskor).
- VIEW/EDIT toggle gomb: csak `isEditing.toggle()`, nincs több commit-logika.
- Dismiss (X) gomb: csak `dismiss()`, nincs több commit-logika (nincs mit
  commitolni, már élőben ír).
- Trash confirm: csak `notes = ""` (draftNotes már nem létezik).
- `.onAppear { draftNotes = notes }` törölve (feleslegessé vált).
- Fájl fejléc komment frissítve, részletesen dokumentálva a root cause és a
  fix, hogy a jelenség többet ne térjen vissza tévesen "UI polish"-ként.

**Mellékhatás (várt, nem hiba)**: mivel most minden betűlecsütés azonnal
ír a `$item.notes` binding-on keresztül a `CountdownView`-beli `items` @State
tartcolra, ez minden karakter begépelésekor triggereli a `CountdownView`
`.onChange(of: items) { save(); rebuildCache() }` blokkját — azaz **minden
billentyűleutés lement UserDefaults-ba**. Kis notes-mennyiségnél ez nem
probléma, de ha a jegyzetek nagyra nőnek/gyakran szerkesztik, érdemes lehet
később debounce-olni a persistence-t. **Egyelőre nem optimalizálva — ha
build után látható teljesítmény/beki-lag probléma jelentkezik, ide vissza
kell térni.**

### Session 36 — NYITOTT
- [x] `draftNotes` puffer kiiktatva, `TextEditor` közvetlen `$notes` binding
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Build ellenőrzés — **KRITIKUS**: teszteld, hogy a badge most helyesen vált-e
  és hogy nincs-e érezhető lag gépeléskor (minden karakter ír UserDefaults-ba)
- [ ] Git commit (Session 36 teljes: cím fix, accountname eltávolítás,
  dimmelés eltávolítás, plus badge, trash gomb, draft-buffer bug fix)

---

## Session 36 — 2026-08-10 (SLOT-NOTES polish, folytatás 2: trash gomb)

### Context

User UX visszajelzés: a VIEW/EDIT toggle marad (nem vonjuk össze gépeléssel),
DE hiányzott egy mód a jegyzet teljes törlésére — zavaró volt, hogy edit
gomb van, delete nincs. Két döntés a userrel egyeztetve (ask_user_input):
1. Szerkesztési mód marad a jelenlegi VIEW/EDIT toggle (nincs élő szöveg-gépelés
   + külön preview, nincs split view) — EZ NEM VáLTOZOTT.
2. Trash gomb: a TELJES notes mezőt törli, DE megerősítő alert-tel.

### Completed

**Trash gomb hozzáadva** — `NotesSheet.swift` header, sorrend: **Copy → Edit/View
toggle → Trash → Dismiss** (a felhasználói folyamatot tükrözi: előbb
szerkeszt, utána dönt a törlésről — nem fordítva):
- Ikon: `trash`, ugyanaz a stílus mint a Copy gomb (`Color.white.opacity(0.7)`
  fg, `Color.white.opacity(0.07)` bg, `36×36`, `cornerRadius 8`) — nincs
  dimmelés/feltételes enabled állapot, mindig aktiv.
- Tap → `showDeleteConfirm = true` → `.alert("Delete all notes?", ...)`:
  Cancel (role: .cancel) / Delete (role: .destructive).
- Confirm esetén `notes = ""` **ÉS** `draftNotes = ""` (ha épp EDIT módban
  vagyunk, a draft is nullázódik, hogy ne írja vissza a régi szöveget a
  következő mode-váltáskor).
- Fájl fejléc komment frissítve az új gombbal.

### Session 36 — NYITOTT
- [x] Trash gomb + megerősítő alert (`NotesSheet.swift`)
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Build ellenőrzés
- [ ] Git commit (Session 36 teljes: cím fix, accountname eltávolítás, dimmelés eltávolítás, plus badge, trash gomb)

---

## Session 36 — 2026-08-10 (SLOT-NOTES polish, folytatás)

### Context

`NotesSheet.swift` és `CountdownDetailView.swift` a userrészről kézzel is módosult
(Xcode-ban közvetlenül) a Session 36 során — az alábbi állapot a TWO fájl
aktuális tartalma alapján **forrás az igazság**, minden régebbi tervezett-spec
(handoff.md "tervezett"/archívum szekciói) ehhez lett igazítva.

### Completed

**1. Cím szín/méret fix** — `NotesSheet.swift` header:
- Root cause volt: `.foregroundStyle(AppTheme.background)` — az `AppTheme.background`
  amber szín, UGYANAZ mint a sheet háttere, ezért a cím beleolvadt.
- Fix: statikus `"NOTES"` felirat, `alienLeagueBold(24)`, `AppTheme.dark` szín.

**2. Account name (slotLabel) eltávolítva a NotesSheet fejlécéből** — user
döntése: a slot neve már látszik a háttérben (CountdownDetailView), a
NotesSheetben feleslegesen duplázódott. A `slotLabel` paraméter megmaradt a
structban (hívási kompatibilitás miatt), de a fejléc már csak a statikus
"NOTES" címkét rendereli.

**3. Gomb dimmelés eltávolítva (user design döntés)** —
`CountdownDetailView.swift` sound toggle és notes gombok: NINCS több
`.opacity(0.4)`/`.opacity(0.45)` állapot-dimmelés. Az állapotjelzés KIZÁRÓLAG
 ikoncserével történik (pl. `note.text.badge.plus` ↔ `note.text`,
`speaker.wave.2.fill` ↔ `speaker.slash.fill`), mindkét állapotban teljes
(`opacity(1.0)`) színnel. **Ezt többet ne állítsuk vissza dimmeltre.**
- `CountdownDetailView.swift` fejléc komment frissítve, hogy ezt tükrözze.

**4. Gomb méretek (source of truth, `CountdownDetailView.swift` bottom row)**:
- Gombok: `32×32`, `RoundedRectangle(cornerRadius: 7)` (NEM 44×44/cornerRadius 9,
  ahogy a régi SOUND-1 archívum spec írta — az elavult volt).
- Bottom HStack spacing: `20` (fő csoportok között), belső HStack spacing: `8`
  (sound/notes/colorpicker gombok között).
- `.padding(.bottom, 36)` a teljes bottom button row alatt.

**5. "+" badge hiányzott a NotesSheet üres állapotából** — a külső trigger
gomb (CountdownDetailView) helyesen mutatta a `note.text.badge.plus` ikont
üres jegyzet esetén, de a NotesSheet SAJÁT belső üres-állapot placeholder-e
("No notes yet...") sima `note.text` ikont használt, plus badge nélkül — ez
inkonzisztens volt, nem jelezte az additív módot. Fix: a placeholder ikon is
`note.text.badge.plus`-ra váltva. Egyútt szín is javítva `Color.white.opacity`
→ `AppTheme.dark.opacity` (ugyanaz a láthatósági bug osztály, mint a címnél:
fehér szöveg amber háttéren alig látszik).

### Folyamatban / következő lépés

- **Betűtípus**: user döntése — **Roboto Flex Light**, a user maga teszi be a
  projekt "Fonts" mappájába (`resources/Font/` vagy Xcode "Fonts" csoport).
  Hátralévő lépések innen:
  - Info.plist regisztráció (NEM entitlements — az sandbox/capability jogokat
    tartalmaz; a bundled fontokat az Info.plist "Fonts provided by
    application" kulcsa regisztrálja).
  - `MarkdownWebView.css` `font-family: 'Roboto Flex', 'Menlo', monospace` →
    frissítés pontos PostScript névre (`Roboto Flex Light` vagy a tényleges
    belépõ font-face név, amit a `.ttf` tartalmaz — ellenőrizni kell build után
    Font Book-ban vagy `otfinfo`-val).
- Build ellenőrzés (user).
- Git commit (user).

### Session 36 — NYITOTT
- [x] `NotesSheet.swift` — cím statikus "NOTES", `AppTheme.dark`, méret 24
- [x] `NotesSheet.swift` — slotLabel/accountname sor eltávolítva a fejlécből
- [x] Gomb dimmelés eltávolítva (user), dokumentáció frissítve ehhez
- [x] NotesSheet üres állapot — plus badge + láthatósági szín fix
- [ ] Roboto Flex Light betetése a Fonts mappába (user, foly.) + Info.plist regisztráció + CSS frissítés
- [ ] Build ellenőrzés
- [ ] Git commit

---

## Session 35 — 2026-08-10 (CALC-SAVE UX polish)

### Completed

**CALC-SAVE UX polish** (commit pending)

`CalculateView.swift`:

1. **Chevron hit area fix** — a split SAVE gomb jobb felének (▾) kattintható területe
   korábban csak a `chevron.down` ikon intrinsic mérete volt (~9pt), nem a paddingolt
   zona. Fix: `.contentShape(Rectangle())` hozzáadva a chevron `Image` padding-je UTÁn,
   így a teljes `padding(.horizontal, 10).padding(.vertical, 8)` zóna tappable.
   (`.buttonStyle(.plain)`-nél macOS csak a content intrinsic méretét veszi hit area-nak;
   `.contentShape(Rectangle())` kényszeríti ki a padded rect-et.)

2. **Save sheet és detail sheet design** — `saveSheetContent` és `deadlineDetailContent`
   korábban egyszerű `AppTheme.calculateBackground` hátteret kaptak; most ugyanazt a
   purple gradienset és white 8% opacity horizontális divider vonalt kapják mint a
   `deadlineListPopoverContent`. A design language egységes a három CALC-SAVE felület
   között:
   - Háttér: `calcSaveGradient` — `LinearGradient` purple `#593C73` @ 35% opacity
     (top) → `AppTheme.calculateBackground` (25% pont-nál). Shared computed property
     a duplikáció elkerülésére.
   - Felső zóna (purple gradient rész): cím `alienLeagueBold(18/20)` amber +
     dátum felirat `alienLeague(13)` white 55%; `.padding(.top, 28)` + `.padding(.bottom, 20)`.
   - Divider: `Color.white.opacity(0.08)` 1pt vonal a header alatt (ugyanaz mint a
     popover list sorközötti divider).
   - Body: TextField / action gombok `padding(.horizontal, 28).padding(.top, 20)`.

3. **`calcSaveGradient` helper** — `private var calcSaveGradient: LinearGradient`
   computed property kiemelve, a három `@ViewBuilder` mind ezt használja — egyetlen
   helyen kell módosítani ha a szín változna.

4. **File header dokumentáció** — a `CalculateView.swift` header kommentje frissítve:
   CALC-SAVE design language összefoglalva (gradient, divider, gomb-stílus, chevron fix).

### Session 35 — LEZÁRVA
- [x] `CalculateView.swift` — chevron `.contentShape(Rectangle())` fix
- [x] `CalculateView.swift` — `saveSheetContent` purple gradient + divider
- [x] `CalculateView.swift` — `deadlineDetailContent` purple gradient + divider
- [x] `CalculateView.swift` — `calcSaveGradient` shared helper
- [x] `CalculateView.swift` — file header design dokumentáció
- [ ] Build ellenőrzés (user)
- [ ] Git commit (user)

---

## Session 34 — UX fix (commitolni szükséges)

Session 34 tartalom — ld. az eredeti Session 33 bejegyzés alatt.

---

## Session 33 — 2026-08-10 (CALC-SAVE)

### Completed

**CALC-SAVE — Named Deadlines from Calculate View** (commit `c84bb39`)

`NamedDeadline.swift` (új fájl):
- `struct NamedDeadline: Identifiable, Codable` — `id: UUID`, `title: String`,
  `date: Date`, `createdAt: Date`; synthesized Codable rendben.
- Storage: UserDefaults kulcs `"namedDeadlines"`, JSON-kódolt `[NamedDeadline]` tömb.

`CalculateView.swift` (commit `c84bb39` + Session 34 UX fix):
- Új `@State` változók: `namedDeadlines`, `showSaveSheet`, `saveTitleDraft`, `selectedDeadline`.
- `saveButton` — felirat: `"SAVE / EDIT"`. Bal klikk: `showSaveSheet = true`.
  Jobb klikk: `.contextMenu` → `ForEach(namedDeadlines)` native macOS menüként
  (cím + dátum másodlagos szövegként). Kiválasztás: `selectedDeadline = deadline`.
  `saveHoverTask` és `.onHover`/`.popover` eltávolítva (Session 34).
- `saveSheetContent` — `"SAVE DEADLINE"` cím + TO dátum + `TextField("Name...")` +
  amber SAVE gomb (disabled ha üres) + szürke CANCEL gomb.
- `deadlineDetailContent(_:)` — detail sheet: cím + dátum + `LOAD AS TO` gomb + trash gomb.
- Persistence: `loadDeadlines()` / `saveDeadlines()` / `addNamedDeadline(title:)`.
- `.onAppear { loadDeadlines() }` + `.sheet(isPresented: $showSaveSheet)` +
  `.sheet(item: $selectedDeadline)` a ZStack-re kötve.

**Session 34 — UX fix: popover → contextMenu**
- Probléma: a hover-triggered `.popover` a SAVE gombra volt kötve — a kurzor
  elhagyásakor (pl. a lista egy elemére menve) a popover azonnal bezárt.
- Fix: `.onHover` + `saveHoverTask` + `.popover` eltávolítva; helyette `.contextMenu`
  a natív macOS jobb klikk menüt használja. A lista elemei kattinthatók mielőtt
  a menü bezárul — ez a natív macOS menu viselkedése.
- `showDeadlineListPopover`/`showDeadlineListSheet` state változók eltávolítva.
- Build: ellenőrizni szükséges.

### Session 33 — LEZÁRVA
- [x] `NamedDeadline.swift` — létrehozva
- [x] `CalculateView.swift` — SAVE gomb + save sheet + detail sheet + persistence
- [x] Build: SUCCEEDED
- [x] Git commit — `c84bb39`

### Session 34 — UX fix (commitolni szükséges)
- [x] `CalculateView.swift` — split gomb: bal = save sheet, jobb (▾) = click-triggered
  amber popover (invertált paletta: amber alap, sötétbarna szöveg)

---

## Session 32 — 2026-08-10 (feature planning)

### Tervezett fejlesztési irányok — dokumentálva

Három új fejlesztési irányt tárgyaltunk meg és dokumentáltunk. Kódírás nem
történt ebben a sessionben — csak tervezés és handoff-frissítés.

#### CALC-SAVE — Named Deadlines from Calculate View
- A Calculate View eredmény-nézetéből menthetők el névvel ellátott határidők.
- Concept: „SAVE AS…" gomb a result row közelében → névbeviteli modal →
  `NamedDeadline` lista (`title`, `date`, `createdAt`) UserDefaults-ban tárolva.
- Megjelenítés: a Calculate View-ban saját szekció (pl. result row alatt)
  vagy popover/sheet a mentett deadline-okhoz; opcionálisan Countdown Slot
  létrehozható belőle (import gomb).
- Részletek: ld. handoff.md CALC-SAVE szekció.

#### SLOT-NOTES — Per-slot Notes with Copy (Detail View Modal)
- Minden `CountdownItem` kap egy `notes: String` mezőt (default `""`).
- A `CountdownDetailView`-ban notes gomb → modal sheet szerkesztéshez + Copy gombbal.
- Modal: olvashatóbb betűtípus a body szöveghez (nem Alien League — pl.
  monospace vagy SF Pro), markdown-formázott tartalom.
- FONTOS: `CountdownItem.init(from decoder:)` frissítés szükséges (`decodeIfPresent`).
- Részletek: ld. handoff.md SLOT-NOTES szekció.

#### SNIPPETS — Master Prompt Snippets Tab
- Új, harmadik tab az appban (Calculate / Countdown / Snippets).
- Projekt szerint csoportosított, másolható markdown szöveg-snippetek.
- `Snippet` struct: `id`, `title`, `body`, `project` (string tag).
- `[Snippet]` lista UserDefaults-ban tárolva.
- Minden snippet-hez Copy gomb, szerkesztés/törlés lehetőség.
- Részletek: ld. handoff.md SNIPPETS szekció.

### Session 32 — LEZÁRVA (tervezési dokumentáció)
- [x] CALC-SAVE feature-terv dokumentálva (handoff.md)
- [x] SLOT-NOTES feature-terv dokumentálva (handoff.md)
- [x] SNIPPETS feature-terv dokumentálva (handoff.md)
- [ ] Implementáció: user dönt sorrendről

---

## Session 31 — 2026-08-09 (time display sizing fix)

### Completed

**TIME DISPLAY SIZING FIX** (commit `db5f054`)

`CountdownDetailView.swift`:
- A korábbi `ZStack` + fix `frame(maxWidth: 300)` lecserélve `Image.overlay { GeometryReader }`
  kombinációra.
- `timeDisplay(at:)` → `timeDisplay(at:maxWidth:)` szignatura, a `maxWidth` a GeometryReader-től
  jön: `min(geo.size.width, geo.size.height) * 0.62` (paradicsom test ~62%-a).
- `position(x: geo.size.width/2, y: geo.size.height/2 + 42)` helyezi el a szöveget
  a paradicsom közepére + 42pt lefelé offset.
- `minimumScaleFactor` 0.45→0.3 (remaining) és 0.6→0.3 (deadline) — több helyet enged
  a shrinkingnek mielőtt layout feladja.
- Fallback: ha `maxWidth == 0` (első render), `w = 280`.
- Build: SUCCEEDED (xcodebuild ellenőrizve).

**Diagnosztika**: az előző session megközelítése kódszinten helyes volt és a build
sikeresen lefutott — a "lista eltűnt" valószínűleg egy félbeszakadt fájlmentés
miatti ideiglenes compile error volt.

**BUG-SOUND-1 — CountdownItem custom init(from:) — szüntető hiba: üres lista** (commit `892f1ed`)

`CountdownItem.swift`:
- Root cause: Swift synthesized `Decodable` **nem használja** a property default értékét
  ha a kulcs hiányzik a JSON-ból — `keyNotFound`-ot dob, amit a `load()`-ban lévő
  `try?` csendes `nil`-lé alakít → `items = []`.
- `soundEnabled: Bool = false` Új mező nem volt benne a régi mentett JSON-ban →
  minden `load()` hívás üres listát adott a SOUND-1 commit után.
- Fix: explicit `CodingKeys` enum + `init(from decoder:)` hozzáadva, minden
  opcionális/defaults mezőre `decodeIfPresent` + `?? default` fallback:
  `showRemaining ?? true`, `accentColorIndex ?? nil`, `soundEnabled ?? false`.
- Ugyanez a minta véd jövőbeli mezők hozzáadásakor is.

### Session 31 — LEZÁRVA
- [x] `CountdownDetailView.swift` — GeometryReader overlay szöveg-sizing (`db5f054`)
- [x] `CountdownItem.swift` — BUG-SOUND-1 custom Codable fix (`892f1ed`)
- [x] Build: SUCCEEDED (mindktét commit)

---

## Session 30 — 2026-08-09 (SOUND-1)

### Completed

**SOUND-1 — Per-slot expiry sound notification** (commit `c04d4a6`)

`CountdownItem.swift`:
- `soundEnabled: Bool = false` mező hozzáadva (backward-compatible Codable: ha
  a JSON-ban nincs kulcs, Swift decoder a default `false`-t használja).

`CountdownView.swift`:
- `import AppKit` hozzáadva (NSSound-hoz szükséges).
- `@State private var previousActiveIDs: Set<UUID> = []` — snapshot az aktív
  item ID-kről az előző `rebuildCache` hívásból.
- `rebuildCache(now:playExpirySounds:)` — új `playExpirySounds: Bool = false`
  paraméter. Ha `true`: kiszámolja `newActiveIDs`-t, diff-el
  `previousActiveIDs`-szel, és minden `justExpired` itemre ahol `soundEnabled==true`
  meghívja `NSSound(named: "Funk")?.play()`-t. Ezután `previousActiveIDs`
  mindig frissül a jelenlegi aktív setre.
- `crossingTask` → `rebuildCache(now: Date(), playExpirySounds: true)`-val hívja
  (csak a deadline-crossing pillanatában, nem minden ticknél).
- Egyéb `rebuildCache()` hívások (`onAppear`, `.onChange`) maradnak
  `playExpirySounds: false`-sal — startup-kor nem szól a hang.

`CountdownDetailView.swift`:
- Sound toggle gomb hozzáadva a bottom buttons HStack-be (a trash elé),
  minden slot típuson látható (aktív és expired egyaránt).
- `speaker.wave.2.fill` (bekapcsolt) / `speaker.slash.fill` (kikapcsolt) ikon.
- Bekapcsolt állapot: `AppTheme.dark` háttér, `AppTheme.background` fg.
- Kikapcsolt állapot: `AppTheme.dark.opacity(0.45)` háttér, `AppTheme.background.opacity(0.4)` fg.
- `.focusable(false)` — FocusBridge crash megelőzés.
- `item.soundEnabled.toggle()` → `@Binding` → `CountdownView.items` →
  `.onChange(of: items)` → `save()` — automatikus perzisztálás.

### Session 30 — LEZÁRVA
- [x] `CountdownItem.swift` — `soundEnabled` mező
- [x] `CountdownView.swift` — `previousActiveIDs` + `playExpirySounds` logika + `import AppKit`
- [x] `CountdownDetailView.swift` — speaker toggle gomb
- [x] Git commit — `c04d4a6`

---

## Session 25 — 2026-08-09

### Completed

**CALC-1 FIX — Calendar-aware result mode** — `CalculateView.swift`.
Two result display modes, toggled by `DAYS` / `CAL` buttons placed below the result row.
- **DAYS** (default, unchanged): fixed `d h m s` breakdown via integer arithmetic on `difference`.
- **CAL** (new): `Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second],
  from: earlier, to: later)` — order-aware (always earlier→later, sign handled by existing `isFuture`/`resultLabel`). Leading zero components hidden; at least the last non-zero component always shown (falls back to the last element if all zero).
- Toggle buttons styled identically to `RESET FROM/TO NOW` (`alienLeague(13)`, `padding 16/8`, `cornerRadius 8`). Active: `Color.white.opacity(0.35)`, inactive: `Color.white.opacity(0.12)`.
- Persisted via `@AppStorage("calculateDisplayMode")` (`"days"` / `"cal"`).
- Weeks excluded per plan.
- `calResultParts` computed var added; `resultRow` switches on `displayMode`; `modeToggle` + `modeButton` helpers added under `// MARK: - Mode toggle`.

**23-D FIX — LongPressStepperButton timer double-registration** — `LongPressStepperButton.swift`.

### Session 25 — LEZÁRVA
- Files changed: `CalculateView.swift`, `LongPressStepperButton.swift`
