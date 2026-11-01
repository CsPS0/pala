// Public address of the website. NEXT_PUBLIC_SITE_URL overrides it (e.g. for previews). A
// forgotten variable must not move canonical URLs and the sitemap to a *.vercel.app address,
// so production falls back to the real domain and local development to localhost.
export const SITE_URL = (
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.NODE_ENV === "production" ? "https://pala-app.hu" : "http://localhost:3000")
).replace(/\/$/, "");
