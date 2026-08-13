# countdownApp — Bug & Enhancement List

Minden bejegyzés egyeztetés után kerül implementációra.
Prioritás-jelzés: 🔴 kritikus, 🟡 fontos, 🟢 nice-to-have

---

## UX-1: Max-szélesség korlátok hiánya 🟡

**Érintett területek:**
- Főablak (ContentView / CountdownView) — nincs maximális szélesség; nagyon széles ablakban
  az elemek ízléstelenül szétfolynak
- `CalculateView` componentStepper-ek — a két chevron gomb eszelősen messze kerül egymástól
  széles ablakban; a steppernek saját `maxWidth`-re van szüksége
- `CountdownRowView` countdown elemek — hasonló probléma: a sor megnyúlik, nincs cap
- `SnippetsView` snippet sorok — kisebb prioritás, de konzisztencia miatt érdemes limitálni

**Popupok — egyenkénti ellenőrzés szükséges:**
- `AddCountdownSheet` — már van `WindowHelpers` alapú sheetWidth; ellenőrizni: tartalom
  a széles ablakban összetartja-e magát
- `ColorPickerSheet` — ellenőrizni
- `NotesSheet` — ellenőrizni
- `SnippetEditSheet` — ellenőrizni
- `DeadlineDetailSheet` — új fájl, még nem ellenőrzött
- `CalculateView` (saveSheet + deadline detail) — ellenőrizni

**Egyeztetés lezárva (AU session):**
- Főablak max szélesség: **520pt** — ez az egyetlen szükséges változás
- Megvalósítás: ContentView / WindowGroup szinten (pontosan hol: implementációkor dől el)
- ComponentStepper, CountdownRowView, SnippetsView sorok: külön cap nem kell — a főablak max elég
- Popup-ok (AddCountdownSheet, ColorPickerSheet, DeadlineDetailSheet, CalculateView sheets,
  NotesSheet, SnippetEditSheet): mind marad a jelenlegi WindowHelpers range — nem érintett
- Referencia: MBP M4 14", 1800×1169 felbontás; app ablak látható szélessége ~500–520pt-nek
  felel meg azon a kijelzőn (Claude Desktop ~900px + app a maradék jobb oldalon ~55–60%)

**Státusz:** ✅ KÉSZ — implementálva AU sessionben (`AppTheme.windowMaxWidth = 520`, commit `bc725a2`/`4bbe75e`).
Lásd UX-2 alant — az 520pt érték felülvizsgálat alatt.

---

## UX-2: Főablak max szélesség felülvizsgálata (520pt → 600pt?) 🟡

A felhasználó visszajelzése szerint a tényleges ablak szélesség 500–520pt között mozog — a jelenlegi
`windowMinWidth = 460` / `windowMaxWidth = 520` (UX-1, AU session) tartomány gyakorlatilag nem enged
érdemi átméretezést.

**Két opció, egyeztetés szükséges:**
1. `windowMaxWidth` növelése 600pt-ra — több mozgástér az átméretezésre
2. Fix 500pt szélesség, `.windowResizability` teljesen kikapcsolva — ha úgyis csak 500–520pt között van értelme,
   az átméretezhetőség feleslegessé válik

**Státusz:** NYITOTT — egyeztetés szükséges melyik irány, implementáció külön session

---

## BUG-CHECKMARKDIRTY-1: SnippetEditSheet checkmark mentése után az X mégis confirm alertet mutat 🔴

Meglévő snippet szerkesztése: szöveg módosítása → checkmark (menti, VIEW módba vált) → X (bezárás) —
az X ennek ellenére felteszi a “Quit without saving / Save and quit / Cancel” confirm alertet, holott a
checkmark már elmentette a változást és nem kéne újra rákérdeznie.

**Valószínű root cause (AZ session implementáció alapján):** `originalTitle`/`originalProject`/`originalBody`
`let` property-k, csak `init`-ben beállítva (dirty baseline). A checkmark (`commitEdit()`) menti a
szöveget és `isEditing = false`-ra vált, de az `original*` baseline-t NEM frissíti — így az `isDirty`
computed var továbbra is `true`-t ad, mert a jelenlegi érték még mindig eltér az init-kori originaltól.
Ezért az utána következő X (`handleDismiss()`) feleslegesen dirty-nek látja az állapotot.

**Ellenőrzés a következő sessionben:** meg kell nézni, hogy a `commitEdit()` (checkmark ág) frissíti-e
az `original*` értékeket mentés után — ha nem, ezt kell pótolni (pl. `original* = current*` a `commitSave()`
hívása után, checkmark ágban). Megjegyzés: mivel az `original*` jelenleg `let`, ehhez `var`-ra kell váltani
— ez adatmodell-érintő változás, a Claude.md szabálya szerint egyeztetés szükséges implementáció előtt.
Hasonló root cause-t érdemes megnézni a `NotesSheet`-ben is (lásd `BUG-NOTESDISMISS-1` — ott más a hiba,
de a dirty-tracking mechanizmus rokon).

**Státusz:** ✅ KÉSZ — BC session: `let` → `var` az `original*` property-ken; `commitEdit()` checkmark ágában `originalTitle/Project/Body = title/project/snippetBody` refresh a `commitSave()` után.

---

## BUG-MANUAL-1: Manual frissítése a bezárási metódus változása miatt 🟡

Az AZ sessionben implementált pipa/X viselkedés (`NotesSheet` + `SnippetEditSheet` — pipa: ment+dismiss,
X: dirty esetén confirm alert) nincs dokumentálva a manualban. Screenshotok készülnek, utána a
`countdownApp-manual.md` érintett szekciói (Notes, Snippets szerkesztés) frissítendők.

