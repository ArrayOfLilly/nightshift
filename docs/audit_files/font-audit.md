# Audit 11: Custom Font Registration & PostScript Names

**Scope:** `countdownAppApp.swift`, `AppTheme.swift`, `SharedEditorComponents.swift`
(+ saját kibővítés: teljes kódbázis)

**Összefoglalás:** Két kritikus PostScript név mismatch azonosítva. A SwiftUI
`Font.custom()` hívások family nevet használnak (`"Alien League"`), de a CoreText
regisztráció PostScript nevet vár (`"AlienLeague"`). Eredmény: az Alien League font
valószínűleg sosem jelenik meg a SwiftUI felületen — San Francisco fallback fut helyette.
A WKWebView headingek ugyanezen okból system-ui-ra esnek vissza.

---

## §1 — Fizikai TTF fájlok és PostScript nevek (nameID 6)

| # | TTF fájlnév | PostScript név (nameID 6) | Family Name (nameID 1) | Style |
|---|---|---|---|---|
| 1 | `alienleague.ttf` | `AlienLeague` | Alien League | Regular |
| 2 | `alienleaguebold.ttf` | `AlienLeagueBold` | Alien League Bold | Bold |
| 3 | `alienleagueital.ttf` | `AlienLeagueItalic` | Alien League Italic | Italic |
| 4 | `alienleaguebolditalic.ttf` | `AlienLeagueBoldItalic` | Alien League Bold Italic | Bold Italic |
| 5 | `MozillaHeadline-VariableFont_wdth,wght.ttf` | `MozillaHeadline-ExtraLight` | Mozilla Headline ExtraLight | Regular |
| 6 | `RobotoFlex-VariableFont_GRAD,…wght.ttf` | `RobotoFlex-Regular` | Roboto Flex | Regular |

---

## §2 — registerBundledFonts() — CoreText regisztráció (countdownAppApp.swift)

| Sor | Regisztrált fájlnév | TTF fájl | Státusz |
|---|---|---|---|
| L34 | `"alienleague"` | `alienleague.ttf` | ✅ helyes |
| L34 | `"alienleaguebold"` | `alienleaguebold.ttf` | ✅ helyes |
| L34 | `"alienleagueital"` | `alienleagueital.ttf` | ✅ helyes |
| L34 | `"alienleaguebolditalic"` | `alienleaguebolditalic.ttf` | ✅ helyes |

A fájlnév → bundle felbontás helyes, mind a 4 Alien League TTF regisztrálódik process scope-ban.
Mozilla Headline és Roboto Flex **nem** regisztrálódik CoreText-en keresztül — CSS @font-face-en
keresztül érhetők el (lásd §4).


---

## §3 — Font.custom() vs. PostScript nevek — KRITIKUS MISMATCH (AppTheme.swift)

| AppTheme.swift sor | Font.custom() argumentum | Tényleges PostScript név | Egyezés? | Következmény |
|---|---|---|---|---|
| L57 | `"Alien League"` | `AlienLeague` | ❌ NEM | San Francisco fallback |
| L61 | `"Alien League Bold"` | `AlienLeagueBold` | ❌ NEM | San Francisco Bold fallback |

**Gyökérok:** A CoreText a fontot a TTF nameID 6 mezője (PostScript név) szerint regisztrálja.
A `Font.custom("Alien League", ...)` a `"Alien League"` stringet keresi a regisztrált PostScript
nevek között — ilyen nincs, mert a PostScript név `AlienLeague` (szóköz nélkül, camelCase).
A SwiftUI csendben visszaesik a rendszer alapbetűtípusra.

**FN-1 (Critical):** `Font.custom("Alien League", size:)` → nem találja a fontot → San Francisco.
**FN-2 (Critical):** `Font.custom("Alien League Bold", size:)` → nem találja a fontot → San Francisco Bold.

Javasolt fix:

```swift
// Volt (hibás — family name, nem PostScript name):
Font.custom("Alien League", size: size)       // AppTheme.swift L57
Font.custom("Alien League Bold", size: size)  // AppTheme.swift L61

// Legyen (helyes — nameID 6 PostScript name):
Font.custom("AlienLeague", size: size)
Font.custom("AlienLeagueBold", size: size)
```

---

## §4 — WKWebView CSS @font-face deklarációk (SharedEditorComponents.swift)

| Sorok | Függvény | CSS font-family érték | TTF fájlra mutat? | Megjegyzés |
|---|---|---|---|---|
| L89–L96 | `mozillaHeadlineFontFaceCSS()` | `'Mozilla Headline'` | ✅ igen | Bundle URL dinamikus, helyes |
| L104–L111 | `robotoFlexFontFaceCSS()` | `'Roboto Flex'` | ✅ igen | Bundle URL dinamikus, helyes |

Mindkét @font-face blokk helyes — `Bundle.main.resourceURL` alapú dinamikus path, érvényes
CSS struktúra. Ezek nem igényelnek CoreText regisztrációt, a WKWebView önállóan tölti be.

---

## §5 — markdownCSS heading font-stack — DISCREPANCY (SharedEditorComponents.swift)

