// Pala Extension - Side Panel Logic

const spState = {
  isDemo: true,
  isMaintenance: false,
  demoAWeekOverride: null,
  selectedDay: "all",
  absenceFilter: "all",
  gradeSearch: "",
  data: null
};

const DAY_NAMES_HU = ["Hétfő", "Kedd", "Szerda", "Csütörtök", "Péntek", "Szombat", "Vasárnap"];

function applyThemeMode(isDark) {
  if (isDark) {
    document.documentElement.removeAttribute("data-theme");
  } else {
    document.documentElement.setAttribute("data-theme", "light");
  }
}

function normalizeHungarian(str) {
  return String(str || "")
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

function getLessonAnomaly(lesson) {
  if (!lesson) return { isCancelled: false, isSubstituted: false, substituteTeacher: "" };
  const stateName = String(lesson.Allapot?.Nev || lesson.Allapot || "").toLowerCase();
  const isCancelled = stateName.includes("elmarad");
  const subTeacher = lesson.HelyettesTanarNeve || "";
  const isSubstituted = !isCancelled && (Boolean(subTeacher) || stateName.includes("helyettes"));
  return { isCancelled, isSubstituted, substituteTeacher: subTeacher };
}

document.addEventListener("DOMContentLoaded", async () => {
  const themeStore = await chrome.storage.local.get("pala_dark_mode");
  applyThemeMode(themeStore.pala_dark_mode !== false);

  setupNavigation();
  setupHeaderActions();
  setupTimetableControls();
  setupGradeControls();
  setupAbsenceControls();

  renderSkeletons();
  await loadSidePanelData();

  setInterval(() => {
    if (spState.data?.timetable) {
      renderLiveHero(spState.data.timetable);
    }
  }, 30000);
});

chrome.storage?.onChanged?.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes.pala_dark_mode) {
    applyThemeMode(changes.pala_dark_mode.newValue !== false);
  }
  if (changes.pala_session || changes.pala_use_demo || changes.pala_cached_data) {
    loadSidePanelData(false);
  }
});

function switchSpTab(tabId) {
  document.querySelectorAll(".sp-tab").forEach(btn => {
    btn.classList.toggle("active", btn.getAttribute("data-tab") === tabId);
  });
  document.querySelectorAll(".sp-view").forEach(view => {
    view.classList.toggle("active", view.id === tabId);
  });
}

function setupNavigation() {
  document.querySelectorAll(".sp-tab").forEach(btn => {
    btn.addEventListener("click", () => {
      const target = btn.getAttribute("data-tab");
      if (target) switchSpTab(target);
    });
  });

  document.querySelectorAll("[data-goto]").forEach(el => {
    el.addEventListener("click", () => {
      const target = el.getAttribute("data-goto");
      if (target) switchSpTab(target);
    });
  });
}

function setupHeaderActions() {
  const profileBtn = document.getElementById("sp-profile-btn");
  const profileMenu = document.getElementById("sp-profile-menu");

  profileBtn?.addEventListener("click", async (e) => {
    e.stopPropagation();
    if (!profileMenu) return;
    if (profileMenu.style.display !== "none") {
      profileMenu.style.display = "none";
    } else {
      await renderProfileDropdown();
      profileMenu.style.display = "block";
    }
  });

  document.addEventListener("click", (e) => {
    if (profileMenu && profileMenu.style.display !== "none" && !profileMenu.contains(e.target) && !profileBtn?.contains(e.target)) {
      profileMenu.style.display = "none";
    }
  });

  document.getElementById("sp-btn-theme")?.addEventListener("click", async () => {
    const isLight = document.documentElement.getAttribute("data-theme") === "light";
    const nextDark = isLight;
    applyThemeMode(nextDark);
    await chrome.storage.local.set({ pala_dark_mode: nextDark });
  });

  document.getElementById("sp-btn-refresh")?.addEventListener("click", async () => {
    renderSkeletons();
    await loadSidePanelData(true);
  });

  document.getElementById("sp-btn-full-dashboard")?.addEventListener("click", () => {
    chrome.tabs.create({ url: chrome.runtime.getURL("dashboard/dashboard.html") });
  });

  document.getElementById("sp-btn-maint-retry")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_simulate_maintenance: false });
    await loadSidePanelData(true);
  });
}

