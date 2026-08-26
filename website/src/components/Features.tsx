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
      title: "100% Offline Gyorsítótár & Titkosítás",
      description:
        "Minden adat és hitelesítő adat helyben, AES-256 titkosítással tárolódik. Nincs köztes szerver, nincs telemetria és nincsenek hirdetések.",
    },
  ];

  return (
    <section id="funkciok" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full overflow-hidden">
      <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-14">
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-[#f3f3f6]">
          Minden, amire a tanév során szükséged van
        </h2>
        <p className="text-[#8c8c94] text-base">
          A Pala nem csupán egy kliens, hanem egy intelligens tanulói asszisztens az összes eszközödön.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {features.map((item, idx) => {
          const IconComp = item.icon;
          return (
            <div
              key={idx}
              className="bg-[#1b1b1f] border border-[#28282d] hover:border-[#ff8800] p-7 rounded-3xl transition-all hover:-translate-y-1 hover:bg-[#222227] group"
            >
              <div className="w-12 h-12 rounded-2xl bg-[#ff8800]/10 text-[#ff8800] border border-[#ff8800]/20 flex items-center justify-center mb-5 group-hover:scale-110 transition-transform">
                <IconComp size={22} />
              </div>
              <h3 className="text-lg font-bold text-[#f3f3f6] mb-2.5">{item.title}</h3>
              <p className="text-sm text-[#8c8c94] leading-relaxed">{item.description}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}
