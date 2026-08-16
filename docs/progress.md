## Session CO — 2026-08-16 (ENH-HELP-2: Overview + Countdown szekció bővítése — FOLYAMATBAN)

### Session CO — FOLYAMATBAN
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `Models/HelpContent.swift` elolvasva (25 item, 5 szekció áttekintve)
- [x] **Új feladat felvéve: ENH-HELP-2** — a felhasználó szerint a Help menü nem elég
  részletes; kérése: minden szekció bővebb szöveget kapjon (nem új item, hanem a
  meglévő body szövegek mélyítése)
- [x] **Overview szekció (5/5 item) kész** — csak `Localizable.xcstrings` EN+HU
  `body` értékek bővítve: `what`, `cooldowns`, `schedule`, `views`, `tooltips`
- [x] **Countdown szekció (8/8 item) kész** — csak `Localizable.xcstrings` EN+HU
  `body` értékek bővítve, `HelpContent.swift` nem változott:
  - `add` — célidőpont részletezése + azonnali visszaszámlálás indítása
  - `copy` — használati példa (fiók/modell név beillesztése)
  - `edit` — mit lehet szerkeszteni + azonnali érvénybe lépés
  - `expand` — keresztutalás Edit/Notes funkciókra
  - `free` — mi történik a szabad slottal (változatlan marad szerkesztés/törlésig)
  - `notes` — használati példa (megszakított munka folytatása) + szem-jelvény feltétel
  - `reorder` — cél (gyakran ellenőrzött fiókok feljebb) + aktív/free külön csoport
  - `toggle` — konkrét példa a formátumra (2ó 15p)
- [ ] Calculate szekció (6 item) — KÖVETKEZŐ
- [ ] Snippets szekció (4 item)
- [ ] Recovery szekció (2 item)
- [ ] Build: FELHASZNÁLÓ FELADATA

**Következő session:** ENH-HELP-2 folytatása — Calculate szekció (6 item: stepper,
reset, toggle, deadlines, load, sunpanel) body szövegeinek bővítése ugyanezzel a
mintával.

---

## Session CN — 2026-08-16 (Help: projekt törlés + tooltipek — LEZÁRVA)

### Session CN — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] `Models/HelpContent.swift`, `Localizable.xcstrings` elolvasva (teljes Help tartalom áttekintve)
- [x] **Érintett fájlok**: `Models/HelpContent.swift`, `Localizable.xcstrings`
- [x] **`HelpContent.swift`**: 2 új `HelpItem` hozzáadva:
  - `snippets.projects` (`folder` ikon) — projekt törlés → General viselkedés
  - `overview.tooltips` (`cursorarrow` ikon) — hover tooltip-ek ismertetése
- [x] **`Localizable.xcstrings`**: 4 új kulcs beillesztve EN+HU-val:
  - `"help.snippets.projects.body"` / `"help.snippets.projects.title"`
  - `"help.overview.tooltips.body"` / `"help.overview.tooltips.title"`
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Snippets.projects tartalom (EN):** "Snippets are grouped by project. Tap the chevron next to a project name to rename or delete the group. Deleting a project does not remove any snippets — they are moved to General automatically."

**Overview.tooltips tartalom (EN):** "Hover the mouse over any button to see a short description of what it does. Most interactive elements throughout the app have a tooltip."

**Megjegyzés:** A manual frissítése (BUG-MANUAL-1) a felhasználó feladata (projekt törlés + tooltipek ott is dokumentálandók).

**Következő session:** build ellenőrzés, BUG-MANUAL-1 (ha a felhasználó átadja), ENH-DEVDOCS-1/2, vagy ENH-L10N-1 maradék.

---

## Session CM — 2026-08-16 (Countdown tooltip javítás — LEZÁRVA)

