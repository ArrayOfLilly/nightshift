# Audit 9: freeColors Array & Szemantikus Szín-mapping

**Scope:** `AppTheme.swift`, `CountdownItem.swift`, `CountdownRowView.swift`,
`ColorPickerSheet.swift`, `CountdownDetailView.swift`

**Összefoglalás:** Az `AppTheme.freeColors` egy pozíció-alapú `[Color]` tömb, amelyből
a szín kiválasztása nyers egész indexszel (`Int?`) történik. Ez az antipattern oka nem
csupán az index-kezelés körüli kockázat — maga a tömb mint adatstruktúra inkonzisztens
a többi AppTheme design tokennel, ahol a névvel rendelkező értékek statikus `let`
propertyként vannak jelen. A tömbön kívüli, névvel ellátott színek (`background`,
`cardSurface`, `dark` stb.) szemantikusan hivatkozhatók; a `freeColors` elemei nem.

---

## §1 — A tömb tartalma és a komment eltérése

**Fájl:** `AppTheme.swift`, sorok 28–45

A sor 28 kommentje `"12 options, rotated by item index"` feliratot és 12 hex értéket sorol
fel. A tényleges tömb **14 elemet** tartalmaz (index 0–13). A kommentből hiányzik a
`#523554` (index 6) és a `#865486` (index 10).

| Index | Hex | Leírás |
|-------|-----------|------------------|
| 0 | `#30271B` | dark brown |
| 1 | `#51422E` | lighter brown |
| 2 | `#778005` | olive-yellow |
| 3 | `#4D70D8` | blue |
| 4 | `#293B72` | navy |
| 5 | `#403873` | dark purple |
| 6 | `#523554` | dark red-purple |
| 7 | `#593C73` | purple |
| 8 | `#723F73` | mid purple |
| 9 | `#8A4273` | magenta-purple |
| 10 | `#865486` | magenta-purple 2 |
| 11 | `#DD3B72` | pink-red |
| 12 | `#DD114A` | hot red-pink |
| 13 | `#B70E26` | deep red |

**FC-1 (Medium):** A sor 28 komment stale — 12-t ír, 14 elem van. A felsorolt hex lista
sem tartalmazza az index 6 és 10 értékeket. Fixelendő ha a tömb permanens marad.


---

## §2 — Hozzáférési helyek (minden index-használat a kódbázisban)

### A — Definíció és accessor (AppTheme.swift, sorok 47–50)

```swift
static func freeColor(for index: Int) -> Color {
    freeColors[index % freeColors.count]
}
```

Modulo wrapping miatt bármely pozitív egész biztonságos. **Swift remainder szemantika
miatt negatív input esetén (`-1 % 14 == -1`) az index negatív lesz → crash.**
Jelenlegi hívóhelyeken negatív érték nem fordulhat elő, de nincs statikus garancia.

### B — Lejárt slot háttérszín (CountdownRowView.swift, sorok 18–20)

```swift
private var itemFreeColor: Color {
    AppTheme.freeColor(for: item.accentColorIndex ?? 6)
}
```

Default fallback: index 6 (`#523554`). A `?? 6` literál nincs AppTheme-ben definiálva
— ha a paletta sorrendje változik, a default szín csendben változik.

### C — Data model tárolás (CountdownItem.swift, sorok 23–25)

```swift
/// Manually selected color index into AppTheme.freeColors.
/// nil = auto (hash-based fallback). Only meaningful for free (expired) slots.
var accentColorIndex: Int? = nil
```

**FC-2 (Low):** A komment `"hash-based fallback"`-et ír, de a kódban sehol nincs
hash számítás. A fallback kizárólag `?? 6` (hardcoded literal). Félrevezető dokumentáció.

### D — Codable perzisztencia (CountdownItem.swift, sorok 42, 63)

```swift
case id, label, deadline, showRemaining, accentColorIndex, soundEnabled, notes

accentColorIndex = try c.decodeIfPresent(Int.self, forKey: .accentColorIndex) ?? nil
```

