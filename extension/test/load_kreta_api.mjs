// Loads extension/shared/kreta_api.js (a plain browser script, no modules)
// into a Node vm context, so its functions can be tested without a build step
// or any npm dependency. Run: node --test extension/test/
import { readFileSync } from "node:fs";
import vm from "node:vm";

export function loadKretaApi() {
  const context = vm.createContext({ console, URL, URLSearchParams, TextEncoder, TextDecoder });
  const source = readFileSync(new URL("../shared/kreta_api.js", import.meta.url), "utf8");
  vm.runInContext(source, context, { filename: "kreta_api.js" });
  // Top-level classes live in the script scope, not on the global object.
  return vm.runInContext("({ KretaApi, offlineReasonOf, offlineLabel, offlineNotice, DEMO_GRADES })", context);
}

export function loadFixture(name) {
  return JSON.parse(readFileSync(new URL(`../../fixtures/rules/${name}`, import.meta.url), "utf8"));
}
