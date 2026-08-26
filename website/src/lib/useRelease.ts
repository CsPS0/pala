// Re-export everything from the central ReleaseContext.
// All components use useRelease() - the provider is mounted in layout.tsx.
export {
  useRelease,
  ReleaseProvider,
  DEFAULT_ASSETS,
  DEFAULT_FALLBACK_VERSION,
} from "./ReleaseContext";

export type { ReleaseInfo, ReleaseAssetMap, GitHubAsset } from "./ReleaseContext";
