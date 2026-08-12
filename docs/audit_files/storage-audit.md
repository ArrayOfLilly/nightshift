# countdownApp Storage Persistence Architecture Audit

## 1. @AppStorage Usages vs. Manual UserDefaults Paths

### 1.1 @AppStorage (SwiftUI Property Wrapper) — Declarative Binding

| File | Line(s) | Key String | Type | Default Value |
|------|---------|------------|------|---------------|
| CalculateView.swift | 29 | `"calculateFromDate"` | `Double` | `Date().timeIntervalSince1970` |
| CalculateView.swift | 30 | `"calculateToDate"` | `Double` | `Date().timeIntervalSince1970` |
| CalculateView.swift | 31 | `"calculateDisplayMode"` | `String` | `"days"` |
| SunTimesService.swift | 20 | `"sunLatitude"` | `Double` | `47.4979` |
| SunTimesService.swift | 21 | `"sunLongitude"` | `Double` | `19.0402` |

### 1.2 Manual UserDefaults — Imperative Read/Write

| File | Lines (R/W) | Key String | Value Type | Encoding |
|------|-------------|------------|------------|----------|
| CalculateView.swift | 680 / 688 | `"namedDeadlines"` (inline literal) | `[NamedDeadline]` | JSON Data |
| CountdownView.swift | 274–276 / 269 | `"countdownItems"` (`private let storageKey`) | `[CountdownItem]` | JSON Data |
| CountdownView.swift | 286–288 / 282 | `"freeSlotOrder"` (`private let freeOrderKey`) | `[String]` (UUID strings) | String Array |
| Snippet.swift | 28–31 / 49 | `"snippets"` (`static let storageKey`) | `[Snippet]` | JSON Data |
| SunTimesService.swift | 99 / 109 | `"sunTimesCache_\(<year>)"` (computed via `cacheKey(forYear:)`, line 95) | `SunTimesYearResponse` raw JSON bytes | Raw Data |


### 1.3 Consistency Analysis — Findings

**INCONSISTENCY #1 — Storage mechanism split on feature boundaries, not data type.**
`@AppStorage` is used for simple scalar prefs (`Double`, `String`) while manual
`UserDefaults.standard.data(forKey:)` + `JSONEncoder/Decoder` is used for complex collections.
However, `CalculateView` itself uses BOTH:
- Lines 29–31: `@AppStorage("calculateFrom...")` for scalar date intervals and display mode.
- Lines 680, 688: manual `UserDefaults.standard.data(forKey: "namedDeadlines")` for the `[NamedDeadline]` array.

This is technically reasonable (complex structs require codable round-trip), but it means **persisted state
for one logical screen (CalculateView) lives under two different access patterns**, making refactoring error-prone.

**INCONSISTENCY #2 — Key declaration style differs per file.**

| File | Declaration Style | Constant Visibility |
|------|-------------------|---------------------|
| CalculateView.swift | Inline literal strings at call sites (`"namedDeadlines"` at lines 680, 688) | NONE — keys are bare literals |
| CountdownView.swift | `private let storageKey = "countdownItems"` and `private let freeOrderKey = "freeSlotOrder"` (instance properties) | Instance-scoped `let` — not reusable across the file hierarchy |
| Snippet.swift | `static let storageKey = "snippets"` (type-level `static let`) | Type-scoped — can be referenced as `Snippet.storageKey` externally |
| SunTimesService.swift | Computed via private method `cacheKey(forYear:)` returning `"sunTimesCache_\(<year>)"` | Encapsulated in function — not a constant at all |

No single centralized key registry (e.g., an enum or `UserDefaults.Keys` typealias pattern) exists.

