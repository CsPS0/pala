"use client";

import React, { useState, useEffect } from "react";
import {
  Download,
  Monitor,
  Smartphone,
  Terminal,
  Globe,
  Check,
  Copy,
  Clock,
  Calculator,
  ShieldAlert,
  Mail,
  Sparkles,
  Database,
  ExternalLink,
  ShieldCheck,
  ArrowRight,
  RefreshCw,
} from "lucide-react";

type PlatformKey = "windows" | "android" | "ios" | "macos" | "linux" | "unknown";

interface PlatformConfig {
  name: string;
  ctaText: string;
  badgeText: string;
  url: string;
  tabId: string;
}

const PLATFORM_CONFIGS: Record<PlatformKey, PlatformConfig> = {
  windows: {
    name: "Windows",
    ctaText: "Letöltés Windowsra (.exe)",
    badgeText: "Asztali alkalmazás (64-bit)",
    url: "https://github.com/CsPS0/pala/releases/latest",
    tabId: "tab-desktop",
  },
  android: {
    name: "Android",
    ctaText: "Letöltés Androidra (.apk)",
    badgeText: "Közvetlen APK telepítés",
    url: "https://github.com/CsPS0/pala/releases/latest",
    tabId: "tab-mobile",
  },
  ios: {
    name: "iOS",
    ctaText: "Megnyitás iOS-re (TestFlight / Web)",
    badgeText: "iPhone és iPad kompatibilis",
    url: "https://github.com/CsPS0/pala/releases/latest",
    tabId: "tab-mobile",
  },
  macos: {
    name: "macOS",
    ctaText: "Letöltés macOS-re",
    badgeText: "Apple Silicon & Intel",
    url: "https://github.com/CsPS0/pala/releases/latest",
    tabId: "tab-desktop",
  },
  linux: {
    name: "Linux",
    ctaText: "Letöltés Linuxra",
    badgeText: "APT, AUR & Bináris",
    url: "https://github.com/CsPS0/pala/releases/latest",
    tabId: "tab-cli",
  },
  unknown: {
    name: "Minden platform",
    ctaText: "Kiadások és Letöltések",
    badgeText: "Válassz platformot",
    url: "https://github.com/CsPS0/pala/releases/latest",
    tabId: "tab-desktop",
  },
};

