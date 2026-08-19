# A NightShift telepítése

## 1. lehetőség: Telepítés .dmg fájlból

1. Töltsd le a legújabb `.dmg` fájlt a [Releases](../../releases) oldalról.
2. Nyisd meg a `.dmg` fájlt.
3. Húzd a **NightShift.app** ikont az ablakban lévő **Applications** mappa parancsikonra.
4. Csatlakoztasd le a lemezképet.
5. Nyisd meg a NightShiftet az Applications mappából vagy a Spotlight kereséssel.

> **Első indításkor:** a macOS biztonsági figyelmeztetést jeleníthet meg, mert az app
> nem a Mac App Store-on keresztül kerül terjesztésre. A megnyitáshoz: jobb gombbal
> kattints az app ikonra → **Megnyitás** → **Megnyitás** a párbeszédablakban.
> Ezt csak egyszer kell megtenni.

## 2. lehetőség: Fordítás forrásból

### Előfeltételek

- macOS 13 Ventura vagy újabb
- Xcode 15 vagy újabb ([letöltés a Mac App Store-ból](https://apps.apple.com/app/xcode/id497799835))

### Lépések

1. Klónozd a repót:
   ```
   git clone https://github.com/ArrayOfLilly/NightShift.git
   cd NightShift/countdownApp
   ```

2. Nyisd meg a projektet Xcode-ban:
   ```
   open countdownApp.xcodeproj
   ```

3. Válaszd ki a `countdownApp` scheme-et és a saját Macet futtatási célként.

4. Nyomj **⌘R**-t a fordításhoz és futtatáshoz, vagy **⌘B**-t csak a fordításhoz.

Az app indítás után megjelenik a menüsorban. Nincs szükség további beállításra.

### Megjegyzések

- A naptáradatok (Kalkuláció fül) az első használatkor hálózati kapcsolatot igényelnek
  a helyzet koordinátáinak meghatározásához. Ezt követően az utolsó ismert pozíció
  gyorsítótárban marad.
- Minden adat (visszaszámlálók, határidők, gyorsszövegek) helyileg, a `UserDefaults`-ban
  tárolódik. Nincs fiók, nincs szinkronizálás, nincs felhő.
