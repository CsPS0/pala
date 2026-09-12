import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";

export const metadata: Metadata = {
  title: "AI használat",
  description:
    "A Pala projekt álláspontja az AI-eszközök használatáról a fejlesztésben és a hozzájárulásokban.",
  alternates: {
    canonical: "/ai-hasznalat",
  },
};

export default function AiUsagePage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col">
      <header className="border-b border-[#28282d] bg-[#151518]/90 backdrop-blur-md h-[70px] flex items-center px-4 sm:px-6">
        <div className="max-w-3xl mx-auto w-full flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <img src="/logo.svg" alt="Pala logó" width={36} height={36} className="w-9 h-9 rounded-xl object-contain" />
            <span className="font-extrabold text-base tracking-wide">PALA</span>
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

      <main className="flex-1 max-w-3xl mx-auto w-full px-4 sm:px-6 py-12 sm:py-16">
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2">AI használat</h1>
        <p className="text-xs text-[#5f5f67] mb-10">Utolsó frissítés: 2026. szeptember</p>

        <div className="space-y-6 text-sm text-[#c5c5cc] leading-relaxed">
          <p>
            A Palát gyakorlatilag egyedül fejlesztem, és ehhez sokat használok AI-t/LLM-eket — ezt nem
            titkolom, és nem is gondolom, hogy szégyellnivaló lenne. Amíg nagyjából értem és valamennyire
            átlátom, amit a gép leír, addig ez csak egy eszköz a sok közül — a maradékra meg ott az MIT
            licenc: a kód &bdquo;ahogy van&rdquo; alapon, mindenféle garancia nélkül érhető el.
          </p>
          <p>
            Ha te is hozzá szeretnél járulni kóddal, ugyanezt az elvárást támasztom feléd: nyugodtan
            használhatsz AI-t a Pull Requestedhez, de a beküldés előtt neked kell értened, hogy mit
            csinált az LLM. Ha megkérdezem, miért így oldottad meg, tudnod kell válaszolni rá — az &bdquo;az
            AI így írta&rdquo; nem válasz.
          </p>
          <p>
            Azok a Pull Requestek, amelyeknél látszik, hogy a hozzájáruló nem érti a saját kódját,
            javítási kérés nélkül elutasításra kerülhetnek.
          </p>
          <p>Emberi szöveg AI-alapú helyesírás-ellenőrzése és fordítása természetesen megengedett.</p>
          <p>
            Ha állásra jelentkezőként vagy felhasználóként megtévesztőnek találod az AI ilyen jellegű
            használatát ebben a projektben, használd inkább a{" "}
            <a
              href="https://github.com/QwIT-Development/firka"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#ff8800] hover:underline"
            >
              Firka
            </a>{" "}
            vagy a{" "}
            <a
              href="https://github.com/Zan1456/folio"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#ff8800] hover:underline"
            >
              Folio
            </a>{" "}
            alkalmazást a Pala helyett.
          </p>
        </div>
      </main>

      <footer className="border-t border-[#28282d] bg-[#151518] py-6 px-4 text-center text-xs text-[#8c8c94]">
        <span>Pala — Nyílt forráskódú Kréta Kliens</span>
      </footer>
    </div>
  );
}
