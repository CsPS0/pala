"use client";

import React, { useEffect, useState } from "react";
import Link from "next/link";
import { ThemeToggle } from "./ThemeToggle";
import { GitHubIcon } from "./PlatformIcons";
import Image from "next/image";
import { usePathname } from "next/navigation";
import {
  Download,
  Menu,
  Search,
  X,
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
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setVisible(true);
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
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
    { label: "Letöltés", href: "/#letoltes" },
    { label: "Adatvédelem", href: "/#biztonsag" },
    { label: "Dokumentáció", href: "/docs" },
    { label: "Történet", href: "/tortenet" },
  ];

  return (
    <header
      className={`fixed top-0 left-0 right-0 z-50 w-full transition-all duration-200 ease-out ${
        visible
          ? "translate-y-0 opacity-100 pointer-events-auto bg-bg/90 border-b border-border"
          : "-translate-y-full opacity-0 pointer-events-none"
      }`}
    >
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
            <span className="text-[10px] font-bold bg-primary/15 text-primary border border-primary/30 px-1.5 py-0.5 rounded">
              {isLoading ? "..." : version}
            </span>
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
            className="hidden md:flex items-center justify-between bg-card hover:bg-card-hover border border-border hover:border-primary/50 rounded-xl px-3 py-2 text-xs text-muted transition-colors cursor-pointer group w-48 lg:w-56"
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

          <a
            href="https://github.com/CsPS0/pala"
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs font-bold text-muted hover:text-fg px-3 py-2 rounded-xl hover:bg-card transition-colors inline-flex items-center gap-1.5"
          >
            <GitHubIcon size={14} />
            <span>GitHub</span>
          </a>

          <Link
            href="/#letoltes"
            className="inline-flex items-center gap-1.5 text-xs font-extrabold px-3.5 py-2 rounded-xl bg-primary-fill hover:bg-primary-fill-hover text-on-primary transition-all"
          >
            <Download size={13} />
            <span>Letöltés</span>
          </Link>
        </div>

        {/* Mobile-only Search Trigger */}
        <button
          onClick={openDocsSearch}
          className="md:hidden p-2 rounded-xl bg-card border border-border text-muted hover:text-fg transition-colors"
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

          <div className="pt-3 border-t border-border flex items-center justify-between gap-3">
            <a
              href="https://github.com/CsPS0/pala"
              target="_blank"
              rel="noopener noreferrer"
              className="text-xs font-bold text-muted hover:text-fg py-2 px-3 rounded-xl hover:bg-card transition-colors inline-flex items-center gap-1.5"
            >
              <GitHubIcon size={14} />
              <span>GitHub</span>
            </a>

            <Link
              href="/#letoltes"
              onClick={() => setMobileMenuOpen(false)}
              className="inline-flex items-center gap-1.5 text-xs font-extrabold px-4 py-2 rounded-xl bg-primary-fill text-on-primary"
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
