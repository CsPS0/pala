import type { Metadata } from "next";
import { ClientHistory } from "@/components/ClientHistory";
import { CommunityProjects } from "@/components/CommunityProjects";
import { Footer } from "@/components/Footer";
import { PROJECTS } from "@/content/communityProjects";
import { fetchLatestRelease } from "@/lib/githubReleases";

export const metadata: Metadata = {
  title: "A Kréta-kliensek története",
  description:
    "A diákok által írt Kréta-kliensek rövid története a Szivacs Naplótól a Paláig, és más nyílt forráskódú Kréta- és Neptun-projektek.",
  alternates: {
    canonical: "/tortenet",
  },
};

/** Latest release tag of each active project, looked up once at build time. */
async function fetchCommunityVersions(): Promise<Record<string, string>> {
  const active = PROJECTS.filter((p) => !p.isArchived);
  const releases = await Promise.all(active.map((p) => fetchLatestRelease(p.repo)));
  const versions: Record<string, string> = {};
  active.forEach((p, i) => {
    const tag = releases[i]?.tag;
    if (tag) versions[p.repo] = tag;
  });
  return versions;
}

export default async function HistoryPage() {
  const versions = await fetchCommunityVersions();

  return (
    <div className="min-h-screen bg-[var(--bg)] text-fg flex flex-col font-sans selection:bg-primary/30 selection:text-primary pt-[68px]">
      {/* Main Content Area */}
      <main className="flex-1 max-w-6xl mx-auto w-full px-4 sm:px-6 py-10 sm:py-16">
        <ClientHistory />
        <CommunityProjects versions={versions} />
      </main>

      {/* Footer */}
      <Footer />
    </div>
  );
}
