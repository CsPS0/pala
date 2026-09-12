# Hozzájárulási Irányelvek

Köszönjük az érdeklődést a **Pala** projekt iránt. A nyílt forráskódú közösség segítségét (hibajelentések, új funkciók, dokumentáció) minden esetben szívesen fogadjuk.

## Közreműködés Menete

### 1. Hibajelentés (Issue)
Hibák esetén nyiss egy új Issue-t a repository-ban.
- Használj egyértelmű címet.
- Mellékelj reprodukciós lépéseket és terminál kimenetet.
- Személyes adatokat (jelszó, oktatási azonosító) soha ne ossz meg.

### 2. Új Funkciók
Funkciókérések esetén szintén az Issue felület használatos. Írd le a javaslat működését és annak gyakorlati hasznát a felhasználók számára.

### 3. Fejlesztés (Pull Request)
Ha kóddal szeretnél hozzájárulni a projekthez:
1. Készíts egy Forkot a saját GitHub fiókodba.
2. Klónozd a tárolót lokálisan.
3. Hozz létre egy új ágat (branch) a módosításoknak.
4. Készítsd el a fejlesztést a meglévő kódolási konvenciók betartásával.
5. Futtass sikeres teszt buildet (`dart compile exe bin/pala.dart`) és ellenőrizd a működést (lehetőség szerint platform-függetlenül).
6. Küldj egy Pull Requestet az eredeti repository felé.
   - *Megjegyzés: A GitHub Actions (CI/CD) automatikusan teszteli és építi a Windows, Linux és macOS binárisokat, valamint frissíti az AUR, Scoop és Homebrew csomagokat, így ezzel a résszel nem kell manuálisan foglalkoznod.*

## Kódolási Szabályok
- Nyelvhasználat: Az alkalmazás felhasználói felülete magyar nyelvű, a forráskód (változók, függvények, kommentek) azonban szigorúan angol nyelvű kell maradjon.
- Biztonság: Hardkódolt jelszavak, tokenek vagy intézménykódok elhelyezése a forráskódban szigorúan tilos. Minden hitelesítési adat lokálisan, titkosítva a felhasználó rendszerében (`~/.config/pala/`) tárolódik.
- Hibakezelés: A Kréta API válaszai változatosak lehetnek. Minden adatszerkezet beolvasásánál kötelező a biztonságos típusellenőrzés és a kivételkezelés.
- UI Konvenciók: A terminál interfészekhez az `interact` csomag használandó, a projekt meglévő vizuális irányelveinek (színtémák, háttér megőrzése) tiszteletben tartásával.

## AI Használat

A Palát gyakorlatilag egyedül fejlesztem, és ehhez sokat használok AI-t/LLM-eket — ezt nem titkolom, és nem is gondolom, hogy szégyellnivaló lenne. Amíg nagyjából értem és valamennyire átlátom, amit a gép leír, addig ez csak egy eszköz a sok közül — a maradékra meg ott az MIT licenc: a kód "ahogy van" alapon, mindenféle garancia nélkül érhető el.

Ha te is hozzá szeretnél járulni kóddal, ugyanezt az elvárást támasztom feléd: nyugodtan használhatsz AI-t a Pull Requestedhez, de a beküldés előtt neked kell értened, hogy mit csinált az LLM. Ha megkérdezem, miért így oldottad meg, tudnod kell válaszolni rá — a "az AI így írta" nem válasz.

Azok a Pull Requestek, amelyeknél látszik, hogy a hozzájáruló nem érti a saját kódját, javítási kérés nélkül elutasításra kerülhetnek.

Emberi szöveg AI-alapú helyesírás-ellenőrzése és fordítása természetesen megengedett.

Ha állásra jelentkezőként vagy felhasználóként megtévesztőnek találod az AI ilyen jellegű használatát ebben a projektben, használd inkább a [Firka](https://github.com/QwIT-Development/firka)-t vagy a [Folio](https://github.com/Zan1456/folio) alkalmazást a Pala helyett.

