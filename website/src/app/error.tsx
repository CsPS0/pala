"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import {
  RefreshCw,
  AlertTriangle,
  ExternalLink,
  Copy,
  Check,
  Trash2,
} from "lucide-react";
import { Footer } from "@/components/Footer";

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    console.error("Pala Runtime Error:", error);
  }, [error]);

  const copyDigest = async () => {
    const textToCopy = error.digest || error.message || "Ismeretlen hiba";
    try {
      if (navigator?.clipboard?.writeText) {
        await navigator.clipboard.writeText(textToCopy);
      } else {
        const ta = document.createElement("textarea");
        ta.value = textToCopy;
        document.body.appendChild(ta);
        ta.select();
        document.execCommand("copy");
        document.body.removeChild(ta);
      }
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Ignore copy error
    }
  };

  const handleClearCacheAndReload = () => {
    try {
      if (typeof window !== "undefined") {
        sessionStorage.clear();
        window.location.reload();
      }
    } catch {
      window.location.reload();
    }
  };

  const issueUrl = `https://github.com/CsPS0/pala/issues/new?title=${encodeURIComponent(
    `[Hiba] ${error.message ? error.message.slice(0, 60) : "Futási hiba"}`
  )}&body=${encodeURIComponent(
    `**Hiba leírása:**\n${error.message || "Nem adott meg részleteket"}\n\n**Digest:**\n\`${
      error.digest || "Nincs"
    }\`\n\n**Böngésző:**\n${typeof navigator !== "undefined" ? navigator.userAgent : "Ismeretlen"}`
  )}`;

  return (
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col font-sans selection:bg-[#ff8800]/30 selection:text-[#ff8800] overflow-x-hidden pt-[68px]">
      {/* Main Error Content */}
      <main className="flex-1 flex flex-col items-center justify-center text-center px-4 sm:px-6 py-14 sm:py-20 max-w-2xl mx-auto w-full">
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

        <p className="text-sm sm:text-base text-[#8c8c94] leading-relaxed max-w-lg mb-6">
          A weboldal egy nem várt kivételbe ütközött. Próbáld meg újratölteni a lapot, törölni a helyi gyorsítótárat, vagy jelezd a hibát a fejlesztőknek.
        </p>

        {/* Digest identifier pill if available */}
        {error.digest && (
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl bg-[#171214] border border-[#ff453a]/30 mb-8 max-w-md">
            <span className="text-[11px] font-mono text-[#8c8c94]">Hibakód:</span>
            <code className="text-xs font-mono font-bold text-[#ff453a] truncate max-w-[200px]">
              {error.digest}
            </code>
            <button
              onClick={copyDigest}
              className="p-1 rounded-md text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#28282d] transition-colors cursor-pointer"
              title="Hibakód másolása"
            >
              {copied ? <Check size={12} className="text-[#30d158]" /> : <Copy size={12} />}
            </button>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 w-full max-w-md mb-6">
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
            <span>Újratöltés</span>
          </button>

          <button
            onClick={handleClearCacheAndReload}
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 bg-[#1b1b1f] hover:bg-[#222227] text-[#f3f3f6] border border-[#28282d] hover:border-[#ff8800] font-bold text-sm sm:text-base px-5 sm:px-6 py-3.5 rounded-2xl transition-all hover:-translate-y-0.5 cursor-pointer"
          >
            <Trash2 size={16} className="text-[#ff8800]" />
            <span>Gyorsítótár ürítése</span>
          </button>
        </div>

        {/* Report link */}
        <div className="flex items-center gap-4 text-xs">
          <a
            href={issueUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1.5 text-[#8c8c94] hover:text-[#ff8800] transition-colors"
          >
            <span>Hibajelentés beküldése GitHubon</span>
            <ExternalLink size={12} />
          </a>
          <span className="text-[#38383e]">•</span>
          <Link href="/" className="text-[#8c8c94] hover:text-[#f3f3f6] transition-colors">
            Vissza a főoldalra
          </Link>
        </div>
      </main>

      {/* Shared Unified Footer */}
      <Footer />
    </div>
  );
}
