import type { Metadata } from "next";
import { DocsView } from "../page";

export const metadata: Metadata = {
  title: "Fejlesztőknek",
  description:
    "A Pala architektúrája, a Kréta API és a titkosítás, a böngészőbővítmény és a TUI, valamint a közreműködés menete.",
  alternates: {
    canonical: "/docs/developers",
  },
};

export default function DevelopersDocsPage() {
  return <DocsView initialPage="dev-architecture" />;
}
