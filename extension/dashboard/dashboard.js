// Pala Extension - Full Dashboard Logic

let fullState = {
  isDemo: true,
  data: null,
  aliases: {}
};

let aliasCategory = "subject"; // "subject" | "teacher"

/** Applies dark (default) or light mode by setting/removing data-theme on <html>. */
function applyThemeMode(isDark) {
  if (isDark) {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.setAttribute("data-theme", "light");
  }
  const toggle = document.getElementById("dash-dark-mode-toggle");
  if (toggle) toggle.checked = isDark;
}

function getDisplaySubject(name) {
  if (!name) return "";
  return fullState.aliases?.[name] || name;
}

document.addEventListener("DOMContentLoaded", async () => {
  // Initialize dark/light mode (dark is the default).
  const themeStore = await chrome.storage.local.get("pala_dark_mode");
  const isDark = themeStore.pala_dark_mode !== false;
  applyThemeMode(isDark);

  document.getElementById("dash-dark-mode-toggle")?.addEventListener("change", async (e) => {
    const dark = e.target.checked;
    applyThemeMode(dark);
    await chrome.storage.local.set({ pala_dark_mode: dark });
  });

  setupSidebarNavigation();
  document.getElementById("btn-reload")?.addEventListener("click", async () => {
    await loadDashboardData(true);
  });
  document.getElementById("btn-dash-maint-retry")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_simulate_maintenance: false });
    await loadDashboardData(true);
  });
  document.getElementById("btn-dash-retry-main")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_simulate_maintenance: false });
    await loadDashboardData(true);
  });
  document.getElementById("btn-dash-demo-main")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_use_demo: true, pala_simulate_maintenance: false });
    await loadDashboardData(true);
  });
  document.getElementById("btn-toggle-dash-sim-maint")?.addEventListener("click", async () => {
    const store = await chrome.storage.local.get("pala_simulate_maintenance");
    const next = !store.pala_simulate_maintenance;
    await chrome.storage.local.set({ pala_simulate_maintenance: next });
    await loadDashboardData(true);
  });

  setupStudentExtraModal();

  // School Autocomplete in Dashboard Settings
  const dashSchoolInput = document.getElementById("dash-login-institute");
  const dashSchoolHidden = document.getElementById("dash-login-institute-code");
  const dashSchoolDropdown = document.getElementById("dash-school-dropdown");
  const dashSchoolInfo = document.getElementById("dash-selected-school-info");

  let dashSchoolDebounce = null;
  dashSchoolInput?.addEventListener("input", () => {
    clearTimeout(dashSchoolDebounce);
    if (dashSchoolHidden) dashSchoolHidden.value = "";
    if (dashSchoolInfo) dashSchoolInfo.style.display = "none";

    const query = dashSchoolInput.value.trim();
    if (query.length < 2) {
      if (dashSchoolDropdown) {
        dashSchoolDropdown.style.display = "none";
        dashSchoolDropdown.innerHTML = "";
      }
      return;
    }

    dashSchoolDebounce = setTimeout(async () => {
      if (!dashSchoolDropdown) return;
      dashSchoolDropdown.innerHTML = '<div style="padding:10px 14px; font-size:0.78rem; color:var(--text-muted);">Keresés...</div>';
      dashSchoolDropdown.style.display = "block";

      const schools = await KretaApi.searchSchools(query);
      if (schools.length === 0) {
        dashSchoolDropdown.innerHTML = '<div style="padding:10px 14px; font-size:0.78rem; color:var(--text-muted);">Nincs találat. Beírhatsz közvetlen kódot is.</div>';
        return;
      }

      dashSchoolDropdown.innerHTML = "";
      schools.forEach(s => {
        const item = document.createElement("div");
        item.className = "school-item";
        item.innerHTML = `<div><strong>${escapeHtml(s.name)}</strong></div><div style="font-size:0.72rem; color:var(--primary); margin-top:2px;">Kód: ${escapeHtml(s.code)}</div>`;
        item.addEventListener("click", () => {
          dashSchoolInput.value = s.name;
          if (dashSchoolHidden) dashSchoolHidden.value = s.code;
          dashSchoolDropdown.style.display = "none";
          if (dashSchoolInfo) {
            dashSchoolInfo.innerText = `Kiválasztva: ${s.code}`;
            dashSchoolInfo.style.display = "block";
          }
        });
        dashSchoolDropdown.appendChild(item);
      });
    }, 250);
  });

  document.addEventListener("click", (e) => {
    if (!dashSchoolInput?.contains(e.target) && !dashSchoolDropdown?.contains(e.target)) {
      if (dashSchoolDropdown) dashSchoolDropdown.style.display = "none";
    }
  });

  document.getElementById("btn-dash-web-login")?.addEventListener("click", async () => {
    const inst = dashSchoolHidden?.value.trim() || dashSchoolInput?.value.trim() || "klik039000";
    const errBox = document.getElementById("dash-login-error");
    const authUrl = await KretaApi.startWebLogin(inst);
    if (errBox) {
      errBox.innerText = "Megnyitás külön lapon... Jelentkezz be a hivatalos Kréta felületen!";
      errBox.style.display = "block";
      errBox.style.color = "var(--primary)";
    }
    chrome.tabs.create({ url: authUrl });
  });

  document.getElementById("btn-dash-demo-mode")?.addEventListener("click", async () => {
    await SecureSession.save(null);
    await chrome.storage.local.set({ pala_use_demo: true, pala_simulate_maintenance: false });
    await loadDashboardData(true);
  });

  document.getElementById("btn-dash-clear-cache")?.addEventListener("click", async () => {
    await chrome.storage.local.remove(["pala_cached_data", "pala_last_fetch"]);
    await loadDashboardData(true);
  });

  document.getElementById("btn-dash-sim-maint-settings")?.addEventListener("click", async () => {
    const store = await chrome.storage.local.get("pala_simulate_maintenance");
    const next = !store.pala_simulate_maintenance;
    await chrome.storage.local.set({ pala_simulate_maintenance: next });
    await loadDashboardData(true);
  });

  document.getElementById("btn-dash-logout")?.addEventListener("click", async () => {
    await SecureSession.save(null);
    await chrome.storage.local.set({ pala_use_demo: true });
    await loadDashboardData(true);
  });

  let isMatrixView = false;
  document.getElementById("btn-timetable-toggle")?.addEventListener("click", () => {
    isMatrixView = !isMatrixView;
    const btn = document.getElementById("btn-timetable-toggle");
    if (btn) btn.innerText = isMatrixView ? "Napi Lista" : "7-napos Mátrix";
    const listGrid = document.getElementById("weekly-timetable-grid");
    const mxGrid = document.getElementById("matrix-timetable-grid");
    if (listGrid) listGrid.style.display = isMatrixView ? "none" : "grid";
    if (mxGrid) mxGrid.style.display = isMatrixView ? "block" : "none";
  });

  setupMessageFilters();
  setupMessageModals();

  // Save Settings
  document.getElementById("btn-save-parental-limit")?.addEventListener("click", async () => {
    const limitInput = document.getElementById("settings-parental-limit");
    if (limitInput) {
      const val = parseInt(limitInput.value, 10);
      if (!isNaN(val) && val > 0) {
        await chrome.storage.local.set({ pala_parental_limit: val });
        const fb = document.getElementById("settings-save-feedback");
        if (fb) {
          fb.style.display = "block";
          setTimeout(() => fb.style.display = "none", 3000);
        }
        await loadDashboardData(false);
      }
    }
  });

  // Save Popup Customization Settings from Dashboard
  document.getElementById("btn-save-dash-popup-settings")?.addEventListener("click", async () => {
    const newSettings = {
      defaultTab: document.getElementById("dash-popup-pref-default-tab")?.value || "tab-today",
      showHeroCard: document.getElementById("dash-popup-pref-show-hero")?.checked !== false,
      compactMode: document.getElementById("dash-popup-pref-compact")?.checked === true,
      showAverageBar: document.getElementById("dash-popup-pref-show-average")?.checked !== false,
      maxGrades: parseInt(document.getElementById("dash-popup-pref-max-grades")?.value || "10", 10),
      maxTasks: parseInt(document.getElementById("dash-popup-pref-max-tasks")?.value || "5", 10)
    };

    await chrome.storage.local.set({ pala_popup_settings: newSettings });
    const fb = document.getElementById("dash-popup-settings-feedback");
    if (fb) {
      fb.style.display = "block";
      setTimeout(() => fb.style.display = "none", 3000);
    }
  });

  // CSV Exports
  const downloadCSV = (filename, csvContent) => {
    const blob = new Blob(["\uFEFF" + csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  document.getElementById("btn-export-grades")?.addEventListener("click", () => {
    if (!fullState.data?.grades) return alert("Nincsenek elérhető jegyek.");
    let csv = "Tantárgy,Típus,Érték,Súly,Dátum,Téma\n";
    fullState.data.grades.forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      const sub = `"${(g.Tantargy?.Nev || g.Tantargy || "Egyéb").replace(/"/g, '""')}"`;
      const type = `"${(g.Tipus?.Leiras || g.Tipus?.Nev || "Értékelés").replace(/"/g, '""')}"`;
      const val = parsed.displayValue;
      const weight = parsed.weightPercent;
      const date = (g.KeszitesDatuma || g.RogzitesDatuma || g.Datum || "").split("T")[0];
      const theme = `"${(g.Tema || "").replace(/"/g, '""')}"`;
      csv += `${sub},${type},${val},${weight}%,${date},${theme}\n`;
    });
    downloadCSV("jegyek_export.csv", csv);
  });

  document.getElementById("btn-export-absences")?.addEventListener("click", () => {
    if (!fullState.data?.absences) return alert("Nincsenek elérhető mulasztások.");
    let csv = "Tantárgy,Dátum,Típus,Állapot,Késés (perc)\n";
    fullState.data.absences.forEach(a => {
      const sub = `"${(a.Tantargy?.Nev || a.Tantargy || "Tanóra").replace(/"/g, '""')}"`;
      const date = (a.Datum || a.OraKezdete || "").split("T")[0];
      const type = `"${(a.Tipus?.Leiras || a.Tipus || "Mulasztás").replace(/"/g, '""')}"`;
      const state = `"${(a.IgazolasAllapota || "Igazolatlan").replace(/"/g, '""')}"`;
      const delay = a.KesesPercben || 0;
      csv += `${sub},${date},${type},${state},${delay}\n`;
    });
    downloadCSV("mulasztasok_export.csv", csv);
  });

  // iCalendar (.ics) Timetable Export
  document.getElementById("btn-export-ics")?.addEventListener("click", () => {
    const lessons = fullState.data?.timetable || [];
    if (!lessons.length) return alert("Nincsenek elérhető órarendi adatok.");

    let ics = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Pala//Pala Extension//HU\r\nCALSCALE:GREGORIAN\r\nMETHOD:PUBLISH\r\nX-WR-CALNAME:Pala Órarend\r\n";
    const nowUtc = new Date().toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";

    lessons.forEach(l => {
      const start = l.KezdetIdopont ? new Date(l.KezdetIdopont).toISOString().replace(/[-:]/g, "").split(".")[0] + "Z" : null;
      const end = l.VegIdopont ? new Date(l.VegIdopont).toISOString().replace(/[-:]/g, "").split(".")[0] + "Z" : null;
      if (!start || !end) return;

      const rawSub = l.Tantargy?.Nev || l.Tantargy || "Tanóra";
      const sub = getDisplaySubject(rawSub);
      const theme = (l.Tema || "").replace(/\r?\n/g, " ");
      const room = l.Terem ? ` (Terem: ${l.Terem})` : "";
      const uid = `lesson-${l.Id || Math.random().toString(36).substring(2)}@pala`;

      ics += `BEGIN:VEVENT\r\nUID:${uid}\r\nDTSTAMP:${nowUtc}\r\nDTSTART:${start}\r\nDTEND:${end}\r\nSUMMARY:${sub}${room}\r\nDESCRIPTION:${theme}\r\nEND:VEVENT\r\n`;
    });

    ics += "END:VCALENDAR\r\n";

    const blob = new Blob([ics], { type: "text/calendar;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "pala_orarend.ics";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  });

  // Pala Wrapped
  document.getElementById("btn-open-wrapped")?.addEventListener("click", () => {
    openWrappedModal();
  });
  document.getElementById("btn-close-wrapped")?.addEventListener("click", () => {
    const modal = document.getElementById("wrapped-modal");
    if (modal) modal.style.display = "none";
  });

  // Aliases Management
  document.getElementById("btn-add-alias")?.addEventListener("click", async () => {
    const origInput = document.getElementById("alias-orig-input");
    const customInput = document.getElementById("alias-custom-input");
    const orig = origInput?.value.trim();
    const custom = customInput?.value.trim();
    if (!orig || !custom) return alert("Kérlek add meg mindkét mezőt!");

    fullState.aliases = fullState.aliases || {};
    fullState.aliases[orig] = custom;
    await chrome.storage.local.set({ pala_aliases: fullState.aliases });
    if (origInput) origInput.value = "";
    if (customInput) customInput.value = "";
    renderAliases();
    renderDashboard();
  });

  document.getElementById("alias-cat-subject")?.addEventListener("click", () => {
    aliasCategory = "subject";
    document.getElementById("alias-cat-subject")?.classList.add("active");
    document.getElementById("alias-cat-teacher")?.classList.remove("active");
    const input = document.getElementById("alias-orig-input");
    if (input) { input.value = ""; }
    populateAliasDatalist();
    renderAliasSuggestions("");
  });
  document.getElementById("alias-cat-teacher")?.addEventListener("click", () => {
    aliasCategory = "teacher";
    document.getElementById("alias-cat-teacher")?.classList.add("active");
    document.getElementById("alias-cat-subject")?.classList.remove("active");
    const input = document.getElementById("alias-orig-input");
    if (input) { input.value = ""; }
    populateAliasDatalist();
    ensureTeachersLoaded();
    renderAliasSuggestions("");
  });

  const aliasOrigInput = document.getElementById("alias-orig-input");
  const aliasOrigBox = document.getElementById("alias-orig-suggestions");
  aliasOrigInput?.addEventListener("focus", () => renderAliasSuggestions(aliasOrigInput.value));
  aliasOrigInput?.addEventListener("input", () => renderAliasSuggestions(aliasOrigInput.value));
  aliasOrigInput?.addEventListener("blur", () => {
    // Small delay so a mousedown-select on a suggestion still registers first.
    setTimeout(() => { if (aliasOrigBox) aliasOrigBox.style.display = "none"; }, 150);
  });

  // Listen for background login or sync updates.
  // Use forceRefresh=true when the session itself changes (new login) so the
  // fresh token is used to fetch data immediately instead of serving stale cache.
  chrome.storage.onChanged?.addListener((changes, area) => {
    if (area !== "local") return;
    if (changes.pala_dark_mode) {
      applyThemeMode(changes.pala_dark_mode.newValue !== false);
    }
    if (changes.pala_session || changes.pala_maintenance_mode) {
      loadDashboardData(true);
    } else if (changes.pala_cached_data) {
      loadDashboardData(false);
    } else if (changes.pala_popup_settings) {
      const s = changes.pala_popup_settings.newValue || {};
      const tabEl = document.getElementById("dash-popup-pref-default-tab");
      if (tabEl) tabEl.value = s.defaultTab || "tab-today";
      const heroEl = document.getElementById("dash-popup-pref-show-hero");
      if (heroEl) heroEl.checked = s.showHeroCard !== false;
      const compactEl = document.getElementById("dash-popup-pref-compact");
      if (compactEl) compactEl.checked = s.compactMode === true;
      const avgEl = document.getElementById("dash-popup-pref-show-average");
      if (avgEl) avgEl.checked = s.showAverageBar !== false;
      const maxGradesEl = document.getElementById("dash-popup-pref-max-grades");
      if (maxGradesEl) maxGradesEl.value = String(s.maxGrades ?? 10);
      const maxTasksEl = document.getElementById("dash-popup-pref-max-tasks");
      if (maxTasksEl) maxTasksEl.value = String(s.maxTasks ?? 5);
    }
  });

  // Listen for broadcast messages from service worker (session changed, data updated)
  chrome.runtime.onMessage?.addListener((msg) => {
    if (msg?.type === "pala_session_changed" || msg?.type === "pala_data_updated") {
      loadDashboardData(true);
    }
  });

  await loadDashboardData();
});

function setupSidebarNavigation() {
  const items = document.querySelectorAll(".nav-item");
  items.forEach(btn => {
    btn.addEventListener("click", () => {
      items.forEach(i => i.classList.remove("active"));
      document.querySelectorAll(".view-panel").forEach(p => p.classList.remove("active"));

      btn.classList.add("active");
      const target = btn.getAttribute("data-tab");
      document.getElementById(target)?.classList.add("active");

      if (target === "view-messages") {
        syncMessagesIfEmpty();
      }
    });
  });
}

async function syncMessagesIfEmpty() {
  const store = await chrome.storage.local.get(["pala_use_demo"]);
  const session = await SecureSession.load();
  if (store.pala_use_demo !== false || !session?.token) return;
  if (fullState.data?.messages && fullState.data.messages.some(m => m.source === "eugyintezes")) return;

  try {
    const token = await KretaApi.ensureValidToken(session);
    const [adminMsgs, teachers, quests] = await Promise.all([
      KretaApi.getAdminMessages(token).catch(() => []),
      KretaApi.getTeachers(token).catch(() => []),
      KretaApi.getQuestionnaires(token).catch(() => [])
    ]);
    if (adminMsgs && adminMsgs.length > 0) fullState.data.messages = adminMsgs;
    if (teachers && teachers.length > 0) fullState.data.teachers = teachers;
    if (quests && quests.length > 0) fullState.data.questionnaires = quests;
    await chrome.storage.local.set({ pala_cached_data: fullState.data });
    renderMessagesView(fullState.data.messages || [], fullState.data.questionnaires || []);
  } catch (_) {}
}

async function loadDashboardData(force = false) {
  const store = await chrome.storage.local.get([
    "pala_use_demo",
    "pala_cached_data",
    "pala_maintenance_mode",
    "pala_simulate_maintenance",
    "pala_aliases"
  ]);
  const session = await SecureSession.load();
  fullState.aliases = store.pala_aliases || {};
  const useDemo = store.pala_use_demo !== false;

  if (useDemo || !session) {
    fullState.isDemo = true;
    fullState.isMaintenance = false;
    fullState.data = KretaApi.getDemoDataset();
  } else {
    fullState.isDemo = false;

    // Auto-force a live fetch when session exists but no cached data is available
    // (e.g. right after a fresh login where the first background fetch failed).
    if (!force && !store.pala_cached_data) {
      force = true;
      // Show a loading state so the user knows a fetch is in progress.
      const nameEl = document.getElementById("student-name");
      if (nameEl) nameEl.innerText = "Adatok betöltése...";
      const instEl = document.getElementById("inst-name");
      if (instEl) instEl.innerText = "Kapcsolódás a Kréta szerverhez...";
    }

    try {
      fullState.data = await KretaApi.getCachedOrFetchData(session, force);
      fullState.isMaintenance = fullState.data?.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
      renderDashboard();
      return;
    } catch (e) {
      console.warn("Could not fetch online Kréta data, falling back to cached:", e);
      const isMaint = e.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
      fullState.isMaintenance = isMaint;
      if (store.pala_cached_data) {
        fullState.data = { ...store.pala_cached_data, isMaintenance: true };
      } else {
        // No cache and no network: show a user-visible error card.
        fullState.data = null;
        fullState.fetchError = e;
      }
    }
  }

  renderDashboard();
}

let currentSubjectFilter = "all";

function renderDashboard() {
  const d = fullState.data;
  const maintBanner = document.getElementById("dash-maintenance-banner");
  const maintView = document.getElementById("view-maintenance");
  const dashView = document.getElementById("view-dashboard");

  // Handle Maintenance state
  if (fullState.isMaintenance) {
    if (!d) {
      // Full maintenance screen (no cached data available)
      if (maintView) {
        maintView.style.display = "block";
        maintView.classList.add("active");
      }
      if (maintBanner) maintBanner.style.display = "none";
      if (dashView) {
        dashView.style.display = "none";
        dashView.classList.remove("active");
      }

      const demoBadge = document.getElementById("demo-indicator");
      if (demoBadge) {
        demoBadge.className = "badge badge-maintenance";
        demoBadge.innerText = "Központi Karbantartás";
      }
      return;
    } else {
      // Offline cached view with alert banner
      if (maintBanner) maintBanner.style.display = "block";
      if (maintView) {
        maintView.style.display = "none";
        maintView.classList.remove("active");
      }
      if (dashView) {
        dashView.style.display = "block";
        dashView.classList.add("active");
      }

      const demoBadge = document.getElementById("demo-indicator");
      if (demoBadge) {
        demoBadge.className = "badge badge-maintenance";
        demoBadge.innerText = "Karbantartás • Offline Gyorsítótár";
      }
    }
  } else {
    if (maintBanner) maintBanner.style.display = "none";
    if (maintView) maintView.style.display = "none";
  }

  if (!d) {
    if (fullState.fetchError) {
      // Session is valid but the server is unreachable: show a user-friendly error.
      const nameEl = document.getElementById("student-name");
      if (nameEl) nameEl.innerText = "Betöltés sikertelen";
      const instEl = document.getElementById("inst-name");
      if (instEl) instEl.innerText = "Kréta szerver nem érhető el";
      const demoBadge = document.getElementById("demo-indicator");
      if (demoBadge) {
        demoBadge.className = "badge badge-figyelmeztetes";
        demoBadge.innerText = "Szerver hiba";
      }

      // Inject an error card into the Home view (view-dashboard).
      const homeView = document.getElementById("view-dashboard");
      if (homeView) {
        const existingCard = document.getElementById("pala-fetch-error-card");
        if (!existingCard) {
          const errCard = document.createElement("div");
          errCard.id = "pala-fetch-error-card";
          errCard.className = "card";
          errCard.style.cssText = "margin:16px; border-left:3px solid var(--danger); background:rgba(255,69,58,0.06);";
          const errTitle = document.createElement("div");
          errTitle.style.cssText = "font-weight:700; color:var(--danger); margin-bottom:8px;";
          errTitle.innerText = "Nem sikerült adatot betölteni";
          const errBody = document.createElement("div");
          errBody.style.cssText = "font-size:0.82rem; color:var(--text-muted); margin-bottom:14px;";
          errBody.innerText = "Nem sikerült adatot betölteni a Kréta szerverről. Kérlek ellenőrizd, hogy a Kréta elérhető-e, majd kattints a Frissítés gombra.";
          const errBtn = document.createElement("button");
          errBtn.className = "btn btn-primary btn-sm";
          errBtn.innerText = "Újra próbálom";
          errBtn.addEventListener("click", async () => {
            errCard.remove();
            await loadDashboardData(true);
          });
          errCard.appendChild(errTitle);
          errCard.appendChild(errBody);
          errCard.appendChild(errBtn);
          homeView.insertBefore(errCard, homeView.firstChild);
        }
      }
      fullState.fetchError = null;
    } else {
      const nameEl = document.getElementById("student-name");
      if (nameEl) nameEl.innerText = "Bejelentkezés szükséges";
      const instEl = document.getElementById("inst-name");
      if (instEl) instEl.innerText = "Kattints a Beállítások menüpontra a bejelentkezéshez!";
      const demoBadge = document.getElementById("demo-indicator");
      if (demoBadge) {
        demoBadge.className = "badge badge-figyelmeztetes";
        demoBadge.innerText = "Munkamenet lejárt";
      }
      const todayCard = document.getElementById("today-lessons-count");
      if (todayCard) todayCard.innerText = "0";
      const gradeAvg = document.getElementById("student-grade-average");
      if (gradeAvg) gradeAvg.innerText = "--";
    }
    return;
  }

  // Header & Student info
  const nameEl = document.getElementById("student-name");
  if (nameEl) nameEl.innerText = d.student?.Nev || "Diák";

  const instEl = document.getElementById("inst-name");
  if (instEl) {
    instEl.innerText = d.student?.IntezmenyNev ||
                       d.student?.Intezmeny?.TeljesNev ||
                       d.student?.Intezmeny?.Nev ||
                       (fullState.isDemo ? "Pala Minta Gimnázium" : "");
  }

  // Demo / Online status badge
  if (!fullState.isMaintenance) {
    const demoBadge = document.getElementById("demo-indicator");
    if (demoBadge) {
      if (fullState.isDemo) {
        demoBadge.className = "badge badge-demo";
        demoBadge.innerText = "Demó Mód (Teszt Elek)";
      } else {
        demoBadge.className = "badge";
        demoBadge.style.color = "var(--success)";
        demoBadge.style.borderColor = "rgba(48,209,88,0.4)";
        demoBadge.style.background = "rgba(48,209,88,0.12)";
        demoBadge.innerText = "Online • Élő Kréta Adatok";
      }
    }
  }

  // 1. Calculate GPA & Stats using robust parser
  let totalWeight = 0;
  let weightedSum = 0;
  const subjectMap = {};

  (d.grades || []).forEach(g => {
    const parsed = KretaApi.parseGrade(g);
    // Include valid 1..5 grades; skip summary and non-numeric evaluations
    if (parsed.numericGrade !== null && !parsed.isSummary) {
      weightedSum += parsed.numericGrade * parsed.weight;
      totalWeight += parsed.weight;
    }

    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy";
    if (!subjectMap[sub]) subjectMap[sub] = [];
    subjectMap[sub].push(g);
  });

  // Fallback: if no mid-term grades exist, include summary grades
  if (totalWeight === 0) {
    (d.grades || []).forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      if (parsed.numericGrade !== null) {
        weightedSum += parsed.numericGrade * parsed.weight;
        totalWeight += parsed.weight;
      }
    });
  }

  const overallAvg = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(2) : "0.00";
  const avgEl = document.getElementById("dash-avg");
  if (avgEl) avgEl.innerText = overallAvg;

  const uniqueSubjects = Object.keys(subjectMap).sort();

  const totalBadge = document.getElementById("dash-subjects-total-badge");
  if (totalBadge) totalBadge.innerText = `${uniqueSubjects.length} tantárgy rögzítve`;

  // Wire 'View All Subjects' button
  const viewAllBtn = document.getElementById("btn-view-all-subjects");
  if (viewAllBtn) {
    viewAllBtn.onclick = () => {
      document.querySelector('[data-tab="view-grades"]')?.click();
    };
  }

  // Today's classes count
  const now = new Date();
  const todayIso = now.toISOString().split("T")[0];
  const todayLessons = (d.timetable || []).filter(item => {
    if (!item.KezdetIdopont) return false;
    return new Date(item.KezdetIdopont).toISOString().split("T")[0] === todayIso;
  });
  const classesEl = document.getElementById("dash-classes");
  if (classesEl) {
    classesEl.innerText = todayLessons.length > 0 ? `${todayLessons.length} óra` : "Nincs óra";
  }

  // Parental absences count
  const parentalAbsences = (d.absences || []).filter(a => {
    const typeStr = (a.Tipus?.Leiras || a.Tipus || "").toLowerCase();
    return typeStr.includes("szülői") || typeStr.includes("szuloi");
  });
  const parentalEl = document.getElementById("dash-parental");
  if (parentalEl) {
    parentalEl.innerText = `${parentalAbsences.length} igazolt`;
  }

  // Calculate Best and Worst subjects
  let bestSub = null;
  let worstSub = null;
  let bestAvg = -1;
  let worstAvg = 99;

  for (const sub of uniqueSubjects) {
    if (subjectMap[sub].length >= 3) {
      let subWeight = 0;
      let subSum = 0;
      subjectMap[sub].forEach(g => {
        const parsed = KretaApi.parseGrade(g);
        if (parsed.numericGrade !== null && !parsed.isSummary) {
          subSum += parsed.numericGrade * parsed.weight;
          subWeight += parsed.weight;
        }
      });
      if (subWeight > 0) {
        const avg = subSum / subWeight;
        if (avg > bestAvg) {
          bestAvg = avg;
          bestSub = sub;
        }
        if (avg < worstAvg) {
          worstAvg = avg;
          worstSub = sub;
        }
      }
    }
  }

  const bestValEl = document.getElementById("dash-best-subject-val");
  const bestNameEl = document.getElementById("dash-best-subject-name");
  if (bestValEl && bestNameEl) {
    if (bestSub) {
      bestValEl.innerText = bestAvg.toFixed(2);
      bestNameEl.innerText = bestSub;
    } else {
      bestValEl.innerText = "--";
      bestNameEl.innerText = "Nincs elég jegy";
    }
  }

  const worstValEl = document.getElementById("dash-worst-subject-val");
  const worstNameEl = document.getElementById("dash-worst-subject-name");
  if (worstValEl && worstNameEl) {
    if (worstSub) {
      worstValEl.innerText = worstAvg.toFixed(2);
      worstNameEl.innerText = worstSub;
    } else {
      worstValEl.innerText = "--";
      worstNameEl.innerText = "Nincs elég jegy";
    }
  }

  // Calculate Unexcused Hours
  let unexcusedCount = 0;
  const unexcusedSubMap = {};
  (d.absences || []).forEach(a => {
    const status = (a.IgazolasAllapota || "").toLowerCase();
    if (!status.includes("igazolt") && a.KesesPercben === 0) {
      unexcusedCount++;
      const sub = a.Tantargy?.Nev || a.Tantargy || "Tanóra";
      unexcusedSubMap[sub] = (unexcusedSubMap[sub] || 0) + 1;
    }
  });

  let topUnexcusedSub = null;
  let maxUnexcused = 0;
  for (const [sub, count] of Object.entries(unexcusedSubMap)) {
    if (count > maxUnexcused) {
      maxUnexcused = count;
      topUnexcusedSub = sub;
    }
  }

  const unexValEl = document.getElementById("dash-unexcused-val");
  const unexNameEl = document.getElementById("dash-unexcused-name");
  if (unexValEl && unexNameEl) {
    unexValEl.innerText = `${unexcusedCount} óra`;
    unexNameEl.innerText = topUnexcusedSub ? `Legtöbb: ${topUnexcusedSub}` : "Nincs igazolatlan";
  }

  // Active / Upcoming Lesson Hero Banner
  try { renderDashboardHero(todayLessons); } catch (e) { console.error("Error rendering hero:", e); }

  // Recent Grades Table with Filter Chips
  try { renderRecentGradesTable(d.grades || [], subjectMap); } catch (e) { console.error("Error rendering recent grades:", e); }

  // Subject Averages Cards Grid on Dashboard
  try { renderDashboardSubjectCards(subjectMap); } catch (e) { console.error("Error rendering subject cards:", e); }

  // View 2: Weekly Timetable Grid
  try { renderWeeklyTimetable(d.timetable || []); } catch (e) { console.error("Error rendering timetable:", e); }

  // View 3: Full Subject Breakdown & Grades
  try {
    renderGhostGradesAndPlanner(subjectMap);
    renderAllGradesView(d.grades || [], d.groupAverages || []);
  } catch (e) { console.error("Error rendering all grades:", e); }

  // View 4: Tasks & Homework
  try { renderTasksView(d.homework || [], d.exams || []); } catch (e) { console.error("Error rendering tasks:", e); }

  // View 5: Messages & e-Ügyintézés (Üzenetek)
  const msgs = Array.isArray(d.messages) ? d.messages : [];
  const quests = Array.isArray(d.questionnaires) ? d.questionnaires : [];
  try { renderMessagesView(msgs, quests); } catch (e) { console.error("Error rendering messages:", e); }

  // View 6: 250h Absence Danger Zone (Mulasztások)
  try { renderAbsencesView(d.absences || []); } catch (e) { console.error("Error rendering absences:", e); }

  // View 7: Student Profile
  try { renderStudentView(d.student); } catch (e) { console.error("Error rendering student:", e); }

  // View 8: Settings (Beállítások)
  try { renderSettingsView(); } catch (e) { console.error("Error rendering settings:", e); }
}

function renderDashboardHero(todayLessons) {
  const titleEl = document.getElementById("dash-active-title");
  const descEl = document.getElementById("dash-active-desc");
  if (!titleEl || !descEl) return;

  const now = new Date();
  let active = null;
  let next = null;

  for (const l of todayLessons) {
    const s = new Date(l.KezdetIdopont);
    const e = new Date(l.VegIdopont);
    if (now >= s && now <= e) {
      active = l;
      break;
    } else if (now < s) {
      if (!next || new Date(next.KezdetIdopont) > s) next = l;
    }
  }

  if (active) {
    const sub = active.Tantargy?.Nev || active.Nev || "Tanóra";
    const room = active.Terem ? ` • Terem: ${active.Terem}` : "";
    const teacher = active.Tanar || active.TanarNeve ? ` (${active.Tanar || active.TanarNeve})` : "";
    titleEl.innerText = `${sub}${room}${teacher}`;

    const end = new Date(active.VegIdopont);
    const minsLeft = Math.ceil((end - now) / 60000);
    descEl.innerText = `Hátra van még: ${minsLeft} perc • ${active.Oraszam || ""}. tanóra`;
  } else if (next) {
    const sub = next.Tantargy?.Nev || next.Nev || "Tanóra";
    const s = new Date(next.KezdetIdopont);
    const timeStr = `${String(s.getHours()).padStart(2, '0')}:${String(s.getMinutes()).padStart(2, '0')}`;
    titleEl.innerText = `Következő tanóra: ${sub}`;
    descEl.innerText = `Kezdés: ${timeStr} • ${next.Oraszam || ""}. tanóra ${next.Terem ? "• Terem: " + next.Terem : ""}`;
  } else {
    titleEl.innerText = todayLessons.length > 0 ? "A mai tanórák véget értek" : "Nincs tanóra rögzítve mára";
    descEl.innerText = todayLessons.length > 0 ? `Összesen ${todayLessons.length} óra volt mára.` : "Jó pihenést és feltöltődést!";
  }
}

function renderRecentGradesTable(grades, subjectMap) {
  const table = document.getElementById("dash-grades-table");
  const filtersContainer = document.getElementById("dash-subject-filters");
  const countSub = document.getElementById("dash-grades-count-sub");
  if (!table) return;

  const subjects = Object.keys(subjectMap || {}).sort();
  if (countSub) {
    countSub.innerText = `Összesen ${grades.length} érdemjegy • ${subjects.length} tantárgyból`;
  }

  // Render subject filter chips
  if (filtersContainer) {
    filtersContainer.innerHTML = "";

    const allBtn = document.createElement("button");
    allBtn.className = `chip-btn ${currentSubjectFilter === "all" ? "active" : ""}`;
    allBtn.innerText = `Minden tantárgy (${grades.length})`;
    allBtn.addEventListener("click", () => {
      currentSubjectFilter = "all";
      renderRecentGradesTable(grades, subjectMap);
    });
    filtersContainer.appendChild(allBtn);

    subjects.forEach(sub => {
      const btn = document.createElement("button");
      btn.className = `chip-btn ${currentSubjectFilter === sub ? "active" : ""}`;
      btn.innerText = `${sub} (${subjectMap[sub].length})`;
      btn.addEventListener("click", () => {
        currentSubjectFilter = sub;
        renderRecentGradesTable(grades, subjectMap);
      });
      filtersContainer.appendChild(btn);
    });
  }

  table.innerHTML = "";

  const filteredGrades = currentSubjectFilter === "all"
    ? grades
    : (subjectMap[currentSubjectFilter] || []);

  if (filteredGrades.length === 0) {
    table.innerHTML = `<div style="text-align:center; padding:24px; color:var(--text-muted);">Nincs rögzített érdemjegy ennél a tantárgynál.</div>`;
    return;
  }

  filteredGrades.slice(0, 50).forEach(g => {
    const parsed = KretaApi.parseGrade(g);
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Tantárgy";
    const topic = g.Tema || g.Tipus?.Leiras || g.Tipus?.Nev || "Értékelés";
    const weightRaw = parsed.weightPercent;

    let dateText = "";
    const dateRaw = g.KeszitesDatuma || g.RogzitesDatuma || g.Datum;
    if (dateRaw) {
      const d = new Date(dateRaw);
      dateText = `${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}.`;
    }

    const row = document.createElement("div");
    row.className = "table-row";
    row.innerHTML = `
      <div style="display:flex; align-items:center; gap:12px;">
        <div class="grade-badge ${parsed.badgeClass}">${parsed.displayValue}</div>
        <div>
          <div style="font-weight:700; font-size:0.88rem;">${escapeHtml(sub)}</div>
          <div style="font-size:0.75rem; color:var(--text-muted);">${escapeHtml(topic)} ${dateText ? "• " + dateText : ""}</div>
        </div>
      </div>
      <span style="font-size:0.75rem; font-weight:700; color:var(--primary);">${weightRaw}%</span>
    `;
    table.appendChild(row);
  });
}

function renderDashboardSubjectCards(subjectMap) {
  const container = document.getElementById("dash-subject-cards-grid");
  if (!container) return;
  container.innerHTML = "";

  const subjects = Object.keys(subjectMap || {}).sort();
  if (subjects.length === 0) {
    container.innerHTML = `<div style="padding:20px; color:var(--text-muted);">Nincsenek elérhető tantárgyak.</div>`;
    return;
  }

  subjects.forEach(sub => {
    const subGrades = subjectMap[sub];
    let sum = 0;
    let weightSum = 0;
    subGrades.forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      if (parsed.numericGrade !== null && !parsed.isSummary) {
        sum += parsed.numericGrade * parsed.weight;
        weightSum += parsed.weight;
      }
    });
    if (weightSum === 0) {
      subGrades.forEach(g => {
        const parsed = KretaApi.parseGrade(g);
        if (parsed.numericGrade !== null) {
          sum += parsed.numericGrade * parsed.weight;
          weightSum += parsed.weight;
        }
      });
    }

    const avg = weightSum > 0 ? (sum / weightSum).toFixed(2) : "-";
    const numAvg = parseFloat(avg);
    const avgColor = isNaN(numAvg) ? "var(--text-muted)" : (numAvg >= 4.5 ? "var(--success)" : (numAvg >= 3.5 ? "var(--info)" : (numAvg >= 2.5 ? "var(--warning)" : "var(--danger)")));

    const card = document.createElement("div");
    card.className = "subject-mini-card";
    card.style.cursor = "pointer";
    card.title = "Kattints a tantárgy jegyeinek szűréséhez";
    card.addEventListener("click", () => {
      currentSubjectFilter = sub;
      const tableSection = document.getElementById("dash-grades-table");
      renderRecentGradesTable(fullState.data.grades || [], subjectMap);
      tableSection?.scrollIntoView({ behavior: "smooth" });
    });

    let gradePills = "";
    subGrades.slice(0, 6).forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      gradePills += `<div class="grade-badge ${parsed.badgeClass}" style="height:22px; font-size:0.75rem;">${parsed.displayValue}</div>`;
    });
    if (subGrades.length > 6) {
      gradePills += `<span style="font-size:0.7rem; color:var(--text-muted); align-self:center;">+${subGrades.length - 6}</span>`;
    }

    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:8px;">
        <strong style="font-size:0.85rem; line-height:1.2;">${escapeHtml(getDisplaySubject(sub))}</strong>
        <span style="font-size:1.1rem; font-weight:900; color:${avgColor};">${avg}</span>
      </div>
      <div style="display:flex; gap:4px; align-items:center; flex-wrap:wrap;">
        ${gradePills}
      </div>
      <div style="font-size:0.68rem; color:var(--text-muted); margin-top:8px;">${subGrades.length} értékelés rögzítve</div>
    `;
    container.appendChild(card);
  });
}

function renderWeeklyTimetable(timetable) {
  const listGrid = document.getElementById("weekly-timetable-grid");
  const matrixGrid = document.getElementById("matrix-timetable-grid");
  if (!listGrid || !matrixGrid) return;
  listGrid.innerHTML = "";
  matrixGrid.innerHTML = "";

  const dayNames = ["Hétfő", "Kedd", "Szerda", "Csütörtök", "Péntek", "Szombat", "Vasárnap"];
  const dayBuckets = { 1: [], 2: [], 3: [], 4: [], 5: [], 6: [], 7: [] };
  const matrixData = {};
  for (let i = 1; i <= 7; i++) matrixData[i] = {};

  (timetable || []).forEach(item => {
    if (item.KezdetIdopont) {
      let d = new Date(item.KezdetIdopont).getDay();
      if (d === 0) d = 7; // Sunday
      if (d >= 1 && d <= 7) {
        dayBuckets[d].push(item);
        const slot = item.Oraszam || 1;
        matrixData[d][slot] = item;
      }
    }
  });

  // 1) List View (Only Mon-Fri usually, but we can do 1-5 to keep it as before)
  for (let i = 1; i <= 5; i++) {
    const col = document.createElement("div");
    col.className = "timetable-day-card";
    col.innerHTML = `<div class="day-title">${dayNames[i - 1]}</div>`;

    const lessons = dayBuckets[i];
    if (lessons.length === 0) {
      col.innerHTML += `<div style="text-align:center; padding: 24px 0; font-size: 0.75rem; color: var(--text-muted);">Nincs tanóra</div>`;
    } else {
      lessons.forEach((l, idx) => {
        const itemEl = document.createElement("div");
        itemEl.style.padding = "8px 0";
        itemEl.style.borderBottom = "1px solid var(--border)";
        const sub = escapeHtml(getDisplaySubject(l.Tantargy?.Nev || l.Nev || "Tanóra"));
        const room = l.Terem ? `Terem: ${escapeHtml(l.Terem)}` : "";
        const substitute = l.HelyettesitoTanarNeve ? `Helyettesítő: ${escapeHtml(l.HelyettesitoTanarNeve)}` : "";

        let stateHtml = "";
        const stateNameRaw = l.Allapot?.Nev || l.Allapot || "Megtartott";
        const stateName = escapeHtml(stateNameRaw);
        let titleStyle = "";

        if (stateNameRaw !== "Megtartott") {
          let badgeColor = "var(--warning)";
          if (stateNameRaw.toLowerCase().includes("elmaradt")) {
            badgeColor = "var(--danger)";
            titleStyle = "text-decoration: line-through; color: var(--text-muted);";
          }
          stateHtml = `<span style="display:inline-block; margin-top:2px; font-size:0.65rem; color:${badgeColor}; font-weight:700;">${stateName}</span>`;
        }

        const theme = l.Tema ? `<div style="font-size:0.65rem; color:var(--text-muted); margin-top:2px;">${escapeHtml(l.Tema)}</div>` : "";

        itemEl.innerHTML = `
          <div style="font-size:0.8rem; font-weight:700; ${titleStyle}">${l.Oraszam || idx + 1}. ${sub}</div>
          <div style="font-size:0.7rem; color:var(--text-muted);">${room} ${substitute ? ' • ' + substitute : ''}</div>
          ${theme}
          ${stateHtml}
        `;
        col.appendChild(itemEl);
      });
    }
    listGrid.appendChild(col);
  }

  // 2) 7-day Matrix View
  let matrixHtml = `<table style="width: 100%; border-collapse: collapse; min-width: 600px; text-align: center; font-size: 0.75rem;">
    <thead>
      <tr style="border-bottom: 2px solid var(--border);">
        <th style="padding: 8px; width: 40px; color: var(--text-muted);">Óra</th>`;
  for (let i = 1; i <= 7; i++) {
    matrixHtml += `<th style="padding: 8px;">${dayNames[i-1]}</th>`;
  }
  matrixHtml += `</tr></thead><tbody>`;

  for (let slot = 1; slot <= 10; slot++) {
    matrixHtml += `<tr style="border-bottom: 1px solid var(--border);">
      <td style="padding: 8px; font-weight: 700; color: var(--text-muted);">${slot}.</td>`;
    for (let day = 1; day <= 7; day++) {
      const l = matrixData[day][slot];
      if (l) {
        const sub = escapeHtml(getDisplaySubject(l.Tantargy?.Nev || l.Nev || "Tanóra"));
        const room = escapeHtml(l.Terem || "");
        const stateName = l.Allapot?.Nev || l.Allapot || "Megtartott";
        let cellStyle = "padding: 8px; border-left: 1px solid var(--border);";
        let contentStyle = "font-weight: 600;";

        if (stateName.toLowerCase().includes("elmaradt")) {
          cellStyle += " background: rgba(255,69,58,0.1);";
          contentStyle = "text-decoration: line-through; color: var(--danger); font-weight: 600;";
        } else if (stateName !== "Megtartott" || l.HelyettesitoTanarNeve) {
          cellStyle += " background: rgba(255,214,10,0.1);";
          contentStyle += " color: var(--warning);";
        }

        matrixHtml += `<td style="${cellStyle}">
          <div style="${contentStyle}">${sub}</div>
          <div style="font-size: 0.65rem; color: var(--text-muted);">${room}</div>
        </td>`;
      } else {
        matrixHtml += `<td style="padding: 8px; border-left: 1px solid var(--border);"></td>`;
      }
    }
    matrixHtml += `</tr>`;
  }
  matrixHtml += `</tbody></table>`;
  matrixGrid.innerHTML = matrixHtml;
}

function renderAllGradesView(grades, groupAverages = []) {
  const container = document.getElementById("all-grades-grid");
  if (!container) return;
  container.innerHTML = "";

  if (grades.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:40px; color:var(--text-muted);">Nincsenek rögzített érdemjegyek.</div>`;
    return;
  }

  // Class-average lookup, subject name -> OsztalyAtlag, for the comparison line on each card.
  const classAvgBySubject = {};
  (groupAverages || []).forEach(a => {
    const sub = a?.Tantargy?.Nev;
    const val = parseFloat(a?.OsztalyAtlag ?? a?.OsztalyCsoportAtlag ?? a?.Atlag ?? a?.Ertek);
    if (sub && !isNaN(val)) classAvgBySubject[sub] = val;
  });

  // Group by Subject
  const subjectMap = {};
  grades.forEach(g => {
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy";
    if (!subjectMap[sub]) subjectMap[sub] = [];
    subjectMap[sub].push(g);
  });

  Object.keys(subjectMap).sort().forEach(subName => {
    const subGrades = subjectMap[subName].sort((a, b) => {
      const d1 = new Date(a.KeszitesDatuma || a.RogzitesDatuma || a.Datum || 0);
      const d2 = new Date(b.KeszitesDatuma || b.RogzitesDatuma || b.Datum || 0);
      return d1 - d2;
    });

    let sum = 0;
    let weightSum = 0;
    
    // For trend arrow: calculate last 3 vs rest
    let sumLast3 = 0;
    let weightLast3 = 0;
    let sumRest = 0;
    let weightRest = 0;
    
    const validGrades = [];
    subGrades.forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      if (parsed.numericGrade !== null && !parsed.isSummary) {
        validGrades.push({ grade: parsed.numericGrade, weight: parsed.weight, original: g, parsed });
        sum += parsed.numericGrade * parsed.weight;
        weightSum += parsed.weight;
      }
    });
    
    if (weightSum === 0) {
      subGrades.forEach(g => {
        const parsed = KretaApi.parseGrade(g);
        if (parsed.numericGrade !== null) {
          validGrades.push({ grade: parsed.numericGrade, weight: parsed.weight, original: g, parsed });
          sum += parsed.numericGrade * parsed.weight;
          weightSum += parsed.weight;
        }
      });
    }

    const numAvg = weightSum > 0 ? (sum / weightSum) : 0;
    const avg = weightSum > 0 ? numAvg.toFixed(2) : "-";
    const avgColor = numAvg >= 4.5 ? "var(--success)" : (numAvg >= 3.5 ? "var(--info)" : (numAvg >= 2.5 ? "var(--warning)" : "var(--danger)"));

    let trendArrow = "→";
    if (validGrades.length > 3) {
      const last3 = validGrades.slice(-3);
      const rest = validGrades.slice(0, -3);
      last3.forEach(g => { sumLast3 += g.grade * g.weight; weightLast3 += g.weight; });
      rest.forEach(g => { sumRest += g.grade * g.weight; weightRest += g.weight; });
      
      if (weightLast3 > 0 && weightRest > 0) {
        const avgLast3 = sumLast3 / weightLast3;
        const avgRest = sumRest / weightRest;
        if (avgLast3 > avgRest + 0.1) trendArrow = "↑";
        else if (avgLast3 < avgRest - 0.1) trendArrow = "↓";
      }
    }

    let warningHtml = "";
    if (numAvg > 0) {
      const rounded = Math.round(numAvg);
      if (Math.abs(numAvg - rounded) <= 0.3 && numAvg !== rounded) {
        warningHtml = `<span class="badge" style="background: rgba(255,214,10,0.15); color: var(--warning); border: none; font-size: 0.7rem; margin-left: 8px;">Közel a ${rounded}-hez/höz!</span>`;
      }
    }

    // Class-average comparison line, when we have both our own average and the class one.
    let classAvgHtml = "";
    const classAvg = classAvgBySubject[subName];
    if (classAvg !== undefined && numAvg > 0) {
      const delta = numAvg - classAvg;
      const deltaColor = delta > 0.05 ? "var(--success)" : (delta < -0.05 ? "var(--danger)" : "var(--text-muted)");
      const deltaText = delta > 0.05 ? `+${delta.toFixed(2)}` : (delta < -0.05 ? delta.toFixed(2) : "±0.00");
      classAvgHtml = `
        <div style="font-size:0.75rem; color:var(--text-muted); margin-top:4px;">
          Osztályátlag: <strong style="color:var(--text);">${classAvg.toFixed(2)}</strong>
          <span style="color:${deltaColor}; font-weight:700; margin-left:4px;">(${deltaText})</span>
        </div>`;
    }

    const card = document.createElement("div");
    card.className = "card";
    card.style.marginBottom = "14px";

    let badgesHtml = "";
    subGrades.forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      badgesHtml += `<div class="grade-badge ${parsed.badgeClass}" style="height:28px; font-size:0.8rem;" title="${escapeHtml(g.Tema || '')} (${parsed.weightPercent}%)">${parsed.displayValue}</div>`;
    });

    const sparklineHtml = createSparklineSvg(validGrades);

    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
        <div style="display:flex; align-items:center; flex-wrap: wrap;">
          <strong style="font-size:0.95rem;">${escapeHtml(getDisplaySubject(subName))}</strong>
          <span style="font-size:0.75rem; color:var(--text-muted); margin-left:8px;">${subGrades.length} jegy</span>
          ${warningHtml}
        </div>
        <div style="text-align: right;">
          <div style="display:flex; align-items:center; gap: 8px; justify-content: flex-end;">
            <span style="font-size:1.1rem; color:var(--text-muted);">${trendArrow}</span>
            <div style="font-size:1.1rem; font-weight:900; padding: 4px 10px; border-radius: 8px; background: ${avgColor}20; color: ${avgColor};">${avg}</div>
          </div>
          ${classAvgHtml}
        </div>
      </div>
      <div style="display:flex; gap:6px; flex-wrap:wrap;">
        ${badgesHtml}
      </div>
      ${sparklineHtml}
    `;
    container.appendChild(card);
  });
}

function createSparklineSvg(validGrades) {
  if (!validGrades || validGrades.length === 0) return "";
  
  if (validGrades.length === 1) {
    const g = validGrades[0].grade;
    const y = 45 - ((g - 1) / 4) * 30 - 6;
    let dotColor = "var(--primary)";
    if (g >= 5) dotColor = "var(--success)";
    else if (g === 4) dotColor = "var(--info)";
    else if (g === 3) dotColor = "var(--warning)";
    else if (g <= 2) dotColor = "var(--danger)";

    return `
      <div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid rgba(255,255,255,0.06);">
        <div style="font-size:0.7rem; color:var(--text-muted); margin-bottom:4px; display:flex; justify-content:space-between;">
          <span>Időbeli alakulás</span>
          <span>1 jegy</span>
        </div>
        <svg viewBox="0 0 240 45" style="width:100%; height:36px; overflow:visible; display:block;">
          <line x1="12" y1="${y.toFixed(1)}" x2="228" y2="${y.toFixed(1)}" stroke="rgba(255,255,255,0.08)" stroke-dasharray="3,3" stroke-width="1"/>
          <circle cx="120" cy="${y.toFixed(1)}" r="4.5" fill="${dotColor}" stroke="var(--card)" stroke-width="1.5">
            <title>${g}</title>
          </circle>
          <text x="120" y="${(y - 6).toFixed(1)}" font-size="9" fill="var(--text)" text-anchor="middle" font-weight="800">${g}</text>
        </svg>
      </div>`;
  }

  const width = 260;
  const height = 50;
  const padX = 14;
  const padY = 8;
  const plotW = width - padX * 2;
  const plotH = height - padY * 2;

  const pts = validGrades.map((item, idx) => {
    const x = padX + (idx / (validGrades.length - 1)) * plotW;
    const y = padY + plotH * (1 - (item.grade - 1) / 4);
    const dStr = (item.original?.KeszitesDatuma || item.original?.RogzitesDatuma || item.original?.Datum || "").split("T")[0];
    return { x, y, grade: item.grade, date: dStr, theme: item.original?.Tema || "" };
  });

  const pathD = pts.map((p, idx) => `${idx === 0 ? "M" : "L"} ${p.x.toFixed(1)} ${p.y.toFixed(1)}`).join(" ");
  const areaD = `${pathD} L ${pts[pts.length - 1].x.toFixed(1)} ${height} L ${pts[0].x.toFixed(1)} ${height} Z`;

  let circlesSvg = "";
  pts.forEach(p => {
    let cColor = "var(--primary)";
    if (p.grade >= 5) cColor = "var(--success)";
    else if (p.grade === 4) cColor = "var(--info)";
    else if (p.grade === 3) cColor = "var(--warning)";
    else if (p.grade <= 2) cColor = "var(--danger)";

    circlesSvg += `
      <circle cx="${p.x.toFixed(1)}" cy="${p.y.toFixed(1)}" r="3.5" fill="${cColor}" stroke="var(--card)" stroke-width="1.5">
        <title>${p.grade} (${p.date}${p.theme ? ' - ' + p.theme : ''})</title>
      </circle>`;
  });

  const gradId = `spark-grad-${Math.random().toString(36).substr(2, 7)}`;
  const startDate = pts[0].date;
  const endDate = pts[pts.length - 1].date;
  const dateRangeStr = (startDate && endDate) ? `${startDate} → ${endDate}` : `${validGrades.length} jegy`;

  return `
    <div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid rgba(255,255,255,0.06);">
      <div style="font-size:0.7rem; color:var(--text-muted); margin-bottom:4px; display:flex; justify-content:space-between;">
        <span>Időbeli alakulás (${dateRangeStr})</span>
        <span style="font-weight:600;">${validGrades.length} jegy</span>
      </div>
      <svg viewBox="0 0 ${width} ${height}" style="width:100%; height:44px; overflow:visible; display:block;">
        <defs>
          <linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="var(--primary)" stop-opacity="0.32"/>
            <stop offset="100%" stop-color="var(--primary)" stop-opacity="0.0"/>
          </linearGradient>
        </defs>
        <!-- Horizontal grid guides -->
        <line x1="${padX}" y1="${padY}" x2="${width - padX}" y2="${padY}" stroke="rgba(255,255,255,0.06)" stroke-dasharray="2,2" stroke-width="1"/>
        <line x1="${padX}" y1="${(padY + plotH / 2).toFixed(1)}" x2="${width - padX}" y2="${(padY + plotH / 2).toFixed(1)}" stroke="rgba(255,255,255,0.06)" stroke-dasharray="2,2" stroke-width="1"/>
        <line x1="${padX}" y1="${(padY + plotH).toFixed(1)}" x2="${width - padX}" y2="${(padY + plotH).toFixed(1)}" stroke="rgba(255,255,255,0.06)" stroke-dasharray="2,2" stroke-width="1"/>
        
        <path d="${areaD}" fill="url(#${gradId})"/>
        <path d="${pathD}" fill="none" stroke="var(--primary)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        ${circlesSvg}
      </svg>
    </div>`;
}

function renderTasksView(homework, exams) {
  const container = document.getElementById("tasks-full-list");
  if (!container) return;
  container.innerHTML = "";

  const items = [
    ...exams.map(e => ({ type: "exam", sub: escapeHtml(getDisplaySubject(e.Tantargy?.Nev || e.Tantargy || "Dolgozat")), title: escapeHtml(e.Tema || e.Tipus?.Leiras || "Számonkérés"), date: e.Datum })),
    ...homework.map(h => ({ type: "hw", sub: escapeHtml(getDisplaySubject(h.Tantargy?.Nev || h.Tantargy || "Házi feladat")), title: escapeHtml(h.Szoveg || h.Feladat || "Házi feladat"), date: h.HataridoDatuma || h.HataridoIdopontja || h.Hatarido }))
  ];

  if (items.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:40px; color:var(--text-muted);">Nincs közelgő házi feladat vagy bejelentett dolgozat.</div>`;
    return;
  }

  items.forEach(it => {
    const isExam = it.type === "exam";
    const tag = isExam ? `<span style="color:var(--danger); font-weight:800; font-size:0.7rem;">DOLGOZAT</span>` : `<span style="color:var(--info); font-weight:800; font-size:0.7rem;">HÁZI</span>`;

    let dateText = "";
    if (it.date) {
      const d = new Date(it.date);
      dateText = `Határidő: ${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}.`;
    }

    const card = document.createElement("div");
    card.className = "card";
    card.style.marginBottom = "10px";
    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:4px;">
        <div>${tag} <strong style="margin-left:6px; font-size:0.9rem;">${it.sub}</strong></div>
        <span style="font-size:0.72rem; color:var(--text-muted);">${dateText}</span>
      </div>
      <div style="font-size:0.8rem; color:var(--text); margin-top:4px;">${it.title}</div>
    `;
    container.appendChild(card);
  });
}

function renderAbsencesView(absences) {
  const container = document.getElementById("absences-full-list");
  if (!container) return;
  container.innerHTML = "";

  const totalHours = (absences || []).length;
  const pct = Math.min(100, (totalHours / 250) * 100);

  const hoursEl = document.getElementById("absences-total-hours");
  if (hoursEl) hoursEl.innerText = `${totalHours} óra`;

  const statusEl = document.getElementById("absences-zone-status");
  const barEl = document.getElementById("absences-progress-bar");

  if (statusEl) {
    if (totalHours < 150) {
      statusEl.innerText = `Biztonságos (${pct.toFixed(1)}%)`;
      statusEl.style.color = "var(--success)";
    } else if (totalHours < 220) {
      statusEl.innerText = `Közelít a limithez (${pct.toFixed(1)}%)`;
      statusEl.style.color = "var(--warning)";
    } else {
      statusEl.innerText = `VESZÉLYZÓNA! (${pct.toFixed(1)}%)`;
      statusEl.style.color = "var(--danger)";
    }
  }

  if (barEl) {
    barEl.style.width = `${pct}%`;
    barEl.style.background = totalHours < 150 ? "var(--success)" : (totalHours < 220 ? "var(--warning)" : "var(--danger)");
  }

  let unexcusedCount = 0;
  let delayMinutes = 0;
  let parentalCount = 0;

  (absences || []).forEach(a => {
    const status = (a.IgazolasAllapota || "").toLowerCase();
    if (!status.includes("igazolt") && a.KesesPercben === 0) {
      unexcusedCount++;
    }
    if (a.KesesPercben && a.KesesPercben > 0) {
      delayMinutes += a.KesesPercben;
    }
    const typeStr = (a.Tipus?.Leiras || a.Tipus || "").toLowerCase();
    if (typeStr.includes("szülői") || typeStr.includes("szuloi")) {
      parentalCount++;
    }
  });

  const unexcusedEl = document.getElementById("absences-unexcused-count");
  if (unexcusedEl) unexcusedEl.innerText = `${unexcusedCount}`;
  
  const delayEl = document.getElementById("absences-delay-minutes");
  if (delayEl) delayEl.innerText = `${delayMinutes} perc`;

  chrome.storage.local.get("pala_parental_limit").then(res => {
    const limit = res.pala_parental_limit || 3;
    // calculate lessons per day approximation if needed? The prompt says "use lesson count" but also "Default limit is 3 days (720 minutes or ~21 lessons, but use lesson count). Show X / 3 szülői igazolás felhasználva" Wait, "limit is 3 days" but the UI says "0 / 3 nap".
    // If the tracker is by *days*, how to convert lesson count to days?
    // "count absences where Tipus includes 'Szülői'. Default limit is 3 days, but use lesson count."
    // Let's assume it means "limit is 3 days" and one day is approx 7 lessons. So limit in lessons = 3 * 7 = 21.
    // Let's use parentalCount directly if it says "use lesson count". But the UI string was "0 / 3 nap".
    // Actually, prompt says "Default limit is 3 days... but use lesson count. Show "X / 3 szülői igazolás felhasználva"".
    // So if limit = 3, show `parentalCount / limit szülői igazolás felhasználva`? No, "X / 3". Wait, maybe it means parentalCount / 3 szülői igazolás (like each absence is 1 igazolás? No).
    // Let's divide by 7 to show days? Let's just show `parentalCount` and `limit * 7` as lessons, OR `parentalCount / (limit * 7)`.
    // Let's make it simple: "parentalCount tanóra / limit*7 tanóra felhasználva" or just limit the progress bar.
    
    // I will show: `${parentalCount} óra / ${limit * 7} óra`
    const maxLessons = limit * 7;
    const parentStatus = document.getElementById("absences-parental-status");
    if (parentStatus) parentStatus.innerText = `${parentalCount} / ${maxLessons} óra`;
    
    const parentBar = document.getElementById("absences-parental-bar");
    if (parentBar) {
      const pPct = Math.min(100, (parentalCount / maxLessons) * 100);
      parentBar.style.width = `${pPct}%`;
      parentBar.style.background = pPct < 70 ? "var(--primary)" : (pPct < 90 ? "var(--warning)" : "var(--danger)");
    }
  });

  if (!absences || absences.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:40px; color:var(--text-muted);">Nincs rögzített mulasztás.</div>`;
    return;
  }

  // Count absences per subject to identify >= 20% course absence risk
  const subAbsenceCounts = {};
  absences.forEach(a => {
    const raw = a.Tantargy?.Nev || a.Tantargy || "Tanóra";
    subAbsenceCounts[raw] = (subAbsenceCounts[raw] || 0) + 1;
  });

  const highRiskSubjects = Object.entries(subAbsenceCounts)
    .filter(([_, count]) => count >= 15)
    .map(([sub, count]) => `${escapeHtml(getDisplaySubject(sub))} (${count} óra)`);

  if (highRiskSubjects.length > 0) {
    const riskBanner = document.createElement("div");
    riskBanner.style.cssText = "background: rgba(255,69,58,0.1); border: 1px solid rgba(255,69,58,0.3); border-radius: 8px; padding: 10px 14px; margin-bottom: 12px; font-size: 0.78rem; color: var(--danger); line-height: 1.4;";
    riskBanner.innerHTML = `<strong>Figyelem!</strong> Az alábbi tantárgy(ak)ból a hiányzások elérték a 20%-os kritikus határt: <strong>${highRiskSubjects.join(", ")}</strong>. (Osztályozó vizsga kockázat!)`;
    container.appendChild(riskBanner);
  }

  absences.forEach(a => {
    const rawSub = a.Tantargy?.Nev || a.Tantargy || "Tanóra";
    const sub = escapeHtml(getDisplaySubject(rawSub));
    const totalInSub = subAbsenceCounts[rawSub] || 0;
    const riskBadge = totalInSub >= 15
      ? `<span class="badge" style="background:rgba(255,69,58,0.15); color:var(--danger); border:1px solid rgba(255,69,58,0.3); font-size:0.68rem; margin-left:6px;" title="${totalInSub} óra mulasztás ebből a tárgyból">20% kockázat</span>`
      : "";

    const statusRaw = a.IgazolasAllapota || "Igazolatlan";
    const status = escapeHtml(statusRaw);
    const type = escapeHtml(a.Tipus?.Leiras || a.Tipus || "Mulasztás");
    const isJustified = statusRaw.toLowerCase().includes("igazolt");

    let dateText = "";
    const dateRaw = a.Datum || a.OraKezdete;
    if (dateRaw) {
      const d = new Date(dateRaw);
      dateText = `${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}.`;
    }

    const row = document.createElement("div");
    row.className = "table-row";
    row.innerHTML = `
      <div>
        <div style="display:flex; align-items:center;">
          <strong style="font-size:0.88rem;">${sub}</strong>
          ${riskBadge}
        </div>
        <div style="font-size:0.72rem; color:var(--text-muted);">${type} • ${dateText}</div>
      </div>
      <span class="badge" style="color: ${isJustified ? 'var(--success)' : 'var(--danger)'}; border-color: ${isJustified ? 'rgba(48,209,88,0.3)' : 'rgba(255,69,58,0.3)'}">
        ${status}
      </span>
    `;
    container.appendChild(row);
  });
}

