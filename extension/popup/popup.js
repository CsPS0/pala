// Pala Extension - Popup Logic

const DEFAULT_POPUP_SETTINGS = {
  defaultTab: "tab-today",
  showHeroCard: true,
  compactMode: false,
  showAverageBar: true,
  maxGrades: 10,
  maxTasks: 5
};

/** Applies dark (default) or light mode by setting/removing data-theme on <html>. */
function applyThemeMode(isDark) {
  if (isDark) {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.setAttribute("data-theme", "light");
  }
}

let currentPopupSettings = { ...DEFAULT_POPUP_SETTINGS };

let appState = {
  isDemo: true,
  data: null
};

document.addEventListener("DOMContentLoaded", async () => {
  // Apply saved dark/light mode (dark is the default).
  const themeStore = await chrome.storage.local.get("pala_dark_mode");
  applyThemeMode(themeStore.pala_dark_mode !== false);

  setupTabs();
  setupActions();
  setupPopupSettingsModal();

  const settingsStore = await chrome.storage.local.get("pala_popup_settings");
  applyPopupSettings(settingsStore.pala_popup_settings, true);

  await loadData();
  startCountdownTimer();
});

chrome.storage?.onChanged?.addListener((changes) => {
  if (changes.pala_dark_mode) {
    applyThemeMode(changes.pala_dark_mode.newValue !== false);
  }
});

function switchTab(targetTabId) {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(t => {
    const isTarget = t.getAttribute("data-tab") === targetTabId;
    t.classList.toggle("active", isTarget);
  });
  document.querySelectorAll(".tab-panel").forEach(p => {
    p.classList.toggle("active", p.id === targetTabId);
  });
}

function applyPopupSettings(settings, isInitial = false) {
  if (!settings) return;
  currentPopupSettings = { ...DEFAULT_POPUP_SETTINGS, ...settings };

  if (isInitial && currentPopupSettings.defaultTab) {
    switchTab(currentPopupSettings.defaultTab);
  }

  const heroCard = document.getElementById("active-class-card");
  if (heroCard) {
    heroCard.style.display = currentPopupSettings.showHeroCard === false ? "none" : "block";
  }
  document.body.classList.toggle("hero-hidden", currentPopupSettings.showHeroCard === false);
  document.body.classList.toggle("compact-mode", currentPopupSettings.compactMode === true);

  const avgBar = document.querySelector(".stat-summary");
  if (avgBar) {
    avgBar.style.display = currentPopupSettings.showAverageBar === false ? "none" : "flex";
  }
}

function setupPopupSettingsModal() {
  const modal = document.getElementById("popup-settings-modal");
  const openBtn = document.getElementById("btn-popup-settings");
  const closeBtn = document.getElementById("btn-close-popup-settings");
  const saveBtn = document.getElementById("btn-save-popup-settings");

  const populateForm = () => {
    const tabSelect = document.getElementById("popup-pref-default-tab");
    if (tabSelect) tabSelect.value = currentPopupSettings.defaultTab || "tab-today";

    const heroCheck = document.getElementById("popup-pref-show-hero");
    if (heroCheck) heroCheck.checked = currentPopupSettings.showHeroCard !== false;

    const compactCheck = document.getElementById("popup-pref-compact");
    if (compactCheck) compactCheck.checked = currentPopupSettings.compactMode === true;

    const avgCheck = document.getElementById("popup-pref-show-average");
    if (avgCheck) avgCheck.checked = currentPopupSettings.showAverageBar !== false;

    const maxGrades = document.getElementById("popup-pref-max-grades");
    if (maxGrades) maxGrades.value = String(currentPopupSettings.maxGrades ?? 10);

    const maxTasks = document.getElementById("popup-pref-max-tasks");
    if (maxTasks) maxTasks.value = String(currentPopupSettings.maxTasks ?? 5);
  };

  openBtn?.addEventListener("click", async () => {
    populateForm();
    const darkStore = await chrome.storage.local.get("pala_dark_mode");
    const darkToggle = document.getElementById("popup-dark-mode-toggle");
    if (darkToggle) darkToggle.checked = darkStore.pala_dark_mode !== false;
    modal?.classList.add("active");
  });

  document.getElementById("popup-dark-mode-toggle")?.addEventListener("change", async (e) => {
    const dark = e.target.checked;
    applyThemeMode(dark);
    await chrome.storage.local.set({ pala_dark_mode: dark });
  });

  closeBtn?.addEventListener("click", () => {
    modal?.classList.remove("active");
  });

  saveBtn?.addEventListener("click", async () => {
    const newSettings = {
      defaultTab: document.getElementById("popup-pref-default-tab")?.value || "tab-today",
      showHeroCard: document.getElementById("popup-pref-show-hero")?.checked !== false,
      compactMode: document.getElementById("popup-pref-compact")?.checked === true,
      showAverageBar: document.getElementById("popup-pref-show-average")?.checked !== false,
      maxGrades: parseInt(document.getElementById("popup-pref-max-grades")?.value || "10", 10),
      maxTasks: parseInt(document.getElementById("popup-pref-max-tasks")?.value || "5", 10)
    };

    await chrome.storage.local.set({ pala_popup_settings: newSettings });
    applyPopupSettings(newSettings);
    modal?.classList.remove("active");

    if (appState.data) {
      renderGrades(appState.data.grades || []);
      renderTasks(appState.data.homework || [], appState.data.exams || []);
    }
  });
}

function setupTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(btn => {
    btn.addEventListener("click", () => {
      const target = btn.getAttribute("data-tab");
      switchTab(target);
    });
  });
}

function setupActions() {
  document.getElementById("btn-open-dashboard")?.addEventListener("click", () => {
    chrome.tabs.create({ url: chrome.runtime.getURL("dashboard/dashboard.html") });
  });

  document.getElementById("btn-refresh")?.addEventListener("click", async () => {
    await loadData(true);
  });

  document.getElementById("btn-account-switch")?.addEventListener("click", () => {
    const modal = document.getElementById("login-modal");
    modal?.classList.toggle("active");
  });

  document.getElementById("btn-toggle-sim-maintenance")?.addEventListener("click", async () => {
    const store = await chrome.storage.local.get("pala_simulate_maintenance");
    const nextState = !store.pala_simulate_maintenance;
    await chrome.storage.local.set({ pala_simulate_maintenance: nextState });
    document.getElementById("login-modal")?.classList.remove("active");
    await loadData(true);
  });

  document.getElementById("btn-maintenance-retry")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_simulate_maintenance: false });
    await loadData(true);
  });

  document.getElementById("btn-maint-retry")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_simulate_maintenance: false });
    await loadData(true);
  });

  document.getElementById("btn-maint-demo")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_use_demo: true, pala_simulate_maintenance: false });
    await loadData(true);
  });

  document.getElementById("btn-demo-mode")?.addEventListener("click", async () => {
    await SecureSession.save(null);
    await chrome.storage.local.set({ pala_use_demo: true, pala_simulate_maintenance: false });
    document.getElementById("login-modal")?.classList.remove("active");
    await loadData(true);
  });

  // School Autocomplete
  const schoolInput = document.getElementById("login-institute");
  const schoolHidden = document.getElementById("login-institute-code");
  const schoolDropdown = document.getElementById("school-dropdown");
  const schoolInfo = document.getElementById("selected-school-info");

  let schoolDebounce = null;
  schoolInput?.addEventListener("input", () => {
    clearTimeout(schoolDebounce);
    if (schoolHidden) schoolHidden.value = "";
    if (schoolInfo) schoolInfo.style.display = "none";

    const query = schoolInput.value.trim();
    if (query.length < 2) {
      if (schoolDropdown) {
        schoolDropdown.style.display = "none";
        schoolDropdown.innerHTML = "";
      }
      return;
    }

    schoolDebounce = setTimeout(async () => {
      if (!schoolDropdown) return;
      schoolDropdown.innerHTML = '<div style="padding:8px 10px; font-size:0.75rem; color:var(--text-muted);">Keresés...</div>';
      schoolDropdown.style.display = "block";

      const schools = await KretaApi.searchSchools(query);
      if (schools.length === 0) {
        schoolDropdown.innerHTML = '<div style="padding:8px 10px; font-size:0.75rem; color:var(--text-muted);">Nincs találat. Beírhatsz közvetlen kódot is.</div>';
        return;
      }

      schoolDropdown.innerHTML = "";
      schools.forEach(s => {
        const item = document.createElement("div");
        item.className = "school-item";
        item.innerHTML = `<div><strong>${escapeHtml(s.name)}</strong></div><div style="font-size:0.68rem; color:var(--primary); margin-top:2px;">Kód: ${escapeHtml(s.code)}</div>`;
        item.addEventListener("click", () => {
          schoolInput.value = s.name;
          if (schoolHidden) schoolHidden.value = s.code;
          schoolDropdown.style.display = "none";
          if (schoolInfo) {
            schoolInfo.innerText = `Kiválasztva: ${s.code}`;
            schoolInfo.style.display = "block";
          }
        });
        schoolDropdown.appendChild(item);
      });
    }, 250);
  });

  document.addEventListener("click", (e) => {
    if (!schoolInput?.contains(e.target) && !schoolDropdown?.contains(e.target)) {
      if (schoolDropdown) schoolDropdown.style.display = "none";
    }
  });

  document.getElementById("btn-web-login")?.addEventListener("click", async () => {
    const inst = schoolHidden?.value.trim() || schoolInput?.value.trim() || "klik039000";
    const errBox = document.getElementById("login-error");

    const authUrl = await KretaApi.startWebLogin(inst);

    if (errBox) {
      errBox.innerText = "Megnyitás a böngészőben... Jelentkezz be a hivatalos Kréta felületen!";
      errBox.style.display = "block";
      errBox.style.color = "var(--primary)";
    }

    chrome.tabs.create({ url: authUrl });
  });

  // Listen for background login or sync updates.
  // Use forceRefresh=true when the session itself changes (new login) so the
  // fresh token is used to fetch data immediately instead of serving stale cache.
  chrome.storage.onChanged?.addListener((changes, area) => {
    if (area !== "local") return;
    if (changes.pala_session || changes.pala_maintenance_mode) {
      loadData(true);
    } else if (changes.pala_cached_data) {
      loadData(false);
    } else if (changes.pala_popup_settings) {
      applyPopupSettings(changes.pala_popup_settings.newValue);
      if (appState.data) {
        renderGrades(appState.data.grades || []);
        renderTasks(appState.data.homework || [], appState.data.exams || []);
      }
    }
  });

  // Listen for broadcast messages from service worker (session changed, data updated)
  chrome.runtime.onMessage?.addListener((msg) => {
    if (msg?.type === "pala_session_changed" || msg?.type === "pala_data_updated") {
      loadData(true);
    }
  });
}

