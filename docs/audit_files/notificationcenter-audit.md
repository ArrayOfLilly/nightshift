# Audit 10: NotificationCenter & Memory Leaks

**Scope:** `CountdownDetailView.swift`, `SharedEditorComponents.swift`

**Összefoglalás:** Egyetlen kritikus observer leak azonosítva a `FocusedNSTextField`
`Coordinator` osztályában (`CountdownDetailView.swift`). A másik két
`NSViewRepresentable` wrapper (`MarkdownWebView`, `PlainTextEditor`) tiszta.

---

## §1 — FocusedNSTextField: Kritikus Observer Leak

**Fájl:** `CountdownDetailView.swift`
**Típus:** `NSViewRepresentable` (privát struct, sor 44)

### NC-1 (Critical) — addObserver deinit nélkül

| Attribútum | Részlet |
|---|---|
| Fájl | `CountdownDetailView.swift` |
| Regisztráció | `makeNSView(context:)`, sorok 61–66 |
| Selector | `#selector(Coordinator.windowDidResignKey(_:))` |
| Notification | `NSWindow.didResignKeyNotification` |
| Object filter | `nil` — az app összes ablakának resign eseményét megkapja |
| Eltávolítás | **NINCS** — sem `deinit` a `Coordinator`-on, sem `removeObserver` sehol |
| Coordinator | `final class Coordinator: NSObject, NSTextFieldDelegate` (sor 87) |
| Lifecycle gap | `FocusedNSTextField` a `CountdownDetailView`-ban él, ami `.navigationDestination(for:)` via presentálódik. Minden navigation push új Coordinator-t hoz létre; minden pop deallocálni kellene — de az observer megakadályozza. |

Regisztrációs kód (sorok 61–66):

```swift
NotificationCenter.default.addObserver(
    context.coordinator,
    selector: #selector(Coordinator.windowDidResignKey(_:)),
    name: NSWindow.didResignKeyNotification,
    object: nil          // ← globális; minden ablak resign eseményét megkapja
)
```

Hiányzó cleanup:

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

### NC-2 (High) — Observation token nem tárolva

| Attribútum | Részlet |
|---|---|
| Fájl | `CountdownDetailView.swift` |
| Hely | Coordinator class, sor 87 |
| Használt pattern | Object-based `addObserver(_:selector:name:object:)` |
| Token | Nincs visszatérési érték, nincs `NSObjectProtocol` property |
| Hatás | Token-alapú `removeObserver` nem lehetséges; az egyetlen életképes cleanup út a `deinit`, ami hiányzik |


### NC-3 (Critical) — Coordinator végtelen életben tartása az observer cikluson keresztül

| Attribútum | Részlet |
|---|---|
| Fájl | `CountdownDetailView.swift` |
| Mechanizmus | `NotificationCenter` retainálja az observert explicit eltávolításig |
| Retainált állapot | Coordinator tárolja: `@Binding var text: String` (sor 90) + `var onCommit: () -> Void` (sor 91) |
| Binding forrás | `$item.label` a szülő viewból (`CountdownView` sor 82) |
| Hatás | Minden megnyitott-majd-bezárt detail view egy élő Coordinator-t hagy a heapen, escaped closure referenciával a szülő állapotába — törlés után is |

A callback ami zombie Coordinator-okon is tüzel (sorok 108–112):

```swift
@objc func windowDidResignKey(_ notification: Notification) {
    isEditing = false
    onCommit()   // ← zombie Coordinator-okon is fut, elavult @Binding-ra
}
```

Mivel `object: nil`, ez az app összes `NSWindow` resign eseményére tüzel — nem csak a
text field ablakára. Zombie Coordinator-ok minden AppKit fókuszváltáskor (ablakváltás,
sheet megnyitás, más app aktiválás) végrehajtják az `onCommit()`-ot elavult binding-ra.

### NC-4 (High) — Strong capture az escaped closure-ban

| Attribútum | Részlet |
|---|---|
| Fájl | `CountdownDetailView.swift` |
| Hely | `Coordinator.init`, sor 93 |
| Closure | `onCommit: @escaping () -> Void` |
| Hívási hely | Sorok 171–174 |

```swift
FocusedNSTextField(text: $item.label) {
    isEditing = false   // ← implicit strong capture a CountdownDetailView állapotára
}
```

A closure implicit strong capture-rel tartja életben a `CountdownDetailView` állapotát.
Ez a Coordinator `onCommit` non-weak property-jébe kerül (sor 91) — mivel a Coordinator
sosem deallocálódik (NC-3), ez a closure és implicit capture-je is leak.

