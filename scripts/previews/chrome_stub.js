// Minimal chrome.* stand-in so extension/popup/popup.html runs as a plain page in demo mode,
// for capturing website preview screenshots only (never shipped with the extension).
// URL hash options: #theme=light|dark&tab=<data-tab id>&now=<local ISO time>,
// e.g. #theme=light&tab=tab-today&now=2026-11-09T09:10:00
(() => {
  const opts = Object.fromEntries(new URLSearchParams(location.hash.slice(1)));

  // now=: the page sees that moment as the current time (still ticking), so the
  // demo shows a school morning whenever the screenshot is taken.
  if (opts.now) {
    const RealDate = Date;
    const offset = new RealDate(opts.now).getTime() - RealDate.now();
    class FakeDate extends RealDate {
      constructor(...args) {
        super(...(args.length ? args : [RealDate.now() + offset]));
      }
      static now() {
        return RealDate.now() + offset;
      }
    }
    window.Date = FakeDate;
  }
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
