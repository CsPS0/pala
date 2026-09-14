"use client";

import React from "react";
import Link from "next/link";
import {
  BookOpen,
  Home,
  Download,
  HelpCircle,
  History,
  Users,
  Search,
} from "lucide-react";
import { Footer } from "@/components/Footer";

export default function NotFound() {
  const SUGGESTIONS = [
    { label: "Windows telepítés", href: "/docs#telepites" },
    { label: "Android APK", href: "/docs#telepites" },
    { label: "Kliensek története", href: "/tortenet" },
    { label: "Gyakori kérdések (GYIK)", href: "/docs#gyik" },
    { label: "Adatvédelem", href: "/adatvedelem" },
  ];

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col font-sans selection:bg-[#ff8800]/30 selection:text-[#ff8800] overflow-x-hidden pt-[68px]">
      {/* Main 404 Hero */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-4 sm:px-6 py-14 sm:py-20 max-w-4xl mx-auto w-full">
        {/* Glowing 404 Badge */}
        <div className="inline-flex items-center gap-2 bg-[#ff453a]/10 border border-[#ff453a]/30 px-4 py-1.5 rounded-full text-xs font-bold text-[#ff453a] mb-6 shadow-[0_0_20px_rgba(255,69,58,0.1)]">
          <span>404 HIBA</span> • <span>AZ OLDAL NEM TALÁLHATÓ</span>
        </div>

        {/* Large 404 Visual Heading */}
        <div className="relative mb-4">
          <span className="text-7xl sm:text-9xl font-black tracking-tighter bg-gradient-to-b from-[#f3f3f6] via-[#8c8c94] to-[#28282d] bg-clip-text text-transparent select-none">
            404
          </span>
          <div className="absolute inset-0 bg-[#ff8800]/10 blur-3xl -z-10 rounded-full" />
        </div>

        <h1 className="text-2xl sm:text-4xl font-black tracking-tight text-[#f3f3f6] mb-3 max-w-xl">
          Hoppá! Ez az oldal nem létezik vagy elköltözött.
        </h1>

        <p className="text-sm sm:text-base text-[#8c8c94] leading-relaxed max-w-lg mb-8">
          A keresett oldal vagy URL nem található. Lehet, hogy elgépelted a hivatkozást, vagy a tartalom átkerült egy másik menüpont alá.
        </p>

        {/* Quick Recovery Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 w-full max-w-md mb-10">
          <Link
            href="/"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-2xl transition-all shadow-[0_0_25px_rgba(255,136,0,0.25)] hover:-translate-y-0.5"
          >
            <Home size={16} />
            <span>Vissza a Főoldalra</span>
          </Link>

          <Link
            href="/docs"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#1b1b1f] hover:bg-[#222227] text-[#f3f3f6] border border-[#28282d] hover:border-[#ff8800] font-bold text-sm sm:text-base px-6 sm:px-7 py-3.5 rounded-2xl transition-all hover:-translate-y-0.5"
          >
            <BookOpen size={16} className="text-[#ff8800]" />
            <span>Dokumentáció</span>
          </Link>
        </div>

        {/* Popular Shortcuts */}
        <div className="flex flex-wrap items-center justify-center gap-2 mb-10 max-w-lg">
          <span className="text-xs font-semibold text-[#666670] flex items-center gap-1.5 mr-1">
            <Search size={12} />
            <span>Gyakori témák:</span>
          </span>
          {SUGGESTIONS.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              className="text-xs px-2.5 py-1 rounded-lg bg-[#18181c] border border-[#28282d] text-[#8c8c94] hover:text-[#ff8800] hover:border-[#ff8800]/40 transition-colors"
            >
              {item.label}
            </Link>
          ))}
        </div>

        {/* Helpful Recovery Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full text-left max-w-2xl">
          <Link
            href="/docs#telepites"
            className="p-4 rounded-2xl bg-[#151518] border border-[#28282d] hover:border-[#ff8800]/40 hover:bg-[#19191d] transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6] group-hover:text-[#ff8800] transition-colors mb-1">
              <Download size={15} className="text-[#ff8800]" />
              <span>Telepítési Útmutató</span>
            </div>
            <p className="text-xs text-[#8c8c94] leading-relaxed">
              Windows asztali app, Android APK, iOS Sideloading, Linux csomagok és böngészőbővítmény.
            </p>
          </Link>

          <Link
            href="/tortenet"
            className="p-4 rounded-2xl bg-[#151518] border border-[#28282d] hover:border-[#bf5af2]/40 hover:bg-[#19191d] transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6] group-hover:text-[#bf5af2] transition-colors mb-1">
              <History size={15} className="text-[#bf5af2]" />
              <span>Kliensek Története</span>
            </div>
            <p className="text-xs text-[#8c8c94] leading-relaxed">
              A magyar és európai elektronikus naplók és alternatív diák-kliensek fejlődésének idővonala.
            </p>
          </Link>

          <Link
            href="/docs#gyik"
            className="p-4 rounded-2xl bg-[#151518] border border-[#28282d] hover:border-[#0a84ff]/40 hover:bg-[#19191d] transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6] group-hover:text-[#0a84ff] transition-colors mb-1">
              <HelpCircle size={15} className="text-[#0a84ff]" />
              <span>Gyakori Kérdések (GYIK)</span>
            </div>
            <p className="text-xs text-[#8c8c94] leading-relaxed">
              Válaszok a hitelesítési, biztonsági, frissítési és működési kérdésekre.
            </p>
          </Link>

          <Link
            href="/#kozosseg"
            className="p-4 rounded-2xl bg-[#151518] border border-[#28282d] hover:border-[#30d158]/40 hover:bg-[#19191d] transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6] group-hover:text-[#30d158] transition-colors mb-1">
              <Users size={15} className="text-[#30d158]" />
              <span>Közösségi Projektek</span>
            </div>
            <p className="text-xs text-[#8c8c94] leading-relaxed">
              Fedezd fel a magyar nyílt forráskódú Kréta és Neptun fejlesztéseket a főoldalon.
            </p>
          </Link>
        </div>
      </main>

      {/* Shared Unified Footer */}
      <Footer />
    </div>
  );
}
