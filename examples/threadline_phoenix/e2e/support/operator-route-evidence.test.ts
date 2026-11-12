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
  "lib/threadline/operator_surface/live/actor_live.ex",
  "lib/threadline/operator_surface/live/coverage_live.ex",
  "lib/threadline/operator_surface/live/evidence_live.ex",
  "lib/threadline/operator_surface/live/export_status_live.ex",
  "lib/threadline/operator_surface/live/policy_redaction_live.ex",
  "lib/threadline/operator_surface/live/retention_history_live.ex",
  "lib/threadline/operator_surface/controllers/theme_controller.ex",
  "lib/threadline/operator_surface/controllers/export_controller.ex",
  "lib/threadline/operator_surface/fonts.ex",
  "lib/threadline/operator_surface/components/logo.ex",
  "lib/threadline/operator_surface/components/surface_header.ex",
  "examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-transaction-evidence.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-features.spec.ts",
  "examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts",
  "test/fixtures/operator_surface/route-inventory.json",
  "examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs",
  "test/threadline/operator_surface/controllers/export_controller_test.exs",
  "brand/BRAND.md",
  "brand/brand.json",
  "brand/assets/README.md",
  "examples/threadline_phoenix/mix.exs",
  "examples/threadline_phoenix/config/dev.exs",
  "examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_controller.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/help_desk_dev_controller.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex",
  "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs",
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
const scenarioStateCriteria = ["empty", "loading", "error_unavailable", "populated", "partial", "overflow_boundary", "zero_one_many", "long_text_unicode_duplicate_label"];

type SemanticReference = { id?: string; path?: string; locator?: string; kind?: string; owner?: string; limitation?: string };
type SemanticCoverage = {
  disposition?: string;
  description?: string;
  reason?: string;
  sourceRefIds?: string[];
  proofRefIds?: string[];
};
type SemanticSurface = {
  id?: string;
  routeId?: string;
  routePattern?: string;
  http?: { method?: string; path?: string };
  surfaceType?: string;
  job?: string;
  jobId?: string;
  journeyOrder?: number;
  renderer?: { module?: string; path?: string; locator?: string; noPageRendererReason?: string };
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
  access?: { authentication?: string; capability?: string; organizationScope?: string; supportDisposition?: string };
  actions?: string[];
  states?: string[];
  uiCoverage?: Record<string, SemanticCoverage>;
  journey?: {
    id?: string;
    routeIds?: string[];
    identity?: { ticket?: string; actor?: string; correlation?: string; record?: { table?: string; key?: string } };
    returnContext?: { transactionHistory?: string; directRowHistory?: string };
  };
};
type SemanticResource = {
  id?: string;
  kind?: string;
  disposition?: string;
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
};
type SemanticInventory = {
  surfaces?: SemanticSurface[];
  resourceDispositions?: SemanticResource[];
  scenarios?: Array<{
    id?: string;
    class?: string;
    selection?: { resetCommand?: string; correlation?: string; routeIds?: string[] };
    identity?: { organization?: { slug?: string }; actor?: { email?: string }; ticket?: { number?: number }; correlation?: string; record?: { table?: string; key?: string }; action?: string };
    clocks?: { eventTime?: string; recordedTime?: string };
    fixtureRefs?: SemanticReference[];
    sourceRefs?: SemanticReference[];
    proofRefs?: SemanticReference[];
    stateCriteria?: Record<string, SemanticCoverage & { status?: string; meaning?: string; sourceRefIds?: string[]; proofRefIds?: string[] }>;
  }>;
};
const uiCriteria = ["empty", "loading", "error", "populated", "partial", "overflow", "zero-one-many", "long-text"];
const expectedSupportDisposition: Record<string, string> = {
  "route.home": "read_only_scoped",
  "route.timeline": "read_only_scoped",
  "route.transaction": "read_only_scoped",
  "route.drawer": "read_only_scoped",
  "route.row": "read_only_scoped",
  "route.actor": "read_only_scoped",
  "route.coverage": "unavailable",
  "route.evidence": "unavailable",
  "route.exports": "unavailable",
  "route.redaction": "unavailable",
  "route.retention": "unavailable",
  "seam.theme": "host_policy",
  "seam.exports.changes-csv": "admin_only",
  "seam.exports.changes-json": "admin_only",
  "seam.exports.changes-ndjson": "admin_only",
  "seam.exports.download-job_id": "admin_only",
};

