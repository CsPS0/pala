// Pala Extension - Popup Logic

const DEFAULT_POPUP_SETTINGS = {
  defaultTab: "tab-grades",
  showHeroCard: true,
  compactMode: false,
  popupSize: "medium",
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
  isMaintenance: false,
  showWeekType: true,
  data: null
};

// Ephemeral state for the quick-expand "Szellem Jegy" calculator drawer
const ghostState = {
  isOpen: false,
  selectedSubject: "",
  selectedGrade: 5,
  selectedWeight: 100,
  items: []
};

document.addEventListener("DOMContentLoaded", async () => {
  const themeStore = await chrome.storage.local.get("pala_dark_mode");
  applyThemeMode(themeStore.pala_dark_mode !== false);

  setupTabs();
  setupActions();
  setupProfileSwitcher();
  setupGhostDrawer();
  setupPopupSettingsModal();

  const settingsStore = await chrome.storage.local.get("pala_popup_settings");
  applyPopupSettings(settingsStore.pala_popup_settings, true);

  renderSkeletons();
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
  document.body.classList.toggle("size-small", currentPopupSettings.popupSize === "small");
  document.body.classList.toggle("size-large", currentPopupSettings.popupSize === "large");

  const avgBar = document.querySelector(".stat-summary");
  if (avgBar) {
    avgBar.style.display = currentPopupSettings.showAverageBar === false ? "none" : "flex";
  }
}

function renderSkeletons() {
  ["grades-list", "timetable-list", "tasks-list"].forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      el.innerHTML = `
        <div class="skeleton-card"></div>
        <div class="skeleton-card"></div>
        <div class="skeleton-card"></div>
      `;
    }
  });
}

function setupProfileSwitcher() {
  const btn = document.getElementById("profile-switcher-btn");
  const menu = document.getElementById("profile-dropdown-menu");
  const addBtn = document.getElementById("btn-add-profile");

  btn?.addEventListener("click", async (e) => {
    e.stopPropagation();
    if (!menu) return;
    const isVisible = menu.style.display !== "none";
    if (isVisible) {
      menu.style.display = "none";
    } else {
      await populateProfileMenu();
      menu.style.display = "block";
    }
  });

  addBtn?.addEventListener("click", () => {
    if (menu) menu.style.display = "none";
    document.getElementById("login-modal")?.classList.add("active");
  });

  document.addEventListener("click", (e) => {
    if (menu && menu.style.display !== "none" && !menu.contains(e.target) && !btn?.contains(e.target)) {
      menu.style.display = "none";
    }
  });
}

async function populateProfileMenu() {
  const listEl = document.getElementById("profile-list-items");
  const menu = document.getElementById("profile-dropdown-menu");
  if (!listEl) return;

  const profiles = await SecureSession.listProfiles();
  listEl.innerHTML = "";

  profiles.forEach(p => {
    const opt = document.createElement("button");
    opt.type = "button";
    opt.className = `profile-option ${p.isActive ? "active" : ""}`;
    opt.innerHTML = `
      <div>
        <span class="profile-option-name">${escapeHtml(p.user)}</span>
        <span class="profile-option-inst">${escapeHtml(p.institute || "Kréta fiók")}</span>
      </div>
      ${p.isActive ? '<span class="profile-active-dot"></span>' : ""}
    `;
    opt.addEventListener("click", async () => {
      if (menu) menu.style.display = "none";
      renderSkeletons();
      await SecureSession.switchProfile(p.id);
      await loadData(true);
    });
    listEl.appendChild(opt);
  });
}

