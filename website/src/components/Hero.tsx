"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import { Download, ArrowDown } from "lucide-react";
import { WindowsIcon, AppleIcon, AndroidIcon, LinuxIcon } from "./PlatformIcons";
import { detectClientOS, type DetectedPlatform } from "@/lib/detectOS";
import { useRelease } from "@/lib/useRelease";
import { shownVersion } from "@/lib/ReleaseContext";
import { HeroPreview } from "./HeroPreview";

type PlatformKey = DetectedPlatform | "unknown";

interface PlatformConfig {
  /** Main button text. */
  cta: string;
  /** One plain sentence under the buttons; null hides the line. */
  hint: string | null;
  icon: React.ComponentType<{ size?: number; className?: string }>;
}

// Written for students and parents, not developers: what to download, in plain words.
const PLATFORM_CONFIGS: Record<PlatformKey, PlatformConfig> = {
  windows: {
    cta: "Letöltés Windowsra",
    hint: "Windowst használsz, ezért a számítógépes alkalmazást ajánljuk.",
    icon: WindowsIcon,
  },
  macos: {
    cta: "Letöltés Macre",
    hint: "Macet használsz, ezért a számítógépes alkalmazást ajánljuk.",
    icon: AppleIcon,
  },
  linux: {
    cta: "Letöltés Linuxra",
    hint: "Linuxot használsz, ezért a számítógépes alkalmazást ajánljuk.",
    icon: LinuxIcon,
  },
  android: {
    cta: "Letöltés Androidra",
    hint: "Androidos telefont használsz, ezért a telefonos alkalmazást ajánljuk.",
    icon: AndroidIcon,
  },
  ios: {
    cta: "Letöltési lehetőségek",
    hint: "iPhone-ra még nincs alkalmazás. Számítógépen a böngészőbővítményt használhatod.",
    icon: AppleIcon,
  },
  unknown: {
    cta: "Letöltés",
    hint: null,
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

  const config = PLATFORM_CONFIGS[detectedPlatform] || PLATFORM_CONFIGS.unknown;
  const IconComp = config.icon;
  const version = shownVersion(release);

  return (
    <section
      id="hero"
      className="pt-6 sm:pt-10 pb-12 px-4 sm:px-6 text-center max-w-6xl mx-auto flex flex-col items-center w-full overflow-hidden"
    >
      {/* Brand */}
      <div className="flex flex-col items-center gap-2.5 mb-6">
        <Image
          src="/logo.svg"
          alt="Pala logó"
          width={64}
          height={64}
          preload
          className="w-14 h-14 sm:w-16 sm:h-16 rounded-2xl sm:rounded-3xl object-contain transition-transform"
        />
        <span className="font-black text-sm sm:text-base tracking-widest text-fg">PALA</span>
      </div>

      {/* What it is, in the visitor's words */}
      <h1 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight leading-[1.12] mb-4 sm:mb-5 max-w-4xl text-fg">
        A Kréta, <span className="text-primary">átláthatóan</span>.
      </h1>

      <p className="text-base sm:text-lg text-muted max-w-2xl mx-auto leading-relaxed mb-7 sm:mb-9">
        Jegyeid, órarended, hiányzásaid és üzeneteid egy helyen: telefonon, számítógépen vagy a
        böngészőben. Ingyenes, reklám nélküli, és az adataid a saját eszközödön maradnak.
      </p>

      {/* One primary action, one friendly secondary */}
      <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 mb-4 w-full sm:w-auto">
        <a
          href="#letoltes"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-primary-fill hover:bg-primary-fill-hover text-on-primary font-extrabold text-base px-7 sm:px-8 py-3.5 rounded-2xl transition-all"
        >
          <IconComp size={18} className="shrink-0" />
          <span>{config.cta}</span>
        </a>

        <a
          href="#hogyan-mukodik"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-card hover:bg-card-hover text-fg border border-border font-bold text-base px-6 sm:px-7 py-3.5 rounded-2xl transition-all"
        >
          <ArrowDown size={18} className="shrink-0 text-muted" />
          <span>Hogyan működik?</span>
        </a>
      </div>

      {config.hint && <p className="text-sm text-muted mb-2 px-2">{config.hint}</p>}

      {/* Small trust line instead of jargon in the headline */}
      <p className="text-xs sm:text-sm text-muted mb-8 px-2">
        Ingyenes · Reklám és követés nélkül · Nyílt forráskódú
        {version && <> · Legfrissebb kiadás: {version}</>}
      </p>

      <HeroPreview />
    </section>
  );
}