function semanticInventoryErrors(
  inventory: SemanticInventory,
  fixture: { routes: Array<{ id: string; pattern: string }>; extraStates?: Array<{ id: string; routeId: string; state: string }>; items: Array<{ id: string; kind: string; label: string }> },
  sources: Record<string, string>,
) {
  const surfaces = inventory.surfaces;
  if (!Array.isArray(surfaces)) return ["semantic surfaces collection"];

  const errors: string[] = [];
  const structuralIds = [
    ...fixture.routes.map((route) => route.id),
    ...fixture.items.filter((item) => item.kind === "seam").map((item) => item.id),
  ];
  const expectedIds = new Set(structuralIds);
  if (expectedIds.size !== structuralIds.length) errors.push("duplicate structural declaration identity");
  const routePatterns = new Map(fixture.routes.map((route) => [route.id, route.pattern]));
  const seamLabels = new Map(fixture.items.filter((item) => item.kind === "seam").map((item) => [item.id, item.label]));
  const knownRouteIds = expectedIds;
  const routeIds = surfaces.map((surface) => surface.routeId ?? "");
  const mappedRouteIds = new Set(routeIds);
  const journeySurfaces = surfaces
    .filter((surface) => surface.jobId === "job.acme-4521-investigation")
    .sort((left, right) => (left.journeyOrder ?? -1) - (right.journeyOrder ?? -1));

  for (const routeId of investigationRouteIds) {
    if (!mappedRouteIds.has(routeId)) errors.push(`missing journey route ${routeId}`);
  }
  if (new Set(routeIds).size !== routeIds.length) errors.push("duplicate route identity");
  for (const routeId of expectedIds) {
    if (!mappedRouteIds.has(routeId)) errors.push(`missing structural identity ${routeId}`);
  }
  for (const routeId of mappedRouteIds) {
    if (!expectedIds.has(routeId)) errors.push(`unknown structural identity ${routeId}`);
  }

  for (const surface of surfaces) {
    if (!surface.id || surface.id !== surface.routeId || !knownRouteIds.has(surface.routeId ?? "")) {
      errors.push(`invalid structural route identity ${surface.routeId ?? "<missing>"}`);
    }
    if (!surface.job?.trim() || !surface.jobId?.trim()) errors.push(`missing job for ${surface.routeId ?? "<missing>"}`);
    if (!surface.surfaceType || !["liveview", "http"].includes(surface.surfaceType)) {
      errors.push(`missing surface type for ${surface.routeId ?? "<missing>"}`);
    }
    if (surface.surfaceType === "liveview" && surface.routePattern !== routePatterns.get(surface.routeId ?? "")) {
      errors.push(`route pattern mismatch for ${surface.routeId ?? "<missing>"}`);
    }
    if (surface.surfaceType === "http") {
      const label = seamLabels.get(surface.routeId ?? "");
      if (!surface.http?.method || !surface.http.path || `${surface.http.method} ${surface.http.path}` !== label) {
        errors.push(`HTTP declaration mismatch for ${surface.routeId ?? "<missing>"}`);
      }
    }
    if (!surface.actions?.length || !surface.states?.length) errors.push(`missing actions or states for ${surface.routeId ?? "<missing>"}`);
    if (surface.actions?.some((action) => !action.trim()) || surface.states?.some((state) => !state.trim())) {
      errors.push(`empty action or state for ${surface.routeId ?? "<missing>"}`);
    }

    const sourceRefs = surface.sourceRefs ?? [];
    const proofRefs = surface.proofRefs ?? [];
    const sourceIds = new Set(sourceRefs.map((ref) => ref.id ?? ""));
    const proofIds = new Set(proofRefs.map((ref) => ref.id ?? ""));
    if (sourceIds.size !== sourceRefs.length || sourceIds.has("")) {
      errors.push(`duplicate or missing source reference id for ${surface.routeId ?? "<missing>"}`);
    }
    if (proofIds.size !== proofRefs.length || proofIds.has("")) {
      errors.push(`duplicate or missing proof reference id for ${surface.routeId ?? "<missing>"}`);
    }
    if (!surface.renderer?.module || !surface.renderer.path || !surface.renderer.locator || !sourceRefs.length) {
      errors.push(`missing source ownership for ${surface.routeId ?? "<missing>"}`);
    }
    if (surface.surfaceType === "http" && !surface.renderer?.noPageRendererReason?.trim()) {
      errors.push(`missing no-page-renderer reason for ${surface.routeId ?? "<missing>"}`);
    }

    for (const ref of [surface.renderer ?? {}, ...sourceRefs]) {
      const source = ref.path ? sources[ref.path] : undefined;
      if (!source || !ref.locator || !source.includes(ref.locator)) {
        errors.push(`invalid source locator ${ref.path ?? "<missing>"}#${ref.locator ?? "<missing>"}`);
      }
    }

    if (!proofRefs.length) errors.push(`missing proof owner for ${surface.routeId ?? "<missing>"}`);
    for (const proof of proofRefs) {
      const source = proof.path ? sources[proof.path] : undefined;
      if (!source || !proof.locator || !source.includes(proof.locator)) {
        errors.push(`invalid proof locator ${proof.path ?? "<missing>"}#${proof.locator ?? "<missing>"}`);
      }
      if (!proof.kind?.toLowerCase().includes("owner") || !proof.owner?.trim() || !proof.limitation?.trim()) {
        errors.push(`incomplete proof ownership for ${surface.routeId ?? "<missing>"}`);
      }
    }

    for (const name of ["authentication", "capability", "organizationScope"] as const) {
      if (!surface.access?.[name]?.trim()) errors.push(`missing access.${name} for ${surface.routeId ?? "<missing>"}`);
    }
    if (surface.access?.supportDisposition !== expectedSupportDisposition[surface.routeId ?? ""]) {
      errors.push(`unexpected support disposition for ${surface.routeId ?? "<missing>"}`);
    }

    const coverage = surface.uiCoverage ?? {};
    if (uiCriteria.some((criterion) => !coverage[criterion])) {
      errors.push(`missing U1 state coverage for ${surface.routeId ?? "<missing>"}`);
    }
    if (Object.keys(coverage).some((criterion) => !uiCriteria.includes(criterion))) {
      errors.push(`unknown U1 state coverage for ${surface.routeId ?? "<missing>"}`);
    }
    for (const [criterion, entry] of Object.entries(coverage)) {
      const refsExist = (ids: string[] | undefined, known: Set<string>) =>
        Array.isArray(ids) && ids.length > 0 && ids.every((id) => known.has(id));
      if (entry.disposition === "mapped") {
        if (!entry.description?.trim() || !refsExist(entry.sourceRefIds, sourceIds) || !refsExist(entry.proofRefIds, proofIds)) {
          errors.push(`unproven ${criterion} state coverage for ${surface.routeId ?? "<missing>"}`);
        }
      } else if (entry.disposition === "not_applicable") {
        if (!entry.reason?.trim() || !refsExist(entry.sourceRefIds, sourceIds)) {
          errors.push(`unexplained ${criterion} state coverage for ${surface.routeId ?? "<missing>"}`);
        }
      } else {
        errors.push(`invalid ${criterion} state coverage disposition for ${surface.routeId ?? "<missing>"}`);
      }
    }
  }

  for (const extra of fixture.extraStates ?? []) {
    const surface = surfaces.find((candidate) => candidate.routeId === extra.routeId);
    if (!surface?.states?.some((state) => state.toLowerCase().includes(extra.state.toLowerCase()))) {
      errors.push(`missing structural state ${extra.id}`);
    }
  }

  const resourceDispositions = inventory.resourceDispositions ?? [];
  const requiredResources = ["resource.shared-assets", "resource.embedded-fonts", "resource.storybook", "resource.help-desk-writes", "resource.mailbox-preview"];
  const resourceIds = resourceDispositions.map((resource) => resource.id ?? "");
  if (new Set(resourceIds).size !== resourceIds.length) errors.push("duplicate resource disposition identity");
  if (resourceIds.some((id) => !requiredResources.includes(id))) errors.push("unknown resource disposition identity");
  for (const required of requiredResources) {
    if (!resourceIds.includes(required)) errors.push(`missing resource disposition ${required}`);
  }
  for (const resource of resourceDispositions) {
    if (!resource.id || !resource.disposition?.trim() || !resource.kind?.trim() || !resource.sourceRefs?.length) {
      errors.push(`incomplete resource disposition ${resource.id ?? "<missing>"}`);
    }
    for (const ref of resource.sourceRefs ?? []) {
      const source = ref.path ? sources[ref.path] : undefined;
      if (!source || !ref.locator || !source.includes(ref.locator)) {
        errors.push(`invalid resource locator ${ref.path ?? "<missing>"}#${ref.locator ?? "<missing>"}`);
      }
    }
    for (const proof of resource.proofRefs ?? []) {
      const source = proof.path ? sources[proof.path] : undefined;
      if (!source || !proof.locator || !source.includes(proof.locator)) {
        errors.push(`invalid resource proof locator ${proof.path ?? "<missing>"}#${proof.locator ?? "<missing>"}`);
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

  const scenarios = inventory.scenarios;
  if (!Array.isArray(scenarios)) return [...errors, "semantic scenarios collection"];
  const scenarioIds = scenarios.map((scenario) => scenario.id ?? "");
  if (new Set(scenarioIds).size !== scenarioIds.length) errors.push("duplicate scenario identity");
  const scenario = scenarios.find((candidate) => candidate.id === "scenario.acme-4521-investigation");
  if (!scenario) {
    errors.push("missing ordinary scenario scenario.acme-4521-investigation");
  } else {
    if (scenario.class !== "ordinary") errors.push("Acme #4521 must remain ordinary selection data");
    if (scenario.selection?.resetCommand !== "mix demo.reset" || scenario.selection?.correlation !== "walk-acme-4521-close") {
      errors.push("Acme #4521 clean reset and correlation selection");
    }
    if (JSON.stringify(scenario.selection?.routeIds) !== JSON.stringify(investigationRouteIds)) {
      errors.push("Acme #4521 selected route chain");
    }
    if (scenario.identity?.organization?.slug !== "acme" || scenario.identity?.actor?.email !== "closer@acme.example.com" ||
        scenario.identity?.ticket?.number !== 4521 || scenario.identity?.correlation !== "walk-acme-4521-close" ||
        scenario.identity?.record?.table !== "ticket_replies" || !scenario.identity?.record?.key?.includes("resolved from the seeded ticket_replies change at runtime") ||
        scenario.identity?.action !== "ticket_replied_and_closed") {
      errors.push("Acme #4521 stable organization, actor, ticket, correlation, record, and action identities");
    }
    if (!scenario.clocks?.eventTime?.includes("2026-05-26T14:30:00Z") || !scenario.clocks.recordedTime?.includes("AuditAction.inserted_at")) {
      errors.push("Acme #4521 event and physical recording clocks");
    }
    const scenarioSources = scenario.sourceRefs ?? [];
    const scenarioFixtures = scenario.fixtureRefs ?? [];
    const scenarioProofs = scenario.proofRefs ?? [];
    const sourceIds = new Set(scenarioSources.map((ref) => ref.id ?? ""));
    const fixtureIds = new Set(scenarioFixtures.map((ref) => ref.id ?? ""));
    const proofIds = new Set(scenarioProofs.map((ref) => ref.id ?? ""));
    if (!scenarioSources.length || !scenarioFixtures.length || !scenarioProofs.length ||
        sourceIds.size !== scenarioSources.length || fixtureIds.size !== scenarioFixtures.length || proofIds.size !== scenarioProofs.length) {
      errors.push("Acme #4521 source, fixture, and proof ownership is missing or duplicated");
    }
    for (const ref of [...scenarioSources, ...scenarioFixtures, ...scenarioProofs]) {
      const unsafePath = !ref.path || ref.path.startsWith("/") || ref.path.split(/[\\/]/).includes("..");
      const source = ref.path ? sources[ref.path] : undefined;
      if (unsafePath || !source || !ref.locator || !source.includes(ref.locator)) {
        errors.push(`invalid scenario reference ${ref.path ?? "<missing>"}#${ref.locator ?? "<missing>"}`);
      }
    }
    for (const proof of scenarioProofs) {
      if (!proof.kind?.toLowerCase().includes("owner") || !proof.owner?.trim() || !proof.limitation?.trim()) {
        errors.push("incomplete Acme #4521 proof owner or limitation");
      }
    }
    if (scenarioFixtures.some((ref) => ref.path?.includes("stress_fixtures") || ref.path?.includes("storybook/fixtures"))) {
      errors.push("ordinary #4521 scenario substituted a stress fixture");
    }
    if (!scenarioProofs.some((proof) => proof.path?.endsWith("operator-earned-flows.spec.ts") && proof.locator?.includes("Home record lookup reaches first-class row history"))) {
      errors.push("Acme #4521 return-context proof owner");
    }
    const criteria = scenario.stateCriteria ?? {};
    if (scenarioStateCriteria.some((criterion) => !criteria[criterion]) || Object.keys(criteria).some((criterion) => !scenarioStateCriteria.includes(criterion))) {
      errors.push("Acme #4521 U2 state criteria coverage");
    }
    for (const [criterion, entry] of Object.entries(criteria)) {
      const refsExist = (ids: string[] | undefined, known: Set<string>) => Array.isArray(ids) && ids.length > 0 && ids.every((id) => known.has(id));
      if (entry.status === "mapped") {
        if (!entry.meaning?.trim() || !refsExist(entry.sourceRefIds, sourceIds) || !refsExist(entry.proofRefIds, proofIds)) {
          errors.push(`unproven Acme #4521 ${criterion} state`);
        }
      } else if (entry.status === "not_applicable") {
        if (!entry.reason?.trim() || !refsExist(entry.sourceRefIds, sourceIds) || !refsExist(entry.proofRefIds, proofIds)) {
          errors.push(`unexplained Acme #4521 ${criterion} state`);
        }
      } else {
        errors.push(`invalid Acme #4521 ${criterion} state disposition`);
      }
    }
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

  const missingDrawer = structuredClone(inventory);
  missingDrawer.surfaces = missingDrawer.surfaces.filter((surface: SemanticSurface) => surface.routeId !== "route.drawer");
  assert.ok(semanticInventoryErrors(missingDrawer, fixture, semanticSources).includes("missing journey route route.drawer"));

  const absentSource = structuredClone(inventory);
  absentSource.surfaces[0].sourceRefs[0].locator = "live(\"/missing\", MissingLive, :show)";
  assert.ok(semanticInventoryErrors(absentSource, fixture, semanticSources).some((error) => error.startsWith("invalid source locator")));

  const absentProof = structuredClone(inventory);
  absentProof.surfaces[0].proofRefs[0].locator = "test(\"missing proof owner\")";
  assert.ok(semanticInventoryErrors(absentProof, fixture, semanticSources).some((error) => error.startsWith("invalid proof locator")));
});

test("ordinary #4521 selection resolves the corrected seed through one maintainer recipe", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const scenario = inventory.scenarios?.find((candidate: { id?: string }) => candidate.id === "scenario.acme-4521-investigation");
  assert.ok(scenario, "expected the ordinary #4521 investigation scenario in the semantic inventory");
  assert.equal(scenario.class, "ordinary");
  assert.equal(scenario.identity.organization.slug, "acme");
  assert.equal(scenario.identity.actor.email, "closer@acme.example.com");
  assert.equal(scenario.identity.ticket.number, 4521);
  assert.equal(scenario.identity.correlation, "walk-acme-4521-close");
  assert.equal(scenario.identity.record.table, "ticket_replies");
  assert.match(scenario.identity.record.key, /resolved from the seeded ticket_replies change at runtime/i);
  assert.match(scenario.clocks.eventTime, /2026-05-26T14:30:00Z/);
  assert.match(scenario.clocks.recordedTime, /AuditAction\.inserted_at/);
  assert.equal(scenario.selection.resetCommand, "mix demo.reset");
  assert.ok(scenario.proofRefs.some((proof: { path?: string }) => proof.path?.endsWith("demo_contract_test.exs")));

  const recipe = readFileSync(resolve(root, "examples/threadline_phoenix/DEMO-MANIFEST.md"), "utf8");
  assert.match(recipe, /scenario\.acme-4521-investigation/);
  assert.match(recipe, /record_id resolved from the seeded ticket_replies change at runtime/i);
  assert.match(recipe, /do not use stress fixtures as ordinary scenario data/i);
});

test("ordinary scenario mapping rejects missing source, proof, return, and ordinary classification links", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));

  const missingSource = structuredClone(inventory);
  missingSource.scenarios[0].sourceRefs = [];
  assert.ok(semanticInventoryErrors(missingSource, fixture, semanticSources).some((error) => error.includes("source, fixture, and proof ownership")));

  const missingProof = structuredClone(inventory);
  missingProof.scenarios[0].proofRefs = [];
  assert.ok(semanticInventoryErrors(missingProof, fixture, semanticSources).some((error) => error.includes("source, fixture, and proof ownership")));

  const missingReturn = structuredClone(inventory);
  missingReturn.scenarios[0].proofRefs = missingReturn.scenarios[0].proofRefs.filter((proof: SemanticReference) => !proof.locator?.includes("Home record lookup reaches first-class row history"));
  assert.ok(semanticInventoryErrors(missingReturn, fixture, semanticSources).includes("Acme #4521 return-context proof owner"));

  const stressSubstitution = structuredClone(inventory);
  stressSubstitution.scenarios[0].class = "stress";
  assert.ok(semanticInventoryErrors(stressSubstitution, fixture, semanticSources).includes("Acme #4521 must remain ordinary selection data"));
});

