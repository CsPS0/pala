// Pala Extension - Kréta API Client & Demo Engine

/**
 * Escapes text pulled from the Kréta API (or typed by the user) before it is
 * interpolated into an innerHTML template string. Kréta content — teacher
 * comments, message bodies, attachment names — is not fully trusted: a
 * compromised teacher account or a crafted attachment name could otherwise
 * inject markup/script into the dashboard page, which holds the (encrypted
 * at rest, but decrypted in memory) session token.
 */
function escapeHtml(value) {
  if (value === null || value === undefined) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

const KRETA_HTML_ALLOWED = new Set(["P", "BR", "B", "STRONG", "I", "EM", "U", "S", "UL", "OL", "LI", "DIV", "SPAN", "BLOCKQUOTE", "A"]);
const KRETA_HTML_DROPPED = new Set(["SCRIPT", "STYLE", "TEMPLATE", "NOSCRIPT", "IFRAME", "OBJECT", "EMBED", "SVG", "MATH", "TITLE"]);

/**
 * Turns Kréta message/notice HTML into a DocumentFragment that keeps only
 * basic formatting. The markup is parsed in an inert DOMParser document (no
 * scripts run, nothing loads); only allowlisted tags are recreated, with no
 * attributes except an http(s) href on links. Everything else is unwrapped
 * to its text, or dropped entirely for script-like elements.
 */
function sanitizeKretaHtml(html) {
  const frag = document.createDocumentFragment();
  const copy = (from, to) => {
    for (const node of from.childNodes) {
      if (node.nodeType === Node.TEXT_NODE) {
        to.append(node.data);
        continue;
      }
      if (node.nodeType !== Node.ELEMENT_NODE) continue;
      const tag = node.tagName.toUpperCase();
      if (KRETA_HTML_DROPPED.has(tag)) continue;
      if (!KRETA_HTML_ALLOWED.has(tag)) {
        copy(node, to);
        continue;
      }
      const el = document.createElement(tag.toLowerCase());
      const href = tag === "A" ? (node.getAttribute("href") || "").trim() : "";
      if (/^https?:\/\//i.test(href)) {
        el.href = href;
        el.target = "_blank";
        el.rel = "noopener noreferrer";
      }
      copy(node, el);
      to.append(el);
    }
  };
  copy(new DOMParser().parseFromString(String(html ?? ""), "text/html").body, frag);
  return frag;
}

function looksLikeHtml(value) {
  return /<[a-z!/][^>]*>/i.test(String(value ?? ""));
}

/** Plain-text version of Kréta message HTML for previews and search. */
function kretaHtmlToText(html) {
  const s = String(html ?? "");
  if (!looksLikeHtml(s)) return s;
  return sanitizeKretaHtml(s.replace(/<br\s*\/?>|<\/(p|div|li)>/gi, "$&\n")).textContent.trim();
}

/** Renders message content into `el`: plain text as text, HTML through the allowlist sanitizer. */
function renderKretaContent(el, content) {
  if (looksLikeHtml(content)) {
    el.replaceChildren(sanitizeKretaHtml(content));
  } else {
    el.innerText = String(content ?? "");
  }
}

/**
 * Why live data could not be loaded, shared by the popup, side panel and
 * dashboard: "expired" (Kréta rejected the login), "network" (no internet),
 * "maintenance" (simulated) or "server" (Kréta itself is down).
 */
function offlineReasonOf(err) {
  if (err?.sessionExpired || err?.status === 401) return "expired";
  if ((typeof navigator !== "undefined" && navigator.onLine === false) || err?.isNetwork) return "network";
  return "server";
}

const OFFLINE_LABELS = {
  login: "Nincs belépve",
  expired: "Lejárt a belépés",
  network: "Nincs internet",
  maintenance: "Karbantartás",
  server: "A Kréta nem elérhető"
};

/** Short status label for the reason in data.offlineReason (or a reason string). */
function offlineLabel(dataOrReason) {
  const reason = typeof dataOrReason === "string" ? dataOrReason : dataOrReason?.offlineReason;
  return OFFLINE_LABELS[reason] || OFFLINE_LABELS.server;
}

/**
 * Makes a search input and its result list usable from the keyboard and by
 * screen readers (combobox pattern): ArrowDown/ArrowUp move through the
 * options, Enter picks one (by clicking it), Escape closes the list. Options
 * are the list's [role=option] children.
 */
function enableComboboxKeys(input, listbox) {
  if (!input || !listbox) return;
  input.setAttribute("role", "combobox");
  input.setAttribute("aria-autocomplete", "list");
  input.setAttribute("aria-controls", listbox.id);
  input.setAttribute("aria-expanded", "false");
  listbox.setAttribute("role", "listbox");
  let active = -1;
  const options = () => [...listbox.querySelectorAll("[role=option]")];
  const highlight = (index) => {
    const list = options();
    list.forEach((el, i) => el.setAttribute("aria-selected", String(i === index)));
    active = index;
    if (list[index]) {
      input.setAttribute("aria-activedescendant", list[index].id);
      list[index].scrollIntoView({ block: "nearest" });
    } else {
      input.removeAttribute("aria-activedescendant");
    }
  };
  // New results or a hidden list reset the highlighted option.
  new MutationObserver(() => {
    active = -1;
    input.removeAttribute("aria-activedescendant");
    input.setAttribute("aria-expanded", String(listbox.style.display !== "none" && options().length > 0));
  }).observe(listbox, { childList: true, attributes: true, attributeFilter: ["style"] });
  input.addEventListener("keydown", (e) => {
    const list = options();
    if (e.key === "ArrowDown" && list.length) {
      e.preventDefault();
      listbox.style.display = "block";
      highlight(Math.min(list.length - 1, active + 1));
    } else if (e.key === "ArrowUp" && list.length) {
      e.preventDefault();
      highlight(Math.max(0, active - 1));
    } else if (e.key === "Enter" && list[active]) {
      e.preventDefault();
      list[active].click();
    } else if (e.key === "Escape" && listbox.style.display !== "none") {
      e.preventDefault();
      listbox.style.display = "none";
    }
  });
}

/**
 * Dark or light: the user's stored choice (pala_dark_mode), or the system
 * setting while they have not picked one.
 */
function prefersDarkMode(stored) {
  if (typeof stored === "boolean") return stored;
  return !(typeof matchMedia === "function" && matchMedia("(prefers-color-scheme: light)").matches);
}

/** Hungarian notice shown above cached data when live data is not available. */
function offlineNotice(data) {
  const at = data?.cachedAt || data?.lastUpdated;
  const when = at ? new Date(at).toLocaleString("hu-HU", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }) : "";
  const saved = when ? `Mentett adatok (${when}).` : "Mentett adatokat látsz.";
  switch (data?.offlineReason) {
    case "expired": return `Lejárt a Kréta-bejelentkezés, lépj be újra. ${saved}`;
    case "network": return `Nincs internetkapcsolat. ${saved}`;
    case "maintenance": return `A Kréta karbantartás alatt áll. ${saved}`;
    default: return `A Kréta szerverei most nem érhetők el. ${saved}`;
  }
}

/**
 * Error for Kréta 5xx answers, timeouts and network failures. Callers treat
 * isMaintenance as "serve the cache", so an outage never wipes cached data
 * or reads as an expired session.
 */
function outageError(status, cause) {
  const err = new Error(status
    ? `A Kréta szervere hibát adott (${status}).`
    : "A Kréta szerverei nem válaszolnak (időtúllépés vagy hálózati hiba).");
  err.status = status || 503;
  err.isMaintenance = true;
  // A connection that could not be made at all (not a timeout) is our side.
  err.isNetwork = !status && cause instanceof TypeError;
  err.cause = cause;
  return err;
}

/** True for fetch failures that mean "unreachable" rather than "bad answer". */
function isNetworkFailure(e) {
  return e?.name === "TimeoutError" || e?.name === "AbortError" || e instanceof TypeError;
}

