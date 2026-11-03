import React from "react";
import Link from "next/link";
import { ArrowRight, Ban, Building2, Laptop } from "lucide-react";

// "No middle server" explained with a picture instead of jargon: your device
// talks to Kréta directly, and nothing of ours sits in between.
const POINTS = [
  {
    title: "Egyenesen a Krétával beszél",
    text: "A Pala a te eszközödről kapcsolódik a Krétához, ugyanúgy, mint a hivatalos alkalmazás. Nincs közben semmilyen más szerver.",
  },
  {
    title: "Az adataid nálad maradnak",
    text: "A belépésed és a jegyeid csak a saját telefonodon vagy gépeden vannak, titkosítva. Mi semmit nem látunk belőlük.",
  },
  {
    title: "Nincs reklám, nincs követés",
    text: "Bárki megnézheti, mit csinál a program, mert a kódja nyilvános. Nem gyűjtünk statisztikát rólad.",
  },
];

function Node({ icon: Icon, title, sub }: { icon: React.ComponentType<{ size?: number }>; title: string; sub: string }) {
  return (
    <div className="flex flex-col items-center text-center gap-2 bg-card border border-border rounded-xl px-4 py-4 w-full sm:w-48">
      <div className="w-11 h-11 rounded-lg bg-sidebar border border-border text-fg flex items-center justify-center">
        <Icon size={22} />
      </div>
      <div className="text-base font-bold text-fg">{title}</div>
      <div className="text-sm text-muted">{sub}</div>
    </div>
  );
}

export function Security() {
  return (
    <section
      id="hogyan-mukodik"
      aria-labelledby="how-heading"
      className="py-12 sm:py-16 px-4 sm:px-6 max-w-5xl mx-auto w-full text-center scroll-mt-24"
    >
      <h2 id="how-heading" className="text-3xl sm:text-4xl font-black tracking-tight text-fg mb-3">
        Hogyan működik?
      </h2>
      <p className="text-base text-muted max-w-2xl mx-auto mb-8">
        A Pala a Kréta saját adataival dolgozik, csak átláthatóbban mutatja meg őket.
      </p>

      {/* Device -> Kréta, with "our server" crossed out in between */}
      <div
        className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4 mb-10"
        role="img"
        aria-label="A te eszközöd közvetlenül a Krétához kapcsolódik, köztes szerver nélkül."
      >
        <Node icon={Laptop} title="A te eszközöd" sub="telefon, gép vagy böngésző" />
        <div className="text-muted text-2xl font-black sm:rotate-0 rotate-90" aria-hidden="true">→</div>
        <div className="flex flex-col items-center text-center gap-2 border border-dashed border-border rounded-xl px-4 py-4 w-full sm:w-44 opacity-80">
          <div className="w-11 h-11 rounded-lg border border-dashed border-border text-muted flex items-center justify-center">
            <Ban size={22} />
          </div>
          <div className="text-base font-bold text-muted line-through">Pala szerver</div>
          <div className="text-sm text-muted">nincs ilyen</div>
        </div>
        <div className="text-muted text-2xl font-black sm:rotate-0 rotate-90" aria-hidden="true">→</div>
        <Node icon={Building2} title="Kréta" sub="a hivatalos szerver" />
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-left mb-6">
        {POINTS.map((p) => (
          <div key={p.title} className="bg-card border border-border rounded-xl p-5">
            <h3 className="text-lg font-bold text-fg mb-2">{p.title}</h3>
            <p className="text-base text-muted leading-relaxed">{p.text}</p>
          </div>
        ))}
      </div>

      <Link href="/adatvedelem" className="inline-flex items-center gap-1.5 text-base font-bold text-fg hover:underline">
        Részletesen az adatvédelemről
        <ArrowRight size={16} />
      </Link>
    </section>
  );
}
