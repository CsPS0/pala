"use client";

import React, { useState, useEffect } from "react";
import { ArrowUp } from "lucide-react";

export function ScrollToTop() {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const toggleVisibility = () => setIsVisible(window.scrollY > 200);

    window.addEventListener("scroll", toggleVisibility, { passive: true });
    toggleVisibility();

    return () => {
      window.removeEventListener("scroll", toggleVisibility);
    };
  }, []);

  const scrollToTop = () => {
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    window.scrollTo({ top: 0, behavior: reduceMotion ? "auto" : "smooth" });
  };

  return (
    <button
      onClick={scrollToTop}
      aria-label="Vissza az oldal tetejére"
      className={`fixed bottom-5 right-5 sm:bottom-8 sm:right-8 z-40 w-12 h-12 rounded-lg bg-primary-fill hover:bg-primary-fill-hover text-on-primary border border-primary flex items-center justify-center transition-[background-color,opacity] duration-150 ease-out cursor-pointer ${
        isVisible ? "opacity-100 pointer-events-auto" : "opacity-0 pointer-events-none"
      }`}
    >
      <ArrowUp size={22} strokeWidth={2.5} />
    </button>
  );
}
