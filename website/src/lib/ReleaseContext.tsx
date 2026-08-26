"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import type { DetectedPlatform } from "./detectOS";

export interface GitHubAsset {
  name: string;
  browser_download_url: string;
  size: number;
}

export interface ReleaseAssetMap {
  windowsExe: string;
  windowsZip: string;
  androidUniversal: string;
  androidArm64: string;
  androidArmv7: string;
  androidX86: string;
  linuxTar: string;
  linuxDeb: string;
  linuxAppImage: string;
  macDmg: string;
  macZip: string;
}

export interface ReleaseInfo {
  version: string;
  versionClean: string;
  publishedAt: string;
  formattedDate: string;
  releaseUrl: string;
  assets: ReleaseAssetMap;
  rawAssets: GitHubAsset[];
  isLoading: boolean;
  getDownloadForOS: (os: DetectedPlatform | "unknown") => {
    url: string;
    label: string;
    isDirect: boolean;
  };
}

const GITHUB_REPO = "CsPS0/pala";
export const DEFAULT_FALLBACK_VERSION = "v1.2.3";

export const DEFAULT_ASSETS: ReleaseAssetMap = {
  windowsExe: `https://github.com/${GITHUB_REPO}/releases/latest/download/Pala-Setup.exe`,
  windowsZip: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-windows-x64.zip`,
  androidUniversal: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-universal.apk`,
  androidArm64: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-arm64-v8a.apk`,
  androidArmv7: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-armeabi-v7a.apk`,
  androidX86: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-x86_64.apk`,
  linuxTar: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-linux-x64.tar.gz`,
  linuxDeb: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala_amd64.deb`,
  linuxAppImage: `https://github.com/${GITHUB_REPO}/releases/latest/download/Pala-x86_64.AppImage`,
  macDmg: `https://github.com/${GITHUB_REPO}/releases/latest/download/Pala-macOS.dmg`,
  macZip: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-macos.zip`,
};

function parseAssetUrls(assets: GitHubAsset[]): ReleaseAssetMap {
  const map: ReleaseAssetMap = { ...DEFAULT_ASSETS };
  if (!assets || !Array.isArray(assets) || assets.length === 0) return map;

  for (const a of assets) {
    const name = a.name.toLowerCase();
    const url = a.browser_download_url;
    if (name.endsWith(".exe")) map.windowsExe = url;
    else if (name.includes("win") && name.endsWith(".zip")) map.windowsZip = url;
    else if (name.endsWith(".apk")) {
      if (name.includes("arm64") || name.includes("v8a")) map.androidArm64 = url;
      else if (name.includes("armv7") || name.includes("v7a") || name.includes("32")) map.androidArmv7 = url;
      else if (name.includes("x86_64") || name.includes("x64")) map.androidX86 = url;
      else map.androidUniversal = url;
    } else if (name.endsWith(".deb")) map.linuxDeb = url;
    else if (name.endsWith(".appimage")) map.linuxAppImage = url;
    else if (name.endsWith(".tar.gz")) map.linuxTar = url;
    else if (name.endsWith(".dmg")) map.macDmg = url;
    else if ((name.includes("mac") || name.includes("darwin")) && name.endsWith(".zip")) map.macZip = url;
  }
  return map;
}

const ReleaseContext = createContext<ReleaseInfo | null>(null);

export function ReleaseProvider({ children }: { children: React.ReactNode }) {
  const [version, setVersion] = useState<string>(DEFAULT_FALLBACK_VERSION);
  const [publishedAt, setPublishedAt] = useState<string>("");
  const [formattedDate, setFormattedDate] = useState<string>("");
  const [releaseUrl, setReleaseUrl] = useState<string>(
    `https://github.com/${GITHUB_REPO}/releases/latest`
  );
  const [assets, setAssets] = useState<ReleaseAssetMap>(DEFAULT_ASSETS);
  const [rawAssets, setRawAssets] = useState<GitHubAsset[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    let isMounted = true;

    async function fetchRelease() {
      try {
        const res = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/releases/latest`);
        if (!res.ok) {
          if (isMounted) setIsLoading(false);
          return;
        }
        const data = await res.json();
        if (!isMounted) return;

        const tag: string = data.tag_name || DEFAULT_FALLBACK_VERSION;
        setVersion(tag);
        if (data.html_url) setReleaseUrl(data.html_url);
        if (data.published_at) {
          setPublishedAt(data.published_at);
          setFormattedDate(new Date(data.published_at).toLocaleDateString("hu-HU"));
        }
        if (data.assets && Array.isArray(data.assets)) {
          setRawAssets(data.assets);
          setAssets(parseAssetUrls(data.assets));
        }
      } catch (err) {
        console.warn("Could not load GitHub release info:", err);
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }

    fetchRelease();
    return () => { isMounted = false; };
  }, []);

  const versionClean = version.replace(/^v/, "");

  const getDownloadForOS = useCallback(
    (os: DetectedPlatform | "unknown") => {
      switch (os) {
        case "windows":
          return { url: assets.windowsExe, label: `Letöltés Windowsra (${version})`, isDirect: true };
        case "android":
          return { url: assets.androidUniversal, label: `Letöltés Androidra (${version})`, isDirect: true };
        case "macos":
          return {
            url: assets.macDmg || "/docs",
            label: `Letöltés macOS-re (${version})`,
            isDirect: Boolean(assets.macDmg),
          };
        case "linux":
          return { url: "/docs", label: `Telepítés Linuxra`, isDirect: false };
        case "ios":
          return { url: "/docs", label: `iOS Telepítési Útmutató`, isDirect: false };
        default:
          return { url: "/docs", label: `Telepítés & Dokumentáció`, isDirect: false };
      }
    },
    [assets, version]
  );

  return (
    <ReleaseContext.Provider
      value={{ version, versionClean, publishedAt, formattedDate, releaseUrl, assets, rawAssets, isLoading, getDownloadForOS }}
    >
      {children}
    </ReleaseContext.Provider>
  );
}

export function useRelease(): ReleaseInfo {
  const ctx = useContext(ReleaseContext);
  if (!ctx) {
    throw new Error("useRelease must be used inside <ReleaseProvider>. Wrap your app in <ReleaseProvider>.");
  }
  return ctx;
}