**Függőség:** a manual frissítés (és screenshotok készítése) csak az összes többi nyitott, UI-t érintő
további változás (pl. `ENH-NOTEBADGE-1`) elkészülte után történjen — a manual mindig utolsóként jön,
hogy a screenshotok a végleges állapotot tükrözzék.

**Státusz:** NYITOTT — screenshot előkészítés alatt (felhasználó oldalán), implementáció (manual szöveg/kép) külön session

---

## ENH-DEVDOCS-1: Fejlesztői dokumentáció hiányzik 🟡

Nincs külön fejlesztői dokumentáció (architektúra áttekintés, modul felelősségek, persistence réteg,
recovery infrastruktúra, hogyan fejlesztünk egy új feature-t) — jelenleg csak a `Claude.md` (fejlesztési policy) +
`countdownApp-handoff.md` (session-állapot) létezik, ezek nem helyettesítik a termék/architektúra dokumentációt.

**Státusz:** NYITOTT — tartalom + struktúra egyeztetése szükséges, implementáció külön session

---

## BUG-TRASH-1: Editor trash gomb nem törli véglegesen a snippetet 🔴

Az editorban (`SnippetEditSheet` feltételezhetően, pontosítandó) a trash gomb látszólag törli a snippetet,
de a törlés után visszakerül (feltehetően auto-save / `.onDisappear` / dirty-state interakció miatt).

**Státusz:** NYITOTT — root cause vizsgálat szükséges (melyik view pontosan, mi írja vissza), implementáció külön session

---

## BUG-DETAILDELETE-1: CountdownDetailView törlés után nem navigál vissza 🔴

`CountdownDetailView`-n egy countdown item törlésekor a nézet nem csukódik be / navigál vissza automatikusan
a `CountdownView`-ra — a felhasználó egy már nem létező item részletein marad, ami használhatatlan állapot.

**Státusz:** NYITOTT — implementáció külön session (valószínűleg `dismiss()` vagy navigation pop hozzáadása
a delete action-höz)

---

## BUG-NOTESDISMISS-1: NotesSheet X gomb ment szó nélkül, nem követi a SnippetEditSheet dirty-check mintát 🔴

Az AZ sessionben a `SnippetEditSheet`-ben implementált pipa/X viselkedés (X gomb: dirty állapotban
confirm alert “Cancel” / “Quit without saving” / “Save and quit”, tiszta állapotban egyszerű dismiss)
nem került át a `NotesSheet`-be — ott az X továbbra is szó nélkül menti és bezárja a lapot, ahelyett
hogy ugyanazt a dirty-check + confirm alert logikát követné.

Megjegyzés: a `progress.md` BA session bejegyzése tévesen állította, hogy a `NotesSheet` már helyesen
implementálva volt (“nem érintett, már helyes volt”) — ezt a következő sessionben felül kell vizsgálni
a tényleges kód alapján, nem a korábbi feljegyzés alapján.

**Státusz:** ✅ KÉSZ — BC session: debounce eltávolítva; `originalNotes` baseline (`.onAppear` +
`commitEdit()` refresh); `handleDismiss()` `draft == originalNotes`; "Quit without saving" visszaállít.

---

## ENH-NOTEBADGE-1: Vizuális jelzés a countdown itemen, ha van hozzá note 🟢

Jelenleg a `CountdownRowView` (és feltételezhetően `CountdownDetailView` címe is) nem jelzi vizuálisan,
hogy az adott countdown itemhez tartozik-e note. Felhasználói megfogalmazás: kell valami jelzés a név
mögé, pici badge — szín: **orangered**; forma: dot/szem-ikon/note-ikon — pontos választás még nyitott,
ha `item.notes` nem üres.

**Fontos sorrend:** ez a változás a manual (`BUG-MANUAL-1`) előtt valósítandó meg — a manual screenshotok
csak a végleges UI állapotot tükrözik, így a note badge-nek már látszania kell rajtuk mielőtt a manual
frissítés (és az ahhoz tartozó screenshotok) elkészülnek. Általánosabban: a manual mindig utolsóként
következik, miután minden más, UI-t érintő változás (bugfix vagy enhancement) már elkészült.

**Egyeztetendő részletek a következő sessionben:**
- Szín: **orangered** lezárva; `AppTheme`-ben nincs még orangered token — új szín bevezetése szükséges
  (Claude.md szabály: `enum AppKeys`-hez hasonlóan át kell gondolni, hova kerüljön — valószínűleg
  `AppTheme` új static color property-je)
- Forma: egyszerű dot, vagy szem-ikon (👁️-szerű), vagy note-ikon (📝-szerű) — SF Symbols közül kell
  választani, ha ikon a választás
- Méret, pozíció a név mellett/mögött
- Csak `CountdownRowView`-n, vagy `CountdownDetailView` fejlécén is jelenjen meg?
- Feltétel: `item.notes` nem üres string (trim-elve?) vagy csak nem-nil, ha a mező opcionális

**Státusz:** NYITOTT — csak dokumentálva, egyeztetés + implementáció külön session

---

## ENH-DEFERRED-1: Deferred taskok dokumentálása (lokalizáció, Settings, About, Help) 🟢

Több deferred téma nincs formálisan dokumentálva:
- **Lokalizáció**: UI nyelv és input nyelv/locale-ok külön kezelése (a `Formatters.swift` fejléc már említi
  deferred taskként, de nincs részletes terv)
- **Settings menü**: jelenleg nincs — szükséges lenne a lokalizációs beállításokhoz és egyéb jövőbeli
  opciókhoz
- **About**: termék-infó (verzió, szerző, stb.) nincs
- **Help menü**: nincs

**Státusz:** NYITOTT — csak dokumentálás, nincs implementációs döntés; scope + prioritás egyeztetése szükséges

---
