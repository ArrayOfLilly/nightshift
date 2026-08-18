# Claude.md — countdownApp fejlesztési policy

## Alapelv

Ez a fájl kötelező érvényű minden fejlesztési sessionban. Olvasd el a `docs/progress.md` és
`docs/countdownApp-handoff.md` után, mielőtt bármit implementálsz.

---

## Session management — free tier

Ez a projekt ingyenes Claude tieren fut. Ennek következményei:

- **Egy session = egy jól körülhatárolt task**, dokumentálással együtt — ne tervezz többet mint ami elfér
- **Azonnal dokumentálj** minden olvasást és döntést — session határon semmi sem marad meg
- **Fájlolvasás szeriálisan** — soha ne töltsd be az összes érintett fájlt egyszerre
- **Fájlírás**: `Filesystem:write_file` teljes cserével vagy `MacOS-MCP:Shell` — soha ne chunkolj
  Desktop Commander stílusban, mert fél fájl elveszhet ha a session letelik közben

---

## Egyeztetés implementáció előtt

Minden döntésnél, ami érinti a kód minőségét, későbbi fejleszthetőségét, módosíthatóságát
vagy bővíthetőségét, **először kérdezz, ne implementálj**.

Ez konkrétan magában foglalja (nem kizárólagos lista):

- Új fájl vagy típus bevezetése
- Meglévő fájl struktúrájának, felelősségének megváltoztatása
- Adatmodell bővítése vagy módosítása (különösen `Codable` érintett típusoknál)
- Persistence layer érintése (új kulcs, új mechanizmus, `UserDefaults` vs. fájl)
- Új `@State`, `@StateObject`, `@EnvironmentObject` bevezetése
- Új `.onChange`, reaktív oldal-effekt, lifecycle hook
- Dependency bevezetése (framework, package)
- Naming döntések, amelyek publikus API-t érintenek
- Bármilyen pattern, amely precedenst teremt a többi fájlra nézve

Ha nem vagy biztos hogy egy döntés ebbe a körbe esik-e: **kérdezz**.

---

## Kódminőség

### Best practice — mindig

- Swift idiomatikus kód; ne kerüld el a language feature-öket kényelemből
- Single Responsibility: egy típus, egy felelősség
- Névadás legyen explicit és önmagát dokumentáló
- Ne vezess be absztrakciót, amíg nincs legalább két konkrét használati hely
- Ne vezess be `TODO`-t vagy `FIXME`-t anélkül, hogy a buglistába is felveszed
- Kommentek angolul; csak azt kommenteld, ami nem nyilvánvaló a kódból

### Amit kerülünk

- **AI slop**: felesleges wrapper, over-engineered absztrakció, "általánosított" megoldás
  egy konkrét problémára, nem kért feature, defensive coding ami sosem fog kelleni
- **Lusta eszköz- és modellválasztás**: a megoldás feleljen meg a probléma valódi természetének,
  ne a legkönnyebb implementációs útnak. Ha egy új feature más adatmodellt vagy tárolási
  mechanizmust igényel, azt kell bevezetni — nem a feature-t kell a meglévő architektúrához
  törni. KV store, glorified JSON, vagy egy meglévő modell erőltetett bővítése csak addig
  elfogadható, amíg valóban illeszkedik a feladathoz. Az eszközt és a modellt a probléma
  választja ki, nem fordítva.
- Másolás-beillesztés meglévő kódból anélkül, hogy megkérdeznéd miért volt ott duplikáció
- Implicit feltételezés a meglévő kód szándékáról — ha nem egyértelmű, olvasd el a fájlt
- `try?` kritikus persistence path-on (az audit 1 és 12 findingei alapján ez ismert tech debt)

---

## Swift 6.3 Strict Concurrency

Az új kód Swift 6.3 strict concurrency szabályait követi. A meglévő kódban nem refaktorálunk
most, de nem rontjuk el a helyzetet.

### Új kódban kötelező

- `@MainActor` annotáció minden SwiftUI view-on és view modellen
- `Sendable` conformance minden típuson, amely határt lép (Task, async context)
- `nonisolated` explicit jelölés ahol indokolt, nem alapértelmezésként
- `async/await` — ne használj `DispatchQueue.main.async`-ot új kódban
- `Task` helyett `task(id:)` view modifier ahol az életciklus a view-hoz kötött

### Meglévő kódban

Ha egy meglévő fájlt szerkesztesz és concurrency warningot láthatnánk strict módban,
jelezd — ne javítsd automatikusan, mert a scope-ot egyeztetni kell.

---

## Adatmodell szabályok

Ezek megszegése adatvesztést okoz (storage-audit.md, codable-audit.md alapján):

- `CountdownItem`, `Snippet`, `NamedDeadline` bővítésekor **kötelező** `decodeIfPresent` +
  default value az `init(from decoder:)`-ben — synthesized Codable tilos új mezőnél
- Új UserDefaults kulcs csak `enum AppKeys`-en keresztül vezethető be (ha az még nem létezik,
  annak bevezetése az első lépés)
- Persistence mechanizmus változtatása (pl. UserDefaults → fájl) mindig egyeztetés tárgya

---

## Docs karbantartás

Session végén kötelező:

1. `docs/progress.md` — session bejegyzés hozzáadva
2. `docs/countdownApp-handoff.md` — aktuális állapot frissítve
3. Git commit — minden változás egy commitba, értelmes üzenettel

Ha egy session közben a handoff elavul (pl. fájlok átkerültek, döntés visszavonva),
azonnal frissítsd — ne hagyd session végére.

### Manual (docs/manual/*.md) — szöveg vs. screenshot

A manual két, eltérő frissítési ütemű részből áll — ezeket nem szabad egybemosni:

- **Leíró szöveg** (viselkedés, UI-elemek listája, workflow-k): amint egy session megváltoztat
  egy olyan viselkedést, amit a manual leír, **azonnal** ellenőrizd az érintett manual
  fájl(oka)t (`nightshiftApp-manual.md` EN + `nightshiftApp-manual-hu.md` HU, mindkettő), és ha
  elavult, javítsd ki ugyanabban a sessionben — nem kell megvárni egy "manual session"-t.
  Ez ugyanaz a fegyelem, mint a `docs/progress.md`/`countdownApp-handoff.md` azonnali
  frissítése fent.
- **Screenshotok**: ezek valóban megvárják, amíg az érintett UI-terület stabil (nem érdemes
  ismételten újrakészíteni egy még változó nézetről) — ez marad batch-elt, session-határokon
  átívelő feladat, lásd `docs/buglist.md` BUG-MANUAL-SCREENSHOTS.

Ha nem egyértelmű, hogy egy változás érinti-e a manualt: grep a `docs/manual/*.md` fájlokban
az érintett fül/funkció nevére, mielőtt a session lezárul.

---

## Fájlstruktúra

```
countdownApp/countdownApp/          ← inner repo gyökér
├── countdownApp/                   ← Swift forrás
├── docs/
│   ├── countdownApp-handoff.md
│   ├── progress.md
│   ├── history.md
│   ├── manual_build.py
│   ├── audit_files/
│   ├── manual/
│   └── misc/
└── Claude.md                       ← ez a fájl
```