test("all independently declared operator routes and HTTP seams have semantic identities", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));
  const liveIds = fixture.routes.map((route: { id: string }) => route.id);
  const declaredHttp = [
    ...[...router.matchAll(/\bpost\("(\/theme)"/g)].map((match) => `POST ${match[1]}`),
    ...[...router.matchAll(/\bget\("(\/(?:changes\.(?:csv|json|ndjson)|download\/:job_id))"/g)].map((match) => `GET ${match[1]}`),
  ].sort();
  const fixtureHttp = fixture.items
    .filter((item: { kind: string }) => item.kind === "seam")
    .map((item: { label: string }) => item.label)
    .sort();
  assert.deepEqual(fixtureHttp, declaredHttp);

  const expectedIds = [
    ...liveIds,
    ...fixture.items.filter((item: { kind: string }) => item.kind === "seam").map((item: { id: string }) => item.id),
  ].sort();
  assert.equal(expectedIds.length, 16);
  assert.deepEqual(inventory.surfaces.map((surface: { id: string }) => surface.id).sort(), expectedIds);
  assert.deepEqual(
    inventory.surfaces.filter((surface: SemanticSurface) => surface.surfaceType === "http")
      .map((surface: SemanticSurface) => `${surface.http?.method} ${surface.http?.path}`).sort(),
    declaredHttp,
  );
});