---

## §2 — NSViewRepresentable wrapperek teljes leltára

| # | Típus | Fájl | Sor | addObserver? | removeObserver/deinit? | Leak kockázat |
|---|---|---|---|---|---|---|
| 1 | `FocusedNSTextField` | CountdownDetailView.swift | 44 | ✅ igen (sor 61) | ❌ **NINCS** | **KRITIKUS** |
| 2 | `MarkdownWebView` | SharedEditorComponents.swift | 21 | Nem | N/A | Nincs |
| 3 | `PlainTextEditor` | SharedEditorComponents.swift | 166 | Nem | N/A | Nincs |

### MarkdownWebView (SharedEditorComponents.swift:21) — Tiszta

- Coordinator (sor 42): `WKNavigationDelegate`, nincs NotificationCenter használat
- Delegate pattern (`wv.navigationDelegate = context.coordinator`) — auto-cleared a WKWebView
  deallocálásakor
- Height callback (`onHeightChange?`) opcionális, view dismiss természetesen megszakítja a
  referencia láncot

### PlainTextEditor (SharedEditorComponents.swift:166) — Tiszta

- Coordinator (sor 240): `NSTextViewDelegate`, nincs NotificationCenter használat
- NSTextView delegate assignment (sor 219) nil-eződik az NSScrollView/NSTextView deallocálásakor
- Nincs lifecycle probléma


---

## §3 — Javasolt fixek

### Fix NC-1/2/3 — deinit hozzáadása a Coordinator-hoz

**Fájl:** `CountdownDetailView.swift`
**Beillesztés:** sor 124 után (Coordinator class vége)

```swift
deinit {
    NotificationCenter.default.removeObserver(self)
}
```

### Fix NC-2 (alternatív, token-alapú megközelítés)

```swift
final class Coordinator: NSObject, NSTextFieldDelegate {
    // meglévő property-k ...
    private var observationToken: NSObjectProtocol?   // ÚJ
}

// makeNSView-ban:
context.coordinator.observationToken = NotificationCenter.default.addObserver(
    forName: NSWindow.didResignKeyNotification,
    object: nil,
    queue: .main
) { [weak coordinator] _ in
    guard let c = coordinator else { return }
    c.isEditing = false
    c.onCommit()
}

// Coordinator.deinit:
deinit {
    if let token = observationToken {
        NotificationCenter.default.removeObserver(token)
    }
}
```

### Fix NC-4 — weak capture az onCommit closure-ban

**Hívási hely:** `CountdownDetailView.swift`, sorok 171–174

```swift
// Volt:
FocusedNSTextField(text: $item.label) {
    isEditing = false
}

// Legyen:
FocusedNSTextField(text: $item.label) { [weak self] in
    self?.isEditing = false
}
```

Defense-in-depth: akkor is véd, ha az observer leak egyébként megmaradna.


---

## §4 — Saját kibővítés: teljes kódbázis scan

`NotificationCenter` előfordulás keresve mind a 20 Swift fájlban (Desktop Commander content search).

**Eredmény: egyetlen találat** — `CountdownDetailView.swift` sor 61. A többi 19 fájl nem tartalmaz `NotificationCenter` regisztrációt.

| Fájl | NotificationCenter? |
|---|---|
| `CountdownDetailView.swift` | ✅ igen — NC-1..4 (kritikus leak) |
| `SharedEditorComponents.swift` | Nem |
| `CountdownView.swift` | Nem |
| `CountdownItem.swift` | Nem |
| `CountdownRowView.swift` | Nem |
| `AppTheme.swift` | Nem |
| `CalculateView.swift` | Nem |
| `ColorPickerSheet.swift` | Nem |
| `AddCountdownSheet.swift` | Nem |
| `NotesSheet.swift` | Nem |
| `SnippetEditSheet.swift` | Nem |
| `SnippetsView.swift` | Nem |
| `Snippet.swift` | Nem |
| `NamedDeadline.swift` | Nem |
| `SunPanel.swift` | Nem |
| `SunTimes.swift` | Nem |
| `SunTimesService.swift` | Nem |
| `LongPressStepperButton.swift` | Nem |
| `ContentView.swift` | Nem |
| `countdownAppApp.swift` | Nem |

**Következtetés:** A NC-1..4 findingek izoláltak — a leak kizárólag a `FocusedNSTextField.Coordinator`-ban él. Nincs más fájlban observer regisztráció, amit figyelembe kellene venni a fix tervezésekor.

