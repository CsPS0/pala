"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { Download, BookOpen } from "lucide-react";
import { WindowsIcon, AppleIcon, AndroidIcon, LinuxIcon, GitHubIcon } from "./PlatformIcons";
import { detectClientOS, type DetectedPlatform } from "@/lib/detectOS";
import { useRelease } from "@/lib/useRelease";
import { HeroPreview } from "./HeroPreview";

type PlatformKey = DetectedPlatform | "unknown";

interface PlatformConfig {
  name: string;
  badgeText: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
}

const PLATFORM_CONFIGS: Record<PlatformKey, PlatformConfig> = {
  windows: {
    name: "Windows",
    badgeText: "Asztali alkalmazás & TUI (64-bit)",
    icon: WindowsIcon,
  },
  android: {
    name: "Android",
    badgeText: "Közvetlen APK & Termux",
    icon: AndroidIcon,
  },
  ios: {
    name: "iOS",
    badgeText: "Fejlesztés alatt (Hamarosan)",
    icon: AppleIcon,
  },
  macos: {
    name: "macOS",
    badgeText: "Apple Silicon & Intel",
    icon: AppleIcon,
  },
  linux: {
    name: "Linux",
    badgeText: ".deb, AUR és AppImage",
    icon: LinuxIcon,
  },
  unknown: {
    name: "Minden platform",
    badgeText: "Válassz platformot",
    icon: Download,
  },
};

export function Hero() {
  const [detectedPlatform, setDetectedPlatform] = useState<PlatformKey>("unknown");
  const release = useRelease();

  useEffect(() => {
    const os = detectClientOS();
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setDetectedPlatform(os);
  }, []);

  const config = PLATFORM_CONFIGS[detectedPlatform] || PLATFORM_CONFIGS.windows;
  const IconComp = config.icon;

  return (
    <section
      id="hero"
      className="pt-6 sm:pt-10 pb-12 px-4 sm:px-6 text-center max-w-6xl mx-auto flex flex-col items-center w-full overflow-hidden"
    >
      {/* Brand Header */}
      <div className="flex flex-col items-center gap-2.5 mb-5">
        <Image
          src="/logo.svg"
          alt="Pala logó"
          width={64}
          height={64}
          preload
          className="w-14 h-14 sm:w-16 sm:h-16 rounded-2xl sm:rounded-3xl object-contain transition-transform"
        />
        <div className="inline-flex items-center gap-2 bg-sidebar border border-border px-3.5 py-1 rounded-xl">
          <span className="font-black text-sm sm:text-base tracking-widest text-fg">
            PALA
          </span>
          <span className="text-[10px] sm:text-[11px] font-bold bg-primary/15 text-primary border border-primary/30 px-2 py-0.5 rounded-md min-w-[36px] text-center">
            {release.isLoading ? "..." : release.version}
          </span>
          <span className="hidden sm:inline text-[10px] font-mono text-muted border-l border-border pl-2">
            Zero-Telemetry • MIT
          </span>
        </div>
      </div>

      {/* Main Headline / Tagline */}
      <h1 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight leading-[1.12] mb-4 sm:mb-5 max-w-4xl text-fg">
        Nyílt forráskódú Kréta kliens,{" "}
        <span className="text-primary">köztes szerver nélkül</span>.
      </h1>

      {/* Subtitle */}
      <p className="text-sm sm:text-base md:text-lg text-muted max-w-2xl mx-auto leading-relaxed mb-7 sm:mb-9">
        Elérhető <strong className="text-fg">mobilra</strong>,{" "}
        <strong className="text-fg">asztali gépre</strong>,{" "}
        <strong className="text-fg">böngészőbővítményként</strong> és{" "}
        <strong className="text-fg">terminálban (TUI)</strong>. Egy helyen az
        órarended, a Szellem Jegy kalkulátorod és a 250 órás mulasztásfigyelőd — köztes
        szerverek és reklámok nélkül.
      </p>

      {/* Primary CTAs */}
      <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 mb-5 w-full sm:w-auto">
        <a
          href="#letoltes"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-primary-fill hover:bg-primary-fill-hover text-on-primary font-extrabold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-2xl transition-all"
        >
          <Download size={18} className="shrink-0" />
          <span>Letöltés</span>
        </a>

        <Link
          href="/docs"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-card hover:bg-card-hover text-fg border border-border hover:border-primary font-bold text-sm sm:text-base px-6 sm:px-7 py-3.5 rounded-2xl transition-all"
        >
          <BookOpen size={18} className="text-primary shrink-0" />
          <span>Dokumentáció</span>
        </Link>

        <a
          href="https://github.com/CsPS0/pala"
          target="_blank"
          rel="noopener noreferrer"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-sidebar hover:bg-card text-fg border border-border hover:border-primary/60 font-bold text-sm sm:text-base px-5 sm:px-6 py-3.5 rounded-2xl transition-all"
        >
          <GitHubIcon size={16} className="shrink-0" />
          <span>GitHub</span>
        </a>
      </div>

      {/* Platform Detection & Version Info */}
      <div className="flex flex-wrap items-center justify-center gap-2 text-[11px] sm:text-xs text-muted mb-8 px-2">
        <div className="flex items-center gap-1.5 text-fg">
          <IconComp size={14} className="text-primary shrink-0" />
          <span>Felismerve: {config.name} ({config.badgeText})</span>
        </div>
        <span>•</span>
        <span>
          Legfrissebb kiadás:{" "}
          <strong className="text-fg">
            {release.isLoading ? "..." : release.version}
          </strong>
        </span>
        {release.formattedDate && <span>({release.formattedDate})</span>}
      </div>

      <HeroPreview />
    </section>
  );
}
