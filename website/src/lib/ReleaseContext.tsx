"use client";

import React, { createContext, useContext, useCallback, useMemo } from "react";
import type { DetectedPlatform } from "./detectOS";
import type { LatestRelease } from "./githubReleases";

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
  extensionZip: string;
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
export const DEFAULT_FALLBACK_VERSION = "v2.0.0";

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
  extensionZip: `https://github.com/${GITHUB_REPO}/releases/latest/download/pala-extension.zip`,
};

function parseAssetUrls(assets: GitHubAsset[]): ReleaseAssetMap {
  const map: ReleaseAssetMap = { ...DEFAULT_ASSETS };
  if (!assets || !Array.isArray(assets) || assets.length === 0) return map;

  // Match the exact release file names: a release holds two .exe files (the
  // installer and the TUI) and can hold two .deb files, so matching by
  // extension picked whichever came last.
  for (const key of Object.keys(DEFAULT_ASSETS) as (keyof ReleaseAssetMap)[]) {
    const fileName = DEFAULT_ASSETS[key].split("/").pop();
    const asset = assets.find(a => a.name === fileName);
    if (asset) map[key] = asset.browser_download_url;
  }
  return map;
}

const ReleaseContext = createContext<ReleaseInfo | null>(null);

/**
 * Release data comes from the build (see githubReleases.ts), passed in by the
 * root layout. Nothing is fetched in the browser.
 */
export function ReleaseProvider({ children, release }: { children: React.ReactNode; release: LatestRelease | null }) {
  const version = release?.tag || DEFAULT_FALLBACK_VERSION;
  const publishedAt = release?.publishedAt || "";
  const formattedDate = release?.formattedDate || "";
  const releaseUrl = release?.htmlUrl || `https://github.com/${GITHUB_REPO}/releases/latest`;
  const rawAssets = useMemo(() => release?.assets || [], [release]);
  const assets = useMemo(() => parseAssetUrls(rawAssets), [rawAssets]);
  const isLoading = false;

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
          return { url: "/docs#inst-ios", label: `iOS: Jelenleg nem elérhető (Részletek)`, isDirect: false };
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
