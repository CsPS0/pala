import type { Metadata } from "next";
import { Footer } from "@/components/Footer";

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
    <div className="min-h-screen bg-[var(--bg)] text-fg flex flex-col pt-[68px]">
      <main className="flex-1 max-w-3xl mx-auto w-full px-4 sm:px-6 py-12 sm:py-16">
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2">Adatvédelmi tájékoztató</h1>
        <p className="text-xs text-subtle mb-10">Utolsó frissítés: 2026. november</p>

        <div className="space-y-10 text-sm text-fg leading-relaxed">
          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Kinek szól ez a tájékoztató</h2>
            <p>
              A Pala egy nem hivatalos, nyílt forráskódú kliens az e-Kréta rendszerhez. Nincs saját
              szervere, saját felhasználói fiókja vagy adatbázisa. Ez az oldal azt írja le, hogy a
              weboldal, az asztali és mobil alkalmazás, valamint a böngészőbővítmény milyen adatot
              kezel, és hova kerül az.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">A bejelentkezési adataid</h2>
            <p className="mb-3">
              Amikor bejelentkezel a Pala alkalmazásba vagy a bővítménybe, az a hivatalos e-Kréta
              szerverekkel kommunikál közvetlenül, TLS titkosítással. A Pala nem lát rá erre a
              forgalomra, és nem küldi el máshova.
            </p>
            <p>
              A bejelentkezés után kapott munkamenet-token AES-256-GCM titkosítással kerül eltárolásra,
              kizárólag a saját eszközödön. A titkosításhoz használt kulcs eszközenként véletlenszerűen
              jön létre az első indításkor (az alkalmazásban a rendszer kulcstárában), és soha nem hagyja el az eszközödet. A mobil és asztali alkalmazás nem
              menti a jelszavadat munkamenetek között, csak a tokent.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">A böngészőbővítmény</h2>
            <p className="mb-3">
              <strong>A bővítmény egyetlen célja:</strong> a saját e-Kréta adataid (jegyek, órarend,
              mulasztások, feladatok, üzenetek) áttekinthető megjelenítése a böngésződben. Nem gyűjt
              adatot, nem jelenít meg hirdetést, és nem küld semmit a Kréta szerverein kívül máshova.
            </p>
            <p>
              A bővítmény csak a <code className="text-primary font-mono text-xs">*.e-kreta.hu</code> oldalakhoz
              fér hozzá. A <code className="text-primary font-mono text-xs">storage</code> engedélyt a beállításaid
              és a Krétából lekért adatok (órarend, jegyek, üzenetek) helyi tárolására használja, kizárólag a
              böngésződben. A <code className="text-primary font-mono text-xs">webNavigation</code> a Kréta
              bejelentkezési oldalának felismeréséhez kell, az <code className="text-primary font-mono text-xs">alarms</code>{" "}
              a háttérben futó frissítéshez, a <code className="text-primary font-mono text-xs">notifications</code>{" "}
              az értesítésekhez, a <code className="text-primary font-mono text-xs">sidePanel</code> pedig az
              oldalsávhoz. Egyik adat sem hagyja el az eszközödet a Kréta szerverein kívül.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Ez a weboldal</h2>
            <p>
              A pala-app.hu nem használ követő sütit és nem futtat analitikát. A legfrissebb kiadás
              adatait és a Történet oldalon felsorolt projektek verzióit a weboldal az összeállításakor
              kéri le a GitHubtól, a böngésződ ezért nem küld kérést a GitHubnak. A weboldalt a Vercel szolgálja ki,
              amely a kéréseket a saját szokásos naplóiban rögzítheti. Ezen kívül a weboldal semmilyen
              adatot nem küld harmadik félnek.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Adattörlés</h2>
            <p>
              Mivel minden adat helyben, a te eszközödön tárolódik, a törléshez elég kijelentkezni az
              alkalmazásból, vagy törölni a konfigurációs mappát (Linuxon és macOS-en <code className="text-primary font-mono text-xs">~/.config/pala</code>,
              Windows-on <code className="text-primary font-mono text-xs">%USERPROFILE%\.config\pala</code>) és a gyorsítótár-mappát
              (Linuxon <code className="text-primary font-mono text-xs">~/.cache/pala</code>, macOS-en{" "}
              <code className="text-primary font-mono text-xs">~/Library/Caches/pala</code>, Windows-on{" "}
              <code className="text-primary font-mono text-xs">%LOCALAPPDATA%\pala\cache</code>). Telefonon elég az alkalmazást eltávolítani. Nincs központi
              fiók vagy szerver, amit ehhez értesíteni kellene.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Kapcsolat</h2>
            <p>
              Kérdés vagy hibabejelentés esetén nyiss egy issue-t a{" "}
              <a
                href="https://github.com/CsPS0/pala/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                GitHub repóban
              </a>
              . A Pala nem hivatalos projekt, nem áll kapcsolatban az eKréta Informatikai Zrt.-vel.
            </p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