async function renderProfileDropdown() {
  const listEl = document.getElementById("sp-profile-list");
  const menuEl = document.getElementById("sp-profile-menu");
  if (!listEl) return;

  const profiles = await SecureSession.listProfiles();
  listEl.innerHTML = "";

  profiles.forEach(p => {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = `sp-profile-opt ${p.isActive ? "active" : ""}`;
    btn.innerHTML = `
      <div>
        <strong style="display:block; font-size:0.77rem;">${escapeHtml(p.user)}</strong>
        <span style="font-size:0.65rem; color:var(--text-muted);">${escapeHtml(p.institute || "Kréta fiók")}</span>
      </div>
      ${p.isActive ? '<span class="status-dot" style="background:var(--primary);"></span>' : ""}
    `;
    btn.addEventListener("click", async () => {
      if (menuEl) menuEl.style.display = "none";
      renderSkeletons();
      await SecureSession.switchProfile(p.id);
      await loadSidePanelData(true);
    });
    listEl.appendChild(btn);
  });
}

function renderSkeletons() {
  ["sp-recent-grades", "sp-upcoming-tasks", "sp-timetable-container", "sp-grade-matrix", "sp-absences-list"].forEach(id => {
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

function setSpStatus(mode, text) {
  const badge = document.getElementById("sp-status-badge");
  const txt = document.getElementById("sp-status-text");
  if (badge) badge.className = `badge ${mode}`;
  if (txt) txt.innerText = text;
}

let loadSeq = 0;
let renderFrame = 0;

async function loadSidePanelData(forceRefresh = false) {
  // Storage events and clicks can start overlapping loads; only the newest renders.
  const seq = ++loadSeq;
  const store = await chrome.storage.local.get([
    "pala_use_demo",
    "pala_cached_data",
    "pala_maintenance_mode",
    "pala_simulate_maintenance"
  ]);
  const session = await SecureSession.load();
  const useDemo = store.pala_use_demo !== false;
  const next = { isDemo: true, isMaintenance: false, data: null };

  if (useDemo || !session) {
    next.data = KretaApi.getDemoDataset(spState.demoAWeekOverride);
  } else {
    next.isDemo = false;
    setSpStatus("badge-sync", "Szinkron...");
    try {
      next.data = await KretaApi.getCachedOrFetchData(session, forceRefresh);
      next.isMaintenance = next.data?.isMaintenance || store.pala_maintenance_mode === true || store.pala_simulate_maintenance === true;
    } catch (err) {
      console.warn("Could not fetch online Kréta data, falling back to cached:", err);
      next.isMaintenance = true;
      // No cache: show the offline state, never demo data posing as the student's.
      next.data = store.pala_cached_data ? { ...store.pala_cached_data, isMaintenance: true } : null;
    }
  }

  if (seq !== loadSeq) return;
  Object.assign(spState, next);
  // One render per frame: bursts of loads collapse and never block a tab click.
  cancelAnimationFrame(renderFrame);
  renderFrame = requestAnimationFrame(renderAllViews);
}

function renderAllViews() {
  const data = spState.data;
  const maintBanner = document.getElementById("sp-maint-banner");
  const maintText = document.getElementById("sp-maint-text");
  if (!data) {
    if (maintText) maintText.textContent = "A Kréta szerverei most nem érhetők el, és még nincs mentett adat.";
    if (maintBanner) maintBanner.style.display = "flex";
    setSpStatus("badge-maintenance", "Offline");
    ["sp-recent-grades", "sp-upcoming-tasks", "sp-timetable-container", "sp-grade-matrix", "sp-absences-list"].forEach(id => {
      document.getElementById(id)?.replaceChildren();
    });
    return;
  }

  const nameEl = document.getElementById("sp-student-name");
  if (nameEl) nameEl.innerText = data.student?.Nev || "Diák";

  const schoolEl = document.getElementById("sp-student-school");
  if (schoolEl) {
    schoolEl.innerText = data.student?.IntezmenyNev ||
                         data.student?.Intezmeny?.TeljesNev ||
                         data.student?.Intezmeny?.Nev ||
                         (spState.isDemo ? "Pala Minta Gimnázium" : "e-Kréta");
  }

  if (spState.isMaintenance) {
    if (maintText) maintText.textContent = offlineNotice(data);
    if (maintBanner) maintBanner.style.display = "flex";
    setSpStatus("badge-maintenance", "Offline");
  } else {
    if (maintBanner) maintBanner.style.display = "none";
    setSpStatus(spState.isDemo ? "badge-demo" : "badge-online", spState.isDemo ? "Demó" : "Online");
  }

  renderLiveHero(data.timetable || []);
  renderDashboardView(data);
  renderTimetableView(data.timetable || [], data.weekType);
  renderGradeMatrixView(data.grades || [], data.groupAverages || []);
  renderAbsencesView(data.absences || []);
}

function renderLiveHero(timetable) {
  const tagEl = document.getElementById("sp-live-tag");
  const roomEl = document.getElementById("sp-live-room");
  const subEl = document.getElementById("sp-live-subject");
  const detEl = document.getElementById("sp-live-details");
  const bannerEl = document.getElementById("sp-live-sub-banner");
  const progWrap = document.getElementById("sp-live-progress-wrap");
  const progFill = document.getElementById("sp-live-progress-fill");
  const countEl = document.getElementById("sp-live-countdown");

  if (!subEl) return;

  const now = new Date();
  const todayIso = localDateKey(now);
  const todayLessons = (timetable || []).filter(l => l.KezdetIdopont && localDateKey(l.KezdetIdopont) === todayIso);

  if (todayLessons.length === 0) {
    if (tagEl) tagEl.innerText = "NINCS TANÍTÁS MÁRA";
    if (roomEl) roomEl.style.display = "none";
    if (bannerEl) bannerEl.style.display = "none";
    subEl.innerText = "Nincs rögzített tanóra";
    if (detEl) detEl.innerText = "Szabadnap vagy hétvége — jó pihenést!";
    if (progWrap) progWrap.style.display = "none";
    if (countEl) countEl.innerText = "";
    return;
  }

  let current = null;
  let next = null;
  for (const lesson of todayLessons) {
    const s = new Date(lesson.KezdetIdopont);
    const e = new Date(lesson.VegIdopont);
    if (now >= s && now <= e) {
      current = lesson;
      break;
    } else if (now < s && (!next || new Date(next.KezdetIdopont) > s)) {
      next = lesson;
    }
  }

  const target = current || next;
  const anomaly = getLessonAnomaly(target);

  if (roomEl) {
    if (target?.TeremNeve) {
      roomEl.style.display = "inline-block";
      roomEl.innerText = `Terem: ${target.TeremNeve}`;
    } else {
      roomEl.style.display = "none";
    }
  }

  if (bannerEl) {
    if (anomaly.isCancelled) {
      bannerEl.style.display = "block";
      bannerEl.className = "sub-alert-banner is-cancelled";
      bannerEl.innerText = "ELMARAD: Ez az óra törölve lett a mai órarendből.";
    } else if (anomaly.isSubstituted) {
      bannerEl.style.display = "block";
      bannerEl.className = "sub-alert-banner is-sub";
      bannerEl.innerText = `HELYETTESÍTÉS${anomaly.substituteTeacher ? `: ${anomaly.substituteTeacher}` : ""}`;
    } else {
      bannerEl.style.display = "none";
    }
  }

  if (current) {
    const s = new Date(current.KezdetIdopont);
    const e = new Date(current.VegIdopont);
    const pct = Math.min(100, Math.max(0, Math.round(((now - s) / (e - s)) * 100)));
    const mins = Math.ceil((e - now) / 60000);

    if (tagEl) tagEl.innerText = `FOLYAMATBAN • ${current.Oraszam || ""}. ÓRA`;
    subEl.innerText = current.Tantargy?.Nev || current.Nev || "Tanóra";
    if (detEl) detEl.innerText = `${formatLocalTime(s)} - ${formatLocalTime(e)} • ${current.TanarNeve || ""}`;
    if (progWrap) progWrap.style.display = "block";
    if (progFill) progFill.style.width = `${pct}%`;
    if (countEl) countEl.innerText = `Hátra van: ${mins} perc`;
  } else if (next) {
    const s = new Date(next.KezdetIdopont);
    const mins = Math.ceil((s - now) / 60000);
    if (tagEl) tagEl.innerText = `KÖVETKEZŐ • ${next.Oraszam || ""}. ÓRA`;
    subEl.innerText = next.Tantargy?.Nev || next.Nev || "Tanóra";
    if (detEl) detEl.innerText = `Kezdés: ${formatLocalTime(s)} • ${next.TanarNeve || ""}`;
    if (progWrap) progWrap.style.display = "none";
    if (countEl) countEl.innerText = `Kezdésig: ${mins} perc`;
  } else {
    if (tagEl) tagEl.innerText = "TANÍTÁSI NAP VÉGE";
    if (roomEl) roomEl.style.display = "none";
    if (bannerEl) bannerEl.style.display = "none";
    subEl.innerText = "Minden mai óra véget ért";
    if (detEl) detEl.innerText = `Ma összesen ${todayLessons.length} tanóra volt.`;
    if (progWrap) progWrap.style.display = "none";
    if (countEl) countEl.innerText = "Szép estét!";
  }
}

function renderDashboardView(data) {
  const grades = data.grades || [];
  const timetable = data.timetable || [];
  const absences = data.absences || [];
  const homework = data.homework || [];
  const exams = data.exams || [];

  let weightedSum = 0;
  let totalWeight = 0;
  grades.forEach(g => {
    const p = KretaApi.parseGrade(g);
    if (p.numericGrade !== null && !p.isSummary) {
      weightedSum += p.numericGrade * p.weight;
      totalWeight += p.weight;
    }
  });
  const gpa = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(2) : "--";

  const todayIso = localDateKey(new Date());
  const todayCount = timetable.filter(l => l.KezdetIdopont && localDateKey(l.KezdetIdopont) === todayIso).length;
  const missedHours = absences.filter(a => !(a.KesesPercben > 0)).length;

  const kpiGpa = document.getElementById("sp-kpi-gpa");
  const kpiGpaSub = document.getElementById("sp-kpi-gpa-sub");
  if (kpiGpa) kpiGpa.innerText = gpa;
  if (kpiGpaSub) kpiGpaSub.innerText = `${grades.length} rögzített jegy`;

  const kpiLessons = document.getElementById("sp-kpi-lessons");
  const kpiLessonsSub = document.getElementById("sp-kpi-lessons-sub");
  if (kpiLessons) kpiLessons.innerText = `${todayCount} óra`;
  if (kpiLessonsSub) kpiLessonsSub.innerText = data.weekType ? `Hetirend: ${data.weekType}` : "Mai tanórák";

  const kpiAbs = document.getElementById("sp-kpi-absences");
  const kpiAbsSub = document.getElementById("sp-kpi-absences-sub");
  if (kpiAbs) {
    kpiAbs.innerText = `${missedHours} óra`;
    kpiAbs.style.color = missedHours >= 200 ? "var(--danger)" : (missedHours >= 150 ? "var(--warning)" : "var(--success)");
  }
  if (kpiAbsSub) kpiAbsSub.innerText = `${Math.max(0, 250 - missedHours)} óra maradt`;

  const kpiTasks = document.getElementById("sp-kpi-tasks");
  const kpiTasksSub = document.getElementById("sp-kpi-tasks-sub");
  if (kpiTasks) kpiTasks.innerText = `${homework.length + exams.length} db`;
  if (kpiTasksSub) kpiTasksSub.innerText = `${exams.length} dolgozat, ${homework.length} házi`;

  // Recent grades (top 6)
  const recGradesEl = document.getElementById("sp-recent-grades");
  if (recGradesEl) {
    recGradesEl.innerHTML = "";
    grades.slice(0, 6).forEach(g => {
      const p = KretaApi.parseGrade(g);
      const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Tantárgy";
      const topic = g.Tema || g.Tipus?.Leiras || "Értékelés";
      const item = document.createElement("div");
      item.className = "sp-list-item";
      item.innerHTML = `
        <div class="sp-item-left">
          <span class="grade-badge ${p.badgeClass}">${escapeHtml(p.displayValue)}</span>
          <div style="min-width:0; flex:1;">
            <div class="sp-item-title">${escapeHtml(sub)}</div>
            <div class="sp-item-sub">${escapeHtml(topic)} (${p.weightPercent}%)</div>
          </div>
        </div>
      `;
      recGradesEl.appendChild(item);
    });
  }

  // Upcoming tasks
  const tasksEl = document.getElementById("sp-upcoming-tasks");
  if (tasksEl) {
    tasksEl.innerHTML = "";
    const combined = [
      ...exams.map(e => ({ type: "DOLGOZAT", color: "var(--danger)", sub: e.Tantargy?.Nev || e.Tantargy || "Tantárgy", text: e.Tema || e.Tipus || "Számonkérés" })),
      ...homework.map(h => ({ type: "HÁZI", color: "var(--info)", sub: h.Tantargy?.Nev || h.Tantargy || "Tantárgy", text: h.Szoveg || h.Feladat || "Házi feladat" }))
    ];
    if (combined.length === 0) {
      tasksEl.innerHTML = `<div style="padding:14px; text-align:center; color:var(--text-muted); font-size:0.75rem;">Nincs közelgő feladat.</div>`;
    } else {
      combined.slice(0, 5).forEach(t => {
        const card = document.createElement("div");
        card.className = "sp-list-item";
        card.innerHTML = `
          <div style="min-width:0; flex:1;">
            <div style="font-size:0.74rem; margin-bottom:2px;">
              <strong style="color:${t.color}; font-size:0.64rem; margin-right:5px;">${t.type}</strong>
              <strong>${escapeHtml(t.sub)}</strong>
            </div>
            <div class="sp-item-sub">${escapeHtml(t.text)}</div>
          </div>
        `;
        tasksEl.appendChild(card);
      });
    }
  }
}

function setupTimetableControls() {
  document.querySelectorAll("#sp-day-tabs .chip-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      spState.selectedDay = btn.getAttribute("data-day") || "all";
      document.querySelectorAll("#sp-day-tabs .chip-btn").forEach(b => b.classList.toggle("active", b === btn));
      if (spState.data) {
        renderTimetableView(spState.data.timetable || [], spState.data.weekType);
      }
    });
  });

  document.getElementById("sp-btn-ab-week")?.addEventListener("click", () => {
    if (!spState.isDemo) return;
    const currentIsA = (spState.data?.weekType || "A hét").startsWith("A");
    spState.demoAWeekOverride = !currentIsA;
    spState.data = KretaApi.getDemoDataset(spState.demoAWeekOverride);
    renderAllViews();
  });

  document.getElementById("sp-btn-export-ics")?.addEventListener("click", () => {
    exportIcsFile(spState.data?.timetable || []);
  });
}

