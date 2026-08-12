# Codable Correctness & Data Loss Audit — countdownApp

---

## File: `Snippet.swift`

### S-1: No CodingKeys enum declared *(file-level)*

**Location:** `Snippet.swift`, struct definition ~line 17  
**Properties:** `id`, `title`, `body`, `project`, `createdAt`, `updatedAt`

The struct relies entirely on synthesized `Codable`. No custom `CodingKeys` or `init(from decoder:)` exists. A JSON key missing from any position in the array causes the entire `[Snippet]` decode to throw and return `nil` → `try?` → `return []`.

---

### S-2: All properties decoded via synthesized mechanism — no `decodeIfPresent` + default *(file-level)*

**Location:** `Snippet.swift`, implicit in the absence of custom `init(from:)`  
**Properties affected:** All six (`id`, `title`, `body`, `project`, `createdAt`, `updatedAt`)

Swift's synthesized `Decodable.init(from:)` uses only direct keyed containment. Fields without a default value (`title`, `body`, `project`) demand the key be present; if absent, `keyNotFound` is thrown and the entire snippet array is lost. Even fields with defaults (`id`, `createdAt`, `updatedAt`) throw instead of falling back to their Swift default when the key is missing in JSON from an older build.

---

### S-3: Semantically unsafe default for `createdAt`

**Location:** `Snippet.swift`, line 19

```swift
var createdAt: Date = Date()
```

The default is evaluated at *instance creation time*, not deserialization time. During a JSON load, if the `createdAt` key is missing, the synthesized decoder does not use this default — it throws `keyNotFound`. Any stored JSON written by a hypothetical older build without `createdAt` silently fails the entire array load (see S-5).

---

### S-4: Semantically unsafe default for `updatedAt`

**Location:** `Snippet.swift`, line 20

```swift
var updatedAt: Date = Date()
```

Same as S-3. Missing key → decode fails for entire array, no graceful fallback to current time. The default only fires during in-memory construction (`Snippet()`), never during JSON deserialization.

---

### S-5: Silent data loss — `try?` swallows ALL decode failures *(Critical)*

**Location:** `Snippet.swift`, line 38

```swift
let list = try? JSONDecoder().decode([Snippet].self, from: data)
else { return [] }
```

Any single malformed snippet, missing key among non-optional fields, or any deserialization error causes the entire `[Snippet]` decode to throw. The `try?` converts that to `nil` → guard fails → empty array returned. All previously saved snippets are **silently and permanently wiped**. No recovery path, no partial decoding, no logging, no user-visible error.

---

### S-6: Silent write failure — `try?` swallows encode errors

**Location:** `Snippet.swift`, line 52

```swift
guard let data = try? JSONEncoder().encode(snippets) else { return }
```

Encode failures silently discard the entire save operation. No logging, no user feedback. The `@State` variable in the view retains the "new" data in memory while UserDefaults still holds stale data.

---

### S-7: `updatedAt` NOT mutated on project rename

**Location:** `SnippetsView.swift`, lines 183–191

```swift
private func renameProject(from old: String, to new: String) {
    let trimmed = new.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty, trimmed != old else { return }
    snippets = snippets.map { s in
        guard s.project == old else { return s }
        var updated = s
        updated.project = trimmed
        return updated
    }
    Snippet.save(snippets)
}
```

Every affected snippet's `project` field is mutated but `updatedAt` is never touched. After rename, all affected snippets retain their original pre-rename timestamp. The edit sheet correctly mutates `updatedAt` (`SnippetEditSheet.swift` line 288), but the rename path is a blind spot.

---

### S-8: `updatedAt` mutation coverage across all write paths

| Line(s)   | Operation                        | `updatedAt` Mutated?                              |
|-----------|----------------------------------|---------------------------------------------------|
| 67–72     | New snippet via Sheet → `onSave` | ✅ Yes (handled by `SnippetEditSheet` line 288)   |
| 76–82     | Edit existing via Sheet → `onSave`| ✅ Yes (`SnippetEditSheet` line 288)              |
| 84–86     | Delete single snippet            | N/A (item removed, not mutated)                   |
| 183–191   | Rename project (batch map)       | ❌ No — see S-7                                   |
| 193–195   | Delete project (filter-remove)   | N/A (items removed)                               |

