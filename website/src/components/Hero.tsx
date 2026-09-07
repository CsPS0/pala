"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { Download, ArrowRight, BookOpen, Monitor, Smartphone, Terminal } from "lucide-react";
import { WindowsIcon, AppleIcon, AndroidIcon, LinuxIcon } from "./PlatformIcons";
import { detectClientOS, type DetectedPlatform } from "@/lib/detectOS";
import { useRelease } from "@/lib/useRelease";

type PlatformKey = DetectedPlatform | "unknown";
type PreviewMode = "desktop" | "mobile" | "tui";

interface PlatformConfig {
  name: string;
  badgeText: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
}

const PLATFORM_CONFIGS: Record<PlatformKey, PlatformConfig> = {
  windows: {
    name: "Windows",
    badgeText: "Asztali alkalmazás (64-bit)",
    icon: WindowsIcon,
  },
  android: {
    name: "Android",
    badgeText: "Közvetlen APK telepítés",
    icon: AndroidIcon,
  },
  ios: {
    name: "iOS",
    badgeText: "iPhone és iPad",
    icon: AppleIcon,
  },
  macos: {
    name: "macOS",
    badgeText: "Apple Silicon & Intel",
    icon: AppleIcon,
  },
  linux: {
    name: "Linux",
    badgeText: "APT, AUR & Telepítő",
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
  const [previewMode, setPreviewMode] = useState<PreviewMode>("desktop");
  const release = useRelease();

  useEffect(() => {
    const os = detectClientOS();
    setDetectedPlatform(os);
    if (os === "android" || os === "ios") {
      setPreviewMode("mobile");
    } else {
      setPreviewMode("desktop");
    }
  }, []);

  const config = PLATFORM_CONFIGS[detectedPlatform] || PLATFORM_CONFIGS.windows;
  const downloadInfo = release.getDownloadForOS(detectedPlatform);
  const IconComp = config.icon;

  return (
    <section className="pt-6 sm:pt-10 pb-12 px-4 sm:px-6 text-center max-w-5xl mx-auto flex flex-col items-center w-full overflow-hidden">
      {/* Brand Header: Logo on Top, then PALA Name & Version under it */}
      <div className="flex flex-col items-center gap-2.5 mb-6">
        <img
          src="/logo.svg"
          alt="Pala logó"
          width={64}
          height={64}
          className="w-14 h-14 sm:w-16 sm:h-16 rounded-2xl sm:rounded-3xl object-contain shadow-[0_0_30px_rgba(255,136,0,0.3)] transition-transform hover:scale-105"
        />
        <div className="inline-flex items-center gap-2 bg-[#151518] border border-[#28282d] px-3.5 py-1 rounded-xl shadow-lg">
          <span className="font-black text-sm sm:text-base tracking-widest text-[#f3f3f6]">
            PALA
          </span>
          <span className="text-[10px] sm:text-[11px] font-bold bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 px-2 py-0.5 rounded-md min-w-[36px] text-center">
            {release.isLoading ? "..." : release.version}
          </span>
        </div>
      </div>

      {/* Main Headline */}
      <h1 className="text-3xl sm:text-5xl md:text-6xl font-black tracking-tight leading-[1.15] mb-4 sm:mb-6 max-w-3xl text-[#f3f3f6]">
        A te Krétád, a te szabályaid.
      </h1>

      {/* Subtitle */}
      <p className="text-sm sm:text-base md:text-lg text-[#8c8c94] max-w-2xl mx-auto leading-relaxed mb-8 sm:mb-10">
        Egy helyen az órarended, a jegyeid, a mulasztásaid és a tanári üzeneteid. Asztali alkalmazásként,
        böngészőbővítményként, mobilon és terminálban is elérhető, teljesen ingyenesen és nyílt forráskóddal.
      </p>

      {/* CTA Buttons */}
      <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 mb-4 w-full sm:w-auto">
        {downloadInfo.isDirect ? (
          <a
            href={downloadInfo.url}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-2xl transition-all shadow-[0_0_30px_rgba(255,136,0,0.25)] hover:shadow-[0_0_40px_rgba(255,136,0,0.4)] hover:-translate-y-0.5"
          >
            <IconComp size={18} className="shrink-0" />
            <span className="truncate">{downloadInfo.label}</span>
          </a>
        ) : (
          <Link
            href="/docs"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-2xl transition-all shadow-[0_0_30px_rgba(255,136,0,0.25)] hover:shadow-[0_0_40px_rgba(255,136,0,0.4)] hover:-translate-y-0.5"
          >
            <IconComp size={18} className="shrink-0" />
            <span className="truncate">{downloadInfo.label}</span>
          </Link>
        )}

        <Link
          href="/docs"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2.5 bg-[#1b1b1f] hover:bg-[#222227] text-[#f3f3f6] border border-[#28282d] hover:border-[#ff8800] font-bold text-sm sm:text-base px-6 sm:px-7 py-3.5 rounded-2xl transition-all hover:-translate-y-0.5 shadow-[0_0_15px_rgba(0,0,0,0.3)] hover:shadow-[0_0_20px_rgba(255,136,0,0.2)]"
        >
          <BookOpen size={18} className="text-[#ff8800] shrink-0" />
          <span>Dokumentáció</span>
        </Link>

        <a
          href="https://github.com/CsPS0/pala"
          target="_blank"
          rel="noopener noreferrer"
          className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#151518] hover:bg-[#1b1b1f] text-[#8c8c94] hover:text-[#f3f3f6] border border-[#28282d] hover:border-[#8c8c94] font-bold text-sm sm:text-base px-5 sm:px-6 py-3.5 rounded-2xl transition-all hover:-translate-y-0.5"
        >
          <span>GitHub</span>
          <ArrowRight size={16} />
        </a>
      </div>

      {/* Platform Detection & Version Info */}
      <div className="flex flex-wrap items-center justify-center gap-2 text-[11px] sm:text-xs text-[#5f5f67] mb-8 sm:mb-10 px-2">
        <div className="flex items-center gap-1.5 text-[#8c8c94]">
          <IconComp size={14} className="text-[#ff8800] shrink-0" />
          <span>Felismerve: {config.name} ({config.badgeText})</span>
        </div>
        <span>•</span>
        <span>
          Legfrissebb kiadás:{" "}
          <strong className="text-[#8c8c94]">
            {release.isLoading ? "..." : release.version}
          </strong>
        </span>
        {release.formattedDate && <span>({release.formattedDate})</span>}
      </div>

      {/* Form Factor Preview Switcher Pills */}
      <div
        role="tablist"
        aria-label="Előnézet típus kiválasztása"
        className="flex items-center justify-center gap-1.5 sm:gap-2 mb-6 p-1.5 rounded-2xl bg-[#151518] border border-[#28282d] max-w-full overflow-x-auto no-scrollbar"
      >
        <button
          role="tab"
          id="tab-desktop"
          aria-selected={previewMode === "desktop"}
          aria-controls="panel-desktop"
          onClick={() => setPreviewMode("desktop")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            previewMode === "desktop"
              ? "bg-[#ff8800] text-black shadow-[0_0_15px_rgba(255,136,0,0.25)]"
              : "text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#222227]"
          }`}
        >
          <Monitor size={15} />
          <span>Asztali & Web</span>
        </button>

        <button
          role="tab"
          id="tab-mobile"
          aria-selected={previewMode === "mobile"}
          aria-controls="panel-mobile"
          onClick={() => setPreviewMode("mobile")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            previewMode === "mobile"
              ? "bg-[#ff8800] text-black shadow-[0_0_15px_rgba(255,136,0,0.25)]"
              : "text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#222227]"
          }`}
        >
          <Smartphone size={15} />
          <span>Mobil (Telefon)</span>
        </button>

        <button
          role="tab"
          id="tab-tui"
          aria-selected={previewMode === "tui"}
          aria-controls="panel-tui"
          onClick={() => setPreviewMode("tui")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
            previewMode === "tui"
              ? "bg-[#ff8800] text-black shadow-[0_0_15px_rgba(255,136,0,0.25)]"
              : "text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#222227]"
          }`}
        >
          <Terminal size={15} />
          <span>Terminál (TUI)</span>
        </button>
      </div>

      {/* ================= PREVIEW 1: DESKTOP & WEB ================= */}
      {previewMode === "desktop" && (
        <div
          id="panel-desktop"
          role="tabpanel"
          aria-labelledby="tab-desktop"
          aria-live="polite"
          className="w-full rounded-2xl sm:rounded-3xl border border-[#28282d] bg-[#151518] shadow-2xl overflow-hidden text-left max-w-full animate-fadeIn"
        >
          {/* Desktop & Web Window Bar */}
          <div className="h-10 sm:h-11 bg-[#151518] border-b border-[#28282d] flex items-center justify-between px-3 sm:px-4 min-w-0">
            <div className="flex items-center gap-2 min-w-0 flex-1">
              <div className="flex items-center gap-1.5 shrink-0">
                <div className="w-2.5 sm:w-3 h-2.5 sm:h-3 rounded-full bg-[#ff453a]" />
                <div className="w-2.5 sm:w-3 h-2.5 sm:h-3 rounded-full bg-[#ffd60a]" />
                <div className="w-2.5 sm:w-3 h-2.5 sm:h-3 rounded-full bg-[#30d158]" />
              </div>
              <span className="ml-2 sm:ml-3 text-[11px] sm:text-xs font-bold text-[#8c8c94] truncate">
                Pala Desktop & Web — Élő Kréta Állapot
              </span>
            </div>
            <span className="hidden sm:inline-block text-[11px] font-bold text-[#30d158] bg-[#30d158]/10 border border-[#30d158]/30 px-2 py-0.5 rounded-full shrink-0">
              Online & Szinkronizálva
            </span>
          </div>

          <div className="p-4 sm:p-6 grid grid-cols-1 md:grid-cols-4 gap-4 sm:gap-5 bg-[#0e0e11]">
            {/* Sidebar */}
            <div className="hidden md:flex flex-col gap-1.5 bg-[#151518] border border-[#28282d] p-3 rounded-2xl">
              <div className="text-xs font-bold text-[#ff8800] bg-[#ff8800]/10 px-3 py-2 rounded-xl border border-[#ff8800]/30">
                Vezérlőpult
              </div>
              <div className="text-xs font-semibold text-[#8c8c94] px-3 py-2 hover:text-white transition-colors">
                Érdemjegyek & Átlag
              </div>
              <div className="text-xs font-semibold text-[#8c8c94] px-3 py-2 hover:text-white transition-colors">
                Órarend (Heti nézet)
              </div>
              <div className="text-xs font-semibold text-[#8c8c94] px-3 py-2 hover:text-white transition-colors">
                Feladatok & Dolgozatok
              </div>
              <div className="text-xs font-semibold text-[#8c8c94] px-3 py-2 hover:text-white transition-colors">
                Tanári Üzenetek
              </div>
            </div>

            {/* Main Board */}
            <div className="md:col-span-3 flex flex-col gap-3 sm:gap-4 min-w-0">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 sm:p-4 rounded-2xl">
                  <div className="text-[11px] font-semibold text-[#8c8c94]">Tanulmányi Átlag</div>
                  <div className="text-xl sm:text-2xl font-black text-[#ff8800] mt-1">4.85</div>
                  <div className="text-[10px] text-[#30d158] mt-1 font-semibold">+0.12 múlt héthez képest</div>
                </div>
                <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 sm:p-4 rounded-2xl">
                  <div className="text-[11px] font-semibold text-[#8c8c94]">Mai Órák Száma</div>
                  <div className="text-xl sm:text-2xl font-black text-[#f3f3f6] mt-1">6 óra</div>
                  <div className="text-[10px] text-[#8c8c94] mt-1">3 befejezve • 3 hátra</div>
                </div>
                <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 sm:p-4 rounded-2xl">
                  <div className="text-[11px] font-semibold text-[#8c8c94]">Szülői Igazolás</div>
                  <div className="text-xl sm:text-2xl font-black text-[#30d158] mt-1">2 / 3 nap</div>
                  <div className="text-[10px] text-[#8c8c94] mt-1">1 nap maradt</div>
                </div>
              </div>

              <div className="bg-gradient-to-r from-[#ff8800]/15 to-[#ff8800]/5 border border-[#ff8800]/30 p-4 sm:p-5 rounded-2xl flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                <div className="min-w-0">
                  <div className="text-[10px] font-black tracking-widest text-[#ff8800]">FOLYAMATBAN LÉVŐ TANÓRA</div>
                  <div className="text-base sm:text-lg font-black text-[#f3f3f6] mt-0.5 truncate">Matematika • Terem: 204 (Kovács Péter)</div>
                  <div className="text-xs text-[#8c8c94] mt-1">Hátra van: 18 perc • 4. tanóra (10:00 - 10:45)</div>
                </div>
                <div className="shrink-0">
                  <span className="text-xs font-bold text-[#ff8800] bg-[#ff8800]/10 border border-[#ff8800]/30 px-3 py-1.5 rounded-xl block">
                    Dolgozat csütörtökön
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ================= PREVIEW 2: PHONE / MOBILE APP ================= */}
      {previewMode === "mobile" && (
        <div
          id="panel-mobile"
          role="tabpanel"
          aria-labelledby="tab-mobile"
          aria-live="polite"
          className="w-full flex justify-center animate-fadeIn py-2"
        >
          {/* Smartphone Frame */}
          <div className="w-full max-w-[310px] sm:max-w-[350px] bg-[#111114] border-[3px] sm:border-[4px] border-[#28282d] rounded-[32px] sm:rounded-[38px] shadow-2xl p-3.5 sm:p-4 overflow-hidden text-left relative">
            {/* Dynamic Island / Notch */}
            <div className="w-24 h-4 bg-black rounded-full mx-auto mb-2 flex items-center justify-end px-2">
              <div className="w-2 h-2 rounded-full bg-[#1b1b1f]" />
            </div>

            {/* Mobile Status Bar */}
            <div className="flex items-center justify-between text-[11px] font-bold text-[#8c8c94] px-2 mb-3">
              <span>10:42</span>
              <div className="flex items-center gap-1.5 text-[10px]">
                <span>5G</span>
                <span>•</span>
                <span className="text-[#30d158]">92%</span>
              </div>
            </div>

            {/* Mobile App Header */}
            <div className="flex items-center justify-between px-2 mb-4">
              <div className="flex items-center gap-2">
                <img src="/logo.svg" alt="Pala" width={28} height={28} className="w-7 h-7 rounded-lg" />
                <div>
                  <div className="text-xs font-black text-[#f3f3f6]">Pala Mobile</div>
                  <div className="text-[10px] text-[#30d158] font-semibold">Online • Kréta</div>
                </div>
              </div>
              <span className="text-[10px] font-bold bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 px-2 py-0.5 rounded-full">
                4.85 Átlag
              </span>
            </div>

            {/* Ongoing Class Card */}
            <div className="bg-gradient-to-br from-[#ff8800]/20 to-[#ff8800]/5 border border-[#ff8800]/40 p-3.5 rounded-2xl mb-3 space-y-1.5">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-black text-[#ff8800] uppercase tracking-wider">Most zajlik (4. óra)</span>
                <span className="text-[10px] font-bold text-[#ff8800] bg-[#ff8800]/10 px-1.5 py-0.2 rounded">18p hátra</span>
              </div>
              <div className="text-sm font-black text-[#f3f3f6]">Matematika</div>
              <div className="text-[11px] text-[#8c8c94]">Terem: 204 • Kovács Péter</div>
              {/* Progress bar */}
              <div className="w-full bg-[#1b1b1f] h-1.5 rounded-full overflow-hidden mt-2">
                <div className="bg-[#ff8800] h-full w-[60%] rounded-full" />
              </div>
            </div>

            {/* 3 Mobile Metric Pills */}
            <div className="grid grid-cols-3 gap-2 mb-3 text-center">
              <div className="p-2 rounded-xl bg-[#1b1b1f] border border-[#28282d]">
                <div className="text-[9px] text-[#8c8c94]">Mai Órák</div>
                <div className="text-xs font-bold text-[#f3f3f6]">6 óra</div>
              </div>
              <div className="p-2 rounded-xl bg-[#1b1b1f] border border-[#28282d]">
                <div className="text-[9px] text-[#8c8c94]">Igazolatlan</div>
                <div className="text-xs font-bold text-[#30d158]">0 óra</div>
              </div>
              <div className="p-2 rounded-xl bg-[#1b1b1f] border border-[#28282d]">
                <div className="text-[9px] text-[#8c8c94]">Szülői</div>
                <div className="text-xs font-bold text-[#ff8800]">2 / 3 nap</div>
              </div>
            </div>

            {/* Recent Grades List */}
            <div className="space-y-1.5 mb-4">
              <div className="text-[10px] font-bold text-[#8c8c94] px-1">Legfrissebb Jegyek</div>
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                <div>
                  <div className="text-xs font-bold text-[#f3f3f6]">Matematika</div>
                  <div className="text-[10px] text-[#8c8c94]">Témazáró dolgozat • ma</div>
                </div>
                <div className="w-7 h-7 rounded-lg bg-[#30d158]/15 border border-[#30d158]/30 text-[#30d158] font-black text-sm flex items-center justify-center">
                  5
                </div>
              </div>

              <div className="flex items-center justify-between p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                <div>
                  <div className="text-xs font-bold text-[#f3f3f6]">Történelem</div>
                  <div className="text-[10px] text-[#8c8c94]">Szóbeli felelet • tegnap</div>
                </div>
                <div className="w-7 h-7 rounded-lg bg-[#30d158]/15 border border-[#30d158]/30 text-[#30d158] font-black text-sm flex items-center justify-center">
                  5
                </div>
              </div>
            </div>

            {/* Mobile Bottom Navigation Bar */}
            <div className="pt-2 border-t border-[#28282d] flex items-center justify-around text-[10px] font-bold text-[#8c8c94]">
              <span className="text-[#ff8800]">Kezdőlap</span>
              <span>Órarend</span>
              <span>Jegyek</span>
              <span>Üzenetek</span>
            </div>

            {/* Home Indicator Bar */}
            <div className="w-28 h-1 bg-[#5f5f67] rounded-full mx-auto mt-2.5" />
          </div>
        </div>
      )}

      {/* ================= PREVIEW 3: TERMINAL (TUI) ================= */}
      {previewMode === "tui" && (
        <div
          id="panel-tui"
          role="tabpanel"
          aria-labelledby="tab-tui"
          aria-live="polite"
          className="w-full rounded-2xl sm:rounded-3xl border border-[#28282d] bg-[#0c0c0e] shadow-2xl overflow-hidden text-left max-w-full font-mono animate-fadeIn"
        >
          {/* Terminal Titlebar */}
          <div className="h-10 bg-[#151518] border-b border-[#28282d] flex items-center justify-between px-3 sm:px-4">
            <div className="flex items-center gap-2">
              <LinuxIcon size={14} />
              <span className="text-xs text-[#8c8c94]">pala@terminal: ~ (TUI Kliens)</span>
            </div>
            <div className="flex items-center gap-1.5 text-[10px] text-[#5f5f67]">
              <span>_</span>
              <span>□</span>
              <span>✕</span>
            </div>
          </div>

          <div className="p-4 sm:p-6 text-xs text-[#f3f3f6] space-y-2 overflow-x-auto">
            <div className="text-[#8c8c94]">$ pala --tui</div>
            <div className="text-[#ff8800] font-bold">┌── PALA KRÉTA KLIENS {release.version} ────────────────────────┐</div>
            <div>│ <span className="text-[#30d158] font-bold">[1] Órarend</span>  <span className="text-[#0a84ff]">[2] Jegyek</span>  <span className="text-[#ffd60a]">[3] Átlag</span>  <span className="text-[#ff8800]">[4] Üzenetek</span>  [q] Kilépés │</div>
            <div className="text-[#ff8800] font-bold">├── MAI ÓRAREND (KEDD) ───────────────────────────────┤</div>
            <div>│ 10:00 - 10:45 <strong className="text-[#30d158]">[4. óra] Matematika</strong> (Terem: 204)       │</div>
            <div>│ Tanár: Kovács Péter • <span className="text-[#ffd60a]">Hátra van: 18 perc</span>            │</div>
            <div className="text-[#ff8800] font-bold">├── TANULMÁNYI ÁLLAPOT ────────────────────────────────┤</div>
            <div>│ Tanulmányi átlag: <strong className="text-[#30d158]">4.85</strong> [<span className="text-[#30d158]">████████████████░░░░</span>] 97%       │</div>
            <div>│ Mai órák: 6/6 elérhető • Igazolatlan hiányzás: 0 óra │</div>
            <div className="text-[#ff8800] font-bold">└─────────────────────────────────────────────────────┘</div>
          </div>
        </div>
      )}
    </section>
  );
}
