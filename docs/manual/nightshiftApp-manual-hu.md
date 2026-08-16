# NightShift App — Felhasználói kézikönyv

A NightShift App egy macOS alkalmazás, amivel nyomon követheted a fontos határidőket,
visszaszámlálókat kezelhetsz, és gyakran használt szövegeket tárolhatsz el. Az ablak
tetején három fül érhető el.

---

## Fülsor

A fülsor az ablak tetején található. Az aktív fül mögött egy sötét teli kör jelzi a kiválasztott nézetet.

| Ikon | Fül | Mire való |
|------|-----|-----------|
| Óra | **Calculate** | Két időpont közötti különbség kiszámítása |
| @ | **Countdown** | Visszaszámlálók listájának kezelése |
| Idézőjel | **Snippets** | Újrafelhasználható szövegek tárolása |

---

## Calculate nézet

A Calculate nézet pontosan kiszámítja, mennyi idő telt el vagy van még hátra két dátum között.

### Léptetők

Két léptetősor látható: **FROM** (kezdő) és **TO** (záró). Minden sor öt részből áll:
ÉV, HÓNAP, NAP, ÓRA, PERC — mindegyiknek van egy felfelé és egy lefelé mutató gombja.

- **Egyetlen kattintás** egy lépéssel mozgatja az értéket.
- **Lenyomva tartás** rövid késleltetés után automatikusan ismétlődik, így gyorsan lehet navigálni.

Az alkalmazás minden indításkor visszatölti az utoljára beállított FROM és TO értékeket.

### Reset gombok

- **RESET FROM NOW** — a FROM időpontot az aktuális pillanatra állítja.
- **RESET TO NOW** — a TO időpontot az aktuális pillanatra állítja.

### Eredmény megjelenítése

A léptetők alatt az alkalmazás mutatja a két időpont különbségét napokban, órákban,
percekben és másodpercekben. Egy váltógomb két megjelenítési mód között vált:

