import React from "react";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { CONCEPT_ICONS } from "@/lib/icons";

const STATEMENTS = [
  "Közvetlenül a Krétához csatlakozik, köztes szerver nélkül.",
  "Az adataid csak a saját eszközödön tárolódnak.",
  "Nincs követés vagy reklám, a forráskód nyilvános.",
];

export function Security() {
  const Icon = CONCEPT_ICONS.privacy;
  return (
    <section
      id="biztonsag"
      aria-labelledby="security-heading"
      className="py-12 sm:py-16 px-4 sm:px-6 max-w-3xl mx-auto w-full text-center"
    >
      <div className="w-10 h-10 rounded-lg bg-card border border-border text-primary flex items-center justify-center mx-auto mb-4">
        <Icon size={20} />
      </div>
      <h2 id="security-heading" className="text-3xl sm:text-4xl font-black tracking-tight text-fg mb-6">
        Adatvédelem
      </h2>
      <ul className="space-y-2 text-base text-muted mb-6">
        {STATEMENTS.map((s) => (
          <li key={s}>{s}</li>
        ))}
      </ul>
      <Link
        href="/docs?page=security"
        className="inline-flex items-center gap-1.5 text-sm font-bold text-primary hover:underline"
      >
        Részletek a dokumentációban
        <ArrowRight size={14} />
      </Link>
    </section>
  );
}
