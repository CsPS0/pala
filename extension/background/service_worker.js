// Pala Extension - Background Service Worker

importScripts("../shared/kreta_api.js");

chrome.runtime.onInstalled.addListener(() => {
  console.log("Pala Extension installed successfully.");
  // Setup 15-minute background check alarm
  chrome.alarms.create("pala_grade_sync", { periodInMinutes: 15 });
});

chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === "pala_grade_sync") {
    await checkForNewGrades();
  }
});

async function checkForNewGrades() {
  const store = await chrome.storage.local.get(["pala_use_demo", "pala_session", "pala_known_grade_ids"]);
  if (store.pala_use_demo || !store.pala_session) return;

  try {
    const { institute, token } = store.pala_session;
    const data = await KretaApi.getStudentData(institute, token);
    const knownIds = new Set(store.pala_known_grade_ids || []);

    const newGrades = data.grades.filter(g => !knownIds.has(g.Id));
    if (newGrades.length > 0) {
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

      // Update known IDs
      const allIds = data.grades.map(g => g.Id);
      await chrome.storage.local.set({ pala_known_grade_ids: allIds, pala_cached_data: data });

      // Update badge
      chrome.action.setBadgeText({ text: `${newGrades.length}` });
      chrome.action.setBadgeBackgroundColor({ color: "#FF8800" });
    }
  } catch (err) {
    console.warn("Background grade check failed:", err);
  }
}
