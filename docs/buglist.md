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

**Megközelítés (egyeztetés után):**
- Főablakra: `.frame(maxWidth: X)` valahol a ContentView / WindowGroup szintjén, vagy
  a WindowHelpers-be kerülő új helper a tartalom constraint-jére
- ComponentStepper: `.frame(maxWidth:)` a stepper belső layout-ján belül
- CountdownRowView: `.frame(maxWidth:)` a sor szintjén
- Popupok: esetileg, csak ahol a tartalom valóban szétfolyik

**Státusz:** NYITOTT — implementáció előtt egyeztetés

---
