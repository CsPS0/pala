# Adatvédelmi Szabályzat (Privacy Policy)

Utolsó frissítés: 2026-11-03

Ez a szabályzat a **Pala** böngésző-kiterjesztésre (Chrome, Brave, Microsoft Edge), a terminálos alkalmazásra (TUI), valamint az asztali és mobil alkalmazásra (Windows, macOS, Linux, Android, iOS) vonatkozik. A weboldal ([pala-app.hu](https://pala-app.hu)) adatkezelését a weboldal [Adatvédelem](https://pala-app.hu/adatvedelem) oldala írja le. A Pala nyílt forráskódú, kliensoldali szoftver, amelyet a hivatalos e-Kréta rendszer diákjai/szülei használnak.

## Milyen adatokat kezel a Pala?

A Pala a Kréta hivatalos API-ján (`*.e-kreta.hu`) keresztül elérhető, a felhasználóra vonatkozó oktatási adatokat (jegyek, órarend, hiányzások, üzenetek, tanulói profil) jeleníti meg, valamint a bejelentkezéshez szükséges OAuth2 hitelesítési tokeneket kezeli.

Ezen adatok részletes listáját, tárolási helyét és titkosítását a [DATA_SECURITY.md](DATA_SECURITY.md) dokumentum tartalmazza.

## Adatgyűjtés és -továbbítás

- **A Pala nem gyűjt, nem továbbít és nem tárol semmilyen adatot a fejlesztő vagy bármely harmadik fél szerverén.**
- Nincs beépített analitika, telemetria vagy hirdetési kód.
- Az egyetlen hálózati kommunikáció a hivatalos Kréta szerverek (`*.e-kreta.hu`) felé irányul (bejelentkezés és adatlekérdezés céljából), valamint a GitHub API felé, kizárólag az alkalmazás új verziójának ellenőrzéséhez.
- A böngésző-kiterjesztés a `chrome.storage.local` API-t használja: minden adat (gyorsítótár, tokenek, egyéni profiladatok) kizárólag a felhasználó saját böngészőjében, helyileg tárolódik, és soha nem hagyja el az eszközt a Kréta szerverei felé irányuló kéréseken kívül.
- A TUI és az asztali alkalmazás a bejelentkezési adatokat a felhasználó saját gépén, a `~/.config/pala/` mappában, titkosítva tárolja, a letöltött adatok offline gyorsítótárát pedig a rendszer gyorsítótár-mappájában (lásd [DATA_SECURITY.md](DATA_SECURITY.md)).
- A mobil alkalmazás (Android, iOS) mindent az alkalmazás saját, más alkalmazások számára elérhetetlen tárhelyén tart, a titkosítási kulcsot pedig a rendszer kulcstárában (Android Keystore, iOS Kulcskarika).
- Az iPhone-os változatot a felhasználó a saját Apple ID-jével írja alá (AltStore vagy Sideloadly). Ez a felhasználó és az Apple között történik, a Pala ebben nem vesz részt, és az Apple ID-t nem látja.

## Engedélyek (böngésző-kiterjesztés)

A kiterjesztés az alábbi Manifest V3 engedélyeket kéri, kizárólag a következő célokra:
- `storage`: a fent leírt helyi adattárolás.
- `alarms`: a token silent-refresh és az óraközi visszaszámláló ütemezése.
- `notifications`: új jegy/üzenet értesítések megjelenítése.
- `webNavigation`, valamint a `*.e-kreta.hu` host engedély: a bejelentkezési folyamathoz (a Kréta visszairányításának elkapása) és a Kréta API eléréséhez.

## Adatok törlése

A felhasználó bármikor, teljes egészében törölheti a tárolt adatait:
- **Böngésző-kiterjesztés**: a kiterjesztés eltávolításával, vagy a böngésző beállításaiban a webhelyadatok törlésével.
- **TUI**: a `~/.config/pala/` és a gyorsítótár-mappa törlésével, vagy a Beállítások "Összes mentett adat törlése" pontjával.
- **Asztali és mobil alkalmazás**: a Beállítások "Kijelentkezés a fiókból" gombjával, amely törli a mentett munkamenetet és a gyorsítótárat, vagy az alkalmazás eltávolításával.

## Kapcsolat

Adatvédelemmel vagy biztonsággal kapcsolatos kérdés, illetve sebezhetőség bejelentése esetén lásd a [SECURITY.md](../SECURITY.md) dokumentumot.
