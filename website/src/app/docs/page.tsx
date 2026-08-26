"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import {
  BookOpen,
  Download,
  Trash2,
  HelpCircle,
  Shield,
  Monitor,
  Smartphone,
  Terminal,
  Globe,
  Copy,
  Check,
  Search,
  ExternalLink,
  ChevronRight,
  ArrowLeft,
  Sparkles,
  Calculator,
  Clock,
  ShieldAlert,
  AlertTriangle,
  Info,
  CheckCircle2,
  Cpu,
  Menu,
  X,
  RefreshCw,
  Layers,
  FileText,
  KeyRound,
  Zap,
  ChevronDown,
  Keyboard,
  Sliders,
  FolderTree,
  FileCode2,
  Play,
  Lock,
  ServerOff,
  CornerDownLeft
} from "lucide-react";
import { WindowsIcon, AppleIcon, AndroidIcon, LinuxIcon } from "@/components/PlatformIcons";
import { detectClientOS } from "@/lib/detectOS";
import { useRelease } from "@/lib/useRelease";

interface SearchIndexItem {
  id: string;
  pageId: string;
  tabId?: string;
  title: string;
  category: string;
  description: string;
  keywords: string[];
}

export default function DocsPage() {
  const [activePage, setActivePage] = useState("installation");
  const [installTab, setInstallTab] = useState("windows");
  const [detectedOS, setDetectedOS] = useState<string>("unknown");
  const release = useRelease();
  const [copiedKey, setCopiedKey] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchModalOpen, setSearchModalOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [selectedIndex, setSelectedIndex] = useState(0);

  const searchInputRef = useRef<HTMLInputElement>(null);
  const searchTriggerRef = useRef<HTMLButtonElement>(null);

  // Client-side OS detection on mount
  useEffect(() => {
    const os = detectClientOS();
    setDetectedOS(os);
    if (os !== "unknown") {
      setInstallTab(os);
    }
  }, []);

  const handleCopy = async (text: string, key: string) => {
    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(text);
        setCopiedKey(key);
        setTimeout(() => setCopiedKey(null), 2000);
      } else {
        const textarea = document.createElement("textarea");
        textarea.value = text;
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand("copy");
        document.body.removeChild(textarea);
        setCopiedKey(key);
        setTimeout(() => setCopiedKey(null), 2000);
      }
    } catch (err) {
      console.warn("Clipboard copy error:", err);
    }
  };

  const selectPage = (pageId: string, tabId?: string) => {
    setActivePage(pageId);
    if (tabId) {
      setInstallTab(tabId);
    }
    setSearchModalOpen(false);
    setMobileMenuOpen(false);
    if (typeof window !== "undefined") {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };

  // Lock body scroll when search modal is open
  useEffect(() => {
    if (searchModalOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "";
    }
    return () => {
      document.body.style.overflow = "";
    };
  }, [searchModalOpen]);

  // Intercept Ctrl+K / Cmd+K and Escape globally
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setSearchModalOpen((prev) => !prev);
      }
      if (e.key === "Escape") {
        setSearchModalOpen(false);
        setMobileMenuOpen(false);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Autofocus search input whenever modal opens
  useEffect(() => {
    if (searchModalOpen) {
      setSearchQuery("");
      setSelectedIndex(0);
      setTimeout(() => {
        searchInputRef.current?.focus();
      }, 50);
    } else {
      searchTriggerRef.current?.focus();
    }
  }, [searchModalOpen]);

  const searchIndex: SearchIndexItem[] = [
    {
      id: "inst-win",
      pageId: "installation",
      tabId: "windows",
      title: "Telepítés Windows alatt",
      category: "Kezdő Lépések / Telepítés",
      description: "Grafikus Inno Setup telepítő, Scoop parancs és Defender SmartScreen feloldás.",
      keywords: ["windows", "exe", "setup", "scoop", "smartscreen", "defender", "powershell", "eltávolítás"]
    },
    {
      id: "inst-android",
      pageId: "installation",
      tabId: "android",
      title: "Telepítés Android eszközökre",
      category: "Kezdő Lépések / Telepítés",
      description: "Universal, ARM64, ARMv7 (régebbi telefonok), x86_64 (BlueStacks emulátorok) és architektúra választó útmutató.",
      keywords: ["android", "apk", "universal", "arm64", "armv7", "32-bit", "x86_64", "emulátor", "bluestacks", "nox", "wsa", "telefon", "mobil"]
    },
    {
      id: "inst-ios",
      pageId: "installation",
      tabId: "ios",
      title: "Telepítés iOS eszközökre",
      category: "Kezdő Lépések / Telepítés",
      description: "Sideloading AltStore/SideStore segítségével, IPA telepítés és Safari Főképernyőhöz adás.",
      keywords: ["ios", "iphone", "ipad", "ipa", "altstore", "sidestore", "trollstore", "sideload", "safari", "pwa"]
    },
    {
      id: "inst-linux",
      pageId: "installation",
      tabId: "linux",
      title: "Telepítés Linux rendszerekre",
      category: "Kezdő Lépések / Telepítés",
      description: "Univerzális bash curl script, Ubuntu/Debian APT csomagtár és Arch AUR (yay/paru).",
      keywords: ["linux", "ubuntu", "debian", "apt", "aur", "arch", "manjaro", "yay", "paru", "script", "curl"]
    },
    {
      id: "inst-mac",
      pageId: "installation",
      tabId: "macos",
      title: "Telepítés macOS alatt",
      category: "Kezdő Lépések / Telepítés",
      description: "Homebrew telepítés Apple Silicon és Intel Mac gépekre.",
      keywords: ["macos", "mac", "apple", "silicon", "m1", "m2", "m3", "homebrew", "brew", "zsh"]
    },
    {
      id: "inst-ext",
      pageId: "installation",
      tabId: "extension",
      title: "Böngésző Bővítmény Telepítése",
      category: "Kezdő Lépések / Telepítés",
      description: "Manifest V3 bővítmény Chrome, Edge, Brave, Firefox böngészőkhöz.",
      keywords: ["bővítmény", "extension", "chrome", "edge", "brave", "firefox", "unpacked"]
    },
    {
      id: "compatibility",
      pageId: "compatibility",
      title: "Kompatibilitás és Rendszerkövetelmények",
      category: "Kezdő Lépések",
      description: "Támogatott operációs rendszerek, böngészők és iskolatípusok (általános, gimnázium, technikum).",
      keywords: ["kompatibilitás", "rendszerkövetelmény", "windows", "android", "mac", "gimnázium", "technikum"]
    },
    {
      id: "upgrade",
      pageId: "upgrade-guide",
      title: "Frissítési Útmutató",
      category: "Kezdő Lépések",
      description: "Verziókövetés, adatmegőrzés és frissítés végrehajtása minden rendszeren.",
      keywords: ["frissítés", "upgrade", "update", "új verzió", "adatmegőrzés"]
    },
    {
      id: "hasznalat",
      pageId: "hasznalat",
      title: "Használat & CLI Kapcsolók",
      category: "Funkciók",
      description: "Kréta bejelentkezés, OM azonosító, --demo mód, --clear-cache és naptár export.",
      keywords: ["használat", "bejelentkezés", "om azonosító", "felhasználónév", "jelszó", "cli", "--demo", "--clear-cache", "--json", "--export-ics"]
    },
    {
      id: "gyorsbillentyuk",
      pageId: "gyorsbillentyuk",
      title: "Gyorsbillentyűk (Keybindings)",
      category: "Funkciók",
      description: "TUI navigáció: 1/d órarend, 2/g jegyek, 3/c célátlag szimulátor, 4/a hiányzások, w wrapped, r sync, q kilépés.",
      keywords: ["gyorsbillentyűk", "keybind", "billentyűzet", "1", "2", "3", "4", "d", "g", "c", "a", "w", "r", "q", "esc", "tab"]
    },
    {
      id: "files-configs",
      pageId: "files-configs",
      title: "Fájlok és Konfigurációk (Files & Configs)",
      category: "Funkciók",
      description: "Elérési utak (AppData, XDG, Library), config.json mezők és manuális szerkesztés.",
      keywords: ["fájlok", "config", "json", "appdata", "xdg", "cache.db", "konfiguráció", "szerkesztés", "notepad", "nano"]
    },
    {
      id: "security",
      pageId: "security",
      title: "Zero-Knowledge & Titkosítás",
      category: "Biztonság & Architektúra",
      description: "Közvetlen TLS 1.3 Kréta OAuth2 kapcsolat, helyi AES-256 token tárolás és nulla telemetria.",
      keywords: ["biztonság", "titkosítás", "zero-knowledge", "aes-256", "tls 1.3", "oauth2", "telemetry"]
    },
    {
      id: "faq-website",
      pageId: "troubleshooting",
      title: "GYIK: Miért nincs nyilvános weboldalas verzió?",
      category: "Biztonság & Architektúra / GYIK",
      description: "CORS korlátok, központi szerver elkerülése, GDPR adatvédelmi határok és a kliensoldali modell.",
      keywords: ["miért nincs weboldal", "web app", "cors", "proxy", "gdpr", "szerver", "adatvédelem", "adatkezelés"]
    },
    {
      id: "faq-passwords",
      pageId: "troubleshooting",
      title: "GYIK: Biztonságos a jelszavam megadása?",
      category: "Biztonság & Architektúra / GYIK",
      description: "Közvetlen kapcsolat a hivatalos idp.e-kreta.hu szerverrel jelszótárolás nélkül.",
      keywords: ["jelszó", "biztonság", "token", "titkosítás", "idp.e-kreta.hu"]
    },
    {
      id: "faq-smartscreen",
      pageId: "troubleshooting",
      title: "GYIK: SmartScreen / Play Protect figyelmeztetés",
      category: "Biztonság & Architektúra / GYIK",
      description: "Nyílt forráskódú projekt független aláírás nélkül. Futtatás mindenképpen lépések.",
      keywords: ["smartscreen", "defender", "play protect", "vírus", "tanúsítvány", "futtatás mindenképpen"]
    },
    {
      id: "faq-login",
      pageId: "troubleshooting",
      title: "GYIK: Bejelentkezési hibák elhárítása",
      category: "Biztonság & Architektúra / GYIK",
      description: "Intézménykód ellenőrzése, Kréta szerver leállások kezelése és Teszt Elek demó mód.",
      keywords: ["bejelentkezés", "hiba", "szerverhiba", "karbantartás", "teszt elek", "demo"]
    }
  ];

  // When search query is empty, show nothing! Only show results when user starts typing.
  const filteredResults = searchQuery.trim() === ""
    ? []
    : searchIndex.filter((item) => {
        const q = searchQuery.toLowerCase();
        return (
          item.title.toLowerCase().includes(q) ||
          item.description.toLowerCase().includes(q) ||
          item.category.toLowerCase().includes(q) ||
          item.keywords.some((kw) => kw.toLowerCase().includes(q))
        );
      });

  const handleModalKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "ArrowDown" && filteredResults.length > 0) {
      e.preventDefault();
      setSelectedIndex((prev) => (prev + 1) % filteredResults.length);
    } else if (e.key === "ArrowUp" && filteredResults.length > 0) {
      e.preventDefault();
      setSelectedIndex((prev) => (prev - 1 + filteredResults.length) % filteredResults.length);
    } else if (e.key === "Enter" && filteredResults.length > 0) {
      e.preventDefault();
      if (filteredResults[selectedIndex]) {
        const item = filteredResults[selectedIndex];
        selectPage(item.pageId, item.tabId);
      }
    }
  };

  const navCategories = [
    {
      category: "Kezdő Lépések",
      items: [
        { id: "installation", label: "Telepítés & Beállítás", icon: Download, kicker: "GETTING STARTED / INSTALLATION" },
        { id: "compatibility", label: "Kompatibilitás", icon: Layers, kicker: "GETTING STARTED / COMPATIBILITY" },
        { id: "upgrade-guide", label: "Frissítési Útmutató", icon: RefreshCw, kicker: "GETTING STARTED / UPGRADE" },
      ],
    },
    {
      category: "Funkciók",
      items: [
        { id: "hasznalat", label: "Használat", icon: Play, kicker: "FUNKCIÓK / HASZNÁLAT" },
        { id: "gyorsbillentyuk", label: "Gyorsbillentyűk", icon: Keyboard, kicker: "FUNKCIÓK / GYORSBILLENTYŰK" },
        { id: "files-configs", label: "Fájlok & Konfigurációk", icon: FolderTree, kicker: "FUNKCIÓK / FÁJLOK & KONFIGURÁCIÓK" },
      ],
    },
    {
      category: "Biztonság & Architektúra",
      items: [
        { id: "security", label: "Zero-Knowledge & Titkosítás", icon: Shield, kicker: "SECURITY & ARCHITECTURE" },
        { id: "troubleshooting", label: "Hibaelhárítás & GYIK", icon: HelpCircle, kicker: "BIZTONSÁG & ARCHITEKTÚRA / GYIK" },
      ],
    },
  ];

  const baseTabs = [
    { id: "windows", label: "Windows", icon: WindowsIcon },
    { id: "android", label: "Android", icon: AndroidIcon },
    { id: "ios", label: "iOS", icon: AppleIcon },
    { id: "linux", label: "Linux", icon: LinuxIcon },
    { id: "macos", label: "macOS", icon: AppleIcon },
    { id: "extension", label: "Böngésző", icon: Globe },
  ];

  const installTabs = [
    ...baseTabs.filter((t) => t.id === detectedOS),
    ...baseTabs.filter((t) => t.id !== detectedOS),
  ];

  return (
    <div className="min-h-screen bg-[#0e0e11] text-[#f3f3f6] flex flex-col font-sans selection:bg-[#ff8800]/30 selection:text-[#ff8800]">
      {/* Interactive Command Palette / Search Modal */}
      {searchModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Dokumentáció Kereső"
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-start justify-center p-4 sm:p-6 pt-16 sm:pt-24 animate-fadeIn"
          onClick={() => setSearchModalOpen(false)}
        >
          <div
            className="w-full max-w-2xl bg-[#151518] border border-[#28282d] rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[80vh]"
            onClick={(e) => e.stopPropagation()}
            onKeyDown={handleModalKeyDown}
          >
            {/* Modal Search Input Header */}
            <div className="p-4 border-b border-[#28282d] flex items-center gap-3 bg-[#111114]">
              <Search size={18} className="text-[#ff8800] shrink-0" />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setSelectedIndex(0);
                }}
                placeholder="Keresés témák, parancsok, GYIK kérdések között..."
                className="flex-1 bg-transparent text-sm text-[#f3f3f6] placeholder-[#5f5f67] outline-none font-medium"
              />
              {searchQuery && (
                <button
                  onClick={() => setSearchQuery("")}
                  className="text-xs text-[#8c8c94] hover:text-[#f3f3f6] bg-[#1b1b1f] px-2 py-1 rounded"
                >
                  Törlés
                </button>
              )}
              <kbd className="hidden sm:inline-block bg-[#1b1b1f] border border-[#28282d] text-[10px] font-mono text-[#8c8c94] px-2 py-1 rounded">
                ESC
              </kbd>
            </div>

            {/* Results Area */}
            <div className="p-2 overflow-y-auto divide-y divide-[#28282d]/50 space-y-1 min-h-[140px] flex flex-col justify-center">
              {searchQuery.trim() === "" ? (
                /* Initial State: Clean, minimal prompt with no pre-listed results */
                <div className="p-8 text-center space-y-2">
                  <div className="w-10 h-10 rounded-2xl bg-[#1b1b1f] border border-[#28282d] text-[#8c8c94] flex items-center justify-center mx-auto mb-2">
                    <Search size={18} />
                  </div>
                  <p className="text-xs font-semibold text-[#f3f3f6]">Gépelj be egy kifejezést a kereséshez</p>
                  <p className="text-[11px] text-[#5f5f67]">
                    Kereshetsz operációs rendszerre (pl. <code className="text-[#ff8800]">windows</code>, <code className="text-[#ff8800]">android</code>, <code className="text-[#ff8800]">linux</code>), parancsokra (<code className="text-[#ff8800]">--demo</code>), vagy adatvédelemre (<code className="text-[#ff8800]">gdpr</code>).
                  </p>
                </div>
              ) : filteredResults.length > 0 ? (
                /* Dynamic Results State */
                filteredResults.map((item, idx) => {
                  const isSelected = idx === selectedIndex;
                  return (
                    <button
                      key={item.id}
                      onClick={() => selectPage(item.pageId, item.tabId)}
                      onMouseEnter={() => setSelectedIndex(idx)}
                      className={`w-full text-left p-3.5 rounded-xl transition-all flex items-center justify-between group ${
                        isSelected
                          ? "bg-[#ff8800]/15 border border-[#ff8800]/40 shadow-[0_0_15px_rgba(255,136,0,0.1)]"
                          : "hover:bg-[#1b1b1f] border border-transparent"
                      }`}
                    >
                      <div className="space-y-1 pr-4">
                        <div className="flex items-center gap-2">
                          <span className="text-[10px] font-bold text-[#ff8800] uppercase tracking-wider bg-[#ff8800]/10 px-1.5 py-0.5 rounded">
                            {item.category}
                          </span>
                          <h4 className="text-xs font-bold text-[#f3f3f6] group-hover:text-[#ff8800] transition-colors">
                            {item.title}
                          </h4>
                        </div>
                        <p className="text-[11px] text-[#8c8c94] line-clamp-1">
                          {item.description}
                        </p>
                      </div>

                      <div className="shrink-0 flex items-center text-[#8c8c94] group-hover:text-[#ff8800]">
                        <CornerDownLeft size={14} className={isSelected ? "text-[#ff8800]" : "opacity-0 group-hover:opacity-100"} />
                      </div>
                    </button>
                  );
                })
              ) : (
                /* No Results State */
                <div className="p-8 text-center space-y-2">
                  <p className="text-xs text-[#8c8c94]">Nincs találat a következőre: <strong className="text-[#f3f3f6]">„{searchQuery}”</strong></p>
                  <p className="text-[11px] text-[#5f5f67]">Próbálj más kulcsszót keresni (pl. <code className="text-[#ff8800]">windows</code>, <code className="text-[#ff8800]">jegyek</code>, <code className="text-[#ff8800]">gdpr</code>, <code className="text-[#ff8800]">config</code>)</p>
                </div>
              )}
            </div>

            {/* Modal Footer Keybind Hints */}
            <div className="p-3 border-t border-[#28282d] bg-[#111114] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span><kbd className="bg-[#1b1b1f] px-1.5 py-0.5 rounded text-[#f3f3f6]">↑↓</kbd> Navigáció</span>
                <span><kbd className="bg-[#1b1b1f] px-1.5 py-0.5 rounded text-[#f3f3f6]">↵</kbd> Megnyitás</span>
                <span><kbd className="bg-[#1b1b1f] px-1.5 py-0.5 rounded text-[#f3f3f6]">ESC</kbd> Bezárás</span>
              </div>
              <span className="text-[#5f5f67]">Pala Dokumentáció Kereső</span>
            </div>
          </div>
        </div>
      )}

      {/* Top Sticky Header Navbar */}
      <header className="sticky top-0 z-40 bg-[#151518]/90 backdrop-blur-md border-b border-[#28282d] h-[70px] flex items-center px-4 sm:px-6 w-full shrink-0">
        <div className="max-w-7xl mx-auto w-full flex items-center justify-between">
          <div className="flex items-center gap-3 sm:gap-6">
            <Link href="/" className="flex items-center gap-3 group">
              <img
                src="/logo.svg"
                alt="Pala logó"
                width={40}
                height={40}
                className="w-10 h-10 rounded-xl shadow-[0_0_15px_rgba(255,136,0,0.25)] transition-transform group-hover:scale-105 object-contain"
              />
              <div className="flex flex-col">
                <span className="font-extrabold text-base tracking-wide text-[#f3f3f6] flex items-center gap-2">
                  PALA
                  <span className="text-[10px] font-bold bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 px-1.5 py-0.5 rounded min-w-[36px] text-center">
                    {release.isLoading ? "..." : release.version}
                  </span>
                </span>
                <span className="text-[11px] font-semibold text-[#8c8c94]">Dokumentáció</span>
              </div>
            </Link>
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            {/* Quick Search Button / Box - Opens Command Palette */}
            <button
              ref={searchTriggerRef}
              onClick={() => setSearchModalOpen(true)}
              className="relative flex items-center justify-between bg-[#151518] hover:bg-[#1b1b1f] border border-[#28282d] hover:border-[#ff8800]/50 rounded-xl px-2.5 sm:px-3 py-1.5 text-xs text-[#8c8c94] transition-all cursor-pointer group shadow-sm max-w-[150px] sm:max-w-[240px] lg:w-64"
              aria-label="Dokumentáció kereső megnyitása"
            >
              <div className="flex items-center gap-1.5 sm:gap-2 truncate">
                <Search size={14} className="text-[#8c8c94] group-hover:text-[#ff8800] transition-colors shrink-0" />
                <span className="truncate hidden sm:inline">Keresés a docsban...</span>
                <span className="truncate sm:hidden">Keresés...</span>
              </div>
              <kbd className="hidden sm:inline-block bg-[#1b1b1f] border border-[#28282d] text-[10px] font-mono text-[#8c8c94] group-hover:text-[#f3f3f6] px-1.5 py-0.5 rounded shrink-0">
                Ctrl K
              </kbd>
            </button>

            <Link
              href="/"
              className="hidden sm:inline-flex items-center gap-1.5 bg-[#1b1b1f] hover:bg-[#222227] text-[#8c8c94] hover:text-[#f3f3f6] border border-[#28282d] text-xs font-bold px-3.5 py-2 rounded-xl transition-colors"
            >
              <ArrowLeft size={13} />
              <span>Főoldal</span>
            </Link>

            <a
              href="https://github.com/CsPS0/pala"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:flex bg-[#1b1b1f] hover:bg-[#222227] border border-[#28282d] text-xs font-bold text-[#f3f3f6] px-3.5 py-2 rounded-xl transition-all items-center gap-1.5"
            >
              <span>GitHub</span>
              <ExternalLink size={12} className="text-[#8c8c94]" />
            </a>

            {/* Mobile Navigation Drawer Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden bg-[#1b1b1f] border border-[#28282d] text-[#f3f3f6] p-2 rounded-xl"
              aria-label="Menü"
              aria-expanded={mobileMenuOpen}
            >
              {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div
          className="md:hidden fixed inset-0 top-[70px] z-50 bg-[#0e0e11]/98 backdrop-blur-xl p-6 overflow-y-auto border-b border-[#28282d]"
          onClick={() => setMobileMenuOpen(false)}
        >
          <nav className="space-y-6 max-w-sm mx-auto" onClick={(e) => e.stopPropagation()}>
            {navCategories.map((group, gIdx) => (
              <div key={gIdx}>
                <h4 className="text-[11px] font-black uppercase tracking-wider text-[#ff8800] mb-2 px-1">
                  {group.category}
                </h4>
                <div className="space-y-1">
                  {group.items.map((item) => {
                    const IconComp = item.icon;
                    const isActive = activePage === item.id;
                    return (
                      <button
                        key={item.id}
                        onClick={() => selectPage(item.id)}
                        className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-bold transition-all text-left ${
                          isActive
                            ? "bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 shadow-[0_0_15px_rgba(255,136,0,0.15)]"
                            : "text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#1b1b1f]"
                        }`}
                      >
                        <IconComp size={16} className={isActive ? "text-[#ff8800]" : "text-[#8c8c94]"} />
                        <span>{item.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </nav>
        </div>
      )}

      {/* Main Documentation Container */}
      <div className="max-w-7xl mx-auto w-full flex-1 flex items-start px-3 sm:px-6 py-6 sm:py-8 gap-6 sm:gap-10 min-w-0">
        {/* Left Sticky Sidebar */}
        <aside className="w-64 shrink-0 hidden md:block sticky top-[95px] h-[calc(100vh-120px)] overflow-y-auto pr-2 self-start">
          <nav className="space-y-6">
            {navCategories.map((group, gIdx) => (
              <div key={gIdx}>
                <h4 className="text-[11px] font-black uppercase tracking-wider text-[#ff8800] mb-2 px-3">
                  {group.category}
                </h4>
                <div className="space-y-1">
                  {group.items.map((item) => {
                    const IconComp = item.icon;
                    const isActive = activePage === item.id;
                    return (
                      <button
                        key={item.id}
                        onClick={() => selectPage(item.id)}
                        className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-bold transition-all text-left ${
                          isActive
                            ? "bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 shadow-[0_0_15px_rgba(255,136,0,0.15)]"
                            : "text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#1b1b1f]"
                        }`}
                      >
                        <IconComp size={15} className={isActive ? "text-[#ff8800]" : "text-[#8c8c94]"} />
                        <span className="truncate">{item.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}
          </nav>
        </aside>

        {/* Center Main Content Area */}
        <main className="flex-1 max-w-4xl pb-24 space-y-8 min-w-0 w-full overflow-hidden min-h-[80vh]">
          {/* ================= PAGE: INSTALLATION ================= */}
          {activePage === "installation" && (
            <div className="space-y-8 animate-fadeIn min-w-0 w-full">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  GETTING STARTED / INSTALLATION
                </span>
                <h1 className="text-2xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Telepítés és Beállítás
                </h1>
                <p className="text-xs sm:text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  A Pala elérhető asztali rendszerekre (Windows, Linux, macOS), mobilra (Android) és böngészőbővítményként.
                  Válassz platformot a lépésről lépésre követhető telepítési és eltávolítási útmutatóhoz.
                </p>
              </div>

              {/* Internal Horizontal Tab Navbar with OS priority */}
              <div className="w-full border-b border-[#28282d] flex items-center gap-1 sm:gap-2 overflow-x-auto no-scrollbar pb-px min-w-0">
                {installTabs.map((tab) => {
                  const isActive = installTab === tab.id;
                  const isDetected = tab.id === detectedOS;
                  const TabIcon = tab.icon;
                  return (
                    <button
                      key={tab.id}
                      onClick={() => setInstallTab(tab.id)}
                      className={`shrink-0 px-3.5 py-2 text-xs font-bold transition-all border-b-2 cursor-pointer flex items-center gap-2 ${
                        isActive
                          ? "border-[#ff8800] text-[#ff8800] bg-[#ff8800]/10 rounded-t-xl"
                          : "border-transparent text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#1b1b1f]"
                      }`}
                    >
                      <TabIcon size={14} className={isActive ? "text-[#ff8800]" : "text-[#8c8c94]"} />
                      <span>{tab.label}</span>
                      {isDetected && (
                        <span className="text-[9px] bg-[#30d158]/20 text-[#30d158] border border-[#30d158]/30 px-1.5 py-0.2 rounded font-mono font-black">
                          Ajánlott
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>

              {/* ================= TAB 1: WINDOWS (.exe & PowerShell & Scoop) ================= */}
              {installTab === "windows" && (
                <div className="space-y-8">
                  <p className="text-xs text-[#8c8c94]">
                    Telepítés Windows 10 és Windows 11 rendszerekre grafikus telepítővel, PowerShell parancssorból vagy Scoop csomagkezelővel.
                  </p>

                  {/* Step 1: Download / PowerShell / Scoop */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 01 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Telepítési módszer kiválasztása</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        <strong>„A” opció (Grafikus):</strong> Töltsd le az öntelepítő <code className="text-[#ff8800] font-mono">Pala-Setup.exe</code> fájlt.<br />
                        <strong>„B” opció (PowerShell):</strong> Futtasd a hivatalos telepítőt terminálban.<br />
                        <strong>„C” opció (Scoop):</strong> Telepítsd Scoop csomagkezelővel.
                      </p>
                    </div>
                    <div className="lg:col-span-7 space-y-3">
                      {/* Option A Card */}
                      <div className="bg-[#1b1b1f] border border-[#28282d] rounded-2xl p-4 flex items-center justify-between">
                        <div>
                          <div className="text-xs font-bold text-[#f3f3f6]">„A” Opció: Pala-Setup.exe (Grafikus)</div>
                          <div className="text-[11px] text-[#5f5f67]">Inno Setup • Komponensválasztó (GUI + TUI + PATH)</div>
                        </div>
                        <a
                          href={release.assets.windowsExe}
                          className="inline-flex items-center gap-1.5 bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-xs px-4 py-2 rounded-xl transition-all shadow-[0_0_15px_rgba(255,136,0,0.2)]"
                        >
                          <Download size={13} />
                          <span>Letöltés</span>
                        </a>
                      </div>

                      {/* Option B Card (PowerShell) */}
                      <div className="bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                        <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                          <span>„B” Opció: PowerShell 1-soros Telepítő</span>
                          <button
                            onClick={() => handleCopy("irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex", "win-ps1")}
                            className="hover:text-[#f3f3f6] transition-colors"
                          >
                            {copiedKey === "win-ps1" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                          </button>
                        </div>
                        <div className="p-3.5 font-mono text-xs text-[#ff8800]">
                          irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex
                        </div>
                      </div>

                      {/* Option C Card (Scoop) */}
                      <div className="bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                        <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                          <span>„C” Opció: Scoop Csomagkezelő</span>
                          <button
                            onClick={() => handleCopy("scoop bucket add pala https://github.com/CsPS0/pala-bucket; scoop install pala", "win-scoop")}
                            className="hover:text-[#f3f3f6] transition-colors"
                          >
                            {copiedKey === "win-scoop" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                          </button>
                        </div>
                        <div className="p-3.5 font-mono text-xs text-[#ff8800] space-y-1">
                          <div>scoop bucket add pala https://github.com/CsPS0/pala-bucket</div>
                          <div>scoop install pala</div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Step 2: Install & SmartScreen */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 02 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Telepítés & SmartScreen engedélyezés</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        Futtasd a letöltött exe fájlt vagy szkriptet. Ha a Windows SmartScreen figyelmeztetést ad (*„A Windows védelmet biztosított...”*), kattints a <strong>„További információ”</strong>, majd a <strong>„Futtatás mindenképpen”</strong> gombra.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                      <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                        <span>Windows Defender SmartScreen</span>
                        <AlertTriangle size={13} className="text-[#ffd60a]" />
                      </div>
                      <div className="p-3.5 text-xs text-[#8c8c94] space-y-1 font-sans">
                        <div className="text-[#f3f3f6] font-semibold">1. Kattints: „További információ” (More info)</div>
                        <div className="text-[#30d158] font-semibold">2. Kattints: „Futtatás mindenképpen” (Run anyway)</div>
                      </div>
                    </div>
                  </div>

                  {/* Step 3: Launch */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 03 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Indítás & Használat</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        Indítsd a Start menüből a <strong>Pala Desktop</strong> ikonnal vagy a parancssorból a <code className="text-[#ff8800] font-mono">pala</code> paranccsal.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                      <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                        <span>PowerShell / Terminal Parancsok</span>
                        <button
                          onClick={() => handleCopy("pala", "win-launch")}
                          className="hover:text-[#f3f3f6] transition-colors"
                        >
                          {copiedKey === "win-launch" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                        </button>
                      </div>
                      <div className="p-3.5 font-mono text-xs text-[#ff8800] space-y-1">
                        <div>pala <span className="text-[#5f5f67]"># Terminálos TUI indítása</span></div>
                        <div>pala --desktop <span className="text-[#5f5f67]"># Asztali GUI indítása</span></div>
                      </div>
                    </div>
                  </div>

                  {/* Step 4: Integrated Windows Component Management & Uninstallation */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start border-t border-[#28282d] pt-6">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff453a]">[ 04 ]</span>
                        <h3 className="text-sm font-bold text-[#ff453a] flex items-center gap-1.5">
                          <Trash2 size={14} />
                          <span>Komponens Kezelés & Eltávolítás</span>
                        </h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        A telepített komponensek (parancsikonok, PATH környezeti változó, gyorsítótár) kezelése és eltávolítása.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden divide-y divide-[#28282d] text-xs">
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">Interaktív eltávolító menü:</strong>
                        <div className="font-mono text-[#ff8800]">pala --uninstall</div>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">Parancsikonok kezelése:</strong>
                        <div className="font-mono text-[#ff8800]">pala --install-shortcut <span className="text-[#5f5f67]"># Létrehozás</span></div>
                        <div className="font-mono text-[#ff8800]">pala --remove-shortcut <span className="text-[#5f5f67]"># Törlés</span></div>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">PATH környezeti változó kezelése:</strong>
                        <div className="font-mono text-[#ff8800]">pala --add-path <span className="text-[#5f5f67]"># Hozzáadás</span></div>
                        <div className="font-mono text-[#ff8800]">pala --remove-path <span className="text-[#5f5f67]"># Eltávolítás</span></div>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">Grafikus eltávolítás (.exe):</strong>
                        <span className="text-[#8c8c94]">Gépház &gt; Alkalmazások &gt; Telepített alkalmazások &gt; Pala &gt; Eltávolítás</span>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">Helyi gyorsítótár és bejelentkezés törlése:</strong>
                        <div className="font-mono text-[#ff8800]">pala --clear-cache</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* ================= TAB 2: ANDROID (APK & Emulátor) ================= */}
              {installTab === "android" && (
                <div className="space-y-8">
                  <p className="text-xs text-[#8c8c94]">
                    Közvetlen APK telepítés Android okostelefonokra, régebbi készülékekre, táblagépekre és PC emulátorokra (Google Play mentes, közvetlen frissítések).
                  </p>

                  {/* Architecture Grid (4 options) */}
                  <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-4">
                    <div className="flex items-center justify-between">
                      <h3 className="text-sm font-bold text-[#f3f3f6] flex items-center gap-2">
                        <Cpu size={16} className="text-[#ff8800]" />
                        <span>Melyik APK-t válaszd? (Architektúra útmutató)</span>
                      </h3>
                      <span className="text-[11px] text-[#8c8c94]">4 elérhető csomag</span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      {/* Option 1: Universal */}
                      <div className="p-4 rounded-xl bg-[#151518] border border-[#30d158]/50 space-y-2 relative overflow-hidden">
                        <div className="flex items-center justify-between">
                          <strong className="text-xs text-[#30d158] font-bold">1. Universal (Minden eszközre)</strong>
                          <span className="text-[10px] bg-[#30d158]/15 text-[#30d158] px-2 py-0.5 rounded font-bold">100% Biztos</span>
                        </div>
                        <code className="text-xs text-[#ff8800] font-mono block">app-release.apk</code>
                        <p className="text-[11px] text-[#8c8c94] leading-relaxed">
                          <strong>Ha bizonytalan vagy:</strong> minden processzort és emulátort magában foglal, így kivétel nélkül <em>minden Android eszközön azonnal elindul!</em>
                        </p>
                      </div>

                      {/* Option 2: ARM64 */}
                      <div className="p-4 rounded-xl bg-[#151518] border border-[#ff8800]/40 space-y-2">
                        <div className="flex items-center justify-between">
                          <strong className="text-xs text-[#ff8800] font-bold">2. ARM64-v8a (Modern telefonok)</strong>
                          <span className="text-[10px] bg-[#ff8800]/10 text-[#ff8800] px-2 py-0.5 rounded font-bold">Leggyorsabb</span>
                        </div>
                        <code className="text-xs text-[#ff8800] font-mono block">app-arm64-v8a-release.apk</code>
                        <p className="text-[11px] text-[#8c8c94] leading-relaxed">
                          Minden 2016 után gyártott 64-bites telefonhoz és táblagéphez (Samsung Galaxy, Xiaomi, Pixel, Redmi, Honor, OnePlus).
                        </p>
                      </div>

                      {/* Option 3: ARMv7 / 32-bit (Older phones) */}
                      <div className="p-4 rounded-xl bg-[#151518] border border-[#28282d] space-y-2">
                        <div className="flex items-center justify-between">
                          <strong className="text-xs text-[#f3f3f6] font-bold">3. ARMv7 / armeabi (Régebbi telefonok)</strong>
                          <span className="text-[10px] bg-[#222227] text-[#8c8c94] px-2 py-0.5 rounded font-bold">32-bit</span>
                        </div>
                        <code className="text-xs text-[#ff8800] font-mono block">app-armeabi-v7a-release.apk</code>
                        <p className="text-[11px] text-[#8c8c94] leading-relaxed">
                          Régebbi (2015 előtti) okostelefonokhoz, régebbi táblagépekhez vagy 32-bites belépőszintű készülékekhez.
                        </p>
                      </div>

                      {/* Option 4: x86_64 (Emulators & PC) */}
                      <div className="p-4 rounded-xl bg-[#151518] border border-[#28282d] space-y-2">
                        <div className="flex items-center justify-between">
                          <strong className="text-xs text-[#0a84ff] font-bold">4. x86_64 (PC Emulátorok)</strong>
                          <span className="text-[10px] bg-[#0a84ff]/10 text-[#0a84ff] px-2 py-0.5 rounded font-bold">Emulátor</span>
                        </div>
                        <code className="text-xs text-[#ff8800] font-mono block">app-x86_64-release.apk</code>
                        <p className="text-[11px] text-[#8c8c94] leading-relaxed">
                          PC-n futó Android emulátorokhoz (BlueStacks 5, NoxPlayer, LDPlayer, WSA Windows Subsystem for Android, Android Studio).
                        </p>
                      </div>
                    </div>

                    {/* How to check if user has no idea */}
                    <div className="p-4 rounded-xl bg-[#111114] border border-[#28282d] space-y-2 text-xs">
                      <strong className="text-[#f3f3f6] block">Hogyan válassz, ha fogalmad sincs a telefonod típusáról?</strong>
                      <ol className="list-decimal pl-4 space-y-1 text-[#8c8c94]">
                        <li><span className="text-[#30d158] font-bold">1. Aranyszabály:</span> Töltsd le az <strong>Universal</strong> (<code className="text-[#ff8800] font-mono">app-release.apk</code>) csomagot. Ez garantáltan működni fog!</li>
                        <li><strong>2. Szabály:</strong> Ha a telefonod az elmúlt 7-8 évben vásároltad, válaszd az <strong>ARM64</strong> verziót a legkisebb méretért és legnagyobb sebességért.</li>
                        <li><strong>3. Ellenőrzés appal:</strong> Töltsd le a Play Áruházból a díjmentes <em>CPU-Z</em> vagy <em>AIDA64</em> alkalmazást, és a "System / Processzor" menüben nézd meg az <em>Instruction Set</em> sort.</li>
                      </ol>
                    </div>
                  </div>

                  {/* Step 1: Download */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 01 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">APK Letöltése</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        Töltsd le a telefonod böngészőjében az APK fájlt a GitHub Kiadásokból.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#1b1b1f] border border-[#28282d] rounded-2xl p-4 flex items-center justify-between">
                      <div>
                        <div className="text-xs font-bold text-[#f3f3f6]">Pala Mobile APK-k</div>
                        <div className="text-[11px] text-[#5f5f67]">{release.version} • Android 7.0+ támogatás</div>
                      </div>
                      <a
                        href={release.assets.androidUniversal}
                        className="inline-flex items-center gap-1.5 bg-[#30d158] hover:bg-[#3be065] text-black font-extrabold text-xs px-4 py-2 rounded-xl transition-all shadow-[0_0_15px_rgba(48,209,88,0.2)]"
                      >
                        <Download size={13} />
                        <span>Közvetlen Letöltés</span>
                      </a>
                    </div>
                  </div>

                  {/* Step 2: Install */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 02 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Külső források engedélyezése</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        Nyisd meg a letöltött fájlt és engedélyezd a külső APK telepítését a böngészőnek / fájlkezelőnek.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl p-4 space-y-1.5 text-xs text-[#8c8c94]">
                      <div className="text-[#f3f3f6] font-semibold">1. Kattints: „Beállítások” a felugró értesítésben</div>
                      <div className="text-[#ff8800] font-semibold">2. Kapcsold be: „Engedélyezés ebből a forrásból”</div>
                      <div className="text-[#30d158] font-semibold">3. Kattints a „Telepítés” gombra</div>
                    </div>
                  </div>

                  {/* Step 3: Integrated Android Uninstallation */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start border-t border-[#28282d] pt-6">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff453a]">[ 03 ]</span>
                        <h3 className="text-sm font-bold text-[#ff453a] flex items-center gap-1.5">
                          <Trash2 size={14} />
                          <span>Eltávolítás & Tárhely Törlése</span>
                        </h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        Az Android alkalmazás és a titkosított helyi SQLite adatbázis törlése a telefonról.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl p-4 space-y-2 text-xs text-[#8c8c94]">
                      <div className="text-[#f3f3f6] font-semibold">1. Hosszan nyomj a kezdőképernyőn a Pala ikonra</div>
                      <div className="text-[#8c8c94]">2. Válaszd az <strong>Alkalmazásinfó (i)</strong> lehetőséget</div>
                      <div className="text-[#ff8800]">3. <strong>Tárhely és gyorsítótár</strong> &gt; Kattints a <strong>„Tárhely törlése”</strong> gombra</div>
                      <div className="text-[#ff453a] font-semibold">4. Nyomj az <strong>Eltávolítás (Uninstall)</strong> gombra</div>
                    </div>
                  </div>
                </div>
              )}

              {/* ================= TAB 3: IOS (iPhone & iPad) ================= */}
              {installTab === "ios" && (
                <div className="space-y-8">
                  <p className="text-xs text-[#8c8c94]">
                    Telepítés iPhone és iPad készülékekre Sideloading (AltStore, SideStore, TrollStore) módszerrel vagy Safari Főképernyőhöz adással.
                  </p>

                  {/* Step 1: Methods */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 01 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Telepítési módszer kiválasztása</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        <strong>„A” opció (Sideloading):</strong> Natív .ipa fájl telepítése AltStore / SideStore segítségével (ingyenes Apple ID-val, nem igényel Jailbreaket).<br />
                        <strong>„B” opció (Safari PWA):</strong> Közvetlen Főképernyőhöz adás alkalmazásként.
                      </p>
                    </div>
                    <div className="lg:col-span-7 space-y-3">
                      {/* Option A: Sideloading */}
                      <div className="bg-[#1b1b1f] border border-[#28282d] rounded-2xl p-4 space-y-2">
                        <div className="flex items-center justify-between">
                          <strong className="text-xs font-bold text-[#f3f3f6]">„A” Opció: Sideloading (.ipa csomag)</strong>
                          <span className="text-[10px] bg-[#ff8800]/15 text-[#ff8800] px-2 py-0.5 rounded font-bold">Natív IPA</span>
                        </div>
                        <p className="text-[11px] text-[#8c8c94] leading-relaxed">
                          1. Töltsd le a legfrissebb <code className="text-[#ff8800] font-mono">Pala.ipa</code> fájlt a GitHub Kiadásokból.<br />
                          2. Nyisd meg a telefonodon az <strong>AltStore</strong> vagy <strong>SideStore</strong> alkalmazást.<br />
                          3. Kattints a <strong>„+”</strong> gombra és válaszd ki a letöltött IPA fájlt.
                        </p>
                        <a
                          href="https://github.com/CsPS0/pala/releases/latest"
                          className="inline-flex items-center gap-1.5 bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-xs px-4 py-2 rounded-xl transition-all shadow-[0_0_15px_rgba(255,136,0,0.2)] mt-1"
                        >
                          <Download size={13} />
                          <span>IPA Letöltése</span>
                        </a>
                      </div>

                      {/* Option B: Safari Home Screen */}
                      <div className="bg-[#151518] border border-[#28282d] rounded-2xl p-4 space-y-1.5 text-xs text-[#8c8c94]">
                        <strong className="text-[#f3f3f6] block">„B” Opció: Safari Főképernyőhöz adás (PWA)</strong>
                        <p className="text-[11px] leading-relaxed">
                          1. Nyisd meg Safariban a Pala webes felületét.<br />
                          2. Érintsd meg a <strong>Megosztás</strong> ikont (négyzetből felfelé mutató nyíl).<br />
                          3. Válaszd a <strong>„Főképernyőhöz adás”</strong> (Add to Home Screen) lehetőséget.
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* Step 2: Integrated iOS Uninstallation */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start border-t border-[#28282d] pt-6">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff453a]">[ 02 ]</span>
                        <h3 className="text-sm font-bold text-[#ff453a] flex items-center gap-1.5">
                          <Trash2 size={14} />
                          <span>Eltávolítás iOS alatt</span>
                        </h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        Az alkalmazás és a helyi adatok teljes törlése az iPhone-ról vagy iPad-ről.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl p-4 space-y-1.5 text-xs text-[#8c8c94]">
                      <div className="text-[#f3f3f6] font-semibold">1. Hosszan tartsd nyomva a Pala ikont a Főképernyőn</div>
                      <div className="text-[#ff453a] font-semibold">2. Válaszd az „Alkalmazás törlése” (Delete App) lehetőséget</div>
                      <div className="text-[#8c8c94]">3. Nyomj a „Törlés” gombra a megerősítéshez</div>
                    </div>
                  </div>
                </div>
              )}

              {/* ================= TAB 4: LINUX (Script, APT, AUR) ================= */}
              {installTab === "linux" && (
                <div className="space-y-8">
                  <p className="text-xs text-[#8c8c94]">
                    Válassz a hivatalos univerzális telepítő script, az Ubuntu/Debian APT csomagtár, vagy az Arch Linux AUR csomag közül.
                  </p>

                  {/* Step 1: Choose Method */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 01 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Telepítési módszer kiválasztása</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94] leading-relaxed">
                        <strong>„A” opció (Univerzális):</strong> Automatikus telepítő script minden disztribúcióhoz.<br />
                        <strong>„B” opció (Ubuntu / Debian):</strong> Hivatalos APT csomagtár.<br />
                        <strong>„C” opció (Arch Linux / Manjaro):</strong> AUR csomagkezelő (yay / paru).
                      </p>
                    </div>
                    <div className="lg:col-span-7 space-y-3">
                      {/* Option A: Script */}
                      <div className="bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                        <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                          <span>„A” Opció: Univerzális Script (bash)</span>
                          <button
                            onClick={() => handleCopy("curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash", "linux-script")}
                            className="hover:text-[#f3f3f6] transition-colors"
                          >
                            {copiedKey === "linux-script" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                          </button>
                        </div>
                        <div className="p-3.5 font-mono text-xs text-[#ff8800]">
                          curl -fsSL https://raw.githubusercontent.com/CsPS0/pala/main/install.sh | bash
                        </div>
                      </div>

                      {/* Option B: APT */}
                      <div className="bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                        <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                          <span>„B” Opció: Ubuntu / Debian (APT)</span>
                          <button
                            onClick={() => handleCopy("curl -fsSL https://apt.pala.hu/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/pala.gpg; echo 'deb [signed-by=/etc/apt/trusted.gpg.d/pala.gpg] https://apt.pala.hu stable main' | sudo tee /etc/apt/sources.list.d/pala.list; sudo apt update && sudo apt install pala", "linux-apt")}
                            className="hover:text-[#f3f3f6] transition-colors"
                          >
                            {copiedKey === "linux-apt" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                          </button>
                        </div>
                        <div className="p-3.5 font-mono text-xs text-[#ff8800] space-y-1">
                          <div className="text-[#8c8c94]"># GPG kulcs és csomagtár hozzáadása:</div>
                          <div>curl -fsSL https://apt.pala.hu/gpg.key | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/pala.gpg</div>
                          <div>echo &apos;deb [signed-by=/etc/apt/trusted.gpg.d/pala.gpg] https://apt.pala.hu stable main&apos; | sudo tee /etc/apt/sources.list.d/pala.list</div>
                          <div className="text-[#8c8c94] pt-1"># Telepítés APT-ből:</div>
                          <div>sudo apt update &amp;&amp; sudo apt install pala</div>
                        </div>
                      </div>

                      {/* Option C: AUR */}
                      <div className="bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                        <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                          <span>„C” Opció: Arch Linux (AUR)</span>
                          <button
                            onClick={() => handleCopy("yay -S pala-bin", "linux-aur")}
                            className="hover:text-[#f3f3f6] transition-colors"
                          >
                            {copiedKey === "linux-aur" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                          </button>
                        </div>
                        <div className="p-3.5 font-mono text-xs text-[#ff8800] space-y-1">
                          <div>yay -S pala-bin <span className="text-[#5f5f67]"># vagy: paru -S pala-bin</span></div>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Step 2: Run */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 02 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Indítás & Használat</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        A sikeres telepítést követően a program a terminálból azonnal elindítható.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                      <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                        <span>Terminal (bash)</span>
                        <button
                          onClick={() => handleCopy("pala", "linux-run")}
                          className="hover:text-[#f3f3f6] transition-colors"
                        >
                          {copiedKey === "linux-run" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                        </button>
                      </div>
                      <div className="p-3.5 font-mono text-xs text-[#ff8800]">
                        pala <span className="text-[#5f5f67]"># Kréta TUI felület indítása</span>
                      </div>
                    </div>
                  </div>

                  {/* Step 3: Integrated Linux Uninstallation */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start border-t border-[#28282d] pt-6">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff453a]">[ 03 ]</span>
                        <h3 className="text-sm font-bold text-[#ff453a] flex items-center gap-1.5">
                          <Trash2 size={14} />
                          <span>Eltávolítás Linux alatt</span>
                        </h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        A kiválasztott telepítési módszernek megfelelő eltávolító parancs és a gyorsítótár ürítése.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden divide-y divide-[#28282d] text-xs">
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">Script eltávolítás:</strong>
                        <div className="font-mono text-[#ff8800]">sudo rm -f /usr/local/bin/pala</div>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">APT eltávolítás (Ubuntu/Debian):</strong>
                        <div className="font-mono text-[#ff8800]">sudo apt remove --purge pala</div>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">AUR eltávolítás (Arch):</strong>
                        <div className="font-mono text-[#ff8800]">yay -R pala-bin</div>
                      </div>
                      <div className="p-3 space-y-1">
                        <strong className="text-[#f3f3f6] block">Helyi adatok és tokenek törlése:</strong>
                        <div className="font-mono text-[#ff453a]">rm -rf ~/.config/pala ~/.local/share/pala</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* ================= TAB 5: MACOS (Homebrew) ================= */}
              {installTab === "macos" && (
                <div className="space-y-8">
                  <p className="text-xs text-[#8c8c94]">
                    Telepítés Homebrew segítségével Apple Silicon (M1/M2/M3/M4) és Intel Mac számítógépekre.
                  </p>

                  {/* Step 1 */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 01 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Homebrew Telepítés</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        Futtasd a brew parancsot a Terminálban a csomag letöltéséhez és aktiválásához.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                      <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                        <span>Terminal (zsh)</span>
                        <button
                          onClick={() => handleCopy("brew install CsPS0/pala/pala", "mac-cmd")}
                          className="hover:text-[#f3f3f6] transition-colors"
                        >
                          {copiedKey === "mac-cmd" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                        </button>
                      </div>
                      <div className="p-3.5 font-mono text-xs text-[#ff8800]">
                        brew install CsPS0/pala/pala
                      </div>
                    </div>
                  </div>

                  {/* Step 2: Integrated macOS Uninstallation */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start border-t border-[#28282d] pt-6">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff453a]">[ 02 ]</span>
                        <h3 className="text-sm font-bold text-[#ff453a] flex items-center gap-1.5">
                          <Trash2 size={14} />
                          <span>Eltávolítás macOS alatt</span>
                        </h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        A csomag és a helyi kulcstár adatok törlése Homebrew segítségével.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl overflow-hidden">
                      <div className="px-3.5 py-2 bg-[#0e0e11] border-b border-[#28282d] text-[11px] font-mono text-[#8c8c94] flex items-center justify-between">
                        <span>Terminal (zsh)</span>
                        <button
                          onClick={() => handleCopy("brew uninstall pala; rm -rf ~/Library/Application\ Support/pala", "mac-uninst")}
                          className="hover:text-[#f3f3f6] transition-colors"
                        >
                          {copiedKey === "mac-uninst" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                        </button>
                      </div>
                      <div className="p-3.5 font-mono text-xs text-[#ff453a] space-y-1">
                        <div>brew uninstall pala</div>
                        <div>rm -rf ~/Library/Application\ Support/pala</div>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {/* ================= TAB 6: BROWSER EXTENSION ================= */}
              {installTab === "extension" && (
                <div className="space-y-8">
                  <p className="text-xs text-[#8c8c94]">
                    Manifest V3 böngészőbővítmény Chrome, Edge, Brave, Opera és Firefox böngészőkhöz.
                  </p>

                  {/* Step 1 */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff8800]">[ 01 ]</span>
                        <h3 className="text-sm font-bold text-[#f3f3f6]">Bővítmény Kicsomagolása & Betöltése</h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        Töltsd le a <code className="text-[#ff8800] font-mono">pala-extension.zip</code> fájlt, majd töltsd be a böngésződ bővítménykezelőjében.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl p-4 space-y-2 text-xs text-[#8c8c94]">
                      <div className="text-[#f3f3f6] font-semibold">1. Nyisd meg: chrome://extensions/ vagy edge://extensions/</div>
                      <div className="text-[#ff8800] font-semibold">2. Kapcsold be a jobb felső sarokban a Fejlesztői módot</div>
                      <div className="text-[#30d158] font-semibold">3. Kattints a „Kicsomagolt betöltése” (Load unpacked) gombra</div>
                    </div>
                  </div>

                  {/* Step 2: Extension Uninstallation */}
                  <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start border-t border-[#28282d] pt-6">
                    <div className="lg:col-span-5 space-y-1.5">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-black text-[#ff453a]">[ 02 ]</span>
                        <h3 className="text-sm font-bold text-[#ff453a] flex items-center gap-1.5">
                          <Trash2 size={14} />
                          <span>Bővítmény Eltávolítása</span>
                        </h3>
                      </div>
                      <p className="text-xs text-[#8c8c94]">
                        A bővítmény és a tárolt helyi cookie-k azonnali eltávolítása.
                      </p>
                    </div>
                    <div className="lg:col-span-7 bg-[#151518] border border-[#28282d] rounded-2xl p-4 space-y-1 text-xs text-[#8c8c94]">
                      <div className="text-[#f3f3f6] font-semibold">1. Kattints jobb gombbal a Pala bővítmény ikonra az eszköztáron</div>
                      <div className="text-[#ff453a] font-semibold">2. Válaszd az „Eltávolítás a Chrome-ból...” (Remove from Chrome) menüpontot</div>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ================= PAGE: COMPATIBILITY ================= */}
          {activePage === "compatibility" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  GETTING STARTED / COMPATIBILITY
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Kompatibilitás és Rendszerkövetelmények
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  A Pala célja a lehető legszélesebb körű elérhetőség régebbi és legújabb eszközökön egyaránt.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-[#f3f3f6] font-bold text-sm">
                    <Monitor size={16} className="text-[#ff8800]" />
                    <span>Asztali Rendszerek</span>
                  </div>
                  <ul className="text-xs text-[#8c8c94] space-y-1.5 list-disc pl-4">
                    <li><strong className="text-[#f3f3f6]">Windows</strong>: Windows 10 (1809+) és Windows 11 (64-bit / ARM64)</li>
                    <li><strong className="text-[#f3f3f6]">Linux</strong>: Ubuntu 20.04+, Debian 11+, Arch, Fedora, openSUSE</li>
                    <li><strong className="text-[#f3f3f6]">macOS</strong>: macOS 11.0 (Big Sur) vagy újabb (Apple Silicon & Intel)</li>
                  </ul>
                </div>

                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-[#f3f3f6] font-bold text-sm">
                    <Smartphone size={16} className="text-[#30d158]" />
                    <span>Mobil Rendszerek</span>
                  </div>
                  <ul className="text-xs text-[#8c8c94] space-y-1.5 list-disc pl-4">
                    <li><strong className="text-[#f3f3f6]">Android</strong>: Android 7.0 (Nougat) vagy újabb (ARM64, ARMv7, x86)</li>
                    <li><strong className="text-[#f3f3f6]">iOS / iPadOS</strong>: iOS 14.0 vagy újabb</li>
                  </ul>
                </div>

                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-[#f3f3f6] font-bold text-sm">
                    <Globe size={16} className="text-[#0a84ff]" />
                    <span>Böngészők</span>
                  </div>
                  <ul className="text-xs text-[#8c8c94] space-y-1.5 list-disc pl-4">
                    <li>Google Chrome 88+</li>
                    <li>Microsoft Edge 88+</li>
                    <li>Mozilla Firefox 109+</li>
                    <li>Brave, Opera, Vivaldi</li>
                  </ul>
                </div>

                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-[#f3f3f6] font-bold text-sm">
                    <BookOpen size={16} className="text-[#ff8800]" />
                    <span>Támogatott Iskolatípusok</span>
                  </div>
                  <ul className="text-xs text-[#8c8c94] space-y-1.5 list-disc pl-4">
                    <li>Általános iskola & Gimnázium</li>
                    <li>Technikum & Szakgimnázium</li>
                    <li>Szakképző iskola & Kollégium</li>
                    <li>Művészeti és zeneiskola</li>
                  </ul>
                </div>
              </div>
            </div>
          )}

          {/* ================= PAGE: UPGRADE GUIDE ================= */}
          {activePage === "upgrade-guide" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  GETTING STARTED / UPGRADE
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Frissítési Útmutató
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  Hogyan frissíthetsz a legújabb Pala verzióra anélkül, hogy elveszítenéd a beállításaidat vagy a mentett órarendedet.
                </p>
              </div>

              <div className="space-y-6">
                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-3">
                  <h3 className="text-sm font-bold text-[#f3f3f6] flex items-center gap-2">
                    <RefreshCw size={16} className="text-[#ff8800]" />
                    <span>Automatikus verziókövetés & Frissítés:</span>
                  </h3>
                  <div className="space-y-3 text-xs text-[#8c8c94]">
                    <div className="p-3 bg-[#151518] rounded-xl border border-[#28282d]">
                      <strong className="text-[#f3f3f6] block mb-1">Windows (.exe):</strong>
                      Egyszerűen töltsd le és futtasd az új <code className="text-[#ff8800] font-mono">Pala-Setup.exe</code> fájlt. A telepítő felülírja a binárist, de megőrzi a profilodat.
                    </div>
                    <div className="p-3 bg-[#151518] rounded-xl border border-[#28282d]">
                      <strong className="text-[#f3f3f6] block mb-1">Scoop (Windows):</strong>
                      <code className="text-[#ff8800] font-mono">scoop update pala</code>
                    </div>
                    <div className="p-3 bg-[#151518] rounded-xl border border-[#28282d]">
                      <strong className="text-[#f3f3f6] block mb-1">Linux (Script / APT / AUR):</strong>
                      Futtasd az adott csomagkezelő frissítő parancsát: <code className="text-[#ff8800] font-mono">sudo apt update &amp;&amp; sudo apt upgrade pala</code> vagy <code className="text-[#ff8800] font-mono">yay -Syu pala-bin</code>
                    </div>
                    <div className="p-3 bg-[#151518] rounded-xl border border-[#28282d]">
                      <strong className="text-[#f3f3f6] block mb-1">Android APK:</strong>
                      Töltsd le az új APK-t és nyomj a <strong>Frissítés (Update)</strong> gombra. Nem szükséges a korábbi verzió törlése, az adataid megmaradnak.
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ================= PAGE: HASZNALAT ================= */}
          {activePage === "hasznalat" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  FUNKCIÓK / HASZNÁLAT
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Használat és Kezelési Útmutató
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  A Pala indítása, Kréta bejelentkezés, offline mód, naptár exportálás és parancssori kapcsolók.
                </p>
              </div>

              {/* Login & First Steps */}
              <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-4">
                <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                  <Play size={16} className="text-[#ff8800]" />
                  <span>Első Indítás és Bejelentkezés</span>
                </div>
                <p className="text-xs text-[#8c8c94] leading-relaxed">
                  A Pala indításakor bekéri a hivatalos Kréta azonosítóidat:
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 text-xs">
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <strong className="text-[#f3f3f6] block">1. Intézmény Kód</strong>
                    <span className="text-[11px] text-[#8c8c94]">Iskolád Kréta azonosítója (pl. <code className="text-[#ff8800] font-mono">klik039000</code>). A Pala beépített intézménykeresővel is rendelkezik.</span>
                  </div>
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <strong className="text-[#f3f3f6] block">2. Felhasználónév</strong>
                    <span className="text-[11px] text-[#8c8c94]">Általában a 11 jegyű oktatási azonosítód (7-tel kezdődő OM azonosító).</span>
                  </div>
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <strong className="text-[#f3f3f6] block">3. Jelszó</strong>
                    <span className="text-[11px] text-[#8c8c94]">A hivatalos Kréta jelszavad. A jelszót soha nem tároljuk nyers szövegként, kizárólag a titkosított OAuth2 tokent.</span>
                  </div>
                </div>
              </div>

              {/* CLI Command Line Flags */}
              <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-4">
                <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                  <Terminal size={16} className="text-[#ff8800]" />
                  <span>Hasznos Parancssori Kapcsolók (CLI Flags)</span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <code className="text-[#ff8800] font-mono font-bold block">pala --demo</code>
                    <p className="text-[11px] text-[#8c8c94]">Teszt Elek beépített mintafiók indítása valós Kréta kapcsolat nélkül.</p>
                  </div>
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <code className="text-[#ff8800] font-mono font-bold block">pala --clear-cache</code>
                    <p className="text-[11px] text-[#8c8c94]">Minden mentett token és offline adatbázis azonnali törlése.</p>
                  </div>
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <code className="text-[#ff8800] font-mono font-bold block">pala --json</code>
                    <p className="text-[11px] text-[#8c8c94]">Órarend és jegyek kiírása strukturált JSON formátumban scripteknek.</p>
                  </div>
                  <div className="p-3.5 bg-[#151518] border border-[#28282d] rounded-xl space-y-1">
                    <code className="text-[#ff8800] font-mono font-bold block">pala --export-ics</code>
                    <p className="text-[11px] text-[#8c8c94]">Órarend mentése Google Naptárba vagy Outlookba importálható iCal fájlként.</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ================= PAGE: GYORSBILLENTYUK ================= */}
          {activePage === "gyorsbillentyuk" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  FUNKCIÓK / GYORSBILLENTYŰK
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Gyorsbillentyűk (Keybindings)
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  A billentyűzettel villámgyorsan elérheted a Pala összes nézetét és műveletét egér használata nélkül is.
                </p>
              </div>

              {/* Keybinds Table Card */}
              <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-4">
                <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                  <Keyboard size={16} className="text-[#ff8800]" />
                  <span>Navigációs és Kezelési Gyorsbillentyűk</span>
                </div>

                <div className="border border-[#28282d] rounded-xl overflow-hidden divide-y divide-[#28282d] text-xs">
                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Vezérlőpult & Élő Órarend</strong>
                      <span className="text-[11px] text-[#8c8c94]">Mai órák, hátralévő idő és termek megjelenítése</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#ff8800] font-mono font-bold">1 vagy d</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Jegyek & Tantárgyi Átlagok</strong>
                      <span className="text-[11px] text-[#8c8c94]">Minden beírt jegy, súlyozás és tantárgyi lista</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#ff8800] font-mono font-bold">2 vagy g</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Célátlag & Szellem Jegy Kalkulátor</strong>
                      <span className="text-[11px] text-[#8c8c94]">Virtuális jegyek szimulálása a kívánt átlag eléréséhez</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#ff8800] font-mono font-bold">3 vagy c</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">250 Órás Veszélyzóna Figyelő</strong>
                      <span className="text-[11px] text-[#8c8c94]">Hiányzások és igazolások összesítése</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#ff8800] font-mono font-bold">4 vagy a</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Pala Wrapped (Éves Összefoglaló)</strong>
                      <span className="text-[11px] text-[#8c8c94]">Tanulmányi statisztikák és infografika</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#ff8800] font-mono font-bold">w</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Adatok Frissítése (Kréta Sync)</strong>
                      <span className="text-[11px] text-[#8c8c94]">Azonnali lekérdezés a szerverről</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#30d158] font-mono font-bold">r</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Panelek közötti váltás</strong>
                      <span className="text-[11px] text-[#8c8c94]">Fókusz mozgatása az órarend és jegyoszlopok között</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#f3f3f6] font-mono font-bold">Tab / Shift+Tab</kbd>
                  </div>

                  <div className="p-3.5 bg-[#151518] flex items-center justify-between">
                    <div>
                      <strong className="text-[#f3f3f6] block">Kilépés a programból</strong>
                      <span className="text-[11px] text-[#8c8c94]">Tiszta leállás</span>
                    </div>
                    <kbd className="bg-[#0e0e11] border border-[#28282d] px-2.5 py-1 rounded text-[#ff453a] font-mono font-bold">q vagy Esc</kbd>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ================= PAGE: FILES & CONFIGS ================= */}
          {activePage === "files-configs" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  FUNKCIÓK / FÁJLOK & KONFIGURÁCIÓK
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Fájlok és Konfigurációk (Files & Configs)
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  Hol tárolja a Pala a konfigurációt, a titkosított session tokeneket és az offline adatbázist az egyes operációs rendszereken, valamint hogyan szerkesztheted őket manuálisan.
                </p>
              </div>

              {/* OS Directory Table */}
              <div className="space-y-4">
                <h3 className="text-sm font-bold text-[#f3f3f6] flex items-center gap-2">
                  <FolderTree size={16} className="text-[#ff8800]" />
                  <span>Elérési Utak Rendszerenként</span>
                </h3>

                {/* Windows Card */}
                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-3">
                  <div className="flex items-center justify-between">
                    <strong className="text-xs font-bold text-[#f3f3f6] flex items-center gap-2">
                      <Monitor size={14} className="text-[#ff8800]" />
                      <span>Windows 10 / 11</span>
                    </strong>
                    <span className="text-[10px] font-mono text-[#5f5f67]">%APPDATA%\pala</span>
                  </div>
                  <div className="text-xs text-[#8c8c94] space-y-1.5 font-mono">
                    <div className="p-2.5 bg-[#151518] rounded-xl border border-[#28282d]">
                      <span className="text-[#5f5f67]">Konfiguráció: </span>
                      <span className="text-[#ff8800]">%APPDATA%\pala\config.json</span>
                    </div>
                    <div className="p-2.5 bg-[#151518] rounded-xl border border-[#28282d]">
                      <span className="text-[#5f5f67]">Offline SQLite Adatbázis: </span>
                      <span className="text-[#ff8800]">%LOCALAPPDATA%\pala\cache.db</span>
                    </div>
                  </div>
                  <div className="text-xs text-[#8c8c94]">
                    <strong>Manuális szerkesztés PowerShellből:</strong>
                    <div className="mt-1.5 p-2.5 bg-[#0e0e11] rounded-xl border border-[#28282d] font-mono text-[#ff8800] flex items-center justify-between">
                      <span>notepad $env:APPDATA\pala\config.json</span>
                      <button onClick={() => handleCopy("notepad $env:APPDATA\\pala\\config.json", "cfg-win")} className="hover:text-white">
                        {copiedKey === "cfg-win" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                      </button>
                    </div>
                  </div>
                </div>

                {/* Linux Card */}
                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-3">
                  <div className="flex items-center justify-between">
                    <strong className="text-xs font-bold text-[#f3f3f6] flex items-center gap-2">
                      <Terminal size={14} className="text-[#30d158]" />
                      <span>Linux (XDG Standard)</span>
                    </strong>
                    <span className="text-[10px] font-mono text-[#5f5f67]">~/.config/pala</span>
                  </div>
                  <div className="text-xs text-[#8c8c94] space-y-1.5 font-mono">
                    <div className="p-2.5 bg-[#151518] rounded-xl border border-[#28282d]">
                      <span className="text-[#5f5f67]">Konfiguráció: </span>
                      <span className="text-[#ff8800]">~/.config/pala/config.json</span>
                    </div>
                    <div className="p-2.5 bg-[#151518] rounded-xl border border-[#28282d]">
                      <span className="text-[#5f5f67]">Offline Adatbázis: </span>
                      <span className="text-[#ff8800]">~/.local/share/pala/cache.db</span>
                    </div>
                  </div>
                  <div className="text-xs text-[#8c8c94]">
                    <strong>Manuális szerkesztés terminálban:</strong>
                    <div className="mt-1.5 p-2.5 bg-[#0e0e11] rounded-xl border border-[#28282d] font-mono text-[#ff8800] flex items-center justify-between">
                      <span>nano ~/.config/pala/config.json</span>
                      <button onClick={() => handleCopy("nano ~/.config/pala/config.json", "cfg-lin")} className="hover:text-white">
                        {copiedKey === "cfg-lin" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                      </button>
                    </div>
                  </div>
                </div>

                {/* macOS Card */}
                <div className="bg-[#1b1b1f] border border-[#28282d] p-5 rounded-2xl space-y-3">
                  <div className="flex items-center justify-between">
                    <strong className="text-xs font-bold text-[#f3f3f6] flex items-center gap-2">
                      <Monitor size={14} className="text-[#0a84ff]" />
                      <span>macOS</span>
                    </strong>
                    <span className="text-[10px] font-mono text-[#5f5f67]">~/Library/Application Support/pala</span>
                  </div>
                  <div className="text-xs text-[#8c8c94] space-y-1.5 font-mono">
                    <div className="p-2.5 bg-[#151518] rounded-xl border border-[#28282d]">
                      <span className="text-[#5f5f67]">Konfiguráció: </span>
                      <span className="text-[#ff8800]">~/Library/Application Support/pala/config.json</span>
                    </div>
                    <div className="p-2.5 bg-[#151518] rounded-xl border border-[#28282d]">
                      <span className="text-[#5f5f67]">Gyorsítótár: </span>
                      <span className="text-[#ff8800]">~/Library/Caches/pala/cache.db</span>
                    </div>
                  </div>
                  <div className="text-xs text-[#8c8c94]">
                    <strong>Megnyitás TextEditben:</strong>
                    <div className="mt-1.5 p-2.5 bg-[#0e0e11] rounded-xl border border-[#28282d] font-mono text-[#ff8800] flex items-center justify-between">
                      <span>open -a TextEdit ~/Library/Application\ Support/pala/config.json</span>
                      <button onClick={() => handleCopy("open -a TextEdit ~/Library/Application\\ Support/pala/config.json", "cfg-mac")} className="hover:text-white">
                        {copiedKey === "cfg-mac" ? <Check size={13} className="text-[#30d158]" /> : <Copy size={13} />}
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* JSON Structure Blueprint */}
              <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-4">
                <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                  <FileCode2 size={16} className="text-[#ff8800]" />
                  <span>A <code className="text-[#ff8800] font-mono">config.json</code> Fájl Struktúrája</span>
                </div>

                <p className="text-xs text-[#8c8c94]">
                  A konfigurációs fájl tetszőleges szövegszerkesztővel (VS Code, Notepad, Nano) manuálisan módosítható a program leállított állapotában:
                </p>

                <div className="bg-[#151518] border border-[#28282d] rounded-xl p-4 font-mono text-xs text-[#f3f3f6] overflow-x-auto leading-relaxed">
                  <pre>{`{
  "institute_code": "klik039000",       // Iskolád Kréta azonosító kódja
  "theme": "dark",                     // "dark", "light", vagy "system"
  "auto_sync_interval_minutes": 15,    // Automatikus háttér szinkronizáció gyakorisága
  "absence_warning_hours": 250,        // Figyelmeztetési küszöb a 250 órás limithez
  "notifications_enabled": true,       // Új jegy és teremváltozás asztali értesítések
  "anonymize_student_name": false,     // Név elrejtése nyilvános prezentációkhoz / streamhez
  "offline_fallback": true             // Kréta szerverleálláskor offline gyorsítótár használata
}`}</pre>
                </div>
              </div>
            </div>
          )}

          {/* ================= PAGE: SECURITY ================= */}
          {activePage === "security" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  SECURITY & ARCHITECTURE
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Biztonság és Adatvédelem
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  A Pala kliensoldali Zero-Knowledge elven működik. Nincsenek köztes adatbázisok vagy követők.
                </p>
              </div>

              <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-4">
                <div className="flex items-start gap-3">
                  <CheckCircle2 size={16} className="text-[#30d158] shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-[#f3f3f6] block text-xs">Közvetlen Kréta OAuth2 Kommunikáció</strong>
                    <span className="text-xs text-[#8c8c94]">
                      A hitelesítés közvetlenül a hivatalos <code className="text-[#ff8800] font-mono">https://idp.e-kreta.hu/connect/token</code> végponttal történik TLS 1.3 titkosítással.
                    </span>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <CheckCircle2 size={16} className="text-[#30d158] shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-[#f3f3f6] block text-xs">Helyi AES-256 Titkosítás</strong>
                    <span className="text-xs text-[#8c8c94]">
                      A jelszavadat soha nem tároljuk nyers szövegként. Kizárólag a tokenek tárolódnak helyileg a te gépeden.
                    </span>
                  </div>
                </div>

                <div className="flex items-start gap-3">
                  <CheckCircle2 size={16} className="text-[#30d158] shrink-0 mt-0.5" />
                  <div>
                    <strong className="text-[#f3f3f6] block text-xs">Zero Telemetry</strong>
                    <span className="text-xs text-[#8c8c94]">
                      Semmilyen analitikai vagy viselkedéskövető kód nincs a programban.
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ================= PAGE: TROUBLESHOOTING & FAQ ================= */}
          {activePage === "troubleshooting" && (
            <div className="space-y-8 animate-fadeIn">
              <div>
                <span className="text-[11px] font-mono font-bold tracking-widest text-[#ff8800] uppercase block mb-1">
                  BIZTONSÁG & ARCHITEKTÚRA / GYIK
                </span>
                <h1 className="text-3xl sm:text-4xl font-black text-[#f3f3f6] tracking-tight mb-3">
                  Hibaelhárítás és Gyakori Kérdések (GYIK)
                </h1>
                <p className="text-sm text-[#8c8c94] leading-relaxed max-w-2xl">
                  Gyakran ismételt kérdések a Pala adatkezelési modelljéről, a közvetlen kapcsolat okairól és a felmerülő problémákról.
                </p>
              </div>

              <div className="space-y-4">
                {/* Critical Question: Why no hosted website? */}
                <div className="bg-[#1b1b1f] border border-[#ff8800]/40 p-6 rounded-2xl space-y-3 shadow-[0_0_20px_rgba(255,136,0,0.08)]">
                  <div className="flex items-start gap-3">
                    <ServerOff size={20} className="text-[#ff8800] shrink-0 mt-0.5" />
                    <div>
                      <h3 className="text-sm font-bold text-[#f3f3f6] leading-snug">
                        Miért nincs nyilvános felhős weboldal (Hosted Web App) a Palából?
                      </h3>
                      <span className="text-[11px] text-[#ff8800] font-semibold">Adatvédelmi (GDPR) és jogi határok a Kréta rendszerrel</span>
                    </div>
                  </div>

                  <div className="text-xs text-[#8c8c94] space-y-2 leading-relaxed pl-8">
                    <p>
                      A böngészők biztonsági szabályai (CORS házirend) miatt egy tisztán weboldalas Kréta kliens csak úgy működhetne, ha a weboldal üzemeltetője egy <strong>központi proxy / backend szervert</strong> futtatna, amelyen minden kérés átfut.
                    </p>
                    <p>
                      Egy ilyen központi szerver üzemeltetése azt jelentené, hogy <strong>több tízezer magyar diák és szülő felhasználóneve, jelszava, jegyei, hiányzásai és személyes adatai</strong> ezen a külső szerveren keresztül áramlanának. Ez súlyos GDPR adatvédelmi kockázatot teremtene, a fejlesztőt adatfeldolgozóvá tenné, amihez szülői és hatósági engedélyek kellenének.
                    </p>
                    <div className="p-3 bg-[#151518] rounded-xl border border-[#28282d] text-[#30d158] font-semibold">
                      Ezért a Pala kizárólag <strong>kliensoldali alkalmazásként</strong> (Windows, Linux, macOS, Android, Böngésző Bővítmény) érhető el: az adataid 100%-ban közvetlenül a te saját eszközödről kommunikálnak a hivatalos Kréta szerverrel, köztes szerverek nélkül!
                    </div>
                  </div>
                </div>

                {/* FAQ 2: Password safety */}
                <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                    <Lock size={16} className="text-[#30d158]" />
                    <span>Biztonságos a jelszavam megadása a Palában?</span>
                  </div>
                  <p className="text-xs text-[#8c8c94] leading-relaxed pl-6">
                    Igen. A bejelentkezés közvetlenül a Kréta hivatalos <code className="text-[#ff8800] font-mono">idp.e-kreta.hu</code> OAuth2 végpontjával történik TLS 1.3 titkosított kapcsolaton keresztül. A Pala a jelszavadat soha nem tárolja egyszerű szövegként, kizárólag a kapott munkamenet-tokent őrzi meg a helyi gépeden titkosított formában.
                  </p>
                </div>

                {/* FAQ 3: Windows SmartScreen & Play Protect */}
                <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                    <AlertTriangle size={16} className="text-[#ffd60a]" />
                    <span>Miért jelez a Windows SmartScreen vagy az Android Play Protect?</span>
                  </div>
                  <p className="text-xs text-[#8c8c94] leading-relaxed pl-6">
                    A Pala egy nonprofit, közösségi nyílt forráskódú projekt, így nem rendelkezik évi többszázezer forintos Microsoft/Google EV digitális aláíró tanúsítvánnyal. A forráskód 100%-ban nyilvános és ellenőrizhető a GitHubon. Windows alatt kattints a <strong>„További információ”</strong> &gt; <strong>„Futtatás mindenképpen”</strong> gombra.
                  </p>
                </div>

                {/* FAQ 4: Login failure */}
                <div className="bg-[#1b1b1f] border border-[#28282d] p-6 rounded-2xl space-y-2">
                  <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6]">
                    <HelpCircle size={16} className="text-[#0a84ff]" />
                    <span>Mit tegyek, ha nem sikerül bejelentkeznem?</span>
                  </div>
                  <p className="text-xs text-[#8c8c94] leading-relaxed pl-6">
                    1. Ellenőrizd, hogy az intézménykódot (pl. <code className="text-[#ff8800] font-mono">klik039000</code>) pontosan adtad-e meg.<br />
                    2. Ha a hivatalos Kréta szerverek karbantartás miatt leálltak, a Pala felajánlja az offline módot vagy a <code className="text-[#ff8800] font-mono">pala --demo</code> tesztmódot.
                  </p>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
