import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import { execFileSync } from "node:child_process";

const root = resolve(import.meta.dirname, "../../../..");
const fixturePath = resolve(root, "test/fixtures/operator_surface/route-inventory.json");
const router = readFileSync(resolve(root, "lib/threadline/operator_surface/router.ex"), "utf8");
const routerPaths = [...router.matchAll(/live\("([^"]+)"/g)].map((m) => m[1]).sort();

test("route inventory exactly matches the independently read eleven router paths", () => {
  const fixture = existsSync(fixturePath) ? JSON.parse(readFileSync(fixturePath, "utf8")) : { routes: [] };
  assert.equal(routerPaths.length, 11);
  assert.deepEqual(fixture.routes.map((r: { pattern: string }) => r.pattern).sort(), routerPaths);
  assert.equal(new Set(fixture.routes.map((r: { id: string }) => r.id)).size, 11);
  for (const route of fixture.routes) {
    assert.ok(route.seedResolution && route.role && route.scope);
  }
});

test("System runner preserves an explicit project selector without adding its default", () => {
  const output = execFileSync("bash", [resolve(root, "examples/threadline_phoenix/e2e/run-e2e.sh"), "--project=route-capture", "operator-route-states.spec.ts"], { cwd: root, encoding: "utf8", env: { ...process.env, THREADLINE_E2E_EVIDENCE: "0", THREADLINE_E2E_THEME: "system", THREADLINE_E2E_ARGUMENTS_ONLY: "1" } });
  assert.equal(output.trim(), "npm test -- --project=route-capture operator-route-states.spec.ts");
});

for (const shell of [...new Set(["bash", ...(existsSync("/bin/bash") ? ["/bin/bash"] : [])])]) {
  test(`${shell} forwards zero arguments and dark arguments without phantom empty values`, () => {
    const run = (args: string[]) => execFileSync(shell, [resolve(root, "examples/threadline_phoenix/e2e/run-e2e.sh"), ...args], {cwd:root, encoding:"utf8", env:{...process.env, THREADLINE_E2E_EVIDENCE:"0", THREADLINE_E2E_THEME:"dark", THREADLINE_E2E_ARGUMENTS_ONLY:"1"}}).trim();
    assert.equal(run([]), "npm test --");
    assert.equal(run(["operator-page-capture.spec.ts", "--grep", "home route"]), "npm test -- operator-page-capture.spec.ts --grep home\\ route");
  });
}