### Session CM — LEZÁRVA
- [x] `Claude.md`, `docs/progress.md`, `docs/countdownApp-handoff.md` elolvasva
- [x] **Érintett fájlok**: `CountdownRowView.swift`, `CountdownView.swift`, `Localizable.xcstrings`
- [x] **`CountdownRowView.swift`**: label pill HStack-re `.help(String(localized: "Copy text"))` hozzáadva (`.simultaneousGesture` után)
- [x] **`CountdownView.swift`**: mindkét NavigationLink-re (free + active ág) `.help(String(localized: "Open slot details"))` hozzáadva (`.focusEffectDisabled()` után)
- [x] **`Localizable.xcstrings`**: 2 új kulcs EN+HU-val:
  - `"Copy text"` → `"Szöveg másolása"`
  - `"Open slot details"` → `"Slot részletek megnyitása"`
- [x] Git commit `e73d7ec`: `CM: tooltip .help() for countdown row NavigationLink and label pill`
- [x] Git commit `81cd2a3`: `CM2: fix moon button tooltip — .help() after .popover() so hover is not swallowed`
- [x] Git commit `811fe05`: `CM3: moon tooltip — .help() on wrapper VStack outside popover; remove pill and clock/cal .help()`
- [x] Git commit `7d067b9`: `CM4: remove trivial .help() from reset and save buttons in CalculateView`
  - `nowButton` helper: `helpText` paraméter eltávolítva, `.help()` törölve
  - SAVE gomb: `.help()` törölve
- [x] Git commit `d094b79`: `CM5: NativeTooltip — AppKit NSView.toolTip for moon button, bypasses .help() tracking area issue`
  - `Components/NativeTooltip.swift` új fájl: `NSViewRepresentable` alapú `.nativeTooltip()` View extension; transzparens `NSView` overlay-ként regisztrálja az `NSView.toolTip`-et AppKit-en direkt
  - `CalculateView.swift`: moon VStack wrapper `.help()` → `.nativeTooltip()` cserélve
- [x] Git commit `941731e`: `CM6: nativeTooltip padding param — expand tracking area around moon button`
  - `NativeTooltip.swift`: `padding: CGFloat = 0` paraméter hozzáadva — negatív padding-gel az NSView overlay nagyobb mint a layout frame, így a tracking area kiterjed a hold körüli területre is
  - `CalculateView.swift`: `.nativeTooltip(..., padding: 16)` — **MŰKÖDIK**
  - `CalculateView.swift`: moon gomb Button-t `VStack(spacing:0)`-ba csomagolva; `.help()` és `.offset()` a VStack-ra kerültek, `.popover()` a Button-on maradt — a popover tracking area így nem nyeli el a hover eventeket
  - `CountdownRowView.swift`: pill `.help("Copy text")` és clock/cal gomb `.help()` eltávolítva — a NavigationLink `.help("Open slot details")`-je mindkettőn felülírt volna
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Megjegyzés:** Eye badge (`eye.fill` Image) szándékosan kimaradt — nem interaktív elem, `.help()` nem regisztrál AppKit NSToolTip-et sima Image-en.

**Következő session:** egyeztetés alapján — BUG-MANUAL-1, ENH-DEVDOCS-1/2, ENH-L10N-1, vagy Calculate tooltip javítások (LongPressStepperButton hold, SavedDeadlines row).

---

## Session CL — 2026-08-16 (focusable(false) → focusEffectDisabled() audit — LEZÁRVA)

