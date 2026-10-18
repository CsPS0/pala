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
    <div className="min-h-screen bg-[var(--bg)] text-fg flex flex-col font-sans selection:bg-primary/30 selection:text-primary overflow-x-hidden pt-[68px]">
      {/* Main 404 Hero */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-4 sm:px-6 py-14 sm:py-20 max-w-4xl mx-auto w-full">
        {/* Glowing 404 Badge */}
        <div className="inline-flex items-center gap-2 bg-primary/10 border border-primary/30 px-4 py-1.5 rounded-full text-xs font-bold text-primary mb-6">
          <span>404 HIBA</span> • <span>AZ OLDAL NEM TALÁLHATÓ</span>
        </div>

        {/* Large 404 Visual Heading */}
        <div className="relative mb-4">
          <span className="text-7xl sm:text-9xl font-black tracking-tighter text-fg select-none">
            404
          </span>
        </div>

        <h1 className="text-2xl sm:text-4xl font-black tracking-tight text-fg mb-3 max-w-xl">
          Hoppá! Ez az oldal nem létezik vagy elköltözött.
        </h1>

        <p className="text-sm sm:text-base text-muted leading-relaxed max-w-lg mb-8">
          A keresett oldal vagy URL nem található. Lehet, hogy elgépelted a hivatkozást, vagy a tartalom átkerült egy másik menüpont alá.
        </p>

        {/* Quick Recovery Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 w-full max-w-md mb-10">
          <Link
            href="/"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-primary-fill hover:bg-primary-fill-hover text-on-primary font-extrabold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-2xl transition-all"
          >
            <Home size={16} />
            <span>Vissza a Főoldalra</span>
          </Link>

          <Link
            href="/docs"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-card hover:bg-card-hover text-fg border border-border hover:border-primary font-bold text-sm sm:text-base px-6 sm:px-7 py-3.5 rounded-2xl transition-all"
          >
            <BookOpen size={16} className="text-primary" />
            <span>Dokumentáció</span>
          </Link>
        </div>

        {/* Popular Shortcuts */}
        <div className="flex flex-wrap items-center justify-center gap-2 mb-10 max-w-lg">
          <span className="text-xs font-semibold text-subtle flex items-center gap-1.5 mr-1">
            <Search size={12} />
            <span>Gyakori témák:</span>
          </span>
          {SUGGESTIONS.map((item) => (
            <Link
              key={item.label}
              href={item.href}
              className="text-xs px-2.5 py-1 rounded-lg bg-card-alt border border-border text-muted hover:text-primary hover:border-primary/40 transition-colors"
            >
              {item.label}
            </Link>
          ))}
        </div>

        {/* Helpful Recovery Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full text-left max-w-2xl">
          <Link
            href="/docs#telepites"
            className="p-4 rounded-2xl bg-sidebar border border-border hover:border-primary/40 hover:bg-card-alt transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-fg group-hover:text-primary transition-colors mb-1">
              <Download size={15} className="text-primary" />
              <span>Telepítési Útmutató</span>
            </div>
            <p className="text-xs text-muted leading-relaxed">
              Windows asztali app, Android APK, iOS Sideloading, Linux csomagok és böngészőbővítmény.
            </p>
          </Link>

          <Link
            href="/tortenet"
            className="p-4 rounded-2xl bg-sidebar border border-border hover:border-primary/40 hover:bg-card-alt transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-fg group-hover:text-primary transition-colors mb-1">
              <History size={15} className="text-primary" />
              <span>Kliensek Története</span>
            </div>
            <p className="text-xs text-muted leading-relaxed">
              A magyar és európai elektronikus naplók és alternatív diák-kliensek fejlődésének idővonala.
            </p>
          </Link>

          <Link
            href="/docs#gyik"
            className="p-4 rounded-2xl bg-sidebar border border-border hover:border-primary/40 hover:bg-card-alt transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-fg group-hover:text-primary transition-colors mb-1">
              <HelpCircle size={15} className="text-primary" />
              <span>Gyakori Kérdések (GYIK)</span>
            </div>
            <p className="text-xs text-muted leading-relaxed">
              Válaszok a hitelesítési, biztonsági, frissítési és működési kérdésekre.
            </p>
          </Link>

          <Link
            href="/tortenet"
            className="p-4 rounded-2xl bg-sidebar border border-border hover:border-primary/40 hover:bg-card-alt transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-fg group-hover:text-primary transition-colors mb-1">
              <Users size={15} className="text-primary" />
              <span>Közösségi Projektek</span>
            </div>
            <p className="text-xs text-muted leading-relaxed">
              A Kréta-kliensek története és más nyílt forráskódú projektek.
            </p>
          </Link>
        </div>
      </main>

      {/* Shared Unified Footer */}
      <Footer />
    </div>
  );
}
