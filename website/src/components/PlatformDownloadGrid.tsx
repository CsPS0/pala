"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowRight, ChevronDown } from "lucide-react";
import { WindowsIcon, AppleIcon, LinuxIcon } from "./PlatformIcons";
import { CONCEPT_ICONS } from "@/lib/icons";
import { detectClientOS } from "@/lib/detectOS";
import { useRelease } from "@/lib/useRelease";
import { shownVersion } from "@/lib/ReleaseContext";

type DesktopOS = "windows" | "macos" | "linux";
type CardId = "desktop" | "phone" | "extension";

export function PlatformDownloadGrid() {
  const release = useRelease();
  const [desktopOS, setDesktopOS] = useState<DesktopOS>("windows");
  const [recommended, setRecommended] = useState<CardId>("desktop");
  const [isIPhone, setIsIPhone] = useState(false);

  useEffect(() => {
    const os = detectClientOS();
    /* eslint-disable react-hooks/set-state-in-effect */
    if (os === "macos" || os === "linux") setDesktopOS(os);
    if (os === "android" || os === "ios") setRecommended("phone");
    if (os === "ios") setIsIPhone(true);
    /* eslint-enable react-hooks/set-state-in-effect */
  }, []);

  const desktop: Record<DesktopOS, { name: string; label: string; href: string; Icon: typeof WindowsIcon }> = {
    windows: { name: "Windows", label: "Letöltés Windowsra", href: release.assets.windowsExe, Icon: WindowsIcon },
    macos: { name: "Mac", label: "Letöltés Macre", href: release.assets.macDmg, Icon: AppleIcon },
    linux: { name: "Linux", label: "Letöltés Linuxra", href: release.assets.linuxAppImage, Icon: LinuxIcon },
  };
  const current = desktop[desktopOS];
  const others = (Object.keys(desktop) as DesktopOS[]).filter((os) => os !== desktopOS);

  const cards: {
    id: CardId;
    title: string;
    Icon: React.ComponentType<{ size?: number; className?: string }>;
    text: string;
    action: { label: string; href: string };
    extra: React.ReactNode;
  }[] = [
    {
      id: "desktop",
      title: "Számítógépre",
      Icon: CONCEPT_ICONS.desktop,
      text: "Windowsra, Macre és Linuxra. Töltsd le, indítsd el, és kövesd a telepítő lépéseit.",
      action: { label: current.label, href: current.href },
      extra: (
        <span>
          Másik gépre:{" "}
          {others.map((os, i) => (
            <React.Fragment key={os}>
              {i > 0 && " · "}
              <a href={desktop[os].href} target="_blank" rel="noopener noreferrer" className="text-fg font-bold hover:underline">
                {desktop[os].name}
              </a>
            </React.Fragment>
          ))}
        </span>
      ),
    },
    {
      id: "phone",
      title: "Telefonra",
      Icon: CONCEPT_ICONS.phone,
      // iPhone has no one-tap install: it is sideloaded with a computer, so it gets the guide.
      text: isIPhone
        ? "iPhone-ra egy ingyenes programmal és egy számítógéppel teheted fel. Az útmutató lépésről lépésre végigvezet."
        : "Androidos telefonra. Nyisd meg a letöltött fájlt a telefonon, és engedélyezd a telepítést, ha a telefon rákérdez.",
      action: isIPhone
        ? { label: "Útmutató iPhone-ra", href: "/docs#inst-ios" }
        : { label: "Letöltés Androidra", href: release.assets.androidUniversal },
      extra: isIPhone ? (
        <span>
          Androidra:{" "}
          <a href={release.assets.androidUniversal} className="text-fg font-bold hover:underline">
            letöltés
          </a>
        </span>
      ) : (
        <span>
          iPhone-ra:{" "}
          <Link href="/docs#inst-ios" className="text-fg font-bold hover:underline">
            telepítési útmutató
          </Link>{" "}
          (kísérleti)
        </span>
      ),
    },
    {
      id: "extension",
      title: "Böngészőbe",
      Icon: CONCEPT_ICONS.extension,
      text: "Chrome-ba, Edge-be és Brave-be. Az eszköztáron mindig kéznél van, telepítés nélkül.",
      action: { label: "Bővítmény letöltése", href: release.assets.extensionZip },
      // Until there is a store listing, the ZIP is loaded in developer mode: three short steps.
      extra: (
        <ol className="text-left list-decimal pl-5 space-y-1">
          <li>Csomagold ki a letöltött fájlt egy mappába.</li>
          <li>A böngésző bővítményoldalán kapcsold be a fejlesztői módot.</li>
          <li>
            Kattints a „Kicsomagolt betöltése” gombra, és válaszd ki a mappát.{" "}
            <Link href="/docs?page=installation&tab=extension" className="text-fg font-bold hover:underline">
              Részletesen
            </Link>
          </li>
        </ol>
      ),
    },
  ];

  return (
    <section
      id="letoltes"
      aria-labelledby="download-grid-heading"
      className="py-12 sm:py-16 px-4 sm:px-6 max-w-5xl mx-auto w-full"
    >
      <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
        <p className="text-xs sm:text-sm font-extrabold uppercase tracking-widest text-primary mb-2">Ingyenes, reklám nélkül</p>
        <h2 id="download-grid-heading" className="text-3xl sm:text-4xl font-black tracking-tight text-fg mb-3">
          Letöltés
        </h2>
        <p className="text-base text-muted leading-relaxed">
          Válaszd ki, hol szeretnéd használni. Mindegyik ingyenes, és ugyanazt tudja.
          {shownVersion(release) && <> Legfrissebb kiadás: {shownVersion(release)}.</>}
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {cards.map((card) => {
          const isRecommended = card.id === recommended;
          return (
            <div
              key={card.id}
              className={`bg-card border rounded-xl p-5 flex flex-col gap-4 ${isRecommended ? "border-primary/60" : "border-border"}`}
            >
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-primary/10 border border-primary/25 text-primary flex items-center justify-center shrink-0">
                  <card.Icon size={20} />
                </div>
                <h3 className="text-lg font-extrabold text-fg">{card.title}</h3>
                {isRecommended && (
                  <span className="ml-auto text-xs font-bold text-primary border border-primary/40 rounded-md px-2 py-0.5">
                    Ajánlott
                  </span>
                )}
              </div>
              <p className="text-base text-muted leading-relaxed flex-1">{card.text}</p>
              <a
                href={card.action.href}
                target="_blank"
                rel="noopener noreferrer"
                className={`inline-flex items-center justify-center gap-2 text-sm font-extrabold px-4 py-2.5 rounded-lg transition-colors duration-150 ${
                  isRecommended
                    ? "bg-primary-fill hover:bg-primary-fill-hover text-on-primary"
                    : "bg-sidebar hover:bg-card-hover text-fg border border-border"
                }`}
              >
                <CONCEPT_ICONS.download size={15} />
                <span>{card.action.label}</span>
              </a>
              {card.extra && <div className="text-sm text-muted">{card.extra}</div>}
            </div>
          );
        })}
      </div>

      {/* Everything technical stays one click away, not in front of everyone. */}
      <details className="group mt-6 bg-card border border-border rounded-xl px-5 py-4">
        <summary className="flex items-center justify-between cursor-pointer list-none text-base font-bold text-fg">
          Haladóknak
          <ChevronDown size={18} className="text-muted transition-transform group-open:rotate-180" />
        </summary>
        <div className="mt-3 text-sm text-muted leading-relaxed space-y-2">
          <p>
            Parancssori változat (TUI), csomagkezelők (Scoop, Homebrew, AUR, .deb), ZIP és tar.gz csomagok, valamint
            minden korábbi kiadás és az ellenőrző összegek (SHA256SUMS).
          </p>
          <div className="flex flex-wrap gap-x-5 gap-y-1">
            <Link href="/docs?page=installation" className="inline-flex items-center gap-1.5 font-bold text-fg hover:underline">
              Telepítési útmutató
              <ArrowRight size={14} />
            </Link>
            <a
              href={release.releaseUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 font-bold text-fg hover:underline"
            >
              Kiadások a GitHubon
              <ArrowRight size={14} />
            </a>
          </div>
        </div>
      </details>
    </section>
  );
}
