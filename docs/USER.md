# Felhasználói Kézikönyv

A **Pala** egy interaktív terminálos Kréta e-napló kliens (TUI). Ez a dokumentum a főbb funkciók használatát mutatja be.

## 1. Bejelentkezés és Demó Üzemmód
- **Normál bejelentkezés**: Az első indításkor meg kell adni az intézmény kódját (pl. `bmszc-neumann`). Ha nem tudod a kódot, használd a beépített keresőt az iskola neve alapján. A bejelentkezéshez az oktatási azonosítóra és a jelszóra van szükség.
- **[DEMÓ] Demó / Teszt üzemmód (Teszt Elek)**: Ha a Kréta szerverei éppen nem érhetők el (pl. nyári karbantartás alatt), vagy csak tesztelni szeretnéd a funkciókat, indítsd az alkalmazást a `pala --demo` paranccsal, vagy válaszd a bejelentkező képernyőn a *Demó profil betöltése* opciót. Ez teljes, élethű fiktív adatbázissal (szeptember 1-től június 21-ig tartó jegyek, órarend, házi feladatok, üzenetek, mulasztások) futtatja az alkalmazást internetkapcsolat nélkül.

## 2. Főmenü Funkciók és Kimutatások
- **Élő Dashboard**: Azonnali visszaszámlálás az óra végéig, óraközi szünetek ideje, mai órarend és rendszer-karbantartási figyelmeztetések. 30 másodpercenként automatikusan frissül.
- **Legutóbbi jegyek**: Legfrissebb érdemjegyek, amelyek mellett elérhető a **Szellem Jegyek** szimulátor és a **Heti Heatmap** (átlag alakulása heti bontásban).
- **Órarend**: Dinamikus táblázatos órarend, amely jelzi az elmaradt órákat, a helyettesítéseket (tanárnévvel), dolgozatokat és a saját mulasztásaidat is.
- **Mulasztások**: Igazolt, igazolandó, igazolatlan órák és késések listája, valamint a 250 órás határt mérő **Veszélyzóna Kalkulátor**.
- **Tantárgyi átlagok**: Áttekinthető táblázat a saját átlagaidról, az osztályátlagokról, az eltérésekről és az átlag-trendekről (↗ / ↘), valamint a jegy-határhelyzet figyelmeztetésekről (pl. *Veszélyben a 4-es!*).
- **Jegy-trendek**: Heti bontású grafikon az éves átlagod alakulásáról (dinamikusan skálázott y-tengellyel), részletes statisztikákkal (legjobb/leggyengébb hónap) és az érdemjegyek eloszlási bar chartjával.
- **Számonkérések & Házi feladatok**: Dolgozatok és feladatok leírásokkal és határidőkkel, valamint a csatolt fájlok letöltésének lehetőségével.
- **Üzenetek**: Parancssoros üzenőfal a beérkezett üzenetek elolvasásához és mellékleteik letöltéséhez.
- **Haladó Kereső**: Ékezet-érzéketlen keresőmotor, amellyel a napló teljes tartalmában (jegyek, órák, házi feladatok, üzenetek, hiányzások) kereshetsz, és megnyithatod a részleteket.
- **Pala Wrapped**: Spotify-style éves diákstatisztika, amely bemutatja a legtöbb jegyet adó tanárodat, legszorgalmasabb napodat, késéseid összesített perceit és az üzenetküldő bajnokodat.

Minden listanézetnél és az üzeneteknél is elérhető az arrow-key alapú lapozás (Bal/Jobb nyilak).

## 3. Haladó Funkciók és Beállítások
A főmenü "Beállítások" opciójában az alábbi funkciók érhetők el:
- **Főmenü testreszabása**: Kiválaszthatod (SPACE gombbal), hogy mely menüpontok jelenjenek meg a főképernyőn, így elrejtheted a ritkán használt funkciókat.
- **Exportálások**:
  - Naptár exportálása (.ics): Az elkövetkező két hét órarendjének és vizsgáinak kimentése importálható naptárfájlba (`pala_naptar.ics`).
  - Adatok exportálása (CSV): Jegyek és mulasztások táblázatos kimentése (`Pala_Jegyek.csv`, `Pala_Mulasztasok.csv`).
  - Git-alapú jegytörténet: Lokális Git tárolóba mentés (`Pala_Jegyek_Git`).
