# Pala weboldal

A [pala-app.hu](https://pala-app.hu) forrása: Next.js (App Router), Tailwind CSS v4, statikus exporttal (`output: "export"`), Vercelen.

## Futtatás

```bash
bun install
bun run dev        # http://localhost:3000
```

npm-mel is működik (`npm install`, `npm run dev`). Ha a fejlesztői szerver Node.js-ből előzetes (alpha) verzióval indul el, és `rawHeaders.hasOwnProperty` hibával leáll, telepíts Node LTS-t, vagy indítsd Bun futtatókörnyezettel: `bun --bun run dev`.

## Ellenőrzés

A CI ugyanezeket futtatja:

```bash
bun run lint
bun run build
node scripts/check-contrast.mjs    # a színpárok WCAG-kontrasztja világos és sötét témában
```

## Tudnivalók

- **Kiadási adatok:** a legfrissebb GitHub-kiadást (verzió, letöltési linkek) a build kéri le (`src/lib/githubReleases.ts`), a böngésző nem fordul a GitHubhoz. A `GITHUB_TOKEN` környezeti változó megadása nem kötelező, csak a GitHub API korlátja miatt hasznos. Ha a lekérés nem sikerül, a linkek a `releases/latest/download/...` címekre mutatnak, és az oldal nem ír ki verziószámot.
- **Webcím:** a `NEXT_PUBLIC_SITE_URL` felülírja az oldal címét (például előnézethez); élesben alapértelmezés szerint `https://pala-app.hu`.
- **Szövegek:** minden felhasználói szöveg magyar. A dokumentáció oldal a `src/app/docs/page.tsx` fájlban van, a keresője a `src/content/docs/searchIndex.ts` alapján dolgozik; új oldalnál mindkettőt frissíteni kell.
- **Színek:** a színeket a `src/app/globals.css` tokenjei adják (`text-primary`, `bg-card`, `text-muted` stb.), nem nyers hex értékek. Új színpárnál a `scripts/check-contrast.mjs` listáját is bővíteni kell.
- **Előnézeti képek:** a nyitóoldal képei (`public/previews/`) a valódi alkalmazásokról készülnek, a menetük a [fejlesztői dokumentációban](../docs/DEV.md#weboldal-előnézeti-képek) van.