**INCONSISTENCY #3 — Error handling is non-uniform.**
- `CountdownView.load()` (line 274): `try? JSONDecoder().decode(...) ... else { return }`. On decode failure, silently returns leaving `items` at `[]`.
- `CalculateView.loadDeadlines()` (line 680): Same pattern — `else { return }`, leaves `namedDeadlines` at `[]`.
- `Snippet.load()` (line 28): Same pattern — returns `[]` on failure but **adds a post-load whitespace scrub** (lines 33–43) and conditionally re-persists. This is the only load path that mutates stored data during read.
- `SunTimesService.loadFromCache(year:)` (line 99): Same silent-fail pattern — returns `nil` on decode failure, triggers network fetch as fallback.

There are no crash logs, printed warnings, or user-visible error states for deserialization failures in any
path except SunTimesService (which at least retries from network). All JSON data is lost silently if corruption occurs.


---

## 2. Hardcoded Key Strings That Should Be Static Constants

### 2.1 Inline Literal Strings (No Constant Binding)

| File | Line(s) | Literal String | Context | Risk |
|------|---------|----------------|---------|------|
| CalculateView.swift | 680 | `"namedDeadlines"` | `UserDefaults.standard.data(forKey: "namedDeadlines")` | Typo risk, no compile-time safety, cannot be grep-refactored without missing this site |
| CalculateView.swift | 688 | `"namedDeadlines"` | `UserDefaults.standard.set(data, forKey: "namedDeadlines")` | Duplicate of above — if refactored in one place but not the other, data is orphaned |

**Both occurrences of `"namedDeadlines"` are bare string literals with no constant. `NamedDeadline` struct
itself carries NO storage key association — it should declare a `static let storageKey` as `Snippet` does.**

### 2.2 Instance-Scoped Constants (Repetitive, Not Centralized)

| File | Line | Declaration | Issue |
|------|------|-------------|-------|
| CountdownView.swift | ~69 | `private let storageKey = "countdownItems"` | Instance property — each `CountdownView` instance allocates its own `String`. Cannot be referenced by helper functions or test code outside the view. |
| CountdownView.swift | ~70 | `private let freeOrderKey = "freeSlotOrder"` | Same — should be a type-level (`static let`) or global constant. This key stores `[UUID]` as UUID strings but no documentation connects `"freeSlotOrder"` to its purpose in the codebase. |

### 2.3 Computed Dynamic Keys (Acceptable Pattern But Unlogged)

| File | Line(s) | Key Formula | Observation |
|------|---------|-------------|-------------|
| SunTimesService.swift | 95 | `"sunTimesCache_\(<year>)"` | Dynamic per-year key is architecturally correct. However, there is **no eviction or versioning logic** — caches for years the user will never revisit accumulate indefinitely in UserDefaults with no size cap. A future update that changes `SunTimes` struct shape could corrupt all cached years simultaneously. |

### 2.4 @AppStorage Keys — Always Inline Literals (Acceptable)

| File | Line | Key | Remark |
|------|------|-----|--------|
| CalculateView.swift | 29 | `"calculateFromDate"` | Inline in `@AppStorage(...)` — only place such a key can live; no other file references this key. Acceptable. |
| CalculateView.swift | 30 | `"calculateToDate"` | Same. |
| CalculateView.swift | 31 | `"calculateDisplayMode"` | Note: String enum-like value (`"days"` / `"cal"`) has no validation — a bug writing `"dayz"` would silently break toggle logic on line ~258. |
| SunTimesService.swift | 20 | `"sunLatitude"` | Inline in `@AppStorage(...)`. Acceptable. |
| SunTimesService.swift | 21 | `"sunLongitude"` | Inline in `@AppStorage(...)`. Acceptable. |

**Recommendation:** Extract all manual-UserDefaults keys into a single namespace:
```swift
enum AppKeys {
    static let countdownItems  = "countdownItems"
    static let freeSlotOrder   = "freeSlotOrder"
    static let namedDeadlines  = "namedDeadlines"
    // Snippet.storageKey is already correct as-is
}
```


---

## 3. Missing Data Migration and Fallback Handling for Breaking Model Changes

### 3.1 Model Schema History (Inferred from Coding Patterns)