function renderTimetableView(timetable, weekType) {
  const container = document.getElementById("sp-timetable-container");
  const abBtn = document.getElementById("sp-btn-ab-week");
  if (abBtn) {
    abBtn.style.display = weekType ? "inline-flex" : "none";
    abBtn.innerText = weekType || "A hét";
  }
  if (!container) return;
  container.innerHTML = "";

  // Group lessons by weekday index (0 = Mon .. 4 = Fri)
  const byDay = { 0: [], 1: [], 2: [], 3: [], 4: [] };
  (timetable || []).forEach(lesson => {
    if (!lesson.KezdetIdopont) return;
    const d = new Date(lesson.KezdetIdopont);
    const dayIdx = (d.getDay() + 6) % 7; // 0 = Monday
    if (byDay[dayIdx]) byDay[dayIdx].push(lesson);
  });

  const daysToRender = spState.selectedDay === "all"
    ? [0, 1, 2, 3, 4]
    : [parseInt(spState.selectedDay, 10)];

  daysToRender.forEach(dayIdx => {
    const dayLessons = (byDay[dayIdx] || []).sort((a, b) => (a.Oraszam || 0) - (b.Oraszam || 0));
    if (spState.selectedDay === "all") {
      const hdr = document.createElement("div");
      hdr.className = "sp-day-group-header";
      hdr.innerText = `${DAY_NAMES_HU[dayIdx]} (${dayLessons.length} óra)`;
      container.appendChild(hdr);
    }

    if (dayLessons.length === 0) {
      const empty = document.createElement("div");
      empty.className = "sp-list-item";
      empty.innerHTML = `<span style="font-size:0.75rem; color:var(--text-muted);">Nincs rögzített tanóra ezen a napon.</span>`;
      container.appendChild(empty);
      return;
    }

    dayLessons.forEach(item => {
      const anomaly = getLessonAnomaly(item);
      const card = document.createElement("div");
      card.className = `sp-list-item ${anomaly.isCancelled ? "cancelled" : (anomaly.isSubstituted ? "substituted" : "")}`;

      const subName = item.Tantargy?.Nev || item.Tantargy || item.Nev || "Tanóra";
      const timeRange = item.KezdetIdopont && item.VegIdopont
        ? `${formatLocalTime(item.KezdetIdopont)} - ${formatLocalTime(item.VegIdopont)}`
        : "";
      const teacher = anomaly.isSubstituted && anomaly.substituteTeacher
        ? `Helyettesítő: ${anomaly.substituteTeacher}`
        : (item.TanarNeve || "");
      const meta = [timeRange, item.TeremNeve ? `Terem: ${item.TeremNeve}` : "", teacher].filter(Boolean).join(" • ");

      const badgeHtml = anomaly.isCancelled
        ? `<span class="badge" style="color:var(--danger); border-color:rgba(255,69,58,0.4);">Elmarad</span>`
        : (anomaly.isSubstituted ? `<span class="badge" style="color:var(--warning); border-color:rgba(255,214,10,0.4);">Helyettesítés</span>` : "");

      card.innerHTML = `
        <div class="sp-item-left">
          <div class="sp-lesson-num">${escapeHtml(item.Oraszam ?? "-")}</div>
          <div style="min-width:0; flex:1;">
            <div class="sp-item-title ${anomaly.isCancelled ? "line-through" : ""}">${escapeHtml(subName)}</div>
            <div class="sp-item-sub">${escapeHtml(meta)}</div>
          </div>
        </div>
        ${badgeHtml}
      `;
      container.appendChild(card);
    });
  });
}

