// Search entries for the site-wide docs search (components/search/SearchModal.tsx).
export interface SearchIndexItem {
  id: string;
  pageId: string;
  tabId?: string;
  title: string;
  category: string;
  description: string;
  keywords: string[];
}

export const SEARCH_INDEX: SearchIndexItem[] = [
  {
    id: "inst-win",
    pageId: "installation",
    tabId: "windows",
    title: "Telepítés Windows alatt",
    category: "Kezdő Lépések / Telepítés",
    description: "Grafikus Inno Setup telepítő, Scoop parancs és Defender SmartScreen feloldás.",
    keywords: ["windows", "exe", "setup", "scoop", "smartscreen", "defender", "powershell", "eltávolítás"]
  },
  {
    id: "inst-android",
    pageId: "installation",
    tabId: "android",
    title: "Telepítés Android eszközökre",
    category: "Kezdő Lépések / Telepítés",
    description: "Universal, ARM64, ARMv7 (régebbi telefonok), x86_64 (BlueStacks emulátorok) és architektúra választó útmutató.",
    keywords: ["android", "apk", "universal", "arm64", "armv7", "32-bit", "x86_64", "emulátor", "bluestacks", "nox", "wsa", "telefon", "mobil"]
  },
  {
    id: "inst-android-termux",
    pageId: "installation",
    tabId: "android",
    title: "Android Termux telepítés (TUI, root nélkül)",
    category: "Kezdő Lépések / Telepítés",
    description: "pkg install dart, git clone és dart run — a Pala TUI futtatása Termux terminál-emulátorban APK nélkül.",
    keywords: ["termux", "pkg install", "dart", "tui", "terminál", "android", "root nélkül"]
  },
  {
    id: "inst-ios",
    pageId: "installation",
    tabId: "ios",
    title: "iOS (iPhone/iPad) — még nem elérhető",
    category: "Kezdő Lépések / Telepítés",
    description: "Miért nincs még iOS/iPhone verzió: Safari CORS-korlátok és az Apple fejlesztői díj. Hamarosan érkezik.",
    keywords: ["ios", "iphone", "ipad", "hamarosan", "nem elérhető", "cors", "apple developer", "safari", "pwa"]
  },
  {
    id: "inst-linux",
    pageId: "installation",
    tabId: "linux",
    title: "Telepítés Linux rendszerekre",
    category: "Kezdő Lépések / Telepítés",
    description: "Telepítő script, .deb csomag, AppImage, .tar.gz és Arch AUR (yay/paru).",
    keywords: ["linux", "ubuntu", "debian", "apt", "deb", "appimage", "aur", "arch", "manjaro", "yay", "paru", "script", "curl"]
  },
  {
    id: "inst-mac",
    pageId: "installation",
    tabId: "macos",
    title: "Telepítés macOS alatt",
    category: "Kezdő Lépések / Telepítés",
    description: "Homebrew telepítés Apple Silicon és Intel Mac gépekre.",
    keywords: ["macos", "mac", "apple", "silicon", "m1", "m2", "m3", "homebrew", "brew", "zsh"]
  },
  {
    id: "inst-ext",
    pageId: "installation",
    tabId: "extension",
    title: "Böngésző Bővítmény Telepítése",
    category: "Kezdő Lépések / Telepítés",
    description: "Manifest V3 bővítmény Chrome, Edge, Brave, Firefox böngészőkhöz.",
    keywords: ["bővítmény", "extension", "chrome", "edge", "brave", "firefox", "unpacked"]
  },
  {
    id: "compatibility",
    pageId: "installation",
    title: "Kompatibilitás és Rendszerkövetelmények",
    category: "Kezdő Lépések / Telepítés",
    description: "Támogatott operációs rendszerek, böngészők és iskolatípusok (általános, gimnázium, technikum).",
    keywords: ["kompatibilitás", "rendszerkövetelmény", "windows", "android", "mac", "gimnázium", "technikum"]
  },
  {
    id: "upgrade",
    pageId: "installation",
    title: "Frissítési Útmutató",
    category: "Kezdő Lépések / Telepítés",
    description: "Verziókövetés, adatmegőrzés és frissítés végrehajtása minden rendszeren.",
    keywords: ["frissítés", "upgrade", "update", "új verzió", "adatmegőrzés"]
  },
  {
    id: "hasznalat",
    pageId: "hasznalat",
    title: "Használat & CLI Kapcsolók",
    category: "Kezdő Lépések",
    description: "Kréta bejelentkezés, OM azonosító, --demo mód, --clear-cache és naptár export.",
    keywords: ["használat", "bejelentkezés", "om azonosító", "felhasználónév", "jelszó", "cli", "--demo", "--clear-cache", "--json", "--export-ics"]
  },
  {
    id: "files-configs",
    pageId: "files-configs",
    title: "Fájlok és Konfigurációk (Files & Configs)",
    category: "Kezdő Lépések",
    description: "Elérési utak (AppData, XDG, Library), config.json mezők és manuális szerkesztés.",
    keywords: ["fájlok", "config", "json", "appdata", "xdg", "cache.db", "konfiguráció", "szerkesztés", "notepad", "nano"]
  },
  {
    id: "gyorsbillentyuk",
    pageId: "gyorsbillentyuk",
    title: "Gyorsbillentyűk (Keybindings)",
    category: "Kezdő Lépések",
    description: "TUI navigáció: 1/d órarend, 2/g jegyek, 3/c célátlag szimulátor, 4/a hiányzások, w wrapped, r sync, q kilépés.",
    keywords: ["gyorsbillentyűk", "keybind", "billentyűzet", "1", "2", "3", "4", "d", "g", "c", "a", "w", "r", "q", "esc", "tab"]
  },
  {
    id: "platform-osszehasonlitas",
    pageId: "platformvalasztas",
    title: "Melyiket válasszam? (Platform Összehasonlítás)",
    category: "Változatok / Platform Összehasonlítás",
    description: "TUI, Desktop (Flutter), Mobile és Böngésző Kiterjesztés előnyei és hátrányai egy táblázatban.",
    keywords: ["melyiket válasszam", "összehasonlítás", "platform", "flutter", "tui vagy desktop", "melyik verzió", "előnyök", "hátrányok"]
  },
  {
    id: "tui-overview",
    pageId: "tui",
    title: "Pala TUI (Terminálos Felület)",
    category: "Változatok / TUI",
    description: "Erőforrás-takarékos parancssoros Kréta kliens, billentyűzet-vezérlés, témák és TUI dashboard.",
    keywords: ["tui", "terminál", "cli", "parancssor", "pala dash", "ascii", "linux", "macos", "powershell"]
  },
  {
    id: "desktop-overview",
    pageId: "desktop",
    title: "Pala Desktop (Grafikus Alkalmazás)",
    category: "Változatok / Desktop App",
    description: "Flutter alapú asztali alkalmazás heti mátrixszal, diagramokkal, átlagtrendekkel és bizonyítvány tervezővel.",
    keywords: ["desktop", "asztali", "gui", "windows", "flutter", "linux", "macos", "grafikus"]
  },
  {
    id: "mobile-overview",
    pageId: "mobile",
    title: "Pala Mobile (Mobil Alkalmazás)",
    category: "Változatok / Mobile App",
    description: "Android APK, érintés-optimalizált felület, zero ads, offline mód. iOS/iPhone hamarosan.",
    keywords: ["mobile", "mobil", "android", "apk", "ios", "iphone", "hamarosan", "érintőképernyő"]
  },
  {
    id: "extension-overview",
    pageId: "extension",
    title: "Böngésző Kiterjesztés (Extension)",
    category: "Változatok / Böngésző Kiterjesztés",
    description: "Chrome, Brave, Edge böngészőbővítmény mini popup gyorsnézettel és teljes vezérlőpulttal.",
    keywords: ["extension", "bővítmény", "kiterjesztés", "chrome", "brave", "edge", "popup", "dashboard"]
  },
  {
    id: "extension-session",
    pageId: "extension",
    title: "Kréta Munkamenet & 40-60 perces Időkorlát",
    category: "Változatok / Böngésző Kiterjesztés",
    description: "Hogyan kezeli a Pala az OAuth2 Access és Refresh tokeneket, és miért nem jelentkeztet ki 40-60 perc után.",
    keywords: ["munkamenet", "időkorlát", "token", "refresh token", "40 perc", "60 perc", "lejárás", "automatikus frissítés", "offline cache"]
  },
  {
    id: "extension-profile-api",
    pageId: "extension",
    title: "Profilom & Kréta API Korlátozások",
    category: "Változatok / Böngésző Kiterjesztés",
    description: "Miért hiányoznak banki és okmány adatok a Kréta mobil API-ból, globális szerkesztő és 1-kattintásos beolvasás.",
    keywords: ["profilom", "kréta api korlátozás", "nincs rögzítve", "bankszámla", "adóazonosító", "taj", "diákigazolvány", "adatok beolvasása"]
  },
  {
    id: "extension-popup-settings",
    pageId: "extension",
    title: "Popup Testreszabása",
    category: "Változatok / Böngésző Kiterjesztés",
    description: "Alapértelmezett kezdőlap, kompakt nézet, hero kártya, átlagsáv és jegykorlátok beállítása a popupban és dashboardon.",
    keywords: ["popup testreszabása", "kompakt nézet", "hero card", "átlag sáv", "max jegyek", "beállítások", "gyorsnézet"]
  },
  {
    id: "security",
    pageId: "security",
    title: "Zero-Knowledge & Titkosítás",
    category: "Biztonság & Architektúra",
    description: "Közvetlen TLS 1.3 Kréta OAuth2 kapcsolat, helyi AES-256 token tárolás és nulla telemetria.",
    keywords: ["biztonság", "titkosítás", "zero-knowledge", "aes-256", "tls 1.3", "oauth2", "telemetry"]
  },
  {
    id: "faq-website",
    pageId: "troubleshooting",
    title: "GYIK: Miért nincs nyilvános weboldalas verzió?",
    category: "Biztonság & Architektúra / GYIK",
    description: "CORS korlátok, központi szerver elkerülése, GDPR adatvédelmi határok és a kliensoldali modell.",
    keywords: ["miért nincs weboldal", "web app", "cors", "proxy", "gdpr", "szerver", "adatvédelem", "adatkezelés"]
  },
  {
    id: "faq-passwords",
    pageId: "troubleshooting",
    title: "GYIK: Biztonságos a jelszavam megadása?",
    category: "Biztonság & Architektúra / GYIK",
    description: "Közvetlen kapcsolat a hivatalos idp.e-kreta.hu szerverrel jelszótárolás nélkül.",
    keywords: ["jelszó", "biztonság", "token", "titkosítás", "idp.e-kreta.hu"]
  },
  {
    id: "faq-smartscreen",
    pageId: "troubleshooting",
    title: "GYIK: SmartScreen / Play Protect figyelmeztetés",
    category: "Biztonság & Architektúra / GYIK",
    description: "Nyílt forráskódú projekt független aláírás nélkül. Futtatás mindenképpen lépések.",
    keywords: ["smartscreen", "defender", "play protect", "vírus", "tanúsítvány", "futtatás mindenképpen"]
  },
  {
    id: "faq-login",
    pageId: "troubleshooting",
    title: "GYIK: Bejelentkezési hibák elhárítása",
    category: "Biztonság & Architektúra / GYIK",
    description: "Intézménykód ellenőrzése, Kréta szerver leállások kezelése és Teszt Elek demó mód.",
    keywords: ["bejelentkezés", "hiba", "szerverhiba", "karbantartás", "teszt elek", "demo"]
  },
  {
    id: "hasznalat-intezmenyek",
    pageId: "hasznalat",
    title: "Iskolakereső, OM Azonosító és Gondviselői Fiók",
    category: "Kezdő Lépések / Használat",
    description: "Iskolakódok (klik, szc), 11 jegyű 7-tel kezdődő diák OM azonosító, G- gondviselői fiókok és a beépített intézménykereső.",
    keywords: ["iskolakereső", "intézménykereső", "klik", "szc", "om azonosító", "gondviselő", "szülői fiók", "g-", "diákigazolvány"]
  },
  {
    id: "webui-overview",
    pageId: "webui",
    title: "Pala Webes Felület (Localhost Web UI)",
    category: "Változatok / Webes Felület",
    description: "pala --web vagy pala -w helyi webszerver, böngészős felület, egyedi kriptográfiai session token és zero-cloud adatvédelem.",
    keywords: ["webui", "web", "böngésző", "localhost", "127.0.0.1", "pala --web", "pala -w", "--web", "szerver", "felhőmentes", "privát"]
  },
  {
    id: "zero-proxy-arch",
    pageId: "security",
    title: "Zero-Proxy Architektúra Diagram",
    category: "Biztonság & Architektúra / Titkosítás",
    description: "Miért nem használ a Pala központi proxyt: közvetlen TLS 1.3 kapcsolat vs. veszélyes harmadik feles szervermodell.",
    keywords: ["zero-proxy", "proxy", "architektúra", "tls 1.3", "adatvédelem", "diagram", "biztonság", "gdpr", "központi szerver"]
  },
  {
    id: "kreta-errors",
    pageId: "troubleshooting",
    title: "Kréta API Hibakódok (HTTP 429, 502, 503, 401)",
    category: "Biztonság & Architektúra / Hibaelhárítás",
    description: "HTTP 429 túllépési korlát és Retry-After, 502/503 Kréta szerver leállás offline gyorsítótár, 401 csendes token megújítás.",
    keywords: ["hibakód", "429", "502", "503", "504", "401", "rate limit", "karbantartás", "leállás", "refresh token", "szerverhiba", "hiba", "túlterheltség"]
  },
  {
    id: "kreta-tortenet",
    pageId: "tortenet",
    title: "A Kréta- és Iskolai Kliensek Története (Idővonal)",
    category: "Közösség & Történet",
    description: "A Szivacs Naplótól a Filc, reFilc, Firka, Folio, Toll, rsfilc és Pala kliensekig, külföldi rendszerekig (Wulkanowy, BetterUntis) és a Kréta-feltörésig.",
    keywords: ["történet", "idővonal", "szivacs", "filc", "kréta feltörés", "feltörés", "refilc", "qwit", "firka", "folio", "toll", "rsfilc", "pala", "kronológia", "wulkanowy", "betteruntis", "discipulus", "papillon", "arisztokréta", "napló+"]
  },
  {
    id: "guide-dashboard-search",
    pageId: "guide-dashboard",
    title: "Élő Vezérlőpult, Órarend és Helyettesítések",
    category: "B. Funkció Útmutatók",
    description: "CountdownHeroCard óra-visszaszámláló, helyettesítések, elmaradó órák, A/B hét váltás és .ics naptár export.",
    keywords: ["vezérlőpult", "dashboard", "órarend", "helyettesítés", "elmaradó óra", "ics", "naptár", "a/b hét", "visszaszámláló"]
  },
  {
    id: "guide-grades-search",
    pageId: "guide-grades",
    title: "Jegyek, Súlyozott Átlag és Szellem Jegy Szimulátor",
    category: "B. Funkció Útmutatók",
    description: "Súlyozott GPA számítás, érdemjegy színpszichológia (1-5), interaktív Szellem Jegy kalkulátor és Bizonyítvány Tervező.",
    keywords: ["jegyek", "átlag", "gpa", "szellem jegy", "ghost grade", "kalkulátor", "szimulátor", "bizonyítvány tervező", "mátrix"]
  },
  {
    id: "guide-absences-search",
    pageId: "guide-absences",
    title: "Jelenlét, 250 Órás Mulasztási Határ és Szülői Keret",
    category: "B. Funkció Útmutatók",
    description: "250 órás törvényi mulasztási határ, 30%-os tantárgyi küszöb, szülői igazolási keret és státusz színkódok.",
    keywords: ["mulasztás", "hiányzás", "250 óra", "30%", "szülői igazolás", "igazolatlan", "késés", "osztályozó vizsga"]
  },
  {
    id: "dev-arch-search",
    pageId: "dev-architecture",
    title: "Architektúra & Adaptív Flutter Layout (<600dp vs >=600dp)",
    category: "C. Fejlesztői & API Specifikációk",
    description: "One Core Several Clients felépítés, M3 NavigationBar vs NavigationRail, IndexedStack állapotmegőrzés és WCAG 2.1 AA 48x48dp célterületek.",
    keywords: ["architektúra", "flutter", "600dp", "navigationrail", "navigationbar", "wcag", "material design 3", "m3", "indexedstack"]
  },
  {
    id: "dev-ext-tui-search",
    pageId: "dev-ext-tui",
    title: "Extension Manifest V3 & TUI Null-Vibrálású Motor",
    category: "C. Fejlesztői & API Specifikációk",
    description: "Chrome/Firefox MV3 380x580 Popup és Side Panel, valamint a Dart TUI TuiScreenBuffer soronkénti diff-renderelője és Unicode keretei.",
    keywords: ["manifest v3", "mv3", "sidepanel", "popup", "tuiscreenbuffer", "unicode", "ansi 256", "alternate screen"]
  },
  {
    id: "dev-contrib-search",
    pageId: "dev-contributing",
    title: "Fejlesztői Útmutató, Tesztelés & Honosítás (i18n)",
    category: "C. Fejlesztői & API Specifikációk",
    description: "API és DemoData szinkronizáció (lib/ és extension/), magyar UI szabályok, dart analyze --fatal-infos és CI ellenőrzések.",
    keywords: ["contributing", "közreműködés", "i18n", "honosítás", "teszt", "dart analyze", "flutter analyze", "demo_data"]
  }
];
