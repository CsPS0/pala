# Adatkezelés és Biztonság (Data & Security)

A **Pala** fejlesztése során a legmagasabb prioritásként kezeljük a felhasználóink (diákok, tanárok, szülők) oktatási adatainak és hitelesítő információinak biztonságát. Mivel a Pala minden változata (terminálos alkalmazás, asztali és mobil alkalmazás, böngésző-kiterjesztés) nyílt forráskódú, kliensoldali program, az adatkezelés teljes mértékben transzparens, és kizárólag a te eszközödön történik.

Ebben a dokumentumban áttekintjük, hogy az alkalmazás pontosan milyen adatokat kezel, hogyan védi azokat, és hogyan tudod őket maradéktalanul eltávolítani.

## 1. Milyen adatokat tárol a Pala?

A működés érdekében a program a következő információkat menti el a számítógépeden:

*   **Hitelesítő tokenek:** A sikeres bejelentkezést követően a Kréta rendszertől kapott Access (hozzáférési) és Refresh (frissítési) tokenek. **A jelszavadat a program soha nem írja a lemezre.** Csak a bejelentkezés idejére használja, amíg a Kréta rendszerével (idp.e-kreta.hu) le nem zajlik a belépés.
*   **Profil adatok:** A diák neve és az intézmény azonosítója (kódja), hogy egyszerre több profilt is kényelmesen lehessen kezelni (pl. több diák esetén).
*   **Gyorsítótár (Cache):** Az utoljára letöltött jegyek, órarend, mulasztások, házi feladatok, üzenetek és a tanulói adatlap mentésre kerülnek. Ez teszi lehetővé, hogy az alkalmazás gyorsan induljon, és akkor is lásd a korábbi adataidat, ha a Kréta szerverei éppen elérhetetlenek (Offline mód). **A gyorsítótár nincs titkosítva**, és személyes adatot is tartalmaz (az adatlapon például a lakcímet és a gondviselők elérhetőségét).

## 2. Hogyan és hol tároljuk az adatokat?

Az adatok a számítógépeden, két külön mappában vannak.

A bejelentkezés és a beállítások (`auth.json`, `state.json`, `aliases.json`, `.pala_keyfile`) a `.config/pala` könyvtárban:
*   **Windows:** `%USERPROFILE%\.config\pala` (Pl. `C:\Users\Neved\.config\pala`)
*   **Linux / macOS:** `~/.config/pala` (A home könyvtárban)

A Krétától letöltött adatok offline gyorsítótára (`cache.json`) a rendszer gyorsítótár-mappájában:
*   **Windows:** `%LOCALAPPDATA%\pala\cache`
*   **Linux:** `~/.cache/pala` (vagy `$XDG_CACHE_HOME/pala`)
*   **macOS:** `~/Library/Caches/pala`

A gyorsítótár bármikor törölhető, a Pala a következő frissítéskor újra letölti. Bejelentkezve maradsz.

Telefonon (Android, iOS) mindkettő az alkalmazás saját tárhelyén van, amelyhez más alkalmazások nem férnek hozzá: a beállítások az alkalmazás támogatási mappájában, a gyorsítótár az ideiglenes mappájában. Az alkalmazás eltávolításával ezek is törlődnek.

Linuxon és macOS-en a Pala mindkét mappát csak a saját felhasználód számára teszi olvashatóvá (700-as jogosultság), így egy közös gép többi felhasználója nem fér hozzájuk. Windowson a felhasználói profil mappái eleve csak a te fiókodból érhetők el.

### Titkosítás (Encryption at Rest)
A tokeneket és profiladatokat tartalmazó konfigurációs fájl (`auth.json`) egy erős, iparági szabványnak megfelelő **AES-256-GCM** titkosítással van levédve.
A titkosítási kulcsot a Pala az első induláskor véletlenszerűen generálja (kriptográfiailag biztonságos véletlenszám-generátorral), és egy külön, csak az adott telepítéshez tartozó kulcsfájlban (`.pala_keyfile`) tárolja a `.config/pala` mappában.
*Fontos: a parancssori Pala kulcsfájlja ugyanebben a mappában van, mint az `auth.json`. A titkosítás ezért attól véd, aki csak az `auth.json` fájlt szerzi meg; aki a teljes mappát lemásolja, az a kulcsfájlt is megkapja. A mappát a saját felhasználói fiókod jogosultságai védik.*

