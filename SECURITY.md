# Biztonsági Irányelvek (Security Policy)

A **Pala** csapata elkötelezett a felhasználói adatok és hitelesítési tokenek védelme mellett. Ez a dokumentum összefoglalja a támogatott verziókat és a sebezhetőségek felelős bejelentésének menetét.

## Támogatott Verziók

A biztonsági javítások kizárólag a legfrissebb kiadásokra érhetők el:

| Verzió | Támogatott |
| :--- | :--- |
| Legfrissebb (v2.x) | Igen |
| Régebbi verziók | Nem |

## Sebezhetőség Bejelentése (Reporting a Vulnerability)

Ha biztonsági hibát, sebezhetőséget vagy adatkezelési hiányosságot találtál a Pala alkalmazásban, kérjük, **ne hozz létre nyilvános Issue-t**!

Ehelyett használd a GitHub privát bejelentő funkcióját:

1. Nyisd meg a repository [Biztonsági Tanácsadások (Security Advisories)](https://github.com/CsPS0/pala/security/advisories/new) oldalát.
2. Kattints a **"Report a vulnerability"** gombra.
3. Részletezd a talált hibát, a reprodukálás lépéseit és a lehetséges kockázatot.

### Válaszidő és Javítási Folyamat
- A bejelentéseket igyekszünk 48 órán belül áttekinteni és visszajelzést adni.
- A megerősített hibákra soron kívül biztonsági javítást adunk ki.
- A bejelentő nevét (igény esetén) köszönettel feltüntetjük a kiadási megjegyzésekben.

## Adatbiztonsági Alapelvek
- **Helyi Titkosítás**: A hitelesítési tokenek AES-GCM titkosítással, véletlenszerű IV-vel kerülnek tárolásra a felhasználói könyvtárban (`~/.config/pala/`).
- **Közvetlen Kapcsolat**: Az alkalmazás kizárólag a hivatalos Kréta szerverekkel (`*.e-kreta.hu`) és a GitHub API-val (frissítés-ellenőrzéshez) kommunikál.
- **Nincs Harmadik Fél**: Az alkalmazás nem tartalmaz telemetriát, analitikát vagy külső adatgyűjtést.
