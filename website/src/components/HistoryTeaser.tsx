import React from "react";
import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { CONCEPT_ICONS } from "@/lib/icons";

/** Small card that points to the history page, which also lists the community projects. */
export function HistoryTeaser() {
  const Icon = CONCEPT_ICONS.history;
  return (
    <section className="py-12 sm:py-16 px-4 sm:px-6 max-w-3xl mx-auto w-full">
      <Link
        href="/tortenet"
        className="group flex items-center gap-4 bg-card border border-border hover:border-primary rounded-xl p-5 transition-colors duration-150"
      >
        <div className="w-10 h-10 rounded-lg bg-sidebar border border-border text-primary flex items-center justify-center shrink-0">
          <Icon size={20} />
        </div>
        <div className="flex-1 min-w-0">
          <h2 className="text-base font-extrabold text-fg">A Kréta-kliensek története és közösségi projektek</h2>
          <p className="text-sm text-muted mt-0.5">A diákok által írt kliensek a Szivacs Naplótól a Paláig, és más nyílt forráskódú projektek.</p>
        </div>
        <ArrowRight size={18} className="text-muted group-hover:text-primary shrink-0 transition-colors duration-150" />
      </Link>
    </section>
  );
}