/** "HH:MM" in local time. Kréta timestamps are UTC, so never slice the ISO string. */
function formatLocalTime(value) {
  const d = new Date(value);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

/** Local calendar date as YYYY-MM-DD (toISOString() would give the UTC date). */
function localDateKey(value) {
  const d = new Date(value);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

const DEMO_STUDENT = {
  // Same field names as Kréta's TanuloAdatlap (fictional values).
  Nev: "Teszt Elek",
  SzuletesiNev: "Teszt Elek",
  SzuletesiDatum: "2008-03-15",
  SzuletesiHely: "Budapest",
  AnyjaNeve: "Minta Mária",
  EmailCim: "elek.teszt@pala.edu.hu",
  Telefonszam: "+36 30 123 4567",
  Cimek: ["1111 Budapest, Példa utca 12. II/4"],
  IntezmenyNev: "Pala Minta Gimnázium és Technikum",
  IntezmenyAzonosito: "pala-minta",
  Bankszamla: { BankszamlaSzam: "11773425-06294344-00000000", BankszamlaTulajdonosNeve: "Teszt Elek", BankszamlaTulajdonosTipusId: 1, IsReadOnly: false },
  Gondviselok: [
    { Nev: "Teszt Gábor", EmailCim: "szulo@teszt.hu", Telefonszam: "+36 20 987 6543" },
    { Nev: "Minta Mária", EmailCim: "anya@teszt.hu", Telefonszam: "+36 30 555 4444" }
  ],
  Intezmeny: { TeljesNev: "Pala Minta Gimnázium és Technikum", RovidNev: "Pala Minta" }
};

const DEMO_GRADES = [
  // Matematika (Dr. Számoló Szilárd)
  { Id: 101, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "Függvények & Analízis témazáró", RogzitesDatuma: new Date().toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1011, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 100, Tema: "Váratlan röpdolgozat: Algebrai törtek", RogzitesDatuma: new Date(Date.now() - 50000000).toISOString(), Tipus: { Leiras: "Írásbeli röpdolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1012, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 200, Tema: "Trigonometria és szögfüggvények témazáró", RogzitesDatuma: new Date(Date.now() - 100000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1013, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 100, Tema: "Vektorok koordinátái", RogzitesDatuma: new Date(Date.now() - 150000000).toISOString(), Tipus: { Leiras: "Órai munka" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Magyar nyelv és irodalom (Arany Jánosné)
  { Id: 102, Tantargy: { Nev: "Magyar nyelv és irodalom" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 100, Tema: "Nyugat lírája", RogzitesDatuma: new Date(Date.now() - 86400000).toISOString(), Tipus: { Leiras: "Szóbeli felelet" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1021, Tantargy: { Nev: "Magyar nyelv és irodalom" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 100, Tema: "Helyesírási röpdolgozat", RogzitesDatuma: new Date(Date.now() - 90000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1022, Tantargy: { Nev: "Magyar nyelv és irodalom" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 200, Tema: "Romantika és reformkori irodalom témazáró", RogzitesDatuma: new Date(Date.now() - 120000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Történelem (Kossuth Lajos)
  { Id: 103, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "A reformkor gazdasági törekvései", RogzitesDatuma: new Date(Date.now() - 172800000).toISOString(), Tipus: { Leiras: "Órai munka" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1031, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 100, Tema: "Évszám röpdolgozat", RogzitesDatuma: new Date(Date.now() - 180000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1032, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 200, Tema: "Az 1848-as forradalmak témazáró", RogzitesDatuma: new Date(Date.now() - 190000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Angol nyelv (Smith John)
  { Id: 104, Tantargy: { Nev: "Angol nyelv" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "Conditionals & Essay writing", RogzitesDatuma: new Date(Date.now() - 259200000).toISOString(), Tipus: { Leiras: "Írásbeli dolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1041, Tantargy: { Nev: "Angol nyelv" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "B2 Mock Exam témazáró", RogzitesDatuma: new Date(Date.now() - 300000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Fizika (Eötvös Loránd) - BUKÁSRA ÁLL (~1.71)
  { Id: 105, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 200, Tema: "Newton törvényei témazáró dolgozat", RogzitesDatuma: new Date(Date.now() - 345600000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1051, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 100, Tema: "Vektoriális gyorsulás röpdolgozat", RogzitesDatuma: new Date(Date.now() - 360000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1052, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 100, Tema: "Kinematika és szabadesés felelet", RogzitesDatuma: new Date(Date.now() - 370000000).toISOString(), Tipus: { Leiras: "Szóbeli felelet" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1053, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 200, Tema: "Elektrosztatika és Coulomb-törvény TZ", RogzitesDatuma: new Date(Date.now() - 400000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Informatika / Digitális kultúra (Neumann János)
  { Id: 106, Tantargy: { Nev: "Informatika / Digitális kultúra" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "Python algoritmusok & Adatbázisok", RogzitesDatuma: new Date(Date.now() - 432000000).toISOString(), Tipus: { Leiras: "Gyakorlati feladat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1061, Tantargy: { Nev: "Informatika / Digitális kultúra" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "Relációs adatmodellek házi feladat", RogzitesDatuma: new Date(Date.now() - 440000000).toISOString(), Tipus: { Leiras: "Házi feladat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Kémia (Irinyi János) - BUKÁSRA ÁLL (~1.33)
  { Id: 107, Tantargy: { Nev: "Kémia" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 100, Tema: "Atomszerkezet és periódusos rendszer", RogzitesDatuma: new Date(Date.now() - 190000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1071, Tantargy: { Nev: "Kémia" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 200, Tema: "Kémiai kötések és molekulák témazáró", RogzitesDatuma: new Date(Date.now() - 260000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1072, Tantargy: { Nev: "Kémia" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 200, Tema: "Sav-bázis reakciók és titrálás témazáró", RogzitesDatuma: new Date(Date.now() - 290000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1073, Tantargy: { Nev: "Kémia" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 100, Tema: "Indikátorok pH vizsgálata labor", RogzitesDatuma: new Date(Date.now() - 320000000).toISOString(), Tipus: { Leiras: "Gyakorlati" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Biológia (Szent-Györgyi Albert)
  { Id: 108, Tantargy: { Nev: "Biológia" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "Sejtbiológia és citoplazma", RogzitesDatuma: new Date(Date.now() - 210000000).toISOString(), Tipus: { Leiras: "Órai munka" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1081, Tantargy: { Nev: "Biológia" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 200, Tema: "Genetika és molekuláris biológia témazáró", RogzitesDatuma: new Date(Date.now() - 280000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Testnevelés és egészségfejlesztés (Hajós Alfréd)
  { Id: 109, Tantargy: { Nev: "Testnevelés és egészségfejlesztés" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "Kosárlabda technikai gyakorlatok", RogzitesDatuma: new Date(Date.now() - 150000000).toISOString(), Tipus: { Leiras: "Gyakorlati" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },

  // Földrajz (Teleki Pál) - Gyenge 2-es (~2.00)
  { Id: 110, Tantargy: { Nev: "Földrajz" }, SzovegesErtek: "Elégtelen (1)", SzamErtek: 1, SulySzazalek: 100, Tema: "Földrajzi fokhálózat röpdolgozat", RogzitesDatuma: new Date(Date.now() - 230000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1101, Tantargy: { Nev: "Földrajz" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 200, Tema: "A Föld szerkezete és vulkánosság témazáró", RogzitesDatuma: new Date(Date.now() - 270000000).toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  { Id: 1102, Tantargy: { Nev: "Földrajz" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 100, Tema: "Európa vaktérkép", RogzitesDatuma: new Date(Date.now() - 310000000).toISOString(), Tipus: { Leiras: "Gyakorlati" }, ErtekFajta: { Uid: "1,Osztalyzat", Nev: "Osztalyzat" } },
  // A percentage evaluation with a 1-5 number and a text evaluation: neither
  // counts toward averages (ErtekFajta Szazalekos / Szoveges).
  { Id: 1014, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "4%", SzamErtek: 4, SulySzazalek: null, Tema: "Bemeneti felmérő", RogzitesDatuma: new Date(Date.now() - 200000000).toISOString(), Tipus: { Leiras: "Évközi jegy/értékelés" }, ErtekFajta: { Uid: "3,Szazalekos", Nev: "Szazalekos" } },
  { Id: 1015, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Nem írt", SzamErtek: null, SulySzazalek: null, Tema: "Pótló röpdolgozat", RogzitesDatuma: new Date(Date.now() - 210000000).toISOString(), Tipus: { Leiras: "Évközi jegy/értékelés" }, ErtekFajta: { Uid: "2,Szoveges", Nev: "Szoveges" } }
];

function currentMonday() {
  const now = new Date();
  const currentDay = now.getDay(); // 0 is Sunday, 1 is Monday...
  const mondayOffset = currentDay === 0 ? -6 : 1 - currentDay;
  return new Date(now.getFullYear(), now.getMonth(), now.getDate() + mondayOffset);
}

/** The demo school rotates an A/B week, alternating by week of the year (same rule as DemoData.isDemoAWeek). */
function isDemoAWeek(monday, overrideAWeek = null) {
  if (overrideAWeek !== null) return overrideAWeek;
  const dayOfYear = Math.round((monday - new Date(monday.getFullYear(), 0, 1)) / 86400000);
  return (Math.floor(dayOfYear / 7) + 1) % 2 !== 0;
}

function demoWeekType(overrideAWeek = null) {
  return isDemoAWeek(currentMonday(), overrideAWeek) ? "A hét" : "B hét";
}

function generateDemoTimetable(overrideAWeek = null) {
  const monday = currentMonday();
  const isAWeek = isDemoAWeek(monday, overrideAWeek);

  const weeklySchedule = [
    // Hétfő (Day 0) - 8 óra
    [
      { name: "Matematika", room: "204", teacher: "Dr. Számoló Szilárd", theme: "Másodfokú egyenletek és függvények" },
      { name: "Magyar nyelv és irodalom", room: "108", teacher: "Arany Jánosné", theme: "A magyar felvilágosodás korszaka" },
      { name: "Történelem", room: "215", teacher: "Kossuth Lajos", theme: "A reformkor gazdasági törekvései" },
      { name: "Digitális kultúra", room: "Infó labor 1", teacher: "Neumann János", theme: "Programozás és algoritmusok" },
      { name: "Fizika", room: "Fizika előadó", teacher: "Eötvös Loránd", theme: "Newton törvényei és dinamika", isSubst: true },
      { name: "Angol nyelv", room: "Nyelvi terem 3", teacher: "Smith John", theme: "Conditional sentences practice B2" },
      { name: "Kémia", room: "Kémia labor", teacher: "Irinyi János", theme: "Sav-bázis titrálási kísérlet" },
      { name: "Testnevelés és egészségfejlesztés", room: "Tornaterem", teacher: "Hajós Alfréd", theme: "Kosárlabda technikai elemek" }
    ],
    // Kedd (Day 1) - 7 óra
    [
      { name: "Angol nyelv", room: "Nyelvi terem 3", teacher: "Smith John", theme: "Vocabulary: Environment & Climate" },
      { name: "Matematika", room: "204", teacher: "Dr. Számoló Szilárd", theme: "Geometria: Vektorok a síkban" },
      isAWeek
        ? { name: "Biológia", room: "Bio labor", teacher: "Szent-Györgyi Albert", theme: "Sejtbiológia és biokémiai folyamatok" }
        : { name: "Földrajz", room: "105", teacher: "Teleki Pál", theme: "A Föld belső szerkezete" },
      { name: "Kémia", room: "Kémia előadó", teacher: "Irinyi János", theme: "Redoxireakciók és égés", isSubst: true },
      { name: "Testnevelés és egészségfejlesztés", room: "Tornaterem", teacher: "Hajós Alfréd", theme: "Erőnléti állapotfelmérés" },
      { name: "Földrajz", room: "105", teacher: "Teleki Pál", theme: "A Kárpát-medence természeti földrajza" },
      { name: "Fizika", room: "Fizika előadó", teacher: "Eötvös Loránd", theme: "Elektrosztatika: Coulomb-törvény", isCanc: true }
    ],
    // Szerda (Day 2) - 0 óra (NINCS TANÓRA - Tanítás nélküli nap / Szabadnap)
    [],
    // Csütörtök (Day 3) - 8 óra
    [
      { name: "Kémia", room: "Kémia előadó", teacher: "Irinyi János", theme: "Szerves kémia alapjai" },
      { name: "Biológia", room: "Bio labor", teacher: "Szent-Györgyi Albert", theme: "Fotoszintézis és sejtlégzés" },
      { name: "Angol nyelv", room: "Nyelvi terem 3", teacher: "Smith John", theme: "Reading comprehension B2 mock test", isSubst: true },
      { name: "Magyar nyelv és irodalom", room: "108", teacher: "Arany Jánosné", theme: "Kölcsey Ferenc: Himnusz elemzés" },
      { name: "Történelem", room: "215", teacher: "Kossuth Lajos", theme: "Az 1848-as forradalom eseményei" },
      { name: "Földrajz", room: "105", teacher: "Teleki Pál", theme: "Európa gazdasági földrajza" },
      isAWeek
        ? { name: "Matematika", room: "204", teacher: "Dr. Számoló Szilárd", theme: "Trigonometrikus feladatok" }
        : { name: "Fizika", room: "Fizika előadó", teacher: "Eötvös Loránd", theme: "Mérési gyakorlat" },
      { name: "Digitális kultúra", room: "Infó labor 1", teacher: "Neumann János", theme: "Adatbázisok és SQL lekérdezések" }
    ],
    // Péntek (Day 4) - 7 óra
    [
      { name: "Matematika", room: "204", teacher: "Dr. Számoló Szilárd", theme: "Valószínűségszámítás alapjai" },
      { name: "Digitális kultúra", room: "Infó labor 1", teacher: "Neumann János", theme: "Projektmunka bemutató", isSubst: true },
      { name: "Fizika", room: "Fizika előadó", teacher: "Eötvös Loránd", theme: "Fénytörés és lencsék" },
      { name: "Angol nyelv", room: "Nyelvi terem 3", teacher: "Smith John", theme: "Academic essay writing" },
      { name: "Testnevelés és egészségfejlesztés", room: "Sportpálya", teacher: "Hajós Alfréd", theme: "Foci és atlétika bajnokság" },
      { name: "Osztályfőnöki", room: "215", teacher: "Kossuth Lajos", theme: "DÖK választás és osztályprogramok" },
      { name: "Magyar nyelv és irodalom", room: "108", teacher: "Arany Jánosné", theme: "Vörösmarty: Szózat lírai világa" }
    ]
  ];

  const timetable = [];
  const periodHours = [
    ["07:55", "08:40"],
    ["08:50", "09:35"],
    ["09:45", "10:30"],
    ["10:45", "11:30"],
    ["11:40", "12:25"],
    ["12:45", "13:30"],
    ["13:40", "14:25"],
    ["14:35", "15:20"]
  ];

  weeklySchedule.forEach((dayLessons, dayIdx) => {
    const dayDate = new Date(monday.getFullYear(), monday.getMonth(), monday.getDate() + dayIdx);

    dayLessons.forEach((lesson, lessonIdx) => {
      const [startStr, endStr] = periodHours[lessonIdx] || ["08:00", "08:45"];
      const [sH, sM] = startStr.split(":").map(Number);
      const [eH, eM] = endStr.split(":").map(Number);

      const start = new Date(dayDate.getFullYear(), dayDate.getMonth(), dayDate.getDate(), sH, sM);
      const end = new Date(dayDate.getFullYear(), dayDate.getMonth(), dayDate.getDate(), eH, eM);

      let state = { Nev: "Megtartott" };
      let subTeacher = null;
      if (lesson.isSubst) {
        state = { Nev: "Helyettesített" };
        subTeacher = "Jedlik Ányos";
      } else if (lesson.isCanc) {
        state = { Nev: "Elmaradt" };
      }

      timetable.push({
        Id: (dayIdx + 1) * 1000 + lessonIdx + 1,
        Oraszam: lessonIdx + 1,
        KezdetIdopont: start.toISOString(),
        VegIdopont: end.toISOString(),
        Tantargy: { Nev: lesson.name },
        TeremNeve: lesson.room,
        TanarNeve: lesson.teacher,
        HelyettesTanarNeve: subTeacher,
        Tema: lesson.theme,
        Allapot: state
      });
    });
  });

  return timetable;
}

const DEMO_HOMEWORK = [
  { Id: 201, Tantargy: "Matematika", Hatarido: new Date(Date.now() + 86400000).toISOString(), Szoveg: "Tk. 142. oldal 5, 6, 7. feladatok kidolgozása", Tanar: "Kovács Péter" },
  { Id: 202, Tantargy: "Történelem", Hatarido: new Date(Date.now() + 172800000).toISOString(), Szoveg: "Forráselemzés a reformkori vitákról (vázlatkészítés)", Tanar: "Horváth László" },
  { Id: 203, Tantargy: "Fizika", Hatarido: new Date(Date.now() + 259200000).toISOString(), Szoveg: "Coulomb-törvény gyakorló feladatsor", Tanar: "Szabó Zoltán" }
];

const DEMO_EXAMS = [
  { Id: 301, Tantargy: "Matematika", Datum: new Date(Date.now() + 172800000).toISOString(), Tema: "Függvénytranszformációk & Szélsőérték", Tipus: "Témazáró dolgozat" },
  { Id: 302, Tantargy: "Angol nyelv", Datum: new Date(Date.now() + 345600000).toISOString(), Tema: "C1 Unit 4 Vocabulary & Grammar", Tipus: "Szódolgozat" }
];

const DEMO_ABSENCES = [
  { Id: 401, Datum: new Date(Date.now() - 604800000).toISOString(), Tantargy: "Biológia", IgazolasAllapota: "Igazolt", Tipus: "Szülői igazolás", KesesPercben: 0 },
  { Id: 402, Datum: new Date(Date.now() - 604800000).toISOString(), Tantargy: "Kémia", IgazolasAllapota: "Igazolt", Tipus: "Szülői igazolás", KesesPercben: 0 },
  { Id: 403, Datum: new Date(Date.now() - 500000000).toISOString(), Tantargy: "Fizika", IgazolasAllapota: "Igazolatlan", Tipus: "Mulasztás", KesesPercben: 0 },
  { Id: 404, Datum: new Date(Date.now() - 400000000).toISOString(), Tantargy: "Történelem", IgazolasAllapota: "Igazolt", Tipus: "Késés", KesesPercben: 15 },
  { Id: 405, Datum: new Date(Date.now() - 300000000).toISOString(), Tantargy: "Matematika", IgazolasAllapota: "Igazolatlan", Tipus: "Késés", KesesPercben: 10 },
  // Repeated unexcused absences/lateness behind the megrovás messages below.
  { Id: 406, Datum: new Date(Date.now() - 1641600000).toISOString(), Tantargy: "Történelem", IgazolasAllapota: "Igazolatlan", Tipus: "Mulasztás", KesesPercben: 0 },
  { Id: 407, Datum: new Date(Date.now() - 1641600000).toISOString(), Tantargy: "Kémia", IgazolasAllapota: "Igazolatlan", Tipus: "Mulasztás", KesesPercben: 0 },
  { Id: 408, Datum: new Date(Date.now() - 950400000).toISOString(), Tantargy: "Angol nyelv", IgazolasAllapota: "Igazolatlan", Tipus: "Késés", KesesPercben: 12 }
];

const DEMO_GROUP_AVERAGES = [
  { Tantargy: { Nev: "Matematika" }, OsztalyCsoportAtlag: 3.82 },
  { Tantargy: { Nev: "Magyar nyelv és irodalom" }, OsztalyCsoportAtlag: 4.15 },
  { Tantargy: { Nev: "Történelem" }, OsztalyCsoportAtlag: 3.95 },
  { Tantargy: { Nev: "Angol nyelv" }, OsztalyCsoportAtlag: 4.30 },
  { Tantargy: { Nev: "Informatika / Digitális kultúra" }, OsztalyCsoportAtlag: 4.60 },
  { Tantargy: { Nev: "Fizika" }, OsztalyCsoportAtlag: 3.45 },
  { Tantargy: { Nev: "Kémia" }, OsztalyCsoportAtlag: 3.60 },
  { Tantargy: { Nev: "Biológia" }, OsztalyCsoportAtlag: 4.05 },
  { Tantargy: { Nev: "Testnevelés és egészségfejlesztés" }, OsztalyCsoportAtlag: 4.70 },
  { Tantargy: { Nev: "Földrajz" }, OsztalyCsoportAtlag: 3.75 }
];

const KRETA_IDP = "https://idp.e-kreta.hu";
const KRETA_ADMIN = "https://eugyintezes.e-kreta.hu";
const KRETA_API_KEY = "21ff6c25-d1da-4a68-a811-c881a6057463";
const CLIENT_ID = "kreta-ellenorzo-student-mobile-ios";
const CODE_VERIFIER = "DSpuqj_HhDX4wzQIbtn8lr8NLE5wEi1iVLMtMK0jY6c";
const CODE_CHALLENGE = "HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ";
const REDIRECT_URI = "https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect";
const OAUTH_NONCE = "wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU";
const OAUTH_SCOPE = "openid email offline_access kreta-ellenorzo-webapi.public kreta-eugyintezes-webapi.public kreta-fileservice-webapi.public kreta-mobile-global-webapi.public kreta-dkt-webapi.public kreta-ier-webapi.public";
const USER_AGENT = "eKretaStudent/264745 CFNetwork/1494.0.7 Darwin/23.4.0";
const CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes safe cache TTL
const AUTH_TIMEOUT_MS = 15000;

/**
 * Encrypts the OAuth session (access/refresh tokens) at rest using a
 * non-extractable AES-GCM key kept in IndexedDB. The key material never
 * leaves the crypto subsystem as plain bytes, so the chrome.storage data on
 * its own does not reveal a token. The key lives in the same browser
 * profile, though: whoever copies the whole profile folder gets both.
 * Non-sensitive fields (institute, user, expires_at) stay in plaintext for
 * cheap synchronous reads across the UI.
 */
class SecureSession {
  static _dbPromise = null;

  static _openDb() {
    if (this._dbPromise) return this._dbPromise;
    this._dbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open("pala_secure", 1);
      req.onupgradeneeded = () => {
        req.result.createObjectStore("keys");
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
    return this._dbPromise;
  }

  static async _getKey() {
    const db = await this._openDb();
    const existing = await new Promise((resolve, reject) => {
      const tx = db.transaction("keys", "readonly");
      const req = tx.objectStore("keys").get("session_key");
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error);
    });
    if (existing) return existing;

    const key = await crypto.subtle.generateKey(
      { name: "AES-GCM", length: 256 },
      false, // non-extractable: cannot be exported back to raw bytes
      ["encrypt", "decrypt"]
    );
    await new Promise((resolve, reject) => {
      const tx = db.transaction("keys", "readwrite");
      tx.objectStore("keys").put(key, "session_key");
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
    });
    return key;
  }

  /** Splits a session object into plaintext metadata + an encrypted secrets blob. */
  static async encrypt(session) {
    if (!session) return null;
    const { token, refresh_token, ...rest } = session;
    const key = await this._getKey();
    const iv = crypto.getRandomValues(new Uint8Array(12));
    const plaintext = new TextEncoder().encode(JSON.stringify({ token, refresh_token }));
    const ciphertext = await crypto.subtle.encrypt({ name: "AES-GCM", iv }, key, plaintext);
    return {
      ...rest,
      _secure: {
        iv: Array.from(iv),
        data: Array.from(new Uint8Array(ciphertext)),
      },
    };
  }

  /** Reconstructs the full session object (with plaintext token fields) for API use. */
  static async decrypt(stored) {
    if (!stored) return null;
    if (!stored._secure) return stored; // legacy plaintext session; caller should re-save via encrypt()
    try {
      const key = await this._getKey();
      const iv = new Uint8Array(stored._secure.iv);
      const data = new Uint8Array(stored._secure.data);
      const plainBuf = await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, data);
      const { token, refresh_token } = JSON.parse(new TextDecoder().decode(plainBuf));
      const { _secure, ...rest } = stored;
      return { ...rest, token, refresh_token };
    } catch (e) {
      console.error("Pala: nem sikerult a munkamenet visszafejtese:", e);
      return null;
    }
  }

  /** Encrypts and writes the session to chrome.storage.local under pala_session and registers it in pala_profiles. */
  static async save(session) {
    if (session === null || session === undefined) {
      await chrome.storage.local.set({ pala_session: null });
      return;
    }
    const profileId = session.id || `${session.institute || "klik"}_${(session.user || "diak").replace(/\s+/g, "_")}`;
    const enriched = { ...session, id: profileId };
    const encrypted = await this.encrypt(enriched);

    const store = await chrome.storage.local.get("pala_profiles");
    const profiles = Array.isArray(store.pala_profiles) ? store.pala_profiles : [];
    const idx = profiles.findIndex(p => p.id === profileId || (p.institute === enriched.institute && p.user === enriched.user));
    if (idx >= 0) {
      profiles[idx] = encrypted;
    } else {
      profiles.push(encrypted);
    }

    await chrome.storage.local.set({
      pala_session: encrypted,
      pala_profiles: profiles
    });
  }

  /**
   * Signs out the active profile: revokes its refresh token at Kréta (best
   * effort) and removes it from pala_profiles, so the profile switcher cannot
   * bring it back.
   */
  static async logout() {
    const store = await chrome.storage.local.get(["pala_session", "pala_profiles"]);
    const active = store.pala_session;
    if (active) {
      const session = await this.decrypt(active).catch(() => null);
      if (session?.refresh_token) await KretaApi.revokeToken(session.refresh_token);
      const profiles = Array.isArray(store.pala_profiles) ? store.pala_profiles : [];
      const remaining = profiles.filter(p => !(p.id === active.id || (p.institute === active.institute && p.user === active.user)));
      await chrome.storage.local.set({ pala_profiles: remaining });
    }
    await chrome.storage.local.set({ pala_session: null });
  }

  /** Reads and decrypts pala_session from chrome.storage.local. */
  static async load() {
    const store = await chrome.storage.local.get("pala_session");
    return this.decrypt(store.pala_session);
  }

  /** Returns all available profiles (saved encrypted profiles + Demo profile). */
  static async listProfiles() {
    const store = await chrome.storage.local.get(["pala_profiles", "pala_session", "pala_use_demo"]);
    // Demo data only when the user chose it; a fresh install asks for a login.
    const useDemo = store.pala_use_demo === true;
    const activeSession = store.pala_session;
    const rawProfiles = Array.isArray(store.pala_profiles) ? [...store.pala_profiles] : [];

    if (activeSession && !rawProfiles.some(p => p.id === activeSession.id)) {
      rawProfiles.unshift(activeSession);
    }

    const items = rawProfiles.map(p => ({
      id: p.id || `${p.institute || "klik"}_${p.user || "diak"}`,
      user: p.user || "Kréta Diák",
      institute: p.institute || "",
      isDemo: false,
      isActive: !useDemo && activeSession && (activeSession.id === p.id || activeSession.institute === p.institute)
    }));

    items.push({
      id: "demo",
      user: "Teszt Elek (Demó)",
      institute: "Pala Minta Gimnázium",
      isDemo: true,
      isActive: useDemo
    });

    return items;
  }

  /** Switches active profile by id ("demo" or a saved profile id). */
  static async switchProfile(profileId) {
    if (profileId === "demo") {
      await chrome.storage.local.set({ pala_use_demo: true, pala_simulate_maintenance: false });
      return;
    }
    const store = await chrome.storage.local.get("pala_profiles");
    const profiles = Array.isArray(store.pala_profiles) ? store.pala_profiles : [];
    const target = profiles.find(p => (p.id || `${p.institute || "klik"}_${p.user || "diak"}`) === profileId);
    if (target) {
      await chrome.storage.local.remove(["pala_cached_data", "pala_last_fetch"]);
      await chrome.storage.local.set({
        pala_session: target,
        pala_use_demo: false,
        pala_simulate_maintenance: false
      });
    }
  }
}

class KretaApi {
  /**
   * Kréta institute codes are lowercase letters, digits and dashes. Anything
   * else could move the Bearer token to another host, so it is refused.
   */
  static isValidInstituteCode(code) {
    return /^[a-z0-9-]{2,40}$/.test(String(code ?? ""));
  }

  /** Lowercase, accent-free form for accent-insensitive Hungarian search. */
  static normalizeHu(value) {
    return String(value ?? "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
  }

  /**
   * Searches schools by name or code using Kréta's official institute selector.
   */
  static async searchSchools(query) {
    if (!query || query.trim().length < 2) return [];
    try {
      const url = `https://intezmenykereso.e-kreta.hu/instituteSelector/${encodeURIComponent(query.trim())}?showOnlyLive=true`;
      const res = await fetch(url, { signal: AbortSignal.timeout(AUTH_TIMEOUT_MS) });
      if (!res.ok) return [];
      const html = await res.text();

      const regex = /<a[^>]*class=["'][^"']*dropdown-item[^"']*["'][^>]*data-val=["']([^"']+)["'][^>]*>(.*?)<\/a>/gis;
      const results = [];
      let match;
      while ((match = regex.exec(html)) !== null) {
        const code = match[1]?.trim();
        let text = (match[2] || "").replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
        text = text.replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
                   .replace(/&#([0-9]+);/g, (_, dec) => String.fromCharCode(parseInt(dec, 10)));
        if (code && text) {
          results.push({ code, name: text });
        }
      }
      return results;
    } catch (e) {
      console.warn("School search failed:", e);
      return [];
    }
  }

  /**
   * Generates the official Kréta OAuth2 authorization URL.
   */
  static getAuthorizeUrl(instituteCode, state) {
    const scopeEncoded = encodeURIComponent(OAUTH_SCOPE);
    const redirectEncoded = encodeURIComponent(REDIRECT_URI);
    const stateEncoded = encodeURIComponent(state || "pala_student_mobile");
    let base = `${KRETA_IDP}/connect/authorize` +
      `?prompt=login` +
      `&nonce=${OAUTH_NONCE}` +
      `&response_type=code` +
      `&code_challenge_method=S256` +
      `&scope=${scopeEncoded}` +
      `&code_challenge=${CODE_CHALLENGE}` +
      `&redirect_uri=${redirectEncoded}` +
      `&client_id=${CLIENT_ID}` +
      `&state=${stateEncoded}`;
    if (instituteCode) {
      const code = encodeURIComponent(instituteCode.trim().toLowerCase());
      base += `&institute_code=${code}&acr_values=institute_code:${code}`;
    }
    return base;
  }

  /**
   * Starts a browser-tab OAuth login: generates a fresh random state value,
   * stores it (with the institute code) as the pending login, and returns
   * the authorize URL to open. handleOAuthRedirect() in the background
   * service worker verifies the returned state matches before accepting
   * the authorization code, which prevents a crafted/replayed redirect
   * from being accepted as a legitimate login completion (CSRF on login).
   */
  static async startWebLogin(instituteCode) {
    if (!this.isValidInstituteCode(instituteCode)) throw new Error("Érvénytelen intézménykód.");
    const state = crypto.randomUUID();
    await chrome.storage.local.set({
      pala_pending_login: { institute: instituteCode, state }
    });
    return this.getAuthorizeUrl(instituteCode, state);
  }

  /**
   * Exchanges an OAuth2 authorization code for access and refresh tokens.
   */
  static async exchangeCodeForToken(code) {
    const tokenUrl = `${KRETA_IDP}/connect/token`;
    const body = new URLSearchParams({
      code: code,
      code_verifier: CODE_VERIFIER,
      redirect_uri: REDIRECT_URI,
      client_id: CLIENT_ID,
      grant_type: "authorization_code"
    });

    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": USER_AGENT
      },
      body: body.toString(),
      signal: AbortSignal.timeout(AUTH_TIMEOUT_MS)
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`Token lekérési hiba (${response.status}): ${errText}`);
    }

    const data = await response.json();
    return {
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: Date.now() + (data.expires_in || 1200) * 1000
    };
  }

  /** Revokes a refresh token at Kréta. Best effort: returns false on any failure. */
  static async revokeToken(refreshToken) {
    try {
      const response = await fetch(`${KRETA_IDP}/connect/revocation`, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": USER_AGENT
        },
        body: new URLSearchParams({
          client_id: CLIENT_ID,
          token: refreshToken,
          token_type_hint: "refresh_token"
        }),
        signal: AbortSignal.timeout(AUTH_TIMEOUT_MS)
      });
      return response.ok;
    } catch (e) {
      console.warn("Nem sikerült visszavonni a tokent:", e);
      return false;
    }
  }

  /**
   * Refreshes an expired access token using the stored refresh_token.
   */
  static async refreshAccessToken(refreshToken) {
    const tokenUrl = `${KRETA_IDP}/connect/token`;
    const body = new URLSearchParams({
      client_id: CLIENT_ID,
      grant_type: "refresh_token",
      refresh_token: refreshToken
    });

    let response;
    try {
      response = await fetch(tokenUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "User-Agent": USER_AGENT
        },
        body: body.toString(),
        signal: AbortSignal.timeout(AUTH_TIMEOUT_MS)
      });
    } catch (e) {
      throw isNetworkFailure(e) ? outageError(0, e) : e;
    }

    if (response.status >= 500) throw outageError(response.status);
    if (!response.ok) {
      const err = new Error("A munkamenet lejárt. Kérlek jelentkezz be újra.");
      err.sessionExpired = true;
      throw err;
    }

    const data = await response.json();
    return {
      access_token: data.access_token,
      refresh_token: data.refresh_token || refreshToken,
      expires_at: Date.now() + (data.expires_in || 1200) * 1000
    };
  }

  /**
   * Ensures the session has a valid, non-expired access token before calling APIs.
   */
  static async ensureValidToken(session) {
    if (!session || !session.token) {
      throw new Error("Nincs bejelentkezett felhasználói munkamenet.");
    }

    try {
      await this.refreshSession(session);
    } catch (e) {
      if (e.isMaintenance || e.sessionExpired) throw e;
      console.warn("Token frissítési hiba:", e);
    }
    return session.token;
  }

  /**
   * Refreshes `session` in place when its access token is within 2 minutes of
   * expiry, or unconditionally with `force` (after a 401). Kréta refresh tokens
   * are single-use, and the popup, side panel, dashboard and service worker can
   * all refresh at once, so this runs under a Web Lock shared by every context
   * of the extension origin. The stored session is the source of truth: if
   * another context already rotated the tokens, they are adopted instead of
   * redeeming the old (now burned) refresh token. Nothing is kept in module
   * globals, so a service worker that slept just re-reads storage.
   */
  static async refreshSession(session, force = false) {
    const run = async () => {
      const stored = await SecureSession.load();
      const rotated = !!stored?.refresh_token && stored.id === session.id && stored.refresh_token !== session.refresh_token;
      if (rotated) {
        session.token = stored.token;
        session.refresh_token = stored.refresh_token;
        session.expires_at = stored.expires_at;
      }
      const expiring = session.expires_at && Date.now() > session.expires_at - 120000;
      if (!session.refresh_token || !(expiring || (force && !rotated))) return;

      const refreshed = await this.refreshAccessToken(session.refresh_token);
      session.token = refreshed.access_token;
      session.refresh_token = refreshed.refresh_token;
      session.expires_at = refreshed.expires_at;
      await SecureSession.save(session);
    };
    return navigator.locks ? navigator.locks.request("pala_token_refresh", run) : run();
  }

  /**
   * Direct credentials login simulation via OAuth2 code extraction.
   */
  static async login(instituteCode, username, password) {
    const authorizeUrl = this.getAuthorizeUrl(instituteCode);

    // Step 1: Request the login page to extract CSRF token and return URL
    const step1Res = await fetch(authorizeUrl, {
      method: "GET",
      credentials: "include"
    });

    if (!step1Res.ok) {
      throw new Error(`Nem sikerült elérni a Kréta IDP szerverét (${step1Res.status}).`);
    }

    const html = await step1Res.text();
    const tokenMatch = html.match(/name="__RequestVerificationToken"[^>]+value="([^"]+)"/);
    const returnUrlMatch = html.match(/name="ReturnUrl"[^>]+value="([^"]+)"/);

    if (!tokenMatch || !returnUrlMatch) {
      throw new Error("Nem sikerült kinyerni az azonosítási tokent. Kérlek próbáld a Webes Bejelentkezést!");
    }

    const requestToken = tokenMatch[1];
    const returnUrl = returnUrlMatch[1].replace(/&amp;/g, "&");

    // Step 2: Submit credentials to Kréta IDP Account/Login
    const loginPostUrl = `${KRETA_IDP}/Account/Login?ReturnUrl=${encodeURIComponent(returnUrl)}`;
    const postBody = new URLSearchParams({
      UserName: username,
      Password: password,
      InstituteCode: instituteCode,
      __RequestVerificationToken: requestToken,
      ReturnUrl: returnUrl,
      loginType: "InstituteLogin",
      button: "login"
    });

    const step2Res = await fetch(loginPostUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: postBody.toString(),
      credentials: "include"
    });

    // Step 3: Check response and look for callback URL or code
    let redirectUrl = step2Res.url;
    let code = null;

    if (redirectUrl.includes("code=")) {
      const urlObj = new URL(redirectUrl.replace("#", "?"));
      code = urlObj.searchParams.get("code");
    }

    if (!code) {
      const step2Text = await step2Res.text();
      const callbackMatch = step2Text.match(/href="(\/connect\/authorize\/callback[^"]+)"/);
      if (callbackMatch) {
        const callbackUrl = `${KRETA_IDP}${callbackMatch[1].replace(/&amp;/g, "&")}`;
        const step3Res = await fetch(callbackUrl, {
          method: "GET",
          credentials: "include"
        });
        if (step3Res.url.includes("code=")) {
          const urlObj = new URL(step3Res.url.replace("#", "?"));
          code = urlObj.searchParams.get("code");
        } else {
          const step3Text = await step3Res.text();
          const finalMatch = step3Text.match(/code=([a-zA-Z0-9_\-\.]+)/);
          if (finalMatch) code = finalMatch[1];
        }
      }
    }

    if (!code) {
      let kretaError = "";
      try {
        const step2Text = await step2Res.text();
        const errListMatch = step2Text.match(/<div class="[^"]*validation-summary-errors[^"]*">([\s\S]*?)<\/div>/i) ||
                             step2Text.match(/<li[^>]*>(.*?)<\/li>/i);
        if (errListMatch) {
          kretaError = errListMatch[1].replace(/<[^>]+>/g, " ").replace(/\s+/g, " ").trim();
          kretaError = kretaError.replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
                                 .replace(/&#([0-9]+);/g, (_, dec) => String.fromCharCode(parseInt(dec, 10)));
        }
      } catch (_) {}

      throw new Error(kretaError || "Hibás intézmény, felhasználónév vagy jelszó! Használd az intézménykeresőt az iskola pontos kiválasztásához, vagy a Webes Bejelentkezést.");
    }

    // Step 4: Exchange code for OAuth tokens
    return await this.exchangeCodeForToken(code);
  }

  /**
   * Fetches full student data with rate-limit protections and error handling.
   */
  static async getStudentData(instituteCode, accessToken) {
    const code = String(instituteCode ?? "").trim().toLowerCase();
    if (!this.isValidInstituteCode(code)) throw new Error("Érvénytelen intézménykód.");
    const base = `https://${code}.e-kreta.hu/ellenorzo/V3/Sajat`;
    const headers = {
      "Authorization": `Bearer ${accessToken}`,
      "apiKey": KRETA_API_KEY,
      "User-Agent": USER_AGENT,
      "Accept": "application/json"
    };

    const fetchEndpoint = async (endpoint) => {
      try {
        const res = await fetch(`${base}/${endpoint}`, {
          headers,
          signal: AbortSignal.timeout(8000)
        });
        if (res.status === 429) {
          await chrome.storage.local.set({ pala_backoff_until: Date.now() + 2 * 60 * 1000 });
          // Throw instead of returning null: an empty list would replace the cached data.
          const err = new Error("A Kréta túl sok kérést kapott. Próbáld újra pár perc múlva.");
          err.status = 429;
          throw err;
        }
        if (res.status === 401) {
          const err = new Error("401 Unauthorized - A munkamenet lejárt.");
          err.status = 401;
          throw err;
        }
        // Fail the whole load instead of returning null, so getCachedOrFetchData
        // keeps the last good cache rather than overwriting it with gaps.
        if (res.status >= 500) throw outageError(res.status);
        if (!res.ok) {
          return null;
        }
        return await res.json();
      } catch (e) {
        if (e.status === 401 || e.status === 429 || e.isMaintenance) throw e;
        if (isNetworkFailure(e)) throw outageError(0, e);
        console.warn(`Hiba a(z) ${endpoint} lekérésekor:`, e);
        return null;
      }
    };

    // Calculate current week range for timetable (Monday to Sunday)
    const now = new Date();
    const dayOfWeek = (now.getDay() + 6) % 7; // 0 = Mon, 6 = Sun
    const monday = new Date(now);
    monday.setDate(now.getDate() - dayOfWeek);
    monday.setHours(0, 0, 0, 0);

    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);

    const datumTol = monday.toISOString();
    const datumIg = sunday.toISOString();
    const localStamp = d => `${localDateKey(d)}T${formatLocalTime(d)}:00`;

    // 30 days back for homework
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000);
    const hwDatumTol = thirtyDaysAgo.toISOString().split("T")[0];

    // Class/group averages need the group's task UID first, then the averages
    // endpoint itself — two sequential calls, run alongside everything else.
    let className = null;
    const groupAveragesPromise = (async () => {
      try {
        const groups = await fetchEndpoint("OsztalyCsoportok");
        const group = KretaApi.mainClassGroup(groups);
        if (!group) return [];
        className = group.Nev || null;
        const taskUid = group?.OktatasNevelesiFeladat?.Uid;
        if (!taskUid) return [];
        const avgs = await fetchEndpoint(`Ertekelesek/Atlagok/OsztalyAtlagok?oktatasiNevelesiFeladatUid=${encodeURIComponent(taskUid)}`);
        return Array.isArray(avgs) ? avgs : [];
      } catch (e) {
        console.warn("Hiba az osztályátlagok lekérésekor:", e);
        return [];
      }
    })();

    // Fetch core Ellenőrző data (Fast, reliable, never blocked by e-Ügyintézés)
    const [student, grades, timetable, homework, exams, absences, notes, circulars, groupAverages, weekOrder] = await Promise.all([
      fetchEndpoint("TanuloAdatlap"),
      fetchEndpoint("Ertekelesek"),
      fetchEndpoint(`OrarendElemek?datumTol=${encodeURIComponent(datumTol)}&datumIg=${encodeURIComponent(datumIg)}`),
      fetchEndpoint(`HaziFeladatok?datumTol=${encodeURIComponent(hwDatumTol)}`),
      fetchEndpoint("BejelentettSzamonkeresek"),
      fetchEndpoint("Mulasztasok"),
      fetchEndpoint("Feljegyzesek"),
      fetchEndpoint("FaliujsagElemek"),
      groupAveragesPromise,
      fetchEndpoint(`Intezmenyek/Hetirendek/Orarendi?orarendElemKezdoNapDatuma=${encodeURIComponent(localStamp(monday))}&orarendElemVegNapDatuma=${encodeURIComponent(localStamp(sunday))}`)
    ]);

    // Normalize student institution name
    if (student) {
      if (!student.IntezmenyNev && student.Intezmeny) {
        student.IntezmenyNev = student.Intezmeny.TeljesNev || student.Intezmeny.Nev || student.Intezmeny.Kod || instituteCode;
      }
    }

    const sortedGrades = Array.isArray(grades) ? grades : [];
    sortedGrades.sort((a, b) => {
      const da = new Date(a.KeszitesDatuma || a.RogzitesDatuma || a.Datum || 0).getTime();
      const db = new Date(b.KeszitesDatuma || b.RogzitesDatuma || b.Datum || 0).getTime();
      return db - da;
    });

    const sortedTimetable = Array.isArray(timetable) ? timetable : [];
    sortedTimetable.sort((a, b) => {
      const ta = new Date(a.KezdetIdopont || 0).getTime();
      const tb = new Date(b.KezdetIdopont || 0).getTime();
      return ta - tb;
    });

    const parsedMessages = [];
    // Notes and circulars come from the ellenorzo API; messages from e-Ugyintezas
    // are fetched separately (getAdminMessages) and merged by the UI layer.
    if (Array.isArray(notes)) {
      notes.forEach(n => {
        parsedMessages.push({
          id: n.Uid || n.Id || Math.random(),
          type: n.Tipus?.Leiras || n.Tipus?.Nev || "Feljegyzés",
          sender: n.KeszitoTanarNeve || n.Tanar || "Tanár",
          title: n.Cim || n.Tartalom || n.Tipus?.Leiras || "Feljegyzés",
          content: n.Tartalom || n.Szoveg || "",
          date: n.KeszitesDatuma || n.Datum || n.RogzitesDatuma,
          source: "ellenorzo"
        });
      });
    }
    if (Array.isArray(circulars)) {
      circulars.forEach(c => {
        parsedMessages.push({
          id: c.Uid || c.Id || Math.random(),
          type: "Hirdetmény",
          sender: c.KeszitoNeve || c.IntezmenyNev || "Iskola",
          title: c.Cim || "Faliújság hirdetmény",
          content: c.Tartalom || c.Szoveg || "",
          date: c.KeszitesDatuma || c.Datum || c.PublikalasDatuma,
          source: "circular"
        });
      });
    }
    const sortedMessages = KretaApi.sortMessagesNewestFirst(parsedMessages);

    return {
      student: student || null,
      grades: sortedGrades,
      timetable: sortedTimetable,
      weekType: KretaApi.weekTypeLabel(weekOrder, monday),
      homework: Array.isArray(homework) ? homework : [],
      exams: Array.isArray(exams) ? exams : [],
      absences: Array.isArray(absences) ? absences : [],
      groupAverages: Array.isArray(groupAverages) ? groupAverages : [],
      className,
      messages: sortedMessages,
      // teachers and questionnaires come from e-Ugyintezas (fetched separately).
      teachers: [],
      questionnaires: [],
      lastUpdated: new Date().toISOString()
    };
  }

  /**
   * Helper to fetch from e-Ügyintézés API.
   */
  static async fetchAdmin(token, endpoint, method = "GET", body = null) {
    const url = `${KRETA_ADMIN}/api/v1/${endpoint}`;
    const headers = {
      "Accept": "application/json, text/plain, */*",
      "apiKey": KRETA_API_KEY
    };
    if (token) {
      headers["Authorization"] = `Bearer ${token}`;
    }
    if (body) {
      headers["Content-Type"] = "application/json";
    }

    try {
      const res = await fetch(url, {
        method,
        headers,
        body: body ? JSON.stringify(body) : undefined,
        credentials: "include",
        signal: AbortSignal.timeout(3500)
      });
      if (!res.ok) {
        console.warn(`Admin API válasz nem OK (${res.status}) a(z) ${endpoint} végponton.`);
        return null;
      }
      return await res.json();
    } catch (e) {
      console.warn(`Hiba az e-Ügyintézés (${endpoint}) elérésekor:`, e);
      return null;
    }
  }

  /**
   * Fetches postal mailbox messages from e-Ügyintézés.
   */
  static async getAdminMessages(token) {
    try {
      // 1. Fetch exactly like the Dart TUI / desktop app
      let data = await this.fetchAdmin(token, "kommunikacio/postaladaelemek/sajat");
      if (!Array.isArray(data) || data.length === 0) {
        data = await this.fetchAdmin(token, "kommunikacio/postaladaelemek/beerkezett");
      }

      // 2. Return empty array if not available
      if (!Array.isArray(data) || data.length === 0) {
        return [];
      }

      return KretaApi.sortMessagesNewestFirst(data.map(item => {
        const msg = item.uzenet || {};
        const sender = item.uzenetFeladoNev || msg.feladoNev || item.feladoNev || "Ismeretlen feladó";
        const senderTitle = item.uzenetFeladoTitulus || msg.feladoTitulus || "";
        const fullSender = senderTitle ? `${sender} (${senderTitle})` : sender;
        const subject = item.uzenetTargy || msg.targy || item.targy || "Nincs tárgy";
        const date = item.uzenetKuldesDatum || msg.kuldesDatum || item.kuldesDatum || null;
        const content = item.uzenetSzoveg || item.szoveg || msg.szoveg || "";

        return {
          id: item.azonosito || item.uzenetAzonosito || msg.azonosito || Math.random(),
          sender: fullSender,
          subject: subject,
          title: subject,
          content: content,
          date: date,
          isRead: item.isElolvasva === true,
          attachments: Array.isArray(item.csatolmanyok) ? item.csatolmanyok : (Array.isArray(msg.csatolmanyok) ? msg.csatolmanyok : []),
          type: "Beérkezett üzenet",
          source: "eugyintezes"
        };
      }));
    } catch (e) {
      console.warn("getAdminMessages error:", e);
      return [];
    }
  }

  /**
   * Fetches full content of an e-Ügyintézés message.
   */
  static async getMessageContent(token, messageId) {
    try {
      const data = await this.fetchAdmin(token, `kommunikacio/postaladaelemek/${messageId}`);
      if (data && typeof data === "object") {
        return data.uzenet?.szoveg || data.uzenetSzoveg || data.szoveg || "";
      }
      return "";
    } catch (e) {
      console.warn("getMessageContent error:", e);
      return "";
    }
  }

  /**
   * Fetches list of teachers available as message recipients.
   */
  static async getTeachers(token) {
    try {
      let data = null;

      if (!Array.isArray(data) || data.length === 0) {
        data = await this.fetchAdmin(token, "kreta/alkalmazottak/tanar");
      }

      if (!Array.isArray(data) || data.length === 0) {
        return [];
      }

      return data.map(t => ({
        id: t.azonosito || t.tanarAzonosito || t.id,
        name: t.nev || t.tanarNev || "Tanár",
        subjects: Array.isArray(t.tantargyak) ? t.tantargyak : []
      })).filter(t => t.id && t.name);
    } catch (e) {
      console.warn("getTeachers error:", e);
      return [];
    }
  }

  /**
   * Sends an e-Ügyintézés message to a teacher.
   */
  static async sendMessage(token, subject, text, recipientIds = []) {
    const body = {
      targy: subject,
      szoveg: text,
      cimzettLista: recipientIds.map(id => ({
        azonosito: id,
        tipus: { kod: "TANAR" }
      })),
      csatolmanyok: []
    };

    const url = `${KRETA_ADMIN}/api/v1/kommunikacio/uzenetek`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${token}`,
        "apiKey": KRETA_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json, text/plain, */*"
      },
      credentials: "include",
      body: JSON.stringify(body)
    });

    if (!res.ok) {
      const errText = await res.text().catch(() => "");
      throw new Error(`Üzenetküldési hiba (${res.status}): ${errText || "Nem sikerült elküldeni az üzenetet."}`);
    }

    return true;
  }

  /**
   * Fetches questionnaires (Adatbekérések / kérdőívek) from e-Ügyintézés.
   */
  static async getQuestionnaires(token) {
    try {
      let data = null;

      if (!Array.isArray(data) || data.length === 0) {
        data = await this.fetchAdmin(token, "kommunikacio/adatbekerok/kitolto?isLezartakIs=true");
      }
      if (!Array.isArray(data) || data.length === 0) {
        data = await this.fetchAdmin(token, "kommunikacio/adatbekerok/kitolto");
      }

      if (!Array.isArray(data) || data.length === 0) {
        return [];
      }

      return data.map(q => ({
        id: q.azonosito || q.id || Math.random(),
        title: q.megnevezes || q.nev || "Kérdőív / Adatbekérés",
        status: q.statusz?.nev || q.statusz || "Kiküldve",
        statusCode: q.statusz?.kod || "",
        sender: q.felelos?.nev || "Iskola vezetése",
        deadline: q.kitoltesiHataridoDatum ? q.kitoltesiHataridoDatum.split("T")[0] : "",
        feedback: q.visszajelzesIdopontjaDatum || (Array.isArray(q.visszajelzesLista) && q.visszajelzesLista.length > 0 ? "Kitöltve" : null),
        description: q.leiras || "Hivatalos intézményi adatbekérés."
      }));
    } catch (e) {
      console.warn("getQuestionnaires error:", e);
      const demo = this.getDemoDataset();
      return demo.questionnaires;
    }
  }

  /**
   * Safe Cache-First data retriever (10-minute TTL, Rate-limit backoff).
   */
  static async getCachedOrFetchData(session, forceRefresh = false) {
    const store = await chrome.storage.local.get([
      "pala_cached_data",
      "pala_last_fetch",
      "pala_backoff_until",
      "pala_maintenance_mode",
      "pala_simulate_maintenance"
    ]);

    // Check for simulated maintenance mode
    if (store.pala_simulate_maintenance) {
      if (store.pala_cached_data) {
        return {
          ...store.pala_cached_data,
          isMaintenance: true,
          offlineReason: "maintenance",
          cachedAt: store.pala_last_fetch || Date.now()
        };
      }
      const err = new Error("Karbantartás (503): A Kréta rendszer jelenleg szimulált karbantartás alatt áll.");
      err.isMaintenance = true;
      err.status = 503;
      throw err;
    }

    // 1. Backoff guard
    // Old data shown while waiting is marked stale, so the UI does not call it live.
    if (!forceRefresh && store.pala_backoff_until && Date.now() < store.pala_backoff_until) {
      if (store.pala_cached_data) {
        return { ...store.pala_cached_data, isStale: true, cachedAt: store.pala_last_fetch || Date.now() };
      }
    }
    if (forceRefresh) {
      await chrome.storage.local.remove(["pala_backoff_until"]);
    }

    // 2. Cache-First TTL Guard (10 mins)
    const isFresh = store.pala_last_fetch && (Date.now() - store.pala_last_fetch < CACHE_TTL_MS);
    if (!forceRefresh && isFresh && store.pala_cached_data) {
      return store.pala_cached_data;
    }

    // 3. Network Fetch
    try {
      let token = await this.ensureValidToken(session);
      let data;
      try {
        data = await this.getStudentData(session.institute, token);
      } catch (innerErr) {
        if (innerErr.status === 401 && session.refresh_token) {
          console.log("Token expired on server, refreshing...");
          await this.refreshSession(session, true);
          data = await this.getStudentData(session.institute, session.token);
        } else {
          throw innerErr;
        }
      }

      // 4. Save to local cache if valid data was fetched
      if (data && (data.student || Array.isArray(data.grades))) {
        await chrome.storage.local.set({
          pala_cached_data: data,
          pala_last_fetch: Date.now(),
          pala_maintenance_mode: false
        });

        // Update student name in session if available
        if (data.student?.Nev && session.user !== data.student.Nev) {
          session.user = data.student.Nev;
          await SecureSession.save(session);
        }
      }

      return data;
    } catch (err) {
      // Rate limited: keep showing the last good data, as the backoff guard does.
      if (err.status === 429 && store.pala_cached_data) {
        return { ...store.pala_cached_data, isStale: true, cachedAt: store.pala_last_fetch || Date.now() };
      }
      // Kréta rejected the login: show the saved data, marked as such, and ask for a new login.
      if (offlineReasonOf(err) === "expired" && store.pala_cached_data) {
        return {
          ...store.pala_cached_data,
          isMaintenance: true,
          offlineReason: "expired",
          cachedAt: store.pala_last_fetch || Date.now()
        };
      }
      if (err.isMaintenance || err.status === 502 || err.status === 503 || err.status === 504) {
        await chrome.storage.local.set({
          pala_maintenance_mode: true,
          pala_maintenance_detected_at: Date.now(),
          pala_maintenance_status: err.status || 503
        });
        if (store.pala_cached_data) {
          return {
            ...store.pala_cached_data,
            isMaintenance: true,
            offlineReason: offlineReasonOf(err),
            cachedAt: store.pala_last_fetch || Date.now()
          };
        }
      }
      throw err;
    }
  }

  /**
   * Parser for Kréta evaluation objects.
   * Differentiates standard 1..5 grades, percentages (>5%), text evaluations, "Nem írt", and summary grades.
   */
  /** Monday 00:00 and Sunday 23:59:59.999 (local time) of the week of `date`, moved by `offsetWeeks`. */
  static weekRange(date = new Date(), offsetWeeks = 0) {
    const monday = new Date(date);
    monday.setHours(0, 0, 0, 0);
    monday.setDate(monday.getDate() - ((monday.getDay() + 6) % 7) + offsetWeeks * 7);
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);
    sunday.setHours(23, 59, 59, 999);
    return { monday, sunday };
  }

  /** Copies of the lessons with their start and end moved by `days` (demo mode's other weeks). */
  static shiftLessons(lessons, days) {
    const move = (iso) => {
      if (!iso) return iso;
      const d = new Date(iso);
      d.setDate(d.getDate() + days);
      return `${localDateKey(d)}T${formatLocalTime(d)}:00`;
    };
    return (lessons || []).map(l => ({ ...l, KezdetIdopont: move(l.KezdetIdopont), VegIdopont: move(l.VegIdopont) }));
  }

  /**
   * One week's timetable (OrarendElemek) for the week navigation, sorted by
   * start time. Throws on any HTTP error so the UI can say what went wrong.
   */
  static async getTimetableWeek(instituteCode, accessToken, monday) {
    const code = String(instituteCode ?? "").trim().toLowerCase();
    if (!this.isValidInstituteCode(code)) throw new Error("Érvénytelen intézménykód.");
    const { monday: from, sunday: to } = KretaApi.weekRange(monday, 0);
    const url = `https://${code}.e-kreta.hu/ellenorzo/V3/Sajat/OrarendElemek?datumTol=${encodeURIComponent(from.toISOString())}&datumIg=${encodeURIComponent(to.toISOString())}`;
    const res = await fetch(url, {
      headers: { "Authorization": `Bearer ${accessToken}`, "apiKey": KRETA_API_KEY, "User-Agent": USER_AGENT, "Accept": "application/json" },
      signal: AbortSignal.timeout(8000)
    });
    if (res.status >= 500) throw outageError(res.status);
    if (!res.ok) {
      const err = new Error(`Az órarend nem tölthető be (${res.status}).`);
      err.status = res.status;
      throw err;
    }
    const data = await res.json();
    return (Array.isArray(data) ? data : []).sort((a, b) => new Date(a.KezdetIdopont) - new Date(b.KezdetIdopont));
  }

  /** Pala's public links for the settings footer; an empty URL hides its entry. Mirrors lib/links.dart. */
  static palaLinks() {
    return [
      { label: "Weboldal", url: "https://pala-app.hu" },
      { label: "GitHub", url: "https://github.com/CsPS0/pala" },
      { label: "Instagram", url: "" },
    ].filter(l => l.url);
  }

  /** The student's class among OsztalyCsoportok (Tipus "Osztaly"), else the first group, else null. */
  static mainClassGroup(groups) {
    if (!Array.isArray(groups) || groups.length === 0) return null;
    return groups.find(g => String(g?.Tipus || "").toLowerCase() === "osztaly") || groups[0];
  }

  /**
   * Profile fields from Kréta's TanuloAdatlap, by the names Kréta really uses.
   * Anything Kréta does not send (OM id, TAJ, tax id, ID cards) is "-" here and
   * can only come from the user's own manual entries. className comes from
   * OsztalyCsoportok, not from TanuloAdatlap.
   */
  static studentProfile(student, className = null) {
    const s = student || {};
    const bank = s.Bankszamla || {};
    const text = (v) => (v === undefined || v === null || v === "" ? "-" : String(v));
    const birthDate = s.SzuletesiDatum
      ? (String(s.SzuletesiDatum).includes("T") ? new Date(s.SzuletesiDatum).toLocaleDateString("hu-HU") : s.SzuletesiDatum)
      : null;
    const address = Array.isArray(s.Cimek) ? s.Cimek.filter(Boolean).join("; ") : s.Cim;
    return {
      name: text(s.Nev),
      birthName: text(s.SzuletesiNev || s.Nev),
      birthPlace: text(s.SzuletesiHely),
      birthDate: text(birthDate),
      motherName: text(s.AnyjaNeve),
      address: text(address),
      instituteName: text(s.IntezmenyNev || s.Intezmeny?.TeljesNev),
      instituteCode: text(s.IntezmenyAzonosito),
      className: text(className),
      email: text(s.EmailCim),
      phone: text(s.Telefonszam),
      bankAccount: text(bank.BankszamlaSzam),
      bankOwner: text(bank.BankszamlaTulajdonosNeve),
      // Kréta sends the owner type only as a numeric id with no published names.
      bankOwnerType: "-",
      omId: "-",
    };
  }

  /** A copy of the list with the newest message first; messages without a date go last. Mirrors lib/models/message.dart. */
  static sortMessagesNewestFirst(list) {
    const time = (m) => {
      const t = m?.date ? new Date(m.date).getTime() : NaN;
      return Number.isFinite(t) ? t : null;
    };
    return [...(list || [])].sort((a, b) => {
      const ta = time(a), tb = time(b);
      if (ta === null && tb === null) return 0;
      if (ta === null) return 1;
      if (tb === null) return -1;
      return tb - ta;
    });
  }

  /** Pala Wrapped opens from 14 June to 30 September. Mirrors lib/rules/wrapped_season.dart. */
  static isWrappedSeason(date = new Date()) {
    const m = date.getMonth() + 1, d = date.getDate();
    return (m === 6 && d >= 14) || m === 7 || m === 8 || m === 9;
  }

  /**
   * The class average from one OsztalyAtlagok item. Kréta sends it as
   * OsztalyCsoportAtlag; older names are kept for cached and demo data.
   * Null when missing or not above 0. Mirrors lib/models/class_average.dart.
   */
  static classAverageOf(item) {
    const raw = item?.OsztalyCsoportAtlag ?? item?.OsztalyAtlag ?? item?.Atlag ?? item?.Ertek;
    if (raw === null || raw === undefined) return null;
    const value = typeof raw === "number" ? raw : parseFloat(String(raw).replace(",", "."));
    return Number.isFinite(value) && value > 0 ? value : null;
  }

  /** Maps Kréta's ErtekFajta to "grade" | "percent" | "text", or null when it is missing. */
  static valueKindFromKreta(ertekFajta) {
    const name = ertekFajta?.Nev;
    if (!name) return null;
    if (name === "Osztalyzat") return "grade";
    if (name === "Szazalekos") return "percent";
    return "text";
  }

  static parseGrade(g) {
    if (!g) return { displayValue: "-", badgeClass: "grade-unknown", numericGrade: null, weight: 1, isSummary: false };

    const rawNum = typeof g.SzamErtek === "number" ? g.SzamErtek : parseInt(g.SzamErtek, 10);
    const text = (g.SzovegesErtek || "").trim();
    const typeStr = (g.Tipus?.Leiras || g.Tipus?.Nev || "").toLowerCase();
    // Kréta's value type (ErtekFajta.Nev): Osztalyzat, Szazalekos or Szoveges.
    // A percentage can carry a 1-5 SzamErtek ("4%"), so the number alone does
    // not make a grade. Without ErtekFajta the old heuristics below decide.
    const kretaKind = KretaApi.valueKindFromKreta(g.ErtekFajta);

    // Check if summary grade (félévi, év végi, osztályozó)
    const isSummary = typeStr.includes("év végi") ||
                      typeStr.includes("félévi") ||
                      typeStr.includes("negyedévi") ||
                      typeStr.includes("háromnegyedévi") ||
                      typeStr.includes("vegi") ||
                      typeStr.includes("felevi") ||
                      typeStr.includes("negyedevi") ||
                      typeStr.includes("osztályozó") ||
                      typeStr.includes("osztalyozo");

    // Check if "Nem írt" or absent
    const isNemIrt = text.toLowerCase() === "nem írt" || 
                     text.toLowerCase() === "nem jelent meg" || 
                     text.toLowerCase() === "nem irt";

    // Check if percentage evaluation
    const isPercentage = kretaKind ? kretaKind === "percent" :
                         ((!isNaN(rawNum) && rawNum > 5) ||
                          text.endsWith("%") ||
                          typeStr.includes("százalék") ||
                          typeStr.includes("szazalek"));
    const isText = kretaKind === "text";

    let displayValue = "";
    let badgeClass = "";
    let numericGrade = null;

    if (isNemIrt) {
      displayValue = "Nem írt";
      badgeClass = "grade-nem-irt";
    } else if (isPercentage) {
      const pct = (!isNaN(rawNum) && rawNum > 5) ? rawNum : (parseInt(text, 10) || rawNum || 0);
      displayValue = `${pct}%`;
      badgeClass = "grade-percent";
    } else if (isText) {
      displayValue = text || "-";
      badgeClass = text ? "grade-text" : "grade-unknown";
    } else if (!isNaN(rawNum) && rawNum >= 1 && rawNum <= 5) {
      numericGrade = rawNum;
      displayValue = `${rawNum}`;
      badgeClass = `grade-${rawNum}`;
    } else {
      // Check if text contains number in parentheses, e.g. "Jeles (5)"
      const match = text.match(/\(([1-5])\)/);
      if (match) {
        numericGrade = parseInt(match[1], 10);
        displayValue = `${numericGrade}`;
        badgeClass = `grade-${numericGrade}`;
      } else if (text) {
        displayValue = text;
        badgeClass = "grade-text";
      } else {
        displayValue = "-";
        badgeClass = "grade-unknown";
      }
    }

    // Only a missing weight means 100%; an explicit 0% grade does not count
    // toward averages (docs/DEV.md, "Számítási szabályok").
    const weightRaw = g.SulySzazalekErteke ?? g.SulySzazalek ?? 100;
    const weightParsed = typeof weightRaw === "number" ? weightRaw : parseFloat(weightRaw);
    // Always a number: UIs interpolate it into markup and attributes.
    const weightPercent = Number.isFinite(weightParsed) ? weightParsed : 100;
    const weight = weightPercent / 100;

    return {
      raw: g,
      numericGrade,
      displayValue,
      badgeClass,
      isSummary,
      isPercentage,
      valueKind: numericGrade !== null ? "grade" : (isPercentage ? "percent" : "text"),
      isNemIrt,
      weight,
      weightPercent
    };
  }

  // Calculation rules shared by every Pala client. The Dart side is
  // lib/rules/; both are tested against fixtures/rules/*.json, and the rules
  // are written down in docs/DEV.md ("Számítási szabályok").

  /** True when a parsed grade counts toward averages: a 1-5 grade, not a summary grade, weight above 0. */
  static countsForAverage(p) {
    return p.valueKind === "grade" && p.numericGrade !== null && p.numericGrade >= 1 && p.numericGrade <= 5 && !p.isSummary && p.weight > 0;
  }

  /** Weighted average per subject name, from raw Kréta grades. Subjects without a counted grade are left out. */
  static subjectAverages(grades, subjectOf = g => g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy") {
    const totals = {};
    for (const g of grades || []) {
      const p = this.parseGrade(g);
      if (!this.countsForAverage(p)) continue;
      const sub = subjectOf(g);
      const t = totals[sub] || (totals[sub] = { sum: 0, weight: 0 });
      t.sum += p.numericGrade * p.weight;
      t.weight += p.weight;
    }
    const averages = {};
    for (const [sub, t] of Object.entries(totals)) averages[sub] = t.sum / t.weight;
    return averages;
  }

  /** Overall average: the mean of the subject averages, as on a certificate. Null without counted grades. */
  static overallAverage(grades) {
    const values = Object.values(this.subjectAverages(grades));
    return values.length ? values.reduce((a, b) => a + b, 0) / values.length : null;
  }

  /** True for a lateness entry: it has late minutes, or its type says "késés". */
  static isLateness(a) {
    const type = this.normalizeHu(a?.Tipus?.Nev || a?.Tipus?.Leiras || a?.Tipus || "");
    return Number(a?.KesesPercben || 0) > 0 || type.includes("keses");
  }

  /** "excused", "pending" or "unexcused" from IgazolasAllapota. Anything unknown is still open: "pending". */
  static absenceStatus(a) {
    const status = this.normalizeHu(a?.IgazolasAllapota || "");
    if (status.includes("igazolatlan")) return "unexcused";
    if (status.includes("igazolt")) return "excused";
    return "pending";
  }

  /**
   * One absence summary for every view. Each absence entry is one missed
   * lesson; lateness is counted apart and does not go toward the 250 hours.
   */
  static summarizeAbsences(absences) {
    const s = { missed: 0, excused: 0, pending: 0, unexcused: 0, lateCount: 0, lateMinutes: 0 };
    for (const a of absences || []) {
      if (this.isLateness(a)) {
        s.lateCount++;
        s.lateMinutes += Number(a.KesesPercben || 0);
        continue;
      }
      s.missed++;
      s[this.absenceStatus(a)]++;
    }
    return s;
  }

  // Exports. One CSV and one iCalendar writer for the whole extension, in the
  // same formats as the Dart side (lib/utils/csv.dart, lib/utils/ics_exporter.dart).

  /** CSV: UTF-8 BOM (Excel accents), ';' (Hungarian Excel), every value quoted, CRLF. */
  static toCsv(header, rows) {
    const field = v => `"${String(v ?? "").replace(/"/g, '""')}"`;
    const bom = String.fromCharCode(0xFEFF);
    return bom + [header.join(";"), ...rows.map(r => r.map(field).join(";"))].join("\r\n") + "\r\n";
  }

  /** Grades as CSV, with the local date. */
  static gradesCsv(grades, subjectOf = g => g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb") {
    return this.toCsv(
      ["Tantárgy", "Típus", "Érték", "Súly (%)", "Dátum", "Téma"],
      (grades || []).map(g => {
        const p = this.parseGrade(g);
        const date = g.KeszitesDatuma || g.RogzitesDatuma || g.Datum;
        return [subjectOf(g), g.Tipus?.Leiras || g.Tipus?.Nev || "", p.displayValue, p.weightPercent, date ? localDateKey(date) : "", g.Tema || ""];
      })
    );
  }

  /** Absences as CSV, with the local date. */
  static absencesCsv(absences) {
    return this.toCsv(
      ["Tantárgy", "Dátum", "Típus", "Állapot", "Késés (perc)"],
      (absences || []).map(a => {
        const date = a.Datum || a.OraKezdete;
        return [a.Tantargy?.Nev || a.Tantargy || "", date ? localDateKey(date) : "", a.Tipus?.Leiras || a.Tipus?.Nev || a.Tipus || "", a.IgazolasAllapota || "", Number(a.KesesPercben || 0)];
      })
    );
  }

  /**
   * Timetable lessons as iCalendar (RFC 5545): escaped text, CRLF line ends,
   * lines folded at 75 octets, a stable UID from the lesson's Uid, DTSTAMP,
   * and STATUS:CANCELLED for cancelled lessons.
   */
  static timetableToIcs(lessons, subjectOf = l => l.Tantargy?.Nev || l.Tantargy || l.Nev || "Tanóra") {
    const text = v => String(v ?? "").replace(/\\/g, "\\\\").replace(/;/g, "\\;").replace(/,/g, "\\,").replace(/\r?\n/g, "\\n");
    const utc = v => new Date(v).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
    const encoder = new TextEncoder();
    const fold = line => {
      let out = "";
      let bytes = 0;
      for (const ch of line) {
        const size = encoder.encode(ch).length;
        if (bytes + size > 75) {
          out += "\r\n ";
          bytes = 1;
        }
        out += ch;
        bytes += size;
      }
      return out;
    };
    const stamp = utc(new Date());
    const lines = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Pala//Pala Extension//HU", "CALSCALE:GREGORIAN", "METHOD:PUBLISH", "X-WR-CALNAME:Pala Órarend"];
    for (const l of lessons || []) {
      if (!l.KezdetIdopont || !l.VegIdopont) continue;
      const cancelled = String(l.Allapot?.Nev || l.Allapot || "").toLowerCase().includes("elmarad");
      lines.push("BEGIN:VEVENT");
      lines.push(`UID:lesson-${l.Uid || l.Id || utc(l.KezdetIdopont)}@pala`);
      lines.push(`DTSTAMP:${stamp}`);
      lines.push(`DTSTART:${utc(l.KezdetIdopont)}`);
      lines.push(`DTEND:${utc(l.VegIdopont)}`);
      lines.push(`SUMMARY:${text(subjectOf(l))}`);
      if (l.TeremNeve) lines.push(`LOCATION:${text(l.TeremNeve)}`);
      if (l.Tema) lines.push(`DESCRIPTION:${text(l.Tema)}`);
      lines.push(`STATUS:${cancelled ? "CANCELLED" : "CONFIRMED"}`);
      lines.push("END:VEVENT");
    }
    lines.push("END:VCALENDAR");
    return lines.map(fold).join("\r\n") + "\r\n";
  }

  /** Saves text as a file through a temporary download link (UI pages only). */
  static downloadText(filename, content, mimeType) {
    const url = URL.createObjectURL(new Blob([content], { type: mimeType }));
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  }

  static generateDemoTimetable(overrideAWeek = null) {
    return generateDemoTimetable(overrideAWeek);
  }

  static demoWeekType(overrideAWeek = null) {
    return demoWeekType(overrideAWeek);
  }

  /**
   * Picks the week covering `day` from a Hetirendek/Orarendi response and
   * returns the school's name for it ("A hét", "C hét", ...). "Minden héten"
   * is Kréta's built-in default for no rotation, so it (and any unexpected
   * shape) gives null and the UI hides the badge. Mirrors KretaClient.weekTypeLabel.
   */
  static weekTypeLabel(weeks, day) {
    if (!Array.isArray(weeks)) return null;
    const target = localDateKey(day);
    for (const week of weeks) {
      if (!week?.KezdoNapDatuma || !week?.VegNapDatuma) continue;
      if (target < localDateKey(week.KezdoNapDatuma) || target > localDateKey(week.VegNapDatuma)) continue;
      const label = String(week.Tipus?.Leiras || week.Tipus?.Nev || "").trim();
      if (!label || label.toLowerCase().startsWith("minden")) return null;
      return label;
    }
    return null;
  }

  static getDemoDataset(overrideAWeek = null) {
    return {
      student: DEMO_STUDENT,
      className: "11.I",
      grades: DEMO_GRADES,
      timetable: generateDemoTimetable(overrideAWeek),
      weekType: demoWeekType(overrideAWeek),
      homework: DEMO_HOMEWORK,
      exams: DEMO_EXAMS,
      absences: DEMO_ABSENCES,
      groupAverages: DEMO_GROUP_AVERAGES,
      messages: [
        {
          id: "m-1",
          type: "Beérkezett üzenet",
          sender: "Dr. Számoló Szilárd (tanár)",
          title: "Érettségi büfé - köszönet",
          subject: "Érettségi büfé - köszönet",
          content: "Kedves Diákok! Nagyon szépen köszönöm a segítségeteket és a lelkiismeretes munkátokat az érettségi büfé lebonyolításában!",
          date: "2026-06-22T12:34:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-2",
          type: "Beérkezett üzenet",
          sender: "Dr. Számoló Szilárd (tanár)",
          title: "Érettségi törzslap kivonatot leadott tanulók",
          subject: "Érettségi törzslap kivonatot leadott tanulók",
          content: "Kérem azokat a tanulókat, akik még nem adták le az érettségi törzslap kivonatukat, hogy sürgősen pótolják a titkárságon!",
          date: "2026-06-22T12:15:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-3",
          type: "Beérkezett üzenet",
          sender: "Dr. Számoló Szilárd (tanár)",
          title: "50 óra közösségi szolgálat - szakmai érettségi",
          subject: "50 óra közösségi szolgálat - szakmai érettségi",
          content: "Fontos tájékoztatás: az érettségi bizonyítvány kiadásának feltétele az 50 óra igazolt közösségi szolgálat teljesítése.",
          date: "2026-06-14T17:53:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-4",
          type: "Beérkezett üzenet",
          sender: "Dr. Számoló Szilárd (tanár)",
          title: "ÉRETTSÉGI BÜFÉ",
          subject: "ÉRETTSÉGI BÜFÉ",
          content: "Beosztás és feladatok megbeszélése a szóbeli érettségi vizsgák büféjéhez.",
          date: "2026-06-05T12:59:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-5",
          type: "Beérkezett üzenet",
          sender: "Smith John (tanár)",
          title: "Jövő évi idegen nyelvi órák",
          subject: "Jövő évi idegen nyelvi órák",
          content: "Tájékoztató a jövő évi idegen nyelvi csoportbontásokról és tankönyvekről.",
          date: "2026-06-01T11:42:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-6",
          type: "Beérkezett üzenet",
          sender: "Dr. Igazgató István (igazgató)",
          title: "12. ÉVFOLYAMOSOK IDEGENNYELVI ELŐREHALADÁSÁVAL KAPCSOLATOS 2026/2027-ES TANÉVRE VONATKOZÓ NYILATKOZAT",
          subject: "12. ÉVFOLYAMOSOK IDEGENNYELVI ELŐREHALADÁSÁVAL KAPCSOLATOS 2026/2027-ES TANÉVRE VONATKOZÓ NYILATKOZAT",
          content: "Kérjük a nyilatkozat kitöltését és visszaküldését a megadott határidőig az e-Ügyintézés felületén.",
          date: "2026-06-01T08:40:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-7",
          type: "Beérkezett üzenet",
          sender: "KRÉTA (Rendszer)",
          title: "Pályakövetési kérdőív 2026",
          subject: "Pályakövetési kérdőív 2026",
          content: "Tisztelt Tanuló! Megnyílt az intézményi pályakövetési felmérés a Kréta rendszerben. Kérjük töltse ki a kérdőívet.",
          date: "2026-04-20T14:59:00",
          isRead: true,
          source: "eugyintezes"
        },
        {
          id: "m-8",
          type: "Dicséret",
          sender: "Kovács László (Matematika)",
          title: "Szaktárgyi dicséret kiváló versenyeredményért",
          content: "A Zrínyi Ilona Matematikaverseny vármegyei fordulóján nyújtott kiemelkedő felkészültségéért és az elért dobogós helyezéséért szaktárgyi dicséretben részesül.",
          date: "2026-03-25T10:30:00",
          isRead: true,
          source: "ellenorzo"
        },
        {
          id: "m-9",
          type: "Osztályfőnöki megrovás",
          sender: "Nagy Erika (Osztályfőnök)",
          title: "Osztályfőnöki megrovás",
          content: "Ismétlődő igazolatlan hiányzásai és késései (Történelem, Kémia, Angol nyelv) miatt osztályfőnöki megrovásban részesül. Kérjük a mulasztások haladéktalan igazolását, ellenkező esetben a fegyelmi eljárás következő fokozata alkalmazandó.",
          date: "2026-06-10T09:15:00",
          isRead: false,
          source: "ellenorzo"
        },
        {
          id: "m-10",
          type: "Igazgatói megrovás",
          sender: "Dr. Igazgató István (igazgató)",
          title: "Igazgatói megrovás",
          content: "Az osztályfőnöki jelzés és a folytatódó igazolatlan mulasztások alapján az intézmény vezetése igazgatói megrovás fegyelmező intézkedést alkalmaz. Kérjük a Házirendben foglaltak betartását és a hiányzó igazolások pótlását.",
          date: "2026-06-12T11:00:00",
          isRead: false,
          source: "ellenorzo"
        }
      ],
      teachers: [
        { id: 101, name: "Dr. Számoló Szilárd", subjects: ["Matematika", "Osztályfőnök"] },
        { id: 102, name: "Dr. Igazgató István", subjects: ["Intézményvezető"] },
        { id: 103, name: "Smith John", subjects: ["Idegen nyelv"] },
        { id: 104, name: "Arany Jánosné", subjects: ["Magyar nyelv és irodalom"] },
        { id: 105, name: "Teleki Pál", subjects: ["Földrajz"] }
      ],
      questionnaires: [
        {
          id: "q-1",
          title: "Jelentkezési lap - közösségi szolgálat - tanulói 2024/2025",
          status: "Kiküldve",
          sender: "Dr. Igazgató István",
          deadline: "2025. 06. 30.",
          feedback: "2025. 01. 29. 13:46"
        },
        {
          id: "q-2",
          title: "Pályakövetési felmérés 2025 - BC kérdőív",
          status: "Kiküldve",
          sender: "Pályakövetési Felmérés",
          deadline: "2025. 06. 30.",
          feedback: null
        },
        {
          id: "q-3",
          title: "Pénzügyi tudatosság",
          status: "Kiküldve",
          sender: "Pályakövetési Felmérés",
          deadline: "2025. 06. 30.",
          feedback: null
        },
        {
          id: "q-4",
          title: "Jelentkezési lap - közösségi szolgálat - tanulói 2025/2026",
          status: "Kiküldve",
          sender: "Dr. Igazgató István",
          deadline: "2026. 06. 15.",
          feedback: "2025. 11. 28. 10:31"
        },
        {
          id: "q-5",
          title: "Pályakövetési felmérés 2026 - BC kérdőív",
          status: "Kiküldve",
          sender: "Pályakövetési Felmérés",
          deadline: "2026. 06. 30.",
          feedback: null
        }
      ],
      isDemo: true,
      lastUpdated: new Date().toISOString()
    };
  }
}

// Export for extension contexts
if (typeof window !== "undefined") {
  window.KretaApi = KretaApi;
}

