# Changelog

Ez a fájl a Pala kiadásainak jelentősebb változásait követi.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) elvein alapul.

## [Nem kiadott]

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

## [1.2.3]
- Pala rebrand: TUI, Flutter Desktop App, böngésző-kiterjesztés (Manifest V3) és weboldal egy kiadás alatt.
- OAuth2 web-login folyamat CSRF `state` védelemmel a böngésző-kiterjesztésben.
- Titkosítási kulcs származtatás lecserélve véletlenszerű, telepítésenkénti kulcsfájlra.
- Kréta API kérés-korlátozás (jitter, backoff, cache fallback) bevezetve az anti-abuse védelem elkerülésére.
