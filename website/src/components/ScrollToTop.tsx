"use client";

import React, { useState, useEffect } from "react";
import { ArrowUp } from "lucide-react";

export function ScrollToTop() {
  const [isVisible, setIsVisible] = useState(false);
  const [isScrolling, setIsScrolling] = useState(false);

  useEffect(() => {
    const toggleVisibility = () => {
      if (typeof window !== "undefined") {
        if (window.scrollY > 200) {
          setIsVisible(true);
        } else {
          setIsVisible(false);
        }
      }
    };

    window.addEventListener("scroll", toggleVisibility, { passive: true });
    toggleVisibility();

    return () => {
      window.removeEventListener("scroll", toggleVisibility);
    };
  }, []);

  const scrollToTop = () => {
    if (typeof window === "undefined" || isScrolling) return;

    const startPosition = window.scrollY || window.pageYOffset || document.documentElement.scrollTop;
    if (startPosition <= 0) return;

    setIsScrolling(true);
    const duration = Math.min(800, Math.max(450, startPosition * 0.35));
    let startTimestamp: number | null = null;

    // Cubic ease-in-out curve for natural deceleration
    const easeInOutCubic = (t: number): number => {
      return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
    };

    const step = (timestamp: number) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const elapsed = timestamp - startTimestamp;
      const progress = Math.min(elapsed / duration, 1);
      const ease = easeInOutCubic(progress);

      window.scrollTo(0, startPosition * (1 - ease));

      if (progress < 1) {
        window.requestAnimationFrame(step);
      } else {
        setIsScrolling(false);
      }
    };

    window.requestAnimationFrame(step);
  };

  return (
    <button
      onClick={scrollToTop}
      aria-label="Vissza az oldal tetejére"
      className={`fixed bottom-5 right-5 sm:bottom-8 sm:right-8 z-40 w-12 h-12 sm:w-14 sm:h-14 rounded-full bg-[#ff8800] hover:bg-[#ffa033] text-black shadow-[0_0_25px_rgba(255,136,0,0.45)] hover:shadow-[0_0_40px_rgba(255,136,0,0.65)] flex items-center justify-center transition-all duration-300 cursor-pointer group hover:-translate-y-1 active:scale-95 ${
        isScrolling ? "animate-pulse scale-105 shadow-[0_0_45px_rgba(255,136,0,0.8)]" : ""
      } ${
        isVisible ? "opacity-100 scale-100 pointer-events-auto" : "opacity-0 scale-75 pointer-events-none"
      }`}
    >
      <ArrowUp
        size={24}
        strokeWidth={2.5}
        className={`transition-transform duration-300 ${
          isScrolling ? "-translate-y-1.5 scale-110" : "group-hover:-translate-y-1"
        }`}
      />
    </button>
  );
}
