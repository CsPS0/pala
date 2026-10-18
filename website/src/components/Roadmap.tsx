import React from "react";
import { CheckCircle2, Clock, Calendar } from "lucide-react";

export function Roadmap() {
  const sections = [
    {
      title: "Már elérhető",
      subtitle: "Befejezett funkciók",
      badgeClass: "bg-primary/10 text-primary border-primary/30",
      icon: CheckCircle2,
      items: [
        "Asztali alkalmazás (Windows, Linux, macOS)",
        "Android alkalmazás",
        "Terminálos (TUI) kliens (Scoop, Homebrew, AUR, .deb)",
        "Böngészőbővítmény (Chrome, Edge, Brave, Firefox) felugró ablakkal, oldalsávval és teljes vezérlőpulttal",
        "Világos és sötét téma minden kliensben",
        "Élő órarendi visszaszámláló és szünetjelző",
        "A/B hét felismerése a Kréta adataiból",
        "Célátlag és Szellem Jegy kalkulátor",
        "250 órás hiányzásfigyelő és szülői igazolási keret",
        "Tanári üzenetküldés és válaszok",
        "Órarend exportálása naptárba (.ics)",
        "Pala Wrapped éves összegző",
        "Offline gyorsítótár, titkosított munkamenet-tárolás",
        "Bejelentkezés CAPTCHA-val vagy kétlépcsős azonosítással védett fiókkal",
      ],
    },
    {
      title: "Hamarosan",
      subtitle: "Aktív fejlesztés alatt",
      badgeClass: "bg-primary/10 text-primary border-primary/30",
      icon: Clock,
      items: [
        "Intelligens tanulmányi előrejelzés és heti elemzés",
        "Interaktív házi feladat határidő naptár widget",
        "Továbbfejlesztett vizsga- és dolgozattervező modul",
        "Testreszabható témaszínek",
      ],
    },
    {
      title: "Későbbi tervek",
      subtitle: "Tervezett jövőbeli bővítések",
      badgeClass: "bg-muted/10 text-muted border-muted/30",
      icon: Calendar,
      items: [
        "Automatikus naptárszinkron (Google Naptár, Apple Naptár)",
        "Közösségi tanulási modul és jegyzetmegosztó",
        "Asztali widgetek Windowsra és macOS-re",
        "iPhone-alkalmazás",
      ],
    },
  ];

  return (
    <section id="utemterv" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full overflow-hidden">
      <div className="text-center max-w-2xl mx-auto mb-8 sm:mb-10">
        <h2 className="text-3xl sm:text-4xl font-black tracking-tight mb-3 text-fg">Fejlesztési Ütemterv</h2>
        <p className="text-muted text-base">
          Kövesd nyomon, min dolgozunk jelenleg és milyen újítások érkeznek a következő verziókban.
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
                    <p className="text-xs text-muted font-semibold">{sec.subtitle}</p>
                  </div>
                  <div className={`p-2 rounded-xl border ${sec.badgeClass}`}>
                    <IconComp size={18} />
                  </div>
                </div>

                <ul className={`grid gap-y-2 gap-x-8 ${i === 0 ? "sm:grid-cols-2" : ""}`}>
                  {sec.items.map((item) => (
                    <li key={item} className="flex items-start gap-2.5 text-xs sm:text-sm text-muted">
                      <span className="w-1.5 h-1.5 rounded-full bg-primary-fill shrink-0 mt-2" />
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
