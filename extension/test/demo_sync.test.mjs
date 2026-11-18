// The extension's demo data (DEMO_* in shared/kreta_api.js) must match the
// Dart reference copy, lib/api/demo_data.dart. Both are reduced to the same
// summary and compared with fixtures/demo/demo_summary.json; the Dart side is
// test/demo_sync_test.dart, which also explains how to regenerate the fixture.
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { loadKretaApi } from "./load_kreta_api.mjs";

const { KretaApi } = loadKretaApi();
const fixture = JSON.parse(readFileSync(new URL("../../fixtures/demo/demo_summary.json", import.meta.url), "utf8"));

const two = n => String(n).padStart(2, "0");
const hhmm = value => { const d = new Date(value); return `${two(d.getHours())}:${two(d.getMinutes())}`; };
const hoursFrom = (now, value) => (value ? String(Math.round((new Date(value).getTime() - now) / 3600000)) : "");
const fixed2 = n => n.toFixed(2);

/** Same fields and order as demoSummary in test/demo_sync_test.dart. */
function demoSummary(now) {
  const data = KretaApi.getDemoDataset();
  const subjectAverages = KretaApi.subjectAverages(data.grades);
  const week = aWeek => KretaApi.getDemoDataset(aWeek).timetable.map(l => [
    new Date(l.KezdetIdopont).getDay(),
    l.Oraszam,
    l.Tantargy.Nev,
    l.TanarNeve || "",
    l.TeremNeve || "",
    `${hhmm(l.KezdetIdopont)}-${hhmm(l.VegIdopont)}`,
    l.Tema || "",
    l.HelyettesTanarNeve || "",
    String(l.Allapot?.Nev || "").toLowerCase().includes("elmarad") ? "elmarad" : ""
  ].join("|"));
  const ownMessages = data.messages.filter(m => m.source === "eugyintezes");
  const notes = data.messages.filter(m => m.source === "ellenorzo");

  return {
    student: data.student.Nev,
    className: data.className,
    overallAverage: fixed2(KretaApi.overallAverage(data.grades)),
    subjectAverages: Object.fromEntries(Object.keys(subjectAverages).sort().map(k => [k, fixed2(subjectAverages[k])])),
    groupAverages: Object.fromEntries(data.groupAverages.map(a => [a.Tantargy.Nev, fixed2(a.OsztalyCsoportAtlag)])),
    grades: data.grades.map(g => {
      const p = KretaApi.parseGrade(g);
      const d = new Date(g.KeszitesDatuma);
      return [
        g.Tantargy.Nev,
        g.SzovegesErtek || "",
        KretaApi.countsForAverage(p) ? String(Math.round(g.SulySzazalek)) : "-",
        `${two(d.getMonth() + 1)}-${two(d.getDate())}`,
        g.Tipus?.Leiras || "",
        g.Tema || "",
        g.ErtekeloTanarNeve || ""
      ].join("|");
    }).sort(),
    timetableA: week(true),
    timetableB: week(false),
    exams: data.exams.map(e => [e.Tantargy, e.Modja?.Leiras || "", e.Tema || "", hoursFrom(now, e.Datum)].join("|")),
    homework: data.homework.map(h => [h.Tantargy, h.Szoveg, hoursFrom(now, h.FeladasDatuma), hoursFrom(now, h.Hatarido)].join("|")),
    messages: ownMessages.map(m => [
      m.id,
      m.sender,
      m.subject,
      m.isRead ? "olvasott" : "olvasatlan",
      hoursFrom(now, m.date),
      (m.attachments || []).map(a => a.fajlNev).join(","),
      m.content
    ].join("|")).sort(),
    notes: notes.map(n => [n.id, n.type, n.sender, n.title, hoursFrom(now, n.date), n.content].join("|")).sort(),
    absences: data.absences.map(a => [a.Tantargy, a.IgazolasAllapota, a.Tipus || "", a.KesesPercben || 0, hoursFrom(now, a.Datum)].join("|")),
    teachers: data.teachers.map(t => `${t.name}|${t.subjects.join(", ")}`)
  };
}

// The JSON round trip moves the vm context's arrays into this realm, so
// deepEqual compares values instead of failing on the other Array prototype.
const summary = JSON.parse(JSON.stringify(demoSummary(Date.now())));

// One test per section, so a failure names what drifted.
for (const key of Object.keys(fixture)) {
  test(`extension demo ${key} matches lib/api/demo_data.dart`, () => {
    assert.deepEqual(summary[key], fixture[key]);
  });
}

test("extension demo summary has no section the Dart demo lacks", () => {
  assert.deepEqual(Object.keys(summary).sort(), Object.keys(fixture).sort());
});

test("extension demo shows the same overall average as the app", () => {
  assert.equal(summary.overallAverage, "3.87");
});
