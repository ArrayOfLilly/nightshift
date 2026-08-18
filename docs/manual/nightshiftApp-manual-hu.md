# NightShift — Felhasználói kézikönyv

A NightShift egy macOS alkalmazás két időpont közötti különbség kiszámításához,
visszaszámlálók kezeléséhez és újrafelhasználható szövegek tárolásához.
Az ablak tetején három fül érhető el.

---

## Fülsor

A fülsor az ablak tetején található. Az aktív fül mögött egy sötét teli kör jelzi
a kiválasztott nézetet.

| Ikon | Fül | Mire való |
|------|-----|-----------|
| Óra | **Calculate** | Két időpont közötti különbség kiszámítása |
| @ | **Countdown** | Visszaszámláló slotok listájának kezelése |
| Idézőjel | **Snippets** | Újrafelhasználható szövegek tárolása |

---

## Calculate

A Calculate pontosan kiszámítja a FROM és TO dátum közötti időkülönbséget.

![Calculate nézet – teljes nézet](../../screenshots/01 Calculate View - Calculated Days.png)

### Léptetők

Két léptetősor látható: **FROM** (kezdő) és **TO** (záró). Minden sor öt részből áll:
YEAR, MON, DAY, HOUR, MIN — mindegyiknek van egy felfelé és egy lefelé mutató gombja.

- **Egyetlen kattintás** egy lépéssel mozgatja az értéket.
- **Lenyomva tartás** rövid késleltetés után automatikusan ismétlődik, így gyorsan
  lehet navigálni.

Az alkalmazás minden indításkor visszatölti az utoljára beállított FROM és TO értékeket.

### Reset gombok

- **RESET FROM NOW** — a FROM időpontot az aktuális pillanatra állítja.
- **RESET TO NOW** — a TO időpontot az aktuális pillanatra állítja.

### Eredmény megjelenítése

A léptetők alatt az alkalmazás mutatja a két időpont különbségét. Egy váltógomb két
megjelenítési mód között vált:

