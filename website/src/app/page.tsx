import React from "react";
import { Hero } from "@/components/Hero";
import { Wave } from "@/components/Wave";
import { Roadmap } from "@/components/Roadmap";
import { CommunityProjects } from "@/components/CommunityProjects";
import { Footer } from "@/components/Footer";

export default function HomePage() {
  return (
    <div className="flex flex-col min-h-screen bg-[var(--bg)] text-[#f0f0f5]">
      <main className="flex flex-col items-center w-full">
        <Hero />
        <Wave />
        <Roadmap />
        <Wave />
        <CommunityProjects />
      </main>
      <Footer />
    </div>
  );
}