The rename path is the only mutation-without-timestamp-update.

---

## File: `NamedDeadline.swift`

### ND-1: No CodingKeys enum declared *(file-level)*

**Location:** `NamedDeadline.swift`, struct definition ~line 16  
**Properties:** `id`, `title`, `date`, `createdAt`

Fully synthesized `Codable`. Same exposure as `Snippet` — any missing key on any field throws and wipes the entire array.

---

### ND-2: No `decodeIfPresent` + default for defaulted properties *(file-level)*

**Location:** `NamedDeadline.swift`, file-level  
**Properties affected:** `id` (line 17, default `UUID()`), `createdAt` (line 20, default `Date()`)

When loading JSON written by a build that predates these fields, the synthesized decoder demands keys be present and throws. Missing key → decode fails for entire array.

---

### ND-3: Semantically unsafe default for `createdAt`

**Location:** `NamedDeadline.swift`, line 20

```swift
var createdAt: Date = Date()
```

Same as S-3/S-4. Swift's synthesized `Decodable` ignores property defaults — they only fire during direct struct construction, not JSON decode. A missing key throws instead of falling back to the default timestamp.

---

### ND-4: Silent data loss on load *(Critical)*

**Location:** `CalculateView.swift` (inferred — storage key `"namedDeadlines"`)

```swift
guard let data = UserDefaults.standard.data(forKey: "namedDeadlines"),
      let list = try? JSONDecoder().decode([NamedDeadline].self, from: data)
else { return [] }
```

`try?` silently converts any decode failure → `nil` → empty array. All named deadlines wiped on schema mismatch, with no recovery.

---

## File: `CountdownItem.swift`

### CI-1: `id` decoded with `decode()` instead of `decodeIfPresent` + default

**Location:** `CountdownItem.swift`, line 73

```swift
id = try c.decode(UUID.self, forKey: .id)
```

`id` has a default value (`UUID()`), but `decode()` is used. If an older JSON image lacks the `id` key, this throws `keyNotFound` and the entire items array fails to load.

---

### CI-1b: `label` — direct `decode()` (correct but fragile)

**Location:** `CountdownItem.swift`, line 74

```swift
label = try c.decode(String.self, forKey: .label)
```

Non-optional `String` with no default — direct decode is structurally correct for a required field. However, any malformed label still kills the entire array; there is no per-item error recovery.

---

### CI-1c: `deadline` — direct `decode()` (correct, low severity)

**Location:** `CountdownItem.swift`, line 75

```swift
deadline = try c.decode(Date.self, forKey: .deadline)
```

Non-optional `Date`, direct decode is semantically fine — a countdown without a deadline is meaningless. Fragile to schema drift but likely intentional.

---

### CI-2: `accentColorIndex` — `decodeIfPresent` uses `Int.self` instead of `Int?.self`

**Location:** `CountdownItem.swift`, line 76

```swift
accentColorIndex = try c.decodeIfPresent(Int.self, forKey: .accentColorIndex) ?? nil
```

Functionally correct for the absent-key case, but if the key exists with a non-`Int` value, `decodeIfPresent` still throws (type mismatch). Using `Int?.self` would handle both absent and present-as-null gracefully. Minor, but worth fixing for completeness.

---

## Summary

