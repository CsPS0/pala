"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import {
  Download,
  ArrowRight,
  BookOpen,
  Monitor,
  Smartphone,
  Terminal,
  Search,
  RefreshCw,
  LogOut,
  Sparkles,
  School,
  Calendar,
  ClipboardList,
  CheckCircle2,
  Clock,
  MapPin,
  User,
  LayoutDashboard,
  TrendingUp,
  Calculator,
  ShieldAlert,
  AlertCircle,
  BarChart3,
  Check,
} from "lucide-react";
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
  const [desktopTab, setDesktopTab] = useState<"dashboard" | "grades" | "timetable" | "absences">("dashboard");
  const release = useRelease();

  useEffect(() => {
    const os = detectClientOS();
    // Deliberately set state after mount: detectClientOS() reads navigator/
    // window, which don't exist during this statically-exported page's SSR
    // pass. Computing it during render would make the client's first paint
    // disagree with the server-rendered HTML and break hydration.
    // eslint-disable-next-line react-hooks/set-state-in-effect
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
    <section id="hero" className="pt-6 sm:pt-10 pb-12 px-4 sm:px-6 text-center max-w-5xl mx-auto flex flex-col items-center w-full overflow-hidden">
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
                Pala Desktop & Web — Teszt Elek (Pala Minta Gimnázium)
              </span>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <span className="inline-flex items-center gap-1.5 text-[10px] sm:text-[11px] font-bold text-[#30d158] bg-[#30d158]/10 border border-[#30d158]/30 px-2 py-0.5 rounded-full">
                <span className="w-1.5 h-1.5 rounded-full bg-[#30d158] animate-pulse" />
                Online & Szinkronizálva
              </span>
            </div>
          </div>

          <div className="flex flex-col md:flex-row bg-[#0e0e11] min-h-[480px]">
            {/* Real Desktop Sidebar */}
            <aside aria-label="Desktop navigáció" className="hidden md:flex flex-col w-56 shrink-0 bg-[#151518] border-r border-[#28282d] p-3 justify-between">
              <div className="space-y-3">
                {/* Brand row */}
                <div className="flex items-center gap-2 px-2 py-1">
                  <span className="bg-[#ff8800] text-black text-[11px] font-black px-1.5 py-0.5 rounded tracking-wider">
                    PALA
                  </span>
                  <span className="text-xs font-extrabold tracking-widest text-white">
                    DESKTOP
                  </span>
                </div>

                {/* Profile Card */}
                <div className="bg-[#1b1b1f] border border-[#28282d] rounded-xl p-2.5 flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-full bg-[#ff8800]/20 text-[#ff8800] font-black text-xs flex items-center justify-center shrink-0 border border-[#ff8800]/30">
                    T
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="text-xs font-bold text-white truncate">Teszt Elek</div>
                    <div className="text-[10px] text-[#8c8c94] truncate">Pala Minta Gimnázium</div>
                  </div>
                </div>

                {/* Nav Items */}
                <nav className="space-y-1">
                  <button
                    type="button"
                    onClick={() => setDesktopTab("dashboard")}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-bold transition-all text-left cursor-pointer ${
                      desktopTab === "dashboard"
                        ? "bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 shadow-sm"
                        : "text-[#8c8c94] hover:text-white hover:bg-[#222227] border border-transparent"
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <LayoutDashboard size={15} />
                      <span>Vezérlőpult</span>
                    </div>
                    {desktopTab === "dashboard" && <span className="w-1.5 h-1.5 rounded-full bg-[#ff8800]" />}
                  </button>

                  <button
                    type="button"
                    onClick={() => setDesktopTab("grades")}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-bold transition-all text-left cursor-pointer ${
                      desktopTab === "grades"
                        ? "bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 shadow-sm"
                        : "text-[#8c8c94] hover:text-white hover:bg-[#222227] border border-transparent"
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <School size={15} />
                      <span>Érdemjegyek</span>
                    </div>
                    {desktopTab === "grades" && <span className="w-1.5 h-1.5 rounded-full bg-[#ff8800]" />}
                  </button>

                  <button
                    type="button"
                    onClick={() => setDesktopTab("timetable")}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-bold transition-all text-left cursor-pointer ${
                      desktopTab === "timetable"
                        ? "bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 shadow-sm"
                        : "text-[#8c8c94] hover:text-white hover:bg-[#222227] border border-transparent"
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <Calendar size={15} />
                      <span>Órarend</span>
                    </div>
                    {desktopTab === "timetable" && <span className="w-1.5 h-1.5 rounded-full bg-[#ff8800]" />}
                  </button>

                  <div className="flex items-center gap-2.5 px-3 py-2 rounded-lg text-[#5f5f67] text-xs font-medium cursor-default">
                    <ClipboardList size={15} />
                    <span>Feladatok & Üzenetek</span>
                  </div>

                  <button
                    type="button"
                    onClick={() => setDesktopTab("absences")}
                    className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-xs font-bold transition-all text-left cursor-pointer ${
                      desktopTab === "absences"
                        ? "bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 shadow-sm"
                        : "text-[#8c8c94] hover:text-white hover:bg-[#222227] border border-transparent"
                    }`}
                  >
                    <div className="flex items-center gap-2.5">
                      <Clock size={15} />
                      <span>Mulasztások</span>
                    </div>
                    {desktopTab === "absences" && <span className="w-1.5 h-1.5 rounded-full bg-[#ff8800]" />}
                  </button>

                  <div className="flex items-center gap-2.5 px-3 py-2 rounded-lg text-[#5f5f67] text-xs font-medium cursor-default">
                    <TrendingUp size={15} />
                    <span>Statisztikák</span>
                  </div>
                </nav>
              </div>

              {/* Sidebar Footer */}
              <div className="pt-3 border-t border-[#28282d] space-y-1.5">
                <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg bg-[#ff8800]/10 border border-[#ff8800]/30 text-[#ff8800] text-[11px] font-bold">
                  <Sparkles size={14} />
                  <span>Pala Wrapped 2025</span>
                </div>
                <div className="flex items-center gap-2 px-2.5 py-1.5 rounded-lg text-[#ff453a] hover:bg-[#ff453a]/10 text-[11px] font-semibold transition-colors">
                  <LogOut size={14} />
                  <span>Kijelentkezés</span>
                </div>
              </div>
            </aside>

            {/* Real Desktop Main Column */}
            <div className="flex-1 flex flex-col min-w-0">
              {/* Mobile Subnav for screens without sidebar */}
              <div className="flex md:hidden items-center gap-1.5 p-2 bg-[#151518] border-b border-[#28282d] overflow-x-auto no-scrollbar">
                <button
                  type="button"
                  onClick={() => setDesktopTab("dashboard")}
                  className={`px-3 py-1 rounded-lg text-xs font-bold whitespace-nowrap cursor-pointer transition-colors ${
                    desktopTab === "dashboard" ? "bg-[#ff8800] text-black" : "text-[#8c8c94] bg-[#1b1b1f]"
                  }`}
                >
                  Vezérlőpult
                </button>
                <button
                  type="button"
                  onClick={() => setDesktopTab("grades")}
                  className={`px-3 py-1 rounded-lg text-xs font-bold whitespace-nowrap cursor-pointer transition-colors ${
                    desktopTab === "grades" ? "bg-[#ff8800] text-black" : "text-[#8c8c94] bg-[#1b1b1f]"
                  }`}
                >
                  Érdemjegyek
                </button>
                <button
                  type="button"
                  onClick={() => setDesktopTab("timetable")}
                  className={`px-3 py-1 rounded-lg text-xs font-bold whitespace-nowrap cursor-pointer transition-colors ${
                    desktopTab === "timetable" ? "bg-[#ff8800] text-black" : "text-[#8c8c94] bg-[#1b1b1f]"
                  }`}
                >
                  Órarend
                </button>
                <button
                  type="button"
                  onClick={() => setDesktopTab("absences")}
                  className={`px-3 py-1 rounded-lg text-xs font-bold whitespace-nowrap cursor-pointer transition-colors ${
                    desktopTab === "absences" ? "bg-[#ff8800] text-black" : "text-[#8c8c94] bg-[#1b1b1f]"
                  }`}
                >
                  Mulasztások
                </button>
              </div>

              {/* Header Bar */}
              <div className="h-14 px-4 sm:px-6 bg-[#151518] border-b border-[#28282d] flex items-center justify-between">
                <div>
                  <h2 className="text-sm font-extrabold text-white">
                    {desktopTab === "dashboard" && "Vezérlőpult"}
                    {desktopTab === "grades" && "Érdemjegyek & Átlagok"}
                    {desktopTab === "timetable" && "Órarend & Tanórák"}
                    {desktopTab === "absences" && "Mulasztások & Határok"}
                  </h2>
                  <p className="text-[11px] text-[#8c8c94]">
                    {desktopTab === "dashboard" && "Aktuális órák, határidők és gyors műveletek"}
                    {desktopTab === "grades" && "Tantárgyi átlagok, súlyozott jegyek és célátlag kalkulátor"}
                    {desktopTab === "timetable" && "2026. szeptember 13., kedd (B hét) — 6 tanóra"}
                    {desktopTab === "absences" && "250 órás törvényi határ és szülői igazolás keretfigyelő"}
                  </p>
                </div>
                <div className="flex items-center gap-3">
                  <div className="hidden sm:flex flex-col text-right">
                    <span className="text-xs font-bold text-white tabular-nums">10:42:15</span>
                    <span className="text-[10px] text-[#8c8c94]">2026. szeptember 13., kedd</span>
                  </div>
                  <div className="hidden lg:flex items-center gap-1.5 bg-[#1b1b1f] border border-[#28282d] px-2 py-1 rounded-lg text-[11px] text-[#8c8c94]">
                    <Search size={12} />
                    <span>Keresés</span>
                    <kbd className="bg-[#28282d] px-1 py-0.2 rounded text-[9px] text-[#f3f3f6]">Ctrl + K</kbd>
                  </div>
                  <div className="w-8 h-8 rounded-lg bg-[#1b1b1f] border border-[#28282d] flex items-center justify-center text-[#8c8c94]">
                    <RefreshCw size={14} />
                  </div>
                </div>
              </div>

              {/* View 1: Main Dashboard Grid */}
              {desktopTab === "dashboard" && (
                <div className="p-4 sm:p-5 grid grid-cols-1 lg:grid-cols-2 gap-4 animate-fadeIn">
                  {/* Left Column: Countdown & Today's Schedule */}
                  <div className="space-y-4">
                    {/* Countdown Card */}
                    <div className="bg-gradient-to-br from-[#ff8800]/20 via-[#ff8800]/5 to-transparent border border-[#ff8800]/40 p-4 rounded-2xl">
                      <div className="flex items-center justify-between mb-2">
                        <span className="bg-[#ff8800] text-black text-[10px] font-black px-2 py-0.5 rounded tracking-wide">
                          FOLYAMATBAN
                        </span>
                        <span className="text-[11px] text-[#8c8c94] flex items-center gap-1">
                          <MapPin size={12} />
                          Terem: 204 (Kovács Péter)
                        </span>
                      </div>
                      <div className="text-xl font-black text-[#ff8800]">Matematika</div>
                      <div className="text-xs text-[#8c8c94] mt-0.5">
                        Hátra van még: <strong className="text-white font-bold">18 perc</strong> (4. tanóra • 10:00 - 10:45)
                      </div>
                      {/* Progress Bar */}
                      <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden mt-3">
                        <div className="bg-[#ff8800] h-full w-[60%] rounded-full shadow-[0_0_8px_rgba(255,136,0,0.6)]" />
                      </div>
                    </div>

                    {/* Mai Órarend Section */}
                    <div className="bg-[#1b1b1f] border border-[#28282d] rounded-2xl p-4">
                      <div className="flex items-center justify-between mb-3">
                        <span className="text-xs font-bold text-white">Mai Órarend</span>
                        <span className="text-[10px] text-[#8c8c94]">6 óra • Kedd</span>
                      </div>
                      <div className="space-y-1.5 text-xs">
                        {/* Past lesson 1 */}
                        <div className="flex items-center justify-between p-2 rounded-lg bg-[#151518] border border-[#28282d] opacity-60">
                          <div className="flex items-center gap-2.5">
                            <span className="w-5 h-5 rounded bg-white/5 flex items-center justify-center font-bold text-[10px] text-white">1</span>
                            <div>
                              <span className="font-semibold text-white">Magyar nyelv és irodalom</span>
                              <span className="block text-[10px] text-[#8c8c94]">08:00 - 08:45 • Terem: 102</span>
                            </div>
                          </div>
                          <CheckCircle2 size={14} className="text-[#30d158]" />
                        </div>

                        {/* Past lesson 2 */}
                        <div className="flex items-center justify-between p-2 rounded-lg bg-[#151518] border border-[#28282d] opacity-60">
                          <div className="flex items-center gap-2.5">
                            <span className="w-5 h-5 rounded bg-white/5 flex items-center justify-center font-bold text-[10px] text-white">2</span>
                            <div>
                              <span className="font-semibold text-white">Történelem</span>
                              <span className="block text-[10px] text-[#8c8c94]">09:00 - 09:45 • Terem: 208</span>
                            </div>
                          </div>
                          <CheckCircle2 size={14} className="text-[#30d158]" />
                        </div>

                        {/* Active lesson 3 */}
                        <div className="flex items-center justify-between p-2 rounded-lg bg-[#ff8800]/10 border border-[#ff8800]/40">
                          <div className="flex items-center gap-2.5">
                            <span className="w-5 h-5 rounded bg-[#ff8800] flex items-center justify-center font-black text-[10px] text-black">3</span>
                            <div>
                              <span className="font-bold text-white">Matematika</span>
                              <span className="block text-[10px] text-[#ff8800]">10:00 - 10:45 • Terem: 204</span>
                            </div>
                          </div>
                          <span className="text-[9px] font-extrabold text-[#ff8800] bg-[#ff8800]/20 px-1.5 py-0.5 rounded">
                            Folyamatban
                          </span>
                        </div>

                        {/* Upcoming lesson 4 */}
                        <div className="flex items-center justify-between p-2 rounded-lg bg-[#151518] border border-[#28282d]">
                          <div className="flex items-center gap-2.5">
                            <span className="w-5 h-5 rounded bg-white/5 flex items-center justify-center font-bold text-[10px] text-white">4</span>
                            <div>
                              <span className="font-semibold text-white">Angol nyelv</span>
                              <span className="block text-[10px] text-[#8c8c94]">11:00 - 11:45 • Terem: 310</span>
                            </div>
                          </div>
                          <span className="text-[10px] text-[#8c8c94]">Következő</span>
                        </div>

                        {/* Upcoming lesson 5 (Substitute) */}
                        <div className="flex items-center justify-between p-2 rounded-lg bg-[#151518] border border-[#ffd60a]/30">
                          <div className="flex items-center gap-2.5">
                            <span className="w-5 h-5 rounded bg-white/5 flex items-center justify-center font-bold text-[10px] text-white">5</span>
                            <div>
                              <span className="font-semibold text-white">Biológia</span>
                              <span className="block text-[10px] text-[#ffd60a]">12:00 - 12:45 • Helyettesítés (Nagy Éva)</span>
                            </div>
                          </div>
                          <span className="text-[9px] font-bold text-[#ffd60a] bg-[#ffd60a]/10 px-1.5 py-0.5 rounded">
                            Helyettesítés
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Right Column: Quick Actions + Metrics Grid + Recent Activity */}
                  <div className="space-y-4">
                    {/* Quick Action Pills */}
                    <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs font-semibold">
                      <button
                        type="button"
                        onClick={() => setDesktopTab("absences")}
                        className="flex items-center gap-1.5 bg-[#1b1b1f] hover:bg-[#222227] border border-[#28282d] px-3 py-1.5 rounded-xl text-[#f3f3f6] shrink-0 cursor-pointer transition-colors"
                      >
                        <Clock size={13} className="text-[#ff453a]" />
                        <span>Hiányzások</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setDesktopTab("grades")}
                        className="flex items-center gap-1.5 bg-[#1b1b1f] hover:bg-[#222227] border border-[#28282d] px-3 py-1.5 rounded-xl text-[#f3f3f6] shrink-0 cursor-pointer transition-colors"
                      >
                        <School size={13} className="text-[#ff8800]" />
                        <span>Érdemjegyek</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => setDesktopTab("timetable")}
                        className="flex items-center gap-1.5 bg-[#1b1b1f] hover:bg-[#222227] border border-[#28282d] px-3 py-1.5 rounded-xl text-[#f3f3f6] shrink-0 cursor-pointer transition-colors"
                      >
                        <Calendar size={13} className="text-[#0a84ff]" />
                        <span>Órarend</span>
                      </button>
                    </div>

                    {/* 2x2 Metrics Grid */}
                    <div className="grid grid-cols-2 gap-3">
                      <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 rounded-2xl">
                        <div className="text-[11px] font-semibold text-[#8c8c94]">Tanulmányi Átlag</div>
                        <div className="text-2xl font-black text-[#30d158] mt-0.5">4.85</div>
                        <div className="text-[10px] text-[#30d158] mt-1 font-semibold">32 rögzített jegy</div>
                      </div>
                      <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 rounded-2xl">
                        <div className="text-[11px] font-semibold text-[#8c8c94]">Mai Órák</div>
                        <div className="text-2xl font-black text-white mt-0.5">6</div>
                        <div className="text-[10px] text-[#8c8c94] mt-1">3 hátralévő óra</div>
                      </div>
                      <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 rounded-2xl">
                        <div className="text-[11px] font-semibold text-[#8c8c94]">Szülői Keret</div>
                        <div className="text-2xl font-black text-[#ffd60a] mt-0.5">2 / 3</div>
                        <div className="text-[10px] text-[#8c8c94] mt-1">1 nap maradt</div>
                      </div>
                      <div className="bg-[#1b1b1f] border border-[#28282d] p-3.5 rounded-2xl">
                        <div className="text-[11px] font-semibold text-[#8c8c94]">Közelgő Dolgozatok</div>
                        <div className="text-2xl font-black text-[#ff8800] mt-0.5">2</div>
                        <div className="text-[10px] text-[#8c8c94] mt-1">bejelentett számonkérés</div>
                      </div>
                    </div>

                    {/* Upcoming & Recent Activity */}
                    <div className="bg-[#1b1b1f] border border-[#28282d] rounded-2xl p-4">
                      <div className="text-xs font-bold text-white mb-2.5">
                        Közelgő Dolgozatok & Legutóbbi Jegyek
                      </div>
                      <div className="space-y-2">
                        {/* Exam item */}
                        <div className="flex items-center justify-between text-xs pb-2 border-b border-[#28282d]">
                          <div className="truncate pr-2">
                            <span className="font-bold text-white">Témazáró dolgozat</span>
                            <span className="text-[#8c8c94] block text-[10px]">Matematika • Terem: 204</span>
                          </div>
                          <span className="text-[11px] font-extrabold text-[#ff8800] bg-[#ff8800]/10 border border-[#ff8800]/30 px-2 py-0.5 rounded-md shrink-0">
                            10.15.
                          </span>
                        </div>

                        {/* Grade item 1 */}
                        <div className="flex items-center justify-between text-xs">
                          <div className="truncate pr-2">
                            <span className="font-semibold text-white">Matematika: Függvények témazáró (200%)</span>
                            <span className="text-[#8c8c94] block text-[10px]">Ma, 10:15 • Kovács Péter</span>
                          </div>
                          <div className="w-6 h-6 rounded bg-[#30d158]/15 border border-[#30d158]/30 text-[#30d158] font-black text-xs flex items-center justify-center shrink-0">
                            5
                          </div>
                        </div>

                        {/* Grade item 2 */}
                        <div className="flex items-center justify-between text-xs">
                          <div className="truncate pr-2">
                            <span className="font-semibold text-white">Történelem: Szóbeli felelet</span>
                            <span className="text-[#8c8c94] block text-[10px]">Tegnap, 09:30 • Szabó István</span>
                          </div>
                          <div className="w-6 h-6 rounded bg-[#30d158]/15 border border-[#30d158]/30 text-[#30d158] font-black text-xs flex items-center justify-center shrink-0">
                            5
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* View 2: Detailed Grades Panel */}
              {desktopTab === "grades" && (
                <div className="p-4 sm:p-5 space-y-4 animate-fadeIn">
                  {/* Target Average Calculator Preview Card */}
                  <div className="bg-gradient-to-r from-[#ff8800]/15 via-[#1b1b1f] to-[#1b1b1f] border border-[#ff8800]/30 p-4 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <Calculator size={16} className="text-[#ff8800]" />
                        <span className="text-xs font-black text-white uppercase tracking-wider">Célátlag & Szellemjegy Kalkulátor</span>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        Jelenlegi tanulmányi átlag: <strong className="text-white">4.85</strong> (32 jegy alapján)
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="bg-[#151518] border border-[#28282d] px-3 py-1.5 rounded-xl text-center">
                        <div className="text-[10px] text-[#8c8c94]">Következő jegy 5-ös (200%)</div>
                        <div className="text-xs font-black text-[#30d158]">4.88 (+0.03)</div>
                      </div>
                      <div className="bg-[#151518] border border-[#28282d] px-3 py-1.5 rounded-xl text-center">
                        <div className="text-[10px] text-[#8c8c94]">Következő jegy 4-es (100%)</div>
                        <div className="text-xs font-black text-[#ffd60a]">4.82 (-0.03)</div>
                      </div>
                    </div>
                  </div>

                  {/* Subject List Grid */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {[
                      { subject: "Matematika", avg: "4.80", teacher: "Kovács Péter", grades: [{ val: "5", weight: "200%" }, { val: "5", weight: "100%" }, { val: "4", weight: "100%" }, { val: "5", weight: "100%" }] },
                      { subject: "Angol nyelv", avg: "5.00", teacher: "Kiss Gábor", grades: [{ val: "5", weight: "100%" }, { val: "5", weight: "100%" }, { val: "5", weight: "200%" }] },
                      { subject: "Történelem", avg: "4.50", teacher: "Szabó István", grades: [{ val: "5", weight: "100%" }, { val: "4", weight: "100%" }, { val: "4", weight: "200%" }, { val: "5", weight: "100%" }] },
                      { subject: "Biológia", avg: "4.67", teacher: "Molnár Zsolt", grades: [{ val: "5", weight: "100%" }, { val: "5", weight: "100%" }, { val: "4", weight: "100%" }] },
                      { subject: "Fizika", avg: "4.50", teacher: "Varga Tamás", grades: [{ val: "5", weight: "100%" }, { val: "4", weight: "100%" }] },
                      { subject: "Magyar nyelv és irodalom", avg: "5.00", teacher: "Kovácsné Tóth Anna", grades: [{ val: "5", weight: "200%" }, { val: "5", weight: "100%" }] },
                    ].map((item, idx) => (
                      <div key={idx} className="bg-[#1b1b1f] border border-[#28282d] p-3.5 rounded-2xl flex flex-col justify-between gap-2.5">
                        <div className="flex items-center justify-between">
                          <div className="min-w-0 flex-1">
                            <span className="text-xs font-bold text-white block truncate">{item.subject}</span>
                            <span className="text-[10px] text-[#8c8c94]">{item.teacher}</span>
                          </div>
                          <span className={`text-sm font-black px-2.5 py-0.5 rounded-lg border ${
                            Number(item.avg) >= 4.8
                              ? "bg-[#30d158]/15 text-[#30d158] border-[#30d158]/30"
                              : "bg-[#ffd60a]/15 text-[#ffd60a] border-[#ffd60a]/30"
                          }`}>
                            {item.avg}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5 flex-wrap">
                          {item.grades.map((g, gIdx) => (
                            <span key={gIdx} className="inline-flex items-center gap-1 bg-[#151518] border border-[#28282d] px-2 py-0.5 rounded-md text-xs font-bold text-white">
                              <span>{g.val}</span>
                              <span className="text-[9px] text-[#8c8c94]">({g.weight})</span>
                            </span>
                          ))}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* View 3: Timetable Schedule Panel */}
              {desktopTab === "timetable" && (
                <div className="p-4 sm:p-5 space-y-4 animate-fadeIn">
                  {/* Day Pills */}
                  <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs">
                    {["Hétfő", "Kedd (Ma)", "Szerda", "Csütörtök", "Péntek"].map((day, idx) => (
                      <span
                        key={idx}
                        className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap ${
                          idx === 1
                            ? "bg-[#ff8800] text-black shadow-[0_0_12px_rgba(255,136,0,0.3)]"
                            : "bg-[#1b1b1f] text-[#8c8c94] border border-[#28282d]"
                        }`}
                      >
                        {day}
                      </span>
                    ))}
                  </div>

                  {/* Period Schedule List */}
                  <div className="space-y-2">
                    {[
                      { period: "1", time: "08:00 - 08:45", name: "Magyar nyelv és irodalom", room: "102", teacher: "Kovácsné Tóth Anna", status: "Befejezve", statusType: "done" },
                      { period: "2", time: "09:00 - 09:45", name: "Történelem", room: "208", teacher: "Szabó István", status: "Befejezve", statusType: "done" },
                      { period: "3", time: "10:00 - 10:45", name: "Matematika", room: "204", teacher: "Kovács Péter", status: "Folyamatban", statusType: "active" },
                      { period: "4", time: "11:00 - 11:45", name: "Angol nyelv", room: "310", teacher: "Kiss Gábor", status: "Következő", statusType: "next" },
                      { period: "5", time: "12:00 - 12:45", name: "Biológia", room: "114", teacher: "Helyettesítés: Nagy Éva", status: "Helyettesítés", statusType: "substitute" },
                      { period: "6", time: "13:00 - 13:45", name: "Testnevelés és sport", room: "Tornaterem 1", teacher: "Nemes Béla", status: "Következő", statusType: "upcoming" },
                    ].map((lesson, idx) => (
                      <div
                        key={idx}
                        className={`p-3 rounded-xl border flex items-center justify-between text-xs transition-colors ${
                          lesson.statusType === "active"
                            ? "bg-[#ff8800]/10 border-[#ff8800]/40 shadow-sm"
                            : lesson.statusType === "substitute"
                            ? "bg-[#ffd60a]/5 border-[#ffd60a]/30"
                            : lesson.statusType === "done"
                            ? "bg-[#151518] border-[#28282d] opacity-70"
                            : "bg-[#1b1b1f] border-[#28282d]"
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <span className={`w-7 h-7 rounded-lg flex items-center justify-center font-black text-xs ${
                            lesson.statusType === "active"
                              ? "bg-[#ff8800] text-black"
                              : "bg-[#151518] text-white border border-[#28282d]"
                          }`}>
                            {lesson.period}
                          </span>
                          <div>
                            <div className="font-bold text-white flex items-center gap-2">
                              <span>{lesson.name}</span>
                              <span className="text-[10px] text-[#8c8c94] font-normal">({lesson.time})</span>
                            </div>
                            <div className="text-[10px] text-[#8c8c94] flex items-center gap-2 mt-0.5">
                              <span className="flex items-center gap-1"><MapPin size={10} /> Terem: {lesson.room}</span>
                              <span>•</span>
                              <span>{lesson.teacher}</span>
                            </div>
                          </div>
                        </div>
                        <div>
                          {lesson.statusType === "done" && <CheckCircle2 size={16} className="text-[#30d158]" />}
                          {lesson.statusType === "active" && (
                            <span className="text-[10px] font-black bg-[#ff8800] text-black px-2 py-0.5 rounded-md">
                              18 perc hátra
                            </span>
                          )}
                          {lesson.statusType === "substitute" && (
                            <span className="text-[10px] font-bold text-[#ffd60a] bg-[#ffd60a]/10 border border-[#ffd60a]/30 px-2 py-0.5 rounded-md">
                              Helyettesítés
                            </span>
                          )}
                          {(lesson.statusType === "next" || lesson.statusType === "upcoming") && (
                            <span className="text-[10px] text-[#8c8c94]">Órarend szerint</span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* View 4: Absences & 250h Limit Panel */}
              {desktopTab === "absences" && (
                <div className="p-4 sm:p-5 space-y-4 animate-fadeIn">
                  {/* 3 Metric Summary Cards */}
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <div className="bg-[#1b1b1f] border border-[#28282d] p-4 rounded-2xl">
                      <div className="text-[11px] font-semibold text-[#8c8c94]">Összes Hiányzás</div>
                      <div className="text-2xl font-black text-white mt-1">18 óra</div>
                      <div className="text-[10px] text-[#30d158] font-bold mt-1">18 igazolt • 0 igazolatlan</div>
                    </div>
                    <div className="bg-[#1b1b1f] border border-[#28282d] p-4 rounded-2xl">
                      <div className="text-[11px] font-semibold text-[#8c8c94]">250 Órás Limit</div>
                      <div className="text-2xl font-black text-[#30d158] mt-1">7.2%</div>
                      <div className="text-[10px] text-[#8c8c94] mt-1">232 óra maradt a határig</div>
                    </div>
                    <div className="bg-[#1b1b1f] border border-[#28282d] p-4 rounded-2xl">
                      <div className="text-[11px] font-semibold text-[#8c8c94]">Szülői Igazolás Keret</div>
                      <div className="text-2xl font-black text-[#ffd60a] mt-1">2 / 3 nap</div>
                      <div className="text-[10px] text-[#8c8c94] mt-1">1 nap felhasználható</div>
                    </div>
                  </div>

                  {/* 30% Limit Subject Table */}
                  <div className="bg-[#1b1b1f] border border-[#28282d] rounded-2xl p-4 space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-white">Tantárgyi 30%-os Határérték Ellenőrzés</span>
                      <span className="text-[10px] text-[#30d158] font-bold bg-[#30d158]/10 border border-[#30d158]/30 px-2 py-0.5 rounded-full">
                        Minden tantárgy biztonságos
                      </span>
                    </div>

                    <div className="space-y-2 text-xs">
                      {[
                        { subject: "Matematika", total: 120, missed: 3, pct: "2.5%" },
                        { subject: "Angol nyelv", total: 120, missed: 2, pct: "1.6%" },
                        { subject: "Történelem", total: 90, missed: 2, pct: "2.2%" },
                        { subject: "Testnevelés és sport", total: 120, missed: 6, pct: "5.0%" },
                        { subject: "Biológia", total: 60, missed: 2, pct: "3.3%" },
                      ].map((sub, idx) => (
                        <div key={idx} className="flex items-center justify-between p-2.5 rounded-xl bg-[#151518] border border-[#28282d]">
                          <div>
                            <span className="font-bold text-white">{sub.subject}</span>
                            <span className="text-[10px] text-[#8c8c94] block">Éves óraszám: {sub.total} óra • Hiányzás: {sub.missed} óra</span>
                          </div>
                          <div className="text-right">
                            <span className="font-bold text-white">{sub.pct}</span>
                            <span className="text-[10px] text-[#30d158] block font-semibold">Biztonságos (max 30%)</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Legal Info Notice */}
                  <div className="p-3 rounded-xl bg-[#151518] border border-[#28282d] flex items-center gap-3 text-[11px] text-[#8c8c94]">
                    <ShieldAlert size={16} className="text-[#ff8800] shrink-0" />
                    <span>A jogszabályok szerint 250 órát meghaladó mulasztás esetén a nevelőtestület osztályozó vizsgát írhat elő. A Pala automatikusan figyelmeztet, ha bármely tantárgynál megközelíted a limitet.</span>
                  </div>
                </div>
              )}
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
          <div className="w-full max-w-[340px] sm:max-w-[370px] bg-[#111114] border-[3px] sm:border-[4px] border-[#28282d] rounded-[36px] sm:rounded-[42px] shadow-2xl p-3 sm:p-4 overflow-hidden text-left relative">
            {/* Dynamic Island / Speaker */}
            <div className="w-24 h-4 bg-black rounded-full mx-auto mb-2 flex items-center justify-end px-2">
              <div className="w-2 h-2 rounded-full bg-[#1b1b1f]" />
            </div>

            {/* Mobile Status Bar */}
            <div className="flex items-center justify-between text-[11px] font-bold text-[#8c8c94] px-2 mb-2">
              <span>10:42</span>
              <div className="flex items-center gap-1.5 text-[10px]">
                <span>5G</span>
                <span>•</span>
                <span className="text-[#30d158]">92%</span>
              </div>
            </div>

            {/* Authentic Mobile App Header (MobileShell AppBar) */}
            <div className="flex items-center justify-between px-2 pb-2.5 mb-2.5 border-b border-[#28282d]/70">
              <div className="flex items-center gap-2">
                <span className="bg-[#ff8800] text-black text-[11px] font-black px-1.5 py-0.5 rounded tracking-wider">
                  PALA
                </span>
                <div>
                  <h3 className="text-xs font-bold text-white leading-tight">Vezérlőpult</h3>
                  <p className="text-[9px] text-[#8c8c94]">Teszt Elek</p>
                </div>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="text-[9px] font-black text-[#ffd60a] bg-[#ffd60a]/15 border border-[#ffd60a]/30 px-1.5 py-0.5 rounded">
                  DEMÓ
                </span>
                <div className="w-6 h-6 rounded-md bg-[#1b1b1f] border border-[#28282d] flex items-center justify-center text-[#8c8c94]">
                  <Search size={12} />
                </div>
                <div className="w-6 h-6 rounded-md bg-[#1b1b1f] border border-[#28282d] flex items-center justify-center text-[#8c8c94]">
                  <RefreshCw size={12} />
                </div>
              </div>
            </div>

            {/* Scrollable Mobile Body */}
            <div className="space-y-2.5">
              {/* Ongoing Class Hero Card */}
              <div className="bg-gradient-to-br from-[#ff8800]/25 via-[#ff8800]/10 to-transparent border border-[#ff8800]/40 p-3 rounded-2xl">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-[9px] font-black text-black bg-[#ff8800] px-1.5 py-0.5 rounded">
                    FOLYAMATBAN
                  </span>
                  <span className="text-[10px] text-[#8c8c94]">Terem: 204</span>
                </div>
                <div className="text-base font-black text-[#ff8800]">Matematika</div>
                <div className="text-[11px] text-[#8c8c94]">Hátra van még: 18 perc</div>
                {/* Progress bar */}
                <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden mt-2">
                  <div className="bg-[#ff8800] h-full w-[60%] rounded-full shadow-[0_0_8px_rgba(255,136,0,0.5)]" />
                </div>
              </div>

              {/* Quick Actions Scroll Row */}
              <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-[10px] font-bold">
                <span className="flex items-center gap-1 bg-[#18181c] border border-[#28282d] px-2.5 py-1 rounded-lg text-[#ff453a] shrink-0">
                  <Clock size={11} /> Hiányzások
                </span>
                <span className="flex items-center gap-1 bg-[#18181c] border border-[#28282d] px-2.5 py-1 rounded-lg text-[#ff8800] shrink-0">
                  <TrendingUp size={11} /> Statisztikák
                </span>
                <span className="flex items-center gap-1 bg-[#18181c] border border-[#28282d] px-2.5 py-1 rounded-lg text-[#ff8800] shrink-0">
                  <Sparkles size={11} /> Wrapped
                </span>
                <span className="flex items-center gap-1 bg-[#18181c] border border-[#28282d] px-2.5 py-1 rounded-lg text-[#0a84ff] shrink-0">
                  <Search size={11} /> Keresés
                </span>
              </div>

              {/* 2x2 Metric Grid */}
              <div className="grid grid-cols-2 gap-2">
                <div className="p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                  <div className="text-[9px] text-[#8c8c94] font-medium">Tanulmányi Átlag</div>
                  <div className="text-base font-black text-[#30d158]">4.85</div>
                  <div className="text-[8px] text-[#30d158]">32 rögzített jegy</div>
                </div>
                <div className="p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                  <div className="text-[9px] text-[#8c8c94] font-medium">Mai Órák</div>
                  <div className="text-base font-black text-white">6</div>
                  <div className="text-[8px] text-[#8c8c94]">3 hátralévő óra</div>
                </div>
                <div className="p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                  <div className="text-[9px] text-[#8c8c94] font-medium">Szülői Keret</div>
                  <div className="text-base font-black text-[#ffd60a]">2 / 3</div>
                  <div className="text-[8px] text-[#8c8c94]">1 nap maradt</div>
                </div>
                <div className="p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                  <div className="text-[9px] text-[#8c8c94] font-medium">Dolgozatok</div>
                  <div className="text-base font-black text-[#ff8800]">2</div>
                  <div className="text-[8px] text-[#8c8c94]">közelgő vizsga</div>
                </div>
              </div>

              {/* Today Schedule preview */}
              <div className="p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                <div className="flex items-center justify-between text-[10px] font-bold text-[#8c8c94] mb-2">
                  <span>Mai Órarend</span>
                  <span>Kedd</span>
                </div>
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between text-[11px] p-1.5 rounded-lg bg-[#ff8800]/10 border border-[#ff8800]/30">
                    <div className="flex items-center gap-2">
                      <span className="w-4 h-4 rounded bg-[#ff8800] text-black font-black text-[9px] flex items-center justify-center">3</span>
                      <span className="font-bold text-white">Matematika</span>
                    </div>
                    <span className="text-[9px] font-bold text-[#ff8800]">10:00 - 10:45</span>
                  </div>
                  <div className="flex items-center justify-between text-[11px] p-1.5 rounded-lg bg-[#111114] border border-[#28282d]">
                    <div className="flex items-center gap-2">
                      <span className="w-4 h-4 rounded bg-white/10 text-white font-bold text-[9px] flex items-center justify-center">4</span>
                      <span className="font-medium text-white">Angol nyelv</span>
                    </div>
                    <span className="text-[9px] text-[#8c8c94]">11:00 - 11:45</span>
                  </div>
                </div>
              </div>

              {/* Recent Grades */}
              <div className="p-2.5 rounded-xl bg-[#18181c] border border-[#28282d]">
                <div className="text-[10px] font-bold text-[#8c8c94] mb-2">Legfrissebb Jegyek</div>
                <div className="space-y-1.5">
                  <div className="flex items-center justify-between text-[11px]">
                    <div className="truncate pr-1">
                      <div className="font-semibold text-white truncate">Matematika</div>
                      <div className="text-[9px] text-[#8c8c94]">Témazáró dolgozat</div>
                    </div>
                    <div className="w-6 h-6 rounded bg-[#30d158]/15 border border-[#30d158]/30 text-[#30d158] font-black text-xs flex items-center justify-center shrink-0">
                      5
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-[11px] pt-1.5 border-t border-[#28282d]">
                    <div className="truncate pr-1">
                      <div className="font-semibold text-white truncate">Történelem</div>
                      <div className="text-[9px] text-[#8c8c94]">Szóbeli felelet</div>
                    </div>
                    <div className="w-6 h-6 rounded bg-[#30d158]/15 border border-[#30d158]/30 text-[#30d158] font-black text-xs flex items-center justify-center shrink-0">
                      5
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Mobile Bottom Navigation Bar (Matching Flutter MobileShell) */}
            <div className="mt-3 pt-2.5 border-t border-[#28282d] grid grid-cols-5 text-center">
              <div className="flex flex-col items-center gap-0.5 text-[#ff8800]">
                <LayoutDashboard size={16} />
                <span className="text-[8px] font-bold">Főoldal</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#8c8c94]">
                <School size={16} />
                <span className="text-[8px] font-semibold">Jegyek</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#8c8c94]">
                <Calendar size={16} />
                <span className="text-[8px] font-semibold">Órarend</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#8c8c94]">
                <ClipboardList size={16} />
                <span className="text-[8px] font-semibold">Feladatok</span>
              </div>
              <div className="flex flex-col items-center gap-0.5 text-[#8c8c94]">
                <User size={16} />
                <span className="text-[8px] font-semibold">Profil</span>
              </div>
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
              <span className="text-xs text-[#8c8c94]">teszt@pala-pc: ~ (pala --tui)</span>
            </div>
            <div className="flex items-center gap-1.5 text-[10px] text-[#5f5f67]">
              <span>_</span>
              <span>□</span>
              <span>✕</span>
            </div>
          </div>

          <div className="p-4 sm:p-6 text-xs text-[#f3f3f6] space-y-3 overflow-x-auto leading-relaxed">
            {/* Command prompt */}
            <div>
              <span className="text-[#30d158] font-bold">teszt@pala-pc</span>
              <span className="text-[#8c8c94]">:</span>
              <span className="text-[#0a84ff]">~</span>
              <span className="text-[#8c8c94]">$ </span>
              <span className="text-white font-bold">pala --tui</span>
            </div>

            {/* Real PALA ASCII Banner */}
            <pre className="text-[#ff8800] font-black text-[10px] sm:text-xs leading-none">
{`██████╗  █████╗ ██╗      █████╗ 
██╔══██╗██╔══██╗██║     ██╔══██╗
██████╔╝███████║██║     ███████║
██╔═══╝ ██╔══██║██║     ██╔══██║
██║     ██║  ██║███████╗██║  ██║
╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝  TUI ${release.version}`}
            </pre>

            {/* Mode & Header */}
            <div className="text-[#ffd60a] font-bold">
              &gt;&gt;&gt; DEMÓ ÜZEMMÓD: Teszt Elek (Pala Minta Gimnázium) &lt;&lt;&lt;
            </div>

            <div>
              <span className="text-[#0a84ff] font-bold">Pala Élő Dashboard</span>
              <span className="text-[#8c8c94]"> - Frissítve: 2026-09-13 10:42:15</span>
            </div>

            {/* Countdown Widget */}
            <div className="bg-[#ff8800]/10 border border-[#ff8800]/30 px-3 py-1.5 rounded text-[#ffd60a] font-bold inline-block">
              Matematika órából hátra van: 18 perc (Terem: 204)
            </div>

            {/* Two Column TUI Split */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-1 border-t border-[#28282d]/60">
              {/* Left Column */}
              <div className="space-y-2">
                <div className="text-[#30d158] font-bold">--- Mai Órarend ---</div>
                <div className="text-[#5f5f67]">1. óra (08:00): Magyar nyelv és irodalom</div>
                <div className="text-[#5f5f67]">2. óra (09:00): Történelem</div>
                <div className="text-[#ff8800] font-bold">3. óra (10:00): Matematika [FOLYAMATBAN]</div>
                <div className="text-white">4. óra (11:00): Angol nyelv</div>
                <div className="text-[#ffd60a]">5. óra (12:00): Biológia (Helyettesítés)</div>
                <div className="text-white">6. óra (13:00): Testnevelés</div>

                <div className="pt-2 text-[#0a84ff] font-bold">--- Közelgő Számonkérések ---</div>
                <div>[2026-09-15] Matematika (Témazáró)</div>
                <div>[2026-09-18] Fizika (Röpdolgozat)</div>
              </div>

              {/* Right Column */}
              <div className="space-y-2">
                <div className="text-[#ffd60a] font-bold">--- Legutóbbi Jegyek ---</div>
                <div>Matematika: <span className="text-[#30d158] font-bold">5</span> (Témazáró dolgozat)</div>
                <div>Történelem: <span className="text-[#30d158] font-bold">5</span> (Szóbeli felelet)</div>
                <div>Angol nyelv: <span className="text-[#30d158] font-bold">4</span> (Szódolgozat)</div>
                <div>Fizika: <span className="text-[#30d158] font-bold">5</span> (Röpdolgozat)</div>

                <div className="pt-2 text-[#bf5af2] font-bold">--- Tantárgyi Átlagok ---</div>
                <div>Tanulmányi átlag: <span className="text-[#30d158] font-bold">4.85</span> [<span className="text-[#30d158]">████████████████░░░░</span>] 97%</div>
                <div>Legjobb: Matematika (5.00)</div>
                <div>Leggyengébb: Biológia (4.33)</div>

                <div className="pt-2 text-[#ff453a] font-bold">--- Mulasztások ---</div>
                <div>Összes hiányzás: <span className="text-[#30d158] font-bold">0 óra</span> (Tiszta lap!)</div>
                <div>Szülői igazolás: <span className="text-[#ffd60a] font-bold">2 / 3 nap</span></div>
              </div>
            </div>

            {/* Bottom Hotkey Bar */}
            <div className="pt-3 border-t border-[#28282d] text-[#8c8c94] flex flex-wrap gap-x-3 gap-y-1">
              <span><strong className="text-[#ff8800]">[1]</strong> Órarend</span>
              <span><strong className="text-[#ff8800]">[2]</strong> Jegyek</span>
              <span><strong className="text-[#ff8800]">[3]</strong> Átlag</span>
              <span><strong className="text-[#ff8800]">[4]</strong> Üzenetek</span>
              <span><strong className="text-[#ff8800]">[d]</strong> Dashboard</span>
              <span><strong className="text-[#ff453a]">[q]</strong> Kilépés</span>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}
