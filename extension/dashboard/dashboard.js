// Pala Extension - Full Dashboard Logic

let fullState = {
  isDemo: true,
  data: null,
  aliases: {}
};

let aliasCategory = "subject"; // "subject" | "teacher"
let currentTaskFilter = "all"; // "all" | "exam" | "hw"
let currentAbsenceFilter = "all"; // "all" | "unexcused" | "justified" | "delays"
let isGradesMatrixView = false;
let gradesSearchQuery = "";

const dashGhostState = {
  selectedSubject: "",
  selectedGrade: 5,
  selectedWeight: 100,
  items: []
};

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

function getInitials(name) {
  if (!name) return "PA";
  const parts = String(name).trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "PA";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

/** Collapses the sidebar to icons-only, or restores the full labeled view. */
function applySidebarCollapsed(collapsed) {
  const sidebar = document.querySelector(".sidebar");
  sidebar?.classList.toggle("collapsed", collapsed);
  const btn = document.getElementById("btn-toggle-sidebar");
  if (btn) btn.title = collapsed ? "Oldalsáv kinyitása" : "Oldalsáv összecsukása";
}

function switchDashboardTab(targetId) {
  const items = document.querySelectorAll(".nav-item");
  let activeLabel = "Vezérlőpult";
  items.forEach(btn => {
    const isMatch = btn.getAttribute("data-tab") === targetId;
    btn.classList.toggle("active", isMatch);
    if (isMatch) activeLabel = btn.textContent.trim();
  });

  document.querySelectorAll(".view-panel").forEach(p => {
    p.classList.toggle("active", p.id === targetId);
  });

  document.title = `Pala // ${activeLabel}`;
  const topbarTitle = document.getElementById("topbar-view-title");
  if (topbarTitle) topbarTitle.innerText = activeLabel;

  if (targetId === "view-messages") {
    syncMessagesIfEmpty();
  }
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

  document.getElementById("btn-topbar-theme")?.addEventListener("click", async () => {
    const store = await chrome.storage.local.get("pala_dark_mode");
    const nextDark = store.pala_dark_mode === false;
    applyThemeMode(nextDark);
    await chrome.storage.local.set({ pala_dark_mode: nextDark });
  });

  // Kréta labels weeks per school, not per class; let a class without a rotation hide it.
  const weekTypeStore = await chrome.storage.local.get("pala_show_week_type");
  showWeekType = weekTypeStore.pala_show_week_type !== false;
  const weekTypeToggle = document.getElementById("dash-week-type-toggle");
  if (weekTypeToggle) weekTypeToggle.checked = showWeekType;
  weekTypeToggle?.addEventListener("change", async (e) => {
    showWeekType = e.target.checked;
    await chrome.storage.local.set({ pala_show_week_type: showWeekType });
    renderWeeklyTimetable(fullState.data?.timetable || []);
  });

  const sidebarStore = await chrome.storage.local.get("pala_sidebar_collapsed");
  applySidebarCollapsed(!!sidebarStore.pala_sidebar_collapsed);
  document.getElementById("btn-toggle-sidebar")?.addEventListener("click", async () => {
    const store = await chrome.storage.local.get("pala_sidebar_collapsed");
    const next = !store.pala_sidebar_collapsed;
    applySidebarCollapsed(next);
    await chrome.storage.local.set({ pala_sidebar_collapsed: next });
  });

  setupSidebarNavigation();
  setupAccountSubtabs();
  setupDashProfileSwitcher();
  setupGlobalSearch();
  setupDashboardGhostSimulator();
  setupViewFiltersAndToggles();

  document.getElementById("btn-dash-goto-timetable")?.addEventListener("click", () => {
    switchDashboardTab("view-timetable");
  });
  document.getElementById("btn-dash-goto-tasks")?.addEventListener("click", () => {
    switchDashboardTab("view-tasks");
  });
  document.getElementById("btn-topbar-ghost")?.addEventListener("click", () => {
    const dashActive = document.getElementById("view-dashboard")?.classList.contains("active");
    if (dashActive) {
      document.getElementById("dash-quick-ghost-card")?.scrollIntoView({ behavior: "smooth", block: "center" });
    } else {
      switchDashboardTab("view-grades");
      const details = document.getElementById("grades-ghost-details");
      if (details) details.open = true;
    }
  });
  document.getElementById("btn-dash-open-sidepanel")?.addEventListener("click", async () => {
    try {
      const win = await chrome.windows.getCurrent();
      if (chrome.sidePanel?.open && win?.id) {
        await chrome.sidePanel.open({ windowId: win.id });
        return;
      }
      const res = await chrome.runtime.sendMessage({ type: "pala_open_sidepanel", windowId: win?.id });
      if (res?.ok) return;
    } catch (_) {}
    chrome.tabs.create({ url: chrome.runtime.getURL("sidepanel/sidepanel.html") });
  });

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
    abWeekOverride = null;
    await SecureSession.save(null);
    await chrome.storage.local.remove(["pala_cached_data", "pala_last_fetch"]);
    await chrome.storage.local.set({ pala_use_demo: true, pala_simulate_maintenance: false });
    fullState.aliases = {};
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
    abWeekOverride = null;
    await SecureSession.save(null);
    await chrome.storage.local.remove(["pala_cached_data", "pala_last_fetch", "pala_student_extra"]);
    await chrome.storage.local.set({ pala_use_demo: true });
    fullState.aliases = {};
    await loadDashboardData(true);
  });

  let isMatrixView = false;
  document.getElementById("btn-timetable-toggle")?.addEventListener("click", () => {
    isMatrixView = !isMatrixView;
    const btn = document.getElementById("btn-timetable-toggle");
    if (btn) btn.innerText = isMatrixView ? "5-napos Oszlopok" : "7-napos Mátrix";
    const listGrid = document.getElementById("weekly-timetable-grid");
    const mxGrid = document.getElementById("matrix-timetable-grid");
    if (listGrid) listGrid.style.display = isMatrixView ? "none" : "grid";
    if (mxGrid) mxGrid.style.display = isMatrixView ? "block" : "none";
  });

  // Demo only: real week types come from Kréta, so there is nothing to flip.
  document.getElementById("btn-toggle-ab-week")?.addEventListener("click", () => {
    if (!fullState.isDemo || !fullState.data) return;
    abWeekOverride = fullState.data.weekType !== "A hét";
    fullState.data.timetable = KretaApi.generateDemoTimetable(abWeekOverride);
    fullState.data.weekType = KretaApi.demoWeekType(abWeekOverride);
    renderWeeklyTimetable(fullState.data.timetable);
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
      defaultTab: document.getElementById("dash-popup-pref-default-tab")?.value || "tab-grades",
      showHeroCard: document.getElementById("dash-popup-pref-show-hero")?.checked !== false,
      compactMode: document.getElementById("dash-popup-pref-compact")?.checked === true,
      popupSize: document.getElementById("dash-popup-pref-size")?.value || "medium",
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

  const exportGradesCsv = () => {
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
  };

  const exportAbsencesCsv = () => {
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
  };

  document.getElementById("btn-export-grades")?.addEventListener("click", exportGradesCsv);
  document.getElementById("btn-export-grades-header")?.addEventListener("click", exportGradesCsv);
  document.getElementById("btn-export-absences")?.addEventListener("click", exportAbsencesCsv);
  document.getElementById("btn-export-absences-header")?.addEventListener("click", exportAbsencesCsv);

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
      const room = l.TeremNeve ? ` (Terem: ${l.TeremNeve})` : "";
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
  aliasOrigInput?.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && aliasOrigBox) aliasOrigBox.style.display = "none";
  });
  aliasOrigInput?.addEventListener("blur", () => {
    setTimeout(() => { if (aliasOrigBox) aliasOrigBox.style.display = "none"; }, 150);
  });

  // Listen for background login or sync updates.
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
      if (tabEl) tabEl.value = s.defaultTab || "tab-grades";
      const heroEl = document.getElementById("dash-popup-pref-show-hero");
      if (heroEl) heroEl.checked = s.showHeroCard !== false;
      const compactEl = document.getElementById("dash-popup-pref-compact");
      if (compactEl) compactEl.checked = s.compactMode === true;
      const sizeEl = document.getElementById("dash-popup-pref-size");
      if (sizeEl) sizeEl.value = s.popupSize || "medium";
      const avgEl = document.getElementById("dash-popup-pref-show-average");
      if (avgEl) avgEl.checked = s.showAverageBar !== false;
      const maxGradesEl = document.getElementById("dash-popup-pref-max-grades");
      if (maxGradesEl) maxGradesEl.value = String(s.maxGrades ?? 10);
      const maxTasksEl = document.getElementById("dash-popup-pref-max-tasks");
      if (maxTasksEl) maxTasksEl.value = String(s.maxTasks ?? 5);
    }
  });

  chrome.runtime.onMessage?.addListener((msg) => {
    if (msg?.type === "pala_session_changed" || msg?.type === "pala_data_updated") {
      loadDashboardData(true);
    }
  });

  await loadDashboardData();

  // Live countdown ticker every 30 seconds
  setInterval(() => {
    if (!fullState.data?.timetable) return;
    const todayIso = localDateKey(new Date());
    const todayLessons = (fullState.data.timetable || []).filter(item => {
      if (!item.KezdetIdopont) return false;
      return localDateKey(item.KezdetIdopont) === todayIso;
    });
    renderDashboardHero(todayLessons);
    renderDashboardTodayTimeline(todayLessons);
  }, 30000);
});

function setupSidebarNavigation() {
  const items = document.querySelectorAll(".nav-item");
  items.forEach(btn => {
    btn.addEventListener("click", () => {
      const target = btn.getAttribute("data-tab");
      if (target) switchDashboardTab(target);
    });
  });
}

function setupDashProfileSwitcher() {
  const btn = document.getElementById("dash-profile-switcher-btn");
  const menu = document.getElementById("dash-profile-dropdown-menu");
  const addBtn = document.getElementById("btn-dash-add-profile");

  btn?.addEventListener("click", async (e) => {
    e.stopPropagation();
    if (!menu) return;
    const isVisible = menu.style.display !== "none";
    if (isVisible) {
      menu.style.display = "none";
      return;
    }
    await renderDashProfileDropdown();
    menu.style.display = "block";
  });

  addBtn?.addEventListener("click", () => {
    if (menu) menu.style.display = "none";
    switchDashboardTab("view-account");
    document.getElementById("account-tab-settings")?.click();
    setTimeout(() => document.getElementById("dash-login-institute")?.focus(), 100);
  });

  document.addEventListener("click", (e) => {
    if (menu && menu.style.display !== "none" && !menu.contains(e.target) && !btn?.contains(e.target)) {
      menu.style.display = "none";
    }
  });
}