| ID     | File                  | Line(s)   | Property          | Category                                        | Severity                             |
|--------|-----------------------|-----------|-------------------|-------------------------------------------------|--------------------------------------|
| CI-1a  | `CountdownItem.swift` | 73        | `id`              | `decode()` instead of `decodeIfPresent` + default | **High** — array wipe on schema drift |
| CI-1b  | `CountdownItem.swift` | 74        | `label`           | `decode()` correct for required field, still throws | Medium                             |
| CI-1c  | `CountdownItem.swift` | 75        | `deadline`        | `decode()` correct for required field            | Low                                  |
| CI-2   | `CountdownItem.swift` | 76        | `accentColorIndex`| `Int.self` instead of `Int?.self` in `decodeIfPresent` | Low                           |
| S-1    | `Snippet.swift`       | file-level| All properties    | No `CodingKeys`, no custom `init`               | **High** — zero backward compat      |
| S-2    | `Snippet.swift`       | file-level| All properties    | No `decodeIfPresent` + default                  | **High**                             |
| S-3    | `Snippet.swift`       | 19        | `createdAt`       | Default not used by synthesized `Decodable`     | **High** — missing key = array wipe  |
| S-4    | `Snippet.swift`       | 20        | `updatedAt`       | Default not used by synthesized `Decodable`     | **High**                             |
| S-5    | `Snippet.swift`       | 38        | (round-trip)      | `try?` → silent `[]` on ANY failure             | **Critical** — permanent data loss   |
| S-6    | `Snippet.swift`       | 52        | (write path)      | `try?` encode silently swallowed                | Medium — memory/UserDefaults desync  |
| ND-1   | `NamedDeadline.swift` | file-level| All properties    | No `CodingKeys`, no custom `init`               | **High**                             |
| ND-2   | `NamedDeadline.swift` | file-level| `id`, `createdAt` | No `decodeIfPresent` + default                  | **High** — missing key = array wipe  |
| ND-3   | `NamedDeadline.swift` | 20        | `createdAt`       | Default not used by synthesized `Decodable`     | **High**                             |
| ND-4   | UserDefaults (inferred)| N/A      | (round-trip)      | `try?` decode swallows all errors → `[]`        | **Critical** — silent data loss      |
| S-7    | `SnippetsView.swift`  | 186–190   | `updatedAt`       | Not mutated during project rename               | Medium — timestamp drift             |
| S-8    | `SnippetsView.swift`  | 183–191   | (batch ops)       | Only rename path lacks `updatedAt` update       | Low                                  |

---

## File: `CountdownView.swift`

### CV-1: Silent data loss on load — `try?` swallows all decode failures *(Critical)*

**Location:** `CountdownView.swift`, `load()`

```swift
private func load() {
    guard
        let data    = UserDefaults.standard.data(forKey: storageKey),
        let decoded = try? JSONDecoder().decode([CountdownItem].self, from: data)
    else { return }
    items = decoded
}
```

This is the primary item list — the entire countdown collection. Any decode failure (schema drift, malformed JSON, missing key on a required field such as `id`, `label`, or `deadline` — see CI-1) silently returns early, leaving `items = []`. The user's entire countdown list disappears with no error, no log, no recovery path. Highest-severity instance of the `try?` pattern in the codebase.

---

### CV-2: Silent write failure — `try?` encode swallowed

**Location:** `CountdownView.swift`, `save()`

```swift
private func save() {
    guard let data = try? JSONEncoder().encode(items) else { return }
    UserDefaults.standard.set(data, forKey: storageKey)
}
```

Same pattern as S-6. Encode failure silently drops the save; the `@State items` array is correct in memory but UserDefaults holds stale data. Triggered on every `onChange(of: items)` — a failed encode means *every subsequent app launch* loads the last successfully-written (older) state.

---

### CV-3: `freeOrder` UUID strings — silent discard on malformed entries

**Location:** `CountdownView.swift`, `loadFreeOrder()`

```swift
freeOrder = strings.compactMap { UUID(uuidString: $0) }.filter { validIDs.contains($0) }
```

`compactMap` silently drops any string that fails `UUID(uuidString:)`. This is defensively correct (corrupt entries are filtered out rather than crashing), but there is no logging. If the stored order becomes partially corrupted, the ordering silently resets to the default sort — no indication to the user. Low severity, but worth noting alongside the other silent-discard patterns.

---

## File: `CalculateView.swift`

### CA-1: Silent data loss on load — `try?` on `[NamedDeadline]` *(Critical)*

**Location:** `CalculateView.swift`, `loadDeadlines()`

```swift
private func loadDeadlines() {
    guard let data    = UserDefaults.standard.data(forKey: "namedDeadlines"),
          let decoded = try? JSONDecoder().decode([NamedDeadline].self, from: data)
    else { return }
    namedDeadlines = decoded
}
```

`NamedDeadline` has no custom `init(from:)` (see ND-1–ND-3). Any missing key (`id`, `createdAt`) on any element throws, and `try?` converts it to `nil` → `namedDeadlines` stays `[]`. All saved deadlines are silently lost. This is the same exposure as ND-4, confirmed in the call site.

---

### CA-2: Silent write failure — `try?` encode swallowed

**Location:** `CalculateView.swift`, `saveDeadlines()`

