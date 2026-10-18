import React from "react";
import Link from "next/link";
import Image from "next/image";

export function Footer() {
  return (
    <footer className="border-t border-border bg-bg mt-auto py-12 sm:py-14 px-4 sm:px-6 text-sm text-muted w-full overflow-hidden">
      <div className="max-w-6xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-8 pb-10 border-b border-border/70">
        {/* Column 1: Brand & Mission */}
        <div className="lg:col-span-2 space-y-3.5">
          <div className="flex items-center gap-3">
            <Image
              src="/logo.svg"
              alt="Pala logó"
              width={36}
              height={36}
              className="w-9 h-9 rounded-xl object-contain"
            />
            <div className="flex flex-col">
              <span className="font-black text-fg text-base tracking-wide">
                PALA KRÉTA KLIENS
              </span>
              <span className="text-[11px] text-muted">
                Nyílt forráskódú, adatvédelem-első oktatási ökoszisztéma
              </span>
            </div>
          </div>
          <p className="text-xs text-muted leading-relaxed max-w-sm">
            Gyors, közvetlen és reklámmentes Kréta kliens Androidra, Windowsra, macOS-re, Linuxra,
            böngészőbővítményként és terminálban (TUI).
          </p>
          <div className="flex items-center gap-2 text-[11px] font-mono text-muted">
            <span className="px-2 py-0.5 rounded bg-card border border-border">MIT Licenc</span>
            <span className="px-2 py-0.5 rounded bg-card border border-border">Zero-Telemetry</span>
            <span className="px-2 py-0.5 rounded bg-card border border-border">WCAG 2.1 AA</span>
          </div>
        </div>

        {/* Column 2: Documentation */}
        <div className="space-y-2.5">
          <h3 className="text-xs font-extrabold uppercase tracking-wider text-fg">
            Dokumentáció
          </h3>
          <ul className="space-y-2 text-xs font-semibold">
            <li>
              <Link href="/docs/getting-started" className="hover:text-primary transition-colors">
                Kezdő Lépések & Telepítés
              </Link>
            </li>
            <li>
              <Link href="/docs/guides" className="hover:text-primary transition-colors">
                Funkció Útmutatók
              </Link>
            </li>
            <li>
              <Link href="/docs/developers" className="hover:text-primary transition-colors">
                Fejlesztői & API Specifikációk
              </Link>
            </li>
            <li>
              <Link href="/docs?page=troubleshooting" className="hover:text-primary transition-colors">
                Hibaelhárítás & GYIK
              </Link>
            </li>
          </ul>
        </div>

        {/* Column 3: Platforms */}
        <div className="space-y-2.5">
          <h3 className="text-xs font-extrabold uppercase tracking-wider text-fg">
            Platformok & Letöltés
          </h3>
          <ul className="space-y-2 text-xs font-semibold">
            <li>
              <Link href="/#letoltes" className="hover:text-primary transition-colors">
                Platform Letöltési Központ
              </Link>
            </li>
            <li>
              <Link href="/docs?page=desktop" className="hover:text-primary transition-colors">
                Flutter App (Mobil & Asztali)
              </Link>
            </li>
            <li>
              <Link href="/docs?page=extension" className="hover:text-primary transition-colors">
                Böngésző Bővítmény (Chrome / Firefox)
              </Link>
            </li>
            <li>
              <Link href="/docs?page=tui" className="hover:text-primary transition-colors">
                Pala TUI (Terminál)
              </Link>
            </li>
          </ul>
        </div>

        {/* Column 4: Community, Legal & Repo */}
        <div className="space-y-2.5">
          <h3 className="text-xs font-extrabold uppercase tracking-wider text-fg">
            Közösség & Projekt
          </h3>
          <ul className="space-y-2 text-xs font-semibold">
            <li>
              <a
                href="https://github.com/CsPS0/pala"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-primary transition-colors"
              >
                GitHub Repository
              </a>
            </li>
            <li>
              <a
                href="https://github.com/CsPS0/pala/discussions"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-primary transition-colors"
              >
                Közösségi Fórum & Javaslatok
              </a>
            </li>
            <li>
              <a
                href="https://github.com/CsPS0/pala/blob/main/LICENSE"
                target="_blank"
                rel="noopener noreferrer"
                className="hover:text-primary transition-colors"
              >
                MIT Licenc
              </a>
            </li>
            <li>
              <Link href="/adatvedelem" className="hover:text-primary transition-colors">
                Adatvédelem
              </Link>
            </li>
            <li>
              <Link href="/tortenet" className="hover:text-primary transition-colors">
                Kliensek Története
              </Link>
            </li>
          </ul>
        </div>
      </div>

      <div className="max-w-6xl mx-auto pt-6 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-muted">
        <span>
          Pala — Nem hivatalos nyílt forráskódú Kréta kliens. A Kréta az eKréta Informatikai Zrt.
          védjegye.
        </span>
        <div className="flex items-center gap-4">
          <Link href="/ai-hasznalat" className="hover:text-fg transition-colors">
            AI használat
          </Link>
          <span>•</span>
          <span>Készült a magyar diákközösség számára.</span>
        </div>
      </div>
    </footer>
  );
}