async function renderDashProfileDropdown() {
  const listEl = document.getElementById("dash-profile-list");
  const menu = document.getElementById("dash-profile-dropdown-menu");
  if (!listEl) return;
  listEl.innerHTML = "";

  const profiles = await SecureSession.listProfiles();
  profiles.forEach(p => {
    const row = document.createElement("button");
    row.type = "button";
    row.className = `profile-item-row ${!fullState.isDemo && p.isActive ? "active" : ""}`;
    row.innerHTML = `
      <div style="min-width:0; flex:1;">
        <div style="font-weight:800; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(p.user || "Diák")}</div>
        <div style="font-size:0.66rem; color:var(--text-muted); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(p.instituteName || p.institute || "")}</div>
      </div>
      ${!fullState.isDemo && p.isActive ? '<span style="font-weight:900; color:var(--primary);">&#10003;</span>' : ""}
    `;
    row.addEventListener("click", async () => {
      if (menu) menu.style.display = "none";
      await SecureSession.switchProfile(p.id);
      await loadDashboardData(true);
    });
    listEl.appendChild(row);
  });

  const demoRow = document.createElement("button");
  demoRow.type = "button";
  demoRow.className = `profile-item-row ${fullState.isDemo ? "active" : ""}`;
  demoRow.innerHTML = `
    <div style="min-width:0; flex:1;">
      <div style="font-weight:800;">Teszt Elek (Demó)</div>
      <div style="font-size:0.66rem; color:var(--text-muted);">Pala Minta Gimnázium</div>
    </div>
    ${fullState.isDemo ? '<span style="font-weight:900; color:var(--primary);">&#10003;</span>' : ""}
  `;
  demoRow.addEventListener("click", async () => {
    if (menu) menu.style.display = "none";
    await SecureSession.switchProfile("demo");
    await loadDashboardData(true);
  });
  listEl.appendChild(demoRow);
}

function setupGlobalSearch() {
  const input = document.getElementById("global-search-input");
  const resultsBox = document.getElementById("global-search-results");
  if (!input || !resultsBox) return;

  // Ctrl+K / Cmd+K shortcut
  document.addEventListener("keydown", (e) => {
    if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === "k") {
      e.preventDefault();
      input.focus();
      input.select();
    } else if (e.key === "Escape" && document.activeElement === input) {
      resultsBox.style.display = "none";
      input.blur();
    }
  });

  const runSearch = () => {
    const rawQ = input.value.trim();
    if (!rawQ) {
      resultsBox.style.display = "none";
      resultsBox.innerHTML = "";
      return;
    }
    const q = KretaApi.normalizeHu(rawQ);
    const d = fullState.data || {};
    const hits = [];

    // 1. Subjects
    getKnownSubjectNames().forEach(sub => {
      const disp = getDisplaySubject(sub);
      if (KretaApi.normalizeHu(sub).includes(q) || KretaApi.normalizeHu(disp).includes(q)) {
        hits.push({
          category: "Tantárgy",
          title: disp,
          sub: `${(d.grades || []).filter(g => (g.Tantargy?.Nev || g.Tantargy) === sub).length} db érdemjegy`,
          action: () => {
            gradesSearchQuery = disp;
            const gInput = document.getElementById("grades-search-input");
            if (gInput) gInput.value = disp;
            switchDashboardTab("view-grades");
            renderAllGradesView(d.grades || [], d.groupAverages || []);
            renderGradesMatrixTable(d.grades || [], d.groupAverages || []);
          }
        });
      }
    });

    // 2. Grades by topic
    (d.grades || []).slice(0, 80).forEach(g => {
      const sub = getDisplaySubject(g.Tantargy?.Nev || g.Tantargy || "Tantárgy");
      const topic = g.Tema || g.Tipus?.Leiras || "";
      const parsed = KretaApi.parseGrade(g);
      if (KretaApi.normalizeHu(`${sub} ${topic}`).includes(q)) {
        hits.push({
          category: `Jegy (${parsed.displayValue})`,
          title: `${sub} — ${topic || "Értékelés"}`,
          sub: `Súly: ${parsed.weightPercent}%`,
          action: () => {
            currentSubjectFilter = g.Tantargy?.Nev || g.Tantargy || "all";
            switchDashboardTab("view-dashboard");
            renderDashboard();
            document.getElementById("dash-grades-table")?.scrollIntoView({ behavior: "smooth" });
          }
        });
      }
    });

    // 3. Timetable rooms / teachers
    const seenLessons = new Set();
    (d.timetable || []).forEach(l => {
      const sub = getDisplaySubject(l.Tantargy?.Nev || l.Nev || "Tanóra");
      const room = l.TeremNeve || "";
      const teacher = l.HelyettesTanarNeve || l.TanarNeve || "";
      const key = `${sub}|${room}|${teacher}`;
      if (seenLessons.has(key)) return;
      if (KretaApi.normalizeHu(`${sub} ${room} ${teacher}`).includes(q)) {
        seenLessons.add(key);
        hits.push({
          category: "Órarend",
          title: `${sub} (${room ? "Terem: " + room : "Tanóra"})`,
          sub: teacher || "",
          action: () => switchDashboardTab("view-timetable")
        });
      }
    });

    // 4. Tasks & Exams
    (d.exams || []).forEach(ex => {
      const sub = getDisplaySubject(ex.Tantargy?.Nev || ex.Tantargy || "Dolgozat");
      const tema = ex.Tema || "Számonkérés";
      if (KretaApi.normalizeHu(`${sub} ${tema}`).includes(q)) {
        hits.push({
          category: "Számonkérés",
          title: `${sub}: ${tema}`,
          sub: (ex.Datum || "").split("T")[0],
          action: () => switchDashboardTab("view-tasks")
        });
      }
    });
    (d.homework || []).forEach(hw => {
      const sub = getDisplaySubject(hw.Tantargy?.Nev || hw.Tantargy || "Házi");
      const text = hw.Szoveg || hw.Feladat || "";
      if (KretaApi.normalizeHu(`${sub} ${text}`).includes(q)) {
        hits.push({
          category: "Házi feladat",
          title: `${sub}: ${text.slice(0, 50)}`,
          sub: (hw.HataridoDatuma || hw.Hatarido || "").split("T")[0],
          action: () => switchDashboardTab("view-tasks")
        });
      }
    });

    // 5. Messages
    (d.messages || []).forEach(m => {
      const title = m.title || m.subject || "Üzenet";
      const sender = m.sender || "";
      if (KretaApi.normalizeHu(`${title} ${sender} ${kretaHtmlToText(m.content)}`).includes(q)) {
        hits.push({
          category: "Üzenet",
          title,
          sub: sender,
          action: () => {
            switchDashboardTab("view-messages");
            openMessageViewer(m);
          }
        });
      }
    });

    resultsBox.innerHTML = "";
    if (hits.length === 0) {
      resultsBox.innerHTML = `<div style="padding:12px; font-size:0.78rem; color:var(--text-muted); text-align:center;">Nincs találat erre: "${escapeHtml(rawQ)}"</div>`;
      resultsBox.style.display = "block";
      return;
    }

    hits.slice(0, 10).forEach(hit => {
      const row = document.createElement("div");
      row.className = "search-result-item";
      row.innerHTML = `
        <div style="min-width:0; flex:1;">
          <div style="font-size:0.8rem; font-weight:700; color:var(--text); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(hit.title)}</div>
          <div style="font-size:0.68rem; color:var(--text-muted); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(hit.sub || "")}</div>
        </div>
        <span class="search-cat-tag">${escapeHtml(hit.category)}</span>
      `;
      row.addEventListener("click", () => {
        resultsBox.style.display = "none";
        input.value = "";
        hit.action();
      });
      resultsBox.appendChild(row);
    });
    resultsBox.style.display = "block";
  };

  input.addEventListener("input", runSearch);
  input.addEventListener("focus", () => {
    if (input.value.trim()) runSearch();
  });
  document.addEventListener("click", (e) => {
    if (!input.contains(e.target) && !resultsBox.contains(e.target)) {
      resultsBox.style.display = "none";
    }
  });
}

function setupDashboardGhostSimulator() {
  const quickSubSelect = document.getElementById("dash-quick-ghost-subject");
  const gradeBtns = document.querySelectorAll("#dash-quick-grade-btns .ghost-pill-btn");
  const weightBtns = document.querySelectorAll("#dash-quick-weight-btns .weight-pill-btn");
  const addQuickBtn = document.getElementById("btn-dash-ghost-add");
  const clearQuickBtn = document.getElementById("btn-dash-ghost-clear");
  const addGradesViewBtn = document.getElementById("btn-grades-add-ghost");

  quickSubSelect?.addEventListener("change", (e) => {
    dashGhostState.selectedSubject = e.target.value;
    const gradesSelect = document.getElementById("ghost-subject");
    if (gradesSelect) gradesSelect.value = dashGhostState.selectedSubject;
    refreshGhostSimulations();
  });

  gradeBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      dashGhostState.selectedGrade = parseInt(btn.getAttribute("data-grade") || "5", 10);
      gradeBtns.forEach(b => b.classList.toggle("active", b === btn));
      const gIn = document.getElementById("ghost-grade");
      if (gIn) gIn.value = String(dashGhostState.selectedGrade);
    });
  });

  weightBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      dashGhostState.selectedWeight = parseInt(btn.getAttribute("data-weight") || "100", 10);
      weightBtns.forEach(b => b.classList.toggle("active", b === btn));
      const wIn = document.getElementById("ghost-weight");
      if (wIn) wIn.value = String(dashGhostState.selectedWeight);
    });
  });

  addQuickBtn?.addEventListener("click", () => {
    if (!dashGhostState.selectedSubject) return;
    dashGhostState.items.push({
      id: `${Date.now()}_${Math.random()}`,
      subject: dashGhostState.selectedSubject,
      grade: dashGhostState.selectedGrade,
      weight: dashGhostState.selectedWeight
    });
    refreshGhostSimulations();
  });

  addGradesViewBtn?.addEventListener("click", () => {
    const sub = document.getElementById("ghost-subject")?.value || dashGhostState.selectedSubject;
    const grade = Math.min(5, Math.max(1, parseInt(document.getElementById("ghost-grade")?.value || "5", 10)));
    const weight = Math.min(400, Math.max(1, parseInt(document.getElementById("ghost-weight")?.value || "100", 10)));
    if (!sub) return;
    dashGhostState.selectedSubject = sub;
    dashGhostState.items.push({
      id: `${Date.now()}_${Math.random()}`,
      subject: sub,
      grade,
      weight
    });
    refreshGhostSimulations();
  });

  clearQuickBtn?.addEventListener("click", () => {
    dashGhostState.items = [];
    refreshGhostSimulations();
  });
}

