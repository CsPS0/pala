// The community project list for /tortenet. Kept out of the client component
// so the page (a server component) can look up release versions at build time.
import type React from "react";
import { Archive, Code, History, Home, Monitor, PenTool, Smartphone, Terminal, Zap } from "lucide-react";

export type ProjectCategory = "kreta" | "neptun" | "tools";
export type FilterMode = "all" | "active" | "archived";

export interface CommunityProject {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  image?: string;
  title: string;
  author: string;
  description: string;
  url: string;
  websiteUrl?: string;
  repo: string;
  category: ProjectCategory;
  badge?: string;
  isArchived?: boolean;
  status?: string;
}

export const PROJECTS: CommunityProject[] = [
  // --- Kréta clients & extensions (left column) ---
  {
    icon: PenTool,
    image: "/community/qwit-development_firka.png",
    title: "Firka",
    author: "QwIT Development",
    description: "A QwIT csapat Flutter alapú Kréta kliense, 2025 óta fejlesztik.",
    url: "https://github.com/QwIT-Development/firka",
    websiteUrl: "https://firka.app/",
    repo: "QwIT-Development/firka",
    category: "kreta",
    badge: "Újraírás",
  },
  {
    icon: Smartphone,
    image: "/community/qwit-development_app-legacy.png",
    title: "app-legacy (refilc)",
    author: "reFilc / QwIT Development",
    description: "A Filc utódjaként indult reFilc továbbfejlesztett változata (Flutter).",
    url: "https://github.com/QwIT-Development/app-legacy",
    repo: "QwIT-Development/app-legacy",
    category: "kreta",
    badge: "Mobilapp",
  },
  {
    icon: Smartphone,
    image: "/community/zan1456_folio.png",
    title: "Folio",
    author: "Zan1456",
    description: "A Firka korábbi (legacy) kódjának felfrissített változata, 2026-tól (Flutter).",
    url: "https://github.com/Zan1456/folio",
    websiteUrl: "https://folio.zan1456.dev/",
    repo: "Zan1456/folio",
    category: "kreta",
    badge: "Material You",
  },
  {
    icon: Terminal,
    image: "/community/jarjk_rsfilc.png",
    title: "RozsdásFilc (rsfilc)",
    author: "jarjk",
    description: "Parancssori Kréta kliens Rust nyelven, 2024 óta.",
    url: "https://github.com/jarjk/rsfilc",
    repo: "jarjk/rsfilc",
    category: "kreta",
    badge: "Rust CLI",
  },
  {
    icon: Monitor,
    image: "/community/doomhyena_toll.png",
    title: "Toll",
    author: "doomhyena",
    description: "Asztali Kréta kliens Windowsra, Linuxra és macOS-re (Go, Wails, React). 2026-ban archiválták.",
    url: "https://github.com/doomhyena/toll",
    repo: "doomhyena/toll",
    category: "kreta",
    isArchived: true,
    badge: "Asztali",
  },
  {
    icon: Archive,
    image: "/community/coware-apps_ellenorzo.png",
    title: "Arisztokréta",
    author: "Coware Apps",
    description: "Nem hivatalos, KRÉTA-kompatibilis ellenőrző alkalmazás (TypeScript), 2020-ban indult.",
    url: "https://github.com/Coware-Apps/ellenorzo",
    repo: "Coware-Apps/ellenorzo",
    category: "kreta",
    status: "Megszűnt / Archivált",
  },
  {
    icon: Archive,
    image: "/community/coware-apps_naplo.png",
    title: "Napló+ (Tanári Napló)",
    author: "Coware Apps",
    description: "Független, KRÉTA-kompatibilis tanári napló alkalmazás (2019–2021).",
    url: "https://github.com/Coware-Apps/naplo",
    repo: "Coware-Apps/naplo",
    category: "kreta",
    isArchived: true,
    status: "Megszűnt / Archivált",
  },
  {
    icon: Archive,
    image: "/community/filc_filc.png",
    title: "Filc",
    author: "Filc Team",
    description: "Nem hivatalos e-napló alkalmazás a Kréta rendszerhez (2020–2023), mobilon és asztalon.",
    url: "https://github.com/filc/naplo-archive",
    repo: "filc/naplo-archive",
    isArchived: true,
    status: "Megszűnt / Archivált",
    category: "kreta",
  },
  {
    icon: History,
    image: "/community/boapps_szivacs-naplo.png",
    title: "Szivacs-Naplo",
    author: "boapps",
    description: "Multiplatform kliensalkalmazás az e-napló rendszerhez (2018–2020).",
    url: "https://github.com/boapps/Szivacs-Naplo",
    repo: "boapps/Szivacs-Naplo",
    isArchived: true,
    status: "Megszűnt / Archivált",
    category: "kreta",
  },

  // --- University & Neptun (middle column) ---
  {
    icon: Zap,
    image: "/community/rozsadomb_neptun-powerup.png",
    title: "Neptun PowerUp! Next & NG",
    author: "rozsadomb",
    description: "A Neptun PowerUp! új változata a megújult Neptun webes felülethez (TypeScript).",
    url: "https://github.com/rozsadomb/neptun-powerup",
    websiteUrl: "https://neptun-powerup.com/",
    repo: "rozsadomb/neptun-powerup",
    category: "neptun",
    badge: "Új felület",
  },
  {
    icon: Monitor,
    image: "/community/davidsusu_szaturn.png",
    title: "Szaturn",
    author: "davidsusu",
    description: "Böngészőbővítmény, amely átláthatóbb felületet ad a Neptunnak.",
    url: "https://github.com/davidsusu/szaturn",
    repo: "davidsusu/szaturn",
    category: "neptun",
    badge: "Modern UI",
  },
  {
    icon: Archive,
    image: "/community/solymosi_npu.png",
    title: "Neptun PowerUp! (NPU)",
    author: "Solymosi Máté",
    description: "Böngészőbővítmény a régi Neptun felülethez (2014–2024), ma archivált.",
    url: "https://github.com/solymosi/npu",
    repo: "solymosi/npu",
    category: "neptun",
    isArchived: true,
    status: "Megszűnt / Archivált",
  },
  {
    icon: Archive,
    image: "/community/nanda070_karmin.png",
    title: "Karmin (ELTE Mobil)",
    author: "Nanda070",
    description: "Nem hivatalos Neptun mobilkliens ELTE hallgatóknak (Flutter), archivált.",
    url: "https://github.com/Nanda070/karmin",
    repo: "Nanda070/karmin",
    category: "neptun",
    isArchived: true,
    status: "Megszűnt / Archivált",
  },

  // --- Tools & IoT (right column) ---
  {
    icon: Home,
    image: "/community/majorcs_kreta-homeassistant.png",
    title: "Kréta Okosotthon",
    author: "majorcs",
    description: "Nem hivatalos Kréta integráció a Home Assistant okosotthon-rendszerhez.",
    url: "https://github.com/majorcs/kreta-homeassistant",
    repo: "majorcs/kreta-homeassistant",
    category: "tools",
    badge: "Home Assistant",
  },
  {
    icon: Code,
    image: "/community/bczsalba_ekreta-docs-v3.png",
    title: "e-Kréta API dokumentáció",
    author: "bczsalba",
    description: "Nem hivatalos dokumentáció a Kréta API 2-es és újabb verzióihoz (Python példákkal).",
    url: "https://github.com/bczsalba/ekreta-docs-v3",
    repo: "bczsalba/ekreta-docs-v3",
    category: "tools",
    badge: "API Specifikáció",
  },
];
