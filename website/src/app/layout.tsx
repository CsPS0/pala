import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Pala — A Modern, Nyílt Forráskódú Kréta Kliens",
  description: "Kezeld a jegyeidet, órarendedet, hiányzásaidat és dolgozataidat asztali gépen, mobilon, böngészőben vagy terminálban — reklámok és lassulások nélkül.",
  keywords: ["Kréta", "Pala", "e-Kréta", "TUI", "Desktop", "Mobile", "Nyílt forráskódú", "Kliens"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="hu" className={`${geistSans.variable} ${geistMono.variable} dark scroll-smooth`}>
      <body className="bg-[#09090c] text-[#f0f0f5] min-h-screen flex flex-col font-sans antialiased selection:bg-[#ff8800] selection:text-black">
        {children}
      </body>
    </html>
  );
}