function setupGradeControls() {
  const searchInput = document.getElementById("sp-grade-search");
  searchInput?.addEventListener("input", () => {
    spState.gradeSearch = searchInput.value.trim();
    if (spState.data) {
      renderGradeMatrixView(spState.data.grades || [], spState.data.groupAverages || []);
    }
  });

  ["sp-ghost-subject", "sp-ghost-grade", "sp-ghost-weight"].forEach(id => {
    document.getElementById(id)?.addEventListener("change", () => {
      updateSpGhostSimulation();
    });
  });

  document.getElementById("sp-btn-export-csv")?.addEventListener("click", () => {
    exportGradesCsv(spState.data?.grades || []);
  });
}

function getAvgColorClass(avg) {
  if (avg >= 4.5) return "grade-5";
  if (avg >= 3.5) return "grade-4";
  if (avg >= 2.5) return "grade-3";
  if (avg >= 2.0) return "grade-2";
  return "grade-1";
}

function renderGradeMatrixView(grades, groupAverages) {
  const matrixEl = document.getElementById("sp-grade-matrix");
  const ghostSubSelect = document.getElementById("sp-ghost-subject");
  if (!matrixEl) return;

  const classAvgMap = {};
  (groupAverages || []).forEach(ga => {
    const name = ga.Tantargy?.Nev || ga.TantargyNev || ga.Tantargy;
    if (name && ga.OsztalyAtlag) classAvgMap[name] = Number(ga.OsztalyAtlag);
  });

  const subjectMap = {};
  (grades || []).forEach(g => {
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Egyéb";
    if (!subjectMap[sub]) subjectMap[sub] = [];
    subjectMap[sub].push(g);
  });

  const allSubjects = Object.keys(subjectMap).sort();

  if (ghostSubSelect && ghostSubSelect.options.length !== allSubjects.length) {
    ghostSubSelect.innerHTML = allSubjects
      .map(s => `<option value="${escapeHtml(s)}">${escapeHtml(s)}</option>`)
      .join("");
  }
  updateSpGhostSimulation();

  const queryNorm = normalizeHungarian(spState.gradeSearch);
  const filteredSubjects = allSubjects.filter(s => !queryNorm || normalizeHungarian(s).includes(queryNorm));

  matrixEl.innerHTML = "";
  if (filteredSubjects.length === 0) {
    matrixEl.innerHTML = `<div style="padding:20px; text-align:center; color:var(--text-muted); font-size:0.78rem;">Nincs a keresésnek megfelelő tantárgy.</div>`;
    return;
  }

  filteredSubjects.forEach(sub => {
    const subGrades = subjectMap[sub] || [];
    let sum = 0;
    let weight = 0;
    subGrades.forEach(g => {
      const p = KretaApi.parseGrade(g);
      if (p.numericGrade !== null && !p.isSummary) {
        sum += p.numericGrade * p.weight;
        weight += p.weight;
      }
    });
    const avg = weight > 0 ? sum / weight : 0;
    const classAvg = classAvgMap[sub];

    const pillsHtml = subGrades.map(g => {
      const p = KretaApi.parseGrade(g);
      const topic = g.Tema || g.Tipus?.Leiras || "Értékelés";
      return `<span class="grade-badge ${p.badgeClass}" title="${escapeHtml(topic)} (${p.weightPercent}%)">${escapeHtml(p.displayValue)}</span>`;
    }).join("");

    const card = document.createElement("div");
    card.className = "sp-matrix-card";
    card.innerHTML = `
      <div class="sp-matrix-top">
        <div style="min-width:0; flex:1;">
          <div class="sp-matrix-sub">${escapeHtml(sub)}</div>
          <div class="sp-matrix-meta">
            ${subGrades.length} db jegy${classAvg ? ` • Osztályátlag: ${classAvg.toFixed(2)}` : ""}
          </div>
        </div>
        <span class="sp-matrix-avg ${getAvgColorClass(avg)}">${avg > 0 ? avg.toFixed(2) : "-"}</span>
      </div>
      <div class="sp-matrix-pills">${pillsHtml}</div>
    `;
    matrixEl.appendChild(card);
  });
}

