import React from "react";
import { CheckCircle2, Clock, Calendar } from "lucide-react";

export function Roadmap() {
  const sections = [
    {
      title: "Már elérhető",
      subtitle: "Ezt tudja most",
      badgeClass: "bg-sidebar text-fg border-border",
      icon: CheckCircle2,
      items: [
        "Alkalmazás számítógépre (Windows, Mac, Linux)",
        "Alkalmazás androidos telefonra",
        "Böngészőbővítmény Chrome-ba, Edge-be és Brave-be",
        "Világos és sötét megjelenés",
        "Visszaszámláló a következő óráig, helyettesítések és elmaradó órák",
        "A és B hét felismerése",
        "Jegykalkulátor: mennyi kell még a kívánt jegyhez",
        "Hiányzásfigyelő a 250 órás határig, a szülői igazolásokkal",
        "Üzenetek a tanároknak",
        "Órarend a saját naptáradba",
        "Éves összefoglaló kép (Pala Wrapped)",
        "Net nélkül is mutatja a legutóbbi adataidat",
        "Belépés kétlépcsős azonosítással is",
        "Haladóknak: parancssori változat",
      ],
    },
    {
      title: "Hamarosan",
      subtitle: "Ezen dolgozunk",
      badgeClass: "bg-sidebar text-fg border-border",
      icon: Clock,
      items: [
        "Heti összefoglaló: mi vár rád a jövő héten",
        "Házi feladatok határidőnaptárban",
        "Dolgozattervező: mennyi múlik a következő dolgozaton",
        "Saját színek választása",
      ],
    },
    {
      title: "Későbbi tervek",
      subtitle: "Ezt tervezzük",
      badgeClass: "bg-sidebar text-muted border-border",
      icon: Calendar,
      items: [
        "Automatikus szinkron a Google és az Apple naptárával",
        "Jegyzetek megosztása az osztálytársakkal",
        "Kis ablak (widget) az asztalra Windowson és Macen",
        "iPhone-alkalmazás",
      ],
    },
  ];

  return (
    <section id="utemterv" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full overflow-hidden">
      <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-fg">Mi jön még?</h2>
        <p className="text-muted text-base">
          Mit tud már a Pala, és min dolgozunk most.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {sections.map((sec, i) => {
          const IconComp = sec.icon;
          return (
            <div key={sec.title} className={`bg-card border border-border p-5 sm:p-6 rounded-xl ${i === 0 ? "md:col-span-2" : ""}`}>
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-bold text-fg">{sec.title}</h3>
                    <p className="text-sm text-muted font-semibold">{sec.subtitle}</p>
                  </div>
                  <div className={`p-2 rounded-xl border ${sec.badgeClass}`}>
                    <IconComp size={18} />
                  </div>
                </div>

                <ul className={`grid gap-y-2 gap-x-8 ${i === 0 ? "sm:grid-cols-2" : ""}`}>
                  {sec.items.map((item) => (
                    <li key={item} className="flex items-start gap-2.5 text-sm sm:text-base text-muted">
                      <span className="w-1.5 h-1.5 rounded-full bg-muted shrink-0 mt-2.5" />
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