```swift
private func saveDeadlines() {
    if let data = try? JSONEncoder().encode(namedDeadlines) {
        UserDefaults.standard.set(data, forKey: "namedDeadlines")
    }
}
```

Same as S-6 / CV-2. Encode failure is silently ignored.

---

## Updated Summary

| ID    | File                   | Line(s)    | Property          | Category                                              | Severity                              |
|-------|------------------------|------------|-------------------|-------------------------------------------------------|---------------------------------------|
| CI-1a | `CountdownItem.swift`  | 73         | `id`              | `decode()` instead of `decodeIfPresent` + default    | **High** — array wipe on schema drift |
| CI-1b | `CountdownItem.swift`  | 74         | `label`           | `decode()` correct for required field, still throws  | Medium                                |
| CI-1c | `CountdownItem.swift`  | 75         | `deadline`        | `decode()` correct for required field                | Low                                   |
| CI-2  | `CountdownItem.swift`  | 76         | `accentColorIndex`| `Int.self` instead of `Int?.self` in `decodeIfPresent`| Low                                  |
| S-1   | `Snippet.swift`        | file-level | All properties    | No `CodingKeys`, no custom `init`                    | **High** — zero backward compat       |
| S-2   | `Snippet.swift`        | file-level | All properties    | No `decodeIfPresent` + default                       | **High**                              |
| S-3   | `Snippet.swift`        | 19         | `createdAt`       | Default not used by synthesized `Decodable`          | **High** — missing key = array wipe   |
| S-4   | `Snippet.swift`        | 20         | `updatedAt`       | Default not used by synthesized `Decodable`          | **High**                              |
| S-5   | `Snippet.swift`        | 38         | (round-trip)      | `try?` → silent `[]` on ANY failure                  | **Critical** — permanent data loss    |
| S-6   | `Snippet.swift`        | 52         | (write path)      | `try?` encode silently swallowed                     | Medium — memory/UserDefaults desync   |
| ND-1  | `NamedDeadline.swift`  | file-level | All properties    | No `CodingKeys`, no custom `init`                    | **High**                              |
| ND-2  | `NamedDeadline.swift`  | file-level | `id`, `createdAt` | No `decodeIfPresent` + default                       | **High** — missing key = array wipe   |
| ND-3  | `NamedDeadline.swift`  | 20         | `createdAt`       | Default not used by synthesized `Decodable`          | **High**                              |
| ND-4  | UserDefaults (inferred)| N/A        | (round-trip)      | `try?` decode swallows all errors → `[]`             | **Critical** — silent data loss       |
| S-7   | `SnippetsView.swift`   | 186–190    | `updatedAt`       | Not mutated during project rename                    | Medium — timestamp drift              |
| S-8   | `SnippetsView.swift`   | 183–191    | (batch ops)       | Only rename path lacks `updatedAt` update            | Low                                   |
| CV-1  | `CountdownView.swift`  | `load()`   | `items`           | `try?` decode → silent `[]`; primary item list       | **Critical** — entire list wiped      |
| CV-2  | `CountdownView.swift`  | `save()`   | `items`           | `try?` encode silently swallowed                     | Medium — memory/UserDefaults desync   |
| CV-3  | `CountdownView.swift`  | `loadFreeOrder()` | `freeOrder` | `compactMap` silently discards malformed UUIDs  | Low — ordering resets silently        |
| CA-1  | `CalculateView.swift`  | `loadDeadlines()` | `namedDeadlines` | `try?` on `[NamedDeadline]` → silent `[]`  | **Critical** — all deadlines lost     |
| CA-2  | `CalculateView.swift`  | `saveDeadlines()` | `namedDeadlines` | `try?` encode silently swallowed           | Medium — memory/UserDefaults desync   |

---

## File: `SunTimes.swift` / `SunTimesService.swift`

### ST-1: `SunTimesYearResponse.init(from:)` — silent day-drop via `compactMap`

**Location:** `SunTimes.swift`, `SunTimesYearResponse.init(from:)`

```swift
init(from decoder: Decoder) throws {
    let raw = try RawResults(from: decoder)
    self.results = raw.results.compactMap { SunTimes.build(from: $0) }
    self.status = raw.status
}
```