let currentMessageFilter = "all";

function setupMessageFilters() {
  const chips = [
    { id: "filter-msg-all", filter: "all" },
    { id: "filter-msg-inbox", filter: "inbox" },
    { id: "filter-msg-questionnaires", filter: "questionnaires" },
    { id: "filter-msg-notes", filter: "notes" }
  ];

  chips.forEach(c => {
    const btn = document.getElementById(c.id);
    if (!btn) return;
    btn.addEventListener("click", (e) => {
      e.stopPropagation();
      chips.forEach(x => document.getElementById(x.id)?.classList.remove("active"));
      btn.classList.add("active");
      currentMessageFilter = c.filter;

      const msgs = Array.isArray(fullState.data?.messages) ? fullState.data.messages : [];
      const quests = Array.isArray(fullState.data?.questionnaires) ? fullState.data.questionnaires : [];

      renderMessagesView(msgs, quests);
    });
  });
}

function setupMessageModals() {
  const composerModal = document.getElementById("msg-composer-modal");
  const viewerModal = document.getElementById("msg-viewer-modal");
  const compSelect = document.getElementById("comp-teacher-select");
  const compSubj = document.getElementById("comp-subject-input");
  const compText = document.getElementById("comp-text-input");
  const compFeedback = document.getElementById("comp-feedback-box");

  // Sync directly from active e-Ügyintézés tab
  document.getElementById("btn-sync-active-tab")?.addEventListener("click", async () => {
    const syncBtn = document.getElementById("btn-sync-active-tab");
    if (syncBtn) {
      syncBtn.disabled = true;
      syncBtn.innerText = "Szinkronizálás...";
    }
    try {
      const result = await KretaApi.fetchFromActiveWebTab();
      if (result && (result.messages || result.questionnaires || result.teachers)) {
        if (!fullState.data) fullState.data = {};
        if (Array.isArray(result.messages)) fullState.data.messages = result.messages;
        if (Array.isArray(result.questionnaires)) fullState.data.questionnaires = result.questionnaires;
        if (Array.isArray(result.teachers)) fullState.data.teachers = result.teachers;
        await chrome.storage.local.set({ pala_cached_data: fullState.data });
        renderMessagesView(fullState.data.messages || [], fullState.data.questionnaires || []);
        alert(`Sikeres szinkronizálás az e-Ügyintézés felületéről!\nBeérkezett üzenetek: ${result.messages?.length || 0} db\nKérdőívek: ${result.questionnaires?.length || 0} db`);
      } else {
        alert("Nem sikerült elérni a nyitott e-Ügyintézés fület.\n\nKérlek ellenőrizd:\n1. A böngésződben meg van-e nyitva a https://eugyintezes.e-kreta.hu oldal, és be vagy-e jelentkezve.\n2. A bővítmény frissítve lett-e a brave://extensions oldalon az új jogosultságok miatt!");
      }
    } catch (err) {
      alert("Hiba a szinkronizálás során: " + err.message);
    } finally {
      if (syncBtn) {
        syncBtn.disabled = false;
        syncBtn.innerText = "Szinkronizálás e-Ügyintézésből";
      }
    }
  });

  // Refresh messages
  document.getElementById("btn-refresh-messages")?.addEventListener("click", async () => {
    await loadDashboardData(true);
  });

  // Open Composer
  document.getElementById("btn-open-composer")?.addEventListener("click", () => {
    openComposer();
  });

  document.getElementById("btn-close-composer")?.addEventListener("click", () => {
    if (composerModal) composerModal.style.display = "none";
  });
  document.getElementById("btn-cancel-composer")?.addEventListener("click", () => {
    if (composerModal) composerModal.style.display = "none";
  });

  // Send message submit
  document.getElementById("btn-send-message-submit")?.addEventListener("click", async () => {
    const teacherId = compSelect?.value;
    const subject = compSubj?.value.trim();
    const text = compText?.value.trim();

    if (!teacherId || !subject || !text) {
      if (compFeedback) {
        compFeedback.innerText = "Kérlek válassz címzett tanárt, és töltsd ki a tárgyat és az üzenetet!";
        compFeedback.style.display = "block";
        compFeedback.style.background = "rgba(255,69,58,0.15)";
        compFeedback.style.color = "var(--danger)";
        compFeedback.style.border = "1px solid rgba(255,69,58,0.3)";
      }
      return;
    }

    try {
      if (compFeedback) {
        compFeedback.innerText = "Üzenet küldése a Kréta e-Ügyintézés rendszerébe...";
        compFeedback.style.display = "block";
        compFeedback.style.background = "rgba(255,136,0,0.15)";
        compFeedback.style.color = "var(--primary)";
        compFeedback.style.border = "1px solid rgba(255,136,0,0.3)";
      }

      const session = await SecureSession.load();
      if (fullState.isDemo || !session?.token) {
        // Demo mode send simulation
        await new Promise(r => setTimeout(r, 600));
        const teacherName = compSelect.options[compSelect.selectedIndex]?.text || "Tanár";
        if (!fullState.data.messages) fullState.data.messages = [];
        fullState.data.messages.unshift({
          id: "sent-" + Date.now(),
          type: "Elküldött üzenet",
          sender: `Neked ➔ ${teacherName}`,
          title: subject,
          content: text,
          date: new Date().toISOString(),
          source: "eugyintezes"
        });
      } else {
        const token = await KretaApi.ensureValidToken(session);
        await KretaApi.sendMessage(token, subject, text, [parseInt(teacherId, 10)]);
        const teacherName = compSelect.options[compSelect.selectedIndex]?.text || "Tanár";
        if (!fullState.data.messages) fullState.data.messages = [];
        fullState.data.messages.unshift({
          id: "sent-" + Date.now(),
          type: "Elküldött üzenet",
          sender: `Címzett: ${teacherName}`,
          title: subject,
          content: text,
          date: new Date().toISOString(),
          source: "eugyintezes"
        });
      }

      if (compFeedback) {
        compFeedback.innerText = "Üzenet sikeresen elküldve!";
        compFeedback.style.background = "rgba(48,209,88,0.15)";
        compFeedback.style.color = "var(--success)";
        compFeedback.style.border = "1px solid rgba(48,209,88,0.3)";
      }

      setTimeout(() => {
        if (composerModal) composerModal.style.display = "none";
        renderMessagesView(fullState.data?.messages || [], fullState.data?.questionnaires || []);
      }, 1000);
    } catch (e) {
      if (compFeedback) {
        compFeedback.innerText = e.message || "Hiba az üzenet küldésekor.";
        compFeedback.style.background = "rgba(255,69,58,0.15)";
        compFeedback.style.color = "var(--danger)";
        compFeedback.style.border = "1px solid rgba(255,69,58,0.3)";
      }
    }
  });

  // Viewer close
  document.getElementById("btn-close-viewer")?.addEventListener("click", () => {
    if (viewerModal) viewerModal.style.display = "none";
  });
  document.getElementById("btn-dismiss-viewer")?.addEventListener("click", () => {
    if (viewerModal) viewerModal.style.display = "none";
  });

  // Reply from viewer
  document.getElementById("btn-reply-composer")?.addEventListener("click", () => {
    const origTitle = document.getElementById("viewer-msg-title")?.innerText || "";
    const origSender = document.getElementById("viewer-msg-sender")?.innerText || "";
    const origBody = document.getElementById("viewer-msg-content")?.innerText || "";
    if (viewerModal) viewerModal.style.display = "none";
    openComposer("Re: " + origTitle, `\n\n--- Eredeti üzenet (${origSender}) ---\n${origBody}`);
  });
}