- **DAYS** — a teljes különbség napokban (pl. „142 nap").
- **CAL** — naptár szerinti bontás: évek, hónapok és napok külön értékként.

A váltógomb állása megmarad az újraindítás után is.

<!-- group -->
![Calculate nézet – DAYS mód](../../screenshots/01 Calculate View - Calculated Days - cropped.png)
*Calculate nézet DAYS módban — az eredmény egyetlen összesített napszámként jelenik meg.*
![Calculate nézet – CAL mód](../../screenshots/01b Calculate View - Calculated Epochs - cropped.png)
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
![Határidő mentése – üres névmező](../../screenshots/02 Calculate View - Save Named Duration - empty - cropped.png)
*A mentési panel üres névmezővel nyílik meg. Írd be a nevet, majd kattints a SAVE gombra.*
![Határidő mentése – kitöltött névmező](../../screenshots/02b Calculate View - Save Named Duration - edit - cropped.png)
*A névmező kitöltve. A SAVE elmenti, a CANCEL bezárja a panelt mentés nélkül.*
<!-- /group -->

#### Mentett határidők megtekintése

Kattints a SAVE gomb jobb oldalán lévő **chevronra (▾)**. Megjelenik egy lista az összes
mentett határidővel.

- **Egy sorra kattintva** megnyílik a részletek panel.

![Mentett határidők listája](../../screenshots/03 Calculate View - Saved Named Durations - cropped.png)
*A határidők listája minden mentett elemet megmutat. Kattints bármelyik sorra a részletek megnyitásához.*

#### Részletek panel

A részletek panel a határidő nevét és dátumát mutatja. Innen a következőket teheted:

- **LOAD AS TO** — betölti a határidő dátumát a TO léptető mezőbe.
- **Ceruza ikon** — átnevezési mód: a név szerkeszthető mezővé válik. Írd be az új nevet,
  majd kattints a **RENAME** gombra a megerősítéshez, vagy a **CANCEL**-re az elvetéshez.
- **Kuka ikon** — véglegesen törli a határidőt. Megerősítő párbeszéd jelenik meg;
  kattints a **Delete** gombra a megerősítéshez vagy a **Cancel**-re a visszalépéshez.

![Határidő részletek panelje](../../screenshots/03b Calculate View - Saved Named Durations Details - cropped.png)
*A részletek panel mutatja a határidő nevét és dátumát. Elérhető: LOAD AS TO, átnevezés (ceruza) és törlés (kuka).*

<!-- group -->
![Határidő átnevezése](../../screenshots/03c Calculate View - Edit Saved Named Durations - cropped.png)
*Átnevezési mód: a név szerkeszthető szövegmezővé válik. Kattints a RENAME gombra vagy a CANCEL-re.*
![Határidő törlésének megerősítő párbeszéde](../../screenshots/03d Calculate View - Delete Saved Named Durations - cropped.png)
*Megerősítő párbeszéd jelenik meg a végleges törlés előtt.*
<!-- /group -->

---

### Nap- és holdadatok

A Calculate képernyő alján egy napikon gomb megnyit egy panelt az aktuális dátumra és
helyszínre vonatkozó csillagászati adatokkal. A panel a következőket mutatja:

- **Napkelte és napnyugta** időpontjai.
- **Aranyóra** ablakok (reggel és este).
- **Holdfázis** a fázis nevével és a megvilágítás százalékával.
- A jelenlegi holdciklus holdfázis-csíkja.

![Nap- és holdadatok panel](../../screenshots/04 Calculate View - Sun and Moon Data - cropped.png)
*A Nap & Hold panel megmutatja a mai napkeltét/napnyugtát, az aranyóra ablakait és az aktuális holdfázist.*

---

## Countdown

A Countdown nevesített visszaszámláló slotok listáját kezeli,
mindegyik egy adott határidőhöz kötve.

![Countdown nézet – teljes nézet](../../screenshots/05 CountDown View.png)

### A lista

A bejegyzések két csoportban jelennek meg:

- **Aktív bejegyzések** — a határidő a jövőben van. Növekvő sorrend a határidő szerint
  (leghamarabb lejáró legelöl). Borostyánszínű időzítővel jelenik meg.
- **Szabad slotok** — a határidő lejárt. Színes **FREE ✓** jelzővel jelennek meg.
  Húzással átrendezhetők a szabad slotok szekcióján belül.

<!-- group -->
![Countdown lista – aktív sor](../../screenshots/05 CountDown View - Cooldown - cropped.png)
*Egy aktív sor borostyánszínű élő időzítőt mutat; a sötét pill felirat bal oldalon.*
![Countdown lista – szabad slot](../../screenshots/05 CountDown View - Free Slot - cropped.png)
*A szabad slot színes FREE ✓ jelzőt mutat, és húzással átrendezhető.*
<!-- /group -->

![Countdown lista – határidő megjelenítési mód](../../screenshots/05d CountDown View - Deadline - cropped.png)
*A jobb oldali váltógomb határidő módra állt: a statikus célállapot dátuma jelenik meg az élő visszaszámlálás helyett.*

### Aktív sor

Az aktív sor bal oldalán egy sötét pill mutatja a bejegyzés nevét, jobb oldalán egy
váltógomb vált a következők között:

- **Hátralévő idő** — NN:ÓÓ:PP:MM élő visszaszámlálás.
- **Határidő dátuma** — statikus dátum ÉÉÉÉ.HH.NN ÓÓ:PP formátumban.

**A felirat másolása:** kattints a sötét pillre a felirat vágólapra másolásához.
A pill röviden „COPIED" feliratot mutat visszajelzésként.

**Jegyzetjelző:** ha egy slothoz tartozik jegyzet, egy kis szemikon jelenik meg a pill
feliratától jobbra. Az ikon eltűnik, amíg a „COPIED" felirat látszik.

![Countdown lista – sor jegyzetjelzővel](../../screenshots/05e CountDown View - Existing note - cropped.png)
*A narancs szemikon jelzi, hogy a slothoz tartozik jegyzet. Nyisd meg a részletek nézetet,
és kattints a Jegyzet gombra a megtekintéshez vagy szerkesztéshez.*

### Visszaszámláló hozzáadása

Kattints a lista alján lévő **+ ADD** gombra. Megnyílik egy panel egy felirat mezővel
és határidő léptetőkkel. Töltsd ki az adatokat, majd erősítsd meg a slot létrehozásához.

![Új elem hozzáadása panel](../../screenshots/06 Add New Item - cropped.png)
*A panel: adj meg egy feliratot és állítsd be a határidő dátumát, majd erősítsd meg a slot létrehozásához.*

### Visszaszámláló törlése

A listából kattints egy kártyára a részletes nézet megnyitásához, majd ott használd a
kuka gombot. Törlés előtt mindig megerősítő párbeszéd jelenik meg — kattints a **Delete**
gombra a megerősítéshez vagy a **Cancel**-re a visszalépéshez.

![Visszaszámláló slot törlésének megerősítő párbeszéde](../../screenshots/06b Delete Item - cropped.png)
*Megerősítő párbeszéd jelenik meg minden slot végleges törlése előtt.*

---

### Részletes nézet

Bármelyik kártyára kattintva megnyílik az adott bejegyzés teljes képernyős részletes nézete.

**Felirat szerkesztése:** kattints a felső nagy felirat szövegére az inline szerkesztéshez.
Nyomj Return-t vagy kattints el a megerősítéshez.

**Másolás gomb:** a felirat melletti dokumentumikon a feliratot a vágólapra másolja.

**Időmegjelenítés:** a visszaszámlálás vagy a határidő dátuma az illusztráció fölé kerül
a képernyő közepén.

**Váltó pill:** a képernyő alján lévő sötét pill gomb vált a *Hátralévő idő*
(NN:ÓÓ:PP:MM élő visszaszámlálás) és a *Határidő megjelenítése* (statikus dátum) között.

**Határidő léptető:** öt részből álló léptetők (YEAR, MON, DAY, HOUR, MIN) teszik
lehetővé a határidő módosítását. Lenyomva tartással gyorsan ismétlődik.
A változtatások automatikusan mentődnek.

<!-- group -->
![Részletes nézet – visszaszámlálás mód](../../screenshots/07 CountDown Detail View - Countdown - cropped.png)
*Részletes nézet visszaszámlálás módban: az élő hátralévő idő az illusztráció fölött látható.*
![Részletes nézet – határidő mód](../../screenshots/07b CountDown Detail View - Deadline - cropped.png)
*Részletes nézet határidő módban: a statikus célállapot dátuma jelenik meg.*
![Részletes nézet – lejárt (szabad) slot](../../screenshots/07c CountDown Detail View - Expired - cropped.png)
*Lejárt slot: a FREE állapot jelölve, és a színválasztó gomb aktívvá válik.*
<!-- /group -->

#### Műveleti gombok

Négy ikongomb jelenik meg egy sorban a részletes nézet alján:

| Gomb | Ikon | Mikor elérhető | Művelet |
|------|------|----------------|---------|
| Hang | Hangszóró | Mindig | Bekapcsol/kikapcsol egy rendszerhangot, amely a határidő lejártakor szól |
| Jegyzet | Jegyzet | Mindig | Megnyitja az adott slot Jegyzet szerkesztőjét |
| Szín | Ecset | Csak szabad slotoknál | Megnyitja a színválasztót |
| Törlés | Kuka | Mindig | Törli a slotot (megerősítés szükséges) |

#### Hangváltó

Ha be van kapcsolva (hanghullám ikon), az alkalmazás rendszerhangot játszik le a slot
határidejének lejártakor. Ha ki van kapcsolva (áthúzott hangszóró ikon), nincs hang.
A beállítás slotonként eltérő és megmarad az újraindítás után.

#### Színválasztó (csak szabad slotoknál)

A színválasztó panelen tizenkét ékezőszín és egy **AUTO** lehetőség látható.
Kattints bármelyik kockára a szabad slot kártyájára való alkalmazáshoz.
Az AUTO visszaállítja az alapértelmezett színt. A kiválasztás azonnal mentődik.

![Színválasztó panel](../../screenshots/08 CountDown Detail View - Color Picker - cropped.png)
*A színválasztó tizenkét színt és egy AUTO lehetőséget kínál. A kiválasztás azonnal érvénybe lép.*

#### Törlés

A kuka gomb véglegesen eltávolítja a slotot. Megerősítő párbeszéd jelenik meg;
kattints a **Delete** gombra a megerősítéshez vagy a **Cancel**-re a visszalépéshez.
A törlés nem vonható vissza.

---

### Jegyzetek

Minden visszaszámláló slothoz tartozik egy szabad formátumú szöveg-jegyzetek mező,
amely a részletes nézet Jegyzet gombjával érhető el.

A Jegyzetek panel alapértelmezés szerint **Megjelenítő módban** nyílik meg, amely a
tartalmat formázott markdownként jeleníti meg (fejlécek, listák, kódblokkok, táblázatok,
kiemelt szöveg).


#### Módok közötti váltás

A panel fejlécében lévő váltógomb két mód között vált:

- **Megjelenítő mód** — formázott markdown egy görgethető webnézetben.
- **Szerkesztő mód** — egyszerű szövegszerkesztő a markdown közvetlen írásához vagy szerkesztéséhez.

<!-- group -->
![Jegyzetpanel szerkesztő módban – egyszerű szöveges markdown szerkesztő](../../screenshots/09 CountDown Detail View - Note Editor - Editor View - cropped.png)
*Szerkesztő mód: írj vagy szerkessz nyers markdownt közvetlenül. A változtatások azonnal megjelennek Megjelenítő módban is.*
![Jegyzetpanel megjelenítő módban – renderelt markdown kimenet](../../screenshots/10 CountDown Detail View - Note Editor - Viewer View - cropped.png)
*Megjelenítő mód: a markdown fejlécekkel, listákkal, kódblokkokkal és kiemelt szöveggel renderelve jelenik meg.*
<!-- /group -->

#### Jegyzetek másolása

A **Másolás** gomb (mindkét módban elérhető) a nyers markdown szöveget a vágólapra másolja,
ahonnan közvetlenül beilleszthető egy AI asszisztensbe vagy bármely más alkalmazásba.

#### Jegyzetek törlése

A panel fejlécében lévő **kuka gomb** törli a teljes tartalmát.
Megerősítő párbeszéd jelenik meg; kattints a **Delete** gombra a megerősítéshez
vagy a **Cancel**-re a visszalépéshez.

<!-- group -->
![Törlés megerősítő párbeszéde](../../screenshots/11 CountDown Detail View - Note Editor - Confirm Delete - cropped.png)
*Megerősítő párbeszéd jelenik meg a tartalom végleges törlése előtt.*
![Üres jegyzetek panel helyőrzővel](../../screenshots/12 CountDown Detail View - Note Editor - Empty - cropped.png)
*Ha még nincs tartalom, egy helyőrző szöveg jelenik meg. Kattints rá, hogy rögtön szerkesztő módba ugorj.*
<!-- /group -->

#### Bezárás nem mentett változtatásokkal

Ha bezárod a panelt az **✕ gombbal**, miközben vannak nem mentett szerkesztések,
megerősítő párbeszéd jelenik meg:

- **Quit without saving** — elveti a változtatásokat és bezárja a panelt.
- **Save and quit** — elmenti az aktuális szöveget és bezárja.
- **Cancel** — visszatér a panelhez bezárás nélkül.

![Nem mentett változtatások megerősítő párbeszéde](../../screenshots/11b CountDown Detail View - Note Editor - Confirm Exit - cropped.png)
*A párbeszéd csak akkor jelenik meg, ha vannak nem mentett változtatások. Egy már mentett panelt az ✕ azonnal bezár.*

---

## Snippets

A Snippets fül egy önálló gyorsszöveg-könyvtár, független a visszaszámláló slotoktól.
A gyorsszövegek projekt szerint csoportosulnak.

![Snippets nézet – teljes nézet](../../screenshots/13 Snippets View - Rows.png)

### A lista

A gyorsszövegek projekt szerint, ábécésorrendben csoportosulnak. Minden sor a gyorsszöveg
címét és a tartalom rövid előzetesét mutatja. A sor jobb oldalán lévő **Másolás** gomb
a teljes tartalmat azonnal a vágólapra másolja, a szerkesztőlap megnyitása nélkül.

Kattints egy sorra a gyorsszöveg szerkesztőlapban való megnyitásához.

Kattints az eszköztár **+ gombjára** új gyorsszöveg létrehozásához.

![Snippets lista – sor a címmel, előzetesssel és Másolás gombbal](../../screenshots/13b Snippets View - Row - cropped.png)
*Minden sor megjeleníti a címet, a tartalom előzetesét és a Másolás gombot.*

### Gyorsszöveg-szerkesztő lap

A szerkesztőlap fejlécében lévő gombbal két mód között lehet váltani:

- **Megjelenítő mód** — a gyorsszöveg törzsét formázott markdownként jeleníti meg.
- **Szerkesztő mód** — egyszerű szövegszerkesztő a markdown közvetlen írásához.

A fejléc ezenkívül tartalmaz:

- **Másolás** — a nyers markdown törzset a vágólapra másolja.
- **Törlés** — megerősítés után véglegesen törli a gyorsszöveget.

<!-- group -->
![Gyorsszöveg-szerkesztő megjelenítő módban – renderelt markdown](../../screenshots/14 Snippet Edtor - Viewer - cropped.png)
*Megjelenítő mód: a gyorsszöveg törzsét formázott markdownként jeleníti meg — fejlécek, listák, kódblokkok és egyéb elemekkel.*
![Gyorsszöveg-szerkesztő szerkesztő módban – egyszerű szöveges markdown szerkesztő](../../screenshots/15 Snippet Edtor - Editor - cropped.png)
*Szerkesztő mód: a cím, a projekt és a törzs közvetlenül szerkeszthető. A törzsmező teljes markdownt támogat.*
<!-- /group -->

#### Mezők

| Mező | Leírás |
|------|--------|
| Cím | A gyorsszöveg rövid neve |
| Projekt | A listában csoportosítja a gyorsszöveget; kattints a projektválasztó megnyitásához |
| Törzs | A gyorsszöveg tartalma (markdown támogatott) |

#### Projektválasztó

A projekt mezőre kattintva legördülő lista jelenik meg a meglévő projektnevekkel.
Válassz egy meglévő projektet a gyorsszöveg hozzárendeléséhez, vagy írj be egy új nevet
egy új projektcsoport létrehozásához.

#### Az Általános csoport

Minden projekt nélküli gyorsszöveg az **Általános** csoportba kerül.
Az Általános mindig utoljára jelenik meg, az összes nevesített projektcsoport után.
Nem nevezhető át és nem törölhető — ez egy állandó gyűjtőcsoport a besorolatlan
gyorsszövegek számára.
Egy nevesített projektcsoport törlésekor az ahhoz tartozó összes gyorsszöveg automatikusan
az Általános csoportba kerül.

#### Helyi menü (gyorsszöveg sorok)

Hosszú lenyomással vagy jobb egérgombbal kattintva egy gyorsszöveg soron helyi menü
nyílik meg gyorsműveletekkel, köztük átnevezéssel és törléssel.

<!-- group -->
![Projektválasztó legördülő lista – meglévő projektnevek](../../screenshots/16 Snippet Edtor - Projectname choser Dropdown List - cropped.png)
*A projektválasztó az összes meglévő projektnevet mutatja. Válassz egyet, vagy írj be új nevet egy csoport létrehozásához.*
![Gyorsszöveg sor helyi menüje – gyorsműveletek](../../screenshots/16b Snippets View - Project Editing Context Menu - cropped.png)
*Jobb egérgombbal kattintva vagy hosszan lenyomva egy sort helyi menü nyílik meg gyorsműveletekkel.*
<!-- /group -->

#### Gyorsszöveg törlése

A szerkesztőlap fejlécében lévő **Törlés** gomb megerősítés után véglegesen törli
a gyorsszöveget.

![Gyorsszöveg törlésének megerősítő párbeszéde](../../screenshots/17 Snippet Edtor - Delete - cropped.png)
*Megerősítő párbeszéd jelenik meg a gyorsszöveg végleges törlése előtt.*

#### Bezárás nem mentett változtatásokkal

Ha bezárod a szerkesztőlapot az **✕ gombbal**, miközben vannak nem mentett szerkesztések,
megerősítő párbeszéd jelenik meg:

- **Quit without saving** — elveti a változtatásokat és bezárja a szerkesztőt.
- **Save and quit** — elmenti és bezárja.
- **Cancel** — visszatér a szerkesztőhöz.

![Gyorsszöveg-szerkesztő – nem mentett változtatások megerősítő párbeszéde](../../screenshots/17 Snippet Edtor - Exit - cropped.png)
*A párbeszéd csak akkor jelenik meg, ha vannak nem mentett változtatások. Egy már mentett szerkesztőt az ✕ azonnal bezár.*

---

## Adathelyreállítás

Ha az alkalmazás indításkor azt észleli, hogy egyes tárolt adatok nem tölthetők be —
például mert egy fájl sérült, vagy inkompatibilis formátumban lett elmentve — egy
helyreállítási sáv jelenik meg az érintett fül tetején.

### Helyreállítási sáv

A sáv mindhárom fülön egymástól függetlenül jelenik meg: minden fül csak akkor mutatja,
ha a saját adatkészlete ütközött problémába. A sáv megjeleníti a be nem töltött elemek
számát, és két műveletet kínál.

![Helyreállítási sáv – 3 elem nem tölthető be](../../screenshots/18c Snippets View - Corrupted Data Warning - cropped.png)
*„3 ELEM NEM TÖLTHETŐ BE" — a sáv az érintett fül tetején jelenik meg Nyers adatok másolása és Elvetés gombokkal.*

### Nyers adatok másolása

Kattints a **Nyers adatok másolása** gombra az olvashatatlan elemek nyers JSON-jának
vágólapra másolásához. Az adatok szép formázott JSON-ként kerülnek a vágólapra,
így ellenőrizhetők vagy továbbíthatók a támogatásnak.
Ez a művelet nem zárja be a sávot.

### Elvetés

Kattints az **Elvetés** gombra a sáv eltávolításához. Az olvashatatlan elemek törlődnek
a helyreállítási pufferből. Ha az alkalmazás egy következő indításkor újabb adatsérülést
észlel, a sáv újra megjelenik.

> **Megjegyzés:** A helyreállítási sávban megjelenő elemek nem töltődtek be az
> alkalmazásba — nem láthatók a listában, és adataik nem aktívak. A sáv elvetése a
> nyers adatok vágólapra másolása után biztonságos; a vágólapon lévő másolat az egyetlen
> megmaradt hivatkozás ezekre az elemekre.

---

## Beállítások

Nyisd meg a Beállításokat a **Cmd+,** billentyűkombinációval vagy a NightShift menün
keresztül. Két fül érhető el.

### Nyelv

![Beállítások – Nyelv fül](../../screenshots/21 Settings View - Languages.png)
*A Nyelv fül: Felület nyelve és Dátum- és számformátum választók.*

- **Felület nyelve** — beállítja az alkalmazás megjelenítési nyelvét. Válaszd a
  *Rendszer alapértelmezett* lehetőséget a macOS követéséhez, vagy válaszd az
  *English* vagy *Magyar* lehetőséget explicit módon.
- **Dátum- és számformátum** — szabályozza, hogyan jelennek meg a dátumok és számok
  az alkalmazásban. Válassz a *Rendszer alapértelmezett*, *English (US)* vagy
  *Magyar (HU)* lehetőségek közül.

Mindkét beállítás újraindítást igényel a változtatás érvénybe lépéséhez. Egy tájékoztató
megjegyzés jelenik meg a fülön, amint bármelyik választó az alapértelmezettől eltér.

### Megjelenés

![Beállítások – Megjelenés fül](../../screenshots/21b Settings View - Fontsize.png)
*A Megjelenés fül: Betűméret szegmens vezérlő.*

- **Betűméret** — szabályozza a szöveg méretét az egész alkalmazásban. Négy fokozat
  érhető el: *Alapértelmezett*, *Nagy*, *Nagyobb*, *Legnagyobb*. A változtatás azonnal
  érvénybe lép, újraindítás nem szükséges.

---

## Tippek

- A Calculate módban mentett határidők függetlenek a visszaszámláló slotoktól —
  a dátumkalkulátor referencia-pontjai, nem élő időzítők.
- A Jegyzet és a Gyorsszöveg szerkesztők egyaránt támogatják a markdownt: fejlécek (`#`),
  listák (`-`), kódblokkok (` ``` `), táblázatok és kiemelt szöveg (`==szöveg==`).
- A hang csak a lejárat pillanatában szól — ha az alkalmazás nem fut, amikor a határidő
  lejár, a hang visszamenőlegesen nem szólal meg.
- A szabad slotok sorrendje újraindítás után is megmarad.
- Minden adat (visszaszámláló slotok, mentett határidők, gyorsszövegek, jegyzetek)
  helyileg, ezen a Mac-en kerül tárolásra a UserDefaults segítségével.
  Nincs felhő-szinkronizáció.
