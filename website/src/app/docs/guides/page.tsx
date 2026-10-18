import type { Metadata } from "next";
import { DocsView } from "../page";

export const metadata: Metadata = {
  title: "Útmutatók",
  description:
    "Vezérlőpult és órarend, jegyek és Szellem Jegy kalkulátor, mulasztások és a 250 órás határ a Palában.",
  alternates: {
    canonical: "/docs/guides",
  },
};

export default function GuidesDocsPage() {
  return <DocsView initialPage="guide-dashboard" />;
}