test("semantic identities and source ownership survive reordered declarations; malformed mappings fail", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));
  const reorderedInventory = structuredClone(inventory);
  const reorderedFixture = structuredClone(fixture);
  reorderedInventory.surfaces.reverse();
  reorderedFixture.routes.reverse();
  reorderedFixture.items.reverse();
  assert.deepEqual(semanticInventoryErrors(reorderedInventory, reorderedFixture, semanticSources), []);

  const duplicate = structuredClone(inventory);
  duplicate.surfaces.push(structuredClone(duplicate.surfaces[0]));
  assert.ok(semanticInventoryErrors(duplicate, fixture, semanticSources).includes("duplicate route identity"));

  const missing = structuredClone(inventory);
  missing.surfaces = missing.surfaces.filter((surface: SemanticSurface) => surface.routeId !== "route.actor");
  assert.ok(semanticInventoryErrors(missing, fixture, semanticSources).includes("missing structural identity route.actor"));

  const invalidRenderer = structuredClone(inventory);
  invalidRenderer.surfaces[0].renderer.locator = "defmodule Missing.Renderer";
  assert.ok(semanticInventoryErrors(invalidRenderer, fixture, semanticSources).some((error) => error.startsWith("invalid source locator")));

  const wrongAccess = structuredClone(inventory);
  wrongAccess.surfaces.find((surface: SemanticSurface) => surface.routeId === "route.actor").access.supportDisposition = "admin_only";
  assert.ok(semanticInventoryErrors(wrongAccess, fixture, semanticSources).includes("unexpected support disposition for route.actor"));

  const missingU1 = structuredClone(inventory);
  delete missingU1.surfaces[0].uiCoverage.populated;
  assert.ok(semanticInventoryErrors(missingU1, fixture, semanticSources).includes("missing U1 state coverage for route.home"));

  const missingResourceOwner = structuredClone(inventory);
  missingResourceOwner.resourceDispositions[0].sourceRefs[0].locator = "missing brand asset owner";
  assert.ok(semanticInventoryErrors(missingResourceOwner, fixture, semanticSources).some((error) => error.startsWith("invalid resource locator")));
});