| Sor | CSS selector | font-family stack | Probléma |
|---|---|---|---|
| L136 | `body` | `'Mozilla Headline', 'Helvetica Neue', sans-serif` | ✅ helyes — @font-face deklarált |
| L143 | `h1, h2, h3` | `'AlienLeagueBold', 'Alien League Bold', system-ui` | ⚠️ egyik sem működik |

**FN-3 (High):** A heading font-stack két nevet próbál (`'AlienLeagueBold'`, `'Alien League Bold'`),
de egyik sem rendelkezik `@font-face` deklarációval a `SharedEditorComponents.swift`-ben.
A CoreText-en regisztrált fontok **nem láthatók** a WKWebView CSS kontextusából — a WKWebView
sandboxolt folyamatban fut, saját font kontextussal. Végeredmény: a headingek `system-ui`-val
renderelnek (macOS-en San Francisco).


---

## §6 — Architektúra összefoglaló: CoreText vs. WKWebView font láthatóság

| Font | CoreText regisztrált? | Bundle-ben? | CSS @font-face? | SwiftUI Font.custom? | WKWebView CSS? |
|---|---|---|---|---|---|
| Alien League Regular | ✅ igen | ✅ igen | ❌ nem | ❌ NEM (PS mismatch) | ❌ nem |
| Alien League Bold | ✅ igen | ✅ igen | ❌ nem | ❌ NEM (PS mismatch) | ❌ csak system-ui |
| Mozilla Headline | ❌ nem | ✅ igen | ✅ igen | N/A | ✅ igen |
| Roboto Flex | ❌ nem | ✅ igen | ✅ igen | N/A | ✅ igen |

---

## §7 — Silent fallback összefoglaló

| Felület | Fejlesztő szándéka | Ténylegesen renderel | Ok |
|---|---|---|---|
| SwiftUI szöveg | Alien League | San Francisco | `"Alien League"` ≠ PostScript `AlienLeague` |
| SwiftUI bold | Alien League Bold | San Francisco Bold | `"Alien League Bold"` ≠ PostScript `AlienLeagueBold` |
| WebView headingek | Alien League Bold | system-ui | Nincs @font-face, CoreText nem látható WKWebView-ból |
| WebView body | Mozilla Headline | Mozilla Headline ✅ | @font-face helyesen deklarálva |

---

## §8 — Javasolt fixek

### Fix FN-1/2 — AppTheme.swift PostScript név javítás

```swift
// Volt:
Font.custom("Alien League", size: size)
Font.custom("Alien League Bold", size: size)

// Legyen:
Font.custom("AlienLeague", size: size)
Font.custom("AlienLeagueBold", size: size)
```

### Fix FN-3 — SharedEditorComponents.swift WebView heading font

**A opció — @font-face hozzáadása** (ajánlott, konzisztens megjelenés más gépeken is):

```swift
private func alienLeagueFontFaceCSS() -> String {
    guard let boldURL = Bundle.main.resourceURL?
        .appendingPathComponent("Font/alienleaguebold.ttf") else { return "" }
    return """
    @font-face {
        font-family: 'Alien League Bold';
        src: url('\(boldURL.absoluteString)') format('truetype');
        font-weight: bold;
    }
    """
}
```

Majd a `markdownCSS` heading stack `'Alien League Bold'` névvel hivatkozik rá (az első
`'AlienLeagueBold'` entry eltávolítható — PostScript névként a CSS nem ismeri).

**B opció — fallback eltávolítása** (gyors fix, heading system-ui marad szándékosan):

```swift
// h1, h2, h3 { font-family: system-ui; }  // explicit, dokumentált szándék
```

---

## §9 — Saját kibővítés: Font.custom() teljes scan


`Font.custom()` keresve mind a 20 Swift fájlban.

**Eredmény: 3 hely, 2 fájlban**

| Fájl | Sor | Argumentum | Státusz |
|---|---|---|---|
| `AppTheme.swift` | L57 | `"Alien League"` | ❌ PostScript mismatch (FN-1) |
| `AppTheme.swift` | L61 | `"Alien League Bold"` | ❌ PostScript mismatch (FN-2) |
| `countdownAppApp.swift` | L9 | komment kontextus, nem tényleges hívás | ✅ nem érintett |

**Fontos megfigyelés:** A többi 18 fájl (`CountdownDetailView`, `CountdownRowView`,
`CalculateView` stb.) **nem hív közvetlenül** `Font.custom()`-ot — mind az
`AppTheme.alienLeague()` és `AppTheme.alienLeagueBold()` wrappereket használja.

Ez azt jelenti: **a fix egyetlen helyen szükséges** — `AppTheme.swift` L57 és L61.
Ha ott javul a PostScript név, az összes font-megjelenítés automatikusan javul az
egész alkalmazásban.

**FN-4 (megjegyzés):** A `countdownAppApp.swift` kommentje (`// "Alien League", …)
resolves from inside the app bundle`) szintén stale lesz a fix után — a PostScript
névváltás után a kommentet is frissíteni kell.