async function loadData(forceRefresh = false) {
  const store = await chrome.storage.local.get([
    "pala_use_demo",
    "pala_cached_data",
    "pala_maintenance_mode",
    "pala_simulate_maintenance"
  ]);
  const session = await SecureSession.load();
  const useDemo = store.pala_use_demo !== false; // Default to demo if not set

  if (useDemo || !session) {
    appState.isDemo = true;
    appState.isMaintenance = false;
    appState.data = KretaApi.getDemoDataset();
  } else {
    appState.isDemo = false;

    // Auto-force a live fetch when session exists but no cached data is available
    // (e.g. right after a fresh login where the background fetch failed).
    if (!forceRefresh && !store.pala_cached_data) {
      forceRefresh = true;
      const studentNameEl = document.getElementById("student-name");
      if (studentNameEl) studentNameEl.innerText = "Adatok betöltése...";
    }

    try {
      appState.data = await KretaApi.getCachedOrFetchData(session, forceRefresh);
      appState.isMaintenance = appState.data?.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
    } catch (err) {
      console.warn("Could not fetch online Kréta data, falling back to cached:", err);
      const isMaint = err.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
      appState.isMaintenance = isMaint;
      appState.data = store.pala_cached_data ? { ...store.pala_cached_data, isMaintenance: true } : null;
    }
  }

  renderUI();
}

