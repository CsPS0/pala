# Changelog

Ez a fájl a Pala kiadásainak jelentősebb változásait követi.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) elvein alapul.

## [Nem kiadott]

### Hozzáadva
- Kísérleti iPhone-os változat: a kiadás egy aláíratlan `Pala.ipa` fájlt is tartalmaz, amelyet a felhasználó a saját ingyenes Apple ID-jével tesz fel (AltStore vagy Sideloadly). Útmutató a weboldal Telepítés → iOS fülén. Az ötletet Pacuka ([pacuka.hu](https://pacuka.hu/)) adta.

## [2.0.0] - 2026-10-31

Az első kiadás a Pala néven: TUI, asztali és Android-alkalmazás, böngésző-kiterjesztés.

### Hozzáadva
- CI workflow (`ci.yml`): `dart analyze` + `dart test` a CLI-hez, `flutter analyze` a Desktop App-hoz, minden push/PR esetén.
- Alap teszt lefedettség a `lib/models/` réteghez (`test/models_test.dart`).
- `CHANGELOG.md` bevezetése.
- Bejelentkezés CAPTCHA-val vagy kétlépcsős azonosítással védett Kréta fiókkal: a Pala felismeri a további ellenőrzési lépést, és a Kréta saját oldalára irányít (telefonon és macOS-en beépített ablakban, Windowson, Linuxon, a TUI-ban és a Webes Felületen böngészőben, a kapott kód beillesztésével).

### Javítva
- CAPTCHA vagy kétlépcsős azonosítás esetén a TUI korábban "Hibás adatok" hibát írt ki, vagy csendben offline módba lépett.
- A macOS alkalmazás megkapta a kimenő hálózati jogosultságot (`com.apple.security.network.client`), amely nélkül nem érte el a Kréta szervereit.
- A bejelentkezési folyamat (`lib/api/client.dart`) többé nem omlik össze null-check hibával, ha a Kréta IDP váratlan válaszfejlécet küld — helyette hibaüzenetet ír ki és leállítja a folyamatot.
- `SECURITY.md` és `docs/DATA_SECURITY.md` javított, a kódbázissal már nem egyező állítások (verziószám, titkosítási kulcs származtatása) frissítve.
- A Windows telepítő (`packaging/windows/pala_installer.iss`) verziószáma mostantól automatikusan frissül a kiadási CI folyamat részeként, a Scoop/Homebrew/AUR csomagokhoz hasonlóan.
- Offline módban a tantárgyi átlagok többé nem írják felül a mentett jegyeket.
- A félévi és az év végi jegyek nem számítanak bele az átlagba (asztali app, kiterjesztés).
- Az üzenetküldés ismeretlen címzettnél hibát ad, és nem küld el semmit.
- A kiterjesztés Wrapped összefoglalója valós átlagot és darabszámot mutat.
- A Kréta túlterhelésekor (429) a kiterjesztés megtartja a mentett adatokat.
- Kijelentkezéskor az asztali app és a kiterjesztés visszavonja a Kréta-munkamenetet; a kiterjesztés a profilt is törli.
- A heti órarend-léptetés az óraátállításkor sem csúszik el.
- A helyi webes felület és az asztali értesítések biztonsági javításokat kaptak.
- A dokumentáció eltávolító parancsai a valódi adatmappákra mutatnak, a Homebrew-telepítés a `brew tap` lépéssel indul.
- A kiterjesztés demóadatai csak kitalált neveket használnak.
- A kiadási folyamat a csomagkezelők frissítése után teszi közzé az AUR-csomagot; a GitHub Actions lépések rögzített verzión futnak.
- Minden kiadás mellé `SHA256SUMS` fájl kerül, és a telepítők ellenőrzik vele a letöltött fájlokat. A telepítők hiba esetén nem írnak ki sikert, és nem másolnak programot a munkakönyvtárból.
- Az intézménykódot minden belépési ponton ellenőrzi a Pala; a kiterjesztés nem használ beégetett tartalék iskolát.
- A `-p/--password` kapcsoló figyelmeztet, a jelszó a `PALA_PASSWORD` környezeti változóban is megadható.
- A bejelentkezés csak valódi hálózati hibánál vált offline módra.
- A kiterjesztés megkülönbözteti a lejárt belépést, a hiányzó internetet és a Kréta kiesését, és lejárt belépésnél a belépéshez vezet. Nem kér `tabs` jogot.
- Olvashatóak a jegyszínek az asztali app és a TUI világos témájában.
- A kiterjesztés tervezője 4,0 feletti átlagnál is helyes számot ír, az oldalpanel az „igazolandó” mulasztást nem számolja igazoltnak, és látszik a billentyűzetfókusz.
- A számonkérések `.ics` exportja a helyi napot használja.
- A weboldal letöltőgombja a grafikus telepítőt adja, az adatvédelmi oldal pontosabb, a rejtett fejléc nem kap fókuszt.
- Minden kliens ugyanúgy számolja az átlagot és a mulasztásokat: az összesített átlag a tantárgyi átlagok átlaga, a 0%-os jegy nem számít, a késés nem számít bele a 250 órába, az „igazolandó” külön látszik. A szabályokat közös tesztvektorok ellenőrzik Dartban és a kiterjesztésben is.
- A késések perceit a Pala a Kréta valódi mezőjéből (`KesesPercben`) olvassa.
- A kiterjesztés első indításkor belépést kínál a demóadatok helyett; a demó külön választható. Az iskolaválasztó billentyűzettel is használható.
- A kiterjesztés követi a rendszer sötét/világos témáját, tiszteletben tartja a csökkentett mozgást, a legkisebb betűméret 12 px, és a képernyőolvasók is értik a füleket és az állapotot.
- A weboldal a kiadásadatot építéskor kéri le, a látogató böngészője nem fordul a GitHubhoz. A dokumentáció oldalai megoszthatók, a Vissza gomb működik, és a tartalomjegyzék minden pontja működik.
- A helyi webes felület szigorúbb biztonsági fejlécet kap, és a Kréta-adat nem kerül szkriptkódba.
- Linuxon és macOS-en a beállítás- és gyorsítótár-mappát csak a saját felhasználód olvashatja. A `DATA_SECURITY.md` pontosabban írja le, mit véd a titkosítás.
- Egy CSV- és egy `.ics`-író van nyelvenként: pontosvessző, BOM, helyi dátum, szabályos sorvég és sortördelés.
- A CI a Flutter-teszteket, a kiterjesztés tesztjeit és a weboldal buildjét is futtatja.

## [1.2.3]
- Pala rebrand: TUI, Flutter Desktop App, böngésző-kiterjesztés (Manifest V3) és weboldal egy kiadás alatt.
- OAuth2 web-login folyamat CSRF `state` védelemmel a böngésző-kiterjesztésben.
- Titkosítási kulcs származtatás lecserélve véletlenszerű, telepítésenkénti kulcsfájlra.
- Kréta API kérés-korlátozás (jitter, backoff, cache fallback) bevezetve az anti-abuse védelem elkerülésére.
