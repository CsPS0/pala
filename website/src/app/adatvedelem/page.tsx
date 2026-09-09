import type { Metadata } from "next";
import Link from "next/link";
import { ArrowLeft } from "lucide-react";

export const metadata: Metadata = {
  title: "Adatvédelmi tájékoztató",
  description:
    "Milyen adatot kezel a Pala, hol tárolja a bejelentkezési adataidat, és mit küld el harmadik feleknek.",
  alternates: {
    canonical: "/adatvedelem",
  },
};

export default function PrivacyPage() {
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
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2">Adatvédelmi tájékoztató</h1>
        <p className="text-xs text-[#5f5f67] mb-10">Utolsó frissítés: 2026. szeptember</p>

        <div className="space-y-10 text-sm text-[#c5c5cc] leading-relaxed">
          <section>
            <h2 className="text-lg font-bold text-[#f3f3f6] mb-3">Kinek szól ez a tájékoztató</h2>
            <p>
              A Pala egy nem hivatalos, nyílt forráskódú kliens az e-Kréta rendszerhez. Nincs saját
              szervere, saját felhasználói fiókja vagy adatbázisa. Ez az oldal azt írja le, hogy a
              weboldal, az asztali és mobil alkalmazás, valamint a böngészőbővítmény milyen adatot
              kezel, és hova kerül az.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-[#f3f3f6] mb-3">A bejelentkezési adataid</h2>
            <p className="mb-3">
              Amikor bejelentkezel a Pala alkalmazásba vagy a bővítménybe, az a hivatalos e-Kréta
              szerverekkel kommunikál közvetlenül, TLS titkosítással. A Pala nem lát rá erre a
              forgalomra, és nem küldi el máshova.
            </p>
            <p>
              A bejelentkezés után kapott munkamenet-token AES-256-GCM titkosítással kerül eltárolásra,
              kizárólag a saját eszközödön. A titkosításhoz használt kulcs eszközenként véletlenszerűen
              jön létre telepítéskor, és soha nem hagyja el a gépedet. A mobil és asztali alkalmazás nem
              menti a jelszavadat munkamenetek között, csak a tokent.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-[#f3f3f6] mb-3">A böngészőbővítmény</h2>
            <p>
              A bővítmény a <code className="text-[#ff8800] font-mono text-xs">storage</code> engedélyt
              a beállításaid és a Krétából lekért adatok (órarend, jegyek, üzenetek) helyi tárolására
              használja, kizárólag a böngésződben. A <code className="text-[#ff8800] font-mono text-xs">tabs</code> és{" "}
              <code className="text-[#ff8800] font-mono text-xs">webNavigation</code> engedély azt teszi
              lehetővé, hogy a bővítmény felismerje, mikor vagy az e-Kréta oldalon. Egyik adat sem
              hagyja el az eszközödet a Kréta szerverein kívül.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-[#f3f3f6] mb-3">Ez a weboldal</h2>
            <p>
              A pala-app.hu nem használ követő sütit és nem futtat analitikát. A letölthető verzió
              számának megjelenítéséhez a böngésződ egy nyilvános, személyes adatot nem tartalmazó
              lekérdezést küld a GitHub API-nak. Ezen kívül a weboldal semmilyen adatot nem küld
              harmadik félnek.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-[#f3f3f6] mb-3">Adattörlés</h2>
            <p>
              Mivel minden adat helyben, a te eszközödön tárolódik, a törléshez elég kijelentkezni az
              alkalmazásból, vagy törölni a konfigurációs mappát (<code className="text-[#ff8800] font-mono text-xs">~/.config/pala</code>{" "}
              Linuxon és macOS-en, illetve a Windows-os felhasználói profilban). Nincs központi
              fiók vagy szerver, amit ehhez értesíteni kellene.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-[#f3f3f6] mb-3">Kapcsolat</h2>
            <p>
              Kérdés vagy hibabejelentés esetén nyiss egy issue-t a{" "}
              <a
                href="https://github.com/CsPS0/pala/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#ff8800] hover:underline"
              >
                GitHub repóban
              </a>
              . A Pala nem hivatalos projekt, nem áll kapcsolatban az eKréta Informatikai Zrt.-vel.
            </p>
          </section>
        </div>
      </main>

      <footer className="border-t border-[#28282d] bg-[#151518] py-6 px-4 text-center text-xs text-[#8c8c94]">
        <span>Pala — Nyílt forráskódú Kréta Kliens</span>
      </footer>
    </div>
  );
}