A nyers `Int` index JSON-ba íródik. Ha egy jövőbeli buildben a tömb sorrendje változik
(elem törlés/átrendezés), a persistált index más színre mutat. Nincs UUID-alapú vagy
szín-érték-alapú mentés.

### E — Picker iteráció (ColorPickerSheet.swift, sorok 58–61)

```swift
ForEach(Array(AppTheme.freeColors.enumerated()), id: \.offset) { idx, color in
    swatchButton(color: color, index: idx, label: nil)
}
```

Teljes iteráció, mind a 14 szín megjelenik. Az `id: \.offset` pozíció-alapú azonosítás
— ha a tömb sorrendje változik, a SwiftUI diff hibásan újrarajzolhat.

### F — ColorPickerSheet binding (CountdownDetailView.swift, sor 276)

```swift
ColorPickerSheet(selectedIndex: $item.accentColorIndex)
```

Az `Int?` közvetlenül a modellbe ír vissza.


---

## §3 — Szemantikus konzisztencia: a tömb mint antipattern

**FC-3 (High — architekturális):** Az `AppTheme` többi színe statikus, névvel ellátott
`let` property (`background`, `dark`, `cardSurface`, `calculateBackground` stb.) — ezek
szimbolikusan hivatkozhatók, a szín értelmét a név hordozza. A `freeColors` tömb ezzel
szemben egy pozíció-indexelt paletta, ahol a szín "neve" egy számjegy. Ez két
következménnyel jár:

1. **Refactoring törékenység:** Ha a tömb bővül, rövidül vagy átrendeződik, minden
   persistált `accentColorIndex` értéke csendben más színre mutat. Nincs típusrendszer
   által védett kapcsolat az index és a szín között.

2. **Kizárt semantic tokens:** A tömbben lévő hexek egy része már *névvel is jelen van*
   az AppTheme-ben más kontextusban (`#593C73` = `calcSaveGradient` purple startColor,
   `#723F73` = ProjectField dropdown háttér, `#403873` = snippet sor szín kísérlet).
   Ezek nem a `freeColors` tömb részeként, hanem inline literálként léteznek más
   fájlokban — az átfedés nem dokumentált, és a theme-audit (`#6`) is jelzi.

**FC-4 (High — névhiány):** A `background` szín neve `AppTheme.background`, de értéke
az amber (`#E4A020` körül, ill. `#F5A623` a CSS oldalon — theme-audit FC-1 szerinti
eltérés). Az `amber` szó egyetlen névvel ellátott tokenben sem szerepel a Swift oldalon.
Ha valaki az amber-t keresi a kódbázisban, a `background` nevet kell tudnia — ez
intuitíve nem következik a szín szerepéből. Ez a névadási következetlenség nem a
`freeColors`-ra vonatkozik, de azonos kategória: a szín értéke ismerős, a neve nem.

---

## §4 — Bounds-safety összefoglaló

| Dimenzió | Státusz | Megjegyzés |
|---|---|---|
| Pozitív out-of-bounds | ✅ Biztonságos | Modulo wrapping |
| Negatív index | ⚠️ Potenciális crash | Swift `%` remainder, nem euklideszi modulo |
| Nil fallback | ✅ Biztonságos | `?? 6` default |
| Stale persistált index (tömb shrink) | ⚠️ Néma szín-váltás | Modulo wrap miatt nem crash, de más szín |
| Komment pontosság | ✗ Hibás | "12 options" + "hash-based" — egyik sem igaz |

**FC-5 (Low):** `freeColor(for:)` negatív inputra crashel. Ajánlott fix:
```swift
static func freeColor(for index: Int) -> Color {
    let count = freeColors.count
    return freeColors[((index % count) + count) % count]
}
```
Jelenlegi hívóhelyeken a kockázat elhanyagolható, de a függvény kontraktusa nem garantált.

---

## §5 — Saját kibővítés: nem vizsgált területek

