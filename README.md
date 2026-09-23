<h1 align="left">
<img src="assets/icons/pala.svg" alt="Pala icon" width="30px" style="vertical-align: middle;">
<span style="vertical-align: middle;">Pala</span>
</h1>

[![License: MIT](https://img.shields.io/github/license/CsPS0/pala?color=yellow)](LICENSE)
[![Release](https://img.shields.io/github/v/release/CsPS0/pala)](https://github.com/CsPS0/pala/releases)
[![CI](https://github.com/CsPS0/pala/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/CsPS0/pala/actions/workflows/ci.yml)

A **Pala** ingyenes, nyílt forráskódú kliens a Kréta e-naplóhoz. Gyorsan és reklámok nélkül mutatja meg a jegyeidet, az órarendedet, a hiányzásaidat, a házi feladataidat és az üzeneteidet, három formában:

- **Terminálos alkalmazás (TUI)**: Windows, Linux, macOS és Android (Termux)
- **Asztali alkalmazás**: grafikus felület Windowsra, Linuxra és macOS-re
- **Böngésző-kiterjesztés**: Chrome, Brave és Edge

Weboldal: [pala-app.hu](https://pala-app.hu)

## Mit tud?

- **Élő dashboard**: visszaszámlálás az óra vagy a szünet végéig, mai órarend, helyettesítések és elmaradt órák.
- **Jegyek és átlagok**: tantárgyi és osztályátlagok, jegy-trendek, Szellem jegy kalkulátor és Bizonyítvány tervező.
- **Hiányzások**: igazolt, igazolandó és igazolatlan órák, valamint a 250 órás keret figyelése.
- **Kereső**: ékezet-érzéketlen keresés a jegyek, órák, feladatok, üzenetek és hiányzások között.
- **Pala Wrapped**: éves statisztika a tanévedről.
- **Export**: naptár (`.ics`) és táblázat (CSV).
- **Demó mód**: kipróbálható bejelentkezés nélkül, fiktív adatokkal.

A böngésző-kiterjesztés ezen felül a háttérben megújítja a Kréta munkamenetet, így 40-60 perc után sem léptet ki. Az összes funkció részletesen: [Felhasználói kézikönyv](docs/USER.md).

## Telepítés

> [!WARNING]
> Az első `pala` kiadás még nem jelent meg, ezért a csomagkezelős és az egysoros telepítők egyelőre nem működnek: sikeres telepítést írnak ki, de a letöltés 404-es hibát ad ([#2](https://github.com/CsPS0/pala/issues/2)). Addig csak a forráskódból fordítás használható.

### Forráskódból

Szükséges a [Dart SDK](https://dart.dev/get-dart), az asztali alkalmazáshoz a [Flutter SDK](https://flutter.dev) is.

```bash
git clone https://github.com/CsPS0/pala.git
cd pala
dart pub get
dart compile exe bin/pala.dart -o pala    # terminálos alkalmazás
cd app && flutter build windows           # asztali alkalmazás (vagy: linux, macos)
```

### Android (Termux)

A terminálos alkalmazás APK és root jog nélkül fut a [Termux](https://termux.dev/) alatt:

```bash
pkg update && pkg install dart git -y
git clone https://github.com/CsPS0/pala.git
cd pala
dart pub get
dart run bin/pala.dart
```

Gyorsabb indításhoz lefordíthatod natívan is: `dart compile exe bin/pala.dart -o pala`, majd `./pala`.

### Böngésző-kiterjesztés

1. Töltsd le a kiterjesztést a [pala-app.hu](https://pala-app.hu) oldalról és csomagold ki, vagy használd a repó `extension/` mappáját.
2. Nyisd meg a `chrome://extensions` (Edge alatt `edge://extensions`) oldalt, és kapcsold be a Fejlesztői módot.
3. Kattints a „Kicsomagolt betöltése” gombra, és válaszd ki a mappát.

### Telepítők (az első kiadástól)

<details>
<summary>Windows, Linux, macOS és csomagkezelők</summary>

**Windows**

- Grafikus telepítő: [Pala-Setup.exe](https://github.com/CsPS0/pala/releases/latest) (asztali alkalmazás, terminálos alkalmazás és PATH, választhatóan)
- PowerShell:
  ```powershell
  irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex
  ```
- Scoop:
  ```powershell
  scoop bucket add pala https://github.com/CsPS0/pala-bucket
  scoop install pala
  ```

**Linux és macOS**

- Egysoros telepítő:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash
  ```
- Debian / Ubuntu / Linux Mint (APT):
  ```bash
  curl -fsSL https://CsPS0.github.io/pala/public.key | sudo gpg --dearmor -o /usr/share/keyrings/pala-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/pala-archive-keyring.gpg] https://CsPS0.github.io/pala/repo stable main" | sudo tee /etc/apt/sources.list.d/pala.list > /dev/null
  sudo apt update
  sudo apt install pala
  ```
- Arch Linux (AUR):
  ```bash
  yay -S pala-bin
  ```
- macOS (Homebrew):
  ```bash
  brew tap CsPS0/pala https://github.com/CsPS0/pala
  brew install pala
  ```

</details>

## Használat

```bash
pala              # terminálos felület
pala --desktop    # asztali alkalmazás (röviden: pala -g)
pala dash         # közvetlenül az élő dashboard
pala --demo       # demó profil (Teszt Elek), bejelentkezés nélkül
pala --daemon     # háttérfolyamat az értesítésekhez
pala --help       # az összes kapcsoló
```

A parancsikonok, a PATH, a gyorsítótár törlése és az eltávolítás a [Felhasználói kézikönyvben](docs/USER.md) található.

## Adatvédelem

A Pala csak a hivatalos Kréta szerverekkel kommunikál, és frissítések ellenőrzéséhez a GitHubbal. Az adataid a saját gépeden maradnak, a bejelentkezési tokenek titkosítva, telemetria és analitika nélkül.

- [Adatkezelés és biztonság](docs/DATA_SECURITY.md): mit, hol és hogyan tárol a Pala, és hogyan törölheted.
- [Adatvédelmi szabályzat](docs/PRIVACY_POLICY.md)
- Biztonsági hibát találtál? Lásd: [SECURITY.md](SECURITY.md).

## Fejlesztés és hozzájárulás

- [Fejlesztői dokumentáció](docs/DEV.md): architektúra, build és a Kréta API sajátosságai.
- [Hozzájárulási irányelvek](CONTRIBUTING.md) és [Magatartási kódex](CODE_OF_CONDUCT.md).
- [Kiadási napló](CHANGELOG.md).

### AI használat

A Pala fejlesztése során AI-alapú kódolóasszisztenseket is használok, és ezt nem titkolom. Ez nem megy a minőség rovására: minden változtatást átnézek, és a kiadások előtt ugyanazok az ellenőrzések futnak (elemzés, tesztek, build), mint bármely más kódnál. Az alkalmazás ettől függetlenül ingyenes és szabadon használható marad. A hozzájárulókra vonatkozó elvárások a [CONTRIBUTING.md](CONTRIBUTING.md) fájlban találhatók.

## Elismerések

Köszönet minden felhasznált nyílt forráskódú csomagnak, és a hasonló célú projekteknek, amelyek inspirációt adtak:

- **Aktív projektek**: [Firka](https://github.com/QwIT-Development/firka), [app-legacy (refilc)](https://github.com/QwIT-Development/app-legacy), [firka-extension](https://github.com/QwIT-Development/firka-extension), [Folio](https://github.com/Zan1456/folio), [folio-extension](https://github.com/Zan1456/folio-extension), [RozsdásFilc (rsfilc)](https://github.com/jarjk/rsfilc), [Toll](https://github.com/doomhyena/toll)
- **Archivált projektek**: [Filc](https://github.com/filc/filc), [Szivacs-Naplo](https://github.com/boapps/Szivacs-Naplo)

A felsorolt projektek egy része eltérő licenc (pl. GPL) alatt áll. A Pala a nyilvánosan dokumentált e-Kréta API alapján, ezektől függetlenül készült, és egyikükből sem vett át kódot.

## Licenc

MIT, lásd: [LICENSE](LICENSE).