function renderUI() {
  const data = appState.data;
  const maintBanner = document.getElementById("maintenance-banner");
  const maintView = document.getElementById("tab-maintenance");
  const heroCard = document.getElementById("active-class-card");
  const tabBar = document.getElementById("popup-tab-bar");
  const contentPanels = document.querySelectorAll(".tab-panel:not(#tab-maintenance)");

  // Handle Maintenance state
  if (appState.isMaintenance) {
    if (!data) {
      // Full maintenance screen (no cached data available)
      if (maintView) maintView.style.display = "block";
      if (maintBanner) maintBanner.style.display = "none";
      if (heroCard) heroCard.style.display = "none";
      if (tabBar) tabBar.style.display = "none";
      contentPanels.forEach(p => p.style.display = "none");

      const badgeEl = document.getElementById("status-badge");
      if (badgeEl) {
        badgeEl.className = "badge badge-maintenance";
        badgeEl.innerText = "Karbantartás";
      }
      return;
    } else {
      // Offline cached view with alert banner
      if (maintBanner) maintBanner.style.display = "block";
      if (maintView) maintView.style.display = "none";
      if (heroCard) heroCard.style.display = "block";
      if (tabBar) tabBar.style.display = "flex";

      const badgeEl = document.getElementById("status-badge");
      if (badgeEl) {
        badgeEl.className = "badge badge-maintenance";
        badgeEl.innerText = "Karbantartás • Offline";
      }
    }
  } else {
    if (maintBanner) maintBanner.style.display = "none";
    if (maintView) maintView.style.display = "none";
    if (heroCard) heroCard.style.display = "block";
    if (tabBar) tabBar.style.display = "flex";
  }

  if (!data) {
    const studentNameEl = document.getElementById("student-name");
    if (studentNameEl) studentNameEl.innerText = "Bejelentkezés szükséges";
    const studentSchoolEl = document.getElementById("student-school");
    if (studentSchoolEl) studentSchoolEl.innerText = "Kattints a fogaskerékre!";
    const badgeEl = document.getElementById("status-badge");
    if (badgeEl) {
      badgeEl.className = "badge badge-figyelmeztetes";
      badgeEl.innerText = "Lejárt";
    }
    if (heroCard) {
      heroCard.innerHTML = `
        <div style="padding: 12px; text-align: center;">
          <div style="font-weight: 700; font-size: 0.9rem; margin-bottom: 6px;">A munkamenet lejárt</div>
          <div style="font-size: 0.76rem; color: var(--text-muted); margin-bottom: 10px;">Jelentkezz be újra a beállítások menüben, vagy válts át Demó módra.</div>
          <button id="btn-popup-relogin" class="btn btn-primary btn-sm" style="font-size: 0.78rem;">Bejelentkezés / Demó</button>
        </div>
      `;
      document.getElementById("btn-popup-relogin")?.addEventListener("click", () => {
        document.getElementById("btn-account-switch")?.click();
      });
    }
    return;
  }

  // Header: Name & School
  const studentNameEl = document.getElementById("student-name");
  if (studentNameEl) studentNameEl.innerText = data.student?.Nev || "Diák";

  const studentSchoolEl = document.getElementById("student-school");
  if (studentSchoolEl) {
    const instName = data.student?.IntezmenyNev ||
                     data.student?.Intezmeny?.TeljesNev ||
                     data.student?.Intezmeny?.Nev ||
                     (appState.isDemo ? "Pala Minta Gimnázium" : "");
    studentSchoolEl.innerText = instName;
  }

  if (!appState.isMaintenance) {
    const badgeEl = document.getElementById("status-badge");
    if (badgeEl) {
      if (appState.isDemo) {
        badgeEl.className = "badge badge-demo";
        badgeEl.innerText = "Demó (Teszt Elek)";
      } else {
        badgeEl.className = "badge";
        badgeEl.style.color = "var(--success)";
        badgeEl.style.borderColor = "rgba(48,209,88,0.4)";
        badgeEl.style.background = "rgba(48,209,88,0.12)";
        badgeEl.innerText = "Online";
      }
    }
  }

  renderTimetable(data.timetable || []);
  renderGrades(data.grades || []);
  renderTasks(data.homework || [], data.exams || []);
  updateActiveClass(data.timetable || []);
}

