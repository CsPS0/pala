# Adatvédelmi Szabályzat (Privacy Policy)

Utolsó frissítés: 2026-09-07

Ez a szabályzat a **Pala** böngésző-kiterjesztésre (Chrome, Brave, Microsoft Edge) és a Pala TUI/Desktop alkalmazásra vonatkozik. A Pala nyílt forráskódú, kliensoldali szoftver, amelyet a hivatalos e-Kréta rendszer diákjai/szülei használnak.

## Milyen adatokat kezel a Pala?

A Pala a Kréta hivatalos API-ján (`*.e-kreta.hu`) keresztül elérhető, a felhasználóra vonatkozó oktatási adatokat (jegyek, órarend, hiányzások, üzenetek, tanulói profil) jeleníti meg, valamint a bejelentkezéshez szükséges OAuth2 hitelesítési tokeneket kezeli.

Ezen adatok részletes listáját, tárolási helyét és titkosítását a [DATA_SECURITY.md](DATA_SECURITY.md) dokumentum tartalmazza.

## Adatgyűjtés és -továbbítás

- **A Pala nem gyűjt, nem továbbít és nem tárol semmilyen adatot a fejlesztő vagy bármely harmadik fél szerverén.**
- Nincs beépített analitika, telemetria vagy hirdetési kód.
- Az egyetlen hálózati kommunikáció a hivatalos Kréta szerverek (`*.e-kreta.hu`) felé irányul (bejelentkezés és adatlekérdezés céljából), valamint a GitHub API felé, kizárólag az alkalmazás új verziójának ellenőrzéséhez.
- A böngésző-kiterjesztés a `chrome.storage.local` API-t használja: minden adat (gyorsítótár, tokenek, egyéni profiladatok) kizárólag a felhasználó saját böngészőjében, helyileg tárolódik, és soha nem hagyja el az eszközt a Kréta szerverei felé irányuló kéréseken kívül.
- A TUI/Desktop alkalmazás az adatokat a felhasználó saját gépén, a `~/.config/pala/` mappában, titkosítva tárolja (lásd [DATA_SECURITY.md](DATA_SECURITY.md)).

## Engedélyek (böngésző-kiterjesztés)

A kiterjesztés az alábbi Manifest V3 engedélyeket kéri, kizárólag a következő célokra:
- `storage`: a fent leírt helyi adattárolás.
- `alarms`: a token silent-refresh és az óraközi visszaszámláló ütemezése.
- `notifications`: új jegy/üzenet értesítések megjelenítése.
- `tabs`, `webNavigation`, valamint a `*.e-kreta.hu` host engedély: a Kréta weboldal automatikus adat-beolvasásához és a bejelentkezési folyamathoz.

## Adatok törlése

A felhasználó bármikor, teljes egészében törölheti a tárolt adatait:
- **Böngésző-kiterjesztés**: a kiterjesztés eltávolításával, vagy a böngésző beállításaiban a webhelyadatok törlésével.
- **TUI/Desktop**: a `~/.config/pala/` mappa törlésével, vagy az alkalmazás "Összes mentett adat törlése" funkciójával.

## Kapcsolat

Adatvédelemmel vagy biztonsággal kapcsolatos kérdés, illetve sebezhetőség bejelentése esetén lásd a [SECURITY.md](../SECURITY.md) dokumentumot.