function updateSpGhostSimulation() {
  const grades = spState.data?.grades || [];
  const sub = document.getElementById("sp-ghost-subject")?.value;
  const gVal = parseInt(document.getElementById("sp-ghost-grade")?.value || "5", 10);
  const wVal = parseInt(document.getElementById("sp-ghost-weight")?.value || "100", 10) / 100;
  const outEl = document.getElementById("sp-ghost-output");
  if (!outEl || !sub) return;

  let sum = 0;
  let weight = 0;
  grades.forEach(g => {
    const s = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy;
    const p = KretaApi.parseGrade(g);
    if (s === sub && p.numericGrade !== null && !p.isSummary) {
      sum += p.numericGrade * p.weight;
      weight += p.weight;
    }
  });

  const cur = weight > 0 ? sum / weight : 0;
  const proj = (sum + gVal * wVal) / (weight + wVal);
  const diff = proj - cur;
  const diffColor = diff >= 0 ? "var(--success)" : "var(--danger)";

  outEl.innerHTML = `
    <strong>${escapeHtml(sub)}</strong>: ${cur.toFixed(2)} &rarr;
    <strong style="color:var(--primary);">${proj.toFixed(2)}</strong>
    <span style="color:${diffColor}; font-weight:800; margin-left:4px;">(${diff >= 0 ? "+" : ""}${diff.toFixed(2)})</span>
  `;
}