function setupViewFiltersAndToggles() {
  // Grades Search & Matrix Toggle
  const gradesSearchInput = document.getElementById("grades-search-input");
  gradesSearchInput?.addEventListener("input", (e) => {
    gradesSearchQuery = e.target.value || "";
    renderAllGradesView(fullState.data?.grades || [], fullState.data?.groupAverages || []);
    renderGradesMatrixTable(fullState.data?.grades || [], fullState.data?.groupAverages || []);
  });

  const gradesViewToggle = document.getElementById("btn-grades-view-toggle");
  gradesViewToggle?.addEventListener("click", () => {
    isGradesMatrixView = !isGradesMatrixView;
    gradesViewToggle.innerText = isGradesMatrixView ? "Kártyás nézet" : "Jegymátrix nézet";
    const cardsGrid = document.getElementById("all-grades-grid");
    const matrixBox = document.getElementById("grades-matrix-container");
    if (cardsGrid) cardsGrid.style.display = isGradesMatrixView ? "none" : "grid";
    if (matrixBox) matrixBox.style.display = isGradesMatrixView ? "block" : "none";
  });

  // Tasks Filter Chips
  const taskBtns = document.querySelectorAll("#tasks-filter-chips .chip-btn");
  taskBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      currentTaskFilter = btn.getAttribute("data-task-filter") || "all";
      taskBtns.forEach(b => b.classList.toggle("active", b === btn));
      renderTasksView(fullState.data?.homework || [], fullState.data?.exams || []);
    });
  });

  // Absences Filter Chips
  const absBtns = document.querySelectorAll("#absences-filter-chips .chip-btn");
  absBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      currentAbsenceFilter = btn.getAttribute("data-abs-filter") || "all";
      absBtns.forEach(b => b.classList.toggle("active", b === btn));
      renderAbsencesView(fullState.data?.absences || []);
    });
  });
}

