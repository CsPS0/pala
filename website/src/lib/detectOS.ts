export type DetectedPlatform = "windows" | "android" | "ios" | "linux" | "macos";

// Returns "unknown" server-side or when no platform is detected.
// Components should render a neutral "choose your platform" state until
// the client has finished detection.
export function detectClientOS(): DetectedPlatform | "unknown" {
  if (typeof window === "undefined" || typeof navigator === "undefined") {
    return "unknown";
  }

  const ua = (navigator.userAgent || navigator.vendor || "").toLowerCase();
  const uadPlatform = (
    (navigator as Navigator & { userAgentData?: { platform?: string } })
      .userAgentData?.platform ?? ""
  ).toLowerCase();
  const navPlatform = (navigator.platform || "").toLowerCase();
  const maxTouch = navigator.maxTouchPoints || 0;

  // 1. Android (highest priority on mobile)
  if (
    uadPlatform.includes("android") ||
    ua.includes("android") ||
    ua.includes("adr ") ||
    ua.includes("samsung") ||
    ua.includes("xiaomi") ||
    ua.includes("pixel") ||
    ua.includes("redmi") ||
    ua.includes("huawei") ||
    (navPlatform.includes("linux") && (maxTouch > 0 || /mobi|tablet/i.test(ua))) ||
    (ua.includes("linux") && ua.includes("mobile"))
  ) {
    return "android";
  }

  // 2. iOS
  if (
    uadPlatform.includes("ios") ||
    /ipad|iphone|ipod/.test(ua) ||
    (navPlatform === "macintel" && maxTouch > 1) ||
    (ua.includes("macintosh") && maxTouch > 1)
  ) {
    return "ios";
  }

  // 3. Windows
  if (
    uadPlatform.includes("win") ||
    navPlatform.includes("win") ||
    ua.includes("windows") ||
    ua.includes("win32") ||
    ua.includes("win64")
  ) {
    return "windows";
  }

  // 4. macOS (desktop)
  if (
    uadPlatform.includes("mac") ||
    navPlatform.includes("mac") ||
    ua.includes("macintosh") ||
    ua.includes("mac os x")
  ) {
    return "macos";
  }

  // 5. Linux (desktop)
  if (
    uadPlatform.includes("linux") ||
    navPlatform.includes("linux") ||
    ua.includes("linux") ||
    ua.includes("x11")
  ) {
    return "linux";
  }

  return "unknown";
}
