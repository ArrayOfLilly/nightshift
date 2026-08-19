# NightShift

macOS menubar alkalmazás fejlesztőknek, akik éjjel dolgoznak mellékes projekteken — ingyenes eszközökkel.

## Miért csináltam

Mellékes projekteken dolgozom éjszaka, a nappali munka után, ingyenes AI-fiókok segítségével
(Claude, ChatGPT, Codex, DeepSeek, Qwen, Kimi és mások). A korlátok valósak: minden fióknak
van egy visszatöltési ideje, és amikor hajnalodik, aludni kell — ez nem javaslat, hanem kemény
határ.

A NightShift az az eszköz, amit ehhez a munkarendhez csináltam. Három fül, egy cél: legyen
produktív az éjszaka, és tudd, mikor kell megállni.

## Mit csinál

**Időzítő fül** — nyilvántartja, mikor lesz újra elérhető az egyes AI-fiókok. Nem általános
visszaszámláló-lista: minden sor egy konkrét szolgáltatás a saját visszatöltési idejével.
Ha a visszaszámláló nullára ér, az a fiók újra szabad.

**Kalkuláció fül** — megmutatja, mennyi idő van még napkelteig a helyed szerint. Ez az app
magja: a napkelte az éjszakai munka határideje. Ide menthetők névvel ellátott határidők
(projekt-mérföldkövek, önként vállalt célok), és összehasonlíthatók a maradék időablakkal.

**Gyorsszövegek fül** — session-átadó feljegyzéseket tárol. Ha AI-sessionök között váltasz,
vagy a következő éjszaka folytatod, ahol abbahagytad: itt él a kontextus — mi történt, mi
a következő lépés, melyik fájlok vannak nyitva.

Az egyes visszaszámláló-elemekhez fűzött jegyzetek lehetővé teszik a feladat közbeni
kontextus rögzítését fülváltás nélkül — gyors emlékeztető arról, hol tartottál, amikor
egy visszatöltési idő félbeszakította a munkát.

## Követelmények

- macOS 13 Ventura vagy újabb
- Xcode 15 vagy újabb (forrásból való fordításhoz)

## Telepítés

Lásd az [install-hu.md](install-hu.md) fájlt a forrásból való fordítás és a .dmg-telepítés leírásához.

## Licenc

Személyes használatra. Garancia nélkül.
