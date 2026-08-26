"use client";

import React, { useEffect } from "react";
import Link from "next/link";
import { RefreshCw, Home, AlertTriangle, ExternalLink } from "lucide-react";
import { useRelease } from "@/lib/useRelease";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const { version } = useRelease();

  useEffect(() => {
    console.error("Pala Runtime Error:", error);
  }, [error]);

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col font-sans selection:bg-[#ff8800]/30 selection:text-[#ff8800] overflow-x-hidden">
      {/* Top Header */}
      <header className="border-b border-[#28282d] bg-[#151518]/90 backdrop-blur-md h-[70px] flex items-center px-4 sm:px-6">
        <div className="max-w-6xl mx-auto w-full flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <img
              src="/logo.svg"
              alt="Pala logó"
              width={40}
              height={40}
              className="w-10 h-10 rounded-xl shadow-[0_0_15px_rgba(255,136,0,0.25)] object-contain"
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
        </div>
      </header>

      {/* Main Error Content */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-4 sm:px-6 py-16 max-w-2xl mx-auto w-full">
        {/* Error Icon Badge */}
        <div className="w-16 h-16 rounded-3xl bg-[#ff453a]/10 border border-[#ff453a]/30 flex items-center justify-center text-[#ff453a] mb-6 shadow-[0_0_30px_rgba(255,69,58,0.15)]">
          <AlertTriangle size={30} />
        </div>

        <div className="inline-flex items-center gap-2 bg-[#ff453a]/10 border border-[#ff453a]/30 px-4 py-1.5 rounded-full text-xs font-bold text-[#ff453a] mb-4">
          <span>FUTÁSI HIBA</span> • <span>500 ERROR</span>
        </div>

        <h1 className="text-2xl sm:text-4xl font-black tracking-tight text-[#f3f3f6] mb-3">
          Váratlan hiba történt a felület betöltésekor
        </h1>

        <p className="text-sm sm:text-base text-[#8c8c94] leading-relaxed max-w-lg mb-8">
          A felület egy váratlan hibába ütközött. Próbáld meg újratölteni az oldalt, vagy látogass el a GitHub repo hibajelentő felületére.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 w-full max-w-md mb-8">
          <button
            onClick={() => {
              if (typeof window !== "undefined") {
                window.location.reload();
              } else {
                reset();
              }
            }}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-sm sm:text-base px-6 sm:px-8 py-3.5 rounded-2xl transition-all shadow-[0_0_25px_rgba(255,136,0,0.25)] hover:-translate-y-0.5 cursor-pointer"
          >
            <RefreshCw size={16} />
            <span>Újrapróbálkozás</span>
          </button>

          <Link
            href="/"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#1b1b1f] hover:bg-[#222227] text-[#f3f3f6] border border-[#28282d] hover:border-[#ff8800] font-bold text-sm sm:text-base px-6 sm:px-7 py-3.5 rounded-2xl transition-all hover:-translate-y-0.5"
          >
            <Home size={16} />
            <span>Főoldal</span>
          </Link>
        </div>

        {/* Report link */}
        <a
          href="https://github.com/CsPS0/pala/issues/new"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1.5 text-xs text-[#8c8c94] hover:text-[#ff8800] transition-colors"
        >
          <span>Hibajelentés küldése a GitHubon</span>
          <ExternalLink size={12} />
        </a>
      </main>

      {/* Footer */}
      <footer className="border-t border-[#28282d] bg-[#151518] py-6 px-4 text-center text-xs text-[#8c8c94]">
        <span>Pala — Nyílt forráskódú Kréta Kliens</span>
      </footer>
    </div>
  );
}
