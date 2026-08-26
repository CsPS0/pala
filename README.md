<h1 align="left">
<img src="pala.svg" alt="Pala icon" width="30px" style="vertical-align: middle;">
<span style="vertical-align: middle;">Pala</span>
</h1>
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Release](https://img.shields.io/github/v/release/CsPS0/pala)](https://github.com/CsPS0/pala/releases)
[![Build Status](https://github.com/CsPS0/pala/actions/workflows/release.yml/badge.svg)](https://github.com/CsPS0/pala/actions)

A **Pala** egy interaktív terminálos felhasználói felület (TUI) a Kréta e-napló rendszerhez. Az iOS alkalmazás OAuth2 hitelesítési folyamatait szimulálva közvetlen, gyors és látványos terminálos hozzáférést biztosít a diákok adatlapjához, jegyeihez, órarendjéhez és hiányzásaihoz.

## Főbb funkciók
- **Élő Dashboard (TUI felület)**
- **Pala Wrapped (Éves statisztika)**
- **Bizonyítvány Tervező & Szellem Jegyek**
- **Jegy-trendek & Átlagok**
- **Globális Haladó Kereső**
- *...és még több!*

## Telepítés

### 1. Windows Gyors Telepítés
- **Grafikus telepítő (.exe)**: Töltsd le a [Pala-Setup.exe](https://github.com/CsPS0/pala/releases/latest) fájlt (egyéni komponensválasztóval: Desktop GUI + CLI / TUI + PATH integráció).
- **PowerShell 1-soros**:
  ```powershell
  irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex
  ```
- **Scoop**:
  ```powershell
  scoop bucket add pala https://github.com/CsPS0/pala-bucket
  scoop install pala
  ```

### 2. Linux & macOS Gyors Telepítés
- **Interaktív 1-soros telepítő (Bash)**:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash
  ```

Ha manuálisan szeretnéd telepíteni vagy saját csomagkezelőt használsz:

   <details>
   <summary>Debian / Ubuntu / Linux Mint (APT)</summary>

> ```bash
> curl -fsSL https://CsPS0.github.io/pala/public.key | sudo gpg --dearmor -o /usr/share/keyrings/pala-archive-keyring.gpg
>
> echo "deb [signed-by=/usr/share/keyrings/pala-archive-keyring.gpg] https://CsPS0.github.io/pala/repo stable main" | sudo tee /etc/apt/sources.list.d/pala.list > /dev/null
>
> sudo apt update
> sudo apt install pala
> ```

   </details>

   <details>
   <summary>Arch Linux (AUR)</summary>

> ```bash
> yay -S pala-bin
> ```

   </details>

   <details>
   <summary>macOS (Homebrew)</summary>

> ```bash
> brew tap CsPS0/pala https://github.com/CsPS0/pala
> brew install pala
> ```

   </details>

   <details>
   <summary>Forráskódból történő fordítás</summary>

> [Dart SDK](https://dart.dev/get-dart) és [Flutter SDK](https://flutter.dev) szükséges.
> ```bash
> git clone https://github.com/CsPS0/pala.git
> cd pala
> dart pub get
> dart compile exe bin/pala.dart -o pala
> cd app && flutter build windows  # vagy linux / macos
> ```

   </details>

## Használat
A telepítés után a Pala közvetlenül indítható terminálból és a Start menüből:
```bash
pala
```

**Fő parancsok és kapcsolók:**
- `pala` : Interaktív terminálos TUI felület indítása.
- `pala --desktop` vagy `pala -g` : Pala Asztali Grafikus Alkalmazás (Desktop GUI) indítása.
- `pala dash` : Közvetlen belépés az Élő Dashboard nézetbe.
- `pala --demo` : Indítás beépített demó profillal (**Teszt Elek** - offline tesztadatok).
- `pala --daemon` : Háttérfolyamat indítása értesítésekhez.

**Komponens kezelés és rendszerintegráció:**
- `pala --install-shortcut` : Start menü és asztali parancsikon létrehozása.
- `pala --remove-shortcut` : Start menü és asztali parancsikonok eltávolítása.
- `pala --add-path` : Pala hozzáadása a felhasználói PATH környezeti változóhoz.
- `pala --remove-path` : Pala eltávolítása a PATH-ból.
- `pala --clear-cache` : Helyi gyorsítótár és hitelesítési adatok törlése.
- `pala --uninstall` : Interaktív komponens eltávolítás és rendszer-tisztítás.

## Dokumentáció
- [USER.md](docs/USER.md): Felhasználói útmutató és funkciók részletezése.
- [DEV.md](docs/DEV.md): Fejlesztői és architektúrális dokumentáció.
- [CONTRIBUTING.md](CONTRIBUTING.md): Irányelvek hozzájárulóknak.
- [DATA_SECURITY.md](docs/DATA_SECURITY.md): Adatkezelés és biztonsági tájékoztató.

## Elismerések & Közösségi Projektek

Minden használatba vett nyílt forráskódú csomagnak köszönet.

### Aktív és kapcsolódó projektek:
- [Firka](https://github.com/QwIT-Development/firka)
- [app-legacy (refilc)](https://github.com/QwIT-Development/app-legacy)
- [firka-extension](https://github.com/QwIT-Development/firka-extension)
- [Folio](https://github.com/Zan1456/folio)
- [folio-extension](https://github.com/Zan1456/folio-extension)
- [RozsdásFilc (rsfilc)](https://github.com/jarjk/rsfilc)
- [Toll](https://github.com/doomhyena/toll)

### Archivált és korábbi projektek:
- [Filc](https://github.com/filc/filc)
- [Szivacs-Naplo](https://github.com/boapps/Szivacs-Naplo)