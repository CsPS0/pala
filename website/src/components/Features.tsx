import React from "react";
import { Clock, Calculator, ShieldAlert, Mail, Sparkles, Database } from "lucide-react";

export function Features() {
  const features = [
    {
      icon: Clock,
      title: "Élő Visszaszámláló & Órarend",
      description:
        "Valós idejű órarendi visszaszámlálás, szünetjelző, teremszámok, tanárok neve és elmaradó tanórák azonnali megjelenítése.",
    },
    {
      icon: Calculator,
      title: "Célátlag & Szellem Jegy Kalkulátor",
      description:
        "Kiszámolja, hogy pontosan hány darab 5-ös szükséges a kívánt tanulmányi átlag eléréséhez, és azonnal szimulálhatsz feltételes jegyeket.",
    },
    {
      icon: ShieldAlert,
      title: "250 Órás Veszélyzóna & Igazolás",
      description:
        "Precíz hiányzásfigyelő a 250 órás törvényi határhoz és 30%-os tantárgyi limithez, szülői keretmérővel és hivatalos kérvény sablonnal.",
    },
    {
      icon: Mail,
      title: "Közvetlen Tanári Üzenetküldés",
      description:
        "Írj levelet tanáraidnak a beépített tantárgyi és órarendi névsorból, vagy válaszolj a beérkezett üzenetekre egy kattintással.",
    },
    {
      icon: Sparkles,
      title: "Pala Wrapped & 9:16 Story Megosztás",
      description:
        "Generálj összefoglaló statisztikai posztert az évedről 9:16 formátumban, amelyet azonnal megoszthatsz Instagramra vagy Facebookra.",
    },
    {
      icon: Database,
      title: "Offline gyorsítótár és titkosítás",
      description:
        "Minden adat és hitelesítő adat helyben, AES-256 titkosítással tárolódik. Nincs köztes szerver, nincs telemetria és nincsenek hirdetések.",
    },
  ];

  return (
    <section id="funkciok" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full">
      {/* Feature Cards Grid */}
      <div>
        <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
          <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-fg">
            Funkciók
          </h2>
          <p className="text-muted text-base">
            Ugyanazok a funkciók asztalon, telefonon és a böngészőben.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {features.map((item, idx) => {
            const IconComp = item.icon;
            return (
              <div
                key={idx}
                className="bg-card border border-border p-5 rounded-xl"
              >
                <div className="w-10 h-10 rounded-lg bg-primary/10 text-primary border border-primary/20 flex items-center justify-center mb-4">
                  <IconComp size={22} />
                </div>
                <h3 className="text-base font-bold text-fg mb-2">{item.title}</h3>
                <p className="text-sm text-muted leading-relaxed">{item.description}</p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