export default function HomePage() {
  const [detectedPlatform, setDetectedPlatform] = useState<PlatformKey>("unknown");
  const [activeTab, setActiveTab] = useState<string>("tab-desktop");
  const [latestVersion, setLatestVersion] = useState<string>("v1.2.3");
  const [releaseDate, setReleaseDate] = useState<string>("");
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  // 1. Detect platform on client mount
  useEffect(() => {
    const ua = navigator.userAgent;
    // @ts-ignore
    const platform = navigator.userAgentData?.platform || navigator.platform || "";

    let detected: PlatformKey = "unknown";
    if (/android/i.test(ua)) detected = "android";
    else if (/iPad|iPhone|iPod/.test(ua) || (platform === "MacIntel" && navigator.maxTouchPoints > 1)) detected = "ios";
    else if (/Win/i.test(platform) || /Windows/i.test(ua)) detected = "windows";
    else if (/Mac/i.test(platform) || /Macintosh/i.test(ua)) detected = "macos";
    else if (/Linux/i.test(platform) || /Linux/i.test(ua)) detected = "linux";

    setDetectedPlatform(detected);
    const config = PLATFORM_CONFIGS[detected];
    if (config?.tabId) {
      setActiveTab(config.tabId);
    }
  }, []);

  // 2. Fetch latest release info from GitHub API
  useEffect(() => {
    async function fetchRelease() {
      try {
        const res = await fetch("https://api.github.com/repos/CsPS0/pala/releases/latest");
        if (res.ok) {
          const data = await res.json();
          if (data.tag_name) setLatestVersion(data.tag_name);
          if (data.published_at) {
            const d = new Date(data.published_at);
            setReleaseDate(d.toLocaleDateString("hu-HU"));
          }
        }
      } catch (err) {
        console.warn("Could not fetch release info:", err);
      }
    }
    fetchRelease();
  }, []);

  const currentPlatformConfig = PLATFORM_CONFIGS[detectedPlatform] || PLATFORM_CONFIGS.unknown;

  const handleCopy = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  return (
    <div className="flex flex-col min-h-screen">
      {/* Navbar */}
      <header className="sticky top-0 z-50 bg-[#0f0f14]/85 backdrop-blur-md border-b border-[#262633] h-[70px] flex items-center">
        <div className="max-w-6xl mx-auto px-6 w-full flex items-center justify-between">
          <a href="#" className="flex items-center gap-2.5 font-extrabold text-lg tracking-wider">
            <span className="bg-[#ff8800] text-black text-xs font-black px-2 py-0.5 rounded tracking-widest">
              PALA
            </span>
            <span className="text-white">Kréta Kliens</span>
          </a>

          <nav className="hidden md:flex items-center gap-7 text-sm font-semibold text-[#8e8ea0]">
            <a href="#funkciok" className="hover:text-white transition-colors">
              Funkciók
            </a>
            <a href="#platformok" className="hover:text-white transition-colors">
              Platformok
            </a>
            <a href="#telepites" className="hover:text-white transition-colors">
              Telepítés
            </a>
            <a href="#biztonsag" className="hover:text-white transition-colors">
              Biztonság
            </a>
            <a
              href="https://github.com/CsPS0/pala"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-white transition-colors flex items-center gap-1"
            >
              GitHub <ExternalLink size={13} />
            </a>
          </nav>

          <div className="flex items-center gap-3">
            <a
              href="#telepites"
              className="bg-[#ff8800] hover:bg-[#ffa133] text-black font-bold text-sm px-4 py-2 rounded-lg transition-all shadow-[0_0_15px_rgba(255,136,0,0.2)] hover:shadow-[0_0_25px_rgba(255,136,0,0.35)]"
            >
              Letöltés
            </a>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative pt-24 pb-16 px-6 text-center">
        <div className="max-w-4xl mx-auto">
          {/* Tag Pill */}
          <div className="inline-flex items-center gap-2 bg-[#ff8800]/10 border border-[#ff8800]/30 px-4 py-1.5 rounded-full text-xs font-bold text-[#ff8800] mb-6">
            <span>Nyílt forráskódú</span> • <span>Villámgyors</span> • <span>Offline-kompatibilis</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-black tracking-tight leading-[1.1] mb-6">
            A modern, intelligens és letisztult{" "}
            <span className="bg-gradient-to-r from-[#ff8800] to-[#ffbb66] bg-clip-text text-transparent">
              Kréta élmény
            </span>
            .
          </h1>

          <p className="text-lg text-[#8e8ea0] max-w-2xl mx-auto leading-relaxed mb-10">
            Kezeld a jegyeidet, órarendedet, mulasztásaidat és tanári üzeneteidet asztali alkalmazásban, mobilon,
            böngészőben vagy terminálban — reklámok és lassulások nélkül.
          </p>

          {/* Smart CTA Buttons */}
          <div className="flex flex-wrap items-center justify-center gap-4 mb-5">
            <a
              href={currentPlatformConfig.url}
              className="inline-flex items-center gap-2.5 bg-[#ff8800] hover:bg-[#ffa133] text-black font-extrabold text-base px-7 py-3.5 rounded-xl transition-all shadow-[0_0_25px_rgba(255,136,0,0.25)] hover:shadow-[0_0_35px_rgba(255,136,0,0.4)] hover:-translate-y-0.5"
            >
              <Download size={18} />
              <span>{currentPlatformConfig.ctaText}</span>
            </a>

            <a
              href="https://github.com/CsPS0/pala"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-[#15151c] hover:bg-[#1b1b24] text-white border border-[#262633] hover:border-[#8e8ea0] font-bold text-base px-6 py-3.5 rounded-xl transition-all hover:-translate-y-0.5"
            >
              <span>GitHub Forráskód</span>
              <ArrowRight size={16} />
            </a>
          </div>

          {/* Version Info Badge */}
          <div className="flex items-center justify-center gap-2 text-xs text-[#5a5a6e] mb-12">
            <span>Felismerve: {currentPlatformConfig.name} ({currentPlatformConfig.badgeText})</span>
            <span>•</span>
            <span>Legfrissebb verzió: <strong className="text-[#8e8ea0]">{latestVersion}</strong></span>
            {releaseDate && <span>({releaseDate})</span>}
          </div>

          {/* Platform Pills */}
          <div id="platformok" className="flex flex-wrap items-center justify-center gap-2.5 mb-16">
            {(["windows", "android", "ios", "macos", "linux", "tui"] as const).map((pKey) => {
              const isSelected = detectedPlatform === pKey;
              const labels: Record<string, string> = {
                windows: "Windows Desktop",
                android: "Android (.apk)",
                ios: "iOS",
                macos: "macOS",
                linux: "Linux",
                tui: "Terminál (TUI)",
              };
              return (
                <a
                  key={pKey}
                  href="#telepites"
                  className={`px-3.5 py-1.5 rounded-full text-xs font-semibold border transition-all ${
                    isSelected
                      ? "bg-[#ff8800]/15 border-[#ff8800] text-[#ff8800]"
                      : "bg-[#15151c] border-[#262633] text-[#8e8ea0] hover:border-[#ff8800] hover:text-white"
                  }`}
                >
                  {labels[pKey]}
                </a>
              );
            })}
          </div>

          {/* Mockup Preview Card */}
          <div className="rounded-2xl border border-[#262633] bg-[#0f0f14] shadow-2xl overflow-hidden text-left max-w-4xl mx-auto">
            <div className="h-10 bg-[#09090c] border-b border-[#262633] flex items-center px-4 gap-2">
              <div className="w-2.5 h-2.5 rounded-full bg-[#ef4444]" />
              <div className="w-2.5 h-2.5 rounded-full bg-[#eab308]" />
              <div className="w-2.5 h-2.5 rounded-full bg-[#22c55e]" />
              <span className="ml-2 text-xs font-semibold text-[#5a5a6e]">
                Pala Desktop — Vezérlőpult & Élő Órarend
              </span>
            </div>

            <div className="p-6 grid grid-cols-1 md:grid-cols-4 gap-5 bg-[#09090c]">
              <div className="hidden md:flex flex-col gap-2 bg-[#0f0f14] border border-[#262633] p-3.5 rounded-xl">
                <div className="text-xs font-bold text-[#ff8800] bg-[#ff8800]/10 px-3 py-2 rounded-lg border border-[#ff8800]/30">
                  Vezérlőpult
                </div>
                <div className="text-xs font-semibold text-[#8e8ea0] px-3 py-1.5">Érdemjegyek</div>
                <div className="text-xs font-semibold text-[#8e8ea0] px-3 py-1.5">Órarend (5 napos)</div>
                <div className="text-xs font-semibold text-[#8e8ea0] px-3 py-1.5">Feladatok & Dolgozatok</div>
                <div className="text-xs font-semibold text-[#8e8ea0] px-3 py-1.5">Tanári Üzenetek</div>
                <div className="text-xs font-semibold text-[#8e8ea0] px-3 py-1.5">250h Veszélyzóna</div>
              </div>

              <div className="md:col-span-3 flex flex-col gap-4">
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-[#15151c] border border-[#262633] p-3.5 rounded-xl">
                    <div className="text-[11px] font-semibold text-[#8e8ea0]">Tanulmányi Átlag</div>
                    <div className="text-xl font-extrabold text-[#ff8800] mt-1">4.82</div>
                  </div>
                  <div className="bg-[#15151c] border border-[#262633] p-3.5 rounded-xl">
                    <div className="text-[11px] font-semibold text-[#8e8ea0]">Mai Órák</div>
                    <div className="text-xl font-extrabold text-white mt-1">6 tanóra</div>
                  </div>
                  <div className="bg-[#15151c] border border-[#262633] p-3.5 rounded-xl">
                    <div className="text-[11px] font-semibold text-[#8e8ea0]">Szülői Keret</div>
                    <div className="text-xl font-extrabold text-[#22c55e] mt-1">2 / 3 nap</div>
                  </div>
                </div>

                <div className="bg-[#ff8800]/10 border border-[#ff8800]/30 p-4 rounded-xl">
                  <div className="text-[10px] font-black tracking-wider text-[#ff8800]">FOLYAMATBAN LÉVŐ TANÓRA</div>
                  <div className="text-base font-extrabold text-white mt-1">Matematika • Terem: 204</div>
                  <div className="text-xs text-[#8e8ea0] mt-0.5">Hátra van még: 18 perc (Vége: 10:45)</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section id="funkciok" className="py-20 px-6 border-t border-[#262633]">
        <div className="max-w-6xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="text-3xl font-extrabold tracking-tight mb-3">
              Minden, amire a tanév során szükséged van
            </h2>
            <p className="text-[#8e8ea0] text-base">
              A Pala nem csupán egy egyszerű kliens, hanem egy komplett tanulói asszisztens.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="bg-[#15151c] border border-[#262633] hover:border-[#ff8800] p-6 rounded-2xl transition-all">
              <div className="w-11 h-11 rounded-xl bg-[#ff8800]/10 text-[#ff8800] flex items-center justify-center mb-4">
                <Clock size={20} />
              </div>
              <h3 className="text-lg font-bold mb-2">Élő Visszaszámláló & Órarend</h3>
              <p className="text-sm text-[#8e8ea0] leading-relaxed">
                Valós idejű órarendi visszaszámlálás dinamikus folyamatjelzővel, teremszámokkal, tanárokkal és elmaradó
                órák jelzésével.
              </p>
            </div>

            <div className="bg-[#15151c] border border-[#262633] hover:border-[#ff8800] p-6 rounded-2xl transition-all">
              <div className="w-11 h-11 rounded-xl bg-[#ff8800]/10 text-[#ff8800] flex items-center justify-center mb-4">
                <Calculator size={20} />
              </div>
              <h3 className="text-lg font-bold mb-2">Célátlag & Szellem Jegy Kalkulátor</h3>
              <p className="text-sm text-[#8e8ea0] leading-relaxed">
                Kiszámítja, hogy hány darab 5-ös szükséges a kitűzött tanulmányi átlag eléréséhez, és azonnal
                szimulálhatsz feltételes jegyeket.
              </p>
            </div>

            <div className="bg-[#15151c] border border-[#262633] hover:border-[#ff8800] p-6 rounded-2xl transition-all">
              <div className="w-11 h-11 rounded-xl bg-[#ff8800]/10 text-[#ff8800] flex items-center justify-center mb-4">
                <ShieldAlert size={20} />
              </div>
              <h3 className="text-lg font-bold mb-2">250 Órás Veszélyzóna & Igazolás</h3>
              <p className="text-sm text-[#8e8ea0] leading-relaxed">
                Pontos hiányzásmérő a 250 órás tantárgyi osztályozóvizsga-küszöbhöz, szülői keret figyelővel és
                1-kattintásos igazolás generátorral.
              </p>
            </div>

            <div className="bg-[#15151c] border border-[#262633] hover:border-[#ff8800] p-6 rounded-2xl transition-all">
              <div className="w-11 h-11 rounded-xl bg-[#ff8800]/10 text-[#ff8800] flex items-center justify-center mb-4">
                <Mail size={20} />
              </div>
              <h3 className="text-lg font-bold mb-2">Közvetlen Tanári Üzenetküldés</h3>
              <p className="text-sm text-[#8e8ea0] leading-relaxed">
                Írj üzenetet közvetlenül tanáraidnak a beépített tantárgyi és órarendi névsorból, vagy válaszolj a
                beérkezett levelekre egy kattintással.
              </p>
            </div>

            <div className="bg-[#15151c] border border-[#262633] hover:border-[#ff8800] p-6 rounded-2xl transition-all">
              <div className="w-11 h-11 rounded-xl bg-[#ff8800]/10 text-[#ff8800] flex items-center justify-center mb-4">
                <Sparkles size={20} />
              </div>
              <h3 className="text-lg font-bold mb-2">Pala Wrapped & Story Megosztás</h3>
              <p className="text-sm text-[#8e8ea0] leading-relaxed">
                Év végi összefoglaló kártya, amelyet 9:16 formátumban azonnal lementhetsz és megoszthatsz Instagram
                vagy Facebook történetként.
              </p>
            </div>

            <div className="bg-[#15151c] border border-[#262633] hover:border-[#ff8800] p-6 rounded-2xl transition-all">
              <div className="w-11 h-11 rounded-xl bg-[#ff8800]/10 text-[#ff8800] flex items-center justify-center mb-4">
                <Database size={20} />
              </div>
              <h3 className="text-lg font-bold mb-2">100% Offline & Gyorsítótár</h3>
              <p className="text-sm text-[#8e8ea0] leading-relaxed">
                Nincs internet a suliban? A Pala minden adatot titkosított helyi gyorsítótárban tárol, így
                internetkapcsolat nélkül is azonnal elérhető.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Installation Section */}
      <section id="telepites" className="py-20 px-6 bg-[#0f0f14]/60 border-t border-[#262633]">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-extrabold tracking-tight mb-3">Válaszd ki a platformodat</h2>
            <p className="text-[#8e8ea0] text-base">A Pala minden eszközödön natívan és villámgyorsan fut.</p>
          </div>

          {/* Tab Buttons */}
          <div className="flex flex-wrap justify-center gap-2 mb-8">
            {[
              { id: "tab-desktop", label: "Windows Asztali Alkalmazás", icon: Monitor },
              { id: "tab-mobile", label: "Mobil (Android & iOS)", icon: Smartphone },
              { id: "tab-cli", label: "Terminál (TUI / CLI)", icon: Terminal },
              { id: "tab-web", label: "Webes Felület", icon: Globe },
            ].map((tab) => {
              const IconComp = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`inline-flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-bold border transition-all ${
                    isActive
                      ? "bg-[#15151c] border-[#ff8800] text-white shadow-[0_0_15px_rgba(255,136,0,0.15)]"
                      : "bg-[#09090c] border-[#262633] text-[#8e8ea0] hover:text-white hover:border-[#8e8ea0]"
                  }`}
                >
                  <IconComp size={16} className={isActive ? "text-[#ff8800]" : ""} />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>

          {/* Tab 1: Windows Desktop */}
          {activeTab === "tab-desktop" && (
            <div className="bg-[#15151c] border border-[#262633] p-8 rounded-2xl">
              <h3 className="text-xl font-bold mb-2">Pala Windows Asztali Alkalmazás</h3>
              <p className="text-[#8e8ea0] text-sm mb-6">
                Kényelmes, egérrel és billentyűzettel vezérelhető asztali felület Windows 10 és Windows 11 rendszerekre,
                Start menü integrációval.
              </p>

              <div className="mb-6">
                <a
                  href="https://github.com/CsPS0/pala/releases/latest"
                  className="inline-flex items-center gap-2 bg-[#ff8800] hover:bg-[#ffa133] text-black font-bold text-sm px-6 py-3 rounded-xl transition-all"
                >
                  <Download size={16} />
                  <span>Telepítő Letöltése (.exe)</span>
                </a>
              </div>

              <div>
                <div className="text-xs font-bold text-[#8e8ea0] mb-2">
                  Parancssoros Start menü parancsikon létrehozása:
                </div>
                <div className="bg-[#09090c] border border-[#262633] p-3.5 rounded-xl flex items-center justify-between font-mono text-xs text-[#ff8800]">
                  <span>pala --install-shortcut</span>
                  <button
                    onClick={() => handleCopy("pala --install-shortcut", "shortcut")}
                    className="flex items-center gap-1 bg-[#15151c] hover:bg-[#ff8800] hover:text-black text-white px-2.5 py-1 rounded border border-[#262633] text-xs font-sans transition-all"
                  >
                    {copiedKey === "shortcut" ? <Check size={12} /> : <Copy size={12} />}
                    <span>{copiedKey === "shortcut" ? "Másolva!" : "Másolás"}</span>
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Tab 2: Mobile */}
          {activeTab === "tab-mobile" && (
            <div className="bg-[#15151c] border border-[#262633] p-8 rounded-2xl">
              <h3 className="text-xl font-bold mb-2">Mobil Alkalmazás (Android & iOS)</h3>
              <p className="text-[#8e8ea0] text-sm mb-6">
                Hordozható, érintőképernyőre optimalizált élmény okostelefonokra és táblagépekre.
              </p>

              <div className="flex flex-wrap gap-4">
                <a
                  href="https://github.com/CsPS0/pala/releases/latest"
                  className="inline-flex items-center gap-2 bg-[#ff8800] hover:bg-[#ffa133] text-black font-bold text-sm px-6 py-3 rounded-xl transition-all"
                >
                  <Download size={16} />
                  <span>Android APK Letöltése (.apk)</span>
                </a>

                <a
                  href="https://github.com/CsPS0/pala"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-2 bg-[#09090c] hover:bg-[#1b1b24] text-white border border-[#262633] font-bold text-sm px-6 py-3 rounded-xl transition-all"
                >
                  <span>iOS Telepítési Útmutató</span>
                  <ExternalLink size={14} />
                </a>
              </div>
            </div>
          )}

          {/* Tab 3: Terminal */}
          {activeTab === "tab-cli" && (
            <div className="bg-[#15151c] border border-[#262633] p-8 rounded-2xl space-y-4">
              <h3 className="text-xl font-bold mb-1">Terminálos Kliens (TUI) Telepítése</h3>
              <p className="text-[#8e8ea0] text-sm mb-4">
                Telepítsd a kedvenc csomagkezelőddel Windows, Linux és macOS rendszereken:
              </p>

              <div>
                <div className="text-xs font-bold text-[#8e8ea0] mb-1.5">Windows (Scoop):</div>
                <div className="bg-[#09090c] border border-[#262633] p-3 rounded-xl flex items-center justify-between font-mono text-xs text-[#ff8800] overflow-x-auto">
                  <span>scoop bucket add pala https://github.com/CsPS0/pala-bucket && scoop install pala</span>
                  <button
                    onClick={() =>
                      handleCopy(
                        "scoop bucket add pala https://github.com/CsPS0/pala-bucket && scoop install pala",
                        "scoop"
                      )
                    }
                    className="ml-3 flex items-center gap-1 bg-[#15151c] hover:bg-[#ff8800] hover:text-black text-white px-2.5 py-1 rounded border border-[#262633] text-xs font-sans transition-all shrink-0"
                  >
                    {copiedKey === "scoop" ? <Check size={12} /> : <Copy size={12} />}
                    <span>{copiedKey === "scoop" ? "Másolva!" : "Másolás"}</span>
                  </button>
                </div>
              </div>

              <div>
                <div className="text-xs font-bold text-[#8e8ea0] mb-1.5">Linux & macOS (Gyors telepítő szkript):</div>
                <div className="bg-[#09090c] border border-[#262633] p-3 rounded-xl flex items-center justify-between font-mono text-xs text-[#ff8800] overflow-x-auto">
                  <span>curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash</span>
                  <button
                    onClick={() =>
                      handleCopy("curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash", "curl")
                    }
                    className="ml-3 flex items-center gap-1 bg-[#15151c] hover:bg-[#ff8800] hover:text-black text-white px-2.5 py-1 rounded border border-[#262633] text-xs font-sans transition-all shrink-0"
                  >
                    {copiedKey === "curl" ? <Check size={12} /> : <Copy size={12} />}
                    <span>{copiedKey === "curl" ? "Másolva!" : "Másolás"}</span>
                  </button>
                </div>
              </div>

              <div>
                <div className="text-xs font-bold text-[#8e8ea0] mb-1.5">macOS (Homebrew):</div>
                <div className="bg-[#09090c] border border-[#262633] p-3 rounded-xl flex items-center justify-between font-mono text-xs text-[#ff8800] overflow-x-auto">
                  <span>brew tap CsPS0/pala && brew install pala</span>
                  <button
                    onClick={() => handleCopy("brew tap CsPS0/pala && brew install pala", "brew")}
                    className="ml-3 flex items-center gap-1 bg-[#15151c] hover:bg-[#ff8800] hover:text-black text-white px-2.5 py-1 rounded border border-[#262633] text-xs font-sans transition-all shrink-0"
                  >
                    {copiedKey === "brew" ? <Check size={12} /> : <Copy size={12} />}
                    <span>{copiedKey === "brew" ? "Másolva!" : "Másolás"}</span>
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* Tab 4: Web UI */}
          {activeTab === "tab-web" && (
            <div className="bg-[#15151c] border border-[#262633] p-8 rounded-2xl">
              <h3 className="text-xl font-bold mb-2">Helyi Webes Felület (Pala Web)</h3>
              <p className="text-[#8e8ea0] text-sm mb-6">
                Nyisd meg a Palát közvetlenül a böngésződben helyi szerverként a terminálból:
              </p>

              <div className="bg-[#09090c] border border-[#262633] p-3.5 rounded-xl flex items-center justify-between font-mono text-xs text-[#ff8800]">
                <span>pala --web</span>
                <button
                  onClick={() => handleCopy("pala --web", "web")}
                  className="flex items-center gap-1 bg-[#15151c] hover:bg-[#ff8800] hover:text-black text-white px-2.5 py-1 rounded border border-[#262633] text-xs font-sans transition-all"
                >
                  {copiedKey === "web" ? <Check size={12} /> : <Copy size={12} />}
                  <span>{copiedKey === "web" ? "Másolva!" : "Másolás"}</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* Security Section */}
      <section id="biztonsag" className="py-20 px-6 border-t border-[#262633]">
        <div className="max-w-4xl mx-auto bg-gradient-to-br from-[#ff8800]/10 via-[#15151c] to-[#22c55e]/5 border border-[#262633] p-8 sm:p-12 rounded-3xl grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
          <div>
            <div className="inline-flex items-center gap-2 text-xs font-bold text-[#22c55e] mb-3">
              <ShieldCheck size={16} />
              <span>Adatvédelem & Biztonság</span>
            </div>
            <h2 className="text-2xl sm:text-3xl font-extrabold tracking-tight mb-4">
              A személyes adataid kizárólag a tiéd
            </h2>
            <p className="text-sm text-[#8e8ea0] leading-relaxed">
              A Pala nem használ köztes proxy szervereket, és nem gyűjt telemetriát vagy felhasználói analitikát.
            </p>
          </div>

          <ul className="space-y-3 text-sm text-[#8e8ea0]">
            <li className="flex items-start gap-2.5">
              <Check size={18} className="text-[#22c55e] shrink-0 mt-0.5" />
              <span>Közvetlen kapcsolat a hivatalos Kréta API szervereivel</span>
            </li>
            <li className="flex items-start gap-2.5">
              <Check size={18} className="text-[#22c55e] shrink-0 mt-0.5" />
              <span>A jelszavak és tokenek AES-256 titkosítással tárolódnak helyben</span>
            </li>
            <li className="flex items-start gap-2.5">
              <Check size={18} className="text-[#22c55e] shrink-0 mt-0.5" />
              <span>100% nyílt forráskódú és függetlenül auditálható</span>
            </li>
            <li className="flex items-start gap-2.5">
              <Check size={18} className="text-[#22c55e] shrink-0 mt-0.5" />
              <span>Nincs adatgyűjtés, nincsenek analitikai követőkódok és nincsenek hirdetések</span>
            </li>
          </ul>
        </div>
      </section>

      {/* Footer */}
      <footer className="mt-auto border-t border-[#262633] bg-[#0f0f14] py-12 px-6 text-sm text-[#8e8ea0]">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-2.5 font-bold">
            <span className="bg-[#ff8800] text-black text-xs font-black px-2 py-0.5 rounded tracking-widest">
              PALA
            </span>
            <span className="text-white">Kréta Kliens</span>
          </div>

          <div className="flex items-center gap-6 text-xs font-semibold">
            <a href="https://github.com/CsPS0/pala" target="_blank" rel="noopener noreferrer" className="hover:text-white">
              GitHub
            </a>
            <a href="https://github.com/CsPS0/pala/releases" target="_blank" rel="noopener noreferrer" className="hover:text-white">
              Kiadások
            </a>
            <a href="https://github.com/CsPS0/pala/blob/main/LICENSE" target="_blank" rel="noopener noreferrer" className="hover:text-white">
              MIT Licenc
            </a>
            <a href="https://github.com/CsPS0/pala/blob/main/docs/DATA_SECURITY.md" target="_blank" rel="noopener noreferrer" className="hover:text-white">
              Adatvédelem
            </a>
          </div>
        </div>

        <div className="max-w-6xl mx-auto mt-8 pt-6 border-t border-white/5 text-center text-xs text-[#5a5a6e]">
          Pala — Nem hivatalos, nyílt forráskódú Kréta kliens. A Kréta az eKréta Informatikai Zrt. védjegye.
        </div>
      </footer>
    </div>
  );
}
