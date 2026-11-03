import React from "react";
import { Clock, Calculator, CalendarX, Mail, Sparkles, WifiOff } from "lucide-react";

// Each card answers a question a student actually asks, in everyday words.
// Technical details (encryption, export formats) live in the docs.
const FEATURES = [
  {
    icon: Clock,
    title: "Mikor kezdődik a következő óra?",
    description:
      "Látod, mennyi van még hátra az órából, melyik teremben leszel, és azt is, ha egy óra elmarad vagy helyettesítés lesz.",
  },
  {
    icon: Calculator,
    title: "Hány ötös kell még?",
    description:
      "Megmutatja, hány jó jegy kell a kívánt jegyhez, és kipróbálhatod, hogyan változna az átlagod egy következő jeggyel.",
  },
  {
    icon: CalendarX,
    title: "Hány órát hiányozhatok még?",
    description:
      "Követi a hiányzásaidat a 250 órás határig, és külön mutatja, mi igazolt, és mi vár még igazolásra.",
  },
  {
    icon: Mail,
    title: "Üzenet a tanárodnak",
    description: "Írj a tanáraidnak, és olvasd el, amit küldtek, ugyanott, ahol a jegyeidet is látod.",
  },
  {
    icon: Sparkles,
    title: "Az éved egy képben",
    description: "Év végén összefoglaló képet készít a jegyeidből és a hiányzásaidból, amit megoszthatsz a barátaiddal.",
  },
  {
    icon: WifiOff,
    title: "Akkor is működik, ha a Kréta akadozik",
    description:
      "A legutóbb letöltött adataidat akkor is látod, ha nincs internet, vagy a Kréta épp nem elérhető.",
  },
];

export function Features() {
  return (
    <section id="funkciok" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full">
      <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
        <p className="text-xs sm:text-sm font-extrabold uppercase tracking-widest text-primary mb-2">Funkciók</p>
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-fg">Mire jó a Pala?</h2>
        <p className="text-muted text-base">Ugyanazt tudja telefonon, számítógépen és a böngészőben.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {FEATURES.map((item) => {
          const IconComp = item.icon;
          return (
            <div key={item.title} className="bg-card border border-border p-5 rounded-xl">
              <div className="w-10 h-10 rounded-lg bg-primary/10 text-primary border border-primary/25 flex items-center justify-center mb-4">
                <IconComp size={20} />
              </div>
              <h3 className="text-lg font-bold text-fg mb-2">{item.title}</h3>
              <p className="text-base text-muted leading-relaxed">{item.description}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}
