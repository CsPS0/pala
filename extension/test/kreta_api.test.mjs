import { test } from "node:test";
import assert from "node:assert/strict";
import { loadKretaApi } from "./load_kreta_api.mjs";

const { KretaApi, offlineReasonOf, offlineLabel } = loadKretaApi();

test("parseGrade reads the numeric grade and weight", () => {
  const p = KretaApi.parseGrade({ SzamErtek: 4, SulySzazalekErteke: 200, Tipus: { Leiras: "Évközi jegy/értékelés" } });
  assert.equal(p.numericGrade, 4);
  assert.equal(p.weight, 2);
  assert.equal(p.isSummary, false);
});

test("parseGrade keeps an explicit 0% weight", () => {
  assert.equal(KretaApi.parseGrade({ SzamErtek: 5, SulySzazalekErteke: 0 }).weight, 0);
  assert.equal(KretaApi.parseGrade({ SzamErtek: 5 }).weight, 1);
});

test("parseGrade marks midyear grades by code or description", () => {
  assert.equal(KretaApi.parseGrade({ SzamErtek: 3, Tipus: { Nev: "felevi_jegy_ertekeles" } }).isSummary, true);
  assert.equal(KretaApi.parseGrade({ SzamErtek: 3, Tipus: { Leiras: "Év végi jegy/értékelés" } }).isSummary, true);
});

test("institute codes that could change the host are refused", () => {
  assert.equal(KretaApi.isValidInstituteCode("klik012345678"), true);
  for (const bad of ["evil.example#", "a/b", "KLIK1", "", null]) {
    assert.equal(KretaApi.isValidInstituteCode(bad), false, String(bad));
  }
});

test("offline reasons: expired login, no internet, Kréta down", () => {
  assert.equal(offlineReasonOf({ sessionExpired: true }), "expired");
  assert.equal(offlineReasonOf({ status: 401 }), "expired");
  assert.equal(offlineReasonOf({ isMaintenance: true, isNetwork: true }), "network");
  assert.equal(offlineReasonOf({ isMaintenance: true, status: 503 }), "server");
  assert.equal(offlineLabel("expired"), "Lejárt a belépés");
});

test("toCsv: BOM, semicolons, quoted values, CRLF", () => {
  const csv = KretaApi.toCsv(["Tantárgy", "Téma"], [["Matematika", 'Egyenletek; "nehéz"']]);
  assert.equal(csv.charCodeAt(0), 0xfeff);
  assert.ok(csv.includes("Tantárgy;Téma\r\n"));
  assert.ok(csv.includes('"Matematika";"Egyenletek; ""nehéz"""\r\n'));
});

test("timetableToIcs: escaped text, stable UID, cancelled status, folded CRLF lines", () => {
  const lesson = {
    Uid: "123,Orarend",
    KezdetIdopont: "2026-10-20T07:00:00Z",
    VegIdopont: "2026-10-20T07:45:00Z",
    Tantargy: { Nev: "Matematika" },
    Tema: "Egyenletek; függvények, " + "hosszú téma ".repeat(10),
    Allapot: { Nev: "Elmaradt" }
  };
  const ics = KretaApi.timetableToIcs([lesson]);
  const unfolded = ics.replace(/\r\n /g, "");
  assert.ok(unfolded.includes("UID:lesson-123,Orarend@pala"));
  // ";" and "," are escaped with a backslash in iCalendar text.
  const bs = String.fromCharCode(92);
  assert.ok(unfolded.includes(`DESCRIPTION:Egyenletek${bs}; függvények${bs}, hosszú`));
  assert.ok(unfolded.includes("STATUS:CANCELLED"));
  for (const line of ics.split("\r\n")) {
    assert.ok(new TextEncoder().encode(line).length <= 75, line);
  }
});
