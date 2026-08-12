# countdownApp — Refactor Plan

## Státusz: TERVEZÉS ALATT

Audit forrás: `docs/audit_files/` (16 fájl, mind kész)
Döntési elv: `Claude.md`

---

## Prioritási keretek

A 16 audit findingeit 3 keret mentén rendezzük:

1. **Adatvesztés-kockázat** — javítandó mielőtt bármilyen modell bővítés történik
2. **Fejleszthetőség** — ami nélkül az új feature-ök nehézkesek vagy veszélyesek
3. **Tisztítás** — tech debt, ami nem blokkoló, de rontja a kód olvashatóságát

---

## 1. Adatvesztés-kockázat (BLOKKOLÓ)

Forrás: `codable-audit.md`, `storage-audit.md`, `lifecycle-audit.md`

| ID | Finding | Érintett fájl | Státusz |
|---|---|---|---|
| RF-1 | `Snippet` + `NamedDeadline` synthesized Codable — új mező = adatvesztés | `Snippet.swift`, `NamedDeadline.swift` | ⬜ |
| RF-2 | `UserDefaults.synchronize()` hiánya — force-quit kockázat | `countdownAppApp.swift` | ⬜ |
| RF-3 | `SnippetEditSheet` — nincs `.onChange(of: snippetBody)`, csak X-dismiss ment | `SnippetEditSheet.swift` | ⬜ |

---

## 2. Fejleszthetőség

Forrás: `storage-audit.md`, `duplication-audit.md`, `notificationcenter-audit.md`

| ID | Finding | Érintett fájl | Státusz |
|---|---|---|---|
| RF-4 | `enum AppKeys` hiánya — UserDefaults kulcsok szétszórva | több fájl | ⬜ |
| RF-5 | `componentStepper` 3× duplikált | `CalculateView`, `CountdownDetailView`, `AddCountdownSheet` | ⬜ |
| RF-6 | `NotificationCenter` observer leak — `FocusedNSTextField.Coordinator` | `SharedEditorComponents.swift` | ⬜ |
| RF-7 | `monthAbbrev()` + `DateFormatter` ad-hoc — 3-6× duplikált | több fájl | ⬜ |

---

## 3. Tisztítás

Forrás: `theme-audit.md`, `freecolors-audit.md`, `font-audit.md`, `magic-numbers-audit.md`

| ID | Finding | Érintett fájl | Státusz |
|---|---|---|---|
| RF-8 | `freeColors` pozíció-indexelt paletta → névvel ellátott tokenek | `AppTheme.swift` | ⬜ |
| RF-9 | `Color.white.opacity(X)` — 16 különböző érték, nincs token | `AppTheme.swift` + több | ⬜ |
| RF-10 | Magic numbers — padding, cornerRadius, font size szétszórva | több fájl | ⬜ |

---

## Tervezési kérdések (következő sessionban döntendő)

- RF-1: `decodeIfPresent` retrofit elég, vagy érdemes `@Model` (SwiftData) irányba gondolkodni?
- RF-4: `enum AppKeys` bevezetése — hol lakjon? `CountdownItem.swift`? Külön fájl?
- RF-5: `componentStepper` kiszervezése — `AppTheme` extension vagy önálló view?
- RF-8/9: color token refaktor hatóköre — csak Swift, vagy CSS-szinkron is egyszerre?