function setupGhostDrawer() {
  const drawer = document.getElementById("ghost-calc-drawer");
  const handle = document.getElementById("btn-toggle-ghost-drawer");
  const body = document.getElementById("ghost-drawer-body");
  const subSelect = document.getElementById("popup-ghost-subject");
  const gradeBtns = document.querySelectorAll("#popup-ghost-grade-btns .ghost-grade-btn");
  const weightBtns = document.querySelectorAll("#popup-ghost-weight-btns .ghost-weight-btn");
  const addBtn = document.getElementById("btn-add-ghost-grade");
  const clearBtn = document.getElementById("btn-clear-ghost-grades");

  handle?.addEventListener("click", () => {
    ghostState.isOpen = !ghostState.isOpen;
    drawer?.classList.toggle("open", ghostState.isOpen);
    if (body) body.style.display = ghostState.isOpen ? "flex" : "none";
    if (ghostState.isOpen) {
      updateGhostCalculator();
    }
  });

  subSelect?.addEventListener("change", () => {
    ghostState.selectedSubject = subSelect.value;
    updateGhostCalculator();
  });

  gradeBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      ghostState.selectedGrade = parseInt(btn.getAttribute("data-val") || "5", 10);
      gradeBtns.forEach(b => b.classList.toggle("active", b === btn));
    });
  });

  weightBtns.forEach(btn => {
    btn.addEventListener("click", () => {
      ghostState.selectedWeight = parseInt(btn.getAttribute("data-weight") || "100", 10);
      weightBtns.forEach(b => b.classList.toggle("active", b === btn));
    });
  });

  addBtn?.addEventListener("click", () => {
    if (!ghostState.selectedSubject) return;
    ghostState.items.push({
      id: `${Date.now()}_${Math.random()}`,
      subject: ghostState.selectedSubject,
      grade: ghostState.selectedGrade,
      weight: ghostState.selectedWeight
    });
    updateGhostCalculator();
  });

  clearBtn?.addEventListener("click", () => {
    ghostState.items = [];
    updateGhostCalculator();
  });
}

