import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";

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
