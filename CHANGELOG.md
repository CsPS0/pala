# Changelog

Ez a fájl a Pala kiadásainak jelentősebb változásait követi.
A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) elvein alapul.

## [Nem kiadott]

### Hozzáadva
- CI workflow (`ci.yml`): `dart analyze` + `dart test` a CLI-hez, `flutter analyze` a Desktop App-hoz, minden push/PR esetén.
- Alap teszt lefedettség a `lib/models/` réteghez (`test/models_test.dart`).
- `CHANGELOG.md` bevezetése.

### Javítva
- A bejelentkezési folyamat (`lib/api/client.dart`) többé nem omlik össze null-check hibával, ha a Kréta IDP váratlan válaszfejlécet küld — helyette hibaüzenetet ír ki és leállítja a folyamatot.
- `SECURITY.md` és `docs/DATA_SECURITY.md` javított, a kódbázissal már nem egyező állítások (verziószám, titkosítási kulcs származtatása) frissítve.
- A Windows telepítő (`packaging/windows/pala_installer.iss`) verziószáma mostantól automatikusan frissül a kiadási CI folyamat részeként, a Scoop/Homebrew/AUR csomagokhoz hasonlóan.

## [1.2.3]
- Pala rebrand: TUI, Flutter Desktop App, böngésző-kiterjesztés (Manifest V3) és weboldal egy kiadás alatt.
- OAuth2 web-login folyamat CSRF `state` védelemmel a böngésző-kiterjesztésben.
- Titkosítási kulcs származtatás lecserélve véletlenszerű, telepítésenkénti kulcsfájlra.
- Kréta API kérés-korlátozás (jitter, backoff, cache fallback) bevezetve az anti-abuse védelem elkerülésére.