function setupAbsenceControls() {
  document.querySelectorAll("#sp-absence-filters .chip-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      spState.absenceFilter = btn.getAttribute("data-filter") || "all";
      document.querySelectorAll("#sp-absence-filters .chip-btn").forEach(b => b.classList.toggle("active", b === btn));
      if (spState.data) {
        renderAbsencesView(spState.data.absences || []);
      }
    });
  });
}

function renderAbsencesView(absences) {
  let excused = 0;
  let unexcused = 0;
  let delayMins = 0;

  (absences || []).forEach(a => {
    const delay = Number(a.KesesPercben || 0);
    const status = String(a.IgazolasAllapota || "").toLowerCase();
    const isUnexcused = status.includes("igazolatlan");
    if (delay > 0) {
      delayMins += delay;
    } else if (isUnexcused) {
      unexcused++;
    } else {
      excused++;
    }
  });

  const totalHours = excused + unexcused;
  const pct = Math.min(100, (totalHours / 250) * 100);
  const remaining = Math.max(0, 250 - totalHours);

  const zoneBadge = document.getElementById("sp-absence-zone-badge");
  const pctEl = document.getElementById("sp-absence-pct");
  const titleEl = document.getElementById("sp-absence-total-title");
  const remEl = document.getElementById("sp-absence-remaining");
  const progEl = document.getElementById("sp-absence-progress");

  const isCrit = totalHours >= 200;
  const isWarn = totalHours >= 150 && totalHours < 200;
  const toneColor = isCrit ? "var(--danger)" : (isWarn ? "var(--warning)" : "var(--success)");

  if (zoneBadge) {
    zoneBadge.className = `badge ${isCrit ? "badge-maintenance" : (isWarn ? "badge-demo" : "badge-online")}`;
    zoneBadge.innerText = isCrit ? "KRITIKUS (200+ ÓRA)" : (isWarn ? "FIGYELMEZTETÉS (150+ ÓRA)" : "BIZTONSÁGOS ZÓNA");
  }
  if (pctEl) {
    pctEl.innerText = `${pct.toFixed(1)}%`;
    pctEl.style.color = toneColor;
  }
  if (titleEl) titleEl.innerText = `${totalHours} / 250 óra`;
  if (remEl) remEl.innerText = `Még ${remaining} óra maradt`;
  if (progEl) {
    progEl.style.width = `${pct}%`;
    progEl.style.background = toneColor;
  }

  const excEl = document.getElementById("sp-abs-excused");
  const unexcEl = document.getElementById("sp-abs-unexcused");
  const lateEl = document.getElementById("sp-abs-late");
  if (excEl) excEl.innerText = `${excused} óra`;
  if (unexcEl) unexcEl.innerText = `${unexcused} óra`;
  if (lateEl) lateEl.innerText = `${delayMins} perc`;

  const listEl = document.getElementById("sp-absences-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const filtered = (absences || []).filter(a => {
    const delay = Number(a.KesesPercben || 0);
    const isUnexcused = String(a.IgazolasAllapota || "").toLowerCase().includes("igazolatlan");
    if (spState.absenceFilter === "late") return delay > 0;
    if (spState.absenceFilter === "unexcused") return isUnexcused;
    if (spState.absenceFilter === "excused") return !isUnexcused && delay === 0;
    return true;
  });

  if (filtered.length === 0) {
    listEl.innerHTML = `<div style="padding:18px; text-align:center; color:var(--text-muted); font-size:0.75rem;">Nincs megjeleníthető mulasztás.</div>`;
    return;
  }

  filtered.forEach(a => {
    const sub = a.Tantargy?.Nev || a.Tantargy || "Tanóra";
    const delay = Number(a.KesesPercben || 0);
    const isUnexcused = String(a.IgazolasAllapota || "").toLowerCase().includes("igazolatlan");
    const dateStr = a.Datum ? new Date(a.Datum).toLocaleDateString("hu-HU") : "";
    const statusLabel = delay > 0 ? `Késés (${delay} p)` : (isUnexcused ? "Igazolatlan" : "Igazolt");
    const statusColor = isUnexcused ? "var(--danger)" : (delay > 0 ? "var(--warning)" : "var(--success)");

    const row = document.createElement("div");
    row.className = "sp-list-item";
    row.innerHTML = `
      <div style="min-width:0; flex:1;">
        <div class="sp-item-title">${escapeHtml(sub)}</div>
        <div class="sp-item-sub">${escapeHtml(dateStr)} • ${escapeHtml(a.Tipus || "Mulasztás")}</div>
      </div>
      <span class="badge" style="color:${statusColor}; border-color:${statusColor};">${escapeHtml(statusLabel)}</span>
    `;
    listEl.appendChild(row);
  });
}

