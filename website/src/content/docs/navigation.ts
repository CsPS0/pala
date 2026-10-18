export interface TocHeading {
  id: string;
  label: string;
  level: 2 | 3;
}

export interface DocNavItem {
  id: string;
  label: string;
  route: string;
  kicker: string;
  badge?: string;
}

export interface DocNavGroup {
  id: string;
  category: string;
  routePrefix: string;
  items: DocNavItem[];
}

export interface SearchEntry {
  id: string;
  pageId: string;
  tabId?: string;
  anchorId?: string;
  route: string;
  title: string;
  category: string;
  description: string;
  keywords: string[];
}

export const DOC_NAVIGATION: DocNavGroup[] = [
  {
    id: "getting-started",
    category: "A. Kezdő Lépések (Getting Started)",
    routePrefix: "/docs/getting-started",
    items: [
      {
        id: "installation",
        label: "Telepítés & Beállítás",
        route: "/docs/getting-started",
        kicker: "KEZDŐ LÉPÉSEK / TELEPÍTÉS MINDEN PLATFORMRA",
        badge: "Alap",
      },
      {
        id: "hasznalat",
        label: "Első Bejelentkezés & CLI",
        route: "/docs/getting-started#elso-bejelentkezes",
        kicker: "KEZDŐ LÉPÉSEK / ELSŐ KRÉTA BEJELENTKEZÉS & CLI",
      },
      {
        id: "files-configs",
        label: "Fájlok & Konfigurációk",
        route: "/docs/getting-started#files-configs",
        kicker: "KEZDŐ LÉPÉSEK / FÁJLOK & KONFIGURÁCIÓK",
      },
      {
        id: "gyorsbillentyuk",
        label: "Gyorsbillentyűk",
        route: "/docs/getting-started#gyorsbillentyuk",
        kicker: "KEZDŐ LÉPÉSEK / GYORSBILLENTYŰK",
      },
    ],
  },
  {
    id: "guides",
    category: "B. Funkció Útmutatók (Feature Guides)",
    routePrefix: "/docs/guides",
    items: [
      {
        id: "guide-dashboard",
        label: "Vezérlőpult & Órarend",
        route: "/docs/guides#vezerlopult-es-orarend",
        kicker: "FUNKCIÓ ÚTMUTATÓK / VEZÉRLŐPULT & ÓRAREND",
      },
      {
        id: "guide-grades",
        label: "Jegyek & Szellem Jegy",
        route: "/docs/guides#jegyek-es-atlagok",
        kicker: "FUNKCIÓ ÚTMUTATÓK / JEGYEK & SZELLEM JEGY",
        badge: "Szimulátor",
      },
      {
        id: "guide-absences",
        label: "Mulasztások & 250 Órás Limit",
        route: "/docs/guides#mulasztasok-es-hatarok",
        kicker: "FUNKCIÓ ÚTMUTATÓK / JELENLÉT & 250 ÓRÁS LIMIT",
      },
    ],
  },
  {
    id: "developers",
    category: "C. Fejlesztői & API Specifikációk",
    routePrefix: "/docs/developers",
    items: [
      {
        id: "dev-architecture",
        label: "Architektúra & Flutter (<600dp)",
        route: "/docs/developers#architektura",
        kicker: "FEJLESZTŐI SPECIFIKÁCIÓK / ARCHITEKTÚRA & ADAPTÍV LAYOUT",
        badge: "M3 / WCAG",
      },
      {
        id: "security",
        label: "Kréta API & Helyi Titkosítás",
        route: "/docs/developers#kreta-api-specifikacio",
        kicker: "FEJLESZTŐI SPECIFIKÁCIÓK / KRÉTA API & TITKOSÍTÁS",
      },
      {
        id: "dev-ext-tui",
        label: "Extension MV3 & TUI Motor",
        route: "/docs/developers#extension-es-tui",
        kicker: "FEJLESZTŐI SPECIFIKÁCIÓK / EXTENSION MV3 & TUI ARCHITEKTÚRA",
      },
      {
        id: "dev-contributing",
        label: "Közreműködés & Honosítás (i18n)",
        route: "/docs/developers#fejlesztoi-utmutato",
        kicker: "FEJLESZTŐI SPECIFIKÁCIÓK / KÖZREMŰKÖDÉS & I18N",
      },
    ],
  },
  {
    id: "ecosystem",
    category: "D. Platformok & Ökoszisztéma",
    routePrefix: "/docs",
    items: [
      {
        id: "platformvalasztas",
        label: "Melyiket válasszam?",
        route: "/docs?page=platformvalasztas",
        kicker: "PLATFORMOK / ÖSSZEHASONLÍTÁS",
      },
      {
        id: "tui",
        label: "Pala TUI (Terminál)",
        route: "/docs?page=tui",
        kicker: "PLATFORMOK / TUI TERMINÁL",
      },
      {
        id: "desktop",
        label: "Pala Desktop App",
        route: "/docs?page=desktop",
        kicker: "PLATFORMOK / DESKTOP APP",
      },
      {
        id: "mobile",
        label: "Pala Mobile App",
        route: "/docs?page=mobile",
        kicker: "PLATFORMOK / MOBILE APP",
      },
      {
        id: "extension",
        label: "Böngésző Kiterjesztés",
        route: "/docs?page=extension",
        kicker: "PLATFORMOK / BÖNGÉSZŐ KITERJESZTÉS",
      },
      {
        id: "webui",
        label: "Localhost Web UI",
        route: "/docs?page=webui",
        kicker: "PLATFORMOK / LOCALHOST WEB UI",
      },
      {
        id: "troubleshooting",
        label: "Hibaelhárítás & GYIK",
        route: "/docs?page=troubleshooting",
        kicker: "TÁMOGATÁS / HIBAELHÁRÍTÁS & GYIK",
      },
      {
        id: "tortenet",
        label: "Kliensek Története",
        route: "/docs?page=tortenet",
        kicker: "KÖZÖSSÉG / A KRÉTA-KLIENSEK TÖRTÉNETE",
      },
    ],
  },
];

