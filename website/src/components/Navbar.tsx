"use client";

import React from "react";
import Link from "next/link";
import { ThemeToggle } from "./ThemeToggle";
import { GitHubIcon } from "./PlatformIcons";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { Menu, Search, X } from "lucide-react";
import { useRelease } from "@/lib/useRelease";
import { shownVersion } from "@/lib/ReleaseContext";
import { useDocsUI } from "@/lib/DocsUIContext";

export function Navbar() {
  const version = shownVersion(useRelease());
  const { isDocsPage, mobileMenuOpen, setMobileMenuOpen, openDocsSearch } = useDocsUI();
  const pathname = usePathname();

  // In the order the sections follow each other on the home page, then the other pages.
  const NAV_LINKS = [
    { label: "Funkciók", href: "/#funkciok" },
    { label: "Hogyan működik?", href: "/#hogyan-mukodik" },
    { label: "Letöltés", href: "/#letoltes" },
    { label: "Ütemterv", href: "/#utemterv" },
    { label: "Történet", href: "/tortenet" },
    { label: "Dokumentáció", href: "/docs" },
  ];

  return (
    // Always visible, with a solid surface and an edge so it never melts into the page below.
    <header className="fixed top-0 left-0 right-0 z-50 w-full bg-sidebar/95 backdrop-blur-md border-b border-border shadow-[0_10px_24px_-18px_rgba(0,0,0,0.7)]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 h-[68px] flex items-center justify-between gap-4">
        {/* Brand */}
        <Link href="/" className="flex items-center gap-2.5 group shrink-0">
          <Image
            src="/logo.svg"
            alt="Pala logó"
            width={34}
            height={34}
            className="w-8 h-8 rounded-xl object-contain transition-transform"
          />
          <div className="flex items-center gap-2">
            <span className="font-black text-base tracking-wider text-fg">PALA</span>
            {version && (
              <span className="text-xs font-bold text-muted border border-border px-1.5 py-0.5 rounded">
                {version}
              </span>
            )}
          </div>
        </Link>

        {/* Desktop Navigation Links */}
        <nav className="hidden lg:flex items-center gap-1 text-xs font-bold text-muted whitespace-nowrap">
          {NAV_LINKS.map((link) => {
            const isActive = !link.href.includes("#") && pathname?.startsWith(link.href);
            return (
              <Link
                key={link.label}
                href={link.href}
                aria-current={isActive ? "page" : undefined}
                className={`px-3 py-1.5 rounded-lg transition-all ${
                  isActive
                    ? "text-primary bg-primary/10"
                    : "hover:text-fg hover:bg-card"
                }`}
              >
                {link.label}
              </Link>
            );
          })}
        </nav>

        {/* Action Buttons */}
        <div className="hidden sm:flex items-center gap-2.5">
          <button
            onClick={openDocsSearch}
            className="hidden xl:flex items-center justify-between bg-card hover:bg-card-hover border border-border hover:border-primary/50 rounded-xl px-3 py-2 text-xs text-muted transition-colors cursor-pointer group w-56"
            aria-label="Dokumentáció kereső megnyitása"
          >
            <span className="flex items-center gap-1.5 truncate">
              <Search size={14} className="text-muted group-hover:text-primary transition-colors shrink-0" />
              <span className="truncate">Keresés a docsban...</span>
            </span>
            <kbd className="bg-sidebar border border-border text-[10px] font-mono text-muted group-hover:text-fg px-1.5 py-0.5 rounded shrink-0">
              Ctrl K
            </kbd>
          </button>
        </div>

        <a
          href="https://github.com/CsPS0/pala"
          target="_blank"
          rel="noopener noreferrer"
          title="Forráskód a GitHubon"
          aria-label="A Pala forráskódja a GitHubon"
          className="hidden sm:flex p-2 rounded-xl bg-card border border-border text-muted hover:text-fg transition-colors"
        >
          <GitHubIcon size={18} />
        </a>

        {/* Mobile-only Search Trigger */}
        <button
          onClick={openDocsSearch}
          className="xl:hidden p-2 rounded-xl bg-card border border-border text-muted hover:text-fg transition-colors"
          aria-label="Dokumentáció kereső megnyitása"
        >
          <Search size={18} />
        </button>

        <ThemeToggle />

        {/* Mobile Hamburger Button */}
        <button
          onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          className="lg:hidden p-2 rounded-xl bg-card border border-border text-muted hover:text-fg transition-colors"
          aria-label={mobileMenuOpen ? "Menü bezárása" : "Menü megnyitása"}
          aria-expanded={mobileMenuOpen}
        >
          {mobileMenuOpen ? <X size={18} /> : <Menu size={18} />}
        </button>
      </div>

      {/* Mobile Drawer Menu (docs pages render their own section drawer instead) */}
      {mobileMenuOpen && !isDocsPage && (
        <div className="lg:hidden border-b border-border bg-sidebar/95 px-4 py-4 space-y-2">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.label}
              href={link.href}
              onClick={() => setMobileMenuOpen(false)}
              className="block px-3 py-2.5 rounded-xl text-sm font-bold text-muted hover:text-fg hover:bg-card transition-colors"
            >
              {link.label}
            </Link>
          ))}

          <div className="pt-3 border-t border-border flex items-center gap-3">
            <a
              href="https://github.com/CsPS0/pala"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs font-bold text-muted hover:text-fg py-2 px-3 rounded-xl hover:bg-card transition-colors inline-flex items-center gap-1.5"
            >
              <GitHubIcon size={14} />
              <span>GitHub</span>
            </a>
          </div>
        </div>
      )}
    </header>
  );
}