| Model | Fields Present Now | Backward-Compatible Decoding? | Mechanism |
|-------|--------------------|-------------------------------|-----------|
| `CountdownItem` | `id`, `label`, `deadline`, `showRemaining`, `accentColorIndex`, `soundEnabled`, `notes` | ✅ YES | Custom `init(from decoder:)` at lines 48–61 uses `decodeIfPresent(...)` for all optional/default fields. Explicit comment at line 50 explains this. |
| `Snippet` | `id`, `title`, `body`, `project`, `createdAt`, `updatedAt` | ❌ NO | Uses Swift-synthesized `Codable`. Any new field added without a default value will cause `decode` to throw — `Snippet.load()` wraps in `try?`, entire array returns `[]`. All snippets lost on breaking change. |
| `NamedDeadline` | `id`, `title`, `date`, `createdAt` | ❌ NO | Uses Swift-synthesized `Codable`. Same failure mode as `Snippet`. No custom `init(from:)`. If a field is added or renamed, decode throws → `loadDeadlines()` returns → `namedDeadlines` stays at `[]`. All deadlines lost. |
| `SunTimes` (cached) | 17 fields (see SunTimes.swift) | ⚠️ PARTIAL | Custom `init(from:)` via factory method `.build(from: RawDay)` with guard-chain. If any required field fails to parse, that day's record returns nil but year cache is still a partial `[SunTimes]` array. Raw response JSON has no versioning. |

### 3.2 Specific Breaking-Change Risk Scenarios

**RISK A — `Snippet` model evolution.**

`createdAt` and `updatedAt` have defaults but NO `decodeIfPresent` logic. If the JSON lacks these keys
(from a pre-date-tracking version), synthesized `Decodable` calls `try c.decode(Date.self, forKey: .createdAt)`
which throws `.keyNotFound`. Result: all snippets vanish.

Fix: Add custom `init(from decoder:)` mirroring `CountdownItem`, or ensure every field has both a default
AND is decoded with `decodeIfPresent`.

**RISK B — `NamedDeadline` model evolution.**

Same issue. `createdAt` has default but no `decodeIfPresent`. Any addition of a required field
(e.g., `var tags: [String] = []`) will break deserialization entirely. All named deadlines vanish.

**RISK C — Cache stampede on API schema change (SunTimes).**

When the app first runs in a new year, `loadFromCache(year:)` returns nil (no cache), triggering a
network fetch. If an old cached year's JSON no longer matches the updated `SunTimes`/`RawDay` struct
(e.g., API removes "last_light" field), that year's entire cache silently "poisons" returning zero days —
then `fetchYear(year)` overwrites it. Recovery is self-healing but involves an unnecessary network round-trip
for every cached year on the next launch after an update.

**RISK D — `freeSlotOrder` UUID garbage accumulation.**

`loadFreeOrder()` (CountdownView.swift line 286) does filter against current items:
`filter { validIDs.contains($0) }`. This is correct — orphaned UUIDs referencing deleted items are trimmed
on load. ✅ No issue here.

**RISK E — UserDefaults key collision across app versions or sandbox scope.**

No bundle-prefixed keys (e.g., `"com.developer.countdownApp.snippets"`). If the developer repurposes any
of these key strings for a different app sharing the same suite/sandbox, or if macOS deduplicates across
apps in certain configurations, data corruption is possible. Low probability but present.

### 3.3 No Versioned Schema, No Migration Runner

There is no:
- UserDefaults version field (e.g., `"dataVersion"` stored alongside each model)
- Conditional migration logic that checks the version before decoding and transforms old-format data
- Pre-decode validation of JSON structure before attempting full decode
- Any try-catch fallback that partially recovers items instead of returning an empty array on the first failure

`CountdownItem` is the only model with defensive decoding. It is also the model with the most fields and
the highest blast radius if data were lost. The fact that it alone has migration-safe decoding while
`Snippet` and `NamedDeadline` do not is **inconsistent** and should be corrected before any new field
is added to either model.