function openComposer(initialSubject = "", initialText = "") {
  const composerModal = document.getElementById("msg-composer-modal");
  const compSelect = document.getElementById("comp-teacher-select");
  const compSubj = document.getElementById("comp-subject-input");
  const compText = document.getElementById("comp-text-input");
  const compFeedback = document.getElementById("comp-feedback-box");

  if (compFeedback) compFeedback.style.display = "none";
  if (compSubj) compSubj.value = initialSubject;
  if (compText) compText.value = initialText;

  if (compSelect) {
    compSelect.innerHTML = '<option value="">-- Válassz címzett tanárt --</option>';
    const teachers = fullState.data?.teachers || [];
    if (teachers.length === 0) {
      compSelect.innerHTML += '<option value="1">Iskolavezetés / Tanári kar</option>';
    } else {
      teachers.forEach(t => {
        const subStr = (t.subjects && t.subjects.length > 0) ? ` (${escapeHtml(t.subjects.join(", "))})` : "";
        compSelect.innerHTML += `<option value="${t.id}">${escapeHtml(t.name)}${subStr}</option>`;
      });
    }
  }

  if (composerModal) composerModal.style.display = "flex";
}

function renderMessagesView(messages, questionnaires) {
  const container = document.getElementById("messages-list-container");
  if (!container) return;
  container.innerHTML = "";

  const allMsgs = Array.isArray(messages) ? messages : [];
  const allQuests = Array.isArray(questionnaires) ? questionnaires : [];

  if (currentMessageFilter === "questionnaires") {
    if (allQuests.length === 0) {
      container.innerHTML = `
        <div style="text-align:center; padding:40px; color:var(--text-muted);">
          <div style="font-size:1rem; font-weight:700; margin-bottom:8px;">Nincs jelenleg aktív kérdőív vagy adatbekérés.</div>
          <div style="font-size:0.82rem; margin-bottom:16px;">Az intézmény által kiküldött hivatalos adatbekéréseket közvetlenül az e-Ügyintézés felületén is megtekintheted.</div>
          <a href="https://eugyintezes.e-kreta.hu/adatbekeresek" target="_blank" class="btn btn-primary" style="text-decoration:none; display:inline-block;">Kérdőívek megnyitása (e-Ügyintézés) ↗</a>
        </div>
      `;
      return;
    }

    const tableWrapper = document.createElement("div");
    tableWrapper.className = "table-container";
    tableWrapper.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; flex-wrap:wrap; gap:8px;">
        <span style="font-size:0.85rem; font-weight:700; color:var(--text);">Kitöltendő és lezárt kérdőívek (${allQuests.length})</span>
        <a href="https://eugyintezes.e-kreta.hu/adatbekeresek" target="_blank" class="btn btn-secondary btn-sm" style="text-decoration:none; font-size:0.75rem;">Kérdőívek megnyitása a Krétán ↗</a>
      </div>
      <table class="data-table" style="width:100%; border-collapse:collapse;">
        <thead>
          <tr style="border-bottom:1px solid var(--border); text-align:left; font-size:0.78rem; color:var(--text-muted);">
            <th style="padding:10px 12px;">Kérdőív neve</th>
            <th style="padding:10px 12px;">Státusz</th>
            <th style="padding:10px 12px;">Feladó</th>
            <th style="padding:10px 12px;">Határidő</th>
            <th style="padding:10px 12px;">Visszajelzés</th>
            <th style="padding:10px 12px; text-align:right;">Művelet</th>
          </tr>
        </thead>
        <tbody id="questionnaires-table-body">
        </tbody>
      </table>
    `;

    const tbody = tableWrapper.querySelector("#questionnaires-table-body");
    allQuests.forEach(q => {
      const tr = document.createElement("tr");
      tr.style.borderBottom = "1px solid var(--border)";
      tr.style.fontSize = "0.84rem";

      const isCompleted = !!q.feedback;
      const statusBadge = isCompleted
        ? `<span class="badge" style="background:rgba(48,209,88,0.15); color:var(--success); border-color:rgba(48,209,88,0.35);">Kitöltve</span>`
        : `<span class="badge" style="background:rgba(255,69,58,0.15); color:var(--danger); border-color:rgba(255,69,58,0.35);">${escapeHtml(q.status || "Kiküldve")}</span>`;

      const feedbackCell = isCompleted
        ? `<span style="color:var(--success); font-size:0.78rem;">[Kitöltve] ${escapeHtml(q.feedback)}</span>`
        : `<span style="color:var(--text-muted); font-size:0.78rem;">-</span>`;

      tr.innerHTML = `
        <td style="padding:10px 12px; font-weight:700; color:var(--text);">${escapeHtml(q.title || "Adatbekérés")}</td>
        <td style="padding:10px 12px;">${statusBadge}</td>
        <td style="padding:10px 12px; color:var(--text-muted);">${escapeHtml(q.sender || "Iskola")}</td>
        <td style="padding:10px 12px; color:var(--text-muted);">${escapeHtml(q.deadline || "-")}</td>
        <td style="padding:10px 12px;">${feedbackCell}</td>
        <td style="padding:10px 12px; text-align:right;">
          <a href="https://eugyintezes.e-kreta.hu/adatbekeresek" target="_blank" class="btn btn-secondary btn-sm" style="text-decoration:none; font-size:0.74rem;">Kitöltés (Web)</a>
        </td>
      `;
      tbody.appendChild(tr);
    });

    container.appendChild(tableWrapper);
    return;
  }

  let displayList = allMsgs;
  if (currentMessageFilter === "inbox") {
    displayList = allMsgs.filter(m => m.source === "eugyintezes" || m.type === "e-Ügyintézés" || m.type === "Beérkezett üzenet" || m.type === "Elküldött üzenet");
  } else if (currentMessageFilter === "notes") {
    displayList = allMsgs.filter(m => m.source !== "eugyintezes" && m.type !== "e-Ügyintézés" && m.type !== "Beérkezett üzenet" && m.type !== "Elküldött üzenet");
  }

  if (displayList.length === 0) {
    let emptyTitle = "Nincsenek beérkezett üzenetek a Kréta postaládádban.";
    if (currentMessageFilter === "notes") {
      emptyTitle = "Nincsenek tanári feljegyzések vagy faliújság hirdetmények.";
    } else if (currentMessageFilter === "inbox") {
      emptyTitle = "Nincsenek hivatalos e-Ügyintézés postaláda üzenetek.";
    }

    container.innerHTML = `
      <div style="text-align:center; padding:40px 20px; color:var(--text-muted); max-width:540px; margin:0 auto;">
        <div style="font-size:1.05rem; font-weight:700; color:var(--text); margin-bottom:8px;">${emptyTitle}</div>
        <div style="font-size:0.84rem; margin-bottom:20px; line-height:1.5;">
          A Kréta e-Ügyintézés közvetlen szinkronizálásához nyisd meg a <strong>https://eugyintezes.e-kreta.hu</strong> oldalt a böngésződben, majd kattints az alábbi gombra az élő adatok átvételéhez!
        </div>
        <div style="display:flex; gap:10px; justify-content:center; flex-wrap:wrap;">
          <button class="btn btn-primary" onclick="document.getElementById('btn-sync-active-tab')?.click()">Szinkronizálás az e-Ügyintézésből</button>
          <button class="btn btn-secondary" onclick="document.getElementById('btn-open-composer')?.click()">+ Új üzenet írása</button>
          <a href="https://eugyintezes.e-kreta.hu/uzenetek" target="_blank" class="btn btn-secondary" style="text-decoration:none; display:inline-block;">e-Ügyintézés Megnyitása (Web)</a>
        </div>
      </div>
    `;
    return;
  }

  displayList.forEach(m => {
    const card = document.createElement("div");
    card.className = "message-card";
    card.style.cursor = "pointer";
    card.title = "Kattints az üzenet megnyitásához";

    let badgeClass = "message-type-default";
    const typeLower = (m.type || "").toLowerCase();
    if (typeLower.includes("dicséret") || typeLower.includes("dicseret")) {
      badgeClass = "message-type-dicseret";
    } else if (typeLower.includes("figyelmeztet") || typeLower.includes("intő") || typeLower.includes("megrovás")) {
      badgeClass = "message-type-figyelmeztetes";
    } else if (typeLower.includes("hirdetmény") || typeLower.includes("hirdetmeny")) {
      badgeClass = "message-type-hirdetmeny";
    } else if (m.source === "eugyintezes") {
      badgeClass = "message-type-hirdetmeny";
    }

    let dateText = "";
    if (m.date) {
      const d = new Date(m.date);
      dateText = `${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}. ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
    }

    const unreadDot = m.isRead === false ? `<span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:var(--primary); margin-right:6px;"></span>` : "";

    card.innerHTML = `
      <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px; flex-wrap: wrap; gap: 6px;">
        <div style="display: flex; align-items: center; gap: 8px;">
          ${unreadDot}
          <span class="badge ${badgeClass}">${escapeHtml(m.type || "Üzenet")}</span>
          <strong style="font-size: 0.88rem;">${escapeHtml(m.sender || "Iskola")}</strong>
        </div>
        <span style="font-size: 0.75rem; color: var(--text-muted);">${dateText}</span>
      </div>
      <h3 style="font-size: 1rem; font-weight: 800; margin-bottom: 6px; color: var(--text);">${escapeHtml(m.title || m.subject || "Tájékoztató")}</h3>
      <p style="font-size: 0.84rem; line-height: 1.5; color: var(--text-muted); margin: 0; white-space: pre-line; max-height: 48px; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(m.content || "(Kattints a részletek megtekintéséhez)")}</p>
    `;

    card.addEventListener("click", () => {
      openMessageViewer(m);
    });

    container.appendChild(card);
  });
}

