// Public address of the website. Set NEXT_PUBLIC_SITE_URL once the own domain is live; until then
// Vercel builds fall back to the project's production address (VERCEL_PROJECT_PRODUCTION_URL).
export const SITE_URL = (
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : "http://localhost:3000")
).replace(/\/$/, "");
