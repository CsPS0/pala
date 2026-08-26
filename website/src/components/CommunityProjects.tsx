"use client";

import React, { useState, useEffect } from "react";
import { ExternalLink, Terminal, Smartphone, PenTool, Monitor, Globe, Archive, History } from "lucide-react";

interface CommunityProject {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  title: string;
  author: string;
  description: string;
  url: string;
  repo: string;
  isArchived?: boolean;
  status?: string;
}

const PROJECTS: CommunityProject[] = [
  {
    icon: PenTool,
    title: "Firka",
    author: "QwIT Development",
    description: "A modern nyílt forráskódú Kréta kliens fejlesztések egyik meghatározó alapköve és elődje.",
    url: "https://github.com/QwIT-Development/firka",
    repo: "QwIT-Development/firka",
  },
  {
    icon: Smartphone,
    title: "app-legacy (refilc)",
    author: "reFilc / QwIT Development",
    description: "A klasszikus reFilc Android és Flutter alapú mobil Kréta kliens nyílt kódbázisa.",
    url: "https://github.com/QwIT-Development/app-legacy",
    repo: "QwIT-Development/app-legacy",
  },
  {
    icon: Globe,
    title: "firka-extension",
    author: "QwIT Development",
    description: "A Firka webes böngésző-bővítménye modern funkciókkal és e-Kréta integrációval.",
    url: "https://github.com/QwIT-Development/firka-extension",
    repo: "QwIT-Development/firka-extension",
  },
  {
    icon: Smartphone,
    title: "Folio",
    author: "Folio Team / Zan1456",
    description: "Modern, nyílt forráskódú Kréta kliens Material You dizájnnal és fejlett átlagszámítással.",
    url: "https://github.com/Zan1456/folio",
    repo: "Zan1456/folio",
  },
  {
    icon: Globe,
    title: "folio-extension",
    author: "Zan1456",
    description: "A Folio hivatalos böngésző-kiterjesztése Chromium és Firefox alapú böngészőkhöz.",
    url: "https://github.com/Zan1456/folio-extension",
    repo: "Zan1456/folio-extension",
  },
  {
    icon: Terminal,
    title: "RozsdásFilc (rsfilc)",
    author: "jarjk",
    description: "KRÉTA kliens Rust nyelven, villámgyors és memóriahatékony parancssori és TUI felülettel.",
    url: "https://github.com/jarjk/rsfilc",
    repo: "jarjk/rsfilc",
  },
  {
    icon: Monitor,
    title: "Toll",
    author: "Anasztázia (doomhyena)",
    description: "Natív asztali KRÉTA kliens Windows, Linux és macOS rendszerekre jegyekkel és órarenddel.",
    url: "https://github.com/doomhyena/toll",
    repo: "doomhyena/toll",
  },
  {
    icon: Archive,
    title: "Filc",
    author: "Filc Team",
    description: "A magyar diákközösség legelső és legnépszerűbb nyílt forráskódú alternatív Kréta kliense.",
    url: "https://github.com/filc/filc",
    repo: "filc/filc",
    isArchived: true,
    status: "Megszűnt / Archivált",
  },
  {
    icon: History,
    title: "Szivacs-Naplo",
    author: "boapps",
    description: "A legendás korai Androidos e-Kréta kliens, a közösségi kliensfejlesztés egyik úttörője.",
    url: "https://github.com/boapps/Szivacs-Naplo",
    repo: "boapps/Szivacs-Naplo",
    isArchived: true,
    status: "Megszűnt / Archivált",
  },
];

export function CommunityProjects() {
  const [versions, setVersions] = useState<Record<string, string>>({});

  useEffect(() => {
    let isMounted = true;

    async function fetchAllVersions() {
      const activeOnly = PROJECTS.filter((p) => !p.isArchived);
      const results = await Promise.allSettled(
        activeOnly.map(async (proj) => {
          const res = await fetch(`https://api.github.com/repos/${proj.repo}/releases/latest`);
          if (!res.ok) return { repo: proj.repo, version: null };
          const data = await res.json();
          return { repo: proj.repo, version: data.tag_name || null };
        })
      );

      if (!isMounted) return;

      const newVersions: Record<string, string> = {};
      for (const result of results) {
        if (result.status === "fulfilled" && result.value.version) {
          newVersions[result.value.repo] = result.value.version;
        }
      }
      setVersions(newVersions);
    }

    fetchAllVersions();

    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <section id="kozosseg" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full overflow-hidden">
      <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-14">
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-[#f3f3f6]">Közösségi Projektek</h2>
        <p className="text-[#8c8c94] text-base">
          A magyar nyílt forráskódú e-Kréta közösség további figyelemre méltó projektjei és kezdeményezései.
        </p>
      </div>

      {/* Unified Community Projects Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {PROJECTS.map((project) => {
          const IconComp = project.icon;
          const versionTag = versions[project.repo];
          const isArchived = Boolean(project.isArchived);

          return (
            <div
              key={project.repo}
              className={`p-6 sm:p-7 rounded-3xl flex flex-col justify-between transition-all hover:-translate-y-1 group ${
                isArchived
                  ? "bg-[#151518]/70 border border-dashed border-[#ff453a]/30 hover:border-[#ff453a]/70 hover:bg-[#18181c] opacity-90 hover:opacity-100 shadow-[0_0_20px_rgba(255,69,58,0.04)]"
                  : "bg-[#1b1b1f] border border-[#28282d] hover:border-[#ff8800] hover:bg-[#222227]"
              }`}
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div
                    className={`w-11 h-11 rounded-2xl flex items-center justify-center border ${
                      isArchived
                        ? "bg-[#ff453a]/10 text-[#ff453a] border-[#ff453a]/25"
                        : "bg-[#ff8800]/10 text-[#ff8800] border-[#ff8800]/20"
                    }`}
                  >
                    <IconComp size={20} />
                  </div>

                  {isArchived ? (
                    <span className="text-[10px] font-bold bg-[#ff453a]/15 text-[#ff453a] border border-[#ff453a]/35 px-2.5 py-0.5 rounded-full">
                      {project.status}
                    </span>
                  ) : (
                    versionTag && (
                      <span className="text-[11px] font-bold bg-[#151518] text-[#ff8800] border border-[#28282d] px-2.5 py-1 rounded-full">
                        {versionTag}
                      </span>
                    )
                  )}
                </div>

                <h3 className="text-lg font-bold text-[#f3f3f6] mb-1">{project.title}</h3>
                <p
                  className={`text-xs font-semibold mb-3 ${
                    isArchived ? "text-[#8c8c94]" : "text-[#ff8800]"
                  }`}
                >
                  Készítette: {project.author}
                </p>
                <p className="text-xs sm:text-sm text-[#8c8c94] leading-relaxed mb-6">
                  {project.description}
                </p>
              </div>

              <div className="pt-4 border-t border-[#28282d] flex items-center justify-between">
                <a
                  href={project.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={`inline-flex items-center gap-1.5 text-xs font-bold transition-colors ${
                    isArchived
                      ? "text-[#8c8c94] hover:text-[#f3f3f6]"
                      : "text-[#f3f3f6] hover:text-[#ff8800]"
                  }`}
                >
                  <span>GitHub megnyitása</span>
                  <ExternalLink size={13} />
                </a>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
