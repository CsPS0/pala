# Adatkezelés és Biztonság (Data & Security)

A **Pala** fejlesztése során a legmagasabb prioritásként kezeljük a felhasználóink (diákok, tanárok, szülők) oktatási adatainak és hitelesítő információinak biztonságát. Mivel a Pala egy nyílt forráskódú, kliensoldali terminálos alkalmazás (TUI), az adatkezelés teljes mértékben transzparens, és kizárólag a te számítógépeden történik.

Ebben a dokumentumban áttekintjük, hogy az alkalmazás pontosan milyen adatokat kezel, hogyan védi azokat, és hogyan tudod őket maradéktalanul eltávolítani.

## 1. Milyen adatokat tárol a Pala?

A működés érdekében a program a következő információkat menti el a számítógépeden:

*   **Hitelesítő tokenek:** A sikeres bejelentkezést követően a Kréta rendszertől kapott Access (hozzáférési) és Refresh (frissítési) tokenek. **A jelszavadat a program soha nem tárolja el tartósan a lemezen!** A jelszót csak a memóriában tartja addig a néhány másodpercig, amíg a bejelentkezési folyamat a Kréta rendszerével (idp.e-kreta.hu) le nem zajlik, majd az azonnal törlődik a memóriából.
*   **Profil adatok:** A diák neve és az intézmény azonosítója (kódja), hogy egyszerre több profilt is kényelmesen lehessen kezelni (pl. több diák esetén).
*   **Gyorsítótár (Cache):** Az utoljára letöltött jegyek, órarend, mulasztások és házi feladatok mentésre kerülnek. Ez teszi lehetővé, hogy az alkalmazás villámgyors legyen, és akkor is lásd a korábbi adataidat, ha a Kréta szerverei éppen elérhetetlenek (Offline mód).

## 2. Hogyan és hol tároljuk az adatokat?

Az adatok a számítógépeden, az operációs rendszered felhasználói mappájában, a szabványos `.config/pala` könyvtárban találhatóak:
*   **Windows:** `%USERPROFILE%\.config\pala` (Pl. `C:\Users\Neved\.config\pala`)
*   **Linux / macOS:** `~/.config/pala` (A home könyvtárban)

### Titkosítás (Encryption at Rest)
A tokeneket és profiladatokat tartalmazó konfigurációs fájl (`auth.json`) egy erős, iparági szabványnak megfelelő **AES-256-GCM** titkosítással van levédve. 
A titkosítási kulcsot a Pala automatikusan generálja a számítógéped egyedi hardver- és szoftverjellemzőiből (gépnév, OS, felhasználónév).
*A gyakorlatban ez azt jelenti, hogy ha egy kártékony program vagy egy hacker lemásolná a gépedről a `.config/pala` mappát, egy másik gépen vagy felhasználói fiókban teljesen esélytelen lesz visszafejtenie és kiolvasnia a Kréta tokenjeidet.*

### Hálózati Biztonság
A Pala **kizárólag** a Kréta hivatalos szervereivel kommunikál, szigorúan titkosított HTTPS/TLS csatornán keresztül. A program nem használ semmilyen saját vagy külső (third-party) analitikai szervert, adatbázist vagy felhőt. Az adataid soha nem hagyják el a gépedet más irányba, csak a Kréta felé.

## 3. Hogyan törölheted (semmisítheted meg) az adataidat?

Mivel a Pala semmilyen felhős infrastruktúrával nem rendelkezik, az adataid felett 100%-os kontrollal rendelkezel. 

Ha ki szeretnél jelentkezni, vagy teljesen meg akarod semmisíteni a program által tárolt adataidat, egyszerűen használd a Beállítások menüben az "Összes mentett adat törlése" lehetőséget, vagy töröld le a `.config/pala` mappát.

### Törlés lépései parancssorból:

**Windows rendszeren:**
```cmd
rmdir /s /q "%USERPROFILE%\.config\pala"
```

**Linux / macOS rendszeren:**
```bash
rm -rf ~/.config/pala
```

A mappa törlésével minden tárolt profilod, titkosított tokened és offline gyorsítótárad (cache) azonnal és véglegesen törlődik. A program következő indításakor úgy fog viselkedni, mintha most telepítetted volna először.

## 4. Böngésző Kiterjesztés: Munkamenet, Tokenek és Adatbiztonság

A Pala böngésző kiterjesztése (Manifest V3) a TUI-hoz hasonlóan szigorúan a kliensoldali biztonságra és a felhasználói adatvédelemre épül:

### Token Élettartam és Munkamenet Kezelés (40–60 perces limit feloldása)
- **OAuth2 Tokenek**: A bejelentkezéskor a kiterjesztés közvetlenül a hivatalos `idp.e-kreta.hu` szervertől kapja meg a hitelesítést. Két tokent kap: egy rövid élettartamú `access_token`-t (20–60 perc) és egy hosszú élettartamú `refresh_token`-t (30–90 nap).
- **Silent Token Refresh (Észrevétlen Megújítás)**: A webes Kréta felülettel ellentétben (ahol 20-30 perc inaktivitás után a munkamenet sütik lejárnak), a kiterjesztés automatikusan és észrevétlenül megújítja az access tokent a háttérben, még mielőtt az lejárna. A felhasználó aktív munkáját a 40–60 perces limit soha nem szakítja meg.
- **Offline Gyorsítótár Védelem**: A korábban letöltött adatok a `chrome.storage.local` izolált tárhelyében tárolódnak. Kréta leálláskor az adatok offline módban azonnal elérhetők.

### Kréta API Adatvédelmi Korlátozások és Kiegészítő Adatok
- **Miért hiányoznak bizonyos adatok?**: A hivatalos Kréta mobil gateway adatvédelmi okokból a `TanuloAdatlap` végponton nem adja ki a diák bankszámla adatait (bankszámlaszám, bank neve) és okmányait (adóazonosító, TAJ, diákigazolvány adatok).
- **Helyi és Manuális Adattárolás (`pala_student_extra`)**: A kiterjesztés Globális Profil Szerkesztőjében megadott vagy a nyitott Kréta lapról automatikusan beolvasott kiegészítő adatok kizárólag a böngésződ helyi, elszeparált tárhelyében (`chrome.storage.local.pala_student_extra`) tárolódnak. Ezeket az adatokat a Pala soha nem küldi el semmilyen külső szerverre, és a "Kréta adatok visszaállítása" gombbal azonnal törölhetők.