async function openMessageViewer(msg) {
  const viewerModal = document.getElementById("msg-viewer-modal");
  const titleEl = document.getElementById("viewer-msg-title");
  const senderEl = document.getElementById("viewer-msg-sender");
  const dateEl = document.getElementById("viewer-msg-date");
  const contentEl = document.getElementById("viewer-msg-content");
  const badgeEl = document.getElementById("viewer-msg-type-badge");
  const attachBox = document.getElementById("viewer-attachments-box");
  const attachList = document.getElementById("viewer-attachments-list");

  if (titleEl) titleEl.innerText = msg.title || msg.subject || "Üzenet";
  if (senderEl) senderEl.innerText = msg.sender || "Ismeretlen feladó";
  if (dateEl) {
    const d = msg.date ? new Date(msg.date) : new Date();
    dateEl.innerText = `${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}. ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
  }
  if (badgeEl) badgeEl.innerText = msg.type || "e-Ügyintézés";

  if (contentEl) {
    contentEl.innerText = msg.content || "Szövegtartalom betöltése...";
  }

  // If content is empty and it's an e-ugyintezes message, fetch full content
  if (!msg.content && msg.source === "eugyintezes" && msg.id) {
    const session = await SecureSession.load();
    if (session?.token) {
      const token = await KretaApi.ensureValidToken(session);
      const fullText = await KretaApi.getMessageContent(token, msg.id);
      if (fullText && contentEl) {
        contentEl.innerText = fullText;
        msg.content = fullText;
      }
    }
  }

  // Attachments
  if (attachBox && attachList) {
    const atts = msg.attachments || [];
    if (atts.length > 0) {
      attachBox.style.display = "block";
      attachList.innerHTML = atts.map(a => `<span class="badge" style="background:var(--sidebar);">${escapeHtml(a.fajlNev || a.name || "Csatolmány")}</span>`).join("");
    } else {
      attachBox.style.display = "none";
      attachList.innerHTML = "";
    }
  }

  if (viewerModal) viewerModal.style.display = "flex";
}

async function renderSettingsView() {
  const store = await chrome.storage.local.get([
    "pala_session",
    "pala_use_demo",
    "pala_last_fetch",
    "pala_maintenance_mode",
    "pala_simulate_maintenance"
  ]);

  const userEl = document.getElementById("dash-settings-user");
  const instEl = document.getElementById("dash-settings-inst");
  const statusEl = document.getElementById("dash-settings-status");
  const timeEl = document.getElementById("dash-settings-cache-time");

  const student = fullState.data?.student;
  if (userEl) userEl.innerText = student?.Nev || (fullState.isDemo ? "Teszt Elek (Demó)" : store.pala_session?.user || "-");
  if (instEl) instEl.innerText = student?.IntezmenyNev || student?.Intezmeny?.TeljesNev || (fullState.isDemo ? "Pala Minta Gimnázium" : store.pala_session?.institute || "-");

  if (statusEl) {
    if (fullState.isMaintenance) {
      statusEl.className = "badge badge-maintenance";
      statusEl.innerText = "Karbantartás (503)";
    } else if (fullState.isDemo) {
      statusEl.className = "badge badge-demo";
      statusEl.innerText = "Demó Mód";
    } else {
      statusEl.className = "badge";
      statusEl.style.color = "var(--success)";
      statusEl.style.borderColor = "rgba(48,209,88,0.4)";
      statusEl.innerText = "Online • Hitelesített";
    }
  }

  if (timeEl) {
    if (store.pala_last_fetch) {
      const dt = new Date(store.pala_last_fetch);
      timeEl.innerText = `${dt.getFullYear()}. ${dt.getMonth() + 1}. ${dt.getDate()}. ${String(dt.getHours()).padStart(2, "0")}:${String(dt.getMinutes()).padStart(2, "0")}`;
    } else {
      timeEl.innerText = "Nincs rögzítve";
    }
  }

  const instInput = document.getElementById("dash-login-institute");
  if (instInput && !instInput.value && store.pala_session?.institute) {
    instInput.value = store.pala_session.institute;
  }
  
  chrome.storage.local.get(["pala_parental_limit", "pala_popup_settings"]).then(res => {
    const lim = document.getElementById("settings-parental-limit");
    if (lim) lim.value = res.pala_parental_limit || 3;

    const s = res.pala_popup_settings || {};
    const tabEl = document.getElementById("dash-popup-pref-default-tab");
    if (tabEl) tabEl.value = s.defaultTab || "tab-today";

    const heroEl = document.getElementById("dash-popup-pref-show-hero");
    if (heroEl) heroEl.checked = s.showHeroCard !== false;

    const compactEl = document.getElementById("dash-popup-pref-compact");
    if (compactEl) compactEl.checked = s.compactMode === true;

    const avgEl = document.getElementById("dash-popup-pref-show-average");
    if (avgEl) avgEl.checked = s.showAverageBar !== false;

    const maxGradesEl = document.getElementById("dash-popup-pref-max-grades");
    if (maxGradesEl) maxGradesEl.value = String(s.maxGrades ?? 10);

    const maxTasksEl = document.getElementById("dash-popup-pref-max-tasks");
    if (maxTasksEl) maxTasksEl.value = String(s.maxTasks ?? 5);

    renderAliases();
    populateAliasDatalist();
    ensureTeachersLoaded();
  });
}

async function renderStudentView(student) {
  const container = document.getElementById("student-profile-container");
  if (!container) return;
  container.innerHTML = "";
  if (!student) {
    container.innerHTML = `<div style="padding: 20px; color: var(--text-muted);">Nincs elérhető tanulói adat.</div>`;
    return;
  }

  // Debug log for checking exact raw fields returned by Kréta
  console.log("Pala Student Raw Object:", student);

  const extraStore = await chrome.storage.local.get(["pala_student_extra"]);
  const extra = extraStore.pala_student_extra || {};

  const d = fullState.data || {};
  const grades = Array.isArray(d.grades) ? d.grades : [];
  const absences = Array.isArray(d.absences) ? d.absences : [];

  // Helper for flexible case-insensitive field extraction
  function findField(obj, ...keys) {
    if (!obj || typeof obj !== "object") return null;
    for (const k of keys) {
      if (obj[k] !== undefined && obj[k] !== null && obj[k] !== "") return String(obj[k]);
    }
    const objKeys = Object.keys(obj);
    for (const k of keys) {
      const found = objKeys.find(ok => ok.toLowerCase() === k.toLowerCase());
      if (found && obj[found] !== undefined && obj[found] !== null && obj[found] !== "") {
        return String(obj[found]);
      }
    }
    return null;
  }

  // 1. Guardian list
  const guardians = student.Gondviselok || [];
  let guardiansHtml = "";
  if (guardians.length > 0) {
    guardiansHtml = guardians.map(g => `
      <div style="background: var(--sidebar); border: 1px solid var(--border); border-radius: 8px; padding: 10px; margin-bottom: 8px;">
        <strong style="font-size: 0.85rem;">${g.Nev || "-"}</strong>
        <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; display: flex; flex-direction: column; gap: 2px;">
          <div>Email: ${g.Email || g.EmailCim || "Nincs megadva"}</div>
          <div>Telefon: ${g.Telefonszam || "Nincs megadva"}</div>
        </div>
      </div>
    `).join("");
  } else {
    guardiansHtml = `<div style="font-size: 0.75rem; color: var(--text-muted);">Nincs rögzített gondviselő.</div>`;
  }

  // Personal data extraction (from extra or student)
  const studentName = extra.name || student.Nev || "-";
  const birthName = extra.birthName || student.SzuletesiNev || student.Nev || "-";
  const omId = extra.omId || student.OktatasiAzonosito || "-";
  const birthPlace = extra.birthPlace || student.SzuletesiHely || "-";
  const birthDate = extra.birthDate || (student.SzuletesiDatum ? (student.SzuletesiDatum.includes("T") ? new Date(student.SzuletesiDatum).toLocaleDateString("hu-HU") : student.SzuletesiDatum) : "-");
  const motherName = extra.motherName || student.AnyjaNeve || "-";
  const address = extra.address || student.Cim || student.Cimek?.[0] || "-";

  // Institutional data extraction
  const instName = extra.instituteName || student.IntezmenyNev || student.Intezmeny?.TeljesNev || student.Intezmeny?.Nev || "-";
  const instCode = extra.instituteCode || student.Intezmeny?.Kod || student.IntezmenyKod || "-";
  const classGrade = extra.classGrade || student.Osztaly || student.Evfolyam || "-";
  const email = extra.email || student.Email || student.EmailCim || "-";
  const phone = extra.phone || student.Telefonszam || "-";

  // Bank details extraction
  const bankObj = student.Bankszamla || student.BankiAdatok || student.BankszamlaAdatok || {};
  const bankAccount = extra.bankAccount || findField(student, "Bankszamlaszam", "BankszamlaSzam", "Szamlaszam", "Iban") || findField(bankObj, "Bankszamlaszam", "Szamlaszam", "Iban") || "-";
  const bankName = extra.bankName || findField(student, "SzamlavezetoBank", "BankNev", "Bank") || findField(bankObj, "SzamlavezetoBank", "BankNev", "Bank") || "-";
  const bankOwner = extra.bankOwner || findField(student, "BankszamlaTulajdonosNeve", "BankszamlaTulajdonos", "Szamlatulajdonos") || findField(bankObj, "TulajdonosNev", "BankszamlaTulajdonosNeve", "Nev") || studentName || "-";
  const bankOwnerType = extra.bankOwnerType || findField(student, "BankszamlaTulajdonosa", "TulajdonosTipus") || findField(bankObj, "TulajdonosTipus", "Tulajdonosa") || "saját";

  // Official IDs extraction
  const okmanyObj = student.Okmanyok || student.OkmanyAdatok || {};
  const taxId = extra.taxId || findField(student, "AdoazonositoJel", "Adoazonosito", "AdoazonositoSzam", "Adoszam") || findField(okmanyObj, "AdoazonositoJel", "Adoazonosito") || "-";
  const tajNumber = extra.tajNumber || findField(student, "TajSzam", "Taj", "Tajszam") || findField(okmanyObj, "TajSzam", "Taj") || "-";
  const idType = extra.idType || findField(student, "IgazolvanyTipus", "OkmanyTipus") || findField(okmanyObj, "IgazolvanyTipus", "OkmanyTipus") || "Személyi Igazolvány";
  const idNumber = extra.idNumber || findField(student, "SzemelyiIgazolvanySzam", "IgazolvanySzam", "OkmanySzam") || findField(okmanyObj, "IgazolvanySzam", "OkmanySzam") || "-";
  const studentCardNumber = extra.studentCardNumber || findField(student, "DiakigazolvanySzam", "Diakigazolvany") || findField(okmanyObj, "DiakigazolvanySzam", "Diakigazolvany") || "-";
  const rawStudentCardDate = extra.studentCardDate || findField(student, "DiakigazolvanyKelte", "DiakigazolvanyErvenyesseg") || findField(okmanyObj, "DiakigazolvanyKelte");
  const studentCardDate = rawStudentCardDate ? (rawStudentCardDate.includes("T") ? new Date(rawStudentCardDate).toLocaleDateString("hu-HU") : rawStudentCardDate) : "-";

  // Academic & Grade distribution stats
  let count5 = 0, count4 = 0, count3 = 0, count2 = 0, count1 = 0;
  let weightedSum = 0, totalWeight = 0, unweightedSum = 0, gradeCount = 0;
  const subjectSums = {};

  grades.forEach(g => {
    const val = typeof g.SzamErtek === "number" ? g.SzamErtek : parseInt(g.SzamErtek, 10);
    if (!val || isNaN(val) || val < 1 || val > 5) return;

    if (val === 5) count5++;
    else if (val === 4) count4++;
    else if (val === 3) count3++;
    else if (val === 2) count2++;
    else if (val === 1) count1++;

    const w = g.SulySzazalek ? g.SulySzazalek / 100 : 1;
    weightedSum += val * w;
    totalWeight += w;
    unweightedSum += val;
    gradeCount++;

    const subName = g.Tantargy?.Nev || "Egyéb";
    if (!subjectSums[subName]) subjectSums[subName] = { wSum: 0, weight: 0 };
    subjectSums[subName].wSum += val * w;
    subjectSums[subName].weight += w;
  });

  const weightedAvg = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(2) : "-";
  const unweightedAvg = gradeCount > 0 ? (unweightedSum / gradeCount).toFixed(2) : "-";

  let bestSub = "-", bestAvg = 0;
  let worstSub = "-", worstAvg = 6;
  Object.keys(subjectSums).forEach(sub => {
    const s = subjectSums[sub];
    if (s.weight > 0) {
      const avg = s.wSum / s.weight;
      if (avg > bestAvg) { bestAvg = avg; bestSub = sub; }
      if (avg < worstAvg) { worstAvg = avg; worstSub = sub; }
    }
  });

  // Absence metrics
  let totalAbsenceHours = 0;
  let unexcusedHours = 0;
  let totalDelayMins = 0;

  absences.forEach(a => {
    const delay = a.KesesPercben || 0;
    const status = (a.IgazolasAllapota || "").toLowerCase();
    if (delay > 0) {
      totalDelayMins += delay;
    } else {
      totalAbsenceHours++;
      if (!status.includes("igazolt")) {
        unexcusedHours++;
      }
    }
  });

  const remaining250 = Math.max(0, 250 - totalAbsenceHours);

  // Card 1: Személyes Adatok
  const card1 = document.createElement("div");
  card1.className = "card";
  card1.innerHTML = `
    <h2 style="font-size: 1.05rem; font-weight: 800; color: var(--primary); margin-bottom: 16px;">Személyes Adatok</h2>
    <div style="display: flex; flex-direction: column; gap: 10px; font-size: 0.85rem;">
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Név:</span>
        <strong>${studentName}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Születési név:</span>
        <strong>${birthName}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Oktatási azonosító (OM):</span>
        <strong style="color: var(--primary);">${omId}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Születési hely:</span>
        <strong>${birthPlace}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Születési idő:</span>
        <strong>${birthDate}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Anyja neve:</span>
        <strong>${motherName}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Cím (Lakcím/Tartózkodási):</span>
        <strong style="text-align: right; max-width: 60%;">${address}</strong>
      </div>
    </div>
  `;

  // Card 2: Intézmény & Elérhetőségek
  const card2 = document.createElement("div");
  card2.className = "card";
  card2.innerHTML = `
    <h2 style="font-size: 1.05rem; font-weight: 800; color: var(--primary); margin-bottom: 16px;">Intézmény & Elérhetőségek</h2>
    <div style="display: flex; flex-direction: column; gap: 10px; font-size: 0.85rem; margin-bottom: 16px;">
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Intézmény neve:</span>
        <strong style="text-align: right; max-width: 65%; font-size: 0.82rem;">${instName}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Intézmény kódja:</span>
        <strong>${instCode}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Osztály / Évfolyam:</span>
        <strong>${classGrade}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Tanulói Email:</span>
        <strong>${email}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Telefonszám:</span>
        <strong>${phone}</strong>
      </div>
    </div>
    
    <h3 style="font-size: 0.95rem; font-weight: 700; margin-bottom: 10px; color: var(--text);">Gondviselők</h3>
    ${guardiansHtml}
  `;

  // Card 3: Bankszámla Adatok (Ösztöndíj & Pénzügyek)
  const hasBankData = bankAccount !== "-";
  const card3 = document.createElement("div");
  card3.className = "card";
  card3.innerHTML = `
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;">
      <div style="display: flex; align-items: center; gap: 8px;">
        <h2 style="font-size: 1.05rem; font-weight: 800; color: var(--primary); margin: 0;">Bankszámla Adatok</h2>
        <span class="badge ${hasBankData ? "badge-verified" : "badge-maintenance"}" style="font-size: 0.72rem;">
          ${hasBankData ? "Rögzítve • Ösztöndíjhoz aktív" : "Nincs rögzítve"}
        </span>
      </div>
    </div>
    <div style="display: flex; flex-direction: column; gap: 10px; font-size: 0.85rem; margin-bottom: 14px;">
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Bankszámlaszám:</span>
        <strong style="font-family: monospace; font-size: 0.88rem; letter-spacing: 0.5px;">${bankAccount}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Számlavezető bank:</span>
        <strong>${bankName}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Bankszámla tulajdonos neve:</span>
        <strong>${bankOwner}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Bankszámla tulajdonosa:</span>
        <strong style="text-transform: capitalize;">${bankOwnerType}</strong>
      </div>
    </div>
    <div style="background: rgba(255,136,0,0.08); border: 1px solid rgba(255,136,0,0.25); border-radius: 8px; padding: 10px 12px; font-size: 0.73rem; color: var(--text-muted); line-height: 1.4;">
      A tanulói bankszámla adatok a szakképzési ösztöndíj, a rászorultsági támogatás és a duális képzés munkabérének átutalásához szükségesek.
    </div>
  `;

  // Card 4: Hivatalos Okmányok & Igazolványok
  const card4 = document.createElement("div");
  card4.className = "card";
  card4.innerHTML = `
    <h2 style="font-size: 1.05rem; font-weight: 800; color: var(--primary); margin-bottom: 16px;">Hivatalos Okmányok</h2>
    <div style="display: flex; flex-direction: column; gap: 10px; font-size: 0.85rem;">
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Adóazonosító jel:</span>
        <strong style="font-family: monospace; font-size: 0.88rem; color: var(--primary);">${taxId}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">TAJ-szám:</span>
        <strong style="font-family: monospace; font-size: 0.88rem;">${tajNumber}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Igazolvány típusa:</span>
        <strong>${idType}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Igazolvány száma:</span>
        <strong>${idNumber}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Diákigazolvány száma:</span>
        <strong>${studentCardNumber}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Diákigazolvány kelte / érvényessége:</span>
        <strong>${studentCardDate}</strong>
      </div>
    </div>
  `;

  // Card 5: Tanulmányi & Mulasztási Mérföldkövek (Full width summary card)
  const card5 = document.createElement("div");
  card5.className = "card";
  card5.style.gridColumn = "1 / -1";
  card5.innerHTML = `
    <h2 style="font-size: 1.05rem; font-weight: 800; margin-bottom: 16px; color: var(--primary);">Tanulmányi & Mulasztási Mérföldkövek</h2>
    
    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 14px; margin-bottom: 18px;">
      <div style="background: var(--sidebar); border: 1px solid var(--border); border-radius: 10px; padding: 12px 14px;">
        <div style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 4px;">Súlyozott tanulmányi átlag</div>
        <div style="font-size: 1.4rem; font-weight: 800; color: var(--primary);">${weightedAvg}</div>
        <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 2px;">Súlyozatlan: ${unweightedAvg} (${gradeCount} jegy)</div>
      </div>
      <div style="background: var(--sidebar); border: 1px solid var(--border); border-radius: 10px; padding: 12px 14px;">
        <div style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 4px;">Legjobb tantárgy</div>
        <div style="font-size: 1rem; font-weight: 700; color: var(--success); white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(bestSub)}</div>
        <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 2px;">Átlag: ${bestAvg > 0 ? bestAvg.toFixed(2) : "-"}</div>
      </div>
      <div style="background: var(--sidebar); border: 1px solid var(--border); border-radius: 10px; padding: 12px 14px;">
        <div style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 4px;">Leggyengébb tantárgy</div>
        <div style="font-size: 1rem; font-weight: 700; color: ${worstAvg < 3 ? "var(--danger)" : "var(--warning)"}; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(worstSub)}</div>
        <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 2px;">Átlag: ${worstAvg <= 5 ? worstAvg.toFixed(2) : "-"}</div>
      </div>
      <div style="background: var(--sidebar); border: 1px solid var(--border); border-radius: 10px; padding: 12px 14px;">
        <div style="font-size: 0.75rem; color: var(--text-muted); margin-bottom: 4px;">Mulasztott órák / 250h keret</div>
        <div style="font-size: 1.2rem; font-weight: 800; color: ${totalAbsenceHours > 100 ? "var(--warning)" : "var(--text)"};">${totalAbsenceHours} óra</div>
        <div style="font-size: 0.72rem; color: var(--text-muted); margin-top: 2px;">Hátralévő biztonságos: ${remaining250} óra</div>
      </div>
    </div>

    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
      <span style="font-size: 0.8rem; font-weight: 700; color: var(--text-muted);">Érdemjegyek Eloszlása</span>
      <span style="font-size: 0.75rem; color: var(--text-muted);">Összesen ${gradeCount} db értékelés</span>
    </div>
    <div style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px; text-align: center;">
      <div style="background: rgba(48,209,88,0.12); border: 1px solid rgba(48,209,88,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--success);">5-ös</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: var(--success);">${count5}</div>
      </div>
      <div style="background: rgba(10,132,255,0.12); border: 1px solid rgba(10,132,255,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: #0a84ff;">4-es</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: #0a84ff;">${count4}</div>
      </div>
      <div style="background: rgba(255,214,10,0.12); border: 1px solid rgba(255,214,10,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--warning);">3-as</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: var(--warning);">${count3}</div>
      </div>
      <div style="background: rgba(255,159,10,0.12); border: 1px solid rgba(255,159,10,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: #ff9f0a;">2-es</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: #ff9f0a;">${count2}</div>
      </div>
      <div style="background: rgba(255,69,58,0.12); border: 1px solid rgba(255,69,58,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--danger);">1-es</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: var(--danger);">${count1}</div>
      </div>
    </div>
  `;

  container.appendChild(card1);
  container.appendChild(card2);
  container.appendChild(card3);
  container.appendChild(card4);
  container.appendChild(card5);

  document.getElementById("btn-global-edit-profile")?.addEventListener("click", () => openExtraModal());
  document.getElementById("btn-toggle-api-warning")?.addEventListener("click", () => {
    const banner = document.getElementById("student-api-banner");
    if (banner) {
      banner.style.display = banner.style.display === "none" ? "flex" : "none";
    }
  });
  document.getElementById("btn-close-api-banner")?.addEventListener("click", () => {
    const banner = document.getElementById("student-api-banner");
    if (banner) banner.style.display = "none";
  });
}

async function openExtraModal() {
  const modal = document.getElementById("student-extra-modal");
  if (!modal) return;

  const extraStore = await chrome.storage.local.get(["pala_student_extra"]);
  const extra = extraStore.pala_student_extra || {};
  const student = fullState.data?.student || {};

  const setVal = (id, val) => {
    const el = document.getElementById(id);
    if (el) el.value = (val && val !== "-") ? val : "";
  };

  // Group 1: Personal
  setVal("extra-input-name", extra.name || student.Nev);
  setVal("extra-input-birth-name", extra.birthName || student.SzuletesiNev || student.Nev);
  setVal("extra-input-om-id", extra.omId || student.OktatasiAzonosito);
  setVal("extra-input-birth-place", extra.birthPlace || student.SzuletesiHely);
  const rawBirth = student.SzuletesiDatum ? (student.SzuletesiDatum.includes("T") ? new Date(student.SzuletesiDatum).toLocaleDateString("hu-HU") : student.SzuletesiDatum) : "";
  setVal("extra-input-birth-date", extra.birthDate || rawBirth);
  setVal("extra-input-mother-name", extra.motherName || student.AnyjaNeve);
  setVal("extra-input-address", extra.address || student.Cim || student.Cimek?.[0]);

  // Group 2: Institutional & Contacts
  setVal("extra-input-inst-name", extra.instituteName || student.IntezmenyNev || student.Intezmeny?.TeljesNev || student.Intezmeny?.Nev);
  setVal("extra-input-inst-code", extra.instituteCode || student.Intezmeny?.Kod || student.IntezmenyKod);
  setVal("extra-input-class-grade", extra.classGrade || student.Osztaly || student.Evfolyam);
  setVal("extra-input-email", extra.email || student.Email || student.EmailCim);
  setVal("extra-input-phone", extra.phone || student.Telefonszam);

  // Group 3: Bank
  setVal("extra-input-bank-account", extra.bankAccount || student.Bankszamlaszam || student.Bankszamla?.Szamlaszam);
  setVal("extra-input-bank-name", extra.bankName || student.SzamlavezetoBank || student.Bankszamla?.BankNev);
  setVal("extra-input-bank-owner", extra.bankOwner || student.BankszamlaTulajdonosNeve || extra.name || student.Nev);
  setVal("extra-input-bank-type", extra.bankOwnerType || student.BankszamlaTulajdonosa || "saját");

  // Group 4: Official IDs
  setVal("extra-input-tax-id", extra.taxId || student.AdoazonositoJel || student.Adoazonosito);
  setVal("extra-input-taj", extra.tajNumber || student.TajSzam || student.Taj);
  setVal("extra-input-id-type", extra.idType || student.IgazolvanyTipus || "Személyi Igazolvány");
  setVal("extra-input-id-number", extra.idNumber || student.SzemelyiIgazolvanySzam || student.IgazolvanySzam);
  setVal("extra-input-student-card", extra.studentCardNumber || student.DiakigazolvanySzam);
  setVal("extra-input-student-card-date", extra.studentCardDate || student.DiakigazolvanyKelte);

  modal.style.display = "flex";
  document.getElementById("extra-input-name")?.focus();
}

function setupStudentExtraModal() {
  const modal = document.getElementById("student-extra-modal");
  const closeBtn = document.getElementById("btn-close-extra-modal");
  const cancelBtn = document.getElementById("btn-cancel-extra-modal");
  const saveBtn = document.getElementById("btn-save-extra-modal");
  const resetBtn = document.getElementById("btn-reset-extra-modal");
  const syncBtn = document.getElementById("btn-auto-sync-kreta-tab");
  const statusEl = document.getElementById("extra-modal-status");

  const closeModal = () => {
    if (modal) modal.style.display = "none";
    if (statusEl) statusEl.style.display = "none";
  };

  closeBtn?.addEventListener("click", closeModal);
  cancelBtn?.addEventListener("click", closeModal);

  resetBtn?.addEventListener("click", async () => {
    await chrome.storage.local.remove("pala_student_extra");
    if (statusEl) {
      statusEl.innerText = "Kréta gyári adatok visszaállítva!";
      statusEl.style.color = "var(--info)";
      statusEl.style.display = "block";
    }
    setTimeout(async () => {
      await openExtraModal();
      if (fullState.data?.student) {
        renderStudentView(fullState.data.student);
      }
    }, 400);
  });

  saveBtn?.addEventListener("click", async () => {
    const data = {
      name: document.getElementById("extra-input-name")?.value.trim(),
      birthName: document.getElementById("extra-input-birth-name")?.value.trim(),
      omId: document.getElementById("extra-input-om-id")?.value.trim(),
      birthPlace: document.getElementById("extra-input-birth-place")?.value.trim(),
      birthDate: document.getElementById("extra-input-birth-date")?.value.trim(),
      motherName: document.getElementById("extra-input-mother-name")?.value.trim(),
      address: document.getElementById("extra-input-address")?.value.trim(),
      instituteName: document.getElementById("extra-input-inst-name")?.value.trim(),
      instituteCode: document.getElementById("extra-input-inst-code")?.value.trim(),
      classGrade: document.getElementById("extra-input-class-grade")?.value.trim(),
      email: document.getElementById("extra-input-email")?.value.trim(),
      phone: document.getElementById("extra-input-phone")?.value.trim(),
      bankAccount: document.getElementById("extra-input-bank-account")?.value.trim(),
      bankName: document.getElementById("extra-input-bank-name")?.value.trim(),
      bankOwner: document.getElementById("extra-input-bank-owner")?.value.trim(),
      bankOwnerType: document.getElementById("extra-input-bank-type")?.value,
      taxId: document.getElementById("extra-input-tax-id")?.value.trim(),
      tajNumber: document.getElementById("extra-input-taj")?.value.trim(),
      idType: document.getElementById("extra-input-id-type")?.value.trim(),
      idNumber: document.getElementById("extra-input-id-number")?.value.trim(),
      studentCardNumber: document.getElementById("extra-input-student-card")?.value.trim(),
      studentCardDate: document.getElementById("extra-input-student-card-date")?.value.trim()
    };

    await chrome.storage.local.set({ pala_student_extra: data });

    if (statusEl) {
      statusEl.innerText = "Profil adatok sikeresen mentve!";
      statusEl.style.display = "block";
      statusEl.style.color = "var(--success)";
    }

    setTimeout(() => {
      closeModal();
      if (fullState.data?.student) {
        renderStudentView(fullState.data.student);
      }
    }, 600);
  });

  syncBtn?.addEventListener("click", async () => {
    if (!chrome.tabs || !chrome.scripting) {
      if (statusEl) {
        statusEl.innerText = "A böngésző lapok elérése nem lehetséges.";
        statusEl.style.display = "block";
        statusEl.style.color = "var(--danger)";
      }
      return;
    }

    try {
      const tabs = await chrome.tabs.query({ url: ["*://*.e-kreta.hu/*"] });
      if (!tabs || tabs.length === 0) {
        if (statusEl) {
          statusEl.innerText = "Nincs nyitott Kréta lap a böngészőben. Kérlek nyisd meg a Kréta felületét!";
          statusEl.style.display = "block";
          statusEl.style.color = "var(--warning)";
        }
        return;
      }

      const activeTab = tabs.find(t => t.active) || tabs[0];
      const results = await chrome.scripting.executeScript({
        target: { tabId: activeTab.id },
        func: () => {
          const res = {};
          const allText = document.body.innerText || "";
          
          // Bank account pattern
          const bankMatch = allText.match(/\b\d{8}[- ]\d{8}(?:[- ]\d{8})?\b/);
          if (bankMatch) res.bankAccount = bankMatch[0].replace(/\s+/g, "-");

          // Tax ID: 10 digits starting with 8
          const taxMatch = allText.match(/\b8\d{9}\b/);
          if (taxMatch) res.taxId = taxMatch[0];

          // TAJ: 9 digits
          const tajMatch = allText.match(/\b\d{3}[- ]?\d{3}[- ]?\d{3}\b/);
          if (tajMatch && (!taxMatch || tajMatch[0] !== taxMatch[0])) {
            res.tajNumber = tajMatch[0].replace(/[- ]/g, "");
          }

          // OM identifier: 11 digits starting with 7
          const omMatch = allText.match(/\b7\d{10}\b/);
          if (omMatch) res.omId = omMatch[0];

          // Direct inputs scan
          const inputs = Array.from(document.querySelectorAll("input, select, textarea"));
          for (const inp of inputs) {
            const val = (inp.value || "").trim();
            if (!val) continue;
            const name = (inp.name || inp.id || "").toLowerCase();
            if (name.includes("bank") && name.includes("szamla") && !res.bankAccount) res.bankAccount = val;
            if (name.includes("bank") && !name.includes("szamla") && !res.bankName) res.bankName = val;
            if (name.includes("tulajdonos") && !res.bankOwner) res.bankOwner = val;
            if (name.includes("ado") && !res.taxId) res.taxId = val;
            if (name.includes("taj") && !res.tajNumber) res.tajNumber = val;
            if (name.includes("diak") && !res.studentCardNumber) res.studentCardNumber = val;
            if (name.includes("om") && !res.omId) res.omId = val;
            if ((name.includes("tanulo") || name.includes("nev")) && !res.name && val.includes(" ")) res.name = val;
          }

          return res;
        }
      });

      if (results && results[0]?.result) {
        const found = results[0].result;
        let count = 0;
        const populateField = (id, val) => {
          if (!val) return;
          const el = document.getElementById(id);
          if (el) { el.value = val; count++; }
        };

        populateField("extra-input-bank-account", found.bankAccount);
        populateField("extra-input-bank-name", found.bankName);
        populateField("extra-input-bank-owner", found.bankOwner);
        populateField("extra-input-tax-id", found.taxId);
        populateField("extra-input-taj", found.tajNumber);
        populateField("extra-input-om-id", found.omId);
        populateField("extra-input-name", found.name);

        if (statusEl) {
          if (count > 0) {
            statusEl.innerText = `${count} db adat sikeresen beolvasva a nyitott Kréta lapról! Kattints a mentésre.`;
            statusEl.style.color = "var(--success)";
          } else {
            statusEl.innerText = "A nyitott Kréta lapon nem találhatók profil adatok. Kérlek nyisd meg a Személyes adatlap oldalt a Krétában!";
            statusEl.style.color = "var(--warning)";
          }
          statusEl.style.display = "block";
        }
      }
    } catch (err) {
      if (statusEl) {
        statusEl.innerText = "Nem sikerült a beolvasás a lapról: " + err.message;
        statusEl.style.display = "block";
        statusEl.style.color = "var(--danger)";
      }
    }
  });
}

function renderGhostGradesAndPlanner(subjectMap) {
  const ghostSelect = document.getElementById("ghost-subject");
  const ghostGradeIn = document.getElementById("ghost-grade");
  const ghostWeightIn = document.getElementById("ghost-weight");
  const ghostResult = document.getElementById("ghost-result");
  const plannerContainer = document.getElementById("planner-table-container");

  if (!ghostSelect || !ghostResult || !plannerContainer) return;

  const subjects = Object.keys(subjectMap).sort();
  
  const prevSelection = ghostSelect.value;
  ghostSelect.innerHTML = '<option value="">-- Válassz --</option>';
  subjects.forEach(sub => {
    ghostSelect.innerHTML += `<option value="${escapeHtml(sub)}">${escapeHtml(sub)}</option>`;
  });
  if (subjects.includes(prevSelection)) ghostSelect.value = prevSelection;

  const getSubStats = (subName) => {
    let sum = 0;
    let wSum = 0;
    subjectMap[subName].forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      if (parsed.numericGrade !== null && !parsed.isSummary) {
        sum += parsed.numericGrade * parsed.weight;
        wSum += parsed.weight;
      }
    });
    if (wSum === 0) {
      subjectMap[subName].forEach(g => {
        const parsed = KretaApi.parseGrade(g);
        if (parsed.numericGrade !== null) {
          sum += parsed.numericGrade * parsed.weight;
          wSum += parsed.weight;
        }
      });
    }
    return { sum, wSum, currentAvg: wSum > 0 ? (sum / wSum) : 0 };
  };

  const calculateGhost = () => {
    const sub = ghostSelect.value;
    if (!sub) {
      ghostResult.innerHTML = "Válassz tantárgyat a kalkulációhoz...";
      return;
    }
    const { sum, wSum, currentAvg } = getSubStats(sub);
    if (wSum === 0) {
      ghostResult.innerHTML = "Nincs elég jegy a számoláshoz.";
      return;
    }
    
    const newGrade = parseFloat(ghostGradeIn.value) || 5;
    const newWeight = parseFloat(ghostWeightIn.value) || 100;
    const w = newWeight / 100;
    
    const newAvg = (sum + newGrade * w) / (wSum + w);
    const diff = newAvg - currentAvg;
    const diffStr = diff >= 0 ? `+${diff.toFixed(2)}` : diff.toFixed(2);
    const diffColor = diff >= 0 ? "var(--success)" : "var(--danger)";
    
    let target = Math.ceil(currentAvg);
    if (currentAvg >= target) target = Math.min(5, target + 1);
    
    let neededHtml = "";
    if (target <= 5 && currentAvg < 5.0) {
      const nNeeded = Math.ceil((target * wSum - sum) / (5 - target));
      if (nNeeded > 0) {
        neededHtml = `<div style="margin-top:8px; font-size:0.75rem;">Még <strong>${nNeeded} db</strong> 100%-os 5-ös kell a következő kerek egészhez (${target}).</div>`;
      } else {
        neededHtml = `<div style="margin-top:8px; font-size:0.75rem;">Már elérted a ${target}-öt!</div>`;
      }
    } else {
      neededHtml = `<div style="margin-top:8px; font-size:0.75rem;">Már kitűnő vagy!</div>`;
    }

    ghostResult.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <span>Új átlag: <strong>${newAvg.toFixed(2)}</strong></span>
        <span style="color:${diffColor}; font-weight:700;">${diffStr}</span>
      </div>
      <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">
        Jelenlegi: ${currentAvg.toFixed(2)} ➔ Új: ${newAvg.toFixed(2)}
      </div>
      ${neededHtml}
    `;
  };

  ghostSelect.removeEventListener("change", ghostSelect._calcListener);
  ghostGradeIn.removeEventListener("input", ghostSelect._calcListener);
  ghostWeightIn.removeEventListener("input", ghostSelect._calcListener);
  
  ghostSelect._calcListener = calculateGhost;
  ghostSelect.addEventListener("change", calculateGhost);
  ghostGradeIn.addEventListener("input", calculateGhost);
  ghostWeightIn.addEventListener("input", calculateGhost);
  
  calculateGhost();

  let plannerHtml = `
    <table class="data-table" style="width:100%; border-collapse:collapse; font-size:0.8rem; text-align:left;">
      <thead>
        <tr style="border-bottom: 2px solid var(--border); color:var(--text-muted);">
          <th style="padding: 8px;">Tantárgy</th>
          <th style="padding: 8px; text-align:center;">Jelenlegi</th>
          <th style="padding: 8px; text-align:center;">Cél</th>
          <th style="padding: 8px; text-align:center;">Szükséges 5-ös</th>
        </tr>
      </thead>
      <tbody>
  `;
  
  subjects.forEach(sub => {
    const { sum, wSum, currentAvg } = getSubStats(sub);
    if (wSum > 0 && currentAvg < 5.0) {
      let target = Math.ceil(currentAvg);
      if (currentAvg >= target) target = Math.min(5, target + 1);
      
      let nNeeded = 0;
      if (target <= 5) {
        nNeeded = Math.ceil((target * wSum - sum) / (5 - target));
      }
      
      if (nNeeded > 0) {
        plannerHtml += `
          <tr style="border-bottom: 1px solid var(--border);">
            <td style="padding: 8px; font-weight:700;">${sub}</td>
            <td style="padding: 8px; text-align:center;">${currentAvg.toFixed(2)}</td>
            <td style="padding: 8px; text-align:center;">${target}.0</td>
            <td style="padding: 8px; text-align:center; font-weight:800; color:var(--primary);">${nNeeded} db</td>
          </tr>
        `;
      }
    }
  });
  
  plannerHtml += `</tbody></table>`;
  plannerContainer.innerHTML = plannerHtml;
}

