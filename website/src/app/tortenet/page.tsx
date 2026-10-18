import type { Metadata } from "next";
import { ClientHistory } from "@/components/ClientHistory";
import { CommunityProjects } from "@/components/CommunityProjects";
import { Footer } from "@/components/Footer";

export const metadata: Metadata = {
  title: "A Kréta-kliensek története",
  description:
    "A diákok által írt Kréta-kliensek rövid története a Szivacs Naplótól a Paláig, és más nyílt forráskódú Kréta- és Neptun-projektek.",
  alternates: {
    canonical: "/tortenet",
  },
};

export default function HistoryPage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-fg flex flex-col font-sans selection:bg-primary/30 selection:text-primary pt-[68px]">
      {/* Main Content Area */}
      <main className="flex-1 max-w-6xl mx-auto w-full px-4 sm:px-6 py-10 sm:py-16">
        <ClientHistory />
        <CommunityProjects />
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}
