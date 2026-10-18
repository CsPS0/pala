"use client";

import { useEffect, useState } from "react";
import { Moon, Sun } from "lucide-react";

type Theme = "light" | "dark";

/** Switches between the light and dark theme; the choice survives reloads (see the script in layout.tsx). */
export function ThemeToggle() {
  // null until mounted: the server cannot know the theme the head script picked.
  const [theme, setTheme] = useState<Theme | null>(null);

  useEffect(() => {
    const root = document.documentElement;
    // A client-side re-render of <html> (e.g. after a hydration error) drops the attribute the head script set.
    if (root.dataset.theme !== "light" && root.dataset.theme !== "dark") {
      let stored: string | null = null;
      try {
        stored = localStorage.getItem("pala-theme");
      } catch {
        // Storage blocked: fall back to the system setting.
      }
      root.dataset.theme =
        stored === "light" || stored === "dark"
          ? stored
          : matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
    }
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setTheme(root.dataset.theme === "light" ? "light" : "dark");
  }, []);

  const toggle = () => {
    const next: Theme = theme === "light" ? "dark" : "light";
    document.documentElement.dataset.theme = next;
    setTheme(next);
    try {
      localStorage.setItem("pala-theme", next);
    } catch {
      // Storage blocked (private mode): the theme still applies for this page view.
    }
  };

  const label = theme === "light" ? "Sötét téma" : "Világos téma";

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={label}
      title={label}
      className="w-9 h-9 inline-flex items-center justify-center rounded-xl bg-card border border-border text-muted hover:text-fg transition-colors cursor-pointer"
    >
      {theme === null ? null : theme === "light" ? <Moon size={16} /> : <Sun size={16} />}
    </button>
  );
}
