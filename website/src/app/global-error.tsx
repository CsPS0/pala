"use client";

import React, { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error("Pala Global Root Error:", error);
  }, [error]);

  return (
    <html lang="hu">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Hiba lépett fel | Pala</title>
      </head>
      <body className="bg-[#09090c] text-[#f3f3f6] min-h-screen flex flex-col items-center justify-center font-sans p-6 text-center">
        <div className="max-w-md w-full p-8 rounded-3xl bg-[#151518] border border-[#28282d] space-y-6 shadow-2xl">
          <div className="w-14 h-14 rounded-2xl bg-[#ff453a]/10 border border-[#ff453a]/30 flex items-center justify-center text-[#ff453a] mx-auto text-2xl font-bold">
            !
          </div>

          <div className="space-y-2">
            <h1 className="text-xl font-bold text-[#f3f3f6]">Kritikus hiba lépett fel</h1>
            <p className="text-xs text-[#8c8c94] leading-relaxed">
              Az alkalmazás gyökér szintű hibába ütközött. Kattints az alábbi gombra az oldal újratöltéséhez.
            </p>
          </div>

          <button
            onClick={() => {
              if (typeof window !== "undefined") {
                window.location.reload();
              } else {
                reset();
              }
            }}
            className="w-full bg-[#ff8800] hover:bg-[#ffa033] text-black font-extrabold text-xs py-3 px-4 rounded-xl transition-all shadow-[0_0_20px_rgba(255,136,0,0.25)] cursor-pointer"
          >
            Alkalmazás Újraindítása
          </button>
        </div>
      </body>
    </html>
  );
}
