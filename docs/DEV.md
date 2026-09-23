# Fejlesztői Dokumentáció

Ez a leírás a Pala felépítését, a Kréta API sajátosságait, valamint az ellenőrzési és kiadási folyamatot foglalja össze.

## Felépítés

A Pala egy közös Dart magra épülő több kliensből áll:

| Mappa | Tartalom |
| :--- | :--- |
| `lib/`, `bin/` | Közös mag (API, modellek, állapot) és a terminálos alkalmazás (TUI). Tiszta Dart, Flutter nélkül, így gyorsan AOT-fordítható natív binárissá. |
| `app/` | Flutter asztali és mobil alkalmazás (`pala --desktop`). A `lib/`-et a `package:pala` függőségen keresztül használja. |
| `extension/` | Manifest V3 böngésző-kiterjesztés (Chrome, Brave, Edge), sima JavaScript, build lépés nélkül. |
| `website/` | Next.js weboldal ([pala-app.hu](https://pala-app.hu)), Vercelen. |

**Fontos:** a kiterjesztés nem tudja használni a Dart kódot. Ha a `lib/api/` vagy a `lib/models/` viselkedése megváltozik, ugyanazt a változtatást kézzel át kell vezetni az `extension/shared/kreta_api.js` fájlba is. Ugyanez vonatkozik a demó adatokra: a `lib/api/demo_data.dart` és a `kreta_api.js` `DEMO_*` konstansai legyenek szinkronban.

### Közös mag és TUI (`lib/`)

Kiemelt függőségek:
- **interact**: interaktív terminálfelület (menük, bevitel, maszkolás).
- **http**: kommunikáció a Kréta IDP és V3 (Ellenőrző) API-kkal. A `KRETA_API_KEY` konstans (`lib/api/api.dart`, `extension/shared/kreta_api.js`) a hivatalos Kréta mobilalkalmazás publikus API-kulcsa, amelyet minden nyílt forráskódú Kréta-kliens (rsfilc, Firka stb.) ugyanígy használ. Nem titok, ezért szándékosan szerepel a forráskódban.
- **args**: parancssori argumentumok feldolgozása.

Fő modulok:
- **api/client.dart**: hálózati réteg és OAuth2 token-kezelés. A token-frissítés (`refreshAccessToken`) aszinkron zárral (`_activeRefreshFuture`) védett, így párhuzamos API-hívásoknál sem sérül az `auth.json` írása és titkosítása.
- **models/**: típusbiztos modellek (Grade, Student, Absence, TimetableEntry stb.). Az UTC dátumokat azonnal helyi időre alakítják. Az `isSummaryGrade` ékezetes és ékezet nélküli szűréssel is kiszűri a félévi és év végi összefoglaló jegyeket.
- **app/state/app_state.dart**: singleton a helyi beállításokhoz (`state.json` és a titkosított `auth.json`) a `~/.config/pala/` mappában, a témával és az ASCII banner beállításaival együtt.
- **app/theme.dart**: a terminál globális témája és színei (`PalaTheme`).
- **app/views/**:
  - **dashboard_view.dart**: aszinkron billentyűzet-eseményhurok és óra-visszaszámláló. Külön alfolyamatként indul, így az aszinkron `stdin` nem akad össze a főprogram konzoljával.
  - **wrapped_view.dart**: a Pala Wrapped éves statisztika diái.
  - **absences_view.dart**: Veszélyzóna kalkulátor, osztályátlag- és eltérés-táblázat, heti jegy-trendek.
  - **grades_view.dart**: Szellem jegy kalkulátor, jegy-heatmap és az ékezet-érzéketlen kereső.
- **app/components/utf8_input.dart**: saját beviteli réteg, amely Windows konzolon is helyesen kezeli a karakterek visszaírását (echo).
- **utils/win32_console.dart**: Win32 API FFI hívások. A `forceRestoreConsoleMode()` visszaállítja a billentyűzet-echót (`ENABLE_ECHO_INPUT`), és kikapcsolja a `0x0200` (virtual terminal input) módot, hogy a backspace helyesen töröljön.
- **utils/chart_generator.dart**: ANSI terminálgrafikonok. A `generateLineChart` az adatokhoz igazítja az y-tengelyt, így az átlaggrafikon nem lesz lapos.
- **utils/ics_exporter.dart**: RFC 5545 kompatibilis naptárexport.
- **web/pala_web_server.dart** és **web/pala_web_html.dart**: beágyazott HTTP szerver és HTML nézetek.

### Asztali alkalmazás (`app/`)

Nézetek az `app/lib/views/` alatt (bejelentkezés, dashboard, jegyek, hiányzások, órarend, feladatok, üzenetírás, kereső, statisztika, Wrapped, beállítások), állapotkezelés az `app/lib/state/app_model.dart` fájlban.

### Böngésző-kiterjesztés (`extension/`)

- `shared/kreta_api.js`: közös API és OAuth2 réteg, valamint a demó motor.
- `background/service_worker.js`: token-megújítás a háttérben és háttérszinkron.
- `popup/` és `dashboard/`: a felhasználói felületek.

## A Kréta API sajátosságai

- **UTC időpontok:** a Kréta API a dátumokat (például az órák kezdetét) UTC-ben adja vissza. Közvetlen megjelenítésnél a napok elcsúszhatnak, ezért a modellek `fromJson` metódusai minden dátumra meghívják a `.toLocal()` függvényt.
- **Kötelező paraméterek:** a V3 végpontok szigorúak. A `HaziFeladatok` például `500 Internal Server Error` hibát ad, ha hiányzik a `datumTol` paraméter, ezért 30 napos alapértelmezett időablakot használunk.
- **Inkonzisztens típusok:** a JSON mezők típusa (például a `Tantargy` kulcsé) változhat, ezért a kliensoldali típusellenőrzés (null check, típuskonverzió) elengedhetetlen.
- **Windows kódolás:** a PowerShell alapértelmezett Windows-1252 kódolása miatt az UTF-8 karakterek és a táblázatrajzoló elemek külön kezelést igényelnek.

## Ellenőrzés commit előtt

A CI a Dart és Flutter ellenőrzéseket minden `main`-re történő pushnál és pull requestnél lefuttatja, és bármilyen hibánál elbukik. A megváltoztatott részekre futtasd le helyben is:

| Változás helye | Parancs |
| :--- | :--- |
| `lib/`, `bin/`, `test/` | `dart analyze --fatal-infos` és `dart test` a repó gyökerében. A sima `dart analyze` nem elég: a CI az info szintű jelzéseket is hibának veszi. |
| `app/` | `flutter analyze` az `app/` mappában. |
| `extension/` | `node --check <fájl>` minden módosított JS fájlra. |
| `website/` | `npm run lint` és `npm run build` a `website/` mappában. |

Gyors kézi próba: `dart run bin/pala.dart --demo` bejelentkezés és hálózat nélkül, fiktív adatokkal indítja a TUI-t.

## Build és kiadás

A natív terminálos bináris előállítása:
```bash
dart compile exe bin/pala.dart -o pala
```

A Windows Feladatütemezőből háttérben indított példány (`--daemon`) láthatatlan módban fut.

### GitHub Actions

- **ci.yml**: minden `main`-re történő pushnál és pull requestnél `dart analyze --fatal-infos`, `dart test` és `flutter analyze` az `app/` mappában.
- **release.yml**: egy GitHub Release közzétételekor (vagy kézi indításra) elkészíti és a kiadáshoz csatolja:
  - a terminálos binárisokat Windowsra, Linuxra és macOS-re (zip, `.deb` és `.tar.gz` csomagokkal),
  - az asztali alkalmazást: Windows telepítő (`Pala-Setup.exe`), macOS DMG, Linux AppImage,
  - az Android APK-kat,
  - a böngésző-kiterjesztés zip fájlját,
  - az APT tárolót, és frissíti a Scoop (`bucket/pala.json`) és Homebrew (`Formula/pala.rb`) manifesteket.
- **aur.yml**: az AUR `pala-bin` csomagot a `packaging/PKGBUILD` alapján frissíti, a beállított SSH kulccsal.
