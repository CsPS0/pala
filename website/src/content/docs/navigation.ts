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

