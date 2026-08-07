# countdownApp — Progress

## Session 5 — 2026-08-07

### Completed (handoff continuation, follow-up fixes)
- **Pill vastagsag csokkentve** -- CountdownRowView: a sotet pill belso padding-je `.padding(14)`
  -> `.padding(4)`
- **Toggle gomb kikerult a pill-bol** -- CountdownRowView: a remaining/deadline VALTO gomb
  (naptar/ora ikon) mostantol a pill-en KIVUL ul, kozvetlenul a sor sajat accent-szinen
  (`itemFreeColor` / `cardSurface`); a label+copy+ido-szoveg+ceruza tovabbra is egy kozos
  sotet (`AppTheme.dark`) `RoundedRectangle(cornerRadius: 14)` pill-en marad; a korabbi
  ketretegu "ring" trukk (`padding(4)` + kulon `background(ringColor)`) megszunt, most csak
  EGY accent-szin reteg van (`padding(10).background(accentColor)`), igy a szines szegely
  nem vastagodik feleslegesen
- **Detail nezet alapertelmezett remaining time** -- CountdownDetailView: uj lokalis
  `@State private var showRemaining: Bool = true`, letve az `item.showRemaining`-tol (ami
  a CountdownRowView sajat toggle-je marad); igy a Detail nezet mindig remaining time-mal
  nyilik, fuggetlenul attol, hogy a listasorban legutobb mire volt allitva
- **Teljes sor egy pill-be vonva** -- CountdownRowView: mar nem csak a label+copy, hanem a teljes
  sor tartalma (label, copy, remaining/deadline + ora-toggle, ceruza) egy kozos sotet
  (`AppTheme.dark`) `RoundedRectangle(cornerRadius: 14)` pill-en ul; az elem-specifikus szin
  (`itemFreeColor` FREE itemeknel, `cardSurface` egyebkent) csak 4pt-os kulso gyuruben/glow-ban
  latszik (`.padding(4).background(ringColor).clipShape(RoundedRectangle(cornerRadius: 18))`);
  jobb oldali szovegek/ikonok fg szine `AppTheme.dark` -> `Color.white.opacity(0.8-0.9)`, mert
  most mind sotet hatteren vannak; nyitott otlet: stacked elrendezes (ora az accountname alatt)
  ha a sor igy is szuknek bizonyul
- **Row label pill korrigalva** -- CountdownRowView: a pill nem `Capsule()` es nem csak a labelt
  foglalja magaba, hanem a label + copy ikon egyutt ul egy `RoundedRectangle(cornerRadius: 10)`
  sotet (`AppTheme.dark`) pill-ben (12/6 padding); a jobb oldali elemek (ido/datum, ora-toggle,
  ceruza) kivul maradtak a sor sajat szines hatteren -- ez volt az eredeti, korabbi kinezet
  screenshot alapjan visszaallitva; ezt kesobb tovabb bovitettuk a teljes sorra (lasd fentebb)
- **CountdownRowView label pill (elso verzio, kesobb korrigalva)** -- a listasorokban a label
  szoveg sajat sotet pill-en (`AppTheme.dark` hatter + `Capsule()`) ult, feherrel
  `Color.white.opacity(0.8)`; ez volt a fenti korrigalt verzio elozmenye
- **Add gomb disabled kontraszt** -- AddCountdownSheet: disabled allapotban a felirat szine
  `Color.white.opacity(0.8)`, enabled allapotban marad `AppTheme.background` (amber); korabban
  amber szoveg amber-es hatteren szinte lathatatlan volt
- **Tab valto lecserelve nativ Picker-rol sajat HStack-re** -- ContentView: a `.pickerStyle(.segmented)`
  natv macOS NSSegmentedControl figyelmen kivul hagyta a font/padding/foregroundStyle modositokat,
  ezert sajat gombokra (`modeButton`) cserelve: `Button` + `Image(systemName:)`, meret 22pt semibold,
  szin `AppTheme.background` (sarga), padding 14, kivalasztott allapotban sotet `Circle` hatter
  (`AppTheme.dark`), nem kivalasztott ikon opacity 0.45