`SunTimes.build(from:)` returns `nil` if any required field fails to parse. `compactMap` silently drops those days. A year response with one malformed day silently returns 364 days instead of 365 — no error surfaced, no count check, no log. For network API data this is defensively reasonable, but the caller has no way to distinguish "API returned 364 days" from "364 days parsed correctly". Severity: **Low** — fallback is a network re-fetch, not permanent data loss.

---

### ST-2: `SunTimesService.loadFromCache()` — `try?` on a custom `Decodable`

**Location:** `SunTimesService.swift`, `loadFromCache(year:)`

```swift
guard let response = try? JSONDecoder().decode(SunTimesYearResponse.self, from: data) else {
    return nil
}
```

If the cache entry fails to decode (e.g. `SunTimes` struct gains a new non-optional field in a later build), `try?` returns `nil` → `loadYear()` falls back to a network fetch. Unlike S-5/CV-1, data loss here is **not permanent** — the stale cache is simply bypassed and overwritten on the next successful fetch. Severity: **Low** — intentional fallback pattern for a cache.

---

### ST-3: `SunTimes` uses synthesized `Codable` for cache roundtrip

**Location:** `SunTimes.swift`, struct declaration

```swift
struct SunTimes: Codable, Equatable { … }
```

`SunTimes` has no `CodingKeys` enum and no custom `init(from:)`. All fields are non-optional with no defaults. Adding any new property to the struct without a migration strategy will break all existing cache entries on the next build — the synthesized decoder demands every key, and `try?` in `loadFromCache()` converts the failure to a silent cache miss and a network re-fetch. This is functionally acceptable (cache miss → fetch) but worth knowing: **every `SunTimes` struct change silently invalidates all cached data on first launch after update**. Severity: **Low** — the behaviour is recoverable.

---

## No Codable issues found in

| File | Reason |
|---|---|
| `ContentView.swift` | No persistence; `selectedMode` is ephemeral `@State` |
| `AppTheme.swift` | Pure constants and font helpers; no storage |
| `ColorPickerSheet.swift` | Receives `@Binding var selectedIndex: Int?`; persistence is the caller's responsibility |
| `CountdownRowView.swift` | Receives `@Binding var item: CountdownItem`; no own persistence |
| `LongPressStepperButton.swift` | Stateless gesture handler; no storage |
| `SunPanel.swift` | Pure view; receives `SunTimes?` by value |
| `countdownAppApp.swift` | App entry point; font registration only |
| `SharedEditorComponents.swift` | WKWebView rendering helper; no storage |

---

## Final Summary (all files)

