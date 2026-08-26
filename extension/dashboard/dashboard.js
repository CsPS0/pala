// Pala Extension - Full Dashboard Logic

let fullState = {
  isDemo: true,
  data: null
};

document.addEventListener("DOMContentLoaded", async () => {
  setupSidebarNavigation();
  document.getElementById("btn-reload")?.addEventListener("click", () => loadDashboardData(true));
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
    });
  });
}

async function loadDashboardData(force = false) {
  const store = await chrome.storage.local.get(["pala_use_demo", "pala_session", "pala_cached_data"]);
  const useDemo = store.pala_use_demo !== false;

  if (useDemo || !store.pala_session) {
    fullState.isDemo = true;
    fullState.data = KretaApi.getDemoDataset();
  } else {
    fullState.isDemo = false;
    try {
      if (!force && store.pala_cached_data) {
        fullState.data = store.pala_cached_data;
      } else {
        const { institute, token } = store.pala_session;
        fullState.data = await KretaApi.getStudentData(institute, token);
        await chrome.storage.local.set({ pala_cached_data: fullState.data });
      }
    } catch (e) {
      fullState.data = store.pala_cached_data || KretaApi.getDemoDataset();
    }
  }

  renderDashboard();
}

function renderDashboard() {
  const d = fullState.data;
  if (!d) return;

  document.getElementById("student-name").innerText = d.student?.Nev || "Teszt Elek";
  document.getElementById("inst-name").innerText = d.student?.Intezmeny?.Nev || "Pala Minta Gimnázium";

  // Recent Grades in Dashboard
  const table = document.getElementById("dash-grades-table");
  if (table) {
    table.innerHTML = "";
    (d.grades || []).slice(0, 5).forEach(g => {
      const val = g.SzamErtek || 5;
      const row = document.createElement("div");
      row.className = "table-row";
      row.innerHTML = `
        <div style="display:flex; align-items:center; gap:12px;">
          <div class="grade-badge grade-${val}">${val}</div>
          <div>
            <div style="font-weight:700; font-size:0.88rem;">${g.Tantargy?.Nev || "Tantárgy"}</div>
            <div style="font-size:0.75rem; color:var(--text-muted);">${g.Tema || "Értékelés"}</div>
          </div>
        </div>
        <span style="font-size:0.75rem; font-weight:700; color:var(--primary);">${g.SulySzazalek || 100}%</span>
      `;
      table.appendChild(row);
    });
  }

  // 5-Day Weekly Timetable Grid
  const grid = document.getElementById("weekly-timetable-grid");
  if (grid) {
    grid.innerHTML = "";
    const days = ["Hétfő", "Kedd", "Szerda", "Csütörtök", "Péntek"];
    days.forEach(day => {
      const col = document.createElement("div");
      col.className = "timetable-day-card";
      col.innerHTML = `<div class="day-title">${day}</div>`;

      (d.timetable || []).slice(0, 6).forEach((item, idx) => {
        const itemEl = document.createElement("div");
        itemEl.style.padding = "8px 0";
        itemEl.style.borderBottom = "1px solid var(--border)";
        itemEl.innerHTML = `
          <div style="font-size:0.8rem; font-weight:700;">${idx + 1}. ${item.Tantargy?.Nev || "Tanóra"}</div>
          <div style="font-size:0.7rem; color:var(--text-muted);">${item.Terem || "Terem: 101"}</div>
        `;
        col.appendChild(itemEl);
      });
      grid.appendChild(col);
    });
  }
}