- **Ikon-hozzarendeles felcserelve** -- Mode.symbolName: calculate -> "clock", countdown -> "at"
  (korabban forditva volt; a Countdown tab account-listat mutat, ahhoz az @ illik jobban,
  a Calculate-hez az ora)
- **CountdownRowView label pill** -- a listasorokban a label szoveg most sajat sotet pill-en
  (`AppTheme.dark` hatter + `Capsule()`) ul, feherrel `Color.white.opacity(0.8)`; korabban
  a label kozvetlenul a sor (expired/nem-expired) hatteren ult, ami a CountdownDetailView-beli
  account-name pill stilussal nem volt konzisztens

### Completed (earlier sub-sessions in this handoff)
- **AddCountdownSheet focus ring eltavolitva** -- Cancel es Add gombra `.focusable(false)` hozzaadva
- **Account name pill visszaallitva (CountdownDetailView)** -- Text most `.padding(.horizontal, 20)`
  + `.padding(.vertical, 10)` + `.background(AppTheme.dark)` + `.clipShape(Capsule())`;
  szoveg szine `Color.white.opacity(0.85)` -> `Color.white.opacity(0.8)`
- **Countdown lett az alapertelmezett nezet** -- ContentView: `selectedMode` init `.calculate` -> `.countdown`

### Completed (earlier sub-sessions)
- **CountdownRowView szerkeszto eltavolitva** -- showDeadlinePicker state, pencil gomb, .popover es
  deadlinePicker computed var torolve; FREE check badge megmaradt, deadline szerkesztes csak
  CountdownDetailView-ban el tovabb
- **Paradicsom 500px** -- CountdownDetailView tomato frame: 420 -> 500px (maxWidth + maxHeight)
- **Szovegmeretek novelve** -- remaining: 36 -> 46pt, deadline: 24 -> 30pt,
  mindket text frame: maxWidth 220 -> 260
- **CalculateView Spooky Tomato stiluus** -- AppTheme.background hatter (ZStack),
  CALCULATE fejlec (alienLeagueBold 32pt, kerning 4), FROM/TO caption (alienLeague 13pt,
  AppTheme.dark.opacity(0.6)), styled Rectangle divider (AppTheme.dark.opacity(0.25)),
  result label (alienLeague 15pt), result text (alienLeagueBold 38pt, AppTheme.dark)
- **CountdownDetailView always-on stepper** -- showEdit state torolve, stepper mindig latszik
- **Delete atkoltozott DetailView-ba** -- trash gomb (piros) a paradicsomban, X gomb torolve a sorokbol
- **CountdownRowView egyszerusitve** -- onDelete closure eltunt, tisztan csak a label + ido/FREE badge
- **CountdownView callback atvezetese** -- delete logika NavigationLink destination-ba kerult

