"use client";

import React, { useEffect, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { CONCEPT_ICONS } from "@/lib/icons";
import { detectClientOS } from "@/lib/detectOS";

// Real screenshots from the apps in demo mode; regenerate them with the steps in docs/DEV.md.
type TabId = "desktop" | "phone" | "extension";

interface Shot {
  file: string;
  label: string;
  alt: string;
}

interface PreviewTab {
  id: TabId;
  label: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  width: number;
  height: number;
  shots: Shot[];
}

const TABS: PreviewTab[] = [
  {
    id: "desktop",
    label: "Asztali",
    icon: CONCEPT_ICONS.desktop,
    width: 1600,
    height: 1000,
    shots: [
      { file: "desktop-vezerlopult", label: "Vezérlőpult", alt: "A Pala asztali alkalmazás vezérlőpultja demó adatokkal" },
      { file: "desktop-jegyek", label: "Jegyek", alt: "A Pala asztali alkalmazás jegyek nézete a Szellem Jegy kalkulátorral" },
    ],
  },
  {
    id: "phone",
    label: "Telefon",
    icon: CONCEPT_ICONS.phone,
    width: 780,
    height: 1688,
    shots: [
      { file: "phone-fooldal", label: "Főoldal", alt: "A Pala telefonos alkalmazás főoldala demó adatokkal" },
      { file: "phone-orarend", label: "Órarend", alt: "A Pala telefonos alkalmazás heti órarendje" },
    ],
  },
  {
    id: "extension",
    label: "Bővítmény",
    icon: CONCEPT_ICONS.extension,
    width: 760,
    height: 1160,
    shots: [
      { file: "popup-jegyek", label: "Jegyek", alt: "A Pala böngészőbővítmény felugró ablaka a jegyekkel" },
      { file: "popup-feladatok", label: "Feladatok", alt: "A Pala böngészőbővítmény felugró ablaka a feladatokkal" },
    ],
  },
];

const FRAME: Record<TabId, string> = {
  desktop: "w-full max-w-4xl rounded-xl",
  phone: "w-full max-w-[300px] rounded-[28px] p-2",
  extension: "w-full max-w-[380px] rounded-xl",
};

export function HeroPreview() {
  const [active, setActive] = useState<TabId>("desktop");
  // Selected screenshot per tab, kept when switching tabs or themes.
  const [shotIndex, setShotIndex] = useState<Record<TabId, number>>({ desktop: 0, phone: 0, extension: 0 });

  useEffect(() => {
    const os = detectClientOS();
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (os === "android" || os === "ios") setActive("phone");
  }, []);

  const onTabKeyDown = (e: React.KeyboardEvent) => {
    const i = TABS.findIndex((t) => t.id === active);
    const n = TABS.length;
    const next = { ArrowRight: (i + 1) % n, ArrowLeft: (i + n - 1) % n, Home: 0, End: n - 1 }[e.key];
    if (next === undefined) return;
    e.preventDefault();
    setActive(TABS[next].id);
    document.getElementById(`preview-tab-${TABS[next].id}`)?.focus();
  };

  return (
    <div className="w-full flex flex-col items-center">
      <div
        role="tablist"
        aria-label="Előnézet kiválasztása"
        onKeyDown={onTabKeyDown}
        className="flex items-center gap-1.5 mb-5 p-1.5 rounded-xl bg-sidebar border border-border max-w-full overflow-x-auto no-scrollbar"
      >
        {TABS.map((tab) => {
          const selected = tab.id === active;
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              role="tab"
              id={`preview-tab-${tab.id}`}
              aria-selected={selected}
              aria-controls={`preview-panel-${tab.id}`}
              tabIndex={selected ? 0 : -1}
              onClick={() => setActive(tab.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold transition-colors duration-150 cursor-pointer whitespace-nowrap ${
                selected ? "bg-primary-fill text-on-primary" : "text-muted hover:text-fg hover:bg-card-hover"
              }`}
            >
              <Icon size={15} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {TABS.map((tab) => {
        const index = shotIndex[tab.id];
        const shot = tab.shots[index];
        return (
          <div
            key={tab.id}
            role="tabpanel"
            id={`preview-panel-${tab.id}`}
            aria-labelledby={`preview-tab-${tab.id}`}
            hidden={tab.id !== active}
            className="w-full flex flex-col items-center"
          >
            <div className={`bg-card border border-border overflow-hidden ${FRAME[tab.id]}`}>
              <div
                className={`relative w-full overflow-hidden bg-bg ${tab.id === "phone" ? "rounded-[20px]" : ""}`}
                style={{ aspectRatio: `${tab.width} / ${tab.height}` }}
              >
                {(["dark", "light"] as const).map((theme) => (
                  <Image
                    key={`${shot.file}-${theme}`}
                    src={`/previews/${shot.file}-${theme}.webp`}
                    alt={shot.alt}
                    width={tab.width}
                    height={tab.height}
                    preload={tab.id === "desktop" && index === 0}
                    className={`absolute inset-0 w-full h-full object-cover only-${theme}`}
                  />
                ))}
              </div>
            </div>

            <div className="flex items-center gap-2 mt-4" role="group" aria-label={`${tab.label} képernyők`}>
              {tab.shots.map((s, i) => (
                <button
                  key={s.file}
                  type="button"
                  aria-pressed={i === index}
                  onClick={() => setShotIndex((prev) => ({ ...prev, [tab.id]: i }))}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition-colors duration-150 cursor-pointer ${
                    i === index ? "border-primary text-primary bg-primary/10" : "border-border text-muted hover:text-fg"
                  }`}
                >
                  {s.label}
                </button>
              ))}
            </div>
          </div>
        );
      })}

      <p className="mt-5 text-xs text-muted">
        Terminálban vagy böngészőben is fut:{" "}
        <Link href="/docs?page=tui" className="text-primary font-bold hover:underline">TUI</Link>
        {" · "}
        <Link href="/docs?page=webui" className="text-primary font-bold hover:underline">Webes felület</Link>
      </p>
    </div>
  );
}
