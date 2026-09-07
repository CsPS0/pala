import React from "react";
import { CheckCircle2, Clock, Calendar } from "lucide-react";

export function Roadmap() {
  const sections = [
    {
      title: "Már elérhető",
      subtitle: "Befejezett funkciók",
      badgeClass: "bg-[#30d158]/10 text-[#30d158] border-[#30d158]/30",
      icon: CheckCircle2,
      items: [
        "Natív asztali felület (Windows, Linux, macOS)",
        "Reszponzív mobil felület (Android & iOS)",
        "Interaktív terminálos TUI kliens (Scoop, Homebrew, APT)",
        "Manifest V3 böngészőbővítmény (Chrome, Brave, Edge) popup gyorsnézettel és heti vezérlőpulttal",
        "Élő órarendi visszaszámláló & szünetjelző",
        "Célátlag & Szellem jegy kalkulátor",
        "250 órás hiányzásfigyelő & szülői igazolás generátor",
        "Tanári üzenetküldő & válaszkezelő",
        "Pala Wrapped 9:16 Story kép export",
        "100% offline gyorsítótár AES-256 titkosítással",
      ],
    },
    {
      title: "Hamarosan",
      subtitle: "Aktív fejlesztés alatt",
      badgeClass: "bg-[#ff8800]/10 text-[#ff8800] border-[#ff8800]/30",
      icon: Clock,
      items: [
        "Intelligens tanulmányi előrejelzés és heti elemzés",
        "Interaktív házi feladat határidő naptár widget",
        "Továbbfejlesztett vizsga- és dolgozattervező modul",
        "Testreszabható témaszínek és betűtípusok",
      ],
    },
    {
      title: "Későbbi tervek",
      subtitle: "Tervezett jövőbeli bővítések",
      badgeClass: "bg-[#8c8c94]/10 text-[#8c8c94] border-[#8c8c94]/30",
      icon: Calendar,
      items: [
        "Automatikus órarendi szinkronizáció Google Calendar és Apple Naptár felé",
        "Közösségi tanulási modul és jegyzetmegosztó",
        "Widget támogatás Windows és macOS asztalon",
      ],
    },
  ];

  return (
    <section id="utemterv" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full overflow-hidden">
      <div className="text-center max-w-2xl mx-auto mb-10 sm:mb-14">
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-[#f3f3f6]">Fejlesztési Ütemterv</h2>
        <p className="text-[#8c8c94] text-base">
          Kövesd nyomon, min dolgozunk jelenleg és milyen újítások érkeznek a következő verziókban.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {sections.map((sec) => {
          const IconComp = sec.icon;
          return (
            <div key={sec.title} className="bg-[#1b1b1f] border border-[#28282d] p-5 sm:p-7 rounded-2xl sm:rounded-3xl flex flex-col justify-between">
              <div>
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="text-lg font-bold text-[#f3f3f6]">{sec.title}</h3>
                    <p className="text-xs text-[#8c8c94] font-semibold">{sec.subtitle}</p>
                  </div>
                  <div className={`p-2 rounded-xl border ${sec.badgeClass}`}>
                    <IconComp size={18} />
                  </div>
                </div>

                <ul className="space-y-3">
                  {sec.items.map((item) => (
                    <li key={item} className="flex items-start gap-2.5 text-xs sm:text-sm text-[#8c8c94]">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#ff8800] shrink-0 mt-2" />
                      <span className="leading-relaxed">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
