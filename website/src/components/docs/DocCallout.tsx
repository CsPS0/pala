"use client";

import React from "react";
import { Info, AlertTriangle, ShieldCheck } from "lucide-react";

export type CalloutType = "note" | "warning" | "security";

interface DocCalloutProps {
  type: CalloutType;
  title?: string;
  children: React.ReactNode;
}

const CALLOUT_STYLES: Record<
  CalloutType,
  {
    badge: string;
    directive: string;
    border: string;
    bg: string;
    accentText: string;
    iconBg: string;
    Icon: React.ComponentType<{ size?: number; className?: string }>;
  }
> = {
  note: {
    badge: "MEGJEGYZÉS",
    directive: ":::note",
    border: "border-primary/40",
    bg: "bg-primary/[0.07]",
    accentText: "text-primary",
    iconBg: "bg-primary/15 text-primary border-primary/30",
    Icon: Info,
  },
  warning: {
    badge: "FIGYELMEZTETÉS",
    directive: ":::warning",
    border: "border-primary/40",
    bg: "bg-primary/[0.07]",
    accentText: "text-primary",
    iconBg: "bg-primary/15 text-primary border-primary/30",
    Icon: AlertTriangle,
  },
  security: {
    badge: "BIZTONSÁG & ADATVÉDELEM",
    directive: ":::security",
    border: "border-primary/40",
    bg: "bg-primary/[0.07]",
    accentText: "text-primary",
    iconBg: "bg-primary/15 text-primary border-primary/30",
    Icon: ShieldCheck,
  },
};

export function DocCallout({ type, title, children }: DocCalloutProps) {
  const style = CALLOUT_STYLES[type];
  const IconComp = style.Icon;

  return (
    <aside
      role="note"
      aria-label={title || style.badge}
      className={`rounded-2xl border ${style.border} ${style.bg} p-4 sm:p-5 space-y-2.5 my-4`}
    >
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <div className="flex items-center gap-2.5">
          <span
            className={`w-7 h-7 rounded-lg border flex items-center justify-center shrink-0 ${style.iconBg}`}
          >
            <IconComp size={15} />
          </span>
          <span className={`text-xs font-extrabold uppercase tracking-wider ${style.accentText}`}>
            {title || style.badge}
          </span>
        </div>
        <code className="text-[10px] font-mono text-muted bg-bg/80 border border-border px-2 py-0.5 rounded">
          {style.directive}
        </code>
      </div>
      <div className="text-xs sm:text-sm text-fg leading-relaxed pl-0 sm:pl-9 space-y-1.5">
        {children}
      </div>
    </aside>
  );
}
