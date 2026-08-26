import { ImageResponse } from "next/og";

export const dynamic = "force-static";
export const alt = "Pala — A Modern, Nyílt Forráskódú Kréta Kliens";
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = "image/png";

export default async function Image() {
  let tag = "v1.2.3";
  try {
    const res = await fetch("https://api.github.com/repos/CsPS0/pala/releases/latest");
    if (res.ok) {
      const data = await res.json();
      if (data.tag_name) tag = data.tag_name;
    }
  } catch (_) {}

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          backgroundColor: "#09090c",
          backgroundImage:
            "radial-gradient(circle at 50% 35%, rgba(255, 136, 0, 0.22) 0%, rgba(9, 9, 12, 1) 75%)",
          color: "#f3f3f6",
          padding: "50px 60px",
          position: "relative",
        }}
      >
        {/* Glow accent pill */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "8px",
            backgroundColor: "rgba(255, 136, 0, 0.12)",
            border: "1px solid rgba(255, 136, 0, 0.35)",
            padding: "8px 22px",
            borderRadius: "9999px",
            color: "#ff8800",
            fontSize: 18,
            fontWeight: 800,
            marginBottom: 20,
            letterSpacing: "0.08em",
          }}
        >
          NYÍLT FORRÁSKÓDÚ KRÉTA KLIENS • REKLÁMMENTES
        </div>

        {/* Title row */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "20px",
            marginBottom: 16,
          }}
        >
          <div
            style={{
              fontSize: 84,
              fontWeight: 900,
              letterSpacing: "-0.04em",
              color: "#f3f3f6",
            }}
          >
            PALA
          </div>
          <div
            style={{
              fontSize: 22,
              fontWeight: 800,
              backgroundColor: "rgba(255, 136, 0, 0.15)",
              color: "#ff8800",
              border: "1px solid rgba(255, 136, 0, 0.4)",
              padding: "4px 14px",
              borderRadius: "10px",
            }}
          >
            {tag}
          </div>
        </div>

        {/* Main Headline */}
        <div
          style={{
            fontSize: 42,
            fontWeight: 900,
            color: "#ffffff",
            marginBottom: 16,
            textAlign: "center",
            letterSpacing: "-0.02em",
          }}
        >
          A te Krétád, a te szabályaid.
        </div>

        {/* Description */}
        <div
          style={{
            fontSize: 22,
            color: "#8c8c94",
            textAlign: "center",
            maxWidth: "880px",
            lineHeight: 1.4,
            marginBottom: 36,
          }}
        >
          Kezeld a jegyeidet, órarendedet és hiányzásaidat asztali gépen, mobilon, böngészőben és terminálban.
        </div>

        {/* Platform tags */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: "10px",
          }}
        >
          {["Windows", "Android", "iOS", "Linux", "macOS", "Böngésző", "Terminál (TUI)"].map((platform) => (
            <div
              key={platform}
              style={{
                backgroundColor: "#151518",
                border: "1px solid #28282d",
                color: "#f3f3f6",
                fontSize: 16,
                fontWeight: 700,
                padding: "8px 18px",
                borderRadius: "14px",
              }}
            >
              {platform}
            </div>
          ))}
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