### Session CL — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] **Teljes audit**: minden Swift fájl átnézve `.focusable(false)` előfordulásokra
- [x] **Döntés**: Button-ökön `.focusable(false)` → `.focusEffectDisabled()` (macOS 14+, target macOS 26.5)
  - `.focusEffectDisabled()`: benne hagyja az elemet a Tab sorrendben, eltávolítja a focus gyűrűt, NEM zavarja az NSToolTip regisztrációt
  - `.focusable(false)`: kiveszi az elemet az AppKit focus chain-ből → sporadikus tooltip elmaradás lehetséges
  - **Kivétel (szándékos `.focusable(false)` marad):**
    - `LongPressStepperButton` Image-en: nem Button, DragGesture-s Image, kizárás az AppKit focus chain-ből szándékos
    - `SnippetEditSheet` sheet container `.focusable(false)`: Session K-s workaround — AppKit first-responder elkerülés Title TextField-en
    - `AboutView` gyökerén `.focusable(false)`: About ablak-szintű, szándékos
    - `AddCountdownSheet` LABEL VStack `.focusable(false)`: TextField-et tartalmazó VStack, AppKit workaround, marad
- [x] **6 fájl módosítva** (Filesystem:edit_file, sebészeti cserék):
  - `Views/Countdown/NotesSheet.swift` — `headerButton` helper + üres állapot Button: 2 csere
  - `Views/Countdown/ColorPickerSheet.swift` — X gomb + swatch buttonok: 2 csere; X gomb `.help("Close")` → `.help(String(localized: "Close this color picker"))` javítva
  - `Views/Snippets/SnippetsView.swift` — `sectionHeader` Menu: 1 csere
  - `Views/ContentView.swift` — `modeButton`: 1 csere
  - `Views/Countdown/AddCountdownSheet.swift` — Cancel + Add gombok: 2 csere
  - `Views/AboutView.swift` — `infoRow` Button: 1 csere
- [x] Git commit `87afdbb`: `CL: focusable(false) → focusEffectDisabled() on all Button targets`
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Megjegyzés:** `CalculateView.swift` és `DeadlineDetailSheet.swift` már az előző session (CK előtt) teljesen rendbe volt hozva — az ottani Button-ök már `.focusEffectDisabled()` voltak. `CountdownDetailView.swift`, `CountdownView.swift`, `SnippetEditSheet.swift` (headerButton helper) is már kész volt.

**Következő session:** egyeztetés alapján — lehetséges témák: BUG-SNIPPEDITBEACHBALL-1 megerősítése, ENH-DEVDOCS-1/2, BUG-MANUAL-1.


---

## Session CK — 2026-08-15 (ENH-TOOLTIP-1 lezárva — LEZÁRVA)

### Session CK — LEZÁRVA
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` elolvasva
- [x] **Teljes audit**: minden érintett Swift fájl átnézve — a `.help()` modifier szinte mindenhol
  már megvolt korábbi sessionokból (CH és előzők). Valódi hiányok:
  - `ContentView.swift` `modeButton` — nem volt `.help()`
  - `SnippetsView.swift` `snippetRow` edit button — nem volt `.help()`
- [x] **`Localizable.xcstrings`** — 3 új kulcs beillesztve EN+HU-val:
  - `"Switch to Calculate"` → `"Váltás a Kalkulációra"`
  - `"Switch to Countdown"` → `"Váltás az Időzítőre"`
  - `"Switch to Snippets"` → `"Váltás a Gyorsszövegekre"`
- [x] **`Views/ContentView.swift`** — `modeButton`-ra `.help(String(localized: String.LocalizationValue("Switch to \(mode.rawValue)")))` hozzáadva; az interpolált string exact match az xcstrings kulcsokra
- [x] **`Views/Snippets/SnippetsView.swift`** — `snippetRow` edit button-ra `.help(String(localized: "Open this snippet to view or edit its content"))` hozzáadva
- [x] Git commit `05c1460`: `ENH-TOOLTIP-1: modeButton .help() + snippetRow edit .help() + 3 xcstrings keys`
- [x] `docs/progress.md`, `docs/countdownApp-handoff.md`, `docs/buglist.md` frissítve
- [ ] Build: **FELHASZNÁLÓ FELADATA**

**Következő session:** egyeztetés alapján (BUG-SNIPPEDITBEACHBALL-1 megerősítése, ENH-DEVDOCS-1/2, BUG-MANUAL-1).
