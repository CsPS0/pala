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
      <body className="bg-bg text-fg min-h-screen flex flex-col items-center justify-center font-sans p-6 text-center">
        <div className="max-w-md w-full p-8 rounded-3xl bg-sidebar border border-border space-y-6">
          <div className="w-14 h-14 rounded-2xl bg-danger/10 border border-danger/30 flex items-center justify-center text-danger mx-auto text-2xl font-bold">
            !
          </div>

          <div className="space-y-2">
            <h1 className="text-xl font-bold text-fg">Kritikus hiba lépett fel</h1>
            <p className="text-xs text-muted leading-relaxed">
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
            className="w-full bg-primary-fill hover:bg-primary-fill-hover text-on-primary font-extrabold text-xs py-3 px-4 rounded-xl transition-all cursor-pointer"
          >
            Alkalmazás Újraindítása
          </button>
        </div>
      </body>
    </html>
  );
}