function setupAccountSubtabs() {
  const tabProfileBtn = document.getElementById("account-tab-profile");
  const tabSettingsBtn = document.getElementById("account-tab-settings");
  const subviewProfile = document.getElementById("subview-profile");
  const subviewSettings = document.getElementById("subview-settings");

  if (!tabProfileBtn || !tabSettingsBtn) return;

  tabProfileBtn.addEventListener("click", () => {
    tabProfileBtn.classList.add("active");
    tabSettingsBtn.classList.remove("active");
    if (subviewProfile) subviewProfile.style.display = "block";
    if (subviewSettings) subviewSettings.style.display = "none";
  });

  tabSettingsBtn.addEventListener("click", () => {
    tabSettingsBtn.classList.add("active");
    tabProfileBtn.classList.remove("active");
    if (subviewProfile) subviewProfile.style.display = "none";
    if (subviewSettings) subviewSettings.style.display = "block";
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
  const useDemo = store.pala_use_demo !== false;
  fullState.aliases = useDemo ? {} : (store.pala_aliases || {});

  if (useDemo || !session) {
    fullState.isDemo = true;
    fullState.isMaintenance = false;
    fullState.data = KretaApi.getDemoDataset(abWeekOverride);
  } else {
    fullState.isDemo = false;

    if (!force && !store.pala_cached_data) {
      force = true;
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
        fullState.data = null;
        fullState.fetchError = e;
      }
    }
  }

  renderDashboard();
}

let currentSubjectFilter = "all";

function setStatusBadge(className, text) {
  const demoBadge = document.getElementById("demo-indicator");
  const demoText = document.getElementById("demo-indicator-text");
  if (demoBadge) {
    demoBadge.className = `badge status-pill-badge ${className}`;
    if (demoText) {
      demoText.innerText = text;
    } else {
      demoBadge.innerText = text;
    }
  }
}

function renderDashboard() {
  const d = fullState.data;
  const maintBanner = document.getElementById("dash-maintenance-banner");
  const maintView = document.getElementById("view-maintenance");
  const dashView = document.getElementById("view-dashboard");

  // Handle Maintenance state
  if (fullState.isMaintenance) {
    if (!d) {
      if (maintView) {
        maintView.style.display = "block";
        maintView.classList.add("active");
      }
      if (maintBanner) maintBanner.style.display = "none";
      if (dashView) {
        dashView.style.display = "none";
        dashView.classList.remove("active");
      }
      setStatusBadge("badge-maintenance", "Központi Karbantartás");
      return;
    } else {
      if (maintBanner) maintBanner.style.display = "block";
      if (maintView) {
        maintView.style.display = "none";
        maintView.classList.remove("active");
      }
      if (dashView) {
        dashView.style.display = "block";
        dashView.classList.add("active");
      }
      setStatusBadge("badge-maintenance", "Karbantartás • Offline Gyorsítótár");
    }
  } else {
    if (maintBanner) maintBanner.style.display = "none";
    if (maintView) maintView.style.display = "none";
  }

  if (!d) {
    if (fullState.fetchError) {
      const nameEl = document.getElementById("student-name");
      if (nameEl) nameEl.innerText = "Betöltés sikertelen";
      const instEl = document.getElementById("inst-name");
      if (instEl) instEl.innerText = "Kréta szerver nem érhető el";
      setStatusBadge("badge-maintenance", "Szerver hiba");

      const homeView = document.getElementById("view-dashboard");
      if (homeView) {
        const existingCard = document.getElementById("pala-fetch-error-card");
        if (!existingCard) {
          const errCard = document.createElement("div");
          errCard.id = "pala-fetch-error-card";
          errCard.className = "card";
          errCard.style.cssText = "margin-bottom:18px; border-left:3px solid var(--danger); background:rgba(255,69,58,0.06);";
          const errTitle = document.createElement("div");
          errTitle.style.cssText = "font-weight:700; color:var(--danger); margin-bottom:8px;";
          errTitle.innerText = "Nem sikerült adatot betölteni";
          const errBody = document.createElement("div");
          errBody.style.cssText = "font-size:0.82rem; color:var(--text-muted); margin-bottom:14px;";
          errBody.innerText = "Nem sikerült adatot betölteni a Kréta szerverről. Kérlek ellenőrizd, hogy a Kréta elérhető-e, majd kattints a Szinkronizálás gombra.";
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
      if (instEl) instEl.innerText = "Kattints a Beállítások menüpontra";
      setStatusBadge("badge-maintenance", "Munkamenet lejárt");
    }
    return;
  }

  // Header & Student info
  const studentName = d.student?.Nev || "Diák";
  const nameEl = document.getElementById("student-name");
  if (nameEl) nameEl.innerText = studentName;

  const avatarEl = document.getElementById("dash-avatar-initials");
  if (avatarEl) avatarEl.innerText = getInitials(studentName);

  const instEl = document.getElementById("inst-name");
  if (instEl) {
    instEl.innerText = d.student?.IntezmenyNev ||
                       d.student?.Intezmeny?.TeljesNev ||
                       d.student?.Intezmeny?.Nev ||
                       (fullState.isDemo ? "Pala Minta Gimnázium" : "");
  }

  // Demo / Online status badge
  if (!fullState.isMaintenance) {
    if (fullState.isDemo) {
      setStatusBadge("badge-demo", "Demó Mód (Teszt Elek)");
    } else {
      setStatusBadge("badge-online", "Online • Élő Kréta Adatok");
    }
  }

  // 1. Calculate GPA & Stats using the shared parser
  let totalWeight = 0;
  let weightedSum = 0;
  const subjectMap = {};

  (d.grades || []).forEach(g => {
    const parsed = KretaApi.parseGrade(g);
    if (parsed.numericGrade !== null && !parsed.isSummary) {
      weightedSum += parsed.numericGrade * parsed.weight;
      totalWeight += parsed.weight;
    }

    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy";
    if (!subjectMap[sub]) subjectMap[sub] = [];
    subjectMap[sub].push(g);
  });

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

  const viewAllBtn = document.getElementById("btn-view-all-subjects");
  if (viewAllBtn) {
    viewAllBtn.onclick = () => {
      switchDashboardTab("view-grades");
    };
  }

  // Today's classes count
  const now = new Date();
  const todayIso = localDateKey(now);
  const todayLessons = (d.timetable || []).filter(item => {
    if (!item.KezdetIdopont) return false;
    return localDateKey(item.KezdetIdopont) === todayIso;
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
    if (subjectMap[sub].length >= 2) {
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
      bestNameEl.innerText = getDisplaySubject(bestSub);
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
      worstNameEl.innerText = getDisplaySubject(worstSub);
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
    if (!status.includes("igazolt") && (a.KesesPercben || 0) === 0) {
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
  const unexBadgeEl = document.getElementById("dash-unexcused-badge");
  if (unexValEl && unexNameEl) {
    unexValEl.innerText = `${unexcusedCount} óra`;
    unexValEl.className = "stat-val " + (unexcusedCount === 0 ? "green" : (unexcusedCount >= 10 ? "danger" : "orange"));
    unexNameEl.innerText = topUnexcusedSub ? `Legtöbb: ${getDisplaySubject(topUnexcusedSub)}` : "Nincs igazolatlan hiányzás";
  }
  if (unexBadgeEl) {
    if (unexcusedCount >= 30) {
      unexBadgeEl.className = "badge badge-warning-soft";
      unexBadgeEl.innerText = "30h felett!";
    } else if (unexcusedCount >= 10) {
      unexBadgeEl.className = "badge badge-maintenance";
      unexBadgeEl.innerText = "10h felett";
    } else {
      unexBadgeEl.className = "badge badge-success-soft";
      unexBadgeEl.innerText = "Rendben";
    }
  }

  // Active / Upcoming Lesson Hero Banner + Today Timeline
  try {
    renderDashboardHero(todayLessons);
    renderDashboardTodayTimeline(todayLessons);
  } catch (e) { console.error("Error rendering hero:", e); }

  // Recent Grades Table with Filter Chips
  try { renderRecentGradesTable(d.grades || [], subjectMap); } catch (e) { console.error("Error rendering recent grades:", e); }

  // Quick Ghost Simulator & Upcoming Tasks on Dashboard
  try {
    refreshGhostSimulations(subjectMap);
    renderDashboardUpcomingTasks(d.homework || [], d.exams || []);
  } catch (e) { console.error("Error rendering dashboard widgets:", e); }

  // Subject Averages Cards Grid on Dashboard
  try { renderDashboardSubjectCards(subjectMap); } catch (e) { console.error("Error rendering subject cards:", e); }

  // View 2: Weekly Timetable Grid
  try { renderWeeklyTimetable(d.timetable || []); } catch (e) { console.error("Error rendering timetable:", e); }

  // View 3: Full Subject Breakdown, Grades & Matrix
  try {
    renderGhostGradesAndPlanner(subjectMap);
    renderAllGradesView(d.grades || [], d.groupAverages || []);
    renderGradesMatrixTable(d.grades || [], d.groupAverages || []);
  } catch (e) { console.error("Error rendering all grades:", e); }

  // View 4: Tasks & Homework
  try { renderTasksView(d.homework || [], d.exams || []); } catch (e) { console.error("Error rendering tasks:", e); }

  // View 5: Messages & e-Ügyintézés
  const msgs = Array.isArray(d.messages) ? d.messages : [];
  const quests = Array.isArray(d.questionnaires) ? d.questionnaires : [];
  try { renderMessagesView(msgs, quests); } catch (e) { console.error("Error rendering messages:", e); }

  // View 6: 250h Absence Danger Zone
  try { renderAbsencesView(d.absences || []); } catch (e) { console.error("Error rendering absences:", e); }

  // View 7: Student Profile & Settings
  try { renderStudentView(d.student); } catch (e) { console.error("Error rendering student:", e); }
  try { renderSettingsView(); } catch (e) { console.error("Error rendering settings:", e); }
}

function renderDashboardHero(todayLessons) {
  const card = document.getElementById("dash-hero-card");
  const tagEl = document.getElementById("dash-hero-tag");
  const roomEl = document.getElementById("dash-hero-room");
  const subjectEl = document.getElementById("dash-hero-subject");
  const detailsEl = document.getElementById("dash-hero-details");
  const timeEl = document.getElementById("dash-hero-time");
  const statusEl = document.getElementById("dash-hero-status");
  const progressTrack = document.getElementById("dash-hero-progress-track");
  const progressFill = document.getElementById("dash-hero-progress-fill");
  const subBanner = document.getElementById("dash-hero-sub-banner");
  if (!card || !tagEl || !subjectEl || !detailsEl || !timeEl || !statusEl) return;

  card.style.display = "flex";

  const sorted = [...(todayLessons || [])].sort(
    (a, b) => new Date(a.KezdetIdopont) - new Date(b.KezdetIdopont)
  );

  // Check for any substitution or cancellation today
  const anomaly = sorted.find(l => {
    const st = (l.Allapot?.Nev || l.Allapot || "").toLowerCase();
    return st.includes("elmaradt") || !!l.HelyettesTanarNeve;
  });

  if (subBanner) {
    if (anomaly) {
      const st = (anomaly.Allapot?.Nev || anomaly.Allapot || "").toLowerCase();
      const isCanc = st.includes("elmaradt");
      const subName = getDisplaySubject(anomaly.Tantargy?.Nev || anomaly.Nev || "Tanóra");
      const slot = anomaly.Oraszam ? `${anomaly.Oraszam}. óra` : "";
      subBanner.style.display = "block";
      subBanner.className = isCanc ? "hero-sub-alert cancelled" : "hero-sub-alert";
      subBanner.innerText = isCanc
        ? `Elmaradó óra ma: ${slot} ${subName}`
        : `Helyettesítés ma: ${slot} ${subName} (${anomaly.HelyettesTanarNeve})`;
    } else {
      subBanner.style.display = "none";
    }
  }

  const now = new Date();
  let active = null;
  let next = null;

  for (const l of sorted) {
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
    const sub = getDisplaySubject(active.Tantargy?.Nev || active.Nev || "Tanóra");
    const room = active.TeremNeve ? `Terem: ${active.TeremNeve}` : "Terem: --";
    const teacher = active.HelyettesTanarNeve || active.TanarNeve || "";
    const start = new Date(active.KezdetIdopont);
    const end = new Date(active.VegIdopont);
    const minsLeft = Math.max(0, Math.ceil((end - now) / 60000));

    tagEl.innerText = "FOLYAMATBAN";
    tagEl.style.background = "var(--primary-fill)";
    tagEl.style.color = "var(--on-primary)";
    if (roomEl) roomEl.innerText = room;
    subjectEl.innerText = sub;
    detailsEl.innerText = [
      `${formatLocalTime(start)} - ${formatLocalTime(end)}`,
      teacher,
      active.Tema || ""
    ].filter(Boolean).join(" • ");
    timeEl.innerText = active.Oraszam != null ? `${active.Oraszam}. tanóra` : "Tanóra";
    statusEl.innerText = `${minsLeft} perc van hátra`;
    statusEl.style.color = "var(--primary)";

    if (progressTrack && progressFill) {
      const elapsed = now - start;
      const total = end - start;
      const pct = total > 0 ? Math.min(100, Math.max(0, (elapsed / total) * 100)) : 0;
      progressFill.style.width = `${pct}%`;
      progressTrack.style.display = "block";
    }
  } else if (next) {
    const sub = getDisplaySubject(next.Tantargy?.Nev || next.Nev || "Tanóra");
    const room = next.TeremNeve ? `Terem: ${next.TeremNeve}` : "Terem: --";
    const teacher = next.HelyettesTanarNeve || next.TanarNeve || "";
    const s = new Date(next.KezdetIdopont);
    const e = new Date(next.VegIdopont);
    const minsUntil = Math.max(0, Math.ceil((s - now) / 60000));

    tagEl.innerText = "SZÜNET • KÖVETKEZŐ ÓRA";
    tagEl.style.background = "rgba(255, 214, 10, 0.16)";
    tagEl.style.color = "var(--warning)";
    if (roomEl) roomEl.innerText = room;
    subjectEl.innerText = sub;
    detailsEl.innerText = [
      `${formatLocalTime(s)} - ${formatLocalTime(e)}`,
      teacher,
      next.Tema || ""
    ].filter(Boolean).join(" • ");
    timeEl.innerText = next.Oraszam != null ? `${next.Oraszam}. tanóra` : formatLocalTime(s);
    statusEl.innerText = `${minsUntil} perc múlva kezdődik`;
    statusEl.style.color = "var(--warning)";

    if (progressTrack) progressTrack.style.display = "none";
  } else {
    tagEl.innerText = sorted.length > 0 ? "MAI TANÍTÁS VÉGET ÉRT" : "TANÍTÁS NÉLKÜLI NAP";
    tagEl.style.background = "rgba(48, 209, 88, 0.16)";
    tagEl.style.color = "var(--success)";
    if (roomEl) roomEl.innerText = `${sorted.length} tanóra ma`;
    subjectEl.innerText = sorted.length > 0 ? "Mára nincs több tanórád" : "Nincs rögzített tanóra";
    detailsEl.innerText = "Tekintsd át a közelgő számonkéréseket vagy próbáld ki a Szellem Jegy Szimulátort.";
    timeEl.innerText = new Date().toLocaleDateString("hu-HU", { weekday: "long" });
    statusEl.innerText = "Szabadidő";
    statusEl.style.color = "var(--success)";

    if (progressTrack) progressTrack.style.display = "none";
  }
}

function renderDashboardTodayTimeline(todayLessons) {
  const listEl = document.getElementById("dash-today-timeline");
  const badgeEl = document.getElementById("dash-today-date-badge");
  if (!listEl) return;
  listEl.innerHTML = "";

  let lessonsToShow = [...(todayLessons || [])].sort(
    (a, b) => new Date(a.KezdetIdopont) - new Date(b.KezdetIdopont)
  );
  let isFallbackDay = false;

  // If today has no lessons (e.g. weekend), show Monday's lessons as preview
  if (lessonsToShow.length === 0 && fullState.data?.timetable?.length > 0) {
    const allSorted = [...fullState.data.timetable].sort(
      (a, b) => new Date(a.KezdetIdopont) - new Date(b.KezdetIdopont)
    );
    const firstDateKey = allSorted[0]?.KezdetIdopont ? localDateKey(allSorted[0].KezdetIdopont) : null;
    if (firstDateKey) {
      lessonsToShow = allSorted.filter(l => l.KezdetIdopont && localDateKey(l.KezdetIdopont) === firstDateKey);
      isFallbackDay = true;
    }
  }

  if (badgeEl) {
    badgeEl.innerText = isFallbackDay
      ? `Következő tanítási nap (${lessonsToShow.length} óra)`
      : `Ma (${lessonsToShow.length} óra)`;
  }

  if (lessonsToShow.length === 0) {
    listEl.innerHTML = `<div style="padding:18px; text-align:center; font-size:0.78rem; color:var(--text-muted);">Nincs rögzített órarendi adat.</div>`;
    return;
  }

  const nowMs = Date.now();
  lessonsToShow.forEach((l, idx) => {
    const sub = getDisplaySubject(l.Tantargy?.Nev || l.Nev || "Tanóra");
    const room = l.TeremNeve || "";
    const slot = l.Oraszam ?? (idx + 1);
    const startMs = l.KezdetIdopont ? new Date(l.KezdetIdopont).getTime() : 0;
    const endMs = l.VegIdopont ? new Date(l.VegIdopont).getTime() : 0;
    const stateRaw = (l.Allapot?.Nev || l.Allapot || "").toLowerCase();
    const isCanc = stateRaw.includes("elmaradt");
    const isSub = !isCanc && !!l.HelyettesTanarNeve;
    const isActive = !isFallbackDay && startMs > 0 && endMs > 0 && nowMs >= startMs && nowMs <= endMs;

    let cls = "timeline-mini-item";
    if (isActive) cls += " active";
    else if (isCanc) cls += " cancelled";
    else if (isSub) cls += " substitute";

    let tagHtml = room ? `<span class="room-pill">${escapeHtml(room)}</span>` : "";
    if (isCanc) {
      tagHtml = `<span class="badge badge-warning-soft">Elmaradt</span>`;
    } else if (isSub) {
      tagHtml = `<span class="badge badge-maintenance">Helyettesítés</span>`;
    } else if (isActive) {
      tagHtml = `<span class="badge banner-tag">Élő</span>`;
    }

    const timeRange = l.KezdetIdopont && l.VegIdopont
      ? `${formatLocalTime(l.KezdetIdopont)}-${formatLocalTime(l.VegIdopont)}`
      : "";

    const row = document.createElement("div");
    row.className = cls;
    row.innerHTML = `
      <div style="display:flex; align-items:center; gap:8px; min-width:0; flex:1;">
        <span class="lesson-slot-badge" style="width:22px; height:22px; font-size:0.7rem;">${escapeHtml(slot)}</span>
        <div style="min-width:0; flex:1;">
          <div style="font-weight:800; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; ${isCanc ? 'text-decoration:line-through; color:var(--text-muted);' : ''}">${escapeHtml(sub)}</div>
          <div style="font-size:0.66rem; color:var(--text-muted);">${escapeHtml(timeRange)}</div>
        </div>
      </div>
      ${tagHtml}
    `;
    listEl.appendChild(row);
  });
}

function renderDashboardUpcomingTasks(homework, exams) {
  const listEl = document.getElementById("dash-upcoming-tasks-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const combined = [
    ...(exams || []).map(e => ({
      isExam: true,
      sub: getDisplaySubject(e.Tantargy?.Nev || e.Tantargy || "Számonkérés"),
      title: e.Tema || e.Tipus?.Leiras || "Bejelentett számonkérés",
      date: e.Datum || e.OraKezdete || ""
    })),
    ...(homework || []).map(h => ({
      isExam: false,
      sub: getDisplaySubject(h.Tantargy?.Nev || h.Tantargy || "Házi feladat"),
      title: h.Szoveg || h.Feladat || "Házi feladat",
      date: h.HataridoDatuma || h.HataridoIdopontja || h.Hatarido || ""
    }))
  ].sort((a, b) => new Date(a.date || 0) - new Date(b.date || 0));

  if (combined.length === 0) {
    listEl.innerHTML = `<div style="padding:16px; text-align:center; font-size:0.78rem; color:var(--text-muted);">Nincs közelgő számonkérés vagy házi feladat.</div>`;
    return;
  }

  combined.slice(0, 4).forEach(item => {
    const row = document.createElement("div");
    row.className = "compact-task-row";
    const badgeCls = item.isExam ? "badge-warning-soft" : "badge-subtle";
    const badgeLabel = item.isExam ? "Dolgozat" : "Házi";
    const dateStr = item.date ? item.date.split("T")[0] : "";

    row.innerHTML = `
      <div style="min-width:0; flex:1;">
        <div style="display:flex; align-items:center; gap:6px; margin-bottom:2px;">
          <span class="badge ${badgeCls}" style="font-size:0.62rem; padding:1px 6px;">${badgeLabel}</span>
          <strong style="font-size:0.78rem; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(item.sub)}</strong>
        </div>
        <div style="font-size:0.72rem; color:var(--text-muted); white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(item.title)}</div>
      </div>
      <span style="font-size:0.68rem; color:var(--text-muted); flex-shrink:0;">${escapeHtml(dateStr)}</span>
    `;
    listEl.appendChild(row);
  });
}

function refreshGhostSimulations(providedSubjectMap = null) {
  const grades = fullState.data?.grades || [];
  const subjectMap = providedSubjectMap || {};
  if (!providedSubjectMap) {
    grades.forEach(g => {
      const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy";
      if (!subjectMap[sub]) subjectMap[sub] = [];
      subjectMap[sub].push(g);
    });
  }

  const subjects = Object.keys(subjectMap).sort();
  if (subjects.length === 0) subjects.push("Matematika");
  if (!dashGhostState.selectedSubject || !subjects.includes(dashGhostState.selectedSubject)) {
    dashGhostState.selectedSubject = subjects[0];
  }

  // Sync Dashboard Quick Select
  const quickSelect = document.getElementById("dash-quick-ghost-subject");
  if (quickSelect) {
    quickSelect.innerHTML = subjects
      .map(s => `<option value="${escapeHtml(s)}">${escapeHtml(getDisplaySubject(s))}</option>`)
      .join("");
    quickSelect.value = dashGhostState.selectedSubject;
  }

  // Sync Topbar Ghost Badge & Clear Button
  const topBadge = document.getElementById("topbar-ghost-badge");
  if (topBadge) {
    topBadge.style.display = dashGhostState.items.length > 0 ? "inline-flex" : "none";
    topBadge.innerText = String(dashGhostState.items.length);
  }
  const clearBtn = document.getElementById("btn-dash-ghost-clear");
  if (clearBtn) {
    clearBtn.style.display = dashGhostState.items.length > 0 ? "inline-block" : "none";
  }

  // Render Chips in both Quick Card and Grades View
  ["dash-quick-ghost-chips", "grades-view-ghost-chips"].forEach(cid => {
    const wrap = document.getElementById(cid);
    if (!wrap) return;
    wrap.innerHTML = "";
    dashGhostState.items.forEach(it => {
      const chip = document.createElement("button");
      chip.type = "button";
      chip.className = "ghost-chip";
      chip.title = "Kattints a szellem jegy törléséhez";
      chip.innerText = `${getDisplaySubject(it.subject).slice(0, 14)}: ${it.grade} (${it.weight}%) ×`;
      chip.addEventListener("click", () => {
        dashGhostState.items = dashGhostState.items.filter(x => x.id !== it.id);
        refreshGhostSimulations(subjectMap);
      });
      wrap.appendChild(chip);
    });
  });

  // Compute Real vs Projected for selectedSubject and Overall GPA
  let realSubSum = 0, realSubW = 0;
  let realTotSum = 0, realTotW = 0;

  grades.forEach(g => {
    const parsed = KretaApi.parseGrade(g);
    if (parsed.numericGrade !== null && !parsed.isSummary) {
      const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "";
      realTotSum += parsed.numericGrade * parsed.weight;
      realTotW += parsed.weight;
      if (sub === dashGhostState.selectedSubject) {
        realSubSum += parsed.numericGrade * parsed.weight;
        realSubW += parsed.weight;
      }
    }
  });

  let mockSubSum = 0, mockSubW = 0;
  let mockTotSum = 0, mockTotW = 0;
  dashGhostState.items.forEach(m => {
    const w = m.weight / 100;
    mockTotSum += m.grade * w;
    mockTotW += w;
    if (m.subject === dashGhostState.selectedSubject) {
      mockSubSum += m.grade * w;
      mockSubW += w;
    }
  });

  const curSubAvg = realSubW > 0 ? realSubSum / realSubW : 0;
  const projSubAvg = (realSubW + mockSubW) > 0 ? (realSubSum + mockSubSum) / (realSubW + mockSubW) : 0;
  const subDelta = projSubAvg - curSubAvg;

  const curGpa = realTotW > 0 ? realTotSum / realTotW : 0;
  const projGpa = (realTotW + mockTotW) > 0 ? (realTotSum + mockTotSum) / (realTotW + mockTotW) : 0;
  const gpaDelta = projGpa - curGpa;

  const subAvgEl = document.getElementById("dash-ghost-sub-avg");
  const subDeltaEl = document.getElementById("dash-ghost-sub-delta");
  if (subAvgEl) {
    subAvgEl.innerText = (realSubW + mockSubW) > 0
      ? (mockSubW > 0 ? `${curSubAvg.toFixed(2)} → ${projSubAvg.toFixed(2)}` : curSubAvg.toFixed(2))
      : "--";
  }
  if (subDeltaEl) {
    if (mockSubW > 0 && Math.abs(subDelta) >= 0.005) {
      subDeltaEl.innerText = `${subDelta >= 0 ? "+" : ""}${subDelta.toFixed(2)}`;
      subDeltaEl.style.color = subDelta >= 0 ? "var(--success)" : "var(--danger)";
    } else {
      subDeltaEl.innerText = "";
    }
  }

  const gpaAvgEl = document.getElementById("dash-ghost-gpa-avg");
  const gpaDeltaEl = document.getElementById("dash-ghost-gpa-delta");
  if (gpaAvgEl) {
    gpaAvgEl.innerText = (realTotW + mockTotW) > 0
      ? (mockTotW > 0 ? `${curGpa.toFixed(2)} → ${projGpa.toFixed(2)}` : curGpa.toFixed(2))
      : "--";
  }
  if (gpaDeltaEl) {
    if (mockTotW > 0 && Math.abs(gpaDelta) >= 0.005) {
      gpaDeltaEl.innerText = `${gpaDelta >= 0 ? "+" : ""}${gpaDelta.toFixed(2)}`;
      gpaDeltaEl.style.color = gpaDelta >= 0 ? "var(--success)" : "var(--danger)";
    } else {
      gpaDeltaEl.innerText = "";
    }
  }

  // Also update main stat card delta badge if ghost grades exist
  const dashAvgDeltaBadge = document.getElementById("dash-avg-delta-badge");
  if (dashAvgDeltaBadge) {
    if (mockTotW > 0 && Math.abs(gpaDelta) >= 0.005) {
      dashAvgDeltaBadge.style.display = "inline-flex";
      dashAvgDeltaBadge.innerText = `Szellem: ${projGpa.toFixed(2)} (${gpaDelta >= 0 ? "+" : ""}${gpaDelta.toFixed(2)})`;
      dashAvgDeltaBadge.style.color = gpaDelta >= 0 ? "var(--success)" : "var(--danger)";
    } else {
      dashAvgDeltaBadge.style.display = "none";
    }
  }

  renderGhostGradesAndPlanner(subjectMap);
  renderAllGradesView(grades, fullState.data?.groupAverages || []);
  renderGradesMatrixTable(grades, fullState.data?.groupAverages || []);
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
        <div class="grade-badge ${parsed.badgeClass}">${escapeHtml(parsed.displayValue)}</div>
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
      gradePills += `<div class="grade-badge ${parsed.badgeClass}" style="height:22px; font-size:0.75rem;">${escapeHtml(parsed.displayValue)}</div>`;
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

let abWeekOverride = null;
let showWeekType = true;

function renderWeeklyTimetable(timetable) {
  const listGrid = document.getElementById("weekly-timetable-grid");
  const matrixGrid = document.getElementById("matrix-timetable-grid");
  if (!listGrid || !matrixGrid) return;
  listGrid.innerHTML = "";
  matrixGrid.innerHTML = "";

  // Week rotation name straight from Kréta ("A hét", "C hét", ...); schools
  // without a rotation get no badge. Only the demo can flip it.
  const weekType = showWeekType ? fullState.data?.weekType || null : null;
  const abBadge = document.getElementById("timetable-ab-badge");
  const toggleBtn = document.getElementById("btn-toggle-ab-week");
  if (abBadge) abBadge.textContent = weekType || "";
  if (toggleBtn) {
    toggleBtn.style.display = weekType ? "inline-flex" : "none";
    toggleBtn.style.cursor = fullState.isDemo ? "pointer" : "default";
    toggleBtn.querySelector("svg")?.style.setProperty("display", fullState.isDemo ? "" : "none");
    toggleBtn.title = fullState.isDemo ? "Kattints a demó A/B hét váltásához" : "Az iskola hetirendje erre a hétre";
  }

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
        const slot = item.Oraszam ?? 1;
        matrixData[d][slot] = item;
      }
    }
  });

  // 1) List View (Only Mon-Fri usually, but we can do 1-5 to keep it as before)
  const todayWeekday = new Date().getDay() === 0 ? 7 : new Date().getDay();
  const nowMs = Date.now();

  for (let i = 1; i <= 5; i++) {
    const isToday = i === todayWeekday;
    const col = document.createElement("div");
    col.className = isToday ? "timetable-day-card today" : "timetable-day-card";
    const todayBadge = isToday ? `<span class="badge" style="background:var(--primary-fill); color:var(--on-primary); font-weight:900; font-size:0.65rem; border:none;">Ma</span>` : "";
    col.innerHTML = `<div class="day-title" style="display:flex; justify-content:space-between; align-items:center;"><span>${dayNames[i - 1]}</span>${todayBadge}</div>`;

    const lessons = dayBuckets[i];
    if (lessons.length === 0) {
      col.innerHTML += `
        <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; padding: 36px 12px; text-align: center; color: var(--text-muted);">
          <svg class="icon" viewBox="0 0 24 24" style="width: 26px; height: 26px; stroke: currentColor; stroke-width: 1.5; fill: none; opacity: 0.4; margin-bottom: 8px;"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><path d="M9 16l2 2 4-4"/></svg>
          <div style="font-size: 0.8rem; font-weight: 700; color: var(--text);">Nincs tanóra ezen a napon</div>
          <div style="font-size: 0.7rem; color: var(--text-muted); margin-top: 4px;">Tanítás nélküli munkanap / Szabadnap</div>
        </div>
      `;
    } else {
      lessons.forEach((l, idx) => {
        const itemEl = document.createElement("div");
        const sub = escapeHtml(getDisplaySubject(l.Tantargy?.Nev || l.Nev || "Tanóra"));
        const room = l.TeremNeve ? `Terem: ${escapeHtml(l.TeremNeve)}` : "";
        const substitute = l.HelyettesTanarNeve ? `Helyettesítő: ${escapeHtml(l.HelyettesTanarNeve)}` : "";

        const stateNameRaw = l.Allapot?.Nev || l.Allapot || "Megtartott";
        const stateName = escapeHtml(stateNameRaw);

        const startMs = l.KezdetIdopont ? new Date(l.KezdetIdopont).getTime() : 0;
        const endMs = l.VegIdopont ? new Date(l.VegIdopont).getTime() : 0;
        const isActive = isToday && startMs > 0 && endMs > 0 && nowMs >= startMs && nowMs <= endMs;
        const isPast = isToday && endMs > 0 && nowMs > endMs;
        const isCancelled = stateNameRaw.toLowerCase().includes("elmaradt");
        // Only a substitute teacher means a substitution. Real Kréta states are
        // "Naplozott" etc., never the demo's "Megtartott", so don't compare those.
        const isSub = !isCancelled && !!l.HelyettesTanarNeve;

        let pillClass = "lesson-pill";
        if (isActive) pillClass += " active";
        else if (isCancelled) pillClass += " cancelled";
        else if (isSub) pillClass += " substitute";
        else if (isPast) pillClass += " past";
        itemEl.className = pillClass;

        let statusBadgeHtml = "";
        if (isActive) {
          statusBadgeHtml = `<span class="badge" style="background:var(--primary-fill); color:var(--on-primary); font-weight:900; font-size:0.65rem; border:none; flex-shrink:0;">Folyamatban</span>`;
        } else if (isCancelled) {
          statusBadgeHtml = `<span class="badge" style="background:rgba(255,69,58,0.15); color:var(--danger); border:1px solid rgba(255,69,58,0.35); font-size:0.65rem; flex-shrink:0;">Elmaradt</span>`;
        } else if (isSub) {
          statusBadgeHtml = `<span class="badge" style="background:rgba(255,214,10,0.15); color:var(--warning); border:1px solid rgba(255,214,10,0.35); font-size:0.65rem; flex-shrink:0;">Helyettesítés</span>`;
        } else if (isPast) {
          statusBadgeHtml = `<span style="color:var(--success); font-weight:900; font-size:0.75rem; flex-shrink:0;">✓</span>`;
        }

        const slotNum = l.Oraszam ?? idx + 1;
        const timeSpan = l.KezdetIdopont && l.VegIdopont
          ? `${formatLocalTime(l.KezdetIdopont)} - ${formatLocalTime(l.VegIdopont)}`
          : "";
        const titleStyle = isCancelled ? "text-decoration: line-through; color: var(--text-muted);" : (isActive ? "color: var(--primary);" : "");
        const theme = l.Tema ? `<div style="font-size:0.68rem; color:var(--text-muted); margin-top:2px;">${escapeHtml(l.Tema)}</div>` : "";

        itemEl.innerHTML = `
          <div style="display:flex; align-items:center; gap:8px; min-width:0; flex:1;">
            <span class="lesson-slot-badge">${escapeHtml(slotNum)}</span>
            <div style="min-width:0; flex:1;">
              <div style="font-size:0.8rem; font-weight:700; ${titleStyle}; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${sub}</div>
              <div style="font-size:0.68rem; color:var(--text-muted);">${timeSpan ? timeSpan + ' • ' : ''}${room}${substitute ? ' • ' + substitute : ''}</div>
              ${theme}
            </div>
          </div>
          ${statusBadgeHtml}
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
        <th style="padding: 10px; width: 44px; color: var(--text-muted);">Óra</th>`;
  for (let i = 1; i <= 7; i++) {
    const isToday = i === todayWeekday;
    const headerStyle = isToday ? "color: var(--primary); font-weight: 800;" : "color: var(--text);";
    matrixHtml += `<th style="padding: 10px; ${headerStyle}">${dayNames[i-1]}${isToday ? ' (Ma)' : ''}</th>`;
  }
  matrixHtml += `</tr></thead><tbody>`;

  // Some schools have a 0th lesson or more than 10 a day.
  const usedSlots = Object.values(matrixData).flatMap(day => Object.keys(day).map(Number));
  const firstSlot = Math.min(1, ...usedSlots);
  const lastSlot = Math.max(10, ...usedSlots);
  for (let slot = firstSlot; slot <= lastSlot; slot++) {
    matrixHtml += `<tr style="border-bottom: 1px solid var(--border);">
      <td style="padding: 10px; font-weight: 800; color: var(--text-muted);">${slot}.</td>`;
    for (let day = 1; day <= 7; day++) {
      const l = matrixData[day][slot];
      if (l) {
        const sub = escapeHtml(getDisplaySubject(l.Tantargy?.Nev || l.Nev || "Tanóra"));
        const room = escapeHtml(l.TeremNeve || "");
        const stateName = l.Allapot?.Nev || l.Allapot || "Megtartott";
        let cellStyle = "padding: 8px 10px; border-left: 1px solid var(--border);";
        let contentStyle = "font-weight: 700; font-size: 0.78rem;";

        if (stateName.toLowerCase().includes("elmaradt")) {
          cellStyle += " background: rgba(255,69,58,0.1);";
          contentStyle = "text-decoration: line-through; color: var(--danger); font-weight: 600;";
        } else if (l.HelyettesTanarNeve) {
          cellStyle += " background: rgba(255,214,10,0.1);";
          contentStyle += " color: var(--warning);";
        }

        matrixHtml += `<td style="${cellStyle}">
          <div style="${contentStyle}">${sub}</div>
          <div style="font-size: 0.65rem; color: var(--text-muted);">${room}</div>
        </td>`;
      } else {
        matrixHtml += `<td style="padding: 8px 10px; border-left: 1px solid var(--border);"></td>`;
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

  const classAvgBySubject = {};
  (groupAverages || []).forEach(a => {
    const sub = a?.Tantargy?.Nev;
    const val = parseFloat(a?.OsztalyAtlag ?? a?.OsztalyCsoportAtlag ?? a?.Atlag ?? a?.Ertek);
    if (sub && !isNaN(val)) classAvgBySubject[sub] = val;
  });

  const subjectMap = {};
  grades.forEach(g => {
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy";
    if (!subjectMap[sub]) subjectMap[sub] = [];
    subjectMap[sub].push(g);
  });

  const qNorm = KretaApi.normalizeHu(gradesSearchQuery || "");
  const filteredSubjectNames = Object.keys(subjectMap).sort().filter(subName => {
    if (!qNorm) return true;
    const disp = getDisplaySubject(subName);
    if (KretaApi.normalizeHu(subName).includes(qNorm) || KretaApi.normalizeHu(disp).includes(qNorm)) return true;
    return subjectMap[subName].some(g => KretaApi.normalizeHu(g.Tema || "").includes(qNorm));
  });

  if (filteredSubjectNames.length === 0) {
    container.innerHTML = `<div style="grid-column:1/-1; text-align:center; padding:40px; color:var(--text-muted);">Nincs a keresésnek megfelelő tantárgy.</div>`;
    return;
  }

  filteredSubjectNames.forEach(subName => {
    const subGrades = subjectMap[subName].sort((a, b) => {
      const d1 = new Date(a.KeszitesDatuma || a.RogzitesDatuma || a.Datum || 0);
      const d2 = new Date(b.KeszitesDatuma || b.RogzitesDatuma || b.Datum || 0);
      return d1 - d2;
    });

    let sum = 0;
    let weightSum = 0;
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

    // Include ghost grades for this subject
    const subGhostItems = dashGhostState.items.filter(m => m.subject === subName);
    let ghostSum = 0;
    let ghostW = 0;
    subGhostItems.forEach(m => {
      const w = m.weight / 100;
      ghostSum += m.grade * w;
      ghostW += w;
    });

    const numAvg = weightSum > 0 ? (sum / weightSum) : 0;
    const projNumAvg = (weightSum + ghostW) > 0 ? ((sum + ghostSum) / (weightSum + ghostW)) : numAvg;
    const avg = (weightSum + ghostW) > 0 ? projNumAvg.toFixed(2) : "-";
    const avgColor = projNumAvg >= 4.5 ? "var(--success)" : (projNumAvg >= 3.5 ? "var(--info)" : (projNumAvg >= 2.5 ? "var(--warning)" : "var(--danger)"));

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
    if (projNumAvg > 0) {
      const rounded = Math.round(projNumAvg);
      if (Math.abs(projNumAvg - rounded) <= 0.3 && projNumAvg !== rounded) {
        warningHtml = `<span class="badge" style="background: rgba(255,214,10,0.15); color: var(--warning); border: none; font-size: 0.7rem; margin-left: 8px;">Közel a ${rounded}-hez/höz!</span>`;
      }
    }

    let classAvgHtml = "";
    const classAvg = classAvgBySubject[subName];
    if (classAvg !== undefined && projNumAvg > 0) {
      const delta = projNumAvg - classAvg;
      const deltaColor = delta > 0.05 ? "var(--success)" : (delta < -0.05 ? "var(--danger)" : "var(--text-muted)");
      const deltaText = delta > 0.05 ? `+${delta.toFixed(2)}` : (delta < -0.05 ? delta.toFixed(2) : "±0.00");
      classAvgHtml = `
        <div style="font-size:0.75rem; color:var(--text-muted); margin-top:4px;">
          Osztályátlag: <strong style="color:var(--text);">${classAvg.toFixed(2)}</strong>
          <span style="color:${deltaColor}; font-weight:700; margin-left:4px;">(${deltaText})</span>
        </div>`;
    }

    const card = document.createElement("div");
    card.className = "card grade-subject-card";

    let badgesHtml = "";
    subGrades.forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      badgesHtml += `<div class="grade-badge ${parsed.badgeClass}" style="height:28px; border-radius:8px; font-size:0.8rem; font-weight:800;" title="${escapeHtml(g.Tema || '')} (${parsed.weightPercent}%)">${escapeHtml(parsed.displayValue)}</div>`;
    });
    subGhostItems.forEach(m => {
      badgesHtml += `<div class="grade-badge grade-${m.grade} ghost-preview-pill" style="height:28px; border-radius:8px; font-size:0.8rem; font-weight:800;" title="Szellem jegy (${m.weight}%)">${m.grade}</div>`;
    });

    const ghostTagHtml = ghostW > 0
      ? `<span class="badge badge-demo" style="font-size:0.65rem;">Szimulált (${numAvg.toFixed(2)} → ${projNumAvg.toFixed(2)})</span>`
      : "";

    const sparklineHtml = createSparklineSvg(validGrades);

    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
        <div style="display:flex; align-items:center; flex-wrap: wrap; gap: 6px;">
          <strong style="font-size:0.95rem; color:var(--text);">${escapeHtml(getDisplaySubject(subName))}</strong>
          <span style="font-size:0.75rem; color:var(--text-muted);">${subGrades.length} jegy</span>
          ${ghostTagHtml}
          ${warningHtml}
        </div>
        <div style="text-align: right;">
          <div style="display:flex; align-items:center; gap: 8px; justify-content: flex-end;">
            <span style="font-size:1.1rem; color:var(--text-muted);">${trendArrow}</span>
            <div style="font-size:1.05rem; font-weight:900; padding: 4px 10px; border-radius: 10px; background: ${avgColor}20; color: ${avgColor}; border: 1px solid ${avgColor}40;">${avg}</div>
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

function renderGradesMatrixTable(grades, groupAverages = []) {
  const container = document.getElementById("grades-matrix-container");
  if (!container) return;
  container.innerHTML = "";

  if (!grades || grades.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:30px; color:var(--text-muted);">Nincsenek rögzített érdemjegyek.</div>`;
    return;
  }

  const classAvgBySubject = {};
  (groupAverages || []).forEach(a => {
    const sub = a?.Tantargy?.Nev;
    const val = parseFloat(a?.OsztalyAtlag ?? a?.OsztalyCsoportAtlag ?? a?.Atlag ?? a?.Ertek);
    if (sub && !isNaN(val)) classAvgBySubject[sub] = val;
  });

  const subjectMap = {};
  grades.forEach(g => {
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb tantárgy";
    if (!subjectMap[sub]) subjectMap[sub] = [];
    subjectMap[sub].push(g);
  });

  const qNorm = KretaApi.normalizeHu(gradesSearchQuery || "");
  const subjects = Object.keys(subjectMap).sort().filter(subName => {
    if (!qNorm) return true;
    const disp = getDisplaySubject(subName);
    return KretaApi.normalizeHu(subName).includes(qNorm) || KretaApi.normalizeHu(disp).includes(qNorm);
  });

  let html = `
    <table style="width:100%; border-collapse:collapse; font-size:0.82rem;">
      <thead>
        <tr style="border-bottom:2px solid var(--border); text-align:left; color:var(--text-muted); font-size:0.75rem;">
          <th style="padding:10px 12px; width:220px;">Tantárgy</th>
          <th style="padding:10px 12px;">Rögzített & Szimulált Érdemjegyek</th>
          <th style="padding:10px 12px; text-align:center; width:110px;">Osztályátlag</th>
          <th style="padding:10px 12px; text-align:right; width:110px;">Saját Átlag</th>
        </tr>
      </thead>
      <tbody>
  `;

  subjects.forEach(subName => {
    const subGrades = subjectMap[subName];
    let sum = 0, wSum = 0;
    let pillsHtml = "";

    subGrades.forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      if (parsed.numericGrade !== null && !parsed.isSummary) {
        sum += parsed.numericGrade * parsed.weight;
        wSum += parsed.weight;
      }
      pillsHtml += `<span class="grade-badge ${parsed.badgeClass}" style="width:26px; height:26px; font-size:0.78rem; margin-right:5px; margin-bottom:4px;" title="${escapeHtml(g.Tema || '')} (${parsed.weightPercent}%)">${escapeHtml(parsed.displayValue)}</span>`;
    });

    const ghostItems = dashGhostState.items.filter(m => m.subject === subName);
    ghostItems.forEach(m => {
      const w = m.weight / 100;
      sum += m.grade * w;
      wSum += w;
      pillsHtml += `<span class="grade-badge grade-${m.grade} ghost-preview-pill" style="width:26px; height:26px; font-size:0.78rem; margin-right:5px; margin-bottom:4px;" title="Szellem jegy (${m.weight}%)">${m.grade}</span>`;
    });

    const avgVal = wSum > 0 ? (sum / wSum) : 0;
    const avgStr = wSum > 0 ? avgVal.toFixed(2) : "-";
    const avgColor = avgVal >= 4.5 ? "var(--success)" : (avgVal >= 3.5 ? "var(--info)" : (avgVal >= 2.5 ? "var(--warning)" : "var(--danger)"));
    const classAvg = classAvgBySubject[subName];
    const classAvgStr = classAvg !== undefined ? classAvg.toFixed(2) : "-";

    html += `
      <tr style="border-bottom:1px solid var(--border);">
        <td style="padding:10px 12px; font-weight:800;">${escapeHtml(getDisplaySubject(subName))}</td>
        <td style="padding:10px 12px;">${pillsHtml}</td>
        <td style="padding:10px 12px; text-align:center; color:var(--text-muted); font-weight:700;">${classAvgStr}</td>
        <td style="padding:10px 12px; text-align:right; font-weight:900; font-size:0.95rem; color:${avgColor};">${avgStr}</td>
      </tr>
    `;
  });

  html += `</tbody></table>`;
  container.innerHTML = html;
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
        <title>${p.grade} (${escapeHtml(p.date)}${p.theme ? ' - ' + escapeHtml(p.theme) : ''})</title>
      </circle>`;
  });

  const gradId = `spark-grad-${Math.random().toString(36).substr(2, 7)}`;
  const startDate = pts[0].date;
  const endDate = pts[pts.length - 1].date;
  const dateRangeStr = (startDate && endDate) ? `${startDate} → ${endDate}` : `${validGrades.length} jegy`;

  return `
    <div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid rgba(255,255,255,0.06);">
      <div style="font-size:0.7rem; color:var(--text-muted); margin-bottom:4px; display:flex; justify-content:space-between;">
        <span>Időbeli alakulás (${escapeHtml(dateRangeStr)})</span>
        <span style="font-weight:600;">${validGrades.length} jegy</span>
      </div>
      <svg viewBox="0 0 ${width} ${height}" style="width:100%; height:44px; overflow:visible; display:block;">
        <defs>
          <linearGradient id="${gradId}" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="var(--primary)" stop-opacity="0.32"/>
            <stop offset="100%" stop-color="var(--primary)" stop-opacity="0.0"/>
          </linearGradient>
        </defs>
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

  const allItems = [
    ...exams.map(e => ({ type: "exam", sub: escapeHtml(getDisplaySubject(e.Tantargy?.Nev || e.Tantargy || "Dolgozat")), title: escapeHtml(e.Tema || e.Tipus?.Leiras || "Számonkérés"), date: e.Datum })),
    ...homework.map(h => ({ type: "hw", sub: escapeHtml(getDisplaySubject(h.Tantargy?.Nev || h.Tantargy || "Házi feladat")), title: escapeHtml(h.Szoveg || h.Feladat || "Házi feladat"), date: h.HataridoDatuma || h.HataridoIdopontja || h.Hatarido }))
  ];

  const items = currentTaskFilter === "all"
    ? allItems
    : allItems.filter(it => it.type === currentTaskFilter);

  if (items.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:40px; color:var(--text-muted);">Nincs a szűrésnek megfelelő házi feladat vagy számonkérés.</div>`;
    return;
  }

  items.forEach(it => {
    const isExam = it.type === "exam";
    const tag = isExam
      ? `<span class="badge badge-warning-soft" style="font-size:0.68rem;">SZÁMONKÉRÉS</span>`
      : `<span class="badge badge-subtle" style="color:var(--info); font-size:0.68rem;">HÁZI FELADAT</span>`;

    let dateText = "";
    if (it.date) {
      const d = new Date(it.date);
      dateText = `Határidő: ${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}.`;
    }

    const card = document.createElement("div");
    card.className = "card";
    card.style.marginBottom = "10px";
    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:6px; gap:8px; flex-wrap:wrap;">
        <div style="display:flex; align-items:center; gap:8px;">${tag} <strong style="font-size:0.92rem;">${it.sub}</strong></div>
        <span style="font-size:0.74rem; color:var(--text-muted);">${dateText}</span>
      </div>
      <div style="font-size:0.84rem; color:var(--text); line-height:1.45;">${it.title}</div>
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
  const limitPctEl = document.getElementById("absences-limit-pct");
  const remHoursEl = document.getElementById("absences-remaining-hours");

  if (limitPctEl) {
    limitPctEl.innerText = `${pct.toFixed(1)}%`;
    limitPctEl.className = "stat-val " + (totalHours < 150 ? "green" : (totalHours < 220 ? "orange" : "danger"));
  }
  if (remHoursEl) {
    remHoursEl.innerText = `${Math.max(0, 250 - totalHours)} óra maradt a határig`;
  }

  if (statusEl) {
    if (totalHours < 150) {
      statusEl.innerText = `Biztonságos (${pct.toFixed(1)}%)`;
      statusEl.style.color = "var(--success)";
      statusEl.style.borderColor = "rgba(48,209,88,0.3)";
    } else if (totalHours < 220) {
      statusEl.innerText = `Közelít a limithez (${pct.toFixed(1)}%)`;
      statusEl.style.color = "var(--warning)";
      statusEl.style.borderColor = "rgba(255,214,10,0.3)";
    } else {
      statusEl.innerText = `VESZÉLYZÓNA! (${pct.toFixed(1)}%)`;
      statusEl.style.color = "var(--danger)";
      statusEl.style.borderColor = "rgba(255,69,58,0.3)";
    }
  }

  if (barEl) {
    barEl.style.width = `${pct}%`;
    const glowClass = totalHours < 150 ? "progress-glow-success" : (totalHours < 220 ? "progress-glow-warning" : "progress-glow-danger");
    barEl.className = `progress-bar-fill ${glowClass}`;
  }

  let unexcusedCount = 0;
  let delayMinutes = 0;
  let parentalCount = 0;

  (absences || []).forEach(a => {
    const status = (a.IgazolasAllapota || "").toLowerCase();
    if (!status.includes("igazolt") && (a.KesesPercben || 0) === 0) {
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

  const justifiedCount = Math.max(0, totalHours - unexcusedCount);
  const justifiedEl = document.getElementById("absences-justified-count");
  if (justifiedEl) justifiedEl.innerText = `${justifiedCount}`;

  const unexcusedEl = document.getElementById("absences-unexcused-count");
  if (unexcusedEl) unexcusedEl.innerText = `${unexcusedCount}`;

  const delayEl = document.getElementById("absences-delay-minutes");
  if (delayEl) delayEl.innerText = `${delayMinutes} perc`;

  chrome.storage.local.get("pala_parental_limit").then(res => {
    const limit = res.pala_parental_limit || 3;
    const maxLessons = limit * 7;
    const usedDays = Math.ceil(parentalCount / 7);
    const parentStatus = document.getElementById("absences-parental-status");
    if (parentStatus) parentStatus.innerText = `${parentalCount} / ${maxLessons} óra`;

    const parentVal = document.getElementById("absences-parental-val");
    if (parentVal) parentVal.innerText = `${usedDays} / ${limit} nap`;

    const parentSub = document.getElementById("absences-parental-sub");
    if (parentSub) {
      const remDays = Math.max(0, limit - usedDays);
      parentSub.innerText = `${remDays} nap felhasználható (${parentalCount} óra)`;
    }

    const parentBar = document.getElementById("absences-parental-bar");
    if (parentBar) {
      const pPct = Math.min(100, (parentalCount / maxLessons) * 100);
      parentBar.style.width = `${pPct}%`;
      const pGlow = pPct < 70 ? "progress-glow-primary" : (pPct < 90 ? "progress-glow-warning" : "progress-glow-danger");
      parentBar.className = `progress-bar-fill ${pGlow}`;
    }
  });

  if (!absences || absences.length === 0) {
    container.innerHTML = `<div style="text-align:center; padding:40px; color:var(--text-muted);">Nincs rögzített mulasztás.</div>`;
    return;
  }

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
    riskBanner.style.cssText = "background: rgba(255,69,58,0.1); border: 1px solid rgba(255,69,58,0.3); border-radius: 12px; padding: 12px 16px; margin-bottom: 14px; font-size: 0.78rem; color: var(--danger); line-height: 1.45;";
    riskBanner.innerHTML = `<strong>Figyelem!</strong> Az alábbi tantárgy(ak)ból a hiányzások elérték a 20%-os kritikus határt: <strong>${highRiskSubjects.join(", ")}</strong>. (Osztályozó vizsga kockázat!)`;
    container.appendChild(riskBanner);
  }

  const filteredAbsences = absences.filter(a => {
    const statusRaw = (a.IgazolasAllapota || "Igazolatlan").toLowerCase();
    const isJustified = statusRaw.includes("igazolt");
    const isDelay = (a.KesesPercben || 0) > 0;
    if (currentAbsenceFilter === "unexcused") return !isJustified && !isDelay;
    if (currentAbsenceFilter === "justified") return isJustified;
    if (currentAbsenceFilter === "delays") return isDelay;
    return true;
  });

  if (filteredAbsences.length === 0) {
    container.innerHTML += `<div style="text-align:center; padding:32px; color:var(--text-muted);">Nincs a szűrőnek megfelelő mulasztás.</div>`;
    return;
  }

  filteredAbsences.forEach(a => {
    const rawSub = a.Tantargy?.Nev || a.Tantargy || "Tanóra";
    const sub = escapeHtml(getDisplaySubject(rawSub));
    const totalInSub = subAbsenceCounts[rawSub] || 0;
    const riskBadge = totalInSub >= 15
      ? `<span class="badge" style="background:rgba(255,69,58,0.15); color:var(--danger); border:1px solid rgba(255,69,58,0.3); font-size:0.68rem; margin-left:6px;" title="${totalInSub} óra mulasztás ebből a tárgyból">20% kockázat</span>`
      : "";

    const statusRaw = a.IgazolasAllapota || "Igazolatlan";
    const status = escapeHtml(statusRaw);
    const delayMins = a.KesesPercben || 0;
    const type = escapeHtml(a.Tipus?.Leiras || a.Tipus || (delayMins > 0 ? `Késés (${delayMins} perc)` : "Mulasztás"));
    const isJustified = statusRaw.toLowerCase().includes("igazolt");

    let dateText = "";
    const dateRaw = a.Datum || a.OraKezdete;
    if (dateRaw) {
      const d = new Date(dateRaw);
      dateText = `${d.getFullYear()}. ${d.getMonth() + 1}. ${d.getDate()}.`;
    }

    const row = document.createElement("div");
    row.className = "table-row";
    const statusBg = isJustified ? "rgba(48,209,88,0.15)" : "rgba(255,69,58,0.15)";
    const statusBorder = isJustified ? "rgba(48,209,88,0.35)" : "rgba(255,69,58,0.35)";
    const statusColor = isJustified ? "var(--success)" : "var(--danger)";

    row.innerHTML = `
      <div>
        <div style="display:flex; align-items:center;">
          <strong style="font-size:0.88rem; color:var(--text);">${sub}</strong>
          ${riskBadge}
        </div>
        <div style="font-size:0.72rem; color:var(--text-muted); margin-top:2px;">${type} • ${dateText}</div>
      </div>
      <span class="badge" style="background:${statusBg}; color:${statusColor}; border:1px solid ${statusBorder}; font-size:0.72rem; font-weight:700;">
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
        compSelect.innerHTML += `<option value="${escapeHtml(t.id)}">${escapeHtml(t.name)}${subStr}</option>`;
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
          <a href="https://eugyintezes.e-kreta.hu/adatbekeresek" target="_blank" class="btn btn-primary" style="text-decoration:none; display:inline-block;">Kérdőívek megnyitása (e-Ügyintézés)</a>
        </div>
      `;
      return;
    }

    const tableWrapper = document.createElement("div");
    tableWrapper.className = "table-container";
    tableWrapper.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; flex-wrap:wrap; gap:8px;">
        <span style="font-size:0.85rem; font-weight:700; color:var(--text);">Kitöltendő és lezárt kérdőívek (${allQuests.length})</span>
        <a href="https://eugyintezes.e-kreta.hu/adatbekeresek" target="_blank" class="btn btn-secondary btn-sm" style="text-decoration:none; font-size:0.75rem;">Kérdőívek megnyitása a Krétán</a>
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
      <p style="font-size: 0.84rem; line-height: 1.5; color: var(--text-muted); margin: 0; white-space: pre-line; max-height: 48px; overflow: hidden; text-overflow: ellipsis;">${escapeHtml(kretaHtmlToText(m.content) || "(Kattints a részletek megtekintéséhez)")}</p>
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
    renderKretaContent(contentEl, msg.content || "Szövegtartalom betöltése...");
  }

  // If content is empty and it's an e-ugyintezes message, fetch full content
  if (!msg.content && msg.source === "eugyintezes" && msg.id) {
    const session = await SecureSession.load();
    if (session?.token) {
      const token = await KretaApi.ensureValidToken(session);
      const fullText = await KretaApi.getMessageContent(token, msg.id);
      if (fullText && contentEl) {
        renderKretaContent(contentEl, fullText);
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
  if (instInput && !fullState.isDemo && !instInput.value && store.pala_session?.institute) {
    instInput.value = store.pala_session.institute;
  } else if (instInput && fullState.isDemo) {
    instInput.value = "";
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

    const sizeEl = document.getElementById("dash-popup-pref-size");
    if (sizeEl) sizeEl.value = s.popupSize || "medium";

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
  // In demo mode, strictly prevent real student extra data from leaking into Teszt Elek's profile
  const extra = fullState.isDemo ? {} : (extraStore.pala_student_extra || {});

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
        <strong style="font-size: 0.85rem;">${escapeHtml(g.Nev || "-")}</strong>
        <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 4px; display: flex; flex-direction: column; gap: 2px;">
          <div>Email: ${escapeHtml(g.Email || g.EmailCim || "Nincs megadva")}</div>
          <div>Telefon: ${escapeHtml(g.Telefonszam || "Nincs megadva")}</div>
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
        <strong>${escapeHtml(studentName)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Születési név:</span>
        <strong>${escapeHtml(birthName)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Oktatási azonosító (OM):</span>
        <strong style="color: var(--primary);">${escapeHtml(omId)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Születési hely:</span>
        <strong>${escapeHtml(birthPlace)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Születési idő:</span>
        <strong>${escapeHtml(birthDate)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Anyja neve:</span>
        <strong>${escapeHtml(motherName)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Cím (Lakcím/Tartózkodási):</span>
        <strong style="text-align: right; max-width: 60%;">${escapeHtml(address)}</strong>
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
        <strong style="text-align: right; max-width: 65%; font-size: 0.82rem;">${escapeHtml(instName)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Intézmény kódja:</span>
        <strong>${escapeHtml(instCode)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Osztály / Évfolyam:</span>
        <strong>${escapeHtml(classGrade)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Tanulói Email:</span>
        <strong>${escapeHtml(email)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Telefonszám:</span>
        <strong>${escapeHtml(phone)}</strong>
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
        <strong style="font-family: monospace; font-size: 0.88rem; letter-spacing: 0.5px;">${escapeHtml(bankAccount)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Számlavezető bank:</span>
        <strong>${escapeHtml(bankName)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Bankszámla tulajdonos neve:</span>
        <strong>${escapeHtml(bankOwner)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Bankszámla tulajdonosa:</span>
        <strong style="text-transform: capitalize;">${escapeHtml(bankOwnerType)}</strong>
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
        <strong style="font-family: monospace; font-size: 0.88rem; color: var(--primary);">${escapeHtml(taxId)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">TAJ-szám:</span>
        <strong style="font-family: monospace; font-size: 0.88rem;">${escapeHtml(tajNumber)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Igazolvány típusa:</span>
        <strong>${escapeHtml(idType)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Igazolvány száma:</span>
        <strong>${escapeHtml(idNumber)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Diákigazolvány száma:</span>
        <strong>${escapeHtml(studentCardNumber)}</strong>
      </div>
      <div style="display: flex; justify-content: space-between; border-bottom: 1px solid var(--border); padding-bottom: 5px;">
        <span style="color: var(--text-muted);">Diákigazolvány kelte / érvényessége:</span>
        <strong>${escapeHtml(studentCardDate)}</strong>
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
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--info);">4-es</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: var(--info);">${count4}</div>
      </div>
      <div style="background: rgba(255,214,10,0.12); border: 1px solid rgba(255,214,10,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--warning);">3-as</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: var(--warning);">${count3}</div>
      </div>
      <div style="background: rgba(255,159,10,0.12); border: 1px solid rgba(255,159,10,0.3); border-radius: 8px; padding: 8px 4px;">
        <div style="font-size: 0.75rem; font-weight: 700; color: var(--primary);">2-es</div>
        <div style="font-size: 1.15rem; font-weight: 800; color: var(--primary);">${count2}</div>
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
  // In demo mode, strictly prevent real student extra data from appearing in modal
  const extra = fullState.isDemo ? {} : (extraStore.pala_student_extra || {});
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
    if (fullState.isDemo) {
      if (statusEl) {
        statusEl.innerText = "Demó módban a módosítások nem írják felül a valós adatokat.";
        statusEl.style.display = "block";
        statusEl.style.color = "var(--primary)";
      }
      setTimeout(() => closeModal(), 800);
      return;
    }
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

    let ghostSum = 0;
    let ghostW = 0;
    dashGhostState.items.filter(item => item.subject === sub).forEach(item => {
      const gw = (item.weight || 100) / 100;
      ghostSum += item.grade * gw;
      ghostW += gw;
    });

    const newAvg = ghostW > 0
      ? (sum + ghostSum) / (wSum + ghostW)
      : (sum + newGrade * w) / (wSum + w);
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
        Jelenlegi: ${currentAvg.toFixed(2)} &rarr; Szimulált: ${newAvg.toFixed(2)}
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
            <td style="padding: 8px; font-weight:700;">${escapeHtml(sub)}</td>
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
    const teacher = l.TanarNeve;
    const substitute = l.HelyettesTanarNeve;
    if (teacher) names.add(teacher);
    if (substitute) names.add(substitute);
  });
  return Array.from(names).sort((a, b) => a.localeCompare(b, "hu"));
}

let teachersLoading = false;

function renderAliasSuggestions(filterText) {
  const box = document.getElementById("alias-orig-suggestions");
  if (!box) return;

  // Only show while the user is typing in the field. Category switches and the
  // async teacher load also call this, and a box opened without focus never
  // gets the blur that closes it, so it would cover the alias list for good.
  if (document.activeElement !== document.getElementById("alias-orig-input")) {
    box.style.display = "none";
    return;
  }

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
      <div style="background: rgba(var(--primary-rgb), 0.08); border: 1px solid rgba(var(--primary-rgb), 0.3); border-radius: 12px; padding: 18px; text-align: center;">
        <span class="badge" style="background: var(--primary-fill); color: var(--on-primary); font-weight: 800; margin-bottom: 8px;">HIVATALOS TANÉVZÁRÓ</span>
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
