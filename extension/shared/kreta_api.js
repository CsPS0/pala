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

const DEMO_STUDENT = {
  Nev: "Teszt Elek",
  SzuletesiNev: "Teszt Elek",
  SzuletesiDatum: "2008-03-15",
  SzuletesiHely: "Budapest",
  AnyjaNeve: "Minta Mária",
  OktatasiAzonosito: "72458912345",
  AdoazonositoJel: "8514643002",
  TajSzam: "126831612",
  IgazolvanyTipus: "Személyi Igazolvány",
  IgazolvanySzam: "123456AB",
  DiakigazolvanySzam: "00789456123",
  DiakigazolvanyKelte: "2022. 09. 01.",
  Bankszamlaszam: "11773425-06294344-00000000",
  SzamlavezetoBank: "OTP Bank Nyrt.",
  BankszamlaTulajdonosNeve: "Teszt Elek",
  BankszamlaTulajdonosa: "saját",
  Osztaly: "11.I",
  Email: "elek.teszt@pala.edu.hu",
  Telefonszam: "+36 30 123 4567",
  Cim: "1111 Budapest, Példa utca 12. II/4",
  Gondviselok: [
    { Nev: "Teszt Gábor", Email: "szulo@teszt.hu", Telefonszam: "+36 20 987 6543" },
    { Nev: "Minta Mária", Email: "anya@teszt.hu", Telefonszam: "+36 30 555 4444" }
  ],
  Intezmeny: { Nev: "Budapesti Műszaki SZC Neumann János Informatikai Technikum", Kod: "bmszc-neumann" }
};

