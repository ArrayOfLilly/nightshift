# countdownApp — handoff a következő chat-hez

## LEGFRISSEBB (Session P — 2026-08-12, audit-szinkron)

**Állapot ellenőrizve és VERIFIED a forráskód alapján (Filesystem MCP-n keresztül,
`/Users/ArrayOfLilly/tools/countdownApp/countdownApp/countdownApp/` alatt):**

Session P mai 5 fixe mind implementálva van a kódban:
- BUG-WIDTH-CALC (`CalculateView.swift` — saveSheetContent + deadlineDetailContent)
- BUG-WIDTH-COLOR (`ColorPickerSheet.swift`)
- BUG-WIDTH-ADD (`AddCountdownSheet.swift`)
- BUG-DELETE-CONFIRM (`CountdownDetailView.swift` — `showDeleteConfirm` + `.alert`)
- BUG-COLOR-NODISMISS (`ColorPickerSheet.swift` — X gomb)

**Mind a 4 audit dokumentum (`/Users/ArrayOfLilly/tools/countdownApp/docs/`) frissítve
van a mai fixekhez** — ellenőrizve, a `duplication-audit.md` §11, `magic-numbers-audit.md`
§11 és `srp-audit.md` "Post-fix findings — Session P (BUG-WIDTH-CALC/...)" szekciói mind
készen vannak a lemezen. `codable-audit.md` nem érintett (helyesen). `progress.md`
frissítve, hogy ezt tükrözze (korábban a checklist-en nem szerepelt, csak a fájlokban
volt kész — dokumentációs lemaradás, most szinkronban).

**Hátralévő teendő (session limit miatt nem történt meg):**
- [ ] Build ellenőrzés Xcode-ban (saveSheet + detailSheet + colorPicker + addSheet
  egyike sem lóg ki az ablakból semmilyen ablakméretnél)
- [ ] Git commit — Session P TELJES: rename + popover width fix + BUG-WIDTH-CALC/COLOR/ADD
  + BUG-DELETE-CONFIRM + BUG-COLOR-NODISMISS + mind a 4 audit fájl frissítése egy commitban

