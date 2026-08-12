# Audit 14 — JavaScript Injection & Template Literal Escaping

**Fájl:** `SharedEditorComponents.swift`
**Auditáló:** Qwen (alapvizsgálat) + Claude kiegészítés
**Dátum:** 2026-08-12

---

## Hatókör és módszertan

A `MarkdownWebView` komponens felhasználói markdown szöveget WKWebView-ban renderel,
bundled `marked.js` segítségével. A fő kockázati felület: a felhasználói szöveg egy
JavaScript template literal-ba kerül interpolálva, majd `document.body.innerHTML`-en
keresztül kerül DOM-ba.

**Vizsgált fájl:** `SharedEditorComponents.swift` — ez az egyetlen érintett fájl a
20 Swift fájlból; a többi nem tartalmaz WKWebView-t vagy JS injektálást.

**Call site-ok (zero sanitization mindkettőnél):**
- `NotesSheet.swift` — `MarkdownWebView(markdown: notes)`, ahol `notes: String`
  közvetlen `@Binding` a felhasználói billentyűleütésekhez
- `SnippetEditSheet.swift` — `MarkdownWebView(markdown: snippetBody)`, azonos pattern

**App Sandbox mitigáció:** A WKWebView `baseURL: Bundle.main.bundleURL`-el tölt,
így JavaScript hozzáférése korlátozott (nincs cross-origin fetch, fájlrendszer-hozzáférés
csak bundle scope-on belül). Ez csökkenti a legsúlyosabb injection-ök hatókörét,
de nem szünteti meg a kockázatot.

---

## Finding 1 — Elsődleges sebezhetőség: hiányos escaping a `reload()` template literal injektálásban

**Fájl:** `SharedEditorComponents.swift`
**Sorok:** 53–82 (`reload()` metódus)
**Súlyosság:** 🔴 HIGH — JS template literal breakout lehetséges

### Sebezhető kódblokk (68–81. sorok):

```swift
private func reload(_ raw: String, into wv: WKWebView) {
    let markedURL = Bundle.main.url(forResource: "marked.min", withExtension: "js")
                 ?? Bundle.main.url(forResource: "marked.umd", withExtension: "js")
    let fontFaceCSS = mozillaHeadlineFontFaceCSS() + robotoFlexFontFaceCSS()
    guard let markedURL,
          let markedJS = try? String(contentsOf: markedURL, encoding: .utf8)
    else {
        let escaped = raw
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: "\n", with: "<br>")
        wv.loadHTMLString(fallbackHTML(escaped, fontFaceCSS: fontFaceCSS),
                          baseURL: Bundle.main.bundleURL)
        return
    }
    let highlighted = applyHighlight(raw)          // ← 68. sor: escaping ELŐTT
    let escaped = highlighted                      // ← escape lánc (69–73. sorok)
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "`", with: "\\`")
        .replacingOccurrences(of: "${", with: "\\${")
        .replacingOccurrences(of: "</script>", with: "<\\/script>")
    let html = """
    <!DOCTYPE html><html><head><meta charset="utf-8">
    <style>\(fontFaceCSS)\(markdownCSS)</style></head><body>
    <script>\(markedJS)</script>
    <script>document.body.innerHTML = marked.parse(`\(escaped)`);</script>   // ← 78. sor: INJECTION POINT
    </body></html>
    """
    wv.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
}
```

### Adatfolyam (attack surface):

1. `MarkdownWebView.markdown` (caller binding) → `reload(markdown, into:)` → `raw: String`
2. `raw` → `applyHighlight(raw)` — `==...==` → `<mark>` regex csere, **escaping nélkül**
3. `highlighted` → 4 `replacingOccurrences` csere (70–73. sorok)
4. `escaped` → JS template literal interpoláció a 78. sorban: `` marked.parse(`\(escaped)`) ``

### Caller fájlok (mindkét helyen zero sanitization):

- `NotesSheet.swift` — `MarkdownWebView(markdown: notes)` ahol `notes` közvetlen `@Binding` a billentyűleütésekhez
- `SnippetEditSheet.swift` — `MarkdownWebView(markdown: snippetBody)`, azonos minta

---

## Finding 2 — Escaping analízis: mi kerül escapelésre, mi nem

**Fájl:** `SharedEditorComponents.swift`
**Sorok:** 69–73

### Jelenlegi 4 csere:

