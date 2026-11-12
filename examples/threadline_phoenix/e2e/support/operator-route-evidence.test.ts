import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import test from "node:test";
import { execFileSync } from "node:child_process";

const root = resolve(import.meta.dirname, "../../../..");
const fixturePath = resolve(root, "test/fixtures/operator_surface/route-inventory.json");
const router = readFileSync(resolve(root, "lib/threadline/operator_surface/router.ex"), "utf8");
const routerPaths = [...router.matchAll(/live\("([^"]+)"/g)].map((m) => m[1]).sort();
const semanticInventoryPath = resolve(root, "examples/threadline_phoenix/e2e/support/operator-journey-inventory.json");
const semanticSourcePaths = [
  "lib/threadline/operator_surface/router.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
  "lib/threadline/operator_surface/live/start_live.ex",
  "lib/threadline/operator_surface/live/timeline_live.ex",
  "lib/threadline/operator_surface/live/transaction_live.ex",
  "lib/threadline/operator_surface/live/row_history_live.ex",
  "lib/threadline/operator_surface/live/row_history_component.ex",
  "examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts",
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex",
];
const semanticSources: Record<string, string> = Object.fromEntries(
  semanticSourcePaths.map((path) => [path, readFileSync(resolve(root, path), "utf8")]),
);
const investigationRouteIds = [
  "route.home",
  "route.timeline",
  "route.transaction",
  "route.drawer",
  "route.row",
];

type SemanticReference = { path?: string; locator?: string; kind?: string; owner?: string; limitation?: string };
type SemanticSurface = {
  id?: string;
  routeId?: string;
  job?: string;
  jobId?: string;
  journeyOrder?: number;
  renderer?: { module?: string; path?: string; locator?: string };
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
  access?: { authentication?: string; capability?: string; organizationScope?: string };
  actions?: string[];
  states?: string[];
  journey?: {
    id?: string;
    routeIds?: string[];
    identity?: { ticket?: string; actor?: string; correlation?: string; record?: { table?: string; key?: string } };
    returnContext?: { transactionHistory?: string; directRowHistory?: string };
  };
};

function semanticInventoryErrors(
  inventory: { surfaces?: SemanticSurface[] },
  fixture: { routes: Array<{ id: string; pattern: string }> },
  sources: Record<string, string>,
) {
  const surfaces = inventory.surfaces;
  if (!Array.isArray(surfaces)) return ["semantic surfaces collection"];

  const errors: string[] = [];
  const knownRouteIds = new Set(fixture.routes.map((route) => route.id));
  const routeIds = surfaces.map((surface) => surface.routeId ?? "");
  const mappedRouteIds = new Set(routeIds);
  const journeySurfaces = surfaces
    .filter((surface) => surface.jobId === "job.acme-4521-investigation")
    .sort((left, right) => (left.journeyOrder ?? -1) - (right.journeyOrder ?? -1));

  for (const routeId of investigationRouteIds) {
    if (!mappedRouteIds.has(routeId)) errors.push(`missing journey route ${routeId}`);
  }
  if (new Set(routeIds).size !== routeIds.length) errors.push("duplicate route identity");

  for (const surface of surfaces) {
    if (!surface.id || surface.id !== surface.routeId || !knownRouteIds.has(surface.routeId ?? "")) {
      errors.push(`invalid structural route identity ${surface.routeId ?? "<missing>"}`);
    }
    if (!surface.job?.trim() || !surface.jobId?.trim()) errors.push(`missing job for ${surface.routeId ?? "<missing>"}`);
    for (const [name, value] of Object.entries(surface.access ?? {})) {
      if (!value?.trim()) errors.push(`missing access.${name} for ${surface.routeId ?? "<missing>"}`);
    }
    if (!surface.actions?.length || !surface.states?.length) errors.push(`missing actions or states for ${surface.routeId ?? "<missing>"}`);

    const refs: SemanticReference[] = [surface.renderer ?? {}, ...(surface.sourceRefs ?? [])];
    if (!surface.renderer || !surface.sourceRefs?.length) errors.push(`missing source ownership for ${surface.routeId ?? "<missing>"}`);
    for (const ref of refs) {
      const source = ref.path ? sources[ref.path] : undefined;
      if (!source || !ref.locator || !source.includes(ref.locator)) {
        errors.push(`invalid source locator ${ref.path ?? "<missing>"}#${ref.locator ?? "<missing>"}`);
      }
    }

    if (!surface.proofRefs?.length) errors.push(`missing proof owner for ${surface.routeId ?? "<missing>"}`);
    for (const proof of surface.proofRefs ?? []) {
      const source = proof.path ? sources[proof.path] : undefined;
      if (!source || !proof.locator || !source.includes(proof.locator)) {
        errors.push(`invalid proof locator ${proof.path ?? "<missing>"}#${proof.locator ?? "<missing>"}`);
      }
      if (!proof.kind?.trim() || !proof.owner?.trim() || !proof.limitation?.trim()) {
        errors.push(`incomplete proof ownership for ${surface.routeId ?? "<missing>"}`);
      }
    }
  }

  if (journeySurfaces.length !== investigationRouteIds.length ||
      journeySurfaces.map((surface) => surface.routeId).some((routeId, index) => routeId !== investigationRouteIds[index])) {
    errors.push("Acme #4521 journey route order");
  }
  const homeJourney = journeySurfaces.find((surface) => surface.routeId === "route.home")?.journey;
  if (JSON.stringify(homeJourney?.routeIds) !== JSON.stringify(investigationRouteIds)) {
    errors.push("Acme #4521 journey links");
  }
  if (homeJourney?.id !== "job.acme-4521-investigation") errors.push("Acme #4521 journey identity");
  const identity = homeJourney?.identity;
  if (identity?.ticket !== "Acme #4521" || !identity.actor?.trim() ||
      identity.correlation !== "walk-acme-4521-close" || identity.record?.table !== "ticket_replies" ||
      !identity.record.key?.trim()) {
    errors.push("Acme #4521 actor, correlation, and record identity");
  }
  const returnContext = homeJourney?.returnContext;
  if (!returnContext?.transactionHistory?.trim() || !returnContext?.directRowHistory?.trim()) {
    errors.push("Acme #4521 return context");
  }

  const transaction = surfaces.find((surface) => surface.routeId === "route.transaction");
  const drawer = surfaces.find((surface) => surface.routeId === "route.drawer");
  if (transaction?.renderer?.module !== drawer?.renderer?.module || transaction?.id === drawer?.id) {
    errors.push("transaction and transaction-history route identities");
  }
  return errors;
}

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

test("Acme #4521 investigation links Home, Timeline, transaction, drawer, and direct row history", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));
  assert.deepEqual(semanticInventoryErrors(inventory, fixture, semanticSources), []);
});
