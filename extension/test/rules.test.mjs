// Runs the shared rule vectors in fixtures/rules/ against the extension. The
// Dart side runs the same files in test/rules_test.dart.
import { test } from "node:test";
import assert from "node:assert/strict";
import { loadKretaApi, loadFixture } from "./load_kreta_api.mjs";

const { KretaApi } = loadKretaApi();

for (const c of loadFixture("averages.json").cases) {
  test(`averages: ${c.name}`, () => {
    const actual = KretaApi.subjectAverages(c.grades);
    assert.deepEqual(Object.keys(actual).sort(), Object.keys(c.subjectAverages).sort());
    for (const [subject, expected] of Object.entries(c.subjectAverages)) {
      assert.ok(Math.abs(actual[subject] - expected) < 1e-9, `${subject}: ${actual[subject]} != ${expected}`);
    }
    const overall = KretaApi.overallAverage(c.grades);
    if (c.overall === null) assert.equal(overall, null);
    else assert.ok(Math.abs(overall - c.overall) < 1e-9, `overall: ${overall} != ${c.overall}`);
  });
}

for (const c of loadFixture("absences.json").cases) {
  test(`absences: ${c.name}`, () => {
    assert.deepEqual({ ...KretaApi.summarizeAbsences(c.absences) }, c.summary);
  });
}
