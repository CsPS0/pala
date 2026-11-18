import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { ImageResponse } from "next/og";
import sharp from "sharp";

export const dynamic = "force-static";
export const alt = "Pala: a Kréta, átláthatóan. Az Osztályzatok oldal a Pala asztali alkalmazásában.";
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = "image/png";

// Same words as the hero on the front page, so the link preview and the page agree.
const HEADLINE = "A Kréta,";
const HEADLINE_ACCENT = "átláthatóan.";
const TAGLINE = "Jegyek, órarend, hiányzások és üzenetek egy helyen.";
const TRUST = "Ingyenes · reklám nélküli · nyílt forráskódú";
const DOMAIN = "pala-app.hu";
const WORDMARK = "PALA";

// The site's colors (globals.css, dark theme).
const BG = "#0e0e11";
const TEXT = "#f3f3f6";
const MUTED = "#8c8c94";
const BORDER = "#34343b";
const PRIMARY = "#ff8800";

// The app window is drawn larger than the space left for it and runs off the
// right and bottom edges, so the grades stay readable in a small link preview.
const SHOT_WIDTH = 1000;
const SHOT_HEIGHT = 625;
const SHOT_LEFT = 600;
const SHOT_TOP = 92;

async function publicFile(path: string, mime: string): Promise<string> {
  const data = await readFile(join(process.cwd(), "public", path));
  return `data:${mime};base64,${data.toString("base64")}`;
}

/** ImageResponse cannot decode WebP, so the preview is turned into a PNG of the size it is drawn at. */
async function appScreenshot(): Promise<string> {
  const png = await sharp(join(process.cwd(), "public", "previews/desktop-jegyek-dark.webp"))
    .resize(SHOT_WIDTH, SHOT_HEIGHT)
    .png()
    .toBuffer();
  return `data:image/png;base64,${png.toString("base64")}`;
}

/**
 * One weight of Geist (the site's font), cut down to the letters the image
 * uses. ImageResponse ships only the regular weight, and without a real bold
 * the headline looks flat.
 */
async function loadGeist(weight: number, text: string): Promise<ArrayBuffer | null> {
  try {
    const css = await (
      await fetch(`https://fonts.googleapis.com/css2?family=Geist:wght@${weight}&text=${encodeURIComponent(text)}`)
    ).text();
    const url = css.match(/src: url\((.+?)\) format\('(?:opentype|truetype)'\)/)?.[1];
    if (!url) return null;
    const font = await fetch(url);
    return font.ok ? await font.arrayBuffer() : null;
  } catch {
    return null;
  }
}

export default async function Image() {
  const [logo, screenshot, bold, medium] = await Promise.all([
    publicFile("logo.svg", "image/svg+xml"),
    appScreenshot(),
    loadGeist(800, HEADLINE + HEADLINE_ACCENT + DOMAIN + WORDMARK),
    loadGeist(500, TAGLINE + TRUST),
  ]);
  // Custom fonts replace the built-in one, so they are used only when both
  // weights arrived. When Google Fonts cannot be reached, everything is drawn
  // in the built-in regular Geist instead.
  const fonts =
    bold && medium
      ? [
          { name: "Geist", data: medium, weight: 500 as const, style: "normal" as const },
          { name: "Geist Bold", data: bold, weight: 800 as const, style: "normal" as const },
        ]
      : undefined;
  const boldFamily = fonts ? "Geist Bold" : "Geist";

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          position: "relative",
          backgroundColor: BG,
          color: TEXT,
          fontFamily: "Geist",
        }}
      >
        <div
          style={{
            position: "absolute",
            left: SHOT_LEFT,
            top: SHOT_TOP,
            width: SHOT_WIDTH,
            height: SHOT_HEIGHT,
            display: "flex",
            borderRadius: 18,
            border: `1px solid ${BORDER}`,
            overflow: "hidden",
            boxShadow: "0 24px 80px rgba(0, 0, 0, 0.55)",
          }}
        >
          {/* eslint-disable-next-line @next/next/no-img-element, jsx-a11y/alt-text */}
          <img src={screenshot} width={SHOT_WIDTH} height={SHOT_HEIGHT} />
        </div>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: "space-between",
            width: SHOT_LEFT,
            height: "100%",
            padding: "56px 0 56px 64px",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
            {/* eslint-disable-next-line @next/next/no-img-element, jsx-a11y/alt-text */}
            <img src={logo} width={56} height={56} />
            <div style={{ fontFamily: boldFamily, fontSize: 24, letterSpacing: "0.2em" }}>{WORDMARK}</div>
          </div>

          <div style={{ display: "flex", flexDirection: "column" }}>
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                fontFamily: boldFamily,
                fontSize: 74,
                lineHeight: 1.08,
                letterSpacing: "-0.035em",
              }}
            >
              <div>{HEADLINE}</div>
              <div style={{ color: PRIMARY }}>{HEADLINE_ACCENT}</div>
            </div>
            <div style={{ marginTop: 26, maxWidth: 430, fontSize: 27, lineHeight: 1.35, color: MUTED }}>{TAGLINE}</div>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            <div style={{ fontSize: 19, color: MUTED }}>{TRUST}</div>
            <div style={{ fontFamily: boldFamily, fontSize: 26, color: TEXT }}>{DOMAIN}</div>
          </div>
        </div>
      </div>
    ),
    {
      ...size,
      fonts,
    }
  );
}