/**
 * Live "original name" options for the alias picker's datalist, instead of
 * requiring the exact Kréta name to be typed. Subjects are collected from
 * grades/timetable/exams/homework/absences, so a subject shows up even
 * without a grade yet (timetable entries don't need one). Teachers come from
 * the messaging directory plus raw timetable teacher/substitute fields, so a
 * teacher shows up even before they've entered a grade.
 */
function getKnownSubjectNames() {
  const data = fullState.data || {};
  const names = new Set();
  const collect = (arr) => {
    (arr || []).forEach(item => {
      const sub = item?.Tantargy?.Nev || (typeof item?.Tantargy === "string" ? item.Tantargy : null);
      if (sub) names.add(sub);
    });
  };
  collect(data.grades);
  collect(data.timetable);
  collect(data.exams);
  collect(data.homework);
  collect(data.absences);
  return Array.from(names).sort((a, b) => a.localeCompare(b, "hu"));
}

function getKnownTeacherNames() {
  const data = fullState.data || {};
  const names = new Set();
  (data.teachers || []).forEach(t => {
    const n = t?.name || t?.nev;
    if (n) names.add(n);
  });
  (data.timetable || []).forEach(l => {
    // Real API uses TanarNeve/HelyettesTanarNeve; the demo generator uses
    // Tanar/HelyettesitoTanarNeve. Check both so real and demo data both work.
    const teacher = l.TanarNeve || l.Tanar;
    const substitute = l.HelyettesTanarNeve || l.HelyettesitoTanarNeve;
    if (teacher) names.add(teacher);
    if (substitute) names.add(substitute);
  });
  return Array.from(names).sort((a, b) => a.localeCompare(b, "hu"));
}

