"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Download,
  Menu,
  Search,
  X,
  ExternalLink,
} from "lucide-react";
import { useRelease } from "@/lib/useRelease";
import { useDocsUI } from "@/lib/DocsUIContext";

export function Navbar() {
  const { version, isLoading } = useRelease();
  const { isDocsPage, mobileMenuOpen, setMobileMenuOpen, openDocsSearch } = useDocsUI();
  const [visible, setVisible] = useState(true);
  const pathname = usePathname();

  useEffect(() => {
    const heroEl = document.getElementById("hero");
    if (!heroEl) {
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        // Appears only when the screen has scrolled past and is leaving the hero section
        setVisible(!entry.isIntersecting);
      },
      {
        root: null,
        threshold: 0,
        rootMargin: "-40px 0px 0px 0px",
      }
    );

    observer.observe(heroEl);
    return () => observer.disconnect();
  }, [pathname]);

  const NAV_LINKS = [
    { label: "Funkciók", href: "/#funkciok" },
    { label: "Biztonság", href: "/#biztonsag" },
    { label: "Ütemterv", href: "/#utemterv" },
    { label: "Közösség", href: "/#kozosseg" },
    { label: "Dokumentáció", href: "/docs" },
    { label: "Történet", href: "/tortenet" },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 w-full transition-all duration-300 ease-in-out ${
        visible
          ? "translate-y-0 opacity-100 pointer-events-auto bg-[#121215]/90 backdrop-blur-md border-b border-[#28282d] shadow-[0_4px_25px_rgba(0,0,0,0.4)]"
          : "-translate-y-full opacity-0 pointer-events-none"
      }`}
    >
      <div className="max-w-6xl mx-auto px-4 sm:px-6 h-[68px] flex items-center justify-between">
        {/* Brand */}
        <Link href="/" className="flex items-center gap-2.5 group">
          <img
            src="/logo.svg"
            alt="Pala logó"
            width={34}
            height={34}
            className="w-8 h-8 rounded-xl object-contain shadow-[0_0_12px_rgba(255,136,0,0.25)] transition-transform group-hover:scale-105"
          />
          <div className="flex items-center gap-2">
            <span className="font-black text-base tracking-wider text-[#f3f3f6]">PALA</span>
            <span className="text-[10px] font-bold bg-[#ff8800]/15 text-[#ff8800] border border-[#ff8800]/30 px-1.5 py-0.5 rounded">
              {isLoading ? "..." : version}
            </span>
          </div>
        </Link>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-center gap-1.5 text-xs font-bold text-[#8c8c94]">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              className="px-3 py-1.5 rounded-lg hover:text-[#f3f3f6] hover:bg-[#1b1b1f] transition-all"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        {/* Action Buttons */}
        <div className="hidden sm:flex items-center gap-2.5">
          {isDocsPage && (
            <button
              onClick={openDocsSearch}
              className="hidden md:flex items-center justify-between bg-[#1b1b1f] hover:bg-[#222227] border border-[#28282d] hover:border-[#ff8800]/50 rounded-xl px-3 py-2 text-xs text-[#8c8c94] transition-all cursor-pointer group w-48 lg:w-56"
              aria-label="Dokumentáció kereső megnyitása"
            >
              <span className="flex items-center gap-1.5 truncate">
                <Search size={14} className="text-[#8c8c94] group-hover:text-[#ff8800] transition-colors shrink-0" />
                <span className="truncate">Keresés a docsban...</span>
              </span>
              <kbd className="bg-[#151518] border border-[#28282d] text-[10px] font-mono text-[#8c8c94] group-hover:text-[#f3f3f6] px-1.5 py-0.5 rounded shrink-0">
                Ctrl K
              </kbd>
            </button>
          )}

          <a
            href="https://github.com/CsPS0/pala"
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs font-bold text-[#8c8c94] hover:text-[#f3f3f6] px-3 py-2 rounded-xl hover:bg-[#1b1b1f] transition-colors inline-flex items-center gap-1.5"
          >
            <span>GitHub</span>
            <ExternalLink size={12} />
          </a>

          <Link
            href="/docs#telepites"
            className="inline-flex items-center gap-1.5 text-xs font-extrabold px-3.5 py-2 rounded-xl bg-[#ff8800] hover:bg-[#ffa033] text-black transition-all shadow-[0_0_15px_rgba(255,136,0,0.2)] hover:-translate-y-0.5"
          >
            <Download size={13} />
            <span>Letöltés</span>
          </Link>
        </div>

        {/* Mobile-only Search Trigger (docs pages) */}
        {isDocsPage && (
          <button
            onClick={openDocsSearch}
            className="md:hidden p-2 rounded-xl bg-[#1b1b1f] border border-[#28282d] text-[#8c8c94] hover:text-[#f3f3f6] transition-colors"
            aria-label="Dokumentáció kereső megnyitása"
          >
            <Search size={18} />
          </button>
        )}

        {/* Mobile Hamburger Button */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="md:hidden p-2 rounded-xl bg-[#1b1b1f] border border-[#28282d] text-[#8c8c94] hover:text-[#f3f3f6] transition-colors"
          aria-label="Menü megnyitása"
        >
          {mobileMenuOpen ? <X size={18} /> : <Menu size={18} />}
        </button>
      </div>

      {/* Mobile Drawer Menu (docs pages render their own section drawer instead) */}
      {mobileMenuOpen && !isDocsPage && (
        <div className="md:hidden border-b border-[#28282d] bg-[#151518]/95 backdrop-blur-xl px-4 py-4 space-y-2">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2.5 rounded-xl text-sm font-bold text-[#8c8c94] hover:text-[#f3f3f6] hover:bg-[#1b1b1f] transition-colors"
            >
              {link.label}
            </Link>
          ))}

          <div className="pt-3 border-t border-[#28282d] flex items-center justify-between gap-3">
            <a
              href="https://github.com/CsPS0/pala"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs font-bold text-[#8c8c94] hover:text-[#f3f3f6] py-2 px-3 rounded-xl hover:bg-[#1b1b1f] transition-colors inline-flex items-center gap-1.5"
            >
              <span>GitHub repó</span>
              <ExternalLink size={12} />
            </a>

            <Link
              href="/docs#telepites"
              onClick={() => setMobileMenuOpen(false)}
              className="inline-flex items-center gap-1.5 text-xs font-extrabold px-4 py-2 rounded-xl bg-[#ff8800] text-black"
            >
              <Download size={13} />
              <span>Letöltés</span>
            </Link>
          </div>
        </div>
      )}
    </header>
  );
}
