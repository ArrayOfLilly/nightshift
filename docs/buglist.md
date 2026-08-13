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

**Státusz:** NYITOTT — egyeztetés KÉSZ, implementáció következő session

---