- **DAYS** — a teljes különbség napokban (pl. „142 nap").
- **CAL** — naptár szerinti bontás: évek, hónapok és napok külön értékként.

A váltógomb állása megmarad az újraindítás után is.

<!-- group -->
![Calculate nézet – DAYS mód: a két dátum közötti napok száma](../../screenshots/01 Calculate View - Calculated Days.png)
*Calculate nézet DAYS módban — az eredmény egyetlen összesített napszámként jelenik meg.*
![Calculate nézet – CAL mód: évekre, hónapokra és napokra bontva](../../screenshots/01b Calculate View - Calculated Epochs.png)
*Calculate nézet CAL módban — ugyanaz az időtartam évekre, hónapokra és napokra bontva.*
<!-- /group -->


---

### Mentett határidők

A **SAVE** gomb (könyvjelző ikon) lehetővé teszi, hogy a TO dátumot elments egy névvel,
és később újra betölthesd anélkül, hogy újra be kellene gépelned.

#### Határidő mentése

1. Állítsd be a TO dátumot a kívánt határidőre.
2. Kattints a **könyvjelző ikonra** (a SAVE gomb bal oldala). Egy panel nyílik meg.
3. Írd be a határidő nevét, majd kattints a **SAVE** gombra. A határidő elmentésre kerül.

<!-- group -->
![Határidő mentése – üres névmező](../../screenshots/02 Calculate View - Save Named Duration - empty.png)
*A mentési panel üres névmezővel nyílik meg. Írd be a nevet, majd kattints a SAVE gombra.*
![Határidő mentése – kitöltött névmező](../../screenshots/02b Calculate View - Save Named Duration - edit.png)
*A névmező kitöltve. A SAVE elmenti, a CANCEL bezárja a panelt mentés nélkül.*
<!-- /group -->

#### Mentett határidők megtekintése

Kattints a SAVE gomb jobb oldalán lévő **chevronra (▾)**. Megjelenik egy lista az összes
mentett határidővel.

- **Egy sorra kattintva** megnyílik a részletek panel.

![Mentett határidők listája](../../screenshots/03 Calculate View - Saved Named Durations.png)

*A határidők listája minden mentett elemet megmutat. Kattints bármelyik sorra a részletek megnyitásához.*

#### Részletek panel

A részletek panel a határidő nevét és dátumát mutatja. Innen a következőket teheted:

- **LOAD AS TO** — betölti a határidő dátumát a TO léptető mezőbe.
- **Ceruza ikon** — átnevezési mód: a név szerkeszthető mezővé válik.
  Írd be az új nevet, majd kattints a **RENAME** gombra a megerősítéshez, vagy a **CANCEL**-re az elvetéshez.
- **Kuka ikon** — véglegesen törli a határidőt. Megerősítő párbeszéd jelenik meg; kattints a **Delete** gombra a megerősítéshez vagy a **Cancel**-re a visszalépéshez.

![Határidő részletek panelje – név, dátum és műveleti gombok](../../screenshots/03b Calculate View - Saved Named Durations Details.png)

*A részletek panel mutatja a határidő nevét és dátumát. Elérhető: LOAD AS TO, átnevezés (ceruza) és törlés (kuka).*

<!-- group -->
![Határidő átnevezése – szerkeszthető névmező RENAME és CANCEL gombokkal](../../screenshots/03c Calculate View - Edit Saved Named Durations.png)
*Átnevezési mód: a név szerkeszthető szövegmezővé válik. Kattints a RENAME gombra a megerősítéshez.*
![Határidő törlésének megerősítő párbeszéde](../../screenshots/03d Calculate View - Delete Saved Named Durations.png)
*A végleges törlés előtt megerősítő párbeszéd jelenik meg.*
<!-- /group -->


---

### Nap- és holdadatok

A Calculate képernyő alján egy napikon gomb megnyit egy panelt a mai napra vonatkozó
csillagászati adatokkal. A panel a következőket mutatja:

- **Napkelte és napnyugta** időpontjai.
- **Arany óra** és **kék óra** ablakok (reggel és este).
- **Holdfázis** a fázis nevével és a megvilágítás százalékával.
- A jelenlegi holdciklus holdfázis-csíkja.

![Nap- és holdadatok panel](../../screenshots/04 Calculate View - Sun and Moon Data.png)

*A Nap & Hold panel megmutatja a mai napkeltét/napnyugtát, az arany óra ablakait és az aktuális holdfázist.*

---

## Countdown nézet

A Countdown nézet nevesített visszaszámláló slotok listáját kezeli, mindegyik egy adott határidőhöz kötve.

### A lista

A bejegyzések két csoportban jelennek meg:

- **Aktív bejegyzések** — a határidő a jövőben van. Növekvő sorrend a határidő szerint
  (leghamarabb lejáró legelöl). Borostyánszínű időzítővel jelenik meg.
- **Szabad slotok** — a határidő lejárt. Színes **FREE ✓** jelzővel jelennek meg.
  A szabad slotok átrendezhetők húzással a szabad slotok szekcióján belül.

<!-- group -->
![Countdown lista – aktív és szabad slotok összesítve](../../screenshots/05 CountDown View.png)
*Az aktív bejegyzések borostyánszínű időzítőt mutatnak; a szabad slotok színes FREE ✓ jelzőt és húzással rendezhetők.*
![Countdown lista – bejegyzés sor határidő megjelenítési módban](../../screenshots/05d CountDown View - Deadline.png)
*A jobb oldali váltógomb határidő módra állt: a statikus célállapot dátuma jelenik meg az élő visszaszámlálás helyett.*
<!-- /group -->

### Aktív sor

Egy aktív sor bal oldalán egy sötét pill mutatja a bejegyzés nevét, jobb oldalán egy
váltógomb választ a következők között:

- **Hátralévő idő** — NN:ÓÓ:PP:MM élő visszaszámlálás.
- **Határidő dátuma** — statikus dátum ÉÉÉÉ.HH.NN ÓÓ:pp formátumban.

**A név másolása:** koppints a sötét pillre, hogy vágólapra kerüljön a szöveg.
A pill röviden „COPIED" feliratot mutat visszajelzésként.

**Megjegyzés jelző:** ha a slothoz megjegyzés tartozik, egy kis szem ikon jelenik meg
a pill jobb oldalán. Az ikon eltűnik, amíg a „COPIED" felirat látszik.

![Countdown lista – bejegyzés sor megjegyzés jelzővel](../../screenshots/05e CountDown View - Existing note.png)

*A narancsszínű szem ikon jelzi, hogy a slothoz megjegyzés tartozik. Nyisd meg a részletek nézetet a szerkesztéshez.*


### Visszaszámláló hozzáadása

Koppints a lista alján lévő **+ ADD** gombra. Megnyílik egy panel egy névmezővel és
határidő-léptetőkkel. Töltsd ki az adatokat, majd erősítsd meg a slot létrehozásához.

![Új elem hozzáadása panel – névmező és határidő-léptetők](../../screenshots/06 Add New Item.png)

*A hozzáadás panel: adj meg egy nevet és állítsd be a határidőt, majd erősítsd meg a slot létrehozásához.*

### Visszaszámláló törlése

A listából koppints egy kártyára a részletek nézet megnyitásához, majd használd az ottani
kuka gombot. A törlés előtt mindig megjelenik egy megerősítő párbeszéd — kattints a
**Delete** gombra a megerősítéshez vagy a **Cancel**-re az elvetéshez.

![Visszaszámláló törlésének megerősítő párbeszéde](../../screenshots/06b Delete Item.png)

*A végleges törlés előtt mindig megerősítő párbeszéd jelenik meg.*

---

### Részletek nézet

Bármelyik sorkártyára koppintva megnyílik a teljes részletek nézet.

**Név szerkesztése:** koppints a tetején lévő nagy feliratú névre az inline szerkesztéshez.
Nyomd meg az Enter billentyűt vagy kattints máshová a megerősítéshez.

**Másolás gomb:** a név melletti dokumentum ikon vágólapra másolja a nevet.

**Időkijelző:** a visszaszámláló vagy a határidő dátuma az illusztrációra rávetítve jelenik meg.

**Váltó pill:** a képernyő alján lévő sötét pill gomb vált a *Hátralévő idő* (NN:ÓÓ:PP:MM)
és a *Határidő megjelenítése* (statikus dátum) között.

**Határidő-léptető:** öt összetevős léptető (ÉV, HÓNAP, NAP, ÓRA, PERC) lehetővé teszi
a határidő módosítását. Lenyomva tartással gyorsan léptethetsz. A módosítások automatikusan mentésre kerülnek.

<!-- group -->
![Részletek nézet visszaszámlálási módban – élő kijelző](../../screenshots/07 CountDown Detail View - Countdown.png)
*Visszaszámlálási mód: az élő hátralévő idő jelenik meg az illusztráción.*
![Részletek nézet határidő módban – statikus dátum](../../screenshots/07b CountDown Detail View - Deadline.png)
*Határidő mód: a statikus célállapot dátuma jelenik meg az élő visszaszámlálás helyett.*
![Részletek nézet lejárt (szabad) slothoz](../../screenshots/07c CountDown Detail View - Expired.png)
*Egy lejárt slot a részletek nézetben: a FREE állapot látható és a színválasztó gomb elérhetővé válik.*
<!-- /group -->


#### Műveleti gombok

Négy ikongomb jelenik meg sorban a részletek nézet alján:

| Gomb | Ikon | Mikor elérhető | Művelet |
|------|------|----------------|---------|
| Hang | Hangszóró | Mindig | Rendszerhangot játszik le, amikor a slot határideje lejár |
| Megjegyzések | Cetli | Mindig | Megnyitja a megjegyzésszerkesztőt ehhez a slothoz |
| Szín | Ecset | Csak szabad slotoknál | Megnyitja a színválasztót |
| Törlés | Kuka | Mindig | Törli ezt a slotot (megerősítés szükséges) |

#### Hang kapcsoló

Ha be van kapcsolva (hangszóró hullám ikon), az alkalmazás rendszerhangot játszik le
a slot határidejének lejártakor. Ha ki van kapcsolva (áthúzott hangszóró), nem hallható hang.
A beállítás slotonként mentésre kerül.

#### Színválasztó (csak szabad slotoknál)

A színválasztó panel tizenkét kiemelőszín-mintát és egy **AUTO** lehetőséget mutat.
Koppints bármelyik mintára a szabad slot kártyájára való alkalmazáshoz. Az AUTO visszaállítja
az alapértelmezett színt. A kiválasztás azonnal mentésre kerül.

![Színválasztó panel – tizenkét kiemelőszín és AUTO lehetőség](../../screenshots/08 CountDown Detail View - Color Picker.png)

*A színválasztó tizenkét kiemelőszínt és egy AUTO lehetőséget kínál. A kiválasztás azonnal érvénybe lép.*

#### Törlés

A kuka gomb véglegesen eltávolítja a slotot. Megerősítő párbeszéd jelenik meg;
kattints a **Delete** gombra a megerősítéshez vagy a **Cancel**-re az elvetéshez.
A törlés nem vonható vissza.

---

### Megjegyzések

Minden visszaszámláló slothoz tartozik egy szabad formátumú megjegyzésmező,
amely a részletek nézetben a megjegyzés gombbal érhető el.

A megjegyzések panel alapértelmezetten **Megtekintő módban** nyílik meg, amely az
tartalmat formázott markdown-ként jeleníti meg (fejlécek, listák, kódblokkök, táblázatok, kiemelés).

#### Módváltás

A fejléc váltógombja vált a következők között:

- **Megtekintő mód** — formázott markdown egy görgetethető nézetben.
- **Szerkesztő mód** — egyszerű szövegszerkesztő markdown írásához/szerkesztéséhez.

<!-- group -->
![Megjegyzések panel szerkesztő módban](../../screenshots/09 CountDown Detail View - Note Editor - Editor View.png)
*Szerkesztő mód: írj vagy szerkessz markdown szöveget közvetlenül.*
![Megjegyzések panel megtekintő módban – megjelenített markdown](../../screenshots/10 CountDown Detail View - Note Editor - Viewer View.png)
*Megtekintő mód: a markdown fejlécekkel, listákkal, kódblokkökkel és kiemeléssel jelenik meg.*
<!-- /group -->


#### Megjegyzések másolása

A **Másolás** gomb (mindkét módban elérhető) a nyers markdown szöveget a vágólapra másolja,
ahonnan bármely más alkalmazásba beillesztheted.

#### Megjegyzések törlése

A fejléc **kuka gombja** törli a teljes megjegyzésmezőt.
Megerősítő párbeszéd jelenik meg; kattints a **Delete** gombra a megerősítéshez.

<!-- group -->
![Megjegyzések törlésének megerősítő párbeszéde](../../screenshots/11 CountDown Detail View - Note Editor - Confirm Delete.png)
*A megerősítő párbeszéd megjelenik, mielőtt a megjegyzés tartalmát véglegesen törölnéd.*
![Megjegyzések panel – üres állapot](../../screenshots/12 CountDown Detail View - Note Editor - Empty.png)
*Ha még nincs megjegyzés, egy helyőrző jelenik meg. Koppints rá a szerkesztő mód megnyitásához.*
<!-- /group -->

#### Bezárás mentetlen módosításokkal

Ha a **✕ gombbal** zársz be egy megjegyzéspanelt, miközben vannak mentetlen módosítások,
megerősítő párbeszéd jelenik meg:

- **Kilépés mentés nélkül** — elveti a módosításokat és bezárja a panelt.
- **Mentés és kilépés** — elmenti az aktuális szöveget, majd bezárja.
- **Mégse** — visszatér a panelre bezárás nélkül.

![Megjegyzések panel – mentetlen módosítások megerősítő párbeszéde](../../screenshots/11b CountDown Detail View - Note Editor - Confirm Exit.png)

*A párbeszéd csak akkor jelenik meg, ha vannak mentetlen módosítások. Tiszta panel esetén azonnal bezárul.*

---

## Snippets

A Snippets fül újrafelhasználható szövegrészletek könyvtára, projekt neve szerint csoportosítva.
A snippetek teljesen függetlenek a visszaszámláló slotoktól.

### A lista

A snippetek projektenként, ábécérendben vannak csoportosítva, a **General** mindig az utolsó.
Minden sor a snippet nevét és tartalmának rövid előnézetét mutatja. A sorok jobb oldalán
lévő **Másolás** gomb azonnal a vágólapra másolja a teljes szöveget, az editor megnyitása nélkül.

Egy sorra koppintva megnyílik a snippet a szerkesztőpanelen.

A jobb felső sarokban lévő **+** gombbal hozz létre új snippetet.

![Snippets lista – projektcsoportok snippet sorokkal](../../screenshots/13 Snippets View - Rows.png)

*A Snippets lista projektenként csoportosítva. Minden sor a nevet, egy előnézetet és egy Másolás gombot tartalmaz.*


### Snippet szerkesztőpanel

A szerkesztőpanel a fejlécben lévő gombbal két mód között vált:

- **Megtekintő mód** — a snippet testét formázott markdownként jeleníti meg.
- **Szerkesztő mód** — egyszerű szövegszerkesztő markdown írásához közvetlenül.

A fejléc tartalmaz még:

- **Másolás** — a teljes nyers markdown testét a vágólapra másolja.
- **Törlés** — megerősítés után véglegesen törli a snippetet.

<!-- group -->
![Snippet szerkesztő megtekintő módban – megjelenített markdown](../../screenshots/14 Snippet Edtor - Viewer.png)
*Megtekintő mód: a snippet teste formázott markdownként jelenik meg.*
![Snippet szerkesztő szerkesztő módban](../../screenshots/15 Snippet Edtor - Editor.png)
*Szerkesztő mód: szerkeszd a nevet, a projektet és a testet közvetlenül. A test mező teljes markdownt támogat.*
<!-- /group -->

#### Mezők

| Mező | Leírás |
|------|--------|
| Cím | Rövid név a snippetnek |
| Projekt | Csoportosítja a snippetet a listában; koppintásra megnyílik a projektkiválasztó |
| Szöveg | A snippet tartalma (markdown támogatott) |

#### Projektkiválasztó

A projekt mezőre koppintva legördülő lista jelenik meg a meglévő projektnevekkel.
Válassz egy meglévő projektet a snippet hozzárendeléséhez, vagy gépelj be egy új nevet
új projektcsoport létrehozásához. A lista gépelés közben szűr.

![Projektkiválasztó legördülő lista](../../screenshots/16 Snippet Edtor - Projectname choser Dropdown List.png)

*A projektkiválasztó az összes meglévő projektnevet mutatja. Válassz egyet, vagy gépelj be egy újat.*


#### Projektmenü

Minden projektszekció fejlécében a projektnév mellett egy kis **chevron (▾) gomb** látható.
Rákattintva egy menü nyílik meg két lehetőséggel:

- **Projekt átnevezése…** — párbeszéd nyílik meg, ahol beírhatsz egy új nevet.
  A projekthez tartozó összes snippet automatikusan az új névre kerül.
- **Projekt törlése** — eltávolítja a projektmappát. **A benne lévő snippetek nem törlődnek.**
  Átkerülnek a **General** projektbe, és ott teljesen elérhetők maradnak.
  A megerősítő párbeszéd ezt az üzenetet mutatja a törlés előtt.

![Projektszekció fejlécmenüje – Átnevezés és Törlés lehetőségekkel](../../screenshots/16b Snippets View - Project Editing Context Menu.png)

*A projektnév melletti chevron megnyitja a projektmenüt. A Törlés minden snippetet a General projektbe mozgat — semmi sem vész el.*

#### Snippet törlése

A szerkesztőpanel fejlécében lévő **Törlés** gomb megerősítés után véglegesen eltávolítja a snippetet.
Ez különbözik a projekt törlésétől: az egyes snippetek törlése nem vonható vissza.

![Snippet törlésének megerősítő párbeszéde](../../screenshots/17 Snippet Edtor - Delete.png)

*Megerősítő párbeszéd jelenik meg, mielőtt a snippetet véglegesen törölnéd.*

#### Bezárás mentetlen módosításokkal

Ha a **✕ gombbal** zársz be egy snippet szerkesztőt, miközben vannak mentetlen módosítások,
megerősítő párbeszéd jelenik meg:

- **Kilépés mentés nélkül** — elveti a módosításokat és bezárja a szerkesztőt.
- **Mentés és kilépés** — elmenti és bezárja.
- **Mégse** — visszatér a szerkesztőhöz.

![Snippet szerkesztő – mentetlen módosítások megerősítő párbeszéde](../../screenshots/17 Snippet Edtor - Exit.png)

*A párbeszéd csak mentetlen módosítások esetén jelenik meg.*


---

## Adathelyreállítás

Ha az alkalmazás indításkor azt észleli, hogy egyes tárolt adatok nem tölthetők be —
például mert egy fájl megsérült vagy inkompatibilis formátumban van —, a problémás
fülön egy helyreállítási sáv jelenik meg.

### Helyreállítási sáv

A sáv mindhárom fülön egymástól függetlenül jelenik meg: minden fül csak akkor mutatja,
ha a saját adatain volt probléma. A sáv megjeleníti a nem betölthető elemek számát,
és két műveletet kínál.

<!-- group -->
![Helyreállítási sáv a Calculate nézetben](../../screenshots/18 Calculate View - Corrupted Data Warning.png)
*Calculate nézet: „3 ITEMS COULD NOT BE LOADED" a Raw Data másolása és Elvetés gombokkal.*
![Helyreállítási sáv a Countdown nézetben](../../screenshots/18b Countdown View - Corrupted Data Warning.png)
*Countdown nézet: a sáv színe kissé sötétebb, hogy kontrasztot adjon a borostyánszínű háttérrel.*
![Helyreállítási sáv a Snippets nézetben](../../screenshots/18c Snippets View - Corrupted Data Warning.png)
*Snippets nézet: a sáv a snippet lista felett helyezkedik el.*
<!-- /group -->

### Nyers adatok másolása

Kattints a **Copy Raw Data** gombra, hogy a nem olvasható elemek nyers JSON-ját vágólapra
másold. Az adat olvasható formátumban jelenik meg, így megtekinthető vagy supportnak
továbbítható. Ez a művelet nem zárja be a sávot.

### Elvetés

Kattints a **Dismiss** gombra a sáv eltávolításához. A nem olvasható elemek törlődnek
a helyreállítási pufferből. Ha következő indításkor új sérülés kerül felismerésre, a sáv
ismét megjelenik.

> **Megjegyzés:** A helyreállítási sávban szereplő elemek nem kerültek be az alkalmazásba —
> nem láthatók a listában és adataik nem aktívak. A sáv elvetése a nyers adatok másolása
> után biztonságos; a vágólapon lévő másolat az egyetlen hivatkozás ezekre az elemekre.

---

## Névjegy

A Névjegy ablak mutatja az alkalmazás verzióját és jóváírásait. Nyisd meg a menüsorból:
**NightShift → About NightShift**.

![Névjegy ablak – alkalmazás ikon, név, verzió és jóváírások](../../screenshots/19 About.png)

*A Névjegy ablak mutatja az alkalmazás ikonját, verziószámát, a fejlesztő elérhetőségét és a képek jóváírását.*

Az ablak a következőket tartalmazza:

- **Alkalmazás ikon és név** — a tetején jelenik meg.
- **Verzió** — az aktuális verzió- és buildszám, pl. „Version 1.0 (42)".
- **Fejlesztő** — kattintható link, amely megnyit egy előre megcímzett e-mailt
  visszajelzés vagy kérdés küldéséhez.
- **Képek** — az alkalmazásban használt hold- és naprajzok jóváírása.
  A linkre kattintva megnyílik az alkotó weboldala.


---

## Súgó

A Súgó ablak az összes főbb funkcióhoz kínál kereshető, beépített dokumentációt.
Nyisd meg a menüsorból: **Help → NightShift Help**.

![Súgó ablak – szekciók és kereshető súgótételek](../../screenshots/20 Help.png)

*A Súgó ablak szekcióba rendezve listázza az összes funkciót. A tetején lévő keresőmező segítségével gyorsan megtalálhatod a témát.*

### Szekciók

A súgótartalom öt szekcióba van szervezve:

| Szekció | Mit tartalmaz |
|---------|---------------|
| Overview | Mit csinál az alkalmazás és hogyan illeszkedik a három fül egymáshoz |
| Countdown | Slotok hozzáadása, nevek, időzítők, megjegyzések, szabad slotok és átrendezés |
| Calculate | Dátum-léptetők, eredménymódok, mentett határidők és a Nap & Hold panel |
| Snippets | Snippetek létrehozása, szerkesztése, szervezése és másolása |
| Recovery | Mit jelent a helyreállítási sáv és mit tegyél, ha megjelenik |

### Keresés

Gépelj be bármilyen szót a felső keresőmezőbe a súgótételek szűréséhez. A keresés
a témanevekre illeszkedik, így a „notes" gépelésével csak a megjegyzésekkel kapcsolatos
tételek jelennek meg, a „sun" gépelésével csak a nappanel tételei. A keresőmező
törlésével visszatérhetsz az összes szekcióhoz.

---

## Beállítások

Nyisd meg a Beállításokat a menüsorból: **NightShift → Settings…** (vagy nyomd meg a **⌘ ,** billentyűkombinációt).
A Beállítások ablak két fület tartalmaz.

### Language (Nyelv) fül

![Beállítások – Language fül: felület nyelve és dátumformátum választók](../../screenshots/21 Settings View - Languages.png)

*A Language fül lehetővé teszi a felület nyelvének és a dátumformátumnak a független megadását.*

Két választó szabályozza a szövegek és számok megjelenítési módját:

- **Interface Language (Felület nyelve)** — válassz a *System Default* (Rendszer alapértelmezett),
  English (Angol) vagy Magyar lehetőségek közül. A System Default a macOS Rendszerbeállításokban
  megadott nyelvet követi.
- **Date & Number Format (Dátum- és számformátum)** — válassz a *System Default*,
  English (US) vagy Magyar (HU) lehetőségek közül. Ez szabályozza a dátumok és számok
  formázását az egész alkalmazásban.

> **Fontos:** A nyelvi módosítások újraindítást igényelnek. Ha bármelyik választó
> nem alapértelmezett értékre van állítva, a fül alján egy üzenet emlékeztet arra,
> hogy a módosítás érvénybe lépéséhez indítsd újra a NightShift alkalmazást.
> Az alkalmazás az újraindításig normálisan működik tovább.

### Appearance (Megjelenés) fül

![Beállítások – Appearance fül: betűméret szegmentált választó](../../screenshots/21b Settings View - Fontsize.png)

*A megjelenés fül lehetővé teszi a nagyobb betűméret kiválasztását. A módosítás azonnal érvénybe lép.*

A **Font Size (Betűméret)** szegmentált vezérlőnek négy lehetősége van:

| Lehetőség | Leírás |
|-----------|--------|
| Default | Normál betűméret |
| Large | Kissé nagyobb |
| Larger | Észrevehetően nagyobb |
| Largest | Maximális méret |

A kiválasztott méret azonnal érvényes az egész alkalmazásra — újraindítás nem szükséges.

---

## Tooltipek

Az alkalmazás legtöbb gombja és interaktív eleme rövid leírást jelenít meg, ha az
egérmutatót egy pillanatra megállítod fölötte, kattintás nélkül. Ezt a súgót
**tooltip**-nek hívják.

![Tooltip példa – egy gomb fölé helyezett kurzor rövid leírást mutat](../../screenshots/20b Tooltip System - cropped.png)

*Egy gomb fölé mozgatott kurzor rövid leírást mutat arról, mit csinál az adott gomb.*

Tooltipek az egész alkalmazásban elérhetők: a fülsor gombjain, a visszaszámláló részletes
nézetének műveleti gombjain, a snippet lista másolásgombjain, a léptető chevronokon és még
sok másutt. Ha nem tudod, mit csinál egy gomb, csak tartsd fölötte az egérmutatót egy
másodpercig, és a tooltip megjelenik.

---

## Tippek

- A Calculate nézetben mentett határidők függetlenek a visszaszámláló slotoktól —
  ezek a dátumkalkulátor referencia-időpontjai, nem élő időzítők.
- A Megjegyzések és a Snippet szerkesztők is támogatják a markdownt:
  fejlécek (`#`), listák (`-`), kódblokkök (` ``` `), táblázatok és kiemelés (`==szöveg==`).
- A hang csak a lejárat pillanatában szól — ha az alkalmazás nem fut, amikor a határidő
  lejár, a hang nem szólal meg visszamenőlegesen.
- A szabad slotok sorrendje megmarad az újraindítás után is.
- Egy **projekt** törlése a Snippets nézetben nem törli a snippeteket — azok átkerülnek
  a General projektbe. Egy egyes **snippet** törlése a szerkesztőben végleges.
- Az összes adat (visszaszámláló slotok, mentett határidők, snippetek, megjegyzések)
  helyileg van tárolva ezen a Macen. Nincs felhőszinkronizálás.
- Ha nem tudod, mit csinál egy gomb, tartsd fölötte az egérmutatót: egy tooltip rövid
  leírással jelenik meg.
