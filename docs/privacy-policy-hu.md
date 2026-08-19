# NightShift — Adatvédelmi nyilatkozat

## Az adataid védelme fontos

A NightShift egy teljesen helyi alkalmazás. Nem hoz létre fiókokat, nem szinkronizál
felhőszolgáltatással, és nem gyűjt személyes adatokat.

---

## A Macen tárolt adatok

Az alkalmazás összes adata kizárólag az eszközödön tárolódik, UserDefaults és helyi JSON
fájlok formájában. A következő adatok kerülnek mentésre:

- AI-fiók slotok nevei és visszaállítási ideje
- Az általad létrehozott elnevezett határidők
- Gyorsszövegek nevei és tartalma
- Helyszín koordináták a napfelkelte/naplement számításhoz (kézzel megadott, nem GPS)
- Alkalmazásbeállítások (nyelv, betűméret, téma)

---

## Hálózati hozzáférés

A NightShift évente egyszer küld hálózati kérést a sunrisesunset.io szolgáltatásnak,
hogy lekérje a napfelkelte/naplement adatokat a beállított helyszínre. Csak a
Beállításokban megadott koordináták kerülnek elküldésre — nincs eszközazonosító,
az alkalmazás nem naplóz IP-t. Az eredmény helyben gyorsítótárazódik; a következő
évig nem történik újabb kérés.

---

## Nincs követés vagy analitika

A NightShift nem tartalmaz analitikai SDK-t, összeomlásjelentőt, telemetriát vagy
reklámkeretrendszert. Az alkalmazás használata teljesen privát.

---

## Kérdések

Ha kérdéseid vannak ezzel az adatvédelmi nyilatkozattal kapcsolatban, írj:
[arrayoflilly@gmail.com](mailto:arrayoflilly@gmail.com)

---

*Utoljára frissítve: 2026*
