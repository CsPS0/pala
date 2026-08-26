// Pala Extension - Popup Logic

let appState = {
  isDemo: true,
  data: null
};

document.addEventListener("DOMContentLoaded", async () => {
  setupTabs();
  setupActions();
  await loadData();
  startCountdownTimer();
});

function setupTabs() {
  const tabs = document.querySelectorAll(".tab-btn");
  tabs.forEach(btn => {
    btn.addEventListener("click", () => {
      tabs.forEach(t => t.classList.remove("active"));
      document.querySelectorAll(".tab-panel").forEach(p => p.classList.remove("active"));

      btn.classList.add("active");
      const target = btn.getAttribute("data-tab");
      document.getElementById(target)?.classList.add("active");
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

  document.getElementById("btn-demo-mode")?.addEventListener("click", async () => {
    await chrome.storage.local.set({ pala_use_demo: true, pala_session: null });
    document.getElementById("login-modal")?.classList.remove("active");
    await loadData(true);
  });

  document.getElementById("btn-login-submit")?.addEventListener("click", async () => {
    const inst = document.getElementById("login-institute").value.trim();
    const user = document.getElementById("login-username").value.trim();
    const pass = document.getElementById("login-password").value.trim();
    const errBox = document.getElementById("login-error");

    if (!inst || !user || !pass) {
      errBox.innerText = "Minden mező kitöltése kötelező!";
      errBox.style.display = "block";
      return;
    }

    try {
      errBox.innerText = "Bejelentkezés folyamatban...";
      errBox.style.display = "block";
      const tokenData = await KretaApi.login(inst, user, pass);
      await chrome.storage.local.set({
        pala_use_demo: false,
        pala_session: {
          institute: inst,
          token: tokenData.access_token,
          user: user
        }
      });
      document.getElementById("login-modal")?.classList.remove("active");
      await loadData(true);
    } catch (e) {
      errBox.innerText = e.message || "Bejelentkezési hiba.";
      errBox.style.display = "block";
    }
  });
}

async function loadData(forceRefresh = false) {
  const store = await chrome.storage.local.get(["pala_use_demo", "pala_session", "pala_cached_data"]);
  const useDemo = store.pala_use_demo !== false; // Default to demo

  if (useDemo || !store.pala_session) {
    appState.isDemo = true;
    appState.data = KretaApi.getDemoDataset();
  } else {
    appState.isDemo = false;
    try {
      if (!forceRefresh && store.pala_cached_data) {
        appState.data = store.pala_cached_data;
      } else {
        const { institute, token } = store.pala_session;
        appState.data = await KretaApi.getStudentData(institute, token);
        await chrome.storage.local.set({ pala_cached_data: appState.data });
      }
    } catch (err) {
      console.warn("Could not fetch online Kréta data, falling back to cached/demo:", err);
      appState.data = store.pala_cached_data || KretaApi.getDemoDataset();
    }
  }

  renderUI();
}

function renderUI() {
  const data = appState.data;
  if (!data) return;

  // Header & Badge
  const studentNameEl = document.getElementById("student-name");
  if (studentNameEl) studentNameEl.innerText = data.student?.Nev || "Diák";

  const badgeEl = document.getElementById("status-badge");
  if (badgeEl) {
    if (appState.isDemo) {
      badgeEl.className = "badge badge-demo";
      badgeEl.innerText = "Demó (Teszt Elek)";
    } else {
      badgeEl.className = "badge";
      badgeEl.style.color = "var(--success)";
      badgeEl.style.borderColor = "rgba(48,209,88,0.3)";
      badgeEl.innerText = "Online";
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

  if (timetable.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 20px; color: var(--text-muted); font-size: 0.78rem;">Nincs rögzített tanóra mára.</div>`;
    return;
  }

  timetable.forEach((item, idx) => {
    const card = document.createElement("div");
    card.className = "item-card";
    const subName = item.Tantargy?.Nev || item.Nev || "Tanóra";
    const room = item.Terem ? `Terem: ${item.Terem}` : "";
    const teacher = item.Tanar || "";
    const details = [room, teacher].filter(Boolean).join(" • ");

    card.innerHTML = `
      <div class="item-left">
        <div class="item-index">${item.Oraszam || idx + 1}</div>
        <div>
          <div class="item-title">${subName}</div>
          <div class="item-sub">${details || "Időpont: 08:00 - 08:45"}</div>
        </div>
      </div>
    `;
    listEl.appendChild(card);
  });
}

function renderGrades(grades) {
  const listEl = document.getElementById("grades-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  if (grades.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 20px; color: var(--text-muted); font-size: 0.78rem;">Nincs megjeleníthető érdemjegy.</div>`;
    return;
  }

  let totalWeight = 0;
  let weightedSum = 0;

  grades.forEach(g => {
    const val = g.SzamErtek || parseInt(g.SzovegesErtek, 10) || 5;
    const weight = (g.SulySzazalek || 100) / 100;
    weightedSum += val * weight;
    totalWeight += weight;

    const card = document.createElement("div");
    card.className = "item-card";
    const sub = g.Tantargy?.Nev || "Tantárgy";
    const topic = g.Tema || g.Tipus?.Leiras || "Értékelés";
    const weightText = g.SulySzazalek && g.SulySzazalek !== 100 ? ` (${g.SulySzazalek}%)` : "";

    card.innerHTML = `
      <div class="item-left">
        <div class="grade-badge grade-${val}">${val}</div>
        <div>
          <div class="item-title">${sub}${weightText}</div>
          <div class="item-sub">${topic}</div>
        </div>
      </div>
    `;
    listEl.appendChild(card);
  });

  const avg = totalWeight > 0 ? (weightedSum / totalWeight).toFixed(2) : "0.00";
  const avgEl = document.getElementById("average-value");
  if (avgEl) avgEl.innerText = avg;

  const countEl = document.getElementById("grade-count");
  if (countEl) countEl.innerText = `${grades.length} jegy`;
}

function renderTasks(homework, exams) {
  const listEl = document.getElementById("tasks-list");
  if (!listEl) return;
  listEl.innerHTML = "";

  const items = [
    ...exams.map(e => ({ type: "exam", sub: e.Tantargy, title: e.Tema || e.Tipus, date: e.Datum })),
    ...homework.map(h => ({ type: "hw", sub: h.Tantargy, title: h.Szoveg, date: h.Hatarido }))
  ];

  if (items.length === 0) {
    listEl.innerHTML = `<div style="text-align:center; padding: 20px; color: var(--text-muted); font-size: 0.78rem;">Nincs közelgő feladat vagy dolgozat.</div>`;
    return;
  }

  items.forEach(it => {
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
}

function updateActiveClass(timetable) {
  const cardEl = document.getElementById("active-class-card");
  if (!cardEl || timetable.length === 0) return;

  const active = timetable[0]; // Active class preview
  document.getElementById("active-subject").innerText = active.Tantargy?.Nev || "Matematika";
  document.getElementById("active-details").innerText = `Terem: ${active.Terem || "204"} • ${active.Tanar || "Kovács Péter"}`;
}

function startCountdownTimer() {
  let minutesLeft = 18;
  setInterval(() => {
    const countdownEl = document.getElementById("active-countdown");
    if (countdownEl) {
      countdownEl.innerText = `Hátra van még: ${minutesLeft} perc`;
    }
  }, 60000);
}