let teachersLoading = false;

function renderAliasSuggestions(filterText) {
  const box = document.getElementById("alias-orig-suggestions");
  if (!box) return;

  if (aliasCategory === "teacher" && teachersLoading) {
    box.innerHTML = '<div style="padding: 10px 12px; font-size: 0.8rem; color: var(--text-muted);">Tanárok betöltése...</div>';
    box.style.display = "block";
    return;
  }

  const allNames = aliasCategory === "teacher" ? getKnownTeacherNames() : getKnownSubjectNames();
  const q = (filterText || "").trim().toLowerCase();
  const names = q ? allNames.filter(n => n.toLowerCase().includes(q)) : allNames;

  if (names.length === 0) {
    const msg = aliasCategory === "teacher"
      ? "Nincs elérhető tanár (nyisd meg egyszer az Üzenetek fület, vagy gépeld be kézzel a nevet)."
      : "Nincs találat, de kézzel is megadhatod a nevet.";
    box.innerHTML = `<div style="padding: 10px 12px; font-size: 0.8rem; color: var(--text-muted);">${msg}</div>`;
    box.style.display = "block";
    return;
  }

  box.innerHTML = names.map(n =>
    `<div class="alias-suggestion-item" data-value="${escapeHtml(n)}" style="padding: 8px 12px; font-size: 0.82rem; cursor: pointer;">${escapeHtml(n)}</div>`
  ).join("");
  box.querySelectorAll(".alias-suggestion-item").forEach(el => {
    el.addEventListener("mouseenter", () => { el.style.background = "var(--card-hover)"; });
    el.addEventListener("mouseleave", () => { el.style.background = "transparent"; });
    el.addEventListener("mousedown", (e) => {
      // mousedown (not click) so this fires before the input's blur hides the box.
      e.preventDefault();
      const input = document.getElementById("alias-orig-input");
      if (input) input.value = el.getAttribute("data-value");
      box.style.display = "none";
    });
  });
  box.style.display = "block";
}

