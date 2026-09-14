import type { Metadata } from "next";
import { ClientHistory } from "@/components/ClientHistory";
import { Footer } from "@/components/Footer";

export const metadata: Metadata = {
  title: "A Kréta-kliensek története",
  description:
    "A magyar nyílt forráskódú Kréta-kliensek fejlődése és kronológiai idővonala a Szivacs Naplótól a Paláig.",
  alternates: {
    canonical: "/tortenet",
  },
};

export default function HistoryPage() {
  return (
    <div className="min-h-screen bg-[var(--bg)] text-[#f3f3f6] flex flex-col font-sans selection:bg-[#ff8800]/30 selection:text-[#ff8800] pt-[68px]">
      {/* Main Content Area */}
      <main className="flex-1 max-w-6xl mx-auto w-full px-4 sm:px-6 py-10 sm:py-16">
        <ClientHistory />
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}
