import type { Metadata, Viewport } from "next";
import { SITE_URL } from "@/lib/site";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ReleaseProvider } from "@/lib/ReleaseContext";
import { ScrollToTop } from "@/components/ScrollToTop";
import { Navbar } from "@/components/Navbar";
import { DocsUIProvider } from "@/lib/DocsUIContext";
import { SearchModal } from "@/components/search/SearchModal";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: [
    { media: "(prefers-color-scheme: dark)", color: "#0e0e11" },
    { media: "(prefers-color-scheme: light)", color: "#f4f4f7" },
  ],
};

// Runs before first paint so the page never flashes the wrong theme.
const THEME_SCRIPT = `try{var t=localStorage.getItem("pala-theme");if(t!=="light"&&t!=="dark")t=matchMedia("(prefers-color-scheme: light)").matches?"light":"dark";document.documentElement.dataset.theme=t}catch(e){document.documentElement.dataset.theme=matchMedia("(prefers-color-scheme: light)").matches?"light":"dark"}`;

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Pala — Nyílt forráskódú Kréta kliens",
    template: "%s | Pala",
  },
  description:
    "Kezeld a jegyeidet, órarendedet, mulasztásaidat és dolgozataidat asztali gépen, mobilon, böngészőben és terminálban — ingyenes, reklámmentes és nyílt forráskódú.",
  keywords: [
    "Kréta",
    "Pala",
    "e-Kréta",
    "eKréta",
    "TUI",
    "Desktop",
    "Mobile",
    "Android",
    "iOS",
    "Windows",
    "Linux",
    "macOS",
    "Nyílt forráskódú",
    "Kliens",
    "Diák",
  ],
  authors: [{ name: "Pala Csapat", url: "https://github.com/CsPS0/pala" }],
  creator: "Pala Team",
  publisher: "Pala",
  alternates: {
    canonical: "/",
  },
  // og/twitter title and description are filled per page from title/description.
  openGraph: {
    siteName: "Pala Kréta Kliens",
    locale: "hu_HU",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
  },
  icons: {
    icon: "/logo.svg",
    apple: "/logo.png",
  },
  other: {
    "msapplication-TileColor": "#ff8800",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="hu" className={`${geistSans.variable} ${geistMono.variable} scroll-smooth overflow-x-hidden max-w-full`} suppressHydrationWarning>
      <head>
        {/* Inline on purpose: next/script beforeInteractive only queues it for the runtime, after first paint. */}
        <script dangerouslySetInnerHTML={{ __html: THEME_SCRIPT }} />
      </head>
      <body className="bg-[var(--bg)] text-fg min-h-screen flex flex-col font-sans antialiased selection:bg-primary-fill selection:text-on-primary overflow-x-hidden max-w-full w-full">
        <ReleaseProvider>
          <DocsUIProvider>
            <Navbar />
            {children}
            <SearchModal />
          </DocsUIProvider>
          <ScrollToTop />
        </ReleaseProvider>
      </body>
    </html>
  );
}