A Qwen audit nem fedte le az AppTheme névvel ellátott, tömbön kívüli színeit. Ezek
önmagukban nem problémásak, de az átfedések dokumentálatlanok:

| AppTheme token | Hex | freeColors-ban? | Más fájlban inline? |
|---|---|---|---|
| `background` (amber) | `#E4A020` / `#F5A623` | Nem | CSS-ben `#F5A623` (theme-audit §1) |
| `dark` | `#2A2015` | Nem | `markdownCSS` body bg (docs-audit) |
| `cardSurface` | — | Nem | — |
| `calculateBackground` | — | Nem | `calcSaveGradient` gradient stop |
| `#593C73` (calcSave purple) | — | `freeColors[7]` ✓ | `calcSaveGradient` inline literál |
| `#723F73` (projectField bg) | — | `freeColors[8]` ✓ | `SnippetEditSheet` inline literál |

Az utolsó két sor jelzi: a `freeColors` tömb egyes elemei *de facto* szemantikus szerepet
töltenek be (pl. a calcSave gradient purple pontosan `freeColors[7]`), de ez nincs
dokumentálva, és a kapcsolatot semmi sem kényszeríti ki — párhuzamos literálok vannak.


---

## §6 — Megtévesztő szemantikus nevek az AppTheme-ben

**FC-6 (High — névadás):** Az `AppTheme` névvel ellátott színtokenjei egy részének neve
nem utal a vizuális értékre, hanem funkcionális vagy generikus fogalmat használ. Ez
ugyanolyan keresési és refactoring problémát okoz, mint a `freeColors` indexelés — csak
ellentétes irányból: ott **nincs név**, itt **van név, de hazudik**.

| Token | Tényleges szín | Mi sugall a név? | Mi a valóság? |
|---|---|---|---|
| `AppTheme.background` | amber (`#E4A020` / `#F5A623`) | szín-agnosztikus háttér | az app elsődleges amber akcentusa |
| `AppTheme.dark` | `#2A2015` sötét barna | generikus sötét | az amber family árnyék-változata |
| `AppTheme.cardSurface` | — | kártya felszín | funkcionális, de szín értéke nem következik belőle |
| `AppTheme.calculateBackground` | — | a Calculate tab háttere | kontextuálisan kötött, nem általános token |

**`AppTheme.background` — a legsúlyosabb eset:**
Az amber szín az alkalmazás vizuális identitásának középpontja — minden heading, gomb,
akcentus, timer szám ezt a színt használja. Ennek ellenére a neve `background`, ami:

1. **Kereshetetlen:** Ha valaki az amber-t keresi a kódbázisban, a `background` kulcsszóra
   nem asszociál. A `#F5A623` / `#E4A020` hex literálokra kell keresni — és ezek sem
   konzisztensek egymással (theme-audit §1 finding).
2. **Félrevezető olvasáskor:** `AppTheme.background` egy view `.background()` modifierben
   olvasva azt sugallja, hogy az elem "háttérszínét" kapja — miközben valójában az amber
   akcentust. A szándék és az olvasat eltér.
3. **A `dark` tokennel kombinálva különösen zavaros:** `foregroundStyle(AppTheme.dark)`
   olvasható úgy is, mint "sötét előtér szín" általánosan — valójában az amber árnyékát
   jelenti, ami csak az amber háttéren értelmes kontraszt.

**Kapcsolat a `freeColors` antipatternnel:**
A két probléma ugyanazon hiányosság két megjelenése — az AppTheme nem rendelkezik
konzisztens elnevezési konvencióval, ami a szín vizuális szerepét vagy értékét tükrözné.
Sem a `freeColors` indexei, sem a névvel ellátott tokenek nem alkotnak önmagukban
értelmes fogalmi modellt. Egy jövőbeli refactor (pl. `AppTheme.amber`, `AppTheme.amberShadow`,
`AppTheme.slotExpiredDefault` stb.) mindkét problémát egyszerre kezelné.

