import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { ReleaseProvider } from "@/lib/ReleaseContext";
import { ScrollToTop } from "@/components/ScrollToTop";

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
  themeColor: "#ff8800",
};

export const metadata: Metadata = {
  metadataBase: new URL("https://pala-app.hu"),
  title: {
    default: "Pala — A Modern, Nyílt Forráskódú Kréta Kliens",
    template: "%s | Pala",
  },
  description:
    "Kezeld a jegyeidet, órarendedet, mulasztásaidat és dolgozataidat asztali gépen, mobilon, böngészőben és terminálban — 100% ingyenes, reklámmentes és nyílt forráskódú.",
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
  openGraph: {
    title: "Pala — A Modern, Nyílt Forráskódú Kréta Kliens",
    description:
      "Kezeld a jegyeidet, órarendedet, mulasztásaidat és dolgozataidat asztali gépen, mobilon, böngészőben és terminálban — 100% ingyenes, reklámmentes és nyílt forráskódú.",
    url: "https://pala-app.hu",
    siteName: "Pala Kréta Kliens",
    locale: "hu_HU",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Pala — A Modern, Nyílt Forráskódú Kréta Kliens",
    description:
      "Kezeld a jegyeidet, órarendedet, mulasztásaidat és dolgozataidat asztali gépen, mobilon, böngészőben és terminálban — 100% ingyenes, reklámmentes és nyílt forráskódú.",
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
    <html lang="hu" className={`${geistSans.variable} ${geistMono.variable} dark scroll-smooth overflow-x-hidden max-w-full`}>
      <body className="bg-[var(--bg)] text-[#f0f0f5] min-h-screen flex flex-col font-sans antialiased selection:bg-[#ff8800] selection:text-black overflow-x-hidden max-w-full w-full">
        <ReleaseProvider>
          {children}
          <ScrollToTop />
        </ReleaseProvider>
      </body>
    </html>
  );
}