function updateGhostCalculator() {
  const grades = appState.data?.grades || [];
  const subSelect = document.getElementById("popup-ghost-subject");
  const countPill = document.getElementById("ghost-count-pill");
  const clearBtn = document.getElementById("btn-clear-ghost-grades");
  const chipsContainer = document.getElementById("ghost-active-chips");

  const subjectsSet = new Set();
  grades.forEach(g => {
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy;
    if (sub) subjectsSet.add(sub);
  });
  const subjects = Array.from(subjectsSet).sort();
  if (subjects.length === 0) subjects.push("Matematika");

  if (!ghostState.selectedSubject || !subjects.includes(ghostState.selectedSubject)) {
    ghostState.selectedSubject = subjects[0];
  }

  if (subSelect) {
    const prev = ghostState.selectedSubject;
    subSelect.innerHTML = subjects
      .map(s => `<option value="${escapeHtml(s)}">${escapeHtml(s)}</option>`)
      .join("");
    subSelect.value = prev;
  }

  if (countPill) {
    countPill.style.display = ghostState.items.length > 0 ? "inline-flex" : "none";
    countPill.innerText = `${ghostState.items.length}`;
  }
  if (clearBtn) {
    clearBtn.style.display = ghostState.items.length > 0 ? "inline-block" : "none";
  }

  // Render active ghost chips
  if (chipsContainer) {
    chipsContainer.innerHTML = "";
    ghostState.items.forEach(item => {
      const chip = document.createElement("button");
      chip.type = "button";
      chip.className = "ghost-chip";
      chip.title = "Kattints az eltávolításhoz";
      chip.innerText = `${item.subject.slice(0, 12)}: ${item.grade} (${item.weight}%) ✕`;
      chip.addEventListener("click", () => {
        ghostState.items = ghostState.items.filter(x => x.id !== item.id);
        updateGhostCalculator();
      });
      chipsContainer.appendChild(chip);
    });
  }

  // Compute real vs projected averages for selected subject and overall GPA
  let realSubSum = 0;
  let realSubWeight = 0;
  let realTotalSum = 0;
  let realTotalWeight = 0;

  grades.forEach(g => {
    const parsed = KretaApi.parseGrade(g);
    if (parsed.numericGrade !== null && !parsed.isSummary) {
      const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "";
      realTotalSum += parsed.numericGrade * parsed.weight;
      realTotalWeight += parsed.weight;
      if (sub === ghostState.selectedSubject) {
        realSubSum += parsed.numericGrade * parsed.weight;
        realSubWeight += parsed.weight;
      }
    }
  });

  let mockSubSum = 0;
  let mockSubWeight = 0;
  let mockTotalSum = 0;
  let mockTotalWeight = 0;

  ghostState.items.forEach(m => {
    const w = m.weight / 100;
    mockTotalSum += m.grade * w;
    mockTotalWeight += w;
    if (m.subject === ghostState.selectedSubject) {
      mockSubSum += m.grade * w;
      mockSubWeight += w;
    }
  });

  const curSubAvg = realSubWeight > 0 ? realSubSum / realSubWeight : 0;
  const projSubAvg = (realSubWeight + mockSubWeight) > 0
    ? (realSubSum + mockSubSum) / (realSubWeight + mockSubWeight)
    : 0;
  const subDelta = projSubAvg - curSubAvg;

  const curGpa = realTotalWeight > 0 ? realTotalSum / realTotalWeight : 0;
  const projGpa = (realTotalWeight + mockTotalWeight) > 0
    ? (realTotalSum + mockTotalSum) / (realTotalWeight + mockTotalWeight)
    : 0;
  const gpaDelta = projGpa - curGpa;

  const subProjEl = document.getElementById("ghost-sub-projected");
  const subCurEl = document.getElementById("ghost-sub-current");
  const subDeltaEl = document.getElementById("ghost-sub-delta");

  if (subProjEl) subProjEl.innerText = projSubAvg > 0 ? projSubAvg.toFixed(2) : "--";
  if (subCurEl) subCurEl.innerText = `Jelenlegi: ${curSubAvg > 0 ? curSubAvg.toFixed(2) : "--"}`;
  if (subDeltaEl) {
    if (Math.abs(subDelta) > 0.004) {
      subDeltaEl.innerText = `${subDelta > 0 ? "+" : ""}${subDelta.toFixed(2)}`;
      subDeltaEl.className = `ghost-delta ${subDelta >= 0 ? "pos" : "neg"}`;
    } else {
      subDeltaEl.innerText = "";
    }
  }

  const gpaProjEl = document.getElementById("ghost-gpa-projected");
  const gpaCurEl = document.getElementById("ghost-gpa-current");
  const gpaDeltaEl = document.getElementById("ghost-gpa-delta");

  if (gpaProjEl) gpaProjEl.innerText = projGpa > 0 ? projGpa.toFixed(2) : "--";
  if (gpaCurEl) gpaCurEl.innerText = `Jelenlegi: ${curGpa > 0 ? curGpa.toFixed(2) : "--"}`;
  if (gpaDeltaEl) {
    if (Math.abs(gpaDelta) > 0.004) {
      gpaDeltaEl.innerText = `${gpaDelta > 0 ? "+" : ""}${gpaDelta.toFixed(2)}`;
      gpaDeltaEl.className = `ghost-delta ${gpaDelta >= 0 ? "pos" : "neg"}`;
    } else {
      gpaDeltaEl.innerText = "";
    }
  }
}

