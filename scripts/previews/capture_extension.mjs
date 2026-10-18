// Captures the extension popup in demo mode for the website's hero preview.
// Copies extension/ to a temp folder, loads chrome_stub.js before the popup's scripts, opens
// popup.html in a headless Chromium browser over the DevTools protocol and saves 380x580 CSS px at 2x.
// Output: <repo>/build/previews/popup-<screen>-<theme>.png. Needs Node 22+ (built-in WebSocket).
//   node scripts/previews/capture_extension.mjs
import { spawn } from "node:child_process";
import { cpSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "..", "..");
const outDir = join(repo, "build", "previews");
const SHOTS = { jegyek: "tab-grades", feladatok: "tab-tasks" };
const BROWSERS = [
  "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
  "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
  `${process.env.LOCALAPPDATA}\\Google\\Chrome\\Application\\chrome.exe`,
  "C:\\Program Files\\BraveSoftware\\Brave-Browser\\Application\\brave.exe",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/usr/bin/google-chrome",
  "/usr/bin/chromium",
];
const PORT = 9334;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const browserPath = BROWSERS.find((p) => existsSync(p));
if (!browserPath) throw new Error("No Chromium-based browser found; add its path to BROWSERS.");

const tmp = mkdtempSync(join(tmpdir(), "pala-preview-"));
const ext = join(tmp, "extension");
cpSync(join(repo, "extension"), ext, { recursive: true });
copyFileSync(join(here, "chrome_stub.js"), join(ext, "chrome_stub.js"));
const popupPath = join(ext, "popup", "popup.html");
const tag = '<script src="../shared/kreta_api.js"></script>';
const html = readFileSync(popupPath, "utf8");
if (!html.includes(tag)) throw new Error("popup.html changed: kreta_api.js script tag not found");
writeFileSync(popupPath, html.replace(tag, `<script src="../chrome_stub.js"></script>\n  ${tag}`));

const browser = spawn(browserPath, [
  "--headless=new", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
  `--remote-debugging-port=${PORT}`, `--user-data-dir=${join(tmp, "profile")}`, "about:blank",
], { stdio: "ignore" });

try {
  let target;
  for (let i = 0; i < 50 && !target; i++) {
    await sleep(200);
    target = await fetch(`http://127.0.0.1:${PORT}/json/list`).then((r) => r.json()).then((l) => l.find((t) => t.type === "page")).catch(() => undefined);
  }
  if (!target) throw new Error("Browser did not expose a DevTools page target");

  const ws = new WebSocket(target.webSocketDebuggerUrl);
  await new Promise((resolve, reject) => { ws.onopen = resolve; ws.onerror = reject; });
  let nextId = 0;
  const pending = new Map();
  ws.onmessage = (e) => {
    const msg = JSON.parse(e.data);
    if (msg.id && pending.has(msg.id)) {
      pending.get(msg.id)(msg);
      pending.delete(msg.id);
    }
  };
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = ++nextId;
    pending.set(id, (msg) => (msg.error ? reject(new Error(`${method}: ${msg.error.message}`)) : resolve(msg.result)));
    ws.send(JSON.stringify({ id, method, params }));
  });

  await send("Emulation.setDeviceMetricsOverride", { width: 380, height: 580, deviceScaleFactor: 2, mobile: false });
  mkdirSync(outDir, { recursive: true });
  for (const theme of ["dark", "light"]) {
    for (const [name, tab] of Object.entries(SHOTS)) {
      // about:blank first so the hash-only change still reloads the page and the stub re-reads it.
      await send("Page.navigate", { url: "about:blank" });
      await send("Page.navigate", { url: `${pathToFileURL(popupPath).href}#theme=${theme}&tab=${tab}` });
      await sleep(2500);
      const { data } = await send("Page.captureScreenshot", { format: "png" });
      const out = join(outDir, `popup-${name}-${theme}.png`);
      writeFileSync(out, Buffer.from(data, "base64"));
      console.log(out);
    }
  }
  ws.close();
} finally {
  browser.kill();
  await sleep(500);
  rmSync(tmp, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
