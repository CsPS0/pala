import React from "react";
import { Hero } from "@/components/Hero";
import { Wave } from "@/components/Wave";
import { Features } from "@/components/Features";
import { Security } from "@/components/Security";
import { PlatformDownloadGrid } from "@/components/PlatformDownloadGrid";
import { Roadmap } from "@/components/Roadmap";
import { HistoryTeaser } from "@/components/HistoryTeaser";
import { Footer } from "@/components/Footer";

export default function HomePage() {
  return (
    <div className="flex flex-col min-h-screen bg-[var(--bg)] text-fg">
      <main className="flex flex-col items-center w-full">
        <Hero />
        <Wave />
        <Features />
        <Wave />
        <PlatformDownloadGrid />
        <Wave />
        <Security />
        <Wave />
        <Roadmap />
        <HistoryTeaser />
      </main>
      <Footer />
    </div>
  );
}