Az alkalmazás (Android, iOS, macOS, Windows, Linux) a kulcsot nem fájlban, hanem a rendszer biztonságos kulcstárában tartja (Android Keystore, iOS/macOS Kulcskarika, Windows DPAPI, Linuxon libsecret). Frissítéskor a régi `.pala_keyfile` kulcsa átkerül a kulcstárba, és a fájl törlődik. Windowson és Linuxon a kulcsfájl megmarad, mert a parancssori Pala is használja. Ha a kulcstár nem érhető el (például Linuxon nincs kulcstartó szolgáltatás), az alkalmazás a kulcsfájlt használja tovább.

### Hálózati Biztonság
A Pala a Kréta hivatalos szervereivel kommunikál, titkosított HTTPS/TLS csatornán keresztül. Ezen kívül csak a GitHubhoz fordul: a frissítés-ellenőrzéshez, illetve a telepítő és a beépített frissítő a program letöltéséhez. Ezekben a kérésekben nincs Kréta-adat. A program nem használ saját vagy külső analitikai szervert, adatbázist vagy felhőt, és a Kréta-adataid csak a Kréta felé hagyják el a gépedet.

## 3. Hogyan törölheted (semmisítheted meg) az adataidat?

Mivel a Pala semmilyen felhős infrastruktúrával nem rendelkezik, az adataid felett 100%-os kontrollal rendelkezel. 

Ha ki szeretnél jelentkezni, vagy teljesen meg akarod semmisíteni a program által tárolt adataidat, használd a terminálos Pala Beállítások menüjében az "Összes mentett adat törlése" lehetőséget, az asztali és mobil alkalmazásban a "Kijelentkezés a fiókból" gombot, vagy töröld le mindkét mappát.

### Törlés lépései parancssorból:

**Windows rendszeren:**
```cmd
rmdir /s /q "%USERPROFILE%\.config\pala"
rmdir /s /q "%LOCALAPPDATA%\pala"
```

**Linux / macOS rendszeren:**
```bash
rm -rf ~/.config/pala ~/.cache/pala        # Linux
rm -rf ~/.config/pala ~/Library/Caches/pala # macOS
```

A mappák törlésével minden tárolt profilod, titkosított tokened és offline gyorsítótárad (cache) azonnal és véglegesen törlődik. A program következő indításakor úgy fog viselkedni, mintha most telepítetted volna először.

## 4. Böngésző Kiterjesztés: Munkamenet, Tokenek és Adatbiztonság

A Pala böngésző kiterjesztése (Manifest V3) a TUI-hoz hasonlóan szigorúan a kliensoldali biztonságra és a felhasználói adatvédelemre épül:

### Token Élettartam és Munkamenet Kezelés (40–60 perces limit feloldása)
- **OAuth2 Tokenek**: A bejelentkezéskor a kiterjesztés közvetlenül a hivatalos `idp.e-kreta.hu` szervertől kapja meg a hitelesítést. Két tokent kap: egy rövid élettartamú `access_token`-t (20–60 perc) és egy hosszú élettartamú `refresh_token`-t (30–90 nap).
- **Silent Token Refresh (Észrevétlen Megújítás)**: A webes Kréta felülettel ellentétben (ahol 20-30 perc inaktivitás után a munkamenet sütik lejárnak), a kiterjesztés automatikusan és észrevétlenül megújítja az access tokent a háttérben, még mielőtt az lejárna. A felhasználó aktív munkáját a 40–60 perces limit soha nem szakítja meg.
- **Offline Gyorsítótár Védelem**: A korábban letöltött adatok a `chrome.storage.local` izolált tárhelyében tárolódnak. Kréta leálláskor az adatok offline módban azonnal elérhetők.

### Kréta API Adatvédelmi Korlátozások és Kiegészítő Adatok
- **Milyen adatokat küld a Kréta?**: A `TanuloAdatlap` végpont elküldi a diák bankszámlaszámát és a számlatulajdonos nevét (ha az iskola rögzítette), de az OM-azonosítót, az okmányokat (adóazonosító, TAJ, diákigazolvány) és a bank nevét nem. A Pala a bankszámla adatait csak az eszközön jeleníti meg, nem naplózza és nem küldi tovább.
- **Helyi és Manuális Adattárolás (`pala_student_extra`)**: A kiterjesztés Globális Profil Szerkesztőjében kézzel megadott kiegészítő adatok kizárólag a böngésződ helyi, elszeparált tárhelyében (`chrome.storage.local.pala_student_extra`) tárolódnak. Ezeket az adatokat a Pala soha nem küldi el semmilyen külső szerverre, és a "Kréta adatok visszaállítása" gombbal azonnal törölhetők.

