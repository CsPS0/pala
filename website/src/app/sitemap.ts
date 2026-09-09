import type { MetadataRoute } from "next";

export const dynamic = "force-static";

export default function sitemap(): MetadataRoute.Sitemap {
  const routes = ["", "/docs", "/adatvedelem"];

  return routes.map((path) => ({
    url: `https://pala-app.hu${path}`,
    lastModified: new Date(),
  }));
}