function populateAliasDatalist() {
  const input = document.getElementById("alias-orig-input");
  const box = document.getElementById("alias-orig-suggestions");
  if (input) {
    input.placeholder = aliasCategory === "teacher"
      ? "Eredeti Kréta tanárnév (pl. Kovács Péter)"
      : "Eredeti Kréta tantárgynév (pl. Német nyelv)";
  }
  if (box && box.style.display === "block") renderAliasSuggestions(input?.value || "");
}

async function ensureTeachersLoaded() {
  if (fullState.data?.teachers && fullState.data.teachers.length > 0) return;
  if (teachersLoading) return;
  teachersLoading = true;
  renderAliasSuggestions(document.getElementById("alias-orig-input")?.value || "");
  try {
    const store = await chrome.storage.local.get(["pala_use_demo"]);
    const session = await SecureSession.load();
    if (store.pala_use_demo !== false || !session?.token) return;
    const token = await KretaApi.ensureValidToken(session);
    const teachers = await KretaApi.getTeachers(token).catch(() => []);
    if (teachers && teachers.length > 0 && fullState.data) {
      fullState.data.teachers = teachers;
      await chrome.storage.local.set({ pala_cached_data: fullState.data });
    }
  } catch (e) {
    console.warn("Failed to load teachers for alias picker:", e);
  } finally {
    teachersLoading = false;
    if (aliasCategory === "teacher") {
      renderAliasSuggestions(document.getElementById("alias-orig-input")?.value || "");
    }
  }
}

