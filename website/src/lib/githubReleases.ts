// Build-time GitHub release lookups. The site is a static export, so these run
// during `next build`, never in the visitor's browser: no third-party request
// per visit, and no API rate limit for a classroom behind one IP address.
// The data is as fresh as the last deploy; download links use
// releases/latest/download/, so they keep working in between.
import type { GitHubAsset } from "./ReleaseContext";

export interface LatestRelease {
  tag: string;
  htmlUrl: string;
  publishedAt: string;
  formattedDate: string;
  assets: GitHubAsset[];
}

export async function fetchLatestRelease(repo: string): Promise<LatestRelease | null> {
  const headers: Record<string, string> = { Accept: "application/vnd.github+json" };
  // Optional: a token raises the build-time rate limit (the variable is never sent to the browser).
  if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, { headers });
    if (!res.ok) return null;
    const data = await res.json();
    if (!data?.tag_name) return null;
    return {
      tag: data.tag_name,
      htmlUrl: data.html_url || `https://github.com/${repo}/releases/latest`,
      publishedAt: data.published_at || "",
      formattedDate: data.published_at ? new Date(data.published_at).toLocaleDateString("hu-HU") : "",
      assets: Array.isArray(data.assets)
        ? data.assets.map((a: GitHubAsset) => ({ name: a.name, browser_download_url: a.browser_download_url, size: a.size }))
        : [],
    };
  } catch {
    return null;
  }
}