function renderTimetable(timetable) {
  const listEl = document.getElementById("timetable-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const now = new Date();
  const todayIso = now.toISOString().split("T")[0];

  // Filter lessons for today
  const todayLessons = (timetable || []).filter(item => {
    if (!item.KezdetIdopont) return true;
    const itemDate = new Date(item.KezdetIdopont).toISOString().split("T")[0];
    return itemDate === todayIso;
  });

  const displayList = todayLessons.length > 0 ? todayLessons : timetable;

  if (displayList.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 24px; color: var(--text-muted); font-size: 0.78rem;">Nincs rögzített tanóra mára.</div>`;
    return;
  }

  displayList.forEach((item, idx) => {
    const card = document.createElement("div");
    card.className = "item-card";
    const subName = item.Tantargy?.Nev || item.Tantargy || item.Nev || "Tanóra";
    const room = item.Terem ? `Terem: ${item.Terem}` : "";
    const teacher = item.Tanar || item.TanarNeve || "";
    
    let timeRange = "";
    if (item.KezdetIdopont && item.VegIdopont) {
      const s = new Date(item.KezdetIdopont);
      const e = new Date(item.VegIdopont);
      timeRange = `${String(s.getHours()).padStart(2, '0')}:${String(s.getMinutes()).padStart(2, '0')} - ${String(e.getHours()).padStart(2, '0')}:${String(e.getMinutes()).padStart(2, '0')}`;
    }
    const details = [timeRange, room, teacher].filter(Boolean).join(" • ");

    card.innerHTML = `
      <div class="item-left">
        <div class="item-index">${item.Oraszam || idx + 1}</div>
        <div style="min-width:0;">
          <div class="item-title" style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${escapeHtml(subName)}</div>
          <div class="item-sub">${details || "Órarendi tanóra"}</div>
        </div>
      </div>
    `;
    listEl.appendChild(card);
  });
}

let popupSubjectFilter = "all";

function renderGrades(grades) {
  const listEl = document.getElementById("grades-list");
  const filtersContainer = document.getElementById("popup-subject-filters");
  if (!listEl) return;

  const subjectMap = {};
  let totalWeight = 0;
  let weightedSum = 0;

  (grades || []).forEach(g => {
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
    (grades || []).forEach(g => {
      const parsed = KretaApi.parseGrade(g);
      if (parsed.numericGrade !== null) {
        weightedSum += parsed.numericGrade * parsed.weight;
        totalWeight += parsed.weight;
      }
    });
  }

  const avg = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(2) : "0.00";
  const avgEl = document.getElementById("average-value");
  if (avgEl) avgEl.innerText = avg;

  const subjects = Object.keys(subjectMap).sort();
  const countEl = document.getElementById("grade-count");
  if (countEl) countEl.innerText = `${grades.length} jegy • ${subjects.length} tárgy`;

  // Render subject chips
  if (filtersContainer) {
    filtersContainer.innerHTML = "";

    const allBtn = document.createElement("button");
    allBtn.className = `chip-btn ${popupSubjectFilter === "all" ? "active" : ""}`;
    allBtn.innerText = `Mind (${grades.length})`;
    allBtn.addEventListener("click", () => {
      popupSubjectFilter = "all";
      renderGrades(grades);
    });
    filtersContainer.appendChild(allBtn);

    subjects.forEach(sub => {
      const btn = document.createElement("button");
      btn.className = `chip-btn ${popupSubjectFilter === sub ? "active" : ""}`;
      btn.innerText = `${sub} (${subjectMap[sub].length})`; // innerText: safe even without escaping
      btn.addEventListener("click", () => {
        popupSubjectFilter = sub;
        renderGrades(grades);
      });
      filtersContainer.appendChild(btn);
    });
  }

  listEl.innerHTML = "";

  const filteredGrades = popupSubjectFilter === "all"
    ? grades
    : (subjectMap[popupSubjectFilter] || []);

  if (filteredGrades.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 24px; color: var(--text-muted); font-size: 0.78rem;">Nincs megjeleníthető érdemjegy.</div>`;
    return;
  }

  const maxLimit = currentPopupSettings?.maxGrades ?? 10;
  const displayedGrades = maxLimit > 0 ? filteredGrades.slice(0, maxLimit) : filteredGrades;

  displayedGrades.forEach(g => {
    const parsed = KretaApi.parseGrade(g);
    const card = document.createElement("div");
    card.className = "item-card";
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Tantárgy";
    const topic = g.Tema || g.Tipus?.Leiras || g.Tipus?.Nev || g.ErtekelesFajtaja?.Leiras || "Értékelés";
    const weightText = parsed.weightPercent !== 100 ? ` (${parsed.weightPercent}%)` : "";

    let dateText = "";
    const dateRaw = g.KeszitesDatuma || g.RogzitesDatuma || g.Datum;
    if (dateRaw) {
      const d = new Date(dateRaw);
      dateText = ` • ${d.getMonth() + 1}. ${d.getDate()}.`;
    }

    card.innerHTML = `
      <div class="item-left">
        <div class="grade-badge ${parsed.badgeClass}">${parsed.displayValue}</div>
        <div style="min-width:0;">
          <div class="item-title">${escapeHtml(sub)}${weightText}</div>
          <div class="item-sub" style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis; max-width:230px;">${escapeHtml(topic)}${dateText}</div>
        </div>
      </div>
    `;
    listEl.appendChild(card);
  });

  if (maxLimit > 0 && filteredGrades.length > displayedGrades.length) {
    const extraCount = filteredGrades.length - displayedGrades.length;
    const moreEl = document.createElement("div");
    moreEl.style.cssText = "text-align: center; padding: 6px; font-size: 0.72rem; color: var(--text-muted);";
    moreEl.innerText = `+ További ${extraCount} jegy a Vezérlőpulton`;
    listEl.appendChild(moreEl);
  }
}

function renderTasks(homework, exams) {
  const listEl = document.getElementById("tasks-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const items = [
    ...exams.map(e => ({ type: "exam", sub: escapeHtml(e.Tantargy?.Nev || e.Tantargy || "Dolgozat"), title: escapeHtml(e.Tema || e.Tipus?.Leiras || "Számonkérés"), date: e.Datum })),
    ...homework.map(h => ({ type: "hw", sub: escapeHtml(h.Tantargy?.Nev || h.Tantargy || "Házi"), title: escapeHtml(h.Szoveg || h.Feladat || "Házi feladat"), date: h.HataridoDatuma || h.HataridoIdopontja || h.Hatarido }))
  ];

  if (items.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 24px; color: var(--text-muted); font-size: 0.78rem;">Nincs közelgő feladat vagy dolgozat.</div>`;
    return;
  }

  const maxLimit = currentPopupSettings?.maxTasks ?? 5;
  const displayedTasks = maxLimit > 0 ? items.slice(0, maxLimit) : items;

  displayedTasks.forEach(it => {
    const card = document.createElement("div");
    card.className = "item-card";
    const isExam = it.type === "exam";
    const tag = isExam ? `<span style="color: var(--danger); font-weight:800; font-size:0.65rem;">DOLGOZAT</span>` : `<span style="color: var(--info); font-weight:800; font-size:0.65rem;">HÁZI</span>`;

    card.innerHTML = `
      <div>
        <div style="margin-bottom: 2px;">${tag} <strong style="font-size:0.78rem; margin-left:4px;">${it.sub}</strong></div>
        <div class="item-sub" style="max-width: 300px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${it.title}</div>
      </div>
    `;
    listEl.appendChild(card);
  });

  if (maxLimit > 0 && items.length > displayedTasks.length) {
    const extraCount = items.length - displayedTasks.length;
    const moreEl = document.createElement("div");
    moreEl.style.cssText = "text-align: center; padding: 6px; font-size: 0.72rem; color: var(--text-muted);";
    moreEl.innerText = `+ További ${extraCount} feladat a Vezérlőpulton`;
    listEl.appendChild(moreEl);
  }
}

function updateActiveClass(timetable) {
  const tagEl = document.getElementById("active-tag");
  const subjectEl = document.getElementById("active-subject");
  const detailsEl = document.getElementById("active-details");
  const progressContainer = document.getElementById("active-progress-container");
  const progressBar = document.getElementById("active-progress-bar");
  const countdownEl = document.getElementById("active-countdown");

  if (!subjectEl) return;

  const now = new Date();
  const todayIso = now.toISOString().split("T")[0];

  const todayLessons = (timetable || []).filter(item => {
    if (!item.KezdetIdopont) return false;
    return new Date(item.KezdetIdopont).toISOString().split("T")[0] === todayIso;
  });

  if (todayLessons.length === 0) {
    if (tagEl) tagEl.innerText = "NINCS TANÍTÁS MÁRA";
    subjectEl.innerText = "Nincs rögzített tanóra";
    if (detailsEl) detailsEl.innerText = "Jó pihenést és feltöltődést!";
    if (progressContainer) progressContainer.style.display = "none";
    if (countdownEl) countdownEl.innerText = "";
    return;
  }

  let currentLesson = null;
  let nextLesson = null;

  for (const lesson of todayLessons) {
    const start = new Date(lesson.KezdetIdopont);
    const end = new Date(lesson.VegIdopont);

    if (now >= start && now <= end) {
      currentLesson = lesson;
      break;
    } else if (now < start) {
      if (!nextLesson || new Date(nextLesson.KezdetIdopont) > start) {
        nextLesson = lesson;
      }
    }
  }

  if (currentLesson) {
    const start = new Date(currentLesson.KezdetIdopont);
    const end = new Date(currentLesson.VegIdopont);
    const totalMs = end - start;
    const elapsedMs = now - start;
    const percent = Math.min(100, Math.max(0, Math.round((elapsedMs / totalMs) * 100)));
    const minutesLeft = Math.ceil((end - now) / 60000);

    if (tagEl) tagEl.innerText = `FOLYAMATBAN LÉVŐ TANÓRA (${currentLesson.Oraszam || ""}. óra)`;
    subjectEl.innerText = currentLesson.Tantargy?.Nev || currentLesson.Nev || "Tanóra";
    if (detailsEl) {
      const room = currentLesson.Terem ? `Terem: ${currentLesson.Terem}` : "";
      const teacher = currentLesson.Tanar || currentLesson.TanarNeve || "";
      detailsEl.innerText = [room, teacher].filter(Boolean).join(" • ");
    }
    if (progressContainer) progressContainer.style.display = "block";
    if (progressBar) progressBar.style.width = `${percent}%`;
    if (countdownEl) countdownEl.innerText = `Hátra van még: ${minutesLeft} perc`;
  } else if (nextLesson) {
    const start = new Date(nextLesson.KezdetIdopont);
    const minutesUntil = Math.ceil((start - now) / 60000);
    const timeStr = `${String(start.getHours()).padStart(2, '0')}:${String(start.getMinutes()).padStart(2, '0')}`;

    if (tagEl) tagEl.innerText = "SZÜNET";
    subjectEl.innerText = `Következő: ${nextLesson.Tantargy?.Nev || nextLesson.Nev || "Tanóra"}`;
    if (detailsEl) {
      const room = nextLesson.Terem ? `Terem: ${nextLesson.Terem}` : "";
      detailsEl.innerText = `Kezdés: ${timeStr} (${nextLesson.Oraszam}. óra) ${room ? "• " + room : ""}`;
    }
    if (progressContainer) progressContainer.style.display = "none";
    if (countdownEl) countdownEl.innerText = `Kezdésig hátralévő idő: ${minutesUntil} perc`;
  } else {
    if (tagEl) tagEl.innerText = "A MAI TANÓRÁK VÉGET ÉRTEK";
    subjectEl.innerText = "Minden mai óra befejeződött";
    if (detailsEl) detailsEl.innerText = `Összesen ${todayLessons.length} tanóra volt ma megtartva.`;
    if (progressContainer) progressContainer.style.display = "none";
    if (countdownEl) countdownEl.innerText = "Kellemes pihenést!";
  }
}

function startCountdownTimer() {
  setInterval(() => {
    if (appState.data?.timetable) {
      updateActiveClass(appState.data.timetable);
    }
  }, 30000);
}
