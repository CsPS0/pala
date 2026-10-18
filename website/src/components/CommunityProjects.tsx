"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import {
  ExternalLink,
  Terminal,
  Smartphone,
  PenTool,
  Monitor,
  Globe,
  Archive,
  History,
  Zap,
  Home,
  Code,
  Users,
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

function getCategoryStyles(category: ProjectCategory, isArchived?: boolean) {
  if (isArchived) {
    return {
      card: "bg-sidebar/70 border border-dashed border-primary/30 hover:border-primary/70 hover:bg-card-alt opacity-85 hover:opacity-100",
      iconBg: "bg-primary/10 text-primary border-primary/25",
      badge: "bg-primary/15 text-primary border-primary/35",
      author: "text-muted",
      linkHover: "hover:text-fg",
    };
  }

  switch (category) {
    case "neptun":
      return {
        card: "bg-card border border-border hover:border-primary hover:bg-card-alt",
        iconBg: "bg-primary/10 text-primary border-primary/25",
        badge: "bg-primary/10 text-primary border-primary/25 text-primary",
        author: "text-primary",
        linkHover: "hover:text-primary",
      };
    case "tools":
      return {
        card: "bg-card border border-border hover:border-primary hover:bg-card-alt",
        iconBg: "bg-primary/10 text-primary border-primary/25",
        badge: "bg-primary/10 text-primary border-primary/25 text-primary",
        author: "text-primary",
        linkHover: "hover:text-primary",
      };
    case "kreta":
    default:
      return {
        card: "bg-card border border-border hover:border-primary hover:bg-card-hover",
        iconBg: "bg-primary/10 text-primary border-primary/20",
        badge: "bg-primary/10 text-primary border-primary/20 text-primary",
        author: "text-primary",
        linkHover: "hover:text-primary",
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
      className={`p-4 sm:p-5 rounded-2xl flex flex-col justify-between transition-all group ${styles.card}`}
    >
      <div>
        <div className="flex items-start justify-between gap-3 mb-2.5">
          <div className="flex items-center gap-3 min-w-0">
            <div
              className={`w-10 h-10 rounded-xl overflow-hidden flex items-center justify-center shrink-0 border bg-bg ${styles.iconBg}`}
            >
              {project.image && !imageError ? (
                <Image
                  src={project.image}
                  alt={project.title}
                  width={40}
                  height={40}
                  className="w-full h-full object-cover rounded-xl"
                  onError={() => setImageError(true)}
                />
              ) : (
                <IconComp size={18} />
              )}
            </div>
            <div className="min-w-0">
              <h4 className="text-sm sm:text-base font-bold text-fg truncate group-hover:text-fg">
                {project.title}
              </h4>
              <p className={`text-[11px] font-semibold truncate ${styles.author}`}>
                {project.author}
              </p>
            </div>
          </div>

          <div className="shrink-0 flex items-center gap-1.5">
            {isArchived ? (
              <span className="text-[10px] font-bold bg-primary/15 text-primary border border-primary/35 px-2 py-0.5 rounded-full whitespace-nowrap">
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
                  <span className="text-[10px] font-bold bg-sidebar text-primary border border-border px-2 py-0.5 rounded-full font-mono whitespace-nowrap">
                    {versionTag}
                  </span>
                )}
              </>
            )}
          </div>
        </div>

        <p className="text-xs text-muted leading-relaxed mb-3 line-clamp-2">
          {project.description}
        </p>
      </div>

      <div className="pt-2.5 border-t border-border/70 flex items-center justify-between text-xs gap-2">
        <span className="text-[11px] font-mono text-subtle truncate max-w-[130px]">
          {project.repo}
        </span>
        <div className="flex items-center gap-2.5 shrink-0">
          {project.websiteUrl && (
            <a
              href={project.websiteUrl}
              target="_blank"
              rel="noopener noreferrer"
              className={`inline-flex items-center gap-1 text-[11px] font-bold transition-colors text-fg ${styles.linkHover}`}
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
            className={`inline-flex items-center gap-1 text-[11px] font-bold transition-colors text-muted ${styles.linkHover}`}
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
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-card border border-border text-muted text-xs font-semibold mb-4">
          <Users size={13} className="text-primary" />
          <span>Nyílt forráskódú ökoszisztéma</span>
        </div>
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-fg">Közösségi Projektek</h2>
        <p className="text-muted text-base">
          Más nyílt forráskódú Kréta- és Neptun-projektek a magyar diákközösségtől.
        </p>

        {/* View filters */}
        <div className="flex flex-wrap items-center justify-center gap-2 mt-6">
          <button
            onClick={() => setFilterMode("all")}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all border cursor-pointer ${
              filterMode === "all"
                ? "bg-primary-fill text-on-primary border-primary"
                : "bg-card text-muted border-border hover:border-border hover:text-fg"
            }`}
          >
            <span>Összes projekt</span>
            <span className="ml-1.5 font-mono text-[11px] opacity-80">({totalCount})</span>
          </button>
          <button
            onClick={() => setFilterMode("active")}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all border cursor-pointer ${
              filterMode === "active"
                ? "bg-primary-fill text-on-primary border-primary"
                : "bg-card text-muted border-border hover:border-border hover:text-fg"
            }`}
          >
            <span>Csak aktívak</span>
            <span className="ml-1.5 font-mono text-[11px] opacity-80">({activeCount})</span>
          </button>
          <button
            onClick={() => setFilterMode("archived")}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all border cursor-pointer ${
              filterMode === "archived"
                ? "bg-primary-fill text-on-primary border-primary"
                : "bg-card text-muted border-border hover:border-primary/50 hover:text-primary"
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
          <div className="p-4 rounded-2xl bg-sidebar border border-border border-t-2 border-t-primary flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary border border-primary/25 flex items-center justify-center">
                <Smartphone size={18} />
              </div>
              <div>
                <h3 className="text-base font-black text-fg">Kréta Kliensek</h3>
                <p className="text-[11px] text-muted">Mobil, asztali és terminálos alkalmazások</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold bg-primary/10 text-primary border border-primary/25 px-2.5 py-1 rounded-lg">
              {kretaProjects.length}
            </span>
          </div>

          {kretaProjects.length === 0 ? (
            <div className="p-6 rounded-2xl bg-sidebar border border-border text-center text-xs text-muted">
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
          <div className="p-4 rounded-2xl bg-sidebar border border-border border-t-2 border-t-primary flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary border border-primary/25 flex items-center justify-center">
                <GraduationCap size={18} />
              </div>
              <div>
                <h3 className="text-base font-black text-fg">Egyetem / Neptun</h3>
                <p className="text-[11px] text-muted">Egyetemi kiegészítők és OCR motorok</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold bg-primary/10 text-primary border border-primary/25 px-2.5 py-1 rounded-lg">
              {neptunProjects.length}
            </span>
          </div>

          {neptunProjects.length === 0 ? (
            <div className="p-6 rounded-2xl bg-sidebar border border-border text-center text-xs text-muted">
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
          <div className="p-4 rounded-2xl bg-sidebar border border-border border-t-2 border-t-primary flex items-center justify-between shadow-sm">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-primary/10 text-primary border border-primary/25 flex items-center justify-center">
                <Home size={18} />
              </div>
              <div>
                <h3 className="text-base font-black text-fg">Eszközök & IoT</h3>
                <p className="text-[11px] text-muted">Okosotthon és fejlesztői API eszközök</p>
              </div>
            </div>
            <span className="text-xs font-mono font-bold bg-primary/10 text-primary border border-primary/25 px-2.5 py-1 rounded-lg">
              {toolsProjects.length}
            </span>
          </div>

          {toolsProjects.length === 0 ? (
            <div className="p-6 rounded-2xl bg-sidebar border border-border text-center text-xs text-muted">
              Nincs megjeleníthető projekt ebben a szűrésben.
            </div>
          ) : (
            toolsProjects.map((proj) => (
              <ProjectCard key={proj.repo} project={proj} versionTag={versions[proj.repo]} />
            ))
          )}

          {/* Kiegészítő információs kártya: Projekt beküldése */}
          <div className="p-4 sm:p-5 rounded-2xl bg-sidebar border border-border flex flex-col justify-between space-y-3">
            <div className="space-y-1.5">
              <div className="flex items-center gap-2 text-xs font-bold text-primary">
                <Code size={14} />
                <span>Hiányzik egy projekt?</span>
              </div>
              <h4 className="text-sm font-bold text-fg">
                Közösségi projekt beküldése
              </h4>
              <p className="text-xs text-muted leading-relaxed">
                Készítettél egy nyílt forráskódú Kréta- vagy Neptun-eszközt? Nyiss egy hibajegyet GitHubon a hozzáadáshoz!
              </p>
            </div>
            <a
              href="https://github.com/CsPS0/pala/issues"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-between text-xs font-bold py-2 px-3.5 rounded-xl bg-card border border-border text-fg hover:border-primary hover:text-primary transition-colors"
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
