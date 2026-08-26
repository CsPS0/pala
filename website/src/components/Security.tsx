import React from "react";
import { ShieldCheck, Lock, EyeOff, Key } from "lucide-react";

export function Security() {
  const points = [
    {
      icon: Key,
      title: "Közvetlen Kréta API Kapcsolat",
      description:
        "Az alkalmazás közvetlenül a hivatalos e-Kréta szerverekkel kommunikál TLS 1.3 titkosítással, harmadik fél szervereinek beiktatása nélkül.",
    },
    {
      icon: Lock,
      title: "AES-256 Helyi Titkosítás",
      description:
        "A bejelentkezési adatok és munkamenet-tokenek kizárólag a saját eszközödön, titkosított kulcstárban kerülnek eltárolásra.",
    },
    {
      icon: EyeOff,
      title: "Zero Tracking & Zero Ads",
      description:
        "A Pala semmilyen felhasználói adatot, telemetriát vagy analitikát nem gyűjt, és 100%-ban mentes a reklámoktól.",
    },
  ];

  return (
    <section id="biztonsag" className="py-12 sm:py-16 px-4 sm:px-6 max-w-6xl mx-auto w-full overflow-hidden">
      <div className="bg-[#1b1b1f] border border-[#28282d] p-5 sm:p-12 rounded-2xl sm:rounded-3xl">
        <div className="max-w-2xl mb-10">
          <div className="inline-flex items-center gap-2 text-xs font-bold text-[#30d158] mb-3 bg-[#30d158]/10 border border-[#30d158]/30 px-3 py-1 rounded-full">
            <ShieldCheck size={15} />
            <span>Biztonság & Adatvédelem</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black tracking-tight text-[#f3f3f6] mb-3">
            A tanulmányi adataid kizárólag a tiéd
          </h2>
          <p className="text-sm text-[#8c8c94] leading-relaxed">
            Minden lekérdezés és művelet transzparens, nyílt forráskódú és függetlenül ellenőrizhető.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {points.map((pt, idx) => {
            const IconComp = pt.icon;
            return (
              <div key={idx} className="bg-[#151518] border border-[#28282d] p-6 rounded-2xl">
                <div className="w-10 h-10 rounded-xl bg-[#30d158]/10 text-[#30d158] flex items-center justify-center mb-4">
                  <IconComp size={18} />
                </div>
                <h3 className="text-base font-bold text-[#f3f3f6] mb-2">{pt.title}</h3>
                <p className="text-xs text-[#8c8c94] leading-relaxed">{pt.description}</p>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
