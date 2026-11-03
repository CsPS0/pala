# Pala alkalmazás (Flutter)

A Pala asztali és mobil alkalmazása: Windows, macOS, Linux, Android, és kísérletként iOS. A közös magot (Kréta API, modellek, számítási szabályok) a repó gyökerében lévő `lib/` adja, `package:pala` néven.

## Futtatás és build

```bash
flutter pub get
flutter run                      # a csatlakoztatott eszközön vagy asztali ablakban
flutter build windows            # vagy: macos, linux
flutter build apk --release      # Android
flutter build ios --release --no-codesign   # iOS, csak macOS-en
```

- Az asztali buildek előfeltételei (Windowson az ATL összetevő, Linuxon a `libsecret-1-dev`) és az Android aláíró kulcs beállítása a [fejlesztői dokumentációban](../docs/DEV.md) van.
- Az iOS-build aláíratlan: a felhasználók a saját ingyenes Apple ID-jükkel írják alá (AltStore vagy Sideloadly). Háttérfrissítés és háttér-értesítés csak Androidon van.

## Ellenőrzés

```bash
flutter analyze
flutter test
```

## Felépítés

- `lib/main.dart`: indulás, a konfigurációs és gyorsítótár-mappák beállítása mobilon.
- `lib/state/`: az alkalmazás állapota (`AppModel`, `ChangeNotifier`) és a munkamenet tárolása.
- `lib/core/`: téma, adaptív elrendezés (600 dp alatt alsó navigáció, felette oldalsáv), közös widgetek.
- `lib/features/`, `lib/views/`: a képernyők (vezérlőpult, jegyek, hiányzások, órarend, kereső, Wrapped, beállítások).
- `lib/notifications/`: értesítések és az androidos háttérellenőrzés.
