import React from "react";
import { ArrowUpRight } from "lucide-react";
import { CONCEPT_ICONS } from "@/lib/icons";

// Sources (checked 2026-10-18):
// - KRÉTA rollout: summer 2016 in Klebelsberg Központ schools, mandatory for state schools from 2018
//   (hvg.hu, eduline.hu reporting); usability complaints about the official app: eduline.hu
//   ("Nehezen használható a tanárok szerint...", "Szinte sosem működik rendesen a KRÉTA...").
// - Every client below: its GitHub repository (first commit date, last push, archived flag, description,
//   owner name) via the GitHub API; Filc dates from the filc/*-archive repositories.

interface Client {
  name: string;
  period: string;
  author: string;
  platforms: string;
  status: "Aktív" | "Archivált" | "Inaktív";
  text: string;
  url: string;
}

const CLIENTS: Client[] = [
  {
    name: "Szivacs Napló",
    period: "2018–2020",
    author: "boa (boapps)",
    platforms: "Flutter, multiplatform",
    status: "Archivált",
    text: "Az egyik első nyílt forráskódú, nem hivatalos kliens az e-naplóhoz. A fejlesztése 2020 elején állt le.",
    url: "https://github.com/boapps/Szivacs-Naplo",
  },
  {
    name: "Filc Napló",
    period: "2020–2023",
    author: "Filc csapat",
    platforms: "Flutter, mobil és asztali",
    status: "Archivált",
    text: "Nem hivatalos e-napló alkalmazás mobilra és asztalra, saját weboldallal. A repókat 2023 júniusában archiválták.",
    url: "https://github.com/filc/naplo-archive",
  },
  {
    name: "Arisztokréta",
    period: "2020-tól",
    author: "Coware Apps",
    platforms: "TypeScript",
    status: "Inaktív",
    text: "Nem hivatalos, KRÉTA-kompatibilis ellenőrző alkalmazás; a repó utoljára 2024 januárjában változott. A csapat egy tanári napló alkalmazást (Napló+) is készített.",
    url: "https://github.com/Coware-Apps/ellenorzo",
  },
  {
    name: "reFilc",
    period: "2023-tól",
    author: "közösségi fejlesztők, később a QwIT csapat",
    platforms: "Flutter, mobil",
    status: "Aktív",
    text: "A Filc kódjára építve folytatta a fejlesztést az archiválás után. Továbbfejlesztett változatát ma a QwIT csapat app-legacy repójában fejlesztik.",
    url: "https://github.com/QwIT-Development/app-legacy",
  },
  {
    name: "RozsdásFilc (rsfilc)",
    period: "2024-től",
    author: "Kovács Jeromos (jarjk)",
    platforms: "Rust, parancssor",
    status: "Aktív",
    text: "Parancssori Kréta kliens Rust nyelven.",
    url: "https://github.com/jarjk/rsfilc",
  },
  {
    name: "Firka",
    period: "2025-től",
    author: "QwIT Development",
    platforms: "Flutter, mobil; böngészős téma",
    status: "Aktív",
    text: "A QwIT csapat új kliense, mellette egy nem hivatalos téma az e-KRÉTA webes felületéhez.",
    url: "https://github.com/QwIT-Development/firka",
  },
  {
    name: "Folio",
    period: "2026-tól",
    author: "Zan1456",
    platforms: "Flutter",
    status: "Aktív",
    text: "A Firka korábbi (legacy) kódjának felfrissített változata.",
    url: "https://github.com/Zan1456/folio",
  },
  {
    name: "Toll",
    period: "2026",
    author: "doomhyena",
    platforms: "Go, Wails, React; asztali",
    status: "Archivált",
    text: "Asztali kliens Windowsra, Linuxra és macOS-re. Még ugyanabban az évben archiválták.",
    url: "https://github.com/doomhyena/toll",
  },
  {
    name: "Pala",
    period: "2026-tól",
    author: "Solti Csongor Péter (CsPS0)",
    platforms: "Dart és Flutter: terminál, asztali, Android; böngészőbővítmény",
    status: "Aktív",
    text: "Egy közös magra épülő terminálos, asztali és telefonos kliens, valamint böngészőbővítmény.",
    url: "https://github.com/CsPS0/pala",
  },
];

const STATUS_CLASS: Record<Client["status"], string> = {
  Aktív: "bg-primary/10 text-primary border-primary/30",
  Archivált: "bg-card-hover text-muted border-border",
  Inaktív: "bg-card-hover text-muted border-border",
};

/** Short, source-checked history of the Hungarian Kréta clients. Rendered on /tortenet and in the docs. */
export function ClientHistory() {
  const Icon = CONCEPT_ICONS.history;
  return (
    <div className="w-full max-w-3xl mx-auto">
      <div className="mb-8">
        <div className="w-10 h-10 rounded-lg bg-card border border-border text-primary flex items-center justify-center mb-4">
          <Icon size={20} />
        </div>
        <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-fg mb-4">A Kréta-kliensek története</h1>
        <div id="kreta-hatter" className="space-y-3 text-base text-muted leading-relaxed">
          <p>
            A KRÉTA (Köznevelési Regisztrációs és Tanulmányi Alaprendszer) 2016 nyarán indult a Klebelsberg Központ
            iskoláiban, 2018-tól pedig kötelező az állami iskolákban.
          </p>
          <p>
            A hivatalos alkalmazást sokan lassúnak és nehezen használhatónak tartották, ezért diákok saját,
            nyílt forráskódú klienseket kezdtek írni hozzá. Hasonló, diákok által fejlesztett kliensek külföldön is
            vannak, például a lengyel Wulkanowy vagy a francia Papillon.
          </p>
        </div>
      </div>

      <ol id="kreta-kliensek" aria-label="A Kréta-kliensek idővonala" className="relative border-l border-border ml-2 space-y-5">
        {CLIENTS.map((c) => (
          <li key={c.name} className="pl-6 relative">
            <span className="absolute -left-[5px] top-2 w-2.5 h-2.5 rounded-full bg-primary-fill" aria-hidden="true" />
            <div className="bg-card border border-border rounded-xl p-4">
              <div className="flex flex-wrap items-baseline justify-between gap-x-3 gap-y-1">
                <h2 className="text-base font-extrabold text-fg">{c.name}</h2>
                <span className="text-xs font-mono text-muted">{c.period}</span>
              </div>
              <p className="text-xs text-muted mt-1">
                {c.author} · {c.platforms}
              </p>
              <p className="text-sm text-muted leading-relaxed mt-2">{c.text}</p>
              <div className="flex items-center justify-between gap-3 mt-3">
                <span className={`text-[11px] font-bold px-2 py-0.5 rounded-md border ${STATUS_CLASS[c.status]}`}>{c.status}</span>
                <a
                  href={c.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline"
                >
                  Forráskód
                  <ArrowUpRight size={12} />
                </a>
              </div>
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}