| # | Keresett | Csere | Cél | Sor |
|---|----------|-------|-----|-----|
| 1 | `\` | `\\` | Backslash-ek megkétszerezése | 70 |
| 2 | `` ` `` | `` \` `` | Template literal lezárás megakadályozása | 71 |
| 3 | `${` | `\${` | JS template expression kiértékelés megakadályozása | 72 |
| 4 | `</script>` | `<\/script>` | Script tag lezárás megakadályozása HTML kontextusban | 73 |

### Hiányzó escaping — maradék attack vectorok:

**A. Null byte-ok (`\0`, U+0000)**

Swift `String` tartalmazhat null byte-ot. JS engine-ekben a null byte terminálhatja
a forráskód egységet, törve a template literal szintaxist. Payload példa:

```
Hello\0</script><script>alert(1)</script>`
```

**B. Unicode surrogates és nem-UTF-8 szekvenciák**

Páratlan surrogate félpárok (U+D800–U+DBFF vagy U+DC00–U+DFFF) JS-ben dekódolási
hibát okozhatnak. A null byte-problémával kombinálva renderelési korrupciót idézhet elő.

**C. HTML kontextus escaping hiánya az `applyHighlight()` kimenetén**

Az `applyHighlight` `<mark>$1</mark>` template-be illeszti a regex capture group-ot.
Ha a markdown `==<script>alert(1)</script>==` tartalmaz, a kimenet:
`<mark><script>alert(1)</script></mark>` — ez ELŐTTE kerül az escape láncon, de a
`<`, `>`, `"` karakterek nem kerülnek escapelésre (csak `\`, `` ` ``, `${`, `</script>`).

**D. `"` és `'` karakterek hiánya**

HTML attribútum-kontextusban idézőjel-breakout lehetséges, ha a DOM struktúra változna.
A fallback path-ban (ld. Finding 4) szintén hiányzik.

**E. Escaping sorrend és `\\${...}` bypass — részletes analízis a Finding 3-ban**

**F. `<mark>` tag HTML attribútum injection**

Ha a markdown `==title="onerror=alert(1)"<img src=1>==` tartalmat kap, a regex
az egész részt `<mark>` tagbe teszi. A `"`, `'`, `<` (nem-script tagek esetén)
nem kerülnek escapelésre az aktuális láncon.

---

## Finding 3 — Escaping sorrendtől függő bypass: double-backslash attack

**Fájl:** `SharedEditorComponents.swift`
**Sorok:** 70–72
**Súlyosság:** 🔴 HIGH

### Jelenlegi sorrend:

1. `\` → `\\` (minden backslash megkétszerezése)
2. `` ` `` → `` \` ``
3. `${` → `\${`

### Bypass bizonyítás:

Input: `\\${alert(document.cookie)}`

| Lépés | Művelet | Eredmény |
|-------|---------|----------|
| Input | — | `\\${alert(document.cookie)}` |
| 70. sor (`\` → `\\`) | Minden `\` megkétszerezve | `\\\\${alert(document.cookie)}` |
| 71. sor (backtick) | Nincs backtick | `\\\\${alert(document.cookie)}` |
| 72. sor (`${` → `\${`) | Escapes `${` | `\\\\\${alert(document.cookie)}` |

A JS engine-ben: `\\\\` → két literális backslash (`\\`), majd `\${` → literális `${`.
Így az effektív JS string: `\\${alert(document.cookie)}` — a `${...}` **kiértékelődik**.

**⚠️ Kódbázis-ellenőrzés után — Finding 3 felülvizsgálat:**

A bypass valójában **nem működik**. A Qwen összekeverte a JS template literal
*forráskódjában* kiértékelt `${...}` kifejezéseket a template literal által
előállított *string értékkel*.

A teljes escape lánc után a JS forráskódban `\\\\\${alert(1)}` szerepel.
A JS engine ezt így értelmezi:
- `\\` → literális `\`
- `\\` → literális `\`
- `\$` → literális `$` (nem-escape karakter, `\` elnyeli a template expression triggert)
- `{alert(1)}` → literális szöveg

A `marked.parse()` tehát a `\\${alert(1)}` **string értéket** kapja — ezt
markdownként dolgozza fel, nem JS forráskódként. A `${...}` csak a template
literal *forráskódjában* értékelődik ki, a string értékében nem.

**Finding 3 értékelés: false positive.** Az escaping sorrend valóban törékeny
és karbantarthatatlan, de a konkrét `\\${...}` bypass nem eredményez
kódfuttatást a jelenlegi pipeline-ban.

---

## Finding 4 — Fallback path eltérő (hiányos) escaping szabályokkal

**Fájl:** `SharedEditorComponents.swift`
**Sorok:** 57–67 (fallback path) + `fallbackHTML()` függvény
**Súlyosság:** 🟡 LOW-MEDIUM

A `marked.min.js` betöltési hibájánál a fallback path HTML entity encoding-ot használ:

```swift
let escaped = raw
    .replacingOccurrences(of: "&", with: "&amp;")   // 61. sor
    .replacingOccurrences(of: "<", with: "&lt;")    // 62. sor
    .replacingOccurrences(of: "\n", with: "<br>")   // 63. sor
wv.loadHTMLString(fallbackHTML(escaped, fontFaceCSS: fontFaceCSS), ...)
```

```swift
private func fallbackHTML(_ body: String, fontFaceCSS: String = "") -> String {
    "<html><head><style>\(fontFaceCSS)\(markdownCSS)</style></head><body><p>\(body)</p></body></html>"
}
```

### Problémák:

1. **Hiányzó `"` escape** — attribútum-breakout lehetséges ha a struktúra változna
2. **Hiányzó `'` escape** — azonos ok
3. **`&` double-encoding bug** — ha az input `&amp;`, az első csere `&amp;amp;`-t eredményez,
   ami `&amp;`-ként jelenik meg (nem `&`) — az input korrupt lesz
4. **Hiányzó `>` escape** — kisebb kockázat, de szomszédos markup-pal interakcióba léphet

---

## Finding 5 — `applyHighlight()` sanitizálatlan regex capture group injektálás

**Fájl:** `SharedEditorComponents.swift`
**Sorok:** 118–122
**Súlyosság:** 🟠 MEDIUM

```swift
private func applyHighlight(_ s: String) -> String {
    guard let rx = try? NSRegularExpression(pattern: "==(.+?)==") else { return s }
    return rx.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s),
                                       withTemplate: "<mark>$1</mark>")
}
```

A `$1` capture group raw szövegként kerül `<mark>` tagbe — semmi escaping.

**Példa payload:** `==<img src=1 onerror=alert(1)>==`

| Lépés | Eredmény |
|-------|----------|
| `applyHighlight` után | `<mark><img src=1 onerror=alert(1)></mark>` |
| 70. sor (backslash) | változatlan |
| 71. sor (backtick) | változatlan |
| 72. sor (`${`) | változatlan |
| 73. sor (`</script>`) | változatlan |

A végeredmény bekerül a JS template literal-ba, `marked.parse()` feldolgozza,
`innerHTML`-en keresztül renderelődik — az `onerror` event handler a WKWebView
kontextusban végrehajtódhat (WKWebViewConfiguration policy-korlátozás nem látható a kódban).

---

## Finding 6 — Nincs más injection pont a projektben

A projekt összes többi Swift fájljában nincs `loadHTMLString`, `evaluateJavaScript`
vagy HTML string builder. Az összes injection attack surface a `SharedEditorComponents.swift`
`reload()` metódusára koncentrálódik.

| Fájl | Verdict | Megjegyzés |
|------|---------|------------|
| `ContentView.swift` | ✅ Clean | Csak SwiftUI nézetek |
| `CountdownView.swift` | ✅ Clean | SwiftUI only |
| `CountdownDetailView.swift` | ✅ Clean | AppKit NSTextField, nem web kontextus |
| `AddCountdownSheet.swift` | ✅ Clean | Standard SwiftUI form |
| `NotesSheet.swift` | ⚠️ Caller | `notes` → `MarkdownWebView` — az injection a MarkdownWebView-ban (Finding 1–5) |
| `SnippetEditSheet.swift` | ⚠️ Caller | `snippetBody` → `MarkdownWebView` — azonos |
| `SnippetsView.swift` | ✅ Clean | `replacingOccurrences` csak `\n` → space SwiftUI Text-ben, nem HTML |
| `Snippet.swift` | ✅ Clean | Codable data model, nincs rendering |
| `NamedDeadline.swift` | ✅ Clean | Utility modell, nincs web felület |
| `CountdownItem.swift` | ✅ Clean | Data model only |
| `ColorPickerSheet.swift` | ✅ Clean | SwiftUI color swatches |
| `SunPanel.swift` | ✅ Clean | SwiftUI sun time rendering |
| `SunTimesService.swift` | ✅ Clean | `URLComponents` safe URL building |
| `SunTimes.swift` | ✅ Clean | Data model, `DateFormatter` fixed formátumok |
| `AppTheme.swift` | ✅ Clean | Konstansok only |
| `CalculateView.swift` | ✅ Clean | Nincs `loadHTMLString` / `evaluateJavaScript` |

---

## Összefoglaló

| # | Hely | Probléma | Súlyosság |
|---|------|----------|-----------|
| 1 | `SharedEditorComponents.swift:78` | JS template literal interpoláció hiányos escapinggel | 🔴 HIGH |
| 2 | `SharedEditorComponents.swift:70-73` | Hiányzó null byte, `"`, `'`, `<` (HTML kontextus) escaping | 🟠 MEDIUM-HIGH |
| 3 | `SharedEditorComponents.swift:70-72` | Sorrend-függő bypass: `\\${...}` — **false positive** (ld. felülvizsgálat); escaping sorrend törékeny de a bypass nem fut le | ~~🔴 HIGH~~ N/A |
| 4 | `SharedEditorComponents.swift:61-63` (fallback) | HTML escaping hiányzó `'`, `"`, `>`; `&` double-encoding | 🟡 LOW-MEDIUM |
| 5 | `SharedEditorComponents.swift:118-122` (`applyHighlight`) | Regex capture group `<mark>`-ba sanitizálás nélkül | 🟠 MEDIUM |

**Ajánlott fix stratégia:** Ne interpolálj felhasználói tartalmat közvetlenül a JS
template literal stringbe. Helyette: a felhasználói tartalmat JS változóként adj át
`evaluateJavaScript()` híváson keresztül az oldalbetöltés után, vagy használj Data URL
/ content isolation megközelítést. A jelenlegi pattern — egy HTML dokumentum beágyazott
JS-sel és felhasználói adattal egyetlen stringben — inherensen törékeny, mert minden
karakter-whitelist bővítésnél a sorrend és a teljesség kritikus (null byte, Unicode,
escape-szekvencia interakciók stb.).
