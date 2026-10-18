import type { Metadata } from "next";
import { DocsView } from "../page";

export const metadata: Metadata = {
  title: "Kezdő lépések",
  description:
    "A Pala telepítése Windowsra, macOS-re, Linuxra, Androidra és böngészőbe, az első bejelentkezés és a gyorsbillentyűk.",
  alternates: {
    canonical: "/docs/getting-started",
  },
};

export default function GettingStartedDocsPage() {
  return <DocsView initialPage="installation" />;
}
