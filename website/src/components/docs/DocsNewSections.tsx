"use client";

import React, { useState } from "react";
import Link from "next/link";
import {
  Clock,
  Puzzle,
  Calculator,
  ShieldAlert,
  Cpu,
  Terminal,
  GitBranch,
  CheckCircle2,
  Layers,
  ListTree,
  FileCode2,
  ArrowUp,
  ExternalLink,
} from "lucide-react";
import { DocCallout } from "./DocCallout";
import { CodeBlock } from "./CodeBlock";
import { PAGE_TOC_MAP, type TocHeading } from "@/content/docs/navigation";

interface DocsNewSectionsProps {
  activePage: string;
  onSelectPage: (pageId: string) => void;
}

export function DocsNewSections({ activePage, onSelectPage }: DocsNewSectionsProps) {
  const [simGrade, setSimGrade] = useState<number>(5);
  const [simWeight, setSimWeight] = useState<number>(200);

  // Interactive GPA calculation for the Guides -> Grades page
  const baseWeightedSum = 2400; // 4.80 across 500% weight
  const baseWeight = 500;
  const newAvg = (baseWeightedSum + simGrade * simWeight) / (baseWeight + simWeight);
  const delta = newAvg - 4.8;

  if (activePage === "guide-dashboard") {
    return (
      <div className="space-y-8 min-w-0 w-full">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-primary uppercase block mb-1">
            FUNKCIÓ ÚTMUTATÓK / VEZÉRLŐPULT & ÓRAREND
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-fg tracking-tight mb-3">
            Élő Vezérlőpult és Órarend Kezelés
          </h1>
          <p className="text-xs sm:text-sm text-muted leading-relaxed max-w-2xl">
            Hogyan követi a Pala valós időben az aktuális tanórát, a szüneteket, a tanári
            helyettesítéseket és az elmaradó órákat minden platformon.
          </p>
        </div>

        <DocCallout type="note" title="Valós Idejű Órafigyelő (CountdownHeroCard)">
          Az Élő Vezérlőpult automatikusan felismeri az aktuális tanítási órát vagy óraközi szünetet,
          és másodperces pontosságú folyamatjelző sávval mutatja a hátralévő időt, a teremszámot és
          az oktató nevét.
        </DocCallout>

        {/* Section 1: CountdownHeroCard */}
        <section id="elo-orafigyelo" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <Clock size={16} className="text-primary" />
            <h2>1. Élő Óra-visszaszámláló (CountdownHeroCard)</h2>
          </div>
          <p className="text-xs text-muted leading-relaxed">
            A Vezérlőpult tetején elhelyezkedő <code className="text-primary font-mono">CountdownHeroCard</code> három
            állapot között vált automatikusan a helyi rendszeridő és a szinkronizált Kréta órarend alapján:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
            <div className="p-3.5 rounded-xl bg-sidebar border border-primary/30 space-y-1">
              <strong className="text-primary block">1. Aktív tanóra közben</strong>
              <span className="text-muted">
                Kijelzi az óra sorszámát, a tantárgyat, a teremszámot, a hátralévő perceket és a százalékos folyamatjelző sávot.
              </span>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-primary/30 space-y-1">
              <strong className="text-primary block">2. Óraközi szünetben</strong>
              <span className="text-muted">
                Megmutatja, hány perc múlva kezdődik a következő tanóra, és melyik terembe kell átmenned.
              </span>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-border space-y-1">
              <strong className="text-fg block">3. Tanítás után / Hétvégén</strong>
              <span className="text-muted">
                Összegzi a következő tanítási nap első óráját és a teljes napi óraszámot.
              </span>
            </div>
          </div>
        </section>

        {/* Section 2: Substitutions & Cancelled classes */}
        <section id="helyettesites-es-elmaradas" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <h2 className="text-sm font-bold text-fg">
            2. Helyettesítések és Elmaradó Órák Jelölése
          </h2>
          <p className="text-xs text-muted leading-relaxed">
            A Pala kiemelt vizuális hierarchiával (Material Design 3 szerepkörökkel és TUI ANSI 256
            színekkel) különbözteti meg a rendkívüli órarendi eseményeket:
          </p>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
            <div className="p-4 rounded-xl bg-primary/[0.06] border border-primary/40 space-y-1.5">
              <div className="flex items-center justify-between">
                <strong className="text-primary">Helyettesítés (Substitution)</strong>
                <span className="text-[10px] font-mono bg-primary/20 text-primary px-2 py-0.5 rounded font-bold">
                  HELYETTESÍTÉS
                </span>
              </div>
              <p className="text-fg">
                Ha a Kréta <code className="font-mono text-primary">HelyettesTanarNeve</code> mezője kitöltött, a Pala
                sárga figyelmeztető jelvényt és a helyettesítő tanár nevét jeleníti meg az eredeti oktató helyett.
              </p>
            </div>
            <div className="p-4 rounded-xl bg-primary/[0.06] border border-primary/40 space-y-1.5">
              <div className="flex items-center justify-between">
                <strong className="text-primary">Elmaradó óra (Cancelled)</strong>
                <span className="text-[10px] font-mono bg-primary/20 text-primary px-2 py-0.5 rounded font-bold">
                  ELMARAD
                </span>
              </div>
              <p className="text-fg">
                Elmaradó tanóra esetén a tantárgy neve áthúzott (<code className="font-mono text-primary">line-through</code>)
                formázást és magas kontrasztú piros riasztási jelvényt kap.
              </p>
            </div>
          </div>
        </section>

        {/* Section 3: A/B Week & ICS Export */}
        <section id="ab-het-es-ics" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <h3 className="text-sm font-bold text-fg">
            3. A/B Hét Kezelés és .ics Naptár Export
          </h3>
          <p className="text-xs text-muted leading-relaxed">
            A kétciklusos (A/B hetes) órarendet használó középiskolákban a Pala automatikusan kiolvassa a
            hét típusát, vagy lehetővé teszi a kézi A/B hét váltást (TUI-ban az <kbd className="bg-sidebar border border-border px-1.5 py-0.5 rounded font-mono">[a]</kbd> billentyűvel). Az órarend RFC 5545 kompatibilis <code className="text-primary font-mono">.ics</code> fájlba exportálható:
          </p>
          <CodeBlock
            title="Órarend exportálása Google / Apple / Outlook naptárhoz"
            language="bash"
            code={`# Exportálás az alapértelmezett orarend.ics fájlba:
pala --export-ics orarend.ics

# TUI felületen belül az Órarend [3] fülön nyomd meg az [e] billentyűt!`}
          />
        </section>

        <div className="flex items-center justify-between pt-4 border-t border-border">
          <button
            type="button"
            onClick={() => onSelectPage("installation")}
            className="text-xs font-bold text-muted hover:text-fg cursor-pointer"
          >
            ← Előző: Telepítés & Beállítás
          </button>
          <button
            type="button"
            onClick={() => onSelectPage("guide-grades")}
            className="text-xs font-bold text-primary hover:underline cursor-pointer"
          >
            Következő: Jegyek & Szellem Jegy →
          </button>
        </div>
      </div>
    );
  }

  if (activePage === "guide-grades") {
    return (
      <div className="space-y-8 min-w-0 w-full">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-primary uppercase block mb-1">
            FUNKCIÓ ÚTMUTATÓK / JEGYEK & SZELLEM JEGY
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-fg tracking-tight mb-3">
            Jegyek, Súlyozott Átlagok és „Szellem Jegy” Szimulátor
          </h1>
          <p className="text-xs sm:text-sm text-muted leading-relaxed max-w-2xl">
            Súlyozott tanulmányi átlag (GPA) számítás, színpszichológiai érdemjegy-jelvények,
            interaktív Szellem Jegy kalkulátor és Bizonyítvány Tervező.
          </p>
        </div>

        <section id="sulyozott-atlag-szamitas" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <Calculator size={16} className="text-primary" />
            <h2>1. Súlyozott Tanulmányi Átlag (Weighted GPA)</h2>
          </div>
          <p className="text-xs text-muted leading-relaxed">
            A Kréta naplóban minden érdemjegyhez tartozik egy százalékos súlyérték (<code className="text-primary font-mono">SulySzazalekErteke</code>:
            például felelet vagy röpdolgozat <code className="font-mono">50%–100%</code>, témazáró <code className="font-mono">200%</code>,
            projektmunka vagy vizsga <code className="font-mono">300%–400%</code>). A Pala a félévi és év végi lezáró jegyeket
            (<code className="font-mono">isSummaryGrade</code>) kiszűri az évközi átlagból, és pontos súlyozott átlagot számol.
          </p>

          <div id="szinpszichologia" className="grid grid-cols-2 sm:grid-cols-6 gap-2.5 pt-2 text-center text-xs">
            {[
              { val: "5", label: "Jeles", style: "bg-success/15 border-success/40 text-success" },
              { val: "4", label: "Jó", style: "bg-grade-good/15 border-grade-good/40 text-grade-good" },
              { val: "3", label: "Közepes", style: "bg-warning/15 border-warning/40 text-warning" },
              { val: "2", label: "Elégséges", style: "bg-primary/15 border-primary/40 text-primary" },
              { val: "1", label: "Elégtelen", style: "bg-danger/15 border-danger/40 text-danger" },
              { val: "*5*", label: "Szellem", style: "bg-ghost/15 border-ghost/40 text-ghost" },
            ].map((item, idx) => (
              <div key={idx} className={`p-3 rounded-xl border ${item.style}`}>
                <div className="text-lg font-black">{item.val}</div>
                <div className="text-[11px] font-semibold mt-0.5">{item.label}</div>
              </div>
            ))}
          </div>
        </section>

        {/* Interactive Simulator Demo */}
        <section id="szellem-jegy-szimulator" className="bg-card border border-primary/40 rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
            <div>
              <h2 className="text-sm font-bold text-fg">
                2. Interaktív „Szellem Jegy” (Ghost Grade) Szimulátor
              </h2>
              <p className="text-xs text-muted mt-0.5">
                Próbáld ki élőben: hogyan változik egy 4.80-as Matematika átlag új szellem jegy hozzáadásakor?
              </p>
            </div>
            <span className="text-xs font-mono font-black text-primary bg-primary/15 border border-primary/30 px-3 py-1 rounded-xl">
              4.80 → {newAvg.toFixed(2)} ({delta >= 0 ? "+" : ""}
              {delta.toFixed(2)})
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-4 bg-sidebar border border-border p-4 rounded-xl text-xs">
            <div className="flex items-center gap-1.5">
              <span className="font-bold text-fg mr-1">Érdemjegy:</span>
              {[5, 4, 3, 2, 1].map((g) => (
                <button
                  key={g}
                  type="button"
                  onClick={() => setSimGrade(g)}
                  className={`w-8 h-8 rounded-lg font-black cursor-pointer border ${
                    simGrade === g
                      ? "bg-primary-fill text-on-primary border-primary"
                      : "bg-card text-fg border-border"
                  }`}
                >
                  {g}
                </button>
              ))}
            </div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold text-fg mr-1">Súly:</span>
              {[50, 100, 200, 300].map((w) => (
                <button
                  key={w}
                  type="button"
                  onClick={() => setSimWeight(w)}
                  className={`px-3 py-1.5 rounded-lg font-bold cursor-pointer border ${
                    simWeight === w
                      ? "bg-primary-fill text-on-primary border-primary"
                      : "bg-card text-muted border-border"
                  }`}
                >
                  {w}%
                </button>
              ))}
            </div>
          </div>

          <DocCallout type="security" title="Kliensoldali szimuláció">
            A Szellem Jegyek kizárólag a memóriában (RAM) jönnek létre a saját eszközödön. A hivatalos
            Kréta szerverek felé semmilyen módosítás nem történik.
          </DocCallout>
        </section>

        <section id="bizonyitvany-tervezo" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-3">
          <h3 className="text-sm font-bold text-fg">
            3. Bizonyítvány Tervező & Tantárgyi Mátrix
          </h3>
          <p className="text-xs text-muted leading-relaxed">
            A <strong>Bizonyítvány Tervező</strong> minden tantárgyhoz kiszámítja a következő jegyhatárt
            (<code className="font-mono">1.50</code>, <code className="font-mono">2.50</code>,{" "}
            <code className="font-mono">3.50</code>, <code className="font-mono">4.50</code>), és megadja,
            hogy pontosan hány darab <code className="font-mono text-primary">100%</code>-os ötösre van
            még szükséged a jobb év végi jegyhez.
          </p>
        </section>

        <div className="flex items-center justify-between pt-4 border-t border-border">
          <button
            type="button"
            onClick={() => onSelectPage("guide-dashboard")}
            className="text-xs font-bold text-muted hover:text-fg cursor-pointer"
          >
            ← Előző: Vezérlőpult & Órarend
          </button>
          <button
            type="button"
            onClick={() => onSelectPage("guide-absences")}
            className="text-xs font-bold text-primary hover:underline cursor-pointer"
          >
            Következő: Mulasztások & 250 Órás Limit →
          </button>
        </div>
      </div>
    );
  }

  if (activePage === "guide-absences") {
    return (
      <div className="space-y-8 min-w-0 w-full">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-primary uppercase block mb-1">
            FUNKCIÓ ÚTMUTATÓK / JELENLÉT & 250 ÓRÁS LIMIT
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-fg tracking-tight mb-3">
            Mulasztások, 250 Órás Törvényi Határ és Szülői Igazolások
          </h1>
          <p className="text-xs sm:text-sm text-muted leading-relaxed max-w-2xl">
            Hogyan segít a Pala elkerülni az osztályozó vizsgát a 250 órás összhiányzási korlát,
            a 30%-os tantárgyi limit és a szülői igazolási keret folyamatos figyelésével.
          </p>
        </div>

        <DocCallout type="warning" title="250 Órás Jogszabályi Határ (20/2012. EMMI rendelet)">
          Ha egy tanuló igazolt és igazolatlan mulasztásai együttesen meghaladják a{" "}
          <strong>250 tanórát</strong> a tanév során, vagy egy adott tantárgyból a hiányzások
          aránya túllépi az éves óraszám <strong>30%-át</strong>, a tanuló osztályozó vizsgára
          kötelezhető.
        </DocCallout>

        <section id="torvenyi-250-ora" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <ShieldAlert size={16} className="text-primary" />
            <h2>1. A 250 Órás Veszélyzóna és a Tantárgyi 30%</h2>
          </div>
          <p className="text-xs text-muted leading-relaxed">
            A Pala Mulasztások nézete három szintű vizuális visszajelzést ad az összesített hiányzási
            óraszám alapján:
          </p>
          <div id="tantargyi-30-szazalek" className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
            <div className="p-3.5 rounded-xl bg-sidebar border border-primary/30">
              <strong className="text-primary block mb-1">0 – 119 óra (Biztonságos)</strong>
              <span className="text-muted">Zöld folyamatjelző sáv; bőven a törvényi határ alatt.</span>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-primary/30">
              <strong className="text-primary block mb-1">120 – 199 óra (Figyelmeztető)</strong>
              <span className="text-muted">Sárga jelzés; érdemes figyelni a tantárgyi 30%-os arányokat.</span>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-primary/30">
              <strong className="text-primary block mb-1">200+ óra (Veszélyzóna)</strong>
              <span className="text-muted">Kritikus piros riasztás a 250 órás osztályozóvizsga-határ közelében.</span>
            </div>
          </div>
        </section>

        <section id="szuloi-igazolasi-keret" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <h2 className="text-sm font-bold text-fg">
            2. Szülői Igazolási Keret és Státusz Színkódok
          </h2>
          <p className="text-xs text-muted leading-relaxed">
            A Pala automatikusan összeszámolja a szülői/gondviselői igazolással lefedett napokat, és
            összeveti az iskolai házirendben engedélyezett kerettel (alapértelmezetten 3 vagy 5 nap,
            amely a <code className="font-mono text-primary">config.json</code> fájlban testreszabható).
          </p>
          <div id="mulasztas-szurok" className="grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs">
            <div className="p-3 rounded-xl bg-primary/10 border border-primary/30 text-primary font-bold">
              IGAZOLATLAN — Piros kiemelés
            </div>
            <div className="p-3 rounded-xl bg-primary/10 border border-primary/30 text-primary font-bold">
              IGAZOLANDÓ — Sárga jelvény
            </div>
            <div className="p-3 rounded-xl bg-card-hover border border-border text-muted font-bold">
              IGAZOLT — Szürke jelvény
            </div>
            <div className="p-3 rounded-xl bg-primary/10 border border-primary/30 text-primary font-bold">
              KÉSÉS (perc) — Narancs jelvény
            </div>
          </div>
        </section>

        <div className="flex items-center justify-between pt-4 border-t border-border">
          <button
            type="button"
            onClick={() => onSelectPage("guide-grades")}
            className="text-xs font-bold text-muted hover:text-fg cursor-pointer"
          >
            ← Előző: Jegyek & Szellem Jegy
          </button>
          <button
            type="button"
            onClick={() => onSelectPage("dev-architecture")}
            className="text-xs font-bold text-primary hover:underline cursor-pointer"
          >
            Következő: Fejlesztői Architektúra (&lt;600dp) →
          </button>
        </div>
      </div>
    );
  }

  if (activePage === "dev-architecture") {
    return (
      <div className="space-y-8 min-w-0 w-full">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-primary uppercase block mb-1">
            FEJLESZTŐI SPECIFIKÁCIÓK / ARCHITEKTÚRA & ADAPTÍV LAYOUT
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-fg tracking-tight mb-3">
            Architektúra és Egykódos Flutter Layout (&lt;600dp vs &gt;=600dp)
          </h1>
          <p className="text-xs sm:text-sm text-muted leading-relaxed max-w-2xl">
            A Pala „One Core, Several Clients” felépítése, a Material Design 3 adaptív 600dp
            töréspontja, az állapotmegőrzési szabályok és a WCAG 2.1 AA akadálymentességi előírások.
          </p>
        </div>

        <section id="one-core-several-clients" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <Layers size={16} className="text-primary" />
            <h2>1. „One Core, Several Clients” Monorepo Felépítés</h2>
          </div>
          <p className="text-xs text-muted leading-relaxed">
            A Pala egyetlen közös adattípus- és üzletilogika-magot (<code className="text-primary font-mono">lib/</code>)
            használ, amelyre négy különböző felhasználói felület épül:
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
            <div className="p-3.5 rounded-xl bg-sidebar border border-border">
              <code className="text-primary font-mono font-bold">lib/ &amp; bin/</code>
              <p className="text-muted mt-1">
                Közös Dart Kréta API kliens, adatmodellek, Demó adatok, ICS/CSV export és a kétpaneles TUI.
              </p>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-border">
              <code className="text-primary font-mono font-bold">app/</code>
              <p className="text-muted mt-1">
                Material Design 3 Flutter alkalmazás Androidra, Windowsra, Linuxra és macOS-re (<code className="font-mono">package:pala</code>).
              </p>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-border">
              <code className="text-primary font-mono font-bold">extension/</code>
              <p className="text-muted mt-1">
                Manifest V3 böngészőbővítmény (Chrome &amp; Firefox) építési lépés nélküli ES modulokkal.
              </p>
            </div>
            <div className="p-3.5 rounded-xl bg-sidebar border border-border">
              <code className="text-primary font-mono font-bold">website/</code>
              <p className="text-muted mt-1">
                Statikus Next.js 16 + Tailwind CSS v4 főoldal és dokumentációs portál.
              </p>
            </div>
          </div>
        </section>

        <section id="adaptiv-600dp-layout" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <Cpu size={16} className="text-primary" />
            <h2>2. Adaptív 600dp Töréspont és Állapotmegőrzés</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="border-b border-border text-muted">
                  <th className="py-2.5 pr-4">Töréspont</th>
                  <th className="py-2.5 px-4">Elsődleges Komponens</th>
                  <th className="py-2.5 px-4">Elrendezési Minta</th>
                  <th className="py-2.5 pl-4">Érintési Célterület (WCAG 2.1 AA)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/60 text-fg">
                <tr>
                  <td className="py-3 pr-4 font-mono text-primary font-bold">Compact (&lt; 600dp)</td>
                  <td className="py-3 px-4">Alsó <code className="font-mono">NavigationBar</code></td>
                  <td className="py-3 px-4">Egyoszlopos görgethető folyam, alsó hüvelykujj-zóna</td>
                  <td className="py-3 pl-4">Min. 48×48dp (Android) / 44×44pt (iOS)</td>
                </tr>
                <tr>
                  <td className="py-3 pr-4 font-mono text-primary font-bold">Expanded (&gt;= 600dp)</td>
                  <td className="py-3 px-4">Bal oldali <code className="font-mono">NavigationRail</code></td>
                  <td className="py-3 px-4">Master-Detail osztott nézet vezérlőpanelekkel</td>
                  <td className="py-3 pl-4">Min. 48×48dp + hover és fókusz állapotok</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div id="allapotmegorzes" />
          <div id="wcag-akadalymentesseg" />
          <CodeBlock
            title="app/lib/ — WCAG 2.1 AA Érintési Célterület és Szemantika példa"
            language="dart"
            code={`Semantics(
  button: true,
  label: 'Szellem Jegy hozzáadása',
  child: ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    child: IconButton.filledTonal(
      onPressed: onAddGhostGrade,
      icon: const Icon(Icons.calculate_outlined),
    ),
  ),
)`}
          />
        </section>

        <div className="flex items-center justify-between pt-4 border-t border-border">
          <button
            type="button"
            onClick={() => onSelectPage("guide-absences")}
            className="text-xs font-bold text-muted hover:text-fg cursor-pointer"
          >
            ← Előző: Mulasztások & 250 Órás Limit
          </button>
          <button
            type="button"
            onClick={() => onSelectPage("security")}
            className="text-xs font-bold text-primary hover:underline cursor-pointer"
          >
            Következő: Kréta API & Helyi Titkosítás →
          </button>
        </div>
      </div>
    );
  }

  if (activePage === "dev-ext-tui") {
    return (
      <div className="space-y-8 min-w-0 w-full">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-primary uppercase block mb-1">
            FEJLESZTŐI SPECIFIKÁCIÓK / EXTENSION MV3 & TUI ARCHITEKTÚRA
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-fg tracking-tight mb-3">
            Böngésző Bővítmény (Manifest V3) & TUI Renderelő Motor
          </h1>
          <p className="text-xs sm:text-sm text-muted leading-relaxed max-w-2xl">
            A Chrome/Firefox Manifest V3 bővítmény felépítése (380×580 Popup és Side Panel), valamint
            a Dart TUI alternatív képernyőpufferes, null-vibrálású diff-renderelője.
          </p>
        </div>

        <section id="manifest-v3-architektura" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <Puzzle size={16} className="text-primary" />
            <h2>1. Böngésző Bővítmény (Manifest V3 — Chrome & Firefox)</h2>
          </div>
          <p id="popup-es-sidepanel" className="text-xs text-muted leading-relaxed">
            Az <code className="text-primary font-mono">extension/</code> mappa nem igényel Webpack vagy Vite
            fordítási lépést: közvetlenül betölthető a böngészőbe. A <code className="font-mono">manifest.json</code>{" "}
            egyszerre támogatja a Chromium <code className="font-mono">side_panel</code> és a Firefox{" "}
            <code className="font-mono">sidebar_action</code> API-ját.
          </p>
          <CodeBlock
            title="extension/manifest.json — Keresztböngészős MV3 konfiguráció"
            language="json"
            code={`{
  "manifest_version": 3,
  "name": "Pala — Kréta Kliens",
  "permissions": ["storage", "alarms", "declarativeNetRequest", "sidePanel"],
  "action": {
    "default_popup": "popup/popup.html"
  },
  "side_panel": {
    "default_path": "dashboard/dashboard.html"
  },
  "sidebar_action": {
    "default_panel": "dashboard/dashboard.html",
    "default_title": "Pala Vezérlőpult"
  }
}`}
          />
        </section>

        <section id="tui-screenbuffer" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <Terminal size={16} className="text-primary" />
            <h2>2. TUI Null-Vibrálású Képernyőpuffer (TuiScreenBuffer)</h2>
          </div>
          <p id="unicode-box-render" className="text-xs text-muted leading-relaxed">
            A <code className="text-primary font-mono">lib/app/tui/screen_buffer.dart</code> osztály az alternatív
            képernyőpuffert (<code className="font-mono">\x1B[?1049h</code>) használja. Minden képkockánál soronkénti
            diffet számol az előző állapothoz (<code className="font-mono">_previousFrame</code>) képest, és csak a
            módosult sorokat küldi ki a terminálnak:
          </p>
          <CodeBlock
            title="lib/app/tui/screen_buffer.dart — Soronkénti atomi diff-renderelés"
            language="dart"
            code={`final out = StringBuffer();
for (var r = 0; r < h; r++) {
  final line = normalized[r];
  if (!forceRedraw && r < _previousFrame.length && _previousFrame[r] == line) {
    continue; // Változatlan sor kihagyása -> 0 vibrálás!
  }
  out.write('\\x1B[\${r + 1};1H\$line\\x1B[0m\\x1B[K');
}
if (out.isNotEmpty) {
  stdout.write(out.toString());
}`}
          />
        </section>

        <div className="flex items-center justify-between pt-4 border-t border-border">
          <button
            type="button"
            onClick={() => onSelectPage("security")}
            className="text-xs font-bold text-muted hover:text-fg cursor-pointer"
          >
            ← Előző: Kréta API & Titkosítás
          </button>
          <button
            type="button"
            onClick={() => onSelectPage("dev-contributing")}
            className="text-xs font-bold text-primary hover:underline cursor-pointer"
          >
            Következő: Közreműködés & Honosítás →
          </button>
        </div>
      </div>
    );
  }

  if (activePage === "dev-contributing") {
    return (
      <div className="space-y-8 min-w-0 w-full">
        <div>
          <span className="text-[11px] font-mono font-bold tracking-widest text-primary uppercase block mb-1">
            FEJLESZTŐI SPECIFIKÁCIÓK / KÖZREMŰKÖDÉS & I18N
          </span>
          <h1 className="text-2xl sm:text-4xl font-black text-fg tracking-tight mb-3">
            Fejlesztői Útmutató, Tesztelés és Honosítás (i18n)
          </h1>
          <p className="text-xs sm:text-sm text-muted leading-relaxed max-w-2xl">
            Hogyan csatlakozhatsz a Pala fejlesztéséhez: szinkronizációs szabályok a Dart mag és a
            bővítmény között, nyelvi irányelvek és kötelező CI ellenőrzések.
          </p>
        </div>

        <DocCallout type="warning" title="Kézi API és DemoData Szinkronizáció">
          Mivel a böngészőbővítmény (<code className="font-mono">extension/</code>) tiszta JavaScriptben fut,
          minden <code className="font-mono">lib/api/</code> vagy <code className="font-mono">lib/models/</code>{" "}
          módosítást, valamint a <code className="font-mono">lib/api/demo_data.dart</code> demó adatokat
          kézzel is szinkronban kell tartani az <code className="font-mono">extension/shared/kreta_api.js</code> fájllal!
        </DocCallout>

        <section id="repo-struktura" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-4">
          <div className="flex items-center gap-2 text-sm font-bold text-fg">
            <GitBranch size={16} className="text-primary" />
            <h2>1. Kódolási és Honosítási (i18n) Szabályok</h2>
          </div>
          <ul id="api-es-demodata-szinkron" className="space-y-2 text-xs text-muted">
            <li id="honositas-i18n" className="flex items-start gap-2">
              <CheckCircle2 size={14} className="text-primary shrink-0 mt-0.5" />
              <span>
                <strong className="text-fg">Felhasználói felület nyelve (Magyar):</strong> Minden UI
                szöveg, CLI súgó, hibaüzenet és dokumentáció magyar nyelvű.
              </span>
            </li>
            <li className="flex items-start gap-2">
              <CheckCircle2 size={14} className="text-primary shrink-0 mt-0.5" />
              <span>
                <strong className="text-fg">Forráskód és azonosítók (Angol):</strong> Minden osztálynév,
                függvény, változó és kódkomment angol nyelvű.
              </span>
            </li>
            <li className="flex items-start gap-2">
              <CheckCircle2 size={14} className="text-primary shrink-0 mt-0.5" />
              <span>
                <strong className="text-fg">Conventional Commits:</strong> A commit üzenetek a{" "}
                <code className="font-mono text-primary">feat:</code>,{" "}
                <code className="font-mono text-primary">fix(website):</code>,{" "}
                <code className="font-mono text-primary">docs:</code> formátumot követik.
              </span>
            </li>
          </ul>
        </section>

        <section id="ci-ellenorzo-parancsok" className="bg-card border border-border rounded-2xl p-5 sm:p-6 space-y-3">
          <h2 className="text-sm font-bold text-fg">
            2. Kötelező CI Ellenőrzések (Verification Suite)
          </h2>
          <p className="text-xs text-muted">
            Pull request beküldése előtt futtasd az összes módosított komponens ellenőrző parancsát:
          </p>
          <CodeBlock
            title="Teljes ellenőrzési folyamat (Root, App, Extension, Website)"
            language="bash"
            code={`# 1. Dart mag & TUI (a CI az info jelzéseket is hibának tekinti!)
dart analyze --fatal-infos
dart test

# 2. Flutter alkalmazás
cd app && flutter analyze

# 3. Böngészőbővítmény szintaxis-ellenőrzés
node --check extension/shared/kreta_api.js
node --check extension/popup/popup.js
node --check extension/dashboard/dashboard.js

# 4. Next.js dokumentációs weboldal
cd website && npm run lint && npm run build`}
          />
        </section>
      </div>
    );
  }

  return null;
}

interface DocsRightTocProps {
  activePage: string;
  onSelectPage: (pageId: string) => void;
}

export function DocsRightToc({ activePage, onSelectPage }: DocsRightTocProps) {
  const headings: TocHeading[] = PAGE_TOC_MAP[activePage] || [
    { id: "attekintes", label: "Oldal áttekintése", level: 2 },
  ];

  const scrollToTop = () => {
    if (typeof window !== "undefined") {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };

  return (
    <aside
      aria-label="Oldal tartalomjegyzéke"
      className="w-56 shrink-0 hidden xl:block sticky top-[93px] h-[calc(100vh-118px)] overflow-y-auto pl-2 self-start"
    >
      <div className="space-y-5">
        {/* Table of Contents */}
        <div>
          <div className="flex items-center gap-2 text-[11px] font-black uppercase tracking-wider text-fg mb-2.5">
            <ListTree size={13} className="text-primary" />
            <span>Ezen az oldalon</span>
          </div>
          <ul className="space-y-1.5 border-l border-border pl-3 text-xs">
            {headings.map((h) => (
              <li key={h.id} className={h.level === 3 ? "pl-2.5" : ""}>
                <a
                  href={`#${h.id}`}
                  className="block py-0.5 text-muted hover:text-primary transition-colors leading-snug"
                >
                  {h.label}
                </a>
              </li>
            ))}
          </ul>
        </div>

        {/* Quick Section Pillar Links */}
        <div className="pt-4 border-t border-border space-y-2">
          <div className="text-[10px] font-mono font-bold uppercase tracking-wider text-muted">
            Dokumentációs Szekciók
          </div>
          <div className="space-y-1 text-xs font-semibold">
            <Link
              href="/docs/getting-started"
              onClick={() => onSelectPage("installation")}
              className="flex items-center justify-between py-1 text-muted hover:text-primary transition-colors"
            >
              <span>A. Kezdő Lépések</span>
              <span className="text-[10px] font-mono text-subtle">/getting-started</span>
            </Link>
            <Link
              href="/docs/guides"
              onClick={() => onSelectPage("guide-dashboard")}
              className="flex items-center justify-between py-1 text-muted hover:text-primary transition-colors"
            >
              <span>B. Funkció Útmutatók</span>
              <span className="text-[10px] font-mono text-subtle">/guides</span>
            </Link>
            <Link
              href="/docs/developers"
              onClick={() => onSelectPage("dev-architecture")}
              className="flex items-center justify-between py-1 text-muted hover:text-primary transition-colors"
            >
              <span>C. Fejlesztői Specifikációk</span>
              <span className="text-[10px] font-mono text-subtle">/developers</span>
            </Link>
          </div>
        </div>

        {/* Utility Actions */}
        <div className="pt-4 border-t border-border space-y-2 text-xs">
          <a
            href="https://github.com/CsPS0/pala/tree/main/website/src/content/docs"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 text-muted hover:text-fg transition-colors"
          >
            <FileCode2 size={13} className="text-primary" />
            <span>MDX forrásfájlok GitHubon</span>
            <ExternalLink size={11} />
          </a>
          <button
            type="button"
            onClick={scrollToTop}
            className="flex items-center gap-2 text-muted hover:text-primary transition-colors cursor-pointer"
          >
            <ArrowUp size={13} />
            <span>Vissza az oldal tetejére</span>
          </button>
        </div>
      </div>
    </aside>
  );
}