function exportIcsFile(timetable) {
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//Pala//Kreta Timetable//HU",
    "CALSCALE:GREGORIAN"
  ];
  const fmtUtc = (iso) => new Date(iso).toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");

  (timetable || []).forEach(l => {
    if (!l.KezdetIdopont || !l.VegIdopont) return;
    const sub = l.Tantargy?.Nev || l.Tantargy || l.Nev || "Tanóra";
    lines.push("BEGIN:VEVENT");
    lines.push(`UID:pala-${l.Id || Math.random()}@pala.edu.hu`);
    lines.push(`DTSTART:${fmtUtc(l.KezdetIdopont)}`);
    lines.push(`DTEND:${fmtUtc(l.VegIdopont)}`);
    lines.push(`SUMMARY:${sub}`);
    if (l.TeremNeve) lines.push(`LOCATION:${l.TeremNeve}`);
    lines.push("END:VEVENT");
  });
  lines.push("END:VCALENDAR");

  const blob = new Blob([lines.join("\r\n")], { type: "text/calendar;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "pala_orarend.ics";
  a.click();
  URL.revokeObjectURL(url);
}

function exportGradesCsv(grades) {
  const rows = [['"Tantárgy"', '"Jegy"', '"Súly (%)"', '"Téma"', '"Dátum"']];
  (grades || []).forEach(g => {
    const p = KretaApi.parseGrade(g);
    const sub = g.Tantargy?.Nev || g.TantargyNev || g.Tantargy || "Tantárgy";
    const topic = g.Tema || g.Tipus?.Leiras || "Értékelés";
    const dateStr = (g.RogzitesDatuma || g.Datum || "").slice(0, 10);
    const esc = (v) => `"${String(v || "").replace(/"/g, '""')}"`;
    rows.push([esc(sub), esc(p.displayValue), esc(`${p.weightPercent}%`), esc(topic), esc(dateStr)]);
  });

  const csvContent = "\uFEFF" + rows.map(r => r.join(",")).join("\r\n");
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "pala_jegyek.csv";
  a.click();
  URL.revokeObjectURL(url);
}
