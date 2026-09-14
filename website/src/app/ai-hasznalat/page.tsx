import type { Metadata } from "next";
import { Footer } from "@/components/Footer";

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
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col pt-[68px]">
      <main className="flex-1 max-w-3xl mx-auto w-full px-4 sm:px-6 py-12 sm:py-16">
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2">
          AI használat
        </h1>
        <p className="text-xs text-[#5f5f67] mb-10">
          Utolsó frissítés: 2026. szeptember
        </p>

        <div className="space-y-6 text-sm text-[#c5c5cc] leading-relaxed">
          <p>
            A Palát gyakorlatilag egyedül fejlesztem, és ehhez sokat használok
            AI-t/LLM-eket — ezt nem titkolom, és nem is gondolom, hogy
            szégyellnivaló lenne. Amíg nagyjából értem és valamennyire átlátom,
            amit a gép leír, addig ez csak egy eszköz a sok közül — a maradékra
            meg ott az MIT licenc: a kód &bdquo;ahogy van&rdquo; alapon,
            mindenféle garancia nélkül érhető el.
          </p>
          <p>
            Ha te is hozzá szeretnél járulni kóddal, ugyanezt az elvárást
            támasztom feléd: nyugodtan használhatsz AI-t a Pull Requestedhez, de
            a beküldés előtt neked kell értened, hogy mit csinált az LLM. Ha
            megkérdezem, miért így oldottad meg, tudnod kell válaszolni rá — az
            &bdquo;az AI így írta&rdquo; nem válasz.
          </p>
          <p>
            Azok a Pull Requestek, amelyeknél látszik, hogy a hozzájáruló nem
            érti a saját kódját, javítási kérés nélkül elutasításra kerülhetnek.
          </p>
          <p>
            Emberi szöveg AI-alapú helyesírás-ellenőrzése és fordítása
            természetesen megengedett.
          </p>
          <p>
            Ha állásra jelentkezőként vagy felhasználóként megtévesztőnek
            találod az AI ilyen jellegű használatát ebben a projektben, használd
            inkább a{" "}
            <a
              href="https://github.com/QwIT-Development/firka"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#ff8800] hover:underline"
            >
              Firka
            </a>
            ,{" "}
            <a
              href="https://github.com/Zan1456/folio"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#ff8800] hover:underline"
            >
              Folio
            </a>{" "}
            vagy az{" "}
            <a
              href="https://github.com/jarjk/rsfilc"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[#ff8800] hover:underline"
            >
              rsfilc
            </a>{" "}
            alkalmazást a Pala helyett.
          </p>
        </div>
      </main>

      <Footer />
    </div>
  );
}
