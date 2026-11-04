import type { Metadata } from "next";
import Link from "next/link";
import { Footer } from "@/components/Footer";

export const metadata: Metadata = {
  title: "Felhasználási feltételek",
  description:
    "A Pala ingyenes, nyílt forráskódú, nem hivatalos Kréta-kliens. Mire való, mit vállal és mit nem.",
  alternates: {
    canonical: "/felhasznalasi-feltetelek",
  },
};

export default function TermsPage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-fg flex flex-col pt-[68px]">
      <main className="flex-1 max-w-3xl mx-auto w-full px-4 sm:px-6 py-12 sm:py-16">
        <h1 className="text-2xl sm:text-3xl font-black tracking-tight mb-2">Felhasználási feltételek</h1>
        <p className="text-xs text-subtle mb-10">Utolsó frissítés: 2026. november</p>

        <div className="space-y-10 text-sm text-fg leading-relaxed">
          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Mi a Pala</h2>
            <p>
              A Pala ingyenes, nyílt forráskódú kliens az e-Kréta rendszerhez: terminálos program,
              asztali és mobil alkalmazás, valamint böngészőbővítmény. Nem hivatalos termék, nem áll
              kapcsolatban az eKréta Informatikai Zrt.-vel, és nem helyettesíti a hivatalos Kréta
              felületeket. A Kréta az eKréta Informatikai Zrt. védjegye.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Használat</h2>
            <p className="mb-3">
              A Pala használatához a saját Kréta-fiókoddal jelentkezel be. A Pala a te nevedben, a
              hivatalos Kréta szerverekről kéri le az adataidat, és csak a te eszközödön tárolja őket.
              Saját szervere és saját felhasználói fiókja nincs.
            </p>
            <p>
              A bejelentkezési adataidért és azok biztonságáért te felelsz. A Pala használata közben is
              a Kréta saját szabályai érvényesek; a Pala nem kerüli meg a Kréta biztonsági
              beállításait (például a kétlépcsős azonosítást).
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Felelősség</h2>
            <p>
              A Pala az MIT licenc alatt, „ahogy van” alapon érhető el, mindenféle garancia nélkül. A
              megjelenített adatok a Krétából származnak; ha eltérést látsz, a hivatalos Kréta felület
              az irányadó. A számított értékek (például átlagok, hiányzási keret) tájékoztató jellegűek.
              A Kréta szolgáltatás elérhetőségéért és változásaiért a Pala nem felel.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Adatkezelés</h2>
            <p>
              Hogy a Pala milyen adatot kezel és hol tárolja, azt az{" "}
              <Link href="/adatvedelem" className="text-primary hover:underline">
                adatvédelmi tájékoztató
              </Link>{" "}
              írja le.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-fg mb-3">Változások és kapcsolat</h2>
            <p>
              Ezek a feltételek a projekttel együtt változhatnak; a mindenkori változat ezen az oldalon
              olvasható. Kérdés vagy hibabejelentés esetén nyiss egy issue-t a{" "}
              <a
                href="https://github.com/CsPS0/pala/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="text-primary hover:underline"
              >
                GitHub repóban
              </a>
              .
            </p>
          </section>
        </div>
      </main>

      <Footer />
    </div>
  );
}