function setupPopupSettingsModal() {
  const modal = document.getElementById("popup-settings-modal");
  const openBtn = document.getElementById("btn-popup-settings");
  const closeBtn = document.getElementById("btn-close-popup-settings");
  const saveBtn = document.getElementById("btn-save-popup-settings");

  const populateForm = () => {
    const tabSelect = document.getElementById("popup-pref-default-tab");
    if (tabSelect) tabSelect.value = currentPopupSettings.defaultTab || "tab-grades";

    const heroCheck = document.getElementById("popup-pref-show-hero");
    if (heroCheck) heroCheck.checked = currentPopupSettings.showHeroCard !== false;

    const sizeSelect = document.getElementById("popup-pref-size");
    if (sizeSelect) sizeSelect.value = currentPopupSettings.popupSize || "medium";

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
      defaultTab: document.getElementById("popup-pref-default-tab")?.value || "tab-grades",
      showHeroCard: document.getElementById("popup-pref-show-hero")?.checked !== false,
      compactMode: document.getElementById("popup-pref-compact")?.checked === true,
      popupSize: document.getElementById("popup-pref-size")?.value || "medium",
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

async function openSidePanel() {
  try {
    if (chrome.sidePanel && typeof chrome.sidePanel.open === "function") {
      const win = await chrome.windows.getCurrent();
      if (win && win.id !== undefined) {
        await chrome.sidePanel.open({ windowId: win.id });
        window.close();
        return;
      }
    }
    if (typeof browser !== "undefined" && browser.sidebarAction?.open) {
      await browser.sidebarAction.open();
      window.close();
      return;
    }
    chrome.runtime.sendMessage({ type: "pala_open_sidepanel" });
    window.close();
  } catch (_) {
    chrome.tabs.create({ url: chrome.runtime.getURL("sidepanel/sidepanel.html") });
  }
}

function setupActions() {
  document.getElementById("btn-open-dashboard")?.addEventListener("click", () => {
    chrome.tabs.create({ url: chrome.runtime.getURL("dashboard/dashboard.html") });
  });

  document.getElementById("btn-open-sidepanel")?.addEventListener("click", openSidePanel);
  document.getElementById("btn-footer-sidepanel")?.addEventListener("click", openSidePanel);

  document.getElementById("btn-refresh")?.addEventListener("click", async () => {
    renderSkeletons();
    await loadData(true);
  });

  document.getElementById("btn-account-switch")?.addEventListener("click", () => {
    document.getElementById("login-modal")?.classList.toggle("active");
  });

  document.getElementById("btn-close-login-modal")?.addEventListener("click", () => {
    document.getElementById("login-modal")?.classList.remove("active");
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
    await chrome.storage.local.remove(["pala_cached_data", "pala_last_fetch"]);
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
      schoolDropdown.innerHTML = '<div style="padding:8px 10px; font-size:0.73rem; color:var(--text-muted);">Keresés...</div>';
      schoolDropdown.style.display = "block";

      const schools = await KretaApi.searchSchools(query);
      if (schools.length === 0) {
        schoolDropdown.innerHTML = '<div style="padding:8px 10px; font-size:0.73rem; color:var(--text-muted);">Nincs találat. Beírhatsz közvetlen kódot is.</div>';
        return;
      }

      schoolDropdown.innerHTML = "";
      schools.forEach(s => {
        const item = document.createElement("div");
        item.className = "school-item";
        item.innerHTML = `<div><strong>${escapeHtml(s.name)}</strong></div><div style="font-size:0.66rem; color:var(--primary); margin-top:2px;">Kód: ${escapeHtml(s.code)}</div>`;
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

  chrome.storage.onChanged?.addListener((changes, area) => {
    if (area !== "local") return;
    // Another context just fetched, refreshed a token or switched profile, so the
    // cache is current (switchProfile clears it, which forces a fetch anyway).
    if (changes.pala_session || changes.pala_maintenance_mode || changes.pala_cached_data) {
      loadData(false);
    } else if (changes.pala_popup_settings) {
      applyPopupSettings(changes.pala_popup_settings.newValue);
      if (appState.data) {
        renderGrades(appState.data.grades || []);
        renderTasks(appState.data.homework || [], appState.data.exams || []);
      }
    }
  });

  chrome.runtime.onMessage?.addListener((msg) => {
    if (msg?.type === "pala_session_changed") {
      loadData(true);
    } else if (msg?.type === "pala_data_updated") {
      loadData(false);
    }
  });
}

function setStatusBadge(mode, label) {
  const badgeEl = document.getElementById("status-badge");
  const textEl = document.getElementById("status-badge-text");
  if (!badgeEl) return;
  badgeEl.className = `badge ${mode}`;
  if (textEl) {
    textEl.innerText = label;
  } else {
    badgeEl.innerText = label;
  }
}

let loadSeq = 0;
let renderFrame = 0;

async function loadData(forceRefresh = false) {
  // Storage events, messages and clicks can start overlapping loads; only the
  // newest may render, so a slow older fetch never overwrites newer data.
  const seq = ++loadSeq;
  const store = await chrome.storage.local.get([
    "pala_use_demo",
    "pala_cached_data",
    "pala_maintenance_mode",
    "pala_simulate_maintenance",
    "pala_show_week_type"
  ]);
  appState.showWeekType = store.pala_show_week_type !== false;
  const session = await SecureSession.load();
  const useDemo = store.pala_use_demo !== false;
  const next = { isDemo: true, isMaintenance: false, data: null };

  if (useDemo || !session) {
    next.data = KretaApi.getDemoDataset();
  } else {
    next.isDemo = false;
    setStatusBadge("badge-sync", "Szinkron...");

    if (!forceRefresh && !store.pala_cached_data) {
      forceRefresh = true;
    }

    try {
      next.data = await KretaApi.getCachedOrFetchData(session, forceRefresh);
      next.isMaintenance = next.data?.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
    } catch (err) {
      console.warn("Could not fetch online Kréta data, falling back to cached:", err);
      next.isMaintenance = err.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
      next.data = store.pala_cached_data ? { ...store.pala_cached_data, isMaintenance: true } : null;
    }
  }

  if (seq !== loadSeq) return;
  Object.assign(appState, next);
  // One render per frame: bursts of loads collapse and never block a tab click.
  cancelAnimationFrame(renderFrame);
  renderFrame = requestAnimationFrame(renderUI);
}

function renderUI() {
  const data = appState.data;
  const maintBanner = document.getElementById("maintenance-banner");
  const maintView = document.getElementById("tab-maintenance");
  const heroCard = document.getElementById("active-class-card");
  const tabBar = document.getElementById("popup-tab-bar");
  const contentPanels = document.querySelectorAll(".tab-panel:not(#tab-maintenance)");

  if (appState.isMaintenance) {
    if (!data) {
      if (maintView) maintView.style.display = "block";
      if (maintBanner) maintBanner.style.display = "none";
      if (heroCard) heroCard.style.display = "none";
      if (tabBar) tabBar.style.display = "none";
      contentPanels.forEach(p => p.style.display = "none");
      setStatusBadge("badge-maintenance", "Karbantartás");
      return;
    } else {
      const bannerText = document.getElementById("maintenance-banner-text");
      if (bannerText) bannerText.textContent = offlineNotice(data);
      if (maintBanner) maintBanner.style.display = "block";
      if (maintView) maintView.style.display = "none";
      contentPanels.forEach(p => p.style.display = "");
      if (heroCard) heroCard.style.display = currentPopupSettings.showHeroCard === false ? "none" : "block";
      if (tabBar) tabBar.style.display = "grid";
      setStatusBadge("badge-maintenance", "Offline");
    }
  } else {
    if (maintBanner) maintBanner.style.display = "none";
    if (maintView) maintView.style.display = "none";
    contentPanels.forEach(p => p.style.display = "");
    if (heroCard) heroCard.style.display = currentPopupSettings.showHeroCard === false ? "none" : "block";
    if (tabBar) tabBar.style.display = "grid";
  }

  if (!data) {
    const studentNameEl = document.getElementById("student-name");
    if (studentNameEl) studentNameEl.innerText = "Bejelentkezés szükséges";
    const studentSchoolEl = document.getElementById("student-school");
    if (studentSchoolEl) studentSchoolEl.innerText = "Válassz profilt vagy lépj be";
    setStatusBadge("badge-maintenance", "Lejárt");
    return;
  }

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
    if (appState.isDemo) {
      setStatusBadge("badge-demo", "Demó");
    } else {
      setStatusBadge("badge-online", "Online");
    }
  }

  renderTimetable(data.timetable || [], appState.showWeekType ? data.weekType : null);
  renderGrades(data.grades || []);
  renderTasks(data.homework || [], data.exams || []);
  updateActiveClass(data.timetable || []);
  updateGhostCalculator();
}

function getLessonAnomaly(lesson) {
  if (!lesson) return { isCancelled: false, isSubstituted: false, substituteTeacher: "" };
  const stateName = String(lesson.Allapot?.Nev || lesson.Allapot || "").toLowerCase();
  const isCancelled = stateName.includes("elmarad");
  const subTeacher = lesson.HelyettesTanarNeve || "";
  const isSubstituted = !isCancelled && (Boolean(subTeacher) || stateName.includes("helyettes"));
  return { isCancelled, isSubstituted, substituteTeacher: subTeacher };
}

function renderTimetable(timetable, weekType) {
  const listEl = document.getElementById("timetable-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const now = new Date();
  const todayIso = localDateKey(now);
  const todayWeekday = now.getDay();
  const isWeekend = todayWeekday === 0 || todayWeekday === 6;

  const abBadge = document.getElementById("popup-ab-badge");
  if (abBadge) {
    abBadge.textContent = weekType || "";
    abBadge.style.display = weekType ? "" : "none";
  }

  const hasDates = (timetable || []).some(item => !!item.KezdetIdopont);
  const todayLessons = hasDates
    ? (timetable || []).filter(item => item.KezdetIdopont && localDateKey(item.KezdetIdopont) === todayIso)
    : (timetable || []);

  if (todayLessons.length === 0) {
    listEl.innerHTML = `
      <div style="text-align:center; padding: 28px 16px; color: var(--text-muted); font-size: 0.78rem;">
        <strong style="color: var(--text); display: block; margin-bottom: 4px;">${isWeekend ? "Hétvége van." : "Nincs tanóra a mai napon."}</strong>
        <span>${isWeekend ? "Jó pihenést és feltöltődést!" : "Tanítás nélküli munkanap / Szabadnap"}</span>
      </div>
    `;
    return;
  }

  todayLessons.forEach((item, idx) => {
    const anomaly = getLessonAnomaly(item);
    const card = document.createElement("div");
    card.className = `item-card ${anomaly.isCancelled ? "lesson-cancelled" : (anomaly.isSubstituted ? "lesson-substituted" : "")}`;

    const subName = item.Tantargy?.Nev || item.Tantargy || item.Nev || "Tanóra";
    const room = item.TeremNeve ? `Terem: ${item.TeremNeve}` : "";
    const teacher = anomaly.isSubstituted && anomaly.substituteTeacher
      ? `Helyettesítő: ${anomaly.substituteTeacher}`
      : (item.TanarNeve || "");
    const timeRange = item.KezdetIdopont && item.VegIdopont
      ? `${formatLocalTime(item.KezdetIdopont)} - ${formatLocalTime(item.VegIdopont)}`
      : "";
    const details = escapeHtml([timeRange, room, teacher].filter(Boolean).join(" • "));

    const statusBadge = anomaly.isCancelled
      ? `<span class="lesson-status-pill cancelled">Elmarad</span>`
      : (anomaly.isSubstituted ? `<span class="lesson-status-pill substituted">Helyettesítés</span>` : "");

    card.innerHTML = `
      <div class="item-left">
        <div class="item-index">${escapeHtml(item.Oraszam ?? idx + 1)}</div>
        <div style="min-width:0; flex:1;">
          <div class="item-title ${anomaly.isCancelled ? "line-through" : ""}">${escapeHtml(subName)}</div>
          <div class="item-sub">${details || "Órarendi tanóra"}</div>
        </div>
      </div>
      ${statusBadge}
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
      btn.innerText = `${sub} (${subjectMap[sub].length})`;
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
    listEl.innerHTML = `<div style="text-align:center; padding: 24px; color: var(--text-muted); font-size: 0.76rem;">Nincs megjeleníthető érdemjegy.</div>`;
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
        <div class="grade-badge ${parsed.badgeClass}">${escapeHtml(parsed.displayValue)}</div>
        <div style="min-width:0; flex:1;">
          <div class="item-title">${escapeHtml(sub)}${escapeHtml(weightText)}</div>
          <div class="item-sub">${escapeHtml(topic)}${escapeHtml(dateText)}</div>
        </div>
      </div>
    `;
    listEl.appendChild(card);
  });

  if (maxLimit > 0 && filteredGrades.length > displayedGrades.length) {
    const extraCount = filteredGrades.length - displayedGrades.length;
    const moreEl = document.createElement("div");
    moreEl.style.cssText = "text-align: center; padding: 6px; font-size: 0.7rem; color: var(--text-muted);";
    moreEl.innerText = `+ További ${extraCount} jegy az Oldalsávon vagy Vezérlőpulton`;
    listEl.appendChild(moreEl);
  }
}

function renderTasks(homework, exams) {
  const listEl = document.getElementById("tasks-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const items = [
    ...exams.map(e => ({
      type: "exam",
      sub: escapeHtml(e.Tantargy?.Nev || e.Tantargy || "Dolgozat"),
      title: escapeHtml(e.Tema || e.Tipus?.Leiras || "Számonkérés")
    })),
    ...homework.map(h => ({
      type: "hw",
      sub: escapeHtml(h.Tantargy?.Nev || h.Tantargy || "Házi"),
      title: escapeHtml(h.Szoveg || h.Feladat || "Házi feladat")
    }))
  ];

  if (items.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 24px; color: var(--text-muted); font-size: 0.76rem;">Nincs közelgő feladat vagy dolgozat.</div>`;
    return;
  }

  const maxLimit = currentPopupSettings?.maxTasks ?? 5;
  const displayedTasks = maxLimit > 0 ? items.slice(0, maxLimit) : items;

  displayedTasks.forEach(it => {
    const card = document.createElement("div");
    card.className = "item-card";
    const isExam = it.type === "exam";
    const tag = isExam
      ? `<span style="color: var(--danger); font-weight:800; font-size:0.63rem;">DOLGOZAT</span>`
      : `<span style="color: var(--info); font-weight:800; font-size:0.63rem;">HÁZI</span>`;

    card.innerHTML = `
      <div style="min-width:0; flex:1;">
        <div style="margin-bottom: 2px;">${tag} <strong style="font-size:0.77rem; margin-left:4px;">${it.sub}</strong></div>
        <div class="item-sub">${it.title}</div>
      </div>
    `;
    listEl.appendChild(card);
  });
}

function updateActiveClass(timetable) {
  const tagEl = document.getElementById("active-tag");
  const roomBadgeEl = document.getElementById("active-room-badge");
  const subjectEl = document.getElementById("active-subject");
  const detailsEl = document.getElementById("active-details");
  const subBannerEl = document.getElementById("active-sub-banner");
  const progressContainer = document.getElementById("active-progress-container");
  const progressBar = document.getElementById("active-progress-bar");
  const countdownEl = document.getElementById("active-countdown");

  if (!subjectEl) return;

  const now = new Date();
  const todayIso = localDateKey(now);

  const todayLessons = (timetable || []).filter(item => {
    if (!item.KezdetIdopont) return false;
    return localDateKey(item.KezdetIdopont) === todayIso;
  });

  if (todayLessons.length === 0) {
    if (tagEl) tagEl.innerText = "NINCS TANÍTÁS MÁRA";
    if (roomBadgeEl) roomBadgeEl.style.display = "none";
    if (subBannerEl) subBannerEl.style.display = "none";
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

  const targetLesson = currentLesson || nextLesson;
  const anomaly = getLessonAnomaly(targetLesson);

  if (roomBadgeEl) {
    if (targetLesson?.TeremNeve) {
      roomBadgeEl.style.display = "inline-block";
      roomBadgeEl.innerText = `Terem: ${targetLesson.TeremNeve}`;
    } else {
      roomBadgeEl.style.display = "none";
    }
  }

  if (subBannerEl) {
    if (anomaly.isCancelled) {
      subBannerEl.style.display = "flex";
      subBannerEl.className = "sub-alert-banner is-cancelled";
      subBannerEl.innerText = "ELMARAD: Ez a tanóra törölve lett a mai órarendből.";
    } else if (anomaly.isSubstituted) {
      subBannerEl.style.display = "flex";
      subBannerEl.className = "sub-alert-banner is-sub";
      subBannerEl.innerText = `HELYETTESÍTÉS${anomaly.substituteTeacher ? `: ${anomaly.substituteTeacher}` : ""}`;
    } else {
      subBannerEl.style.display = "none";
    }
  }

  if (currentLesson) {
    const start = new Date(currentLesson.KezdetIdopont);
    const end = new Date(currentLesson.VegIdopont);
    const totalMs = end - start;
    const elapsedMs = now - start;
    const percent = Math.min(100, Math.max(0, Math.round((elapsedMs / totalMs) * 100)));
    const minutesLeft = Math.ceil((end - now) / 60000);

    if (tagEl) tagEl.innerText = `FOLYAMATBAN LÉVŐ ÓRA${lessonNumberLabel(currentLesson, " • ", "")}`;
    subjectEl.innerText = currentLesson.Tantargy?.Nev || currentLesson.Nev || "Tanóra";
    if (detailsEl) {
      const timeStr = `${formatLocalTime(start)} - ${formatLocalTime(end)}`;
      const teacher = currentLesson.TanarNeve || "";
      detailsEl.innerText = [timeStr, teacher].filter(Boolean).join(" • ");
    }
    if (progressContainer) progressContainer.style.display = "block";
    if (progressBar) progressBar.style.width = `${percent}%`;
    if (countdownEl) countdownEl.innerText = `Hátra van még: ${formatDuration(minutesLeft)}`;
  } else if (nextLesson) {
    const start = new Date(nextLesson.KezdetIdopont);
    const minutesUntil = Math.ceil((start - now) / 60000);
    const isFirst = todayLessons.every(l => new Date(l.KezdetIdopont) >= start);

    if (tagEl) tagEl.innerText = isFirst ? "MAI ELSŐ ÓRA" : `SZÜNET • KÖVETKEZŐ${lessonNumberLabel(nextLesson, " (", ")")}`;
    subjectEl.innerText = nextLesson.Tantargy?.Nev || nextLesson.Nev || "Tanóra";
    if (detailsEl) {
      detailsEl.innerText = [`Kezdés: ${formatLocalTime(start)}`, nextLesson.TanarNeve || ""].filter(Boolean).join(" • ");
    }
    if (progressContainer) progressContainer.style.display = "none";
    if (countdownEl) countdownEl.innerText = `Kezdésig: ${formatDuration(minutesUntil)}`;
  } else {
    if (tagEl) tagEl.innerText = "TANÍTÁSI NAP VÉGE";
    if (roomBadgeEl) roomBadgeEl.style.display = "none";
    if (subBannerEl) subBannerEl.style.display = "none";
    subjectEl.innerText = "Minden mai óra befejeződött";
    if (detailsEl) detailsEl.innerText = `Összesen ${todayLessons.length} tanóra volt ma megtartva.`;
    if (progressContainer) progressContainer.style.display = "none";
    if (countdownEl) countdownEl.innerText = "Kellemes pihenést!";
  }
}

function lessonNumberLabel(lesson, before = "", after = "") {
  return lesson.Oraszam != null ? `${before}${lesson.Oraszam}. óra${after}` : "";
}

function formatDuration(minutes) {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m} perc`;
  return m === 0 ? `${h} óra` : `${h} óra ${m} perc`;
}

function startCountdownTimer() {
  setInterval(() => {
    if (appState.data?.timetable) {
      updateActiveClass(appState.data.timetable);
    }
  }, 30000);
}