| ID    | File                    | Line(s)           | Property           | Category                                              | Severity                              |
|-------|-------------------------|-------------------|--------------------|-------------------------------------------------------|---------------------------------------|
| CI-1a | `CountdownItem.swift`   | 73                | `id`               | `decode()` instead of `decodeIfPresent` + default    | **High** — array wipe on schema drift |
| CI-1b | `CountdownItem.swift`   | 74                | `label`            | `decode()` correct for required field, still throws  | Medium                                |
| CI-1c | `CountdownItem.swift`   | 75                | `deadline`         | `decode()` correct for required field                | Low                                   |
| CI-2  | `CountdownItem.swift`   | 76                | `accentColorIndex` | `Int.self` instead of `Int?.self` in `decodeIfPresent`| Low                                  |
| S-1   | `Snippet.swift`         | file-level        | All properties     | No `CodingKeys`, no custom `init`                    | **High** — zero backward compat       |
| S-2   | `Snippet.swift`         | file-level        | All properties     | No `decodeIfPresent` + default                       | **High**                              |
| S-3   | `Snippet.swift`         | 19                | `createdAt`        | Default not used by synthesized `Decodable`          | **High** — missing key = array wipe   |
| S-4   | `Snippet.swift`         | 20                | `updatedAt`        | Default not used by synthesized `Decodable`          | **High**                              |
| S-5   | `Snippet.swift`         | 38                | (round-trip)       | `try?` → silent `[]` on ANY failure                  | **Critical** — permanent data loss    |
| S-6   | `Snippet.swift`         | 52                | (write path)       | `try?` encode silently swallowed                     | Medium — memory/UserDefaults desync   |
| ND-1  | `NamedDeadline.swift`   | file-level        | All properties     | No `CodingKeys`, no custom `init`                    | **High**                              |
| ND-2  | `NamedDeadline.swift`   | file-level        | `id`, `createdAt`  | No `decodeIfPresent` + default                       | **High** — missing key = array wipe   |
| ND-3  | `NamedDeadline.swift`   | 20                | `createdAt`        | Default not used by synthesized `Decodable`          | **High**                              |
| ND-4  | UserDefaults (inferred) | N/A               | (round-trip)       | `try?` decode swallows all errors → `[]`             | **Critical** — silent data loss       |
| S-7   | `SnippetsView.swift`    | 186–190           | `updatedAt`        | Not mutated during project rename                    | Medium — timestamp drift              |
| S-8   | `SnippetsView.swift`    | 183–191           | (batch ops)        | Only rename path lacks `updatedAt` update            | Low                                   |
| CV-1  | `CountdownView.swift`   | `load()`          | `items`            | `try?` decode → silent `[]`; primary item list       | **Critical** — entire list wiped      |
| CV-2  | `CountdownView.swift`   | `save()`          | `items`            | `try?` encode silently swallowed                     | Medium — memory/UserDefaults desync   |
| CV-3  | `CountdownView.swift`   | `loadFreeOrder()` | `freeOrder`        | `compactMap` silently discards malformed UUIDs       | Low — ordering resets silently        |
| CA-1  | `CalculateView.swift`   | `loadDeadlines()` | `namedDeadlines`   | `try?` on `[NamedDeadline]` → silent `[]`            | **Critical** — all deadlines lost     |
| CA-2  | `CalculateView.swift`   | `saveDeadlines()` | `namedDeadlines`   | `try?` encode silently swallowed                     | Medium — memory/UserDefaults desync   |
| ST-1  | `SunTimes.swift`        | `init(from:)`     | `results`          | `compactMap` silently drops malformed days           | Low — recoverable, API data           |
| ST-2  | `SunTimesService.swift` | `loadFromCache()` | year cache         | `try?` decode; fallback is network re-fetch          | Low — intentional cache pattern       |
| ST-3  | `SunTimes.swift`        | file-level        | All fields         | Synthesized `Codable`; any struct change busts cache | Low — recoverable                     |

---

## Post-fix note — BUG-1: Saved Deadlines remaining time (CalculateView.swift)

`deadlineRemainingString(for:)` and the popover row UI change do not touch any Codable logic.
No new fields added to `NamedDeadline`, no new encode/decode paths, struct unchanged.

**New Codable findings from this fix: none.**


---

## Post-fix note — Session P: Deadline Rename + Popover Width (CalculateView.swift)

### New state vars — no Codable impact

`isRenamingDeadline: Bool` and `renameDraft: String` are pure `@State` UI helpers.
They are never encoded or decoded. No new Codable exposure.

### Rename write path — CA-2 still applies

The rename action:
```swift
namedDeadlines[idx].title = trimmed
saveDeadlines()
```
calls the existing `saveDeadlines()` which uses `try? JSONEncoder().encode(namedDeadlines)` (CA-2).
A silent encode failure during rename silently drops the title change — UserDefaults retains the
old title while in-memory state has the new one. Severity unchanged: **Medium**.

### `NamedDeadline` — no `updatedAt` field

Unlike `Snippet` (which has both `createdAt` and `updatedAt`), `NamedDeadline` tracks only
`createdAt`. The rename operation updates no timestamp. This is not a Codable issue today,
but if `updatedAt: Date = Date()` is added to `NamedDeadline` in the future without a
corresponding `decodeIfPresent` + default, all existing stored entries will fail to decode
(same exposure as ND-2). Pre-emptive fix: add `updatedAt` now with proper `CodingKeys` +
`init(from:)` treatment, consistent with the ND-1 remediation plan.

**New Codable findings from Session P: none.**


---

## Post-fix note — Session P (cont.): X dismiss + dynamic popover width (CalculateView.swift)

`popoverWidth: CGFloat` is a pure `@State` UI helper, never encoded or decoded.
The X dismiss button sets `selectedDeadline = nil` — no persistence side-effects.
The `.onAppear` width calculation reads `NSApp.mainWindow?.frame.width` — no storage involved.

**New Codable findings: none.**