export const PAGE_TOC_MAP: Record<string, TocHeading[]> = {
  installation: [
    { id: "telepites-platformok", label: "Platformválasztó sáv", level: 2 },
    { id: "telepites-lepesek", label: "Telepítési lépések", level: 2 },
    { id: "rendszerkovetelmenyek", label: "Rendszerkövetelmények", level: 3 },
    { id: "automatikus-frissites", label: "Verziókövetés & Frissítés", level: 3 },
    { id: "eltavolitas", label: "Komponens kezelés & Eltávolítás", level: 3 },
  ],
  hasznalat: [
    { id: "elso-bejelentkezes", label: "Első Kréta bejelentkezés", level: 2 },
    { id: "intezmeny-es-om", label: "Iskolakereső & OM azonosító", level: 3 },
    { id: "cli-kapcsolok", label: "Parancssori (CLI) kapcsolók", level: 2 },
    { id: "demo-es-export", label: "Demó mód & .ics naptár export", level: 3 },
  ],
  "files-configs": [
    { id: "fajl-eleresi-utak", label: "Konfigurációs könyvtárak", level: 2 },
    { id: "interaktiv-config-epito", label: "Interaktív config.json építő", level: 2 },
    { id: "tantargyi-alnevek", label: "Tantárgyi álnevek (Aliases)", level: 3 },
  ],
  gyorsbillentyuk: [
    { id: "globalis-billentyuk", label: "Globális TUI navigáció", level: 2 },
    { id: "szellem-jegy-billentyuk", label: "Szellem Jegy vezérlés", level: 3 },
    { id: "tab-specifikus-billentyuk", label: "Nézet-specifikus parancsok", level: 3 },
  ],
  "guide-dashboard": [
    { id: "elo-orafigyelo", label: "Élő Órafigyelő (CountdownHeroCard)", level: 2 },
    { id: "helyettesites-es-elmaradas", label: "Helyettesítések & Elmaradó órák", level: 2 },
    { id: "ab-het-es-ics", label: "A/B hét váltás & .ics Export", level: 3 },
  ],
  "guide-grades": [
    { id: "sulyozott-atlag-szamitas", label: "Súlyozott tanulmányi átlag (GPA)", level: 2 },
    { id: "szinpszichologia", label: "Érdemjegy színpszichológia", level: 3 },
    { id: "szellem-jegy-szimulator", label: "Szellem Jegy (Ghost Grade) kalkulátor", level: 2 },
    { id: "bizonyitvany-tervezo", label: "Bizonyítvány Tervező & Mátrix", level: 3 },
  ],
  "guide-absences": [
    { id: "torvenyi-250-ora", label: "250 órás törvényi mulasztási határ", level: 2 },
    { id: "tantargyi-30-szazalek", label: "30%-os tantárgyi küszöb", level: 3 },
    { id: "szuloi-igazolasi-keret", label: "Szülői igazolási keret", level: 2 },
    { id: "mulasztas-szurok", label: "Státusz színkódok & szűrők", level: 3 },
  ],
  "dev-architecture": [
    { id: "one-core-several-clients", label: "One Core, Several Clients modell", level: 2 },
    { id: "adaptiv-600dp-layout", label: "Adaptív 600dp töréspont (M3)", level: 2 },
    { id: "allapotmegorzes", label: "Állapotmegőrzés (IndexedStack)", level: 3 },
    { id: "wcag-akadalymentesseg", label: "WCAG 2.1 AA érintési célterületek", level: 3 },
  ],
  security: [
    { id: "oauth2-pkce-folyamat", label: "Kréta OAuth2 PKCE hitelesítés", level: 2 },
    { id: "silent-token-refresh", label: "Csendes Token Megújítás (Refresh)", level: 3 },
    { id: "helyi-aes256-titkositas", label: "Helyi titkosítás & Secure Storage", level: 2 },
    { id: "zero-proxy-diagram", label: "Zero-Proxy architektúra összehasonlítás", level: 3 },
  ],
  "dev-ext-tui": [
    { id: "manifest-v3-architektura", label: "Böngésző Bővítmény (Manifest V3)", level: 2 },
    { id: "popup-es-sidepanel", label: "380×580 Popup & Side Panel", level: 3 },
    { id: "tui-screenbuffer", label: "TUI Null-vibrálású képernyőpuffer", level: 2 },
    { id: "unicode-box-render", label: "Kerekített Unicode keretek & ANSI 256", level: 3 },
  ],
  "dev-contributing": [
    { id: "repo-struktura", label: "Monorepo könyvtárstruktúra", level: 2 },
    { id: "api-es-demodata-szinkron", label: "API & DemoData szinkronizáció", level: 2 },
    { id: "honositas-i18n", label: "Magyar UI & Honosítási szabályok", level: 3 },
    { id: "ci-ellenorzo-parancsok", label: "Kötelező CI tesztek & Linterek", level: 2 },
  ],
  platformvalasztas: [
    { id: "platform-matrix", label: "Kliensek összehasonlító mátrixa", level: 2 },
    { id: "mikor-melyiket", label: "Melyik változatot válaszd?", level: 3 },
  ],
  tui: [
    { id: "tui-felulet", label: "Kétpaneles TUI munkaterület", level: 2 },
    { id: "tui-szinkodok", label: "ANSI 256 színpszichológia", level: 3 },
  ],
  desktop: [
    { id: "desktop-gui", label: "Asztali Flutter alkalmazás", level: 2 },
    { id: "desktop-funkciok", label: "Master-Detail nézetek", level: 3 },
  ],
  mobile: [
    { id: "mobile-app", label: "Android & Mobil élmény", level: 2 },
    { id: "mobile-ergonomia", label: "Alsó navigáció & Offline mód", level: 3 },
  ],
  extension: [
    { id: "extension-felulet", label: "Popup és Teljes Vezérlőpult", level: 2 },
    { id: "extension-token-kezeles", label: "Munkamenet & Token frissítés", level: 3 },
  ],
  webui: [
    { id: "localhost-webui", label: "Helyi webszerver (pala --web)", level: 2 },
    { id: "webui-session-token", label: "Kriptográfiai munkamenet-védelem", level: 3 },
  ],
  troubleshooting: [
    { id: "gyakori-kerdesek", label: "Gyakran Ismételt Kérdések (GYIK)", level: 2 },
    { id: "kreta-http-hibakodok", label: "Kréta HTTP hibakódok (429, 502, 503)", level: 2 },
  ],
  tortenet: [
    { id: "kreta-hatter", label: "Háttér", level: 2 },
    { id: "kreta-kliensek", label: "A kliensek idővonala", level: 2 },
  ],
};
