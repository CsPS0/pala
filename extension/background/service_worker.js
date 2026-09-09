// Pala Extension - Background Service Worker with Safeguards

importScripts("../shared/kreta_api.js");

// Tracks OAuth codes already processed to prevent duplicate handling when
// both webNavigation.onBeforeNavigate and tabs.onUpdated fire for the same redirect.
const handledCodes = new Set();

chrome.runtime.onInstalled.addListener(() => {
  console.log("Pala Extension installed successfully.");
  // Setup safe 30-minute background check alarm
  chrome.alarms.create("pala_grade_sync", { periodInMinutes: 30 });
});

/**
 * Handles an OAuth redirect URL by extracting the code, closing the tab,
 * exchanging the code for tokens, and triggering an initial data fetch.
 * @param {string} url - The full redirect URL containing the code.
 * @param {number} tabId - The tab ID to close after handling.
 */
async function handleOAuthRedirect(url, tabId) {
  try {
    const parsed = new URL(url.replace("#", "?"));
    const code = parsed.searchParams.get("code");
    const returnedState = parsed.searchParams.get("state");
    if (!code) return;

    // Deduplicate: skip if this code was already handled by the other listener.
    if (handledCodes.has(code)) return;
    handledCodes.add(code);
    // Clean up the set after 60 seconds to avoid unbounded growth.
    setTimeout(() => handledCodes.delete(code), 60000);

    // Close the redirect tab immediately; wrap in try/catch because Brave may
    // already have closed it or the tab may have been removed by another handler.
    try {
      await chrome.tabs.remove(tabId);
    } catch (tabErr) {
      console.warn("Pala: redirect tab already closed or not found:", tabErr.message);
    }

    const store = await chrome.storage.local.get(["pala_pending_login"]);
    const pending = store.pala_pending_login;

    // Reject any redirect whose state does not match the one we generated
    // when the login tab was opened. Without this check, a crafted or
    // replayed redirect URL could be accepted as a legitimate login
    // completion (OAuth login CSRF).
    if (!pending || !pending.state || pending.state !== returnedState) {
      console.warn("Pala: OAuth state mismatch, ignoring redirect.");
      await chrome.storage.local.set({ pala_pending_login: null });
      return;
    }

    const institute = pending.institute || "klik039000";

    const tokenData = await KretaApi.exchangeCodeForToken(code);
    await SecureSession.save({
      institute: institute,
      token: tokenData.access_token,
      refresh_token: tokenData.refresh_token,
      expires_at: tokenData.expires_at,
      user: "Online Diak"
    });
    await chrome.storage.local.set({
      pala_use_demo: false,
      pala_pending_login: null
    });

    chrome.notifications.create(`pala_login_${Date.now()}`, {
      type: "basic",
      iconUrl: "../icons/icon-128.png",
      title: "Pala — Sikeres Bejelentkezés!",
      message: "A bővítmény sikeresen összekapcsolódott a Kréta rendszerrel.",
      priority: 2
    });

    // Broadcast to any open extension pages so they reload immediately.
    // The storage.onChanged listener in dashboard/popup also handles this,
    // but sendMessage provides an explicit push for pages that may be open.
    chrome.runtime.sendMessage({ type: "pala_session_changed" }).catch(() => {
      // No listener open — that is normal, ignore the error.
    });

    // Trigger immediate initial data fetch.
    await checkForNewGrades(true);
  } catch (err) {
    console.error("Hiba az OAuth kód beváltásakor:", err);
  }
}

// 1a. Primary intercept: webNavigation.onBeforeNavigate fires before the page
//     renders, which is ideal. The frameId guard prevents sub-frame triggers.
chrome.webNavigation.onBeforeNavigate.addListener(async (details) => {
  if (!details.url || !details.url.includes("mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect")) return;
  if (details.frameId !== 0) return; // Main frame only
  await handleOAuthRedirect(details.url, details.tabId);
}, {
  url: [{ hostContains: "mobil.e-kreta.hu" }]
});

// 1b. Fallback intercept: tabs.onUpdated catches cases where Brave's navigation
//     commits race with the webNavigation event and the tab is not removed in time.
chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
  if (changeInfo.status !== "loading") return;
  const url = changeInfo.url || tab.url || "";
  if (!url.includes("mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect")) return;
  await handleOAuthRedirect(url, tabId);
});

// 2. Alarm Trigger with Safeguards
chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === "pala_grade_sync") {
    await checkForNewGrades();
  }
});

/**
 * Intelligent background grade sync:
 * - Respects active school hours (avoids useless night/weekend polling)
 * - Adds randomized jitter to prevent burst storms
 * - Uses token refresh and honors 429 backoff
 */
