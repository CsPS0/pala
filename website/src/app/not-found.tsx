"use client";

import React from "react";
import Link from "next/link";
import { ArrowLeft, BookOpen, Home, Download, Search } from "lucide-react";
import { useRelease } from "@/lib/useRelease";

export default function NotFound() {
  const { version } = useRelease();

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col font-sans selection:bg-[#ff8800]/30 selection:text-[#ff8800] overflow-x-hidden">
      {/* Top Simple Header */}
      <header className="border-b border-[#28282d] bg-[#151518]/90 backdrop-blur-md h-[70px] flex items-center px-4 sm:px-6">
        <div className="max-w-6xl mx-auto w-full flex items-center justify-between">
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
                <span className="text-[10px] font-bold bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 px-1.5 py-0.5 rounded">
                  {version}
                </span>
              </span>
              <span className="text-[11px] font-semibold text-[#8c8c94]">Kréta Kliens</span>
            </div>
          </Link>

          <Link
            href="/"
            className="inline-flex items-center gap-1.5 bg-[#1b1b1f] hover:bg-[#222227] text-[#8c8c94] hover:text-[#f3f3f6] border border-[#28282d] text-xs font-bold px-3.5 py-2 rounded-xl transition-colors"
          >
            <ArrowLeft size={13} />
            <span>Főoldal</span>
          </Link>
        </div>
      </header>

      {/* Main 404 Hero */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-4 sm:px-6 py-16 max-w-3xl mx-auto w-full">
        {/* Glowing 404 Badge */}
        <div className="inline-flex items-center gap-2 bg-[#ff453a]/10 border border-[#ff453a]/30 px-4 py-1.5 rounded-full text-xs font-bold text-[#ff453a] mb-6">
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

        <p className="text-sm sm:text-base text-[#8c8c94] leading-relaxed max-w-lg mb-8 sm:mb-10">
          A keresett oldal vagy URL nem található. Lehet, hogy elgépelted a címet, vagy a hivatkozott tartalom átkerült egy másik menüpont alá.
        </p>

        {/* Quick Recovery Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 w-full max-w-md mb-12">
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

        {/* Helpful Links Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4 w-full text-left">
          <Link
            href="/docs"
            className="p-4 rounded-2xl bg-[#151518] border border-[#28282d] hover:border-[#ff8800]/40 transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6] group-hover:text-[#ff8800] transition-colors mb-1">
              <Download size={14} className="text-[#ff8800]" />
              <span>Telepítési Útmutató</span>
            </div>
            <p className="text-xs text-[#8c8c94]">
              Windows, Android APK, iOS Sideloading, Linux script és bővítmény telepítés.
            </p>
          </Link>

          <Link
            href="/docs"
            className="p-4 rounded-2xl bg-[#151518] border border-[#28282d] hover:border-[#ff8800]/40 transition-all group"
          >
            <div className="flex items-center gap-2 text-sm font-bold text-[#f3f3f6] group-hover:text-[#ff8800] transition-colors mb-1">
              <Search size={14} className="text-[#ff8800]" />
              <span>Dokumentáció & GYIK</span>
            </div>
            <p className="text-xs text-[#8c8c94]">
              Részletes leírások, gyorsbillentyűk, konfigurációs fájlok és hibaelhárítási tippek.
            </p>
          </Link>
        </div>
      </main>

      {/* Simple Footer */}
      <footer className="border-t border-[#28282d] bg-[#151518] py-6 px-4 text-center text-xs text-[#8c8c94]">
        <span>Pala — Nyílt forráskódú Kréta Kliens</span>
      </footer>
    </div>
  );
}