const DEMO_GRADES = [
  { Id: 101, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "Függvények & Analízis", RogzitesDatuma: new Date().toISOString(), Tipus: { Leiras: "Írásbeli témazáró" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1011, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 100, Tema: "Gyakorló", RogzitesDatuma: new Date(Date.now() - 50000000).toISOString(), Tipus: { Leiras: "Órai munka" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1012, Tantargy: { Nev: "Matematika" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 100, Tema: "Számonkérés", RogzitesDatuma: new Date(Date.now() - 100000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 102, Tantargy: { Nev: "Magyar nyelv és irodalom" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 100, Tema: "Nyugat költészete", RogzitesDatuma: new Date(Date.now() - 86400000).toISOString(), Tipus: { Leiras: "Szóbeli felelet" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1021, Tantargy: { Nev: "Magyar nyelv és irodalom" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 100, Tema: "Memoriter", RogzitesDatuma: new Date(Date.now() - 90000000).toISOString(), Tipus: { Leiras: "Felelet" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 103, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "A reformkor nagyjai", RogzitesDatuma: new Date(Date.now() - 172800000).toISOString(), Tipus: { Leiras: "Órai munka" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1031, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 100, Tema: "Évszámok", RogzitesDatuma: new Date(Date.now() - 180000000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1032, Tantargy: { Nev: "Történelem" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 200, Tema: "Témazáró", RogzitesDatuma: new Date(Date.now() - 190000000).toISOString(), Tipus: { Leiras: "Dolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 104, Tantargy: { Nev: "Angol nyelv" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 100, Tema: "Conditionals & Essay", RogzitesDatuma: new Date(Date.now() - 259200000).toISOString(), Tipus: { Leiras: "Írásbeli dolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 105, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Közepes (3)", SzamErtek: 3, SulySzazalek: 100, Tema: "Elektrosztatika számítások", RogzitesDatuma: new Date(Date.now() - 345600000).toISOString(), Tipus: { Leiras: "Röpdolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1051, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Elégséges (2)", SzamErtek: 2, SulySzazalek: 200, Tema: "Mechanika TZ", RogzitesDatuma: new Date(Date.now() - 360000000).toISOString(), Tipus: { Leiras: "Témazáró dolgozat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 1052, Tantargy: { Nev: "Fizika" }, SzovegesErtek: "Jó (4)", SzamErtek: 4, SulySzazalek: 100, Tema: "Labor", RogzitesDatuma: new Date(Date.now() - 370000000).toISOString(), Tipus: { Leiras: "Gyakorlati" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } },
  { Id: 106, Tantargy: { Nev: "Informatika / Digitális kultúra" }, SzovegesErtek: "Jeles (5)", SzamErtek: 5, SulySzazalek: 200, Tema: "Python algoritmusok & Adatbázisok", RogzitesDatuma: new Date(Date.now() - 432000000).toISOString(), Tipus: { Leiras: "Gyakorlati feladat" }, ErtekelesFajtaja: { Leiras: "Érdemjegy" } }
];

function generateDemoTimetable() {
  const today = new Date();
  const subjects = [
    { name: "Matematika", room: "204", teacher: "Kovács Péter" },
    { name: "Magyar irodalom", room: "102", teacher: "Nagy Erika" },
    { name: "Történelem", room: "305", teacher: "Horváth László" },
    { name: "Angol nyelv", room: "201", teacher: "Kiss Andrea" },
    { name: "Fizika", room: "Fizika Ea.", teacher: "Szabó Zoltán" },
    { name: "Testnevelés", room: "Tornaterem", teacher: "Varga Dániel" }
  ];

  const timetable = [];
  for (let i = 0; i < subjects.length; i++) {
    const startHour = 8 + i;
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate(), startHour, 0);
    const end = new Date(today.getFullYear(), today.getMonth(), today.getDate(), startHour, 45);

    let state = { Nev: "Megtartott" };
    let subTeacher = null;
    let theme = `Tananyag ${i + 1}. fejezet`;

    if (i === 1) {
      state = { Nev: "Helyettesített" };
      subTeacher = "Kiss Andrea";
    }
    if (i === 4) {
      state = { Nev: "Elmaradt" };
      theme = "Tanár betegsége miatt elmarad";
    }

    timetable.push({
      Id: 1000 + i,
      Oraszam: i + 1,
      KezdetIdopont: start.toISOString(),
      VegIdopont: end.toISOString(),
      Tantargy: { Nev: subjects[i].name },
      Terem: subjects[i].room,
      Tanar: subjects[i].teacher,
      HelyettesitoTanarNeve: subTeacher,
      Tema: theme,
      Allapot: state
    });
  }
  
  // Add some for tomorrow to show matrix
  for (let i = 0; i < 3; i++) {
    const startHour = 8 + i;
    const start = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1, startHour, 0);
    const end = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 1, startHour, 45);
    
    timetable.push({
      Id: 2000 + i,
      Oraszam: i + 1,
      KezdetIdopont: start.toISOString(),
      VegIdopont: end.toISOString(),
      Tantargy: { Nev: subjects[i].name },
      Terem: subjects[i].room,
      Tanar: subjects[i].teacher,
      Tema: `Gyakorlás`,
      Allapot: { Nev: "Megtartott" }
    });
  }
  
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
  { Id: 405, Datum: new Date(Date.now() - 300000000).toISOString(), Tantargy: "Matematika", IgazolasAllapota: "Igazolatlan", Tipus: "Késés", KesesPercben: 10 }
];

const DEMO_GROUP_AVERAGES = [
  { Tantargy: { Nev: "Matematika" }, OsztalyAtlag: 3.82 },
  { Tantargy: { Nev: "Magyar nyelv és irodalom" }, OsztalyAtlag: 4.15 },
  { Tantargy: { Nev: "Történelem" }, OsztalyAtlag: 3.95 },
  { Tantargy: { Nev: "Angol nyelv" }, OsztalyAtlag: 4.30 },
  { Tantargy: { Nev: "Informatika / Digitális kultúra" }, OsztalyAtlag: 4.60 },
  { Tantargy: { Nev: "Fizika" }, OsztalyAtlag: 3.45 }
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

/**
 * Encrypts the OAuth session (access/refresh tokens) at rest using a
 * non-extractable AES-GCM key kept in IndexedDB. The key material itself
 * never leaves the crypto subsystem as plain bytes, so even a raw dump of
 * the extension's on-disk storage cannot recover a usable token without
 * also compromising the browser's key-store internals.
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

  /** Encrypts and writes the session to chrome.storage.local under pala_session. */
  static async save(session) {
    if (session === null || session === undefined) {
      await chrome.storage.local.set({ pala_session: null });
      return;
    }
    const encrypted = await this.encrypt(session);
    await chrome.storage.local.set({ pala_session: encrypted });
  }

  /** Reads and decrypts pala_session from chrome.storage.local. */
  static async load() {
    const store = await chrome.storage.local.get("pala_session");
    return this.decrypt(store.pala_session);
  }
}

class KretaApi {
  /**
   * Searches schools by name or code using Kréta's official institute selector.
   */
  static async searchSchools(query) {
    if (!query || query.trim().length < 2) return [];
    try {
      const url = `https://intezmenykereso.e-kreta.hu/instituteSelector/${encodeURIComponent(query.trim())}?showOnlyLive=true`;
      const res = await fetch(url);
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
      const code = instituteCode.trim().toLowerCase();
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
      body: body.toString()
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

    const response = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "User-Agent": USER_AGENT
      },
      body: body.toString()
    });

    if (!response.ok) {
      throw new Error("A munkamenet lejárt. Kérlek jelentkezz be újra.");
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

    // Refresh if within 2 minutes of expiry
    if (session.expires_at && Date.now() > session.expires_at - 120000 && session.refresh_token) {
      try {
        const refreshed = await this.refreshAccessToken(session.refresh_token);
        session.token = refreshed.access_token;
        session.refresh_token = refreshed.refresh_token;
        session.expires_at = refreshed.expires_at;
        await SecureSession.save(session);
      } catch (e) {
        console.warn("Token frissítési hiba:", e);
      }
    }
    return session.token;
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
    const base = `https://${instituteCode.trim().toLowerCase()}.e-kreta.hu/ellenorzo/V3/Sajat`;
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
          return null;
        }
        if (res.status === 401) {
          const err = new Error("401 Unauthorized - A munkamenet lejárt.");
          err.status = 401;
          throw err;
        }
        if (res.status >= 502 && res.status <= 504) {
          const err = new Error(`Kréta karbantartás (${res.status})`);
          err.status = res.status;
          err.isMaintenance = true;
          throw err;
        }
        if (!res.ok) {
          return null;
        }
        return await res.json();
      } catch (e) {
        if (e.status === 401 || e.isMaintenance) throw e;
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

    // 30 days back for homework
    const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000);
    const hwDatumTol = thirtyDaysAgo.toISOString().split("T")[0];

    // Class/group averages need the group's task UID first, then the averages
    // endpoint itself — two sequential calls, run alongside everything else.
    const groupAveragesPromise = (async () => {
      try {
        const groups = await fetchEndpoint("OsztalyCsoportok");
        if (!Array.isArray(groups) || groups.length === 0) return [];
        const group = groups.find(g => g.Tipus === "Osztaly" || g.Tipus === "OSZTALY") || groups[0];
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
    const [student, grades, timetable, homework, exams, absences, notes, circulars, groupAverages] = await Promise.all([
      fetchEndpoint("TanuloAdatlap"),
      fetchEndpoint("Ertekelesek"),
      fetchEndpoint(`OrarendElemek?datumTol=${encodeURIComponent(datumTol)}&datumIg=${encodeURIComponent(datumIg)}`),
      fetchEndpoint(`HaziFeladatok?datumTol=${encodeURIComponent(hwDatumTol)}`),
      fetchEndpoint("BejelentettSzamonkeresek"),
      fetchEndpoint("Mulasztasok"),
      fetchEndpoint("Feljegyzesek"),
      fetchEndpoint("FaliujsagElemek"),
      groupAveragesPromise
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
    parsedMessages.sort((a, b) => new Date(b.date || 0).getTime() - new Date(a.date || 0).getTime());

    return {
      student: student || null,
      grades: sortedGrades,
      timetable: sortedTimetable,
      homework: Array.isArray(homework) ? homework : [],
      exams: Array.isArray(exams) ? exams : [],
      absences: Array.isArray(absences) ? absences : [],
      groupAverages: Array.isArray(groupAverages) ? groupAverages : [],
      messages: parsedMessages,
      // teachers and questionnaires come from e-Ugyintezas (fetched separately).
      teachers: [],
      questionnaires: [],
      lastUpdated: new Date().toISOString()
    };
  }

  /**
   * Attempts to fetch data directly from an active e-Ügyintézés tab if the user has it open.
   * This bypasses all cross-origin restrictions, CORS, and token expiry since it executes
   * inside the browser's already authenticated same-origin page context.
   */
  static async fetchFromActiveWebTab() {
    if (typeof chrome === "undefined" || !chrome.tabs || !chrome.scripting) return null;
    try {
      const tabs = await chrome.tabs.query({ url: "*://eugyintezes.e-kreta.hu/*" });
      if (!tabs || tabs.length === 0) return null;

      // Find an active/ready tab
      const validTab = tabs.find(t => t.id && t.url && !t.url.includes("login") && !t.url.includes("kijelentkezes")) || tabs[0];
      if (!validTab || !validTab.id) return null;

      const results = await chrome.scripting.executeScript({
        target: { tabId: validTab.id },
        func: async () => {
          try {
            const [beerkezett, sajat, adatbekerok, tanarok] = await Promise.all([
              fetch("/api/v1/kommunikacio/postaladaelemek/beerkezett", { credentials: "include" })
                .then(r => r.ok ? r.json() : null)
                .catch(() => null),
              fetch("/api/v1/kommunikacio/postaladaelemek/sajat", { credentials: "include" })
                .then(r => r.ok ? r.json() : null)
                .catch(() => null),
              fetch("/api/v1/kommunikacio/adatbekerok/kitolto?isLezartakIs=true", { credentials: "include" })
                .then(r => r.ok ? r.json() : null)
                .catch(() => null),
              fetch("/api/v1/kommunikacio/tanarok", { credentials: "include" })
                .then(r => r.ok ? r.json() : null)
                .catch(() => null)
            ]);

            const msgs = Array.isArray(beerkezett) && beerkezett.length > 0 ? beerkezett : (Array.isArray(sajat) ? sajat : null);
            return {
              messages: msgs,
              questionnaires: Array.isArray(adatbekerok) ? adatbekerok : null,
              teachers: Array.isArray(tanarok) ? tanarok : null
            };
          } catch (err) {
            return null;
          }
        }
      });

      if (results && results[0] && results[0].result) {
        return results[0].result;
      }
      return null;
    } catch (e) {
      console.warn("fetchFromActiveWebTab nem sikerült:", e);
      return null;
    }
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

      return data.map(item => {
        const msg = item.uzenet || {};
        const sender = item.uzenetFeladoNev || msg.feladoNev || item.feladoNev || "Ismeretlen feladó";
        const senderTitle = item.uzenetFeladoTitulus || msg.feladoTitulus || "";
        const fullSender = senderTitle ? `${sender} (${senderTitle})` : sender;
        const subject = item.uzenetTargy || msg.targy || item.targy || "Nincs tárgy";
        const date = item.uzenetKuldesDatum || msg.kuldesDatum || item.kuldesDatum || new Date().toISOString();
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
      });
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
      const webData = await this.fetchFromActiveWebTab();
      let data = webData?.teachers;

      if (!Array.isArray(data) || data.length === 0) {
        data = await this.fetchAdmin(token, "kommunikacio/tanarok");
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
      const webData = await this.fetchFromActiveWebTab();
      let data = webData?.questionnaires;

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
          cachedAt: store.pala_last_fetch || Date.now()
        };
      }
      const err = new Error("Karbantartás (503): A Kréta rendszer jelenleg szimulált karbantartás alatt áll.");
      err.isMaintenance = true;
      err.status = 503;
      throw err;
    }

    // 1. Backoff guard
    if (!forceRefresh && store.pala_backoff_until && Date.now() < store.pala_backoff_until) {
      if (store.pala_cached_data) return store.pala_cached_data;
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
          const refreshed = await this.refreshAccessToken(session.refresh_token);
          session.token = refreshed.access_token;
          session.refresh_token = refreshed.refresh_token;
          session.expires_at = refreshed.expires_at;
          await SecureSession.save(session);
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
            cachedAt: store.pala_last_fetch || Date.now()
          };
        }
      }
      throw err;
    }
  }

  /**
   * Robust parser for Kréta evaluation objects.
   * Differentiates standard 1..5 grades, percentages (>5%), text evaluations, "Nem írt", and summary grades.
   */
  static parseGrade(g) {
    if (!g) return { displayValue: "-", badgeClass: "grade-unknown", numericGrade: null, weight: 1, isSummary: false };

    const rawNum = typeof g.SzamErtek === "number" ? g.SzamErtek : parseInt(g.SzamErtek, 10);
    const text = (g.SzovegesErtek || "").trim();
    const typeStr = (g.Tipus?.Leiras || g.Tipus?.Nev || g.ErtekelesFajtaja?.Leiras || "").toLowerCase();

    // Check if summary grade (félévi, év végi, osztályozó)
    const isSummary = typeStr.includes("év végi") ||
                      typeStr.includes("félévi") ||
                      typeStr.includes("negyedévi") ||
                      typeStr.includes("háromnegyedévi") ||
                      typeStr.includes("vegi") ||
                      typeStr.includes("felevi") ||
                      typeStr.includes("osztályozó");

    // Check if "Nem írt" or absent
    const isNemIrt = text.toLowerCase() === "nem írt" || 
                     text.toLowerCase() === "nem jelent meg" || 
                     text.toLowerCase() === "nem irt";

    // Check if percentage evaluation
    const isPercentage = (!isNaN(rawNum) && rawNum > 5) || 
                         text.endsWith("%") || 
                         typeStr.includes("százalék") || 
                         typeStr.includes("szazalek");

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

    const weightRaw = g.SulySzazalekErteke || g.SulySzazalek || 100;
    const weight = (typeof weightRaw === "number" ? weightRaw : (parseFloat(weightRaw) || 100)) / 100;

    return {
      raw: g,
      numericGrade,
      displayValue,
      badgeClass,
      isSummary,
      isPercentage,
      isNemIrt,
      weight,
      weightPercent: weightRaw
    };
  }

  static getDemoDataset() {
    return {
      student: DEMO_STUDENT,
      grades: DEMO_GRADES,
      timetable: generateDemoTimetable(),
      homework: DEMO_HOMEWORK,
      exams: DEMO_EXAMS,
      absences: DEMO_ABSENCES,
      groupAverages: DEMO_GROUP_AVERAGES,
      messages: [
        {
          id: "m-1",
          type: "Beérkezett üzenet",
          sender: "Dobronayné Csepeti Melinda (tanár)",
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
          sender: "Dobronayné Csepeti Melinda (tanár)",
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
          sender: "Dobronayné Csepeti Melinda (tanár)",
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
          sender: "Dobronayné Csepeti Melinda (tanár)",
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
          sender: "Farkas-Szebenszki Emese (tanár)",
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
          sender: "Kaufmann Péter (igazgató h.)",
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
        }
      ],
      teachers: [
        { id: 101, name: "Dobronayné Csepeti Melinda", subjects: ["Matematika", "Osztályfőnök"] },
        { id: 102, name: "Kaufmann Péter", subjects: ["Igazgatóhelyettes"] },
        { id: 103, name: "Farkas-Szebenszki Emese", subjects: ["Idegen nyelv"] },
        { id: 104, name: "Zádori Gabriella", subjects: ["Magyar nyelv és irodalom"] },
        { id: 105, name: "Stéberné Urbán Anna Ilona", subjects: ["Igazgatóhelyettes"] }
      ],
      questionnaires: [
        {
          id: "q-1",
          title: "Jelentkezési lap - közösségi szolgálat - tanulói 2024/2025",
          status: "Kiküldve",
          sender: "Kaufmann Péter",
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
          sender: "Kaufmann Péter",
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

