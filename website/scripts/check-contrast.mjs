// Checks WCAG contrast of the theme tokens in src/app/globals.css, for the dark (:root) and light themes.
// Run: node scripts/check-contrast.mjs  (exit 1 on any failing pair)
import { readFileSync } from "node:fs";

const css = readFileSync(new URL("../src/app/globals.css", import.meta.url), "utf8");

function block(selector) {
  const start = css.indexOf(`${selector} {`);
  if (start === -1) return null;
  const body = css.slice(start, css.indexOf("}", start));
  return Object.fromEntries([...body.matchAll(/(--[\w-]+):\s*(#[0-9a-fA-F]{6})\s*;/g)].map((m) => [m[1], m[2]]));
}

const dark = block(":root");
const lightOverrides = block('[data-theme="light"]');
const themes = { dark, light: lightOverrides && { ...dark, ...lightOverrides } };

const PAIRS = [
  ["--text", "--bg", 4.5], ["--text", "--card", 4.5], ["--text-muted", "--bg", 4.5],
  ["--text-muted", "--card", 4.5], ["--text-subtle", "--card", 4.5], ["--primary", "--bg", 4.5],
  ["--primary", "--card", 4.5], ["--success", "--card", 4.5], ["--grade-good", "--card", 4.5],
  ["--warning", "--card", 4.5], ["--danger", "--card", 4.5], ["--info", "--card", 4.5],
  ["--ghost", "--card", 4.5], ["--purple", "--card", 4.5], ["--on-primary", "--primary-fill", 4.5],
];

const lum = (hex) => {
  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((v) => (v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const ratio = (a, b) => {
  const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
};

let failed = 0;
for (const [name, tokens] of Object.entries(themes)) {
  if (!tokens) {
    console.log(`${name}: theme block missing`);
    failed++;
    continue;
  }
  for (const [fg, bg, min] of PAIRS) {
    if (!tokens[fg] || !tokens[bg]) {
      console.log(`FAIL ${name} ${fg} on ${bg}: token missing`);
      failed++;
      continue;
    }
    const r = ratio(tokens[fg], tokens[bg]);
    const ok = r >= min;
    if (!ok) failed++;
    console.log(`${ok ? "ok  " : "FAIL"} ${name} ${fg} on ${bg}: ${r.toFixed(2)}`);
  }
}
process.exit(failed ? 1 : 0);