- **Profilkezelés**: Váltás a mentett fiókok között.
- **Háttér-értesítések**: Windows Feladatütemező integráció. A háttérben futva óránként és bejelentkezéskor ellenőrzi az új jegyeket, majd értesítést küld (`PalaDaemon`).

## 4. Komponensek, Rendszerintegráció & Eltávolítás
A Pala teljes komponenskezelési támogatással rendelkezik a parancssorból és a grafikus beállításokból is:
- **Asztali Alkalmazás indítása**: `pala --desktop` vagy `pala -g`
- **Start menü parancsikon kezelése**:
  - Létrehozás: `pala --install-shortcut`
  - Eltávolítás: `pala --remove-shortcut`
- **PATH környezeti változó kezelése**:
  - Hozzáadás: `pala --add-path`
  - Eltávolítás: `pala --remove-path`
- **Helyi gyorsítótár és hitelesítési adatok törlése**: `pala --clear-cache`
- **Interaktív eltávolító**: `pala --uninstall` (Választhatsz a parancsikonok, a PATH vagy a teljes program eltávolítása között)

## 5. Rendszer és Frissítések
- **Konfigurációs Fájlok**: Az alkalmazás minden mentett adatot a `~/.config/pala/` (Windows-on `C:\Users\Felhasználónév\.config\pala\`) könyvtárban tárol.
- **Csomagkezelők**: A Pala natívan támogatja a Windows (PowerShell / Scoop), macOS/Linux (Homebrew / Bash installer), Arch Linux (AUR) és Debian/Ubuntu (APT) csomagkezelőket.
- **Frissítések**: Az alkalmazás induláskor automatikusan ellenőrzi a GitHub-ot, és sárga szöveges üzenettel jelez, ha új verzió érhető el. A frissítés ezután a telepítés módjától függően (pl. `scoop update pala`, `brew upgrade pala`, `sudo apt update && sudo apt install pala` vagy `irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex`) könnyedén elvégezhető.

## 6. Hibaelhárítás
- **Hálózati vagy API hibák**: A Kréta szervereinek túlterheltsége vagy az API módosulása okozhatja. A program beépített védelemmel rendelkezik a leggyakoribb hibák ellen.
- **Szövegbeviteli / Másolási hibák**: A bejelentkezési kód beillesztésekor a program automatikusan kezeli a vágólapot (beleértve a Linux/macOS "Bracketed Paste" funkcióját és a Windows terminál specifikumait is). Különleges terminál emulátorok esetén javasolt a jobb gombos beillesztés használata.
- **Megjelenítési hibák**: Ékezet- és táblázatproblémák esetén javasolt a terminál (PowerShell/CMD) frissítése és a Pala legújabb verziójának használata.
- **Lefagyás**: Ha régebbi verziót használsz, Windows terminál esetén előfordulhatott eseménykezelési hiba (befagyott beviteli mező). Ezt a legújabb verziókban javítottuk a platform-specifikus I/O szétválasztásával. Ilyenkor frissíts a legújabb verzióra.

## 7. Pala Böngésző Kiterjesztés (Browser Extension)

A Pala böngésző kiterjesztése (Manifest V3) a Chromium alapú böngészőkben (Google Chrome, Brave, Microsoft Edge) nyújt közvetlen, villámgyors hozzáférést a Kréta rendszeréhez.

### 7.1. Felépítés: Mini Gyorsnézet és Teljes Vezérlőpult
- **Mini Gyorsnézet (Popup)**: Az eszköztáron található Pala ikonra kattintva azonnal megjelenik az aktuális/következő tanóra, a visszaszámlálás a szünetre/órára, a mai órarend, a legfrissebb jegyek és a közelgő feladatok/dolgozatok.
- **Teljes Vezérlőpult (Dashboard)**: Külön böngészőlapon futó vezérlőközpont heti órarendi mátrixszal, jegyeloszlási statisztikákkal, tantárgyi súlyozott átlagokkal, Szellem-jegy kalkulátorral, Bizonyítvány tervezővel, 250 órás hiányzáskerettel, üzenetkezelővel és a teljes profilom felülettel.

### 7.2. Kréta Munkamenet és az Időkorlát (40–60 perc) Kezelése
- **A hivatalos weboldal limitje**: A webes Kréta felület (`*.e-kreta.hu`) 20–30 perc tétlenség után automatikusan kijelentkezteti a felhasználót a szerveroldali ASP.NET sütik lejárata miatt.
- **OAuth2 és Refresh Token architektúra**: A Pala a Kréta hivatalos Identity Provider (`idp.e-kreta.hu`) gateway-én keresztül hitelesít, ahol a bejelentkezéskor egy 20–60 perces `access_token`-t és egy 30–90 napos `refresh_token`-t kap.
- **Észrevétlen háttér-megújítás (Silent Refresh)**: A kiterjesztés (`KretaApi.ensureValidToken`) minden API kérés és háttérszinkron előtt ellenőrzi a token érvényességét. Ha a token 2 percen belül lejárna, a kiterjesztés a háttérben automatikusan megújítja azt a refresh token használatával. Ennek köszönhetően a felhasználó sosem kerül kijelentkeztetésre a 40–60 perces limit miatt.
- **401 Unauthorized Automatikus Helyreállítás**: Ha a szerver váratlanul érvénytelenítené a tokent, a kiterjesztés azonnal észleli a hibát, lefut a megújítás, és a kérés automatikusan megismétlődik.
- **Offline gyorsítótár védelem**: Hálózati hiba vagy Kréta szerverkarbantartás esetén a `pala_cached_data` révén minden korábbi jegy, órarend és adat offline is azonnal megtekinthető.

### 7.3. Tanulói Profil & Kréta API Korlátozások (Hiányzó Adatok Kezelése)
- **Miért jelenik meg a "Nincs rögzítve" felirat?**: A hivatalos Kréta mobil API gateway adatvédelmi és 2FA biztonsági korlátozások miatt a `TanuloAdatlap` végponton nem adja át a tanuló bankszámla adatait (bankszámlaszám, bank neve, számlatulajdonos), sem a hivatalos okmányait (adóazonosító jel, TAJ-szám, diákigazolvány adatok). Ezek a Kréta rendszerében kizárólag a kétfaktoros webes felületen érhetők el.
- **Nagy [!] Figyelmeztető Ikon & Értesítő sáv**: A Profilom nézet jobb felső sarkában kihelyezett nagy felkiáltójel gomb és az információs banner azonnal tájékoztat erről az API korlátozásról.
- **Globális Profil Szerkesztő (Teljes Profil Testreszabása)**: A fejlécben lévő "Profil Szerkesztése" gombra kattintva mind a 4 fő kategória (Személyes Adatok, Intézmény & Elérhetőségek, Bankszámla Adatok, Hivatalos Okmányok) manuálisan kitölthető és szerkeszthető.
- **1-Kattintásos Automatikus Beolvasás**: Ha a böngészőben nyitva van a hivatalos Kréta felület, az "Adatok automatikus beolvasása nyitott Kréta lapról" gomb azonnal végigpásztázza a lapot, felismeri a bankszámlaszámot, banknevet, adószámot, TAJ-t, OM kódot, és automatikusan beemeli az adatokat.
- **Gyári Adatok Visszaállítása**: Bármikor 1 kattintással törölhetők a manuális felülbírálások, visszaállítva az eredeti Kréta szerver által küldött állapotot.

### 7.4. Popup Testreszabása
- A felugró mini ablak működése és sűrűsége testreszabható:
  - Alapértelmezett nyitó fül (Mai órák, Jegyek, Feladatok).
  - Aktuális óra Hero card elrejtése / felfedése.
  - Kompakt, sűrűbb lista elrendezés.
  - Tanulmányi átlagsáv ki/bekapcsolása.
  - Megjelenített jegyek és feladatok maximális száma.
- Elérhető mind a Popup láblécében lévő fogaskerék gombbal, mind a Dashboard Beállítások oldalán, valós idejű szinkronizációval (`pala_popup_settings`).

