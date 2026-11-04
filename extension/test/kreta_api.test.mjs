import { test } from "node:test";
import assert from "node:assert/strict";
import { loadKretaApi } from "./load_kreta_api.mjs";

const { KretaApi, offlineReasonOf, offlineLabel, DEMO_GRADES } = loadKretaApi();

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

test("parseGrade shows a Szazalekos evaluation with a 1-5 number as a percentage", () => {
  const p = KretaApi.parseGrade({ SzamErtek: 4, SzovegesErtek: "4", ErtekFajta: { Nev: "Szazalekos" } });
  assert.equal(p.valueKind, "percent");
  assert.equal(p.displayValue, "4%");
  assert.equal(KretaApi.countsForAverage(p), false);
});

test("demo grades include a percentage and a text evaluation that do not count", () => {
  const kinds = DEMO_GRADES.map((g) => KretaApi.parseGrade(g)).filter((p) => p.valueKind !== "grade");
  assert.deepEqual([...kinds.map((p) => p.displayValue)].sort(), ["4%", "Nem írt"]);
  assert.ok(kinds.every((p) => !KretaApi.countsForAverage(p)));
});

test("classAverageOf reads OsztalyCsoportAtlag, older names and comma decimals", () => {
  assert.equal(KretaApi.classAverageOf({ OsztalyCsoportAtlag: 3.42, TanuloAtlag: 4.1 }), 3.42);
  assert.equal(KretaApi.classAverageOf({ OsztalyAtlag: 4 }), 4);
  assert.equal(KretaApi.classAverageOf({ Atlag: "3,5" }), 3.5);
  assert.equal(KretaApi.classAverageOf({}), null);
  assert.equal(KretaApi.classAverageOf({ OsztalyCsoportAtlag: 0 }), null);
});

test("isWrappedSeason runs from 14 June to 30 September", () => {
  assert.equal(KretaApi.isWrappedSeason(new Date(2027, 5, 13, 23, 59)), false);
  assert.equal(KretaApi.isWrappedSeason(new Date(2027, 5, 14)), true);
  assert.equal(KretaApi.isWrappedSeason(new Date(2027, 8, 30, 23, 59)), true);
  assert.equal(KretaApi.isWrappedSeason(new Date(2027, 9, 1)), false);
});

test("sortMessagesNewestFirst puts the newest first and undated ones last", () => {
  const list = [
    { id: 1, date: "2026-10-01T08:00:00Z" },
    { id: 2 },
    { id: 3, date: "2026-11-02T08:00:00Z" },
    { id: 4, date: "2026-10-15T08:00:00Z" },
  ];
  assert.deepEqual([...KretaApi.sortMessagesNewestFirst(list).map((m) => m.id)], [3, 4, 1, 2]);
});

test("data served during a backoff is marked stale, not live", async () => {
  const store = {
    pala_cached_data: { student: { Nev: "Teszt" }, grades: [] },
    pala_last_fetch: Date.now() - 60 * 60 * 1000,
    pala_backoff_until: Date.now() + 60 * 1000,
  };
  const chrome = { storage: { local: { get: async () => ({ ...store }), set: async () => {}, remove: async () => {} } } };
  const { KretaApi: Api } = loadKretaApi({ chrome });
  const data = await Api.getCachedOrFetchData({ institute: "x", token: "t" });
  assert.equal(data.isStale, true);
  assert.equal(data.cachedAt, store.pala_last_fetch);
});

test("mainClassGroup picks the Osztaly group over subject groups", () => {
  const groups = [{ Tipus: "Csoport", Nev: "11.B angol" }, { Tipus: "Osztaly", Nev: "11.B" }];
  assert.equal(KretaApi.mainClassGroup(groups).Nev, "11.B");
  assert.equal(KretaApi.mainClassGroup([]), null);
});

test("studentProfile reads the real TanuloAdatlap fields and invents nothing", () => {
  const p = KretaApi.studentProfile({
    Nev: "Minta Anna",
    IntezmenyNev: "Minta Iskola",
    IntezmenyAzonosito: "minta-123",
    EmailCim: "anna@example.com",
    Cimek: ["1111 Budapest, Minta utca 1."],
    Bankszamla: { BankszamlaSzam: "11111111-22222222", BankszamlaTulajdonosNeve: "Minta Béla", BankszamlaTulajdonosTipusId: 2 },
  }, "11.B");
  assert.equal(p.instituteCode, "minta-123");
  assert.equal(p.className, "11.B");
  assert.equal(p.email, "anna@example.com");
  assert.equal(p.address, "1111 Budapest, Minta utca 1.");
  assert.equal(p.bankAccount, "11111111-22222222");
  assert.equal(p.bankOwner, "Minta Béla");
  assert.equal(p.bankOwnerType, "-");
  assert.equal(p.omId, "-");
});

test("palaLinks lists the website and GitHub and hides empty URLs", () => {
  const links = [...KretaApi.palaLinks()];
  assert.ok(links.some((l) => l.url === "https://pala-app.hu"));
  assert.ok(links.some((l) => l.url === "https://github.com/CsPS0/pala"));
  assert.ok(links.every((l) => l.url));
});

test("weekRange gives Monday 00:00 to Sunday 23:59 of the week, offset by whole weeks", () => {
  const { monday, sunday } = KretaApi.weekRange(new Date(2026, 10, 4, 15, 0), 0); // Wednesday
  assert.equal(monday.getDate(), 2);
  assert.equal(monday.getHours(), 0);
  assert.equal(sunday.getDate(), 8);
  assert.equal(sunday.getHours(), 23);
  const next = KretaApi.weekRange(new Date(2026, 10, 8, 12, 0), 1); // Sunday, next week
  assert.equal(next.monday.getDate(), 9);
  const prev = KretaApi.weekRange(new Date(2026, 10, 2, 0, 0), -1);
  assert.equal(prev.monday.getDate(), 26);
  assert.equal(prev.monday.getMonth(), 9);
});

test("shiftLessons moves lesson times by whole days and keeps the rest", () => {
  const [l] = KretaApi.shiftLessons([{ Uid: "a", KezdetIdopont: "2026-11-02T08:00:00", VegIdopont: "2026-11-02T08:45:00" }], 7);
  assert.equal(new Date(l.KezdetIdopont).getDate(), 9);
  assert.equal(new Date(l.VegIdopont).getDate(), 9);
  assert.equal(l.Uid, "a");
});

test("runningAverages gives the weighted average after each grade", () => {
  const avgs = [...KretaApi.runningAverages([{ grade: 5, weight: 1 }, { grade: 2, weight: 2 }, { grade: 4, weight: 1 }])];
  assert.deepEqual(avgs.map((a) => Math.round(a * 100) / 100), [5, 3, 3.25]);
  assert.equal(KretaApi.runningAverages([]).length, 0);
});