async function checkForNewGrades(force = false) {
  const store = await chrome.storage.local.get([
    "pala_use_demo",
    "pala_known_grade_ids",
    "pala_backoff_until"
  ]);
  const session = await SecureSession.load();

  if (store.pala_use_demo || !session) return;

  // Rate-limit backoff check
  if (store.pala_backoff_until && Date.now() < store.pala_backoff_until) {
    return;
  }

  // School hours guard (Monday-Friday 07:00 - 19:30)
  if (!force) {
    const now = new Date();
    const day = now.getDay();
    const hour = now.getHours();
    const isWeekend = day === 0 || day === 6;
    const isNight = hour < 7 || hour >= 20;

    if (isWeekend || isNight) {
      return; // Skip poll outside active hours
    }

    // Randomized jitter (0 to 30 seconds delay)
    const jitterMs = Math.floor(Math.random() * 30000);
    await new Promise(resolve => setTimeout(resolve, jitterMs));
  }

  try {
    const token = await KretaApi.ensureValidToken(session);
    const data = await KretaApi.getStudentData(session.institute, token);

    if (!data) return;

    // Cache updated data
    await chrome.storage.local.set({
      pala_cached_data: data,
      pala_last_fetch: Date.now()
    });

    // Update student name in session if available
    if (data.student?.Nev && session.user !== data.student.Nev) {
      session.user = data.student.Nev;
      await SecureSession.save(session);
    }

    // Broadcast data update to any open extension views
    chrome.runtime.sendMessage({ type: "pala_data_updated" }).catch(() => {});

    await checkScheduleChanges(data);

    const knownIds = new Set(store.pala_known_grade_ids || []);
    const newGrades = data.grades.filter(g => !knownIds.has(g.Id));

    if (newGrades.length > 0 && knownIds.size > 0) {
      const latest = newGrades[0];
      const sub = latest.Tantargy?.Nev || "Tantárgy";
      const val = latest.SzamErtek || latest.SzovegesErtek || "5";
      const topic = latest.Tema || latest.Tipus?.Leiras || "Értékelés";

      chrome.notifications.create(`pala_grade_${Date.now()}`, {
        type: "basic",
        iconUrl: "../icons/icon-128.png",
        title: `Új érdemjegy: ${sub} — ${val}`,
        message: `Téma: ${topic} (${latest.SulySzazalek || 100}%)`,
        priority: 2
      });

      chrome.action.setBadgeText({ text: `${newGrades.length}` });
      chrome.action.setBadgeBackgroundColor({ color: "#FF8800" });
    }

    // Update known IDs
    const allIds = data.grades.map(g => g.Id);
    await chrome.storage.local.set({ pala_known_grade_ids: allIds });
  } catch (err) {
    console.warn("Background grade check failed:", err);
  }
}

/**
 * Kréta only marks a substitution or cancellation once it's decided, so a
 * student otherwise finds out by opening the timetable. Mirrors the grade
 * check above but tracks notified lesson ids instead of a count, since
 * "new" here means "changed", not "added".
 */
async function checkScheduleChanges(data) {
  const store = await chrome.storage.local.get(["pala_notified_schedule_change_ids"]);
  const notified = new Set(store.pala_notified_schedule_change_ids || []);

  const now = new Date();
  const todayStr = now.toDateString();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const tomorrowStr = tomorrow.toDateString();

  const isChanged = (l) => {
    const stateName = (l.Allapot?.Nev || l.Allapot || "").toLowerCase();
    const substitute = l.HelyettesTanarNeve || l.HelyettesitoTanarNeve;
    return stateName.includes("elmaradt") || !!substitute;
  };

  const changed = (data.timetable || []).filter(l => {
    if (!l.KezdetIdopont) return false;
    const dStr = new Date(l.KezdetIdopont).toDateString();
    return (dStr === todayStr || dStr === tomorrowStr) && isChanged(l);
  });

  const currentIds = new Set();
  for (const l of changed) {
    const id = l.Uid || `${l.KezdetIdopont}_${l.Oraszam}`;
    currentIds.add(id);
    if (notified.has(id)) continue;

    const dStr = new Date(l.KezdetIdopont).toDateString();
    const dayLabel = dStr === todayStr ? "Ma" : "Holnap";
    const sub = l.Tantargy?.Nev || "Tanóra";
    const stateName = (l.Allapot?.Nev || l.Allapot || "").toLowerCase();
    const substitute = l.HelyettesTanarNeve || l.HelyettesitoTanarNeve;
    const cancelled = stateName.includes("elmaradt");

    chrome.notifications.create(`pala_schedule_${Date.now()}_${id}`, {
      type: "basic",
      iconUrl: "../icons/icon-128.png",
      title: cancelled ? `${dayLabel} elmarad: ${sub}` : `${dayLabel} helyettesítés: ${sub}`,
      message: cancelled ? "Az óra törölve lett az órarendből." : `Helyettesítő tanár: ${substitute}`,
      priority: 2
    });

    notified.add(id);
  }

  // Drop ids that fell out of today/tomorrow's changed-lesson window.
  for (const id of Array.from(notified)) {
    if (!currentIds.has(id)) notified.delete(id);
  }

  await chrome.storage.local.set({ pala_notified_schedule_change_ids: Array.from(notified) });
}

