"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { WindowsIcon, AppleIcon, LinuxIcon } from "./PlatformIcons";
import { CONCEPT_ICONS } from "@/lib/icons";
import { detectClientOS } from "@/lib/detectOS";
import { useRelease } from "@/lib/useRelease";

type DesktopOS = "windows" | "macos" | "linux";

export function PlatformDownloadGrid() {
  const release = useRelease();
  const [desktopOS, setDesktopOS] = useState<DesktopOS>("windows");

  useEffect(() => {
    const os = detectClientOS();
    // eslint-disable-next-line react-hooks/set-state-in-effect
    if (os === "macos" || os === "linux") setDesktopOS(os);
  }, []);

  const desktop: Record<DesktopOS, { name: string; file: string; href: string; Icon: typeof WindowsIcon }> = {
    windows: { name: "Windows", file: "Telepítő (.exe)", href: release.assets.windowsExe, Icon: WindowsIcon },
    macos: { name: "macOS", file: "Lemezkép (.dmg)", href: release.assets.macDmg, Icon: AppleIcon },
    linux: { name: "Linux", file: "AppImage", href: release.assets.linuxAppImage, Icon: LinuxIcon },
  };
  const current = desktop[desktopOS];
  const others = (Object.keys(desktop) as DesktopOS[]).filter((os) => os !== desktopOS);

  const cards = [
    {
      id: "desktop",
      title: "Asztali",
      Icon: CONCEPT_ICONS.desktop,
      text: "Windows, macOS és Linux. A telepítő a terminálos (TUI) változatot is tartalmazza.",
      action: { label: `${current.name} ${current.file}`, href: current.href },
      extra: (
        <span>
          Más rendszer:{" "}
          {others.map((os, i) => (
            <React.Fragment key={os}>
              {i > 0 && " · "}
              <a href={desktop[os].href} target="_blank" rel="noopener noreferrer" className="text-primary font-bold hover:underline">
                {desktop[os].name}
              </a>
            </React.Fragment>
          ))}
        </span>
      ),
    },
    {
      id: "phone",
      title: "Telefon",
      Icon: CONCEPT_ICONS.phone,
      text: "Android 7.0 vagy újabb, közvetlenül telepíthető APK. iPhone-ra még nem érhető el.",
      action: { label: "Android APK", href: release.assets.androidUniversal },
      extra: null,
    },
    {
      id: "extension",
      title: "Bővítmény",
      Icon: CONCEPT_ICONS.extension,
      text: "Chrome, Edge, Brave és Firefox. Gyorsnézet a böngésző eszköztárán és teljes vezérlőpult.",
      action: { label: "Bővítmény (.zip)", href: release.assets.extensionZip },
      extra: null,
    },
  ];

  return (
    <section
      id="letoltes"
      aria-labelledby="download-grid-heading"
      className="py-12 sm:py-16 px-4 sm:px-6 max-w-5xl mx-auto w-full"
    >
      <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
        <h2 id="download-grid-heading" className="text-3xl sm:text-4xl font-black tracking-tight text-fg mb-3">
          Letöltés
        </h2>
        <p className="text-sm sm:text-base text-muted leading-relaxed">
          Legfrissebb kiadás: <strong className="text-fg">{release.isLoading ? "..." : release.version}</strong>
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {cards.map((card) => (
          <div key={card.id} className="bg-card border border-border rounded-xl p-5 flex flex-col gap-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-sidebar border border-border text-primary flex items-center justify-center shrink-0">
                <card.Icon size={20} />
              </div>
              <h3 className="text-lg font-extrabold text-fg">{card.title}</h3>
            </div>
            <p className="text-sm text-muted leading-relaxed flex-1">{card.text}</p>
            <a
              href={card.action.href}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center justify-center gap-2 text-sm font-extrabold px-4 py-2.5 rounded-lg bg-primary-fill hover:bg-primary-fill-hover text-on-primary transition-colors duration-150"
            >
              <CONCEPT_ICONS.download size={15} />
              <span>{card.action.label}</span>
            </a>
            {card.extra && <div className="text-xs text-muted text-center">{card.extra}</div>}
          </div>
        ))}
      </div>

      <div className="text-center mt-6">
        <Link
          href="/docs?page=installation"
          className="inline-flex items-center gap-1.5 text-sm font-bold text-primary hover:underline"
        >
          Minden telepítési mód a dokumentációban
          <ArrowRight size={14} />
        </Link>
      </div>
    </section>
  );
}
