"use client";

import React, { useState, useEffect } from "react";
import {
  ExternalLink,
  Terminal,
  Smartphone,
  PenTool,
  Monitor,
  Globe,
  Archive,
  History,
  Sparkles,
  Zap,
  Home,
  Code,
  Users,
  BookOpen,
  GraduationCap,
} from "lucide-react";

type ProjectCategory = "kreta" | "neptun" | "tools";
type FilterMode = "all" | "active" | "archived";

interface CommunityProject {
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

const PROJECTS: CommunityProject[] = [
  // --- Kréta clients & extensions (left column) ---
  {
    icon: PenTool,
    image: "/community/qwit-development_firka.png",
    title: "Firka",
    author: "QwIT Development",
    description: "A modern nyílt forráskódú Kréta kliens fejlesztések egyik meghatározó alapköve és elődje.",
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
    description: "A klasszikus reFilc Android és Flutter alapú mobil Kréta kliens nyílt kódbázisa.",
    url: "https://github.com/QwIT-Development/app-legacy",
    repo: "QwIT-Development/app-legacy",
    category: "kreta",
    badge: "Mobilapp",
  },
  {
    icon: Smartphone,
    image: "/community/zan1456_folio.png",
    title: "Folio",
    author: "Folio Team / Zan1456",
    description: "Modern, nyílt forráskódú Kréta kliens Material You dizájnnal és fejlett átlagszámítással.",
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
    description: "KRÉTA kliens Rust nyelven, villámgyors és memóriahatékony parancssori és TUI felülettel.",
    url: "https://github.com/jarjk/rsfilc",
    repo: "jarjk/rsfilc",
    category: "kreta",
    badge: "Rust CLI",
  },
  {
    icon: Monitor,
    image: "/community/doomhyena_toll.png",
    title: "Toll",
    author: "Anasztázia (doomhyena)",
    description: "Natív asztali KRÉTA kliens Windows, Linux és macOS rendszerekre jegyekkel és órarenddel.",
    url: "https://github.com/doomhyena/toll",
    repo: "doomhyena/toll",
    category: "kreta",
    badge: "Asztali",
  },
  {
    icon: Archive,
    image: "/community/coware-apps_ellenorzo.png",
    title: "Arisztokréta",
    author: "Coware Apps",
    description: "Nyílt forráskódú alternatív ellenőrző alkalmazás TypeScript és Ionic keretrendszerben.",
    url: "https://github.com/Coware-Apps/ellenorzo",
    repo: "Coware-Apps/ellenorzo",
    category: "kreta",
    isArchived: true,
    status: "Megszűnt / Archivált",
  },
  {
    icon: Archive,
    image: "/community/coware-apps_naplo.png",
    title: "Napló+ (Tanári Napló)",
    author: "Coware Apps",
    description: "Független KRÉTA-kompatibilis tanári napló pedagógusok számára, hiányzás- és jegykezeléssel.",
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
    description: "A magyar diákközösség legelső és legnépszerűbb nyílt forráskódú alternatív Kréta kliense.",
    url: "https://github.com/filc/filc",
    repo: "filc/filc",
    isArchived: true,
    status: "Megszűnt / Archivált",
    category: "kreta",
  },
  {
    icon: History,
    image: "/community/boapps_szivacs-naplo.png",
    title: "Szivacs-Naplo",
    author: "boapps",
    description: "A legendás korai Androidos e-Kréta kliens, a közösségi kliensfejlesztés egyik úttörője.",
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
    author: "rozsadomb & l1pz",
    description: "TypeScript és React alapú modern átirat a 2024–2026 között bevezetett megújult Neptun felülethez.",
    url: "https://github.com/rozsadomb/neptun-powerup",
    websiteUrl: "https://neptun-powerup.com/",
    repo: "rozsadomb/neptun-powerup",
    category: "neptun",
    badge: "Új felület",
  },
  {
    icon: Zap,
    image: "/community/letsupdate_csn.png",
    title: "CSN — Captcha Solver",
    author: "LetsUpdate",
    description: "Kliensoldali OCR képfelismerő kiegészítő a tárgyfelvételi biztonsági kódok automatikus kitöltésére.",
    url: "https://github.com/LetsUpdate/CSN",
    repo: "LetsUpdate/CSN",
    category: "neptun",
    badge: "OCR motor",
  },
  {
    icon: Monitor,
    image: "/community/davidsusu_szaturn.png",
    title: "Szaturn",
    author: "davidsusu",
    description: "Modern kártyás, reszponzív felületi motor a Neptun nehézkes ASP.NET WebForms táblázatainak kiváltására.",
    url: "https://github.com/davidsusu/szaturn",
    repo: "davidsusu/szaturn",
    category: "neptun",
    badge: "Modern UI",
  },
  {
    icon: Archive,
    image: "/community/solymosi_npu.png",
    title: "Neptun PowerUp! (NPU)",
    author: "Solymosi Máté (szalio)",
    description: "A legendás egyetemi kiegészítő: automatikus munkamenet-védelem (Keep-Alive), KKI-kalkulátor és helyfigyelő.",
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
    description: "Független, nyílt forráskódú Flutter mobilalkalmazás ELTE hallgatóknak gyors órarenddel és vizsgafelülettel.",
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
    description: "Kréta integráció Home Assistanthez: másnapi első óra, házi feladatok és órarend fali okoskijelzőkre.",
    url: "https://github.com/majorcs/kreta-homeassistant",
    repo: "majorcs/kreta-homeassistant",
    category: "tools",
    badge: "Home Assistant",
  },
  {
    icon: Code,
    image: "/community/bczsalba_ekreta-docs-v3.png",
    title: "e-Kréta Docs v3 & Asztal",
    author: "bczsalba",
    description: "A Kréta v2 és v3 REST API nyilvános specifikációja, hitelesítési leírása és minimalista Python kliense.",
    url: "https://github.com/bczsalba/ekreta-docs-v3",
    repo: "bczsalba/ekreta-docs-v3",
    category: "tools",
    badge: "API Specifikáció",
  },
];

function getCategoryStyles(category: ProjectCategory, isArchived?: boolean) {
  if (isArchived) {
    return {
      card: "bg-[#151518]/70 border border-dashed border-[#ff453a]/30 hover:border-[#ff453a]/70 hover:bg-[#18181c] opacity-85 hover:opacity-100 shadow-[0_0_20px_rgba(255,69,58,0.04)]",
      iconBg: "bg-[#ff453a]/10 text-[#ff453a] border-[#ff453a]/25",
      badge: "bg-[#ff453a]/15 text-[#ff453a] border-[#ff453a]/35",
      author: "text-[#8c8c94]",
      linkHover: "hover:text-[#f3f3f6]",
    };
  }

  switch (category) {
    case "neptun":
      return {
        card: "bg-[#1b1b1f] border border-[#28282d] hover:border-[#0a84ff] hover:bg-[#1b1e28]",
        iconBg: "bg-[#0a84ff]/10 text-[#0a84ff] border-[#0a84ff]/25",
        badge: "bg-[#0a84ff]/10 text-[#0a84ff] border-[#0a84ff]/25 text-[#0a84ff]",
        author: "text-[#0a84ff]",
        linkHover: "hover:text-[#0a84ff]",
      };
    case "tools":
      return {
        card: "bg-[#1b1b1f] border border-[#28282d] hover:border-[#30d158] hover:bg-[#1a231d]",
        iconBg: "bg-[#30d158]/10 text-[#30d158] border-[#30d158]/25",
        badge: "bg-[#30d158]/10 text-[#30d158] border-[#30d158]/25 text-[#30d158]",
        author: "text-[#30d158]",
        linkHover: "hover:text-[#30d158]",
      };
    case "kreta":
    default:
      return {
        card: "bg-[#1b1b1f] border border-[#28282d] hover:border-[#ff8800] hover:bg-[#222227]",
        iconBg: "bg-[#ff8800]/10 text-[#ff8800] border-[#ff8800]/20",
        badge: "bg-[#ff8800]/10 text-[#ff8800] border-[#ff8800]/20 text-[#ff8800]",
        author: "text-[#ff8800]",
        linkHover: "hover:text-[#ff8800]",
      };
  }
}

function ProjectCard({
  project,
  versionTag,
}: {
  project: CommunityProject;
  versionTag?: string;
}) {
  const IconComp = project.icon;
  const isArchived = Boolean(project.isArchived);
  const styles = getCategoryStyles(project.category, isArchived);
  const [imageError, setImageError] = useState(false);

  return (
    <div
      className={`p-4 sm:p-5 rounded-2xl flex flex-col justify-between transition-all hover:-translate-y-0.5 group ${styles.card}`}
    >
      <div>
        <div className="flex items-start justify-between gap-3 mb-2.5">
          <div className="flex items-center gap-3 min-w-0">
            <div
              className={`w-10 h-10 rounded-xl overflow-hidden flex items-center justify-center shrink-0 border bg-[#111114] ${styles.iconBg}`}
            >
              {project.image && !imageError ? (
                <img
                  src={project.image}
                  alt={project.title}
                  className="w-full h-full object-cover rounded-xl"
                  onError={() => setImageError(true)}
                  loading="lazy"
                />
              ) : (
                <IconComp size={18} />
              )}
            </div>
            <div className="min-w-0">
              <h4 className="text-sm sm:text-base font-bold text-[#f3f3f6] truncate group-hover:text-white">
                {project.title}
              </h4>
              <p className={`text-[11px] font-semibold truncate ${styles.author}`}>
                {project.author}
              </p>
            </div>
          </div>

          <div className="shrink-0 flex items-center gap-1.5">
            {isArchived ? (
              <span className="text-[10px] font-bold bg-[#ff453a]/15 text-[#ff453a] border border-[#ff453a]/35 px-2 py-0.5 rounded-full whitespace-nowrap">
                {project.status || "Archivált"}
              </span>
            ) : (
              <>
                {project.badge && (
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full border whitespace-nowrap ${styles.badge}`}
                  >
                    {project.badge}
                  </span>
                )}
                {versionTag && (
                  <span className="text-[10px] font-bold bg-[#151518] text-[#ff8800] border border-[#28282d] px-2 py-0.5 rounded-full font-mono whitespace-nowrap">
                    {versionTag}
                  </span>
                )}
              </>
            )}
          </div>
        </div>

        <p className="text-xs text-[#8c8c94] leading-relaxed mb-3 line-clamp-2">
          {project.description}
        </p>
      </div>

      <div className="pt-2.5 border-t border-[#28282d]/70 flex items-center justify-between text-xs gap-2">
        <span className="text-[11px] font-mono text-[#55555c] truncate max-w-[130px]">
          {project.repo}
        </span>
        <div className="flex items-center gap-2.5 shrink-0">
          {project.websiteUrl && (
            <a
              href={project.websiteUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={`inline-flex items-center gap-1 text-[11px] font-bold transition-colors text-[#f3f3f6] ${styles.linkHover}`}
              title={`${project.title} hivatalos weboldala`}
            >
              <Globe size={12} />
              <span>Weboldal</span>
            </a>
          )}
          <a
            href={project.url}
            target="_blank"
            rel="noopener noreferrer"
            className={`inline-flex items-center gap-1 text-[11px] font-bold transition-colors text-[#8c8c94] ${styles.linkHover}`}
          >
            <span>GitHub</span>
            <ExternalLink size={12} />
          </a>
        </div>
      </div>
    </div>
  );
}

export function CommunityProjects() {
  const [versions, setVersions] = useState<Record<string, string>>({});
  const [filterMode, setFilterMode] = useState<FilterMode>("all");

  useEffect(() => {
    let isMounted = true;

    async function fetchAllVersions() {
      try {
        const cached = sessionStorage.getItem("pala_community_releases");
        if (cached) {
          setVersions(JSON.parse(cached));
          return;
        }
      } catch {
        // Ignore storage access errors
      }

      const activeOnly = PROJECTS.filter((p) => !p.isArchived);
      const results = await Promise.allSettled(
        activeOnly.map(async (proj) => {
          try {
            const res = await fetch(`https://api.github.com/repos/${proj.repo}/releases/latest`);
            if (!res.ok) return { repo: proj.repo, version: null };
            const data = await res.json();
            return { repo: proj.repo, version: data.tag_name || null };
          } catch {
            return { repo: proj.repo, version: null };
          }
        })
      );

      if (!isMounted) return;

      const newVersions: Record<string, string> = {};
      for (const result of results) {
        if (result.status === "fulfilled" && result.value?.version) {
          newVersions[result.value.repo] = result.value.version;
        }
      }
      setVersions(newVersions);

      try {
        sessionStorage.setItem("pala_community_releases", JSON.stringify(newVersions));
      } catch {
        // Ignore storage access errors
      }
    }

    fetchAllVersions();

    return () => {
      isMounted = false;
    };
  }, []);

  const filterProjects = (category: ProjectCategory) => {
    return PROJECTS.filter((p) => {
      if (p.category !== category) return false;
      if (filterMode === "active") return !p.isArchived;
      if (filterMode === "archived") return Boolean(p.isArchived);
      return true;
    });
  };

  const kretaProjects = filterProjects("kreta");
  const neptunProjects = filterProjects("neptun");
  const toolsProjects = filterProjects("tools");

  const totalCount = PROJECTS.length;
  const activeCount = PROJECTS.filter((p) => !p.isArchived).length;
  const archivedCount = PROJECTS.filter((p) => p.isArchived).length;

  return (
    <section id="kozosseg" className="py-12 sm:py-16 px-4 sm:px-6 max-w-7xl mx-auto w-full overflow-hidden">
      <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#1b1b1f] border border-[#28282d] text-[#8c8c94] text-xs font-semibold mb-4">
          <Users size={13} className="text-[#ff8800]" />
          <span>Nyílt forráskódú ökoszisztéma</span>
        </div>
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-[#f3f3f6]">Közösségi Projektek</h2>
        <p className="text-[#8c8c94] text-base">
          A magyar nyílt forráskódú diák- és egyetemi közösség figyelemre méltó Kréta- és Neptun-fejlesztései.
        </p>

        {/* View filters */}
        <div className="flex items-center justify-center gap-2 mt-6">
          <button
            onClick={() => setFilterMode("all")}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all border cursor-pointer ${
              filterMode === "all"
                ? "bg-[#ff8800] text-black border-[#ff8800] shadow-[0_0_15px_rgba(255,136,0,0.25)]"
                : "bg-[#1b1b1f] text-[#8c8c94] border-[#28282d] hover:border-[#38383e] hover:text-[#f3f3f6]"
            }`}
          >
            <span>Összes projekt</span>
            <span className="ml-1.5 font-mono text-[11px] opacity-80">({totalCount})</span>
          </button>
          <button
            onClick={() => setFilterMode("active")}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all border cursor-pointer ${
              filterMode === "active"
                ? "bg-[#30d158] text-black border-[#30d158] shadow-[0_0_15px_rgba(48,209,88,0.25)]"
                : "bg-[#1b1b1f] text-[#8c8c94] border-[#28282d] hover:border-[#38383e] hover:text-[#f3f3f6]"
            }`}
          >
            <span>Csak aktívak</span>
            <span className="ml-1.5 font-mono text-[11px] opacity-80">({activeCount})</span>
          </button>
          <button
            onClick={() => setFilterMode("archived")}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all border cursor-pointer ${
              filterMode === "archived"
                ? "bg-[#ff453a] text-white border-[#ff453a] shadow-[0_0_15px_rgba(255,69,58,0.25)]"
                : "bg-[#1b1b1f] text-[#8c8c94] border-[#28282d] hover:border-[#ff453a]/50 hover:text-[#ff453a]"
            }`}
          >
            <span>Csak archiváltak</span>
            <span className="ml-1.5 font-mono text-[11px] opacity-80">({archivedCount})</span>
          </button>
        </div>
      </div>

      {/* 3-Column Layout: Left (Kréta), Center (Neptun), Right (Eszközök & IoT) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Bal oszlop: Kréta Kliensek */}
        <div className="flex flex-col space-y-3.5">
          <div className="p-4 rounded-2xl bg-[#141417] border border-[#28282d] border-t-2 border-t-[#ff8800] flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#ff8800]/10 text-[#ff8800] border border-[#ff8800]/25 flex items-center justify-center">
                <Smartphone size={18} />
              </div>
              <div>
                <h3 className="text-base font-black text-[#f3f3f6]">Kréta Kliensek</h3>
                <p className="text-[11px] text-[#8c8c94]">Mobil, asztali és terminálos alkalmazások</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold bg-[#ff8800]/10 text-[#ff8800] border border-[#ff8800]/25 px-2.5 py-1 rounded-lg">
              {kretaProjects.length}
            </span>
          </div>

          {kretaProjects.length === 0 ? (
            <div className="p-6 rounded-2xl bg-[#141417] border border-[#28282d] text-center text-xs text-[#8c8c94]">
              Nincs megjeleníthető projekt ebben a szűrésben.
            </div>
          ) : (
            kretaProjects.map((proj) => (
              <ProjectCard key={proj.repo} project={proj} versionTag={versions[proj.repo]} />
            ))
          )}
        </div>

        {/* Középső oszlop: Egyetem / Neptun */}
        <div className="flex flex-col space-y-3.5">
          <div className="p-4 rounded-2xl bg-[#141417] border border-[#28282d] border-t-2 border-t-[#0a84ff] flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#0a84ff]/10 text-[#0a84ff] border border-[#0a84ff]/25 flex items-center justify-center">
                <GraduationCap size={18} />
              </div>
              <div>
                <h3 className="text-base font-black text-[#f3f3f6]">Egyetem / Neptun</h3>
                <p className="text-[11px] text-[#8c8c94]">Egyetemi kiegészítők és OCR motorok</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold bg-[#0a84ff]/10 text-[#0a84ff] border border-[#0a84ff]/25 px-2.5 py-1 rounded-lg">
              {neptunProjects.length}
            </span>
          </div>

          {neptunProjects.length === 0 ? (
            <div className="p-6 rounded-2xl bg-[#141417] border border-[#28282d] text-center text-xs text-[#8c8c94]">
              Nincs megjeleníthető projekt ebben a szűrésben.
            </div>
          ) : (
            neptunProjects.map((proj) => (
              <ProjectCard key={proj.repo} project={proj} versionTag={versions[proj.repo]} />
            ))
          )}
        </div>

        {/* Jobb oszlop: Eszközök & IoT */}
        <div className="flex flex-col space-y-3.5">
          <div className="p-4 rounded-2xl bg-[#141417] border border-[#28282d] border-t-2 border-t-[#30d158] flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#30d158]/10 text-[#30d158] border border-[#30d158]/25 flex items-center justify-center">
                <Home size={18} />
              </div>
              <div>
                <h3 className="text-base font-black text-[#f3f3f6]">Eszközök & IoT</h3>
                <p className="text-[11px] text-[#8c8c94]">Okosotthon és fejlesztői API eszközök</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold bg-[#30d158]/10 text-[#30d158] border border-[#30d158]/25 px-2.5 py-1 rounded-lg">
              {toolsProjects.length}
            </span>
          </div>

          {toolsProjects.length === 0 ? (
            <div className="p-6 rounded-2xl bg-[#141417] border border-[#28282d] text-center text-xs text-[#8c8c94]">
              Nincs megjeleníthető projekt ebben a szűrésben.
            </div>
          ) : (
            toolsProjects.map((proj) => (
              <ProjectCard key={proj.repo} project={proj} versionTag={versions[proj.repo]} />
            ))
          )}

          {/* Kiegészítő információs kártya: Teljes történet */}
          <div className="p-4 sm:p-5 rounded-2xl bg-[#141417] border border-[#28282d] flex flex-col justify-between space-y-3">
            <div className="space-y-1.5">
              <div className="flex items-center gap-2 text-xs font-bold text-[#ff8800]">
                <BookOpen size={14} />
                <span>Részletes történelem</span>
              </div>
              <h4 className="text-sm font-bold text-[#f3f3f6]">
                A Kréta- és Neptun-kliensek fejlődése
              </h4>
              <p className="text-xs text-[#8c8c94] leading-relaxed">
                Tekintsd meg az interaktív idővonalat a papíralapú ellenőrzőktől a modern kliensekig a Dokumentációban.
              </p>
            </div>
            <a
              href="/docs#tortenet"
              className="inline-flex items-center justify-between text-xs font-bold py-2 px-3.5 rounded-xl bg-[#1b1b1f] border border-[#28282d] text-[#f3f3f6] hover:border-[#ff8800] hover:text-[#ff8800] transition-colors"
            >
              <span>Idővonal megnyitása</span>
              <ExternalLink size={13} />
            </a>
          </div>

          {/* Kiegészítő információs kártya: Projekt beküldése */}
          <div className="p-4 sm:p-5 rounded-2xl bg-[#141417] border border-[#28282d] flex flex-col justify-between space-y-3">
            <div className="space-y-1.5">
              <div className="flex items-center gap-2 text-xs font-bold text-[#30d158]">
                <Code size={14} />
                <span>Hiányzik egy projekt?</span>
              </div>
              <h4 className="text-sm font-bold text-[#f3f3f6]">
                Közösségi projekt beküldése
              </h4>
              <p className="text-xs text-[#8c8c94] leading-relaxed">
                Készítettél egy nyílt forráskódú Kréta- vagy Neptun-eszközt? Nyiss egy hibajegyet GitHubon a hozzáadáshoz!
              </p>
            </div>
            <a
              href="https://github.com/CsPS0/pala/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-between text-xs font-bold py-2 px-3.5 rounded-xl bg-[#1b1b1f] border border-[#28282d] text-[#f3f3f6] hover:border-[#30d158] hover:text-[#30d158] transition-colors"
            >
              <span>Projekt beküldése</span>
              <ExternalLink size={13} />
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