### Completed (sub-session before last)
- **Ceruza gomb visszaadva** -- CountdownRowView HStack-be: Image(systemName: "pencil"),
  szin: Color(red: 221/255, green: 17/255, blue: 74/255) (#DD114A); nem Button, igy a parent
  NavigationLink tuz es CountdownDetailView-ra navigal
- **Szovegmeretek novelve** -- CountdownDetailView: remaining 48 -> 56pt, deadline 36 -> 44pt,
  frame maxWidth 260 -> 300
- **Trash hattere #B70E26** -- Color.red.opacity(0.85) -> Color(red: 183/255, green: 14/255, blue: 38/255)
- **Cancel gomb fix** -- AddCountdownSheet: explicit .foregroundStyle(AppTheme.dark) a Cancel Buttonra
- **Account name visibility fix** -- CountdownDetailView: .navigationTitle("") hozzaadva a ZStack-re

### Completed (Session 5 polish pass)
- **Trash hattere = dark** -- CountdownDetailView: trash background AppTheme.dark
- **Cancel gomb fix vegleges** -- AddCountdownSheet: NavigationStack + toolbar teljesen eltavolitva;
  sajat HStack top bar Cancel + Add gombokkal, AppTheme stílusban; Add disabled + halvanyabb ha label ures
- **Account name szine** -- CountdownDetailView: foregroundStyle -> Color.white.opacity(0.85)
- **Account name copy gomb** -- CountdownDetailView header-bol atkerult CountdownRowView-ba;
  Image + simultaneousGesture(TapGesture) pattern (NavigationLink nem tuz el);
  label mel: doc.on.doc ikon -> checkmark 1.2s visszajelzes; trim whitespace masolas elott
- **freeColors lista 11 szin** -- AppTheme: #575F03 kiszedve; vegso lista:
  778005 · 30271B · 293B72 · 4D70D8 · 403873 · 593C73 · 8A4273 · 723F73 · DD3B72 · DD114A · B70E26
- **CountdownRowView freeColor indexelt** -- item.id.hashValue % 11 alapjan valaszt
- **CalculateView stepper szerkesztes** -- DatePicker -> componentStepper (YEAR/MON/DAY/HOUR/MIN)
- **CalculateView eredmeny unit stilus** -- mennyiseg alienLeagueBold 38pt, unit alienLeague 18pt opacity(0.5)
- **CalculateView labelek** -- FROM/TO + "Elapsed/Remaining time:" egyforma meret: alienLeague(20), opacity(0.7);
   utolso fix (15->20 a result labelen) manuálisan alkalmazva

---

## Session 6 — 2026-08-07

### Completed
- **Pencil icon removed** — `Image(systemName: "pencil")` + foregroundStyle + frame torolve
- **Toggle kor hozzaadva** — toggle gomb `.background(AppTheme.dark).clipShape(Circle())` keretbe kerult,
  ikon szine `AppTheme.background` (amber), meret 28x28; ez egyezik a cel kepernyon latott kinezzettel
- **Pill vertical padding csokkentve** — `.padding(.vertical, 8)` -> `.padding(.vertical, 4)`;
  a pill szorosan koruleveszi a szoveget, nem terjed feleslegesen

### Open tasks (next session)
- Swipe-to-delete alternativa (ha kell a listaban is)
- Tap-to-edit label (jelenleg mindig szerkesztheto TextField)

---

## Session 4 — 2026-08-07

### Completed
- Per-account free color → single color `#593C73` (AppTheme.freeColor)
- FREE ✓ badge inline a label sorában (egy sor, nem kettő)
- Deadline szerkesztés: ceruza gomb → 5 komponenses stepper (év/hó/nap/óra/perc) CountdownDetailView-ban
- Alapértelmezett deadline: Date() (most), nem +24h
- macOS build fixek: navigationBarTitleDisplayMode, toolbarBackground, toolbarColorScheme, onChange deprecated signature
- TextField foregroundColor fix (foregroundStyle nem működik macOS TextFielden)
- Paradicsom méret: 300 → 420px
- Account label méret: 28 → 36pt (CountdownDetailView)
- Tomato szöveg: frame(maxWidth: 220) + padding(.horizontal: 16)

---

## Session 3 — 2026-08-07

### Completed
- FREE SLOT HIGHLIGHT implemented:
  - `AppTheme.freeGreen` added (RGB 0.204/0.780/0.349, ~#34C759)
  - `CountdownRowView` updated: expired card → green bg, white fg, green glow shadow,
    `"FREE ✓"` in Alien League Bold 30pt instead of red "EXPIRED"
  - Deadline-date toggle still functional on expired items (shows expiry date in white)
  - No `@State` animation — static glow, performant in List
  - Files changed: `AppTheme.swift`, `CountdownRowView.swift`, `spec.md`, `progress.md`

---

## Session 1+2 — 2026-08-07

### Completed
- Calculate mode: working (date/time diff, from/to pickers)
- Countdown mode architecture:
  - CountdownView: NavigationStack list, add/delete, persistence (UserDefaults JSON)
  - CountdownDetailView: full-screen Spooky Tomato design (tomato image + text overlay)
  - CountdownRowView: label TextField + ticking time + toggle + X delete
  - AddCountdownSheet: label + deadline picker
  - CountdownItem model: Codable, Equatable, Identifiable

### Manual Xcode steps STILL NEEDED
- [ ] Assets.xcassets: add spooky_tomato.png (name: "spooky_tomato")
- [ ] Drag 4 alienleague .ttf into Xcode (Copy + target membership)
- [ ] Info.plist: "Fonts provided by application" array with 4 filenames
- [ ] Project Navigator: Add Files → select all new .swift files
- [ ] Verify Alien League PostScript name in Font Book