**Nyitott audit-témák (SESSION_HANDOFF.md, docs/ mappa) — nem ehhez a session-höz tartozik,
későbbi audit-pipeline munka:** Performance (#5), AppTheme/CSS-szinkron (#6), State Management (#7),
Docs/Hungarian text (#8), freeColors (#9), NotificationCenter (#10), Font registration (#11),
Storage (#12), Layout overflow (#13), JS injection (#14), Accessibility (#15), App Lifecycle (#16).

---

## Korábbi (Session N — 2026-08-11)

**SnippetEditSheet.swift + NotesSheet.swift szélesség fix**: mindkét sheet
régi `.frame(minWidth: X, maxWidth: 900, ...)` beállítása mindig túllógott
az ablak szélein, ha az ablak keskenyebb volt 900pt-nál. Fix mindkét
fájlban azonos mintával: `sheetWidth` @State + `windowMargin` konstans +
`updateSheetWidth()` metódus, ami `.onAppear`-ben a valós
`NSApp.mainWindow?.frame.width` értékből 24pt-ot levonva számítja ki a
sheet szélességét (clamp [450, 900]). `.frame(minWidth: sheetWidth,
maxWidth: sheetWidth, minHeight: ...)` — FONTOS: nem `width:` overload,
mert az nem vehet fel `minHeight:`-et ugyanabban a hívásban.
SnippetEditSheet: `minHeight: sheetMinHeight` (680). NotesSheet:
`minHeight: 520` (változatlan).
Mindkét sheet garantáltan keskenyebb, mint a tényleges ablak.
SnippetEditSheet build OK, user visszaigazolta. NotesSheet build
még NINCS ellenőrizve — ez a **következő lépés**, majd git commit
(mindkét fájl egy commitban, Session N).

**PlainTextEditor lineSpacing (új, ugyanebben a sessionben)**: user kérésére
nagyobb sorköz EDIT módban. `SharedEditorComponents.swift`-ben új
`lineSpacing: CGFloat = 0` param a `PlainTextEditor`-on, `NSParagraphStyle`
ként ráírva typingAttributes + defaultParagraphStyle + a meglévő szöveg
teljes range-ére. Mindkét híváspont (NotesSheet, SnippetEditSheet)
`lineSpacing: 5`. FONTOS korlát: plain-text NSTextView-ban minden sor
külön "paragraph", tehát nem lehet csak a markdown-bekezdések (üres
sorral elválasztott blokkok) közé célozni — minden sor között egyenletesen
nő a tér. Ezt a userrel tisztáztuk, elfogadta.
**Még hátra**: build ellenőrzés mindhárom érintett fájlra + git commit.

**VIEW mód betűméret (új, ugyanebben a sessionben)**: user szerint a nem
monospace (Roboto Flex) test szöveg túl kicsi volt VIEW nézetben. Közös
`markdownCSS` (SharedEditorComponents.swift) `body { font-size }` `13px→14px`
— egy hely, mindkét sheet (Notes + Snippet) VIEW nézetére automatikusan
érvényes. `code`/`pre` monospace 12px változatlan.

**VIEW mód font-csere próbálgatásra (új, ugyanebben a sessionben)**: user
JetBrainsMono-Regular.ttf-et akar kipróbálni a Roboto Flex helyett a VIEW
nézet test szövegében, és még eggyel nagyobb betűméretet. `markdownCSS`
`body { font-family: 'Roboto Flex', ... }` → `'JetBrains Mono', 'Menlo',
monospace`, `font-size` `14px→15px`. A font NINCS bepakolva a bundle-be
(user már installálta rendszerszinten, csak családnév szerint hivatkozunk
rá CSS-ben) — összhangban a korábbi "ne tegyük be, csak próbálgatás"
kéréssel. Ha nem találja a családnevet a WKWebView, Menlóra esik vissza.
Ha a user véglegesíti a JetBrains Mono használatát, akkor kell majd a
fontfájlt és a robotoFlexFontFaceCSS()-hez hasonló @font-face bloklot
beemelni a bundle-be, hogy más gépen is működjön.

**Méret finomhangolás**: user visszaszólt, hogy 15px túl nagy volt a
többihez képest — vissza `14px`-re állítva. User megjegyezte, hogy AZ EGÉSZ
alkalmazásban általánosságban kicsik a betűk, de EGYELŐRE NEM akarja az
egészet átírni — ez EGY KÜLÖN, későbbi, még nem indított feladat, NE
kezdj bele automatikusan egy általános betűméret-felülvizsgálatba, csak
ha a user külön rákér.

**FONT KÍSÉRLETEZÉS — NE NYÚLJ HOZZÁ** (user megjegyzés, 2026-08-11): a user
külső (rendszerszintű, telepített) fonts mappába új betűtípusokat rakott,
hogy kipróbálja őket — EZEK JELENLEG NEM részei az app bundle-nek és NEM
is kell regisztrálni Info.plist-ben, amíg a user másként nem szól. A
korábbi "Roboto Flex Light font regisztráció függőben" tétel (régebbi
Session-ből) továbbra is érvényes marad, de ez egy külön, még el nem
döntött/kipróbálás alatt álló dolog — ne keverődjön össze vele.

---

## Working setup
- Filesystem MCP-n keresztül dolgozunk. Szerializáltan olvasd a fájlokat.
- Filesystem:write_file teljes fájl felülírással működik, NEM appendál — mindig read-then-write.
- Header/komment: angolul, semmi magyar szöveg a kódban.
- progress.md frissítése + git commit minden session végén.
- **Inner kódrepo**: `/Users/ArrayOfLilly/tools/countdownApp/countdownApp/`
  Swift forrás: `countdownApp/countdownApp/countdownApp/` alatt.
- Olvasd el először a `progress.md`-t.

## Jelenlegi állapot (Session K után — 2026-08-11)

### Session K elvégzett változások

**SnippetEditSheet.swift — snippet editor UI polish:**
- Title TextField: `.focused($titleFocused)` → `.focusable(false)` a root ZStack-en (sem title, sem project nem kap auto-focust megnyitáskor)
- `@FocusState titleFocused` eltávolítva (felesleges volt)
- Header gombok: `white 0.07` bg → `white 0.12`, ikon default tint `white 0.7` → `white 1.0`
- Header padding: top 22→18, bottom 20→24
- ProjectField dropdown háttér: `AppTheme.dark` → `#723F73`
- ProjectField popover háttér: `#4A2950` (fix sötétebb lila)
- ProjectField chevron hit area megnövelve: `frame(width:36)` + `.contentShape(Rectangle())`
- ProjectField külső frame: `height: 20` → `height: 28`

**ContentView.swift:** `.frame(minWidth: 460)` hozzáadva — ablak nem mehet 460pt alá

**countdownAppApp.swift:** `.windowResizability(.contentMinSize)` NEM kell — teljes méretben nyitotta az ablakot, eltávolítva

### Következő teendők
- [ ] Git commit (Session J + K összes változás)
- [ ] Folytatás user döntés szerint

---

## Jelenlegi állapot (Session H után — 2026-08-11)

### Session H elvégzett fixek

**NotesSheet.swift — fix magasság:**
- `webHeight` state és `clampedWebHeight` eltávolítva (JS-driven resize ejtve)
- Sheet frame: EDIT / üres: 360pt; VIEW + tartalom: 520pt fix (mint SnippetEditSheet)
- VIEW mód MarkdownWebView: `.frame(maxWidth: .infinity, maxHeight: .infinity)`, belül scrollol

**SnippetEditSheet.swift — QoS + title kijelölés:**
- `DispatchQueue.main.async` → `asyncAfter(deadline: .now() + 0.05)` az `.onAppear`-ben
- Megoldja: QoS priority inversion warning + title TextField nem jelölődik ki megnyitáskor

**Snippet sor szín — nem implementálva, vár a döntésre:**
- Implementáció helye: `SnippetsView.swift` `snippetRow()` HStack `.background()`
- Opciók: `#51422E` (freeColors[1], barna), `#403873` (freeColors[5], lila), `#3D3222` (közbülső barna)

### Következő teendők
- [ ] Build ellenőrzés
- [ ] Git commit (Session E + F + G + H összes változás)
- [ ] Snippet sor szín döntés és implementáció

---

## Jelenlegi állapot (Session F után — 2026-08-11)

### Session F elvégzett fixek

**ColorPickerSheet.swift:**
- Active stroke: `lineWidth: 3` → `2` (túl vastag volt)
- Auto swatch: `Color.white` → `Color.white.opacity(0.70)` (amber háttéren nem vakít)

**SharedEditorComponents.swift — MarkdownWebView auto-height:**
- `var onHeightChange: ((CGFloat) -> Void)? = nil` paraméter hozzáadva
- `Coordinator: NSObject, WKNavigationDelegate` + `makeCoordinator()` hozzáadva
- `didFinish`: JS `document.body.scrollHeight` evaluation → `onHeightChange` callback
- Opcionális paraméter: backward-compatible, régi hívók változatlanul fordulnak

**NotesSheet.swift + SnippetEditSheet.swift — VIEW mód dinamikus magasság:**
- `@State private var webHeight: CGFloat = 280` mindkettőben
- `clampedWebHeight` computed property: `min(max(webHeight, 160), screenH - 54)`
  (54pt ≈ 1.5 cm a képernyő aljától)
- Frame feltétel: EDIT mód / üres → fix minHeight (360 ill. 520); VIEW + tartalom → `minHeight: nil`
- VIEW ág MarkdownWebView: `onHeightChange: { h in webHeight = h }` + `.frame(height: clampedWebHeight)`

**Snippet szín — nem változtatva:**
- Javaslatok: `#403873` (lila), `#3D3222` (sötétebb barna), `#30271B` (legsötétebb barna)
- User dönt, majd következő sessionben implementálható

### Következő teendők
- [ ] Build ellenőrzés (VIEW mód auto-height tesztelése rövid és hosszú tartalommal)
- [ ] Git commit (Session E + Session F összes változás)
- [ ] Snippet sor háttérszín döntés és implementáció (ha user úgy dönt)

---

## Jelenlegi állapot (Session 37 után)

### KÖVETKEZŐ SESSION ELSŐ LÉPÉSE: marked.min.js berakása

**Mi a marked.min.js?**
JavaScript könyvtár, ami a markdown szöveget (# Cím, - lista, stb.) HTML-lé
alakítja. A NotesSheet VIEW módja ezt használja WKWebView-ban. A fájl eddig
HIÁNYZOTT a projekt resources/ mappájából — ezért jelent meg a szöveg amber
bal-szegélyes kódblokk dobozban (a fallbackHTML futott le, ami <pre> tagbe
rakta a szöveget, arra illeszkedett a CSS pre stílus).

**1. lépés: Terminal**
```bash
cd /Users/ArrayOfLilly/tools/countdownApp/countdownApp/countdownApp/resources
curl -s "https://registry.npmjs.org/marked/-/marked-18.0.9.tgz" -o marked.tgz \
  && tar -xzf marked.tgz \
  && cp package/lib/marked.umd.js marked.min.js \
  && rm -rf package marked.tgz
```
Eredmény: `resources/marked.min.js` létrejön (~43KB JS fájl).

**2. lépés: Xcode — Copy Bundle Resources**
"Copy Bundle Resources" = az Xcode Build Phases egyik lépése, ami meghatározza,
melyen fájlokat csomagolja be az alkalmazás .app könyvtárába. Ha egy fájl
(JS, font, kép) nincs ebben a listában, az app futáskor nem látja.
- Xcode-ban: bal oldali projekt navigátorban kattints a kék `countdownApp`
  project ikonra → válaszd a `countdownApp` targetet → Build Phases fül
  → `Copy Bundle Resources` szekció kinyitása → `+` gomb →
  `resources/marked.min.js` hozzáadása.
VAGY: a `resources/` mappát a Finder-ben megnyitva drag-and-drop a
`marked.min.js` fájlt a Xcode navigátorba a `resources` group alá →
az automatikusan Copy Bundle Resources-ba kerül.

**3. lépés: Build + teszt**
NOTES VIEW mód: a szöveg most már normál paragrafusként jelenik meg,
nem amber-szegélyes kódblokk dobozban.

### Roboto Flex Light (következő lépés build után)
- A user mondta: **BENNE VAN** a projekt Font mappájában (Resources/Font/)
- Még hiányzik: Info.plist regisztráció + MarkdownWebView CSS frissítés
- Info.plist kulcs: "Fonts provided by application" → a font fájlnév
  (pl. `RobotoFlex-Regular.ttf`) beírása
- CSS: `font-family: 'Roboto Flex', 'Menlo', monospace` — ellenőrizni
  kell a pontos PostScript nevet Font Book-ban

### Session 37 elvégzett fixek
- [x] NotesSheet.swift — Bundle URL keresés: `marked.min` ÉS `marked.umd`
  névvel keres (fallback sorrendben)
- [x] NotesSheet.swift — fallbackHTML(): `<pre>` → `<p>` tag,
  `\n → <br>` konverzió (biztonsági háló ha hiányzik a JS fájl)
- [x] ColorPickerSheet.swift — AUTO label: 9pt → 12pt, opacity 0.75 → 0.85
- [ ] marked.min.js fizikai berakása (user teendő, ld. fent)
- [ ] Roboto Flex Light Info.plist + CSS
- [ ] Git commit (Session 36 + 37 összes változás)

---

## Jelenlegi állapot (Session 36 közben)

**SLOT-NOTES — Session 36-ban további finomhangolás, készen:**
- [x] `NotesSheet.swift` fejléc: statikus "NOTES" cím, `alienLeagueBold(24)`,
  `AppTheme.dark` szín (a régi `AppTheme.background` amber-on-amber bug javítva).
- [x] Account name (slotLabel) sor kivezetve a NotesSheet fejlécéből — már
  látszik a háttérben (CountdownDetailView), feleslegesen duplázódott volna.
- [x] Gomb dimmelés **teljesen eltávolítva** `CountdownDetailView.swift`-ben
  (user design döntés) — sound/notes/colorpicker/delete gombok mindig teljes
  opacitással jelennek meg, állapotjelzés KIZÁRÓLAG ikoncserével történik.
  **Ne állítsuk vissza a dimmelést.**
- [x] NotesSheet üres állapot placeholder — `note.text.badge.plus` ikon
  (additív mód jelzése) + `AppTheme.dark.opacity` színek (a régi `Color.white`
  alig látszott az amber háttéren).
- [x] **Trash gomb** hozzáadva a fejléchez, sorrend: **Copy → Edit/View toggle
  → Trash → Dismiss** (a folyamatot tükrözi — előbb szerkeszt, utána töröl) —
  a TELJES notes mezőt törli, `.alert` megerősítés után (Cancel/Delete
  destructive). Confirm: `notes = ""`.
  User döntés: a VIEW/EDIT toggle **marad** (nem lett összevonva élő
  gépeléssel/preview-vel), csak a trash hiányzott.
- [x] **KRITIKUS BUG FIX**: a külső note-gomb ikonja (`note.text.badge.plus`
  ↔ `note.text`) sosem váltott — ok: `NotesSheet.swift` egy külön
  `draftNotes` puffert használt, ami csak expliciten (toggle/X gomb) írta
  vissza a valós `notes` bindingot; macOS Escape/ablak-bezárás megkerülte
  ezt. **Fix**: `draftNotes` teljesen kiiktatva, `TextEditor` mostantól
  közvetlenül `$notes`-ra köt (minden billentyűleutés azonnal ír).
  Mellékhatás: minden gépelt karakter mostantól ment UserDefaults-ba —
  build után ellenőrizendő, nincs-e érezhető lag.
- **Megjegyzés (nem hiba, nincs teendő)**: a Console/Xcode logban megjelenő
  `WebContent[...] Conn 0x0 is not a valid connection ID` üzenet ártalmatlan
  WebKit XPC zaj a `WKWebView` (MarkdownWebView) sandboxolt WebContent
  alfolyamatának normál leállásával összefüggésben (pl. NotesSheet bezárásakor).
  Nincs látható funkcionális hatása, user megerősítette (2026-08-10).
- [x] **BUG #2 — láthatatlan EDIT→VIEW gomb**: ugyanaz az amber-on-amber
  hibaosztály, más helyen — a toggle gomb `isEditing` aktiv állapota
  `AppTheme.background` (amber) ikont/tintet használt az amber sheet-háttéren,
  gyakorlatilag láthatatlanná vált (user megerősítette: "eddig egyáltalán
  nem volt szem"). Végleges fix: **fehér családon belül marad** —
  `Color.white` (teljes) ikon + `Color.white.opacity(0.18)` háttér (nem
  `AppTheme.dark`, mert az kilógott a többi fehér gomb közül).
- [x] **Szövegterület színvilág**: EDIT mód TextEditor háttér `AppTheme.dark`,
  szöveg `AppTheme.background` (amber) — volt: áttűnt háttér + fehér szöveg
  (zavaró volt az amber sheeten). VIEW mód `MarkdownWebView` CSS body háttér
  `#0d0d0d` → `#2A2015` (`AppTheme.dark` hex megfelelője, nem fekete többé).
- [x] **EDIT/VIEW padding egységesítve** — `TextEditor` külső paddingja most
  pontosan a `MarkdownWebView` CSS `padding: 20px 24px 40px`-ét tükrözi
  (`top 20 / horizontal 24 / bottom 40`), volt `horizontal 20 / vertical 16`
  — ezért nézett ki másként a két mód. **Ismert maradék eltérés**: a
  `TextEditor` NSTextView belső `textContainerInset`-je SwiftUI-ból nem
  állítható, ha apró eltérés marad, NSViewRepresentable kell a teljes
  igazításhoz.
- [x] **BUG #3 — EDIT doboz nem tölti ki a területet** (screenshotokkal
  igazolva): a `TextEditor`-ról hiányzott a `.frame(maxWidth: .infinity,
  maxHeight: .infinity)`, ezért intrinsic (tartalom szerinti, egysoros)
  méretre húzódott, a maradék terület amber maradt. PLUSZ: a `.background`
  a `.frame` ELŐTT állt a láncban — SwiftUI-ban ez azt jelenti, hogy a
  háttér csak az eredeti kis méretet festi be, a bővített terület
  transzparens marad. Fix: `.frame(...)` majd UTÁNA `.background(AppTheme.dark)`.
- [x] **Üres állapot placeholder kattinthatóvá téve** — tapp-elve
  `isEditing = true`-t állít (ugyanaz, mint a ceruza gomb). `.contentShape(Rectangle())`
  a teljes területre. Szöveg frissítve "Tap to start writing."-re.
- [x] **VIEW/EDIT toggle ikon: szem → pipa** — a `checkmark` jobban utal
  jóváhagyásra/befejezésre, mint az `eye`. (A Copy gomb is `checkmark`-ot
  használ 1s-es visszajelzésként, de külön gomb, nincs ütközés.)
- [x] **Header gomb-konzisztencia**: a toggle gomb korábban `isEditing`-től
  függően más színt/opacitást használt, mint a Copy/Trash — mostantól mind
  a három header-gomb pontosan azonos stílusú (`white.opacity(0.7)` fg /
  `white.opacity(0.07)` bg állandóan), csak az ikon változik.
- [x] **VALÓDI padding-fix**: az eddigi SwiftUI `.padding()` egyeztetés NEM
  volt elég, mert a beépített `TextEditor` NSTextView-jának van egy
  SwiftUI-ból nem nullázható saját `textContainerInset`-je. Új privát
  `PlainTextEditor: NSViewRepresentable` (NSTextView + NSScrollView,
  `textContainerInset = .zero`, `lineFragmentPadding = 0`) váltotta le a
  SwiftUI `TextEditor`-t — mostantól MINDEN térköz a hívási oldal
  `.padding()`-jéből jön, pixelre egyezik a VIEW móddal (WKWebView CSS).
  Az élő-binding elv (`textDidChange` delegate írja `$notes`-ot) megőrizve.
- **KRITIKUS RETEST (még nem visszaigazolt)**: build után ellenőrizendő,
  hogy a toggle gomb most látszik-e/működik-e, és hogy a badge helyesen
  vált-e edit→view→dismiss teljes ciklus után.
- [ ] **NYITOTT: betűtípus** — végleges választás: **Roboto Flex Light**. A
  user maga teszi be a font fájlt a projekt "Fonts" mappájába. Hátralévő:
  - Info.plist regisztráció (NEM entitlements — az sandbox/capability jogokat
    tartalmaz; a bundled fontokat az Info.plist "Fonts provided by
    application" kulcsa regisztrálja).
  - `MarkdownWebView.css` `font-family` frissítés a tényleges font-face
    névre (ellenőrizni build után Font Book/`otfinfo`-val).
  - Build ellenőrzés, git commit.

**FONTOS — source of truth eltolódás**: a `CountdownDetailView.swift`-ben
(bottom button row) a gombméretek **32×32, cornerRadius 7** (NEM 44×44/
cornerRadius 9, ahogy a lentebbi SOUND-1 archívum kódrészlete írja — az már
elavult tervezési jegyzet, a tényleges fájl a mérvadó). HStack spacing: 20
a fő csoportok között, 8 a sound/notes/colorpicker gombok között.

**CALC-SAVE — LEZÁRVA** (commit `c84bb39` + Session 34 UX fix + Session 35 polish)

`NamedDeadline.swift`: `struct NamedDeadline: Identifiable, Codable` — id, title, date, createdAt.
UserDefaults kulcs `"namedDeadlines"`, JSON encode/decode.

`CalculateView.swift` — teljes CALC-SAVE implementáció:
- Split SAVE gomb: bal = save sheet, jobb (▾) = click-triggered popover (namedDeadlines lista)
- **Chevron hit area fix (Session 35)**: `.contentShape(Rectangle())` a chevron image
  padding UTÁN — a teljes paddingolt zóna tappable, nem csak az ikon.
- Save sheet: névbevitel + amber SAVE / szürke CANCEL gombok
- Detail sheet: cím + dátum + LOAD AS TO gomb + trash gomb
- Persistence: `loadDeadlines()` / `saveDeadlines()` / `addNamedDeadline(title:)`

**CALC-SAVE design language (Session 35 — egységesítve)**:
- `calcSaveGradient` shared computed property: `LinearGradient` purple `#593C73` @
  35% opacity (top) → `AppTheme.calculateBackground` (25% pont). Minden CALC-SAVE
  felület (list popover + save sheet + detail sheet) ezt használja.
- Header zóna: cím `alienLeagueBold(18/20)` amber + dátum `alienLeague(13)` white 55%;
  `.padding(.top, 28)` + `.padding(.bottom, 20)`.
- Divider: `Color.white.opacity(0.08)` 1pt, a header alatt.
- Body: content + gombok `padding(.horizontal, 28).padding(.top, 20).padding(.bottom, 28)`.
- Gombok: amber-fill SAVE/LOAD (dark text), grey CANCEL (white 50% text, white 7% bg),
  trash (white 10% bg, amber.60% icon).

**SUN-1-C — LEZÁRVA** (commit `bf41007` + bugfix-ek)
- `SunPanel.swift`: teljes popover UI, 4 szekció
- `SunTimes.swift`, `SunTimesService.swift`, `CalculateView.swift` — ld. Session 29–30

**BUG-SOUND-1 — LEZÁRVA, commitolva (`892f1ed`)**
- `CountdownItem.swift`: explicit `CodingKeys` + `init(from decoder:)`;
  `decodeIfPresent` + `?? default` fallback minden opcionális mezőre.

## Következő feladat: (nyílt, user dönt)

Session 35 után: git commit szükséges (Session 35 CalculateView változások).

Tervezett fejlesztési irányok (Session 32, részletes spec lejjebb):
- **SLOT-NOTES**: Per-slot notes modal Copy gombbal a Detail View-ban
- **SNIPPETS**: Új tab — projektenként csoportosított Master Prompt Snippetek

Korábbi backlog:
- TTS: a slot nevét felolvassa lejáratkor (SOUND-1 bővítés)
- CoreLocation: automatikus koordináta a SunTimesService-be (SUN-1-E)

---

## FONTOS: CountdownItem Codable szabály

Soha ne adj hozzá új mezőt a `CountdownItem`-hez anélkül, hogy az `init(from decoder:)`-be
is felveszed `decodeIfPresent` + `?? default` fallback-kel. A synthesized Decodable
nem használja a Swift default property értékeket — hiányzó kulcs = decode fail = üres lista.

---

## CALC-SAVE — design archívum (Session 35 után végleges)

### CALC-SAVE design language — CalculateView.swift

**Split SAVE gomb** (HStack, `Color.white.opacity(0.12)` háttér, `cornerRadius 8`):
- Bal: `bookmark.fill` (11pt bold) + "SAVE" szöveg (`alienLeague(13)`), amber, `padding leading 14 trailing 10 vertical 8`.
- Elválasztó: `Rectangle()` white 20% opacity, 1pt széles, 20pt magas.
- Jobb (▾): `chevron.down` (9pt bold), amber (30% opacity ha üres lista), `padding horizontal 10 vertical 8`.
  **KRITIKUS**: `.contentShape(Rectangle())` a padding UTÁN → teljes zona tappable.
  `.popover(isPresented: $showDeadlineListPopover)` a chevron Buttonra kötve.

**`calcSaveGradient`** (shared private computed property):
```swift
LinearGradient(
    stops: [
        .init(color: Color(red: 0x59/255, green: 0x3C/255, blue: 0x73/255).opacity(0.35), location: 0),
        .init(color: AppTheme.calculateBackground, location: 0.25),
    ],
    startPoint: .top,
    endPoint: .bottom
)
```

**List popover** (`deadlineListPopoverContent`, `minWidth: 320`):
- Fejléc: "SAVED DEADLINES" `alienLeague(11)` white 50% kerning 2, `padding top 18 bottom 12`.
- Divider: white 8%.
- Sorok: cím `alienLeague(12)` white 50% + dátum `alienLeagueBold(15)` amber, `padding horizontal 20 vertical 10`, `contentShape(Rectangle())`.
- Sorok között: white 8% divider.
- Background: `calcSaveGradient`.

**Save sheet** (`saveSheetContent`, `minWidth: 320`):
- Header: "SAVE DEADLINE" `alienLeagueBold(18)` amber + dátum string `alienLeague(13)` white 55%, `padding top 28 bottom 20`.
- Divider: white 8%.
- Body: TextField `alienLeague(15)` amber, white 10% bg, `cornerRadius 8`; gombok: CANCEL `alienLeague(13)` white 50% + white 7% bg, SAVE `alienLeagueBold(13)` dark text + amber bg.
- Background: `calcSaveGradient`.

**Detail sheet** (`deadlineDetailContent`, `minWidth: 300`):
- Header: cím `alienLeagueBold(20)` amber + dátum `alienLeague(13)` white 55%, `padding top 28 bottom 20`.
- Divider: white 8%, `padding horizontal 28`.
- Body: "LOAD AS TO" gomb (amber bg, dark text, `alienLeagueBold(13)`) + trash gomb (white 10% bg, amber.60 icon), `padding vertical 24`.
- Background: `calcSaveGradient`.

---

## SLOT-NOTES — Per-slot Notes with Copy (tervezett, Session 32)

**Concept**: Minden Countdown Slothoz szabad szöveges notes/handoff mező
rendelhető. A tárolt szöveg tipikusan AI-asszisztenssel váltott
handoff/prompt — tehát pontosan azokat a markdown elemeket kell renderelni,
amiket Claude/ChatGPT/Gemini egy átlagos üzenetben használ.

### Markdown elem-lista és kezelés

Minden elem `marked.js`-sel rendelődik, egyetlen kivétellel:

| Elem | Szintaxis | marked.js natív? |
|---|---|---|
| Headingek | `# H1` `## H2` `### H3` | ✅ igen |
| Bullet lista | `- item` | ✅ igen |
| Numbered lista | `1. item` | ✅ igen |
| Inline kód | `` `code` `` | ✅ igen |
| Kódblokk / file tree | ` ```lang ... ``` ` | ✅ igen |
| Táblázat | `\| a \| b \|` | ✅ igen |
| Highlight | `==text==` | ❌ pre-processzor kell |

### Rendering architektura: WKWebView két módban

A NotesSheet két módban működik, egy toggle gombbal váltható:

**VIEW mód** (alapértelmezett megnyitáskor):
- `WKWebView` rendereli az HTML-t, amit a raw `notes` markdown-ból genrálunk
- `marked.min.js` bundled a resources-ba (NEM CDN — App Sandbox biztonság)
- `==text==` → `<mark>` pre-processzor: 1 regex a parse előtt:
  `notes.replace(/==(.+?)==/g, '<mark>$1</mark>')`
- Egyéni CSS az app témájához (ld. stílus szekció lent)

**EDIT mód** (pencil gombra váltva):
- Sima `TextEditor` monospace fonttal (`.system(.body, design: .monospaced)`)
- Raw markdown szerkesztése
- Done/vissza gomb → WKWebView újratölti a frissített tartalmat

**Copy gomb mindkét módban**:
- Mindig a **raw markdown szöveget** másolja (`notes` string)
- Ez kerül az AI promptba, nem a HTML
- `NSPasteboard.general.setString(notes, forType: .string)`
- 1 másodperces visszajelzés: `doc.on.doc` ikon → `checkmark`

### CSS stílus (az egyedi HTML template-ben)
- Háttér: `AppTheme.background` (#0D0D0D környezetében sima #0d0d0d)
- Szöveg: `rgba(255,255,255,0.85)`, monospace alap font
- `h1`, `h2`, `h3`: amber szín (`#F5A623`), Alien League Bold ha bundle-ben elérhető,
  fallback: system-ui bold
- `code` (inline): sztöbé sötétebb háttér pill, monospace
- `pre code` (kódblokk): scrollable, sötét háttér, amber left border (3px)
- `mark` (highlight): amber/gold háttér, sötét szöveg
- `table`: white border (30% opacity), alternating row opacity (0.04)
- `ul`/`ol`: rendes indent, pontok/számok láthatók

### Data model bővítés (CountdownItem.swift)
```swift
var notes: String = ""
// init(from decoder:) kötelező frissítés:
// notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
```
**FONTOS**: A CodingKeys enum és init(from decoder:) frissítés nélkül
hibsán decode-olna — ld. "FONTOS: CountdownItem Codable szabály" szekció.

### UI — trigger gomb a DetailView-ban (CountdownDetailView.swift)
- Ikon: `note.text` SF Symbol
- Stílus: mint a sound toggle / color picker gomb (44×44, RoundedRectangle clip,
  AppTheme.dark háttér), `.focusable(false)` kötelező
- Ha van tartalom: tele ikon + AppTheme.background fg
- Ha üres: `note.text` opacity(0.4) fg
- Megnyomva: `.sheet(isPresented:)` → NotesSheet

### NotesSheet (NotesSheet.swift — új fájl)
- Fejléc: slot neve (Alien League Bold, amber), "NOTES" felirat
- VIEW/EDIT toggle gomb (eye / pencil ikon)
- VIEW mód: `WKWebViewRepresentable` SwiftUI wrapper
- EDIT mód: `TextEditor`, font `.system(.body, design: .monospaced)`
- Copy gomb (raw markdown → NSPasteboard, minden módban)
- Dismiss gomb (Done / X)
- Minden gombra `.focusable(false)` (FocusBridge-megelőzés)

### Érintett fájlok
- `CountdownItem.swift` — `notes` mező + init(from decoder:) frissítés
- `CountdownDetailView.swift` — notes trigger gomb + sheet binding
- `NotesSheet.swift` — új fájl (WKWebView + TextEditor toggle)
- `marked.min.js` — bundled resource (kb. 45 KB, nem CDN)

---

## SNIPPETS — Master Prompt Snippets Tab (tervezett, Session 32)

**Concept**: Teljesen önálló, Slot-független szöveg-snippet tároló.
Cél: "master prompt snippetek" — visszatérően használt markdown szövegek
(AI promptok, projekt-kontextus, command template-k) egy helyen, Copy gombbal
azonnal használhatók. Projekt szerint csoportosítva.

### Data model (Snippet.swift — új fájl)
```swift
struct Snippet: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String           // "Auth flow prompt"
    var body: String            // A szöveg tartalma (markdown)
    var project: String         // "countdownApp", "sunikertek", stb. — string tag
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}
```
Storage: UserDefaults, kulcs `"snippets"`, JSON encode/decode.

### Tab integráció (ContentView.swift)
- 3. tab hozzáadva a Countdown mellé
- Tab ikon: `text.quote` vagy `doc.plaintext` SF Symbol
- Tab label: "SNIPPETS" (Alien League stílusban)

### SnippetsView.swift — fő lista (új fájl)
- VStack + ForEach csoportok: `Dictionary(grouping:) { $0.project }` →
  projektek szerint betűrendben
- Szekciófej: projekt neve (Alien League Bold, amber)
- Snippet sor: cím + rövid preview (első 60 karakter body-ból) + Copy gomb a sor végén
- Copy gomb: direkt másolás NSPasteboard-ra, navigáció nélkül
- Tap a sorra → SnippetEditSheet a feltöltött adatokkal (szerkesztés)
- `+` gomb a toolbar-on → üres SnippetEditSheet (új snippet)

### SnippetEditSheet.swift — szerkesztő modal (új fájl)
- Title TextField + Project TextField + TextEditor a body-hoz
- Font a body TextEditorhoz: `.font(.system(.body, design: .monospaced))`
- Copy gomb (teljes body → NSPasteboard), Dismiss, Delete (törlés confirmálással)
- Háttér: AppTheme.background, stílus: Alien League cimek, amber akcentus
- Minden gombra `.focusable(false)`

### Érintett fájlok
- `Snippet.swift` — új fájl, data model
- `SnippetsView.swift` — új fájl, fő lista
- `SnippetEditSheet.swift` — új fájl, szerkesztő modal
- `ContentView.swift` — 3. tab hozzáadása

---

## SOUND-1 — archívum (kész, Session 30)

### Mit csinált SOUND-1
Egy countdown slot lejáratakor (active → free átsorolás pillanatában) rendszerhang
szólal meg, ha az adott sloton be van kapcsolva. Per-slot toggle a DetailView-ban,
default OFF.

### Érintett fájlok
- `CountdownItem.swift` — új mező
- `CountdownView.swift` — lejárat detektálás + hang lejátszás
- `CountdownDetailView.swift` — toggle UI

### 1. CountdownItem.swift — új mező
```swift
var soundEnabled: Bool = false
```
A meglévő `Codable` decode backward-compatible marad: ha a JSON-ban nincs
`soundEnabled` kulcs, a Swift decoder a default értéket (`false`) használja.

### 2. Lejárat detektálás — CountdownView.swift

`@State private var previousActiveIDs: Set<UUID> = []` snapshot az aktív item
ID-kről. `rebuildCache(now:playExpirySounds:)` — ha `playExpirySounds: true`:
```swift
let newActiveIDs = Set(items.filter { !$0.isExpired(at: now) }.map { $0.id })
let justExpired = items.filter {
    previousActiveIDs.contains($0.id) && !newActiveIDs.contains($0.id)
}
for item in justExpired where item.soundEnabled {
    NSSound(named: "Funk")?.play()
}
previousActiveIDs = newActiveIDs
```
`crossingTask` hívja `rebuildCache(now: Date(), playExpirySounds: true)`-val.
Egyéb hívások (`onAppear`, `.onChange`) maradnak `playExpirySounds: false`-sal.

**Hang**: `NSSound(named: "Funk")?.play()` — beépített macOS rendszerhang,
sandbox-biztos, nem kell entitlement. Alternatívák: `"Ping"`, `"Glass"`, `"Pop"`.

**Import**: `import AppKit` a `CountdownView.swift` tetején.

### 3. CountdownDetailView.swift — toggle UI

```swift
Button {
    item.soundEnabled.toggle()
} label: {
    Image(systemName: item.soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
        .font(.system(size: 16))
        .foregroundStyle(item.soundEnabled ? AppTheme.background : AppTheme.background.opacity(0.4))
        .frame(width: 44, height: 44)
        .background(item.soundEnabled ? AppTheme.dark : AppTheme.dark.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 9))
}
.focusable(false)
```

---

## Korábbi állapot (Session 26 végén)

**Beachball fix — LEZÁRVA, commitolva (`07861a9`)**
- 23-A: `dropEntered` guard (`if ids != freeOrder`)
- 23-B: `LazyVStack` → `VStack` — végleges fix (nem temp), igazolva Instruments-szel
- 23-C: `cachedEntries` / `cachedFreeItems` / `crossingTask` — ForEach lecsatolva a tick-ről
- TimelineView tick: `1.0s` (visszaállítva)
- Nincs több TEMP flag a kódban

**CalculateView fixek — commitolva (`e3648e1`, `922e299`)**
- CALC-2/3: `snapToMinute()` — minden Date-write percre kerekít
- CALC-4: `RESET FROM NOW` + `RESET TO NOW` gombok
- CALC-1: `DAYS` / `CAL` toggle, `@AppStorage("calculateDisplayMode")`

**23-D — LEZÁRVA (`8b2035b`)**
`LongPressStepperButton.swift` — timer double-registration fix.

## Érintett fájlok (minden commitolva Session 30-ig, Session 35 commit pending)
- `CountdownItem.swift` — SOUND-1 (`c04d4a6`)
- `CountdownView.swift` — SOUND-1 (`c04d4a6`), beachball fixek (`07861a9`)
- `CountdownDetailView.swift` — SOUND-1 (`c04d4a6`)
- `CalculateView.swift` — CALC-1 (`525ed86`), CALC-SAVE (`c84bb39`), Session 35 polish (commit pending)
- `LongPressStepperButton.swift` — 23-D (`8b2035b`)
- `SunPanel.swift` — SUN-1-C (`bf41007`)
- `SunTimes.swift` — SUN-1-A (`86d0846`)
- `SunTimesService.swift` — SUN-1-A (`86d0846`)
- `NamedDeadline.swift` — CALC-SAVE (`c84bb39`)
