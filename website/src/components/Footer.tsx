import React from "react";
import Link from "next/link";

export function Footer() {
  return (
    <footer className="border-t border-[#28282d] bg-[#151518] mt-auto py-10 sm:py-12 px-4 sm:px-6 text-sm text-[#8c8c94] w-full overflow-hidden">
      <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-6">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <img
            src="/logo.svg"
            alt="Pala logó"
            width={32}
            height={32}
            className="w-8 h-8 rounded-lg object-contain"
          />
          <div className="flex flex-col">
            <span className="font-extrabold text-[#f3f3f6] text-sm">Pala Kréta Kliens</span>
            <span className="text-[11px] text-[#5f5f67]">Nyílt forráskódú közösségi projekt</span>
          </div>
        </div>

        {/* Links */}
        <div className="flex flex-wrap items-center gap-6 text-xs font-semibold">
          <Link href="/docs" className="hover:text-[#ff8800] text-[#f3f3f6] font-bold transition-colors">
            Dokumentáció
          </Link>
          <Link href="/adatvedelem" className="hover:text-[#ff8800] text-[#f3f3f6] font-bold transition-colors">
            Adatvédelem
          </Link>
          <Link href="/ai-hasznalat" className="hover:text-[#ff8800] text-[#f3f3f6] font-bold transition-colors">
            AI használat
          </Link>
          <a href="https://github.com/CsPS0/pala" target="_blank" rel="noopener noreferrer" className="hover:text-[#f3f3f6] transition-colors">
            GitHub
          </a>
          <a href="https://github.com/CsPS0/pala/releases" target="_blank" rel="noopener noreferrer" className="hover:text-[#f3f3f6] transition-colors">
            Kiadások
          </a>
          <a href="https://github.com/CsPS0/pala/blob/main/LICENSE" target="_blank" rel="noopener noreferrer" className="hover:text-[#f3f3f6] transition-colors">
            MIT Licenc
          </a>
        </div>
      </div>

      <div className="max-w-6xl mx-auto mt-8 pt-6 border-t border-[#28282d]/60 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-[#5f5f67]">
        <span>Pala — Nem hivatalos nyílt forráskódú Kréta kliens. A Kréta az eKréta Informatikai Zrt. védjegye.</span>
        <span>Készült a magyar diákközösség számára.</span>
      </div>
    </footer>
  );
}