function renderAliases() {
  const container = document.getElementById("alias-list");
  if (!container) return;

  const aliases = fullState.aliases || {};
  const keys = Object.keys(aliases);
  if (keys.length === 0) {
    container.innerHTML = '<div style="font-size: 0.78rem; color: var(--text-muted);">Nincsenek egyéni aliasok megadva.</div>';
    return;
  }

  container.innerHTML = "";
  keys.forEach(orig => {
    const custom = aliases[orig];
    const chip = document.createElement("div");
    chip.style.cssText = "background: var(--sidebar); border: 1px solid var(--border); border-radius: 6px; padding: 4px 10px; display: inline-flex; align-items: center; gap: 8px; font-size: 0.78rem;";
    chip.innerHTML = `
      <span><span style="color: var(--text-muted);">${escapeHtml(orig)}</span> &rarr; <strong style="color: var(--primary);">${escapeHtml(custom)}</strong></span>
      <button class="btn-del-alias" style="background: none; border: none; color: var(--text-muted); cursor: pointer; font-size: 0.85rem; padding: 0 2px;">✕</button>
    `;
    chip.querySelector(".btn-del-alias").addEventListener("click", async () => {
      delete fullState.aliases[orig];
      await chrome.storage.local.set({ pala_aliases: fullState.aliases });
      renderAliases();
      renderDashboard();
    });
    container.appendChild(chip);
  });
}

function openWrappedModal() {
  const modal = document.getElementById("wrapped-modal");
  const content = document.getElementById("wrapped-content");
  if (!modal || !content) return;

  const now = new Date();
  const month = now.getMonth() + 1; // 1-12
  const day = now.getDate();
  const isSummer = (month === 6 && day >= 14) || (month === 7) || (month === 8) || (month === 9 && day <= 30);

  if (!isSummer && !fullState.isDemo) {
    content.innerHTML = `
      <div style="text-align: center; padding: 24px 12px;">
        <div style="width: 54px; height: 54px; border-radius: 50%; background: rgba(255, 136, 0, 0.12); border: 1px solid rgba(255, 136, 0, 0.3); display: flex; align-items: center; justify-content: center; margin: 0 auto 16px auto;">
          <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="12" cy="12" r="5"></circle>
            <line x1="12" y1="1" x2="12" y2="3"></line>
            <line x1="12" y1="21" x2="12" y2="23"></line>
            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
            <line x1="1" y1="12" x2="3" y2="12"></line>
            <line x1="21" y1="12" x2="23" y2="12"></line>
            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
          </svg>
        </div>
        <h3 style="font-size: 1.2rem; font-weight: 800; margin-bottom: 8px;">A Pala Wrapped a nyári szünetben érhető el</h3>
        <p style="font-size: 0.85rem; color: var(--text-muted); line-height: 1.5; margin-bottom: 14px;">
          A hivatalos tanévzáró összefoglaló kizárólag június 14. és szeptember 30. között aktív, amikor az adott tanév összes érdemjegye és mulasztása hivatalosan lezárult.
        </p>
        <p style="font-size: 0.78rem; color: var(--text-muted); margin-bottom: 24px;">
          A tanév közben a Faliújság és az Osztályzatok fülön követheted az eredményeidet és átlagaidat.
        </p>
        <button class="btn btn-secondary" onclick="document.getElementById('wrapped-modal').style.display='none'">Rendben, bezárás</button>
      </div>
    `;
    modal.style.display = "flex";
    return;
  }

  const grades = fullState.data?.grades || [];
  const absences = fullState.data?.absences || [];

  if (!grades.length) {
    content.innerHTML = `
      <div style="text-align: center; padding: 30px; color: var(--text-muted);">
        <p>Sajnos nincsenek elérhető érdemjegyek az összefoglaló elkészítéséhez.</p>
        <button class="btn btn-secondary" onclick="document.getElementById('wrapped-modal').style.display='none'" style="margin-top: 12px;">Bezárás</button>
      </div>
    `;
    modal.style.display = "flex";
    return;
  }

  let total5s = 0;
  let total1s = 0;
  let weightedSum = 0;
  let totalWeight = 0;
  const subStats = {};
  const monthStats = {};

  grades.forEach(g => {
    const p = KretaApi.parseGrade(g);
    if (p.numericValue === 5) total5s++;
    if (p.numericValue === 1) total1s++;

    if (p.numericValue && p.weightPercent) {
      weightedSum += p.numericValue * p.weightPercent;
      totalWeight += p.weightPercent;

      const rawSub = g.Tantargy?.Nev || g.Tantargy || "Egyéb";
      const sub = getDisplaySubject(rawSub);
      if (!subStats[sub]) subStats[sub] = { sum: 0, w: 0 };
      subStats[sub].sum += p.numericValue * p.weightPercent;
      subStats[sub].w += p.weightPercent;
    }

    const dateStr = g.KeszitesDatuma || g.RogzitesDatuma || g.Datum;
    if (dateStr) {
      const m = new Date(dateStr).getMonth() + 1;
      monthStats[m] = (monthStats[m] || 0) + 1;
    }
  });

  const overallGpa = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(2) : "--";

  let bestSub = "-";
  let bestSubAvg = 0;
  let worstSub = "-";
  let worstSubAvg = 6;

  Object.entries(subStats).forEach(([s, data]) => {
    if (data.w > 0) {
      const avg = data.sum / data.w;
      if (avg > bestSubAvg) {
        bestSubAvg = avg;
        bestSub = s;
      }
      if (avg < worstSubAvg) {
        worstSubAvg = avg;
        worstSub = s;
      }
    }
  });

  const monthNames = ["", "Január", "Február", "Március", "Április", "Május", "Június", "Július", "Augusztus", "Szeptember", "Október", "November", "December"];
  let topMonthNum = 1;
  let topMonthCount = 0;
  Object.entries(monthStats).forEach(([m, count]) => {
    if (count > topMonthCount) {
      topMonthCount = count;
      topMonthNum = parseInt(m, 10);
    }
  });
  const topMonthName = monthNames[topMonthNum] || "Szeptember";

  let unexcusedHours = 0;
  absences.forEach(a => {
    const st = (a.IgazolasAllapota || "").toLowerCase();
    if (!st.includes("igazolt") && (a.KesesPercben || 0) === 0) unexcusedHours++;
  });

  content.innerHTML = `
    <div style="display: flex; flex-direction: column; gap: 14px;">
      <div style="background: linear-gradient(135deg, rgba(255,136,0,0.15), rgba(255,136,0,0.04)); border: 1px solid rgba(255,136,0,0.3); border-radius: 12px; padding: 18px; text-align: center;">
        <span class="badge" style="background: var(--primary); color: #000; font-weight: 800; margin-bottom: 8px;">HIVATALOS TANÉVZÁRÓ</span>
        <div style="font-size: 2.2rem; font-weight: 900; color: var(--primary); margin: 6px 0;">${overallGpa}</div>
        <div style="font-size: 0.85rem; color: var(--text-muted);">Súlyozott Tanulmányi Átlag</div>
        <div style="font-size: 0.78rem; color: var(--text-muted); margin-top: 4px;">Összesen <strong>${grades.length}</strong> rögzített érdemjegy alapján</div>
      </div>

      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
        <div class="card" style="padding: 12px 14px; background: var(--sidebar); margin: 0;">
          <div style="font-size: 0.74rem; color: var(--text-muted);">Ötösök száma</div>
          <div style="font-size: 1.5rem; font-weight: 800; color: var(--success); margin: 2px 0;">${total5s} db</div>
          <div style="font-size: 0.7rem; color: var(--text-muted);">${((total5s / grades.length) * 100).toFixed(0)}% a jegyeknek</div>
        </div>

        <div class="card" style="padding: 12px 14px; background: var(--sidebar); margin: 0;">
          <div style="font-size: 0.74rem; color: var(--text-muted);">Egyesek száma</div>
          <div style="font-size: 1.5rem; font-weight: 800; color: var(--danger); margin: 2px 0;">${total1s} db</div>
          <div style="font-size: 0.7rem; color: var(--text-muted);">${((total1s / grades.length) * 100).toFixed(0)}% a jegyeknek</div>
        </div>
      </div>

      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
        <div class="card" style="padding: 12px 14px; background: var(--sidebar); margin: 0;">
          <div style="font-size: 0.74rem; color: var(--text-muted);">Legjobb tantárgy</div>
          <div style="font-size: 1rem; font-weight: 800; color: var(--primary); margin: 4px 0;" title="${escapeHtml(bestSub)}">${escapeHtml(bestSub)}</div>
          <div style="font-size: 0.72rem; color: var(--text-muted);">Átlag: ${bestSubAvg > 0 ? bestSubAvg.toFixed(2) : "-"}</div>
        </div>

        <div class="card" style="padding: 12px 14px; background: var(--sidebar); margin: 0;">
          <div style="font-size: 0.74rem; color: var(--text-muted);">Legaktívabb hónap</div>
          <div style="font-size: 1rem; font-weight: 800; color: #fff; margin: 4px 0;">${topMonthName}</div>
          <div style="font-size: 0.72rem; color: var(--text-muted);">${topMonthCount} rögzített jegy</div>
        </div>
      </div>

      <div class="card" style="padding: 14px; background: var(--sidebar); margin: 0;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <div>
            <div style="font-size: 0.75rem; color: var(--text-muted);">Mulasztások összesen</div>
            <strong style="font-size: 1.1rem;">${absences.length} tanóra</strong>
          </div>
          <div style="text-align: right;">
            <div style="font-size: 0.75rem; color: var(--text-muted);">Igazolatlan hiányzás</div>
            <strong style="font-size: 1.1rem; color: ${unexcusedHours > 0 ? 'var(--danger)' : 'var(--success)'};">${unexcusedHours} óra</strong>
          </div>
        </div>
      </div>

      <div style="text-align: center; margin-top: 6px;">
        <p style="font-size: 0.82rem; color: var(--primary); font-weight: 700; margin-bottom: 12px;">KÉSZ, VÉGE, VAKÁCIÓ! Jó pihenést a nyárra!</p>
        <button class="btn btn-primary btn-block" onclick="document.getElementById('wrapped-modal').style.display='none'">Bezárás</button>
      </div>
    </div>
  `;

  modal.style.display = "flex";
}
