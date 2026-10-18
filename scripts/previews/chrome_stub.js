// Minimal chrome.* stand-in so extension/popup/popup.html runs as a plain page in demo mode,
// for capturing website preview screenshots only (never shipped with the extension).
// URL hash options: #theme=light|dark&tab=<data-tab id>, e.g. #theme=light&tab=tab-today
(() => {
  const opts = Object.fromEntries(new URLSearchParams(location.hash.slice(1)));
  const store = { pala_use_demo: true, pala_dark_mode: opts.theme !== "light" };
  const noop = () => {};
  const asyncNoop = async () => undefined;
  const listener = { addListener: noop, removeListener: noop };

  const pick = (keys) => {
    if (keys == null) return { ...store };
    if (typeof keys === "string") keys = [keys];
    if (Array.isArray(keys)) return Object.fromEntries(keys.filter((k) => k in store).map((k) => [k, store[k]]));
    return Object.fromEntries(Object.entries(keys).map(([k, d]) => [k, k in store ? store[k] : d]));
  };
  // Supports both the promise and the callback form of chrome.storage.
  const wrap = (fn) => (arg, cb) => {
    const result = fn(arg);
    if (typeof cb === "function") cb(result);
    return Promise.resolve(result);
  };
  const local = {
    get: wrap(pick),
    set: wrap((items) => { Object.assign(store, items); }),
    remove: wrap((keys) => { [].concat(keys).forEach((k) => delete store[k]); }),
    clear: wrap(() => { Object.keys(store).forEach((k) => delete store[k]); }),
  };

  window.chrome = {
    storage: { local, session: local, sync: local, onChanged: listener },
    runtime: { id: "preview-stub", lastError: undefined, getURL: (p) => p, sendMessage: asyncNoop, onMessage: listener, getManifest: () => ({ version: "0.0.0" }) },
    tabs: { query: async () => [], create: asyncNoop, update: asyncNoop },
    windows: { getCurrent: async () => ({ id: 1 }) },
    sidePanel: { open: asyncNoop, setOptions: asyncNoop },
    scripting: { executeScript: async () => [] },
    alarms: { create: noop, get: asyncNoop, onAlarm: listener },
    action: { setBadgeText: noop, setBadgeBackgroundColor: noop },
  };

  if (opts.tab) {
    window.addEventListener("load", () => {
      setTimeout(() => document.querySelector(`[data-tab="${opts.tab}"]`)?.click(), 300);
    });
  }
})();
