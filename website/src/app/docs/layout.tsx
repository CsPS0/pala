import type { Metadata } from "next";

// page.tsx is a client component, so the /docs metadata lives here.
export const metadata: Metadata = {
  // A plain string here would drop the root "%s | Pala" template for the docs subpages.
  title: { default: "Dokumentáció", template: "%s | Pala" },
  description:
    "Telepítés, használat, funkció útmutatók és fejlesztői leírás a Pala Kréta klienshez.",
  alternates: {
    canonical: "/docs",
  },
};

export default function DocsLayout({ children }: { children: React.ReactNode }) {
  return children;
}
