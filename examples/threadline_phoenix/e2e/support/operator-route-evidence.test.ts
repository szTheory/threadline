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
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_runs.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex",
  "examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex",
  "examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs",
  "examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs",
  "examples/threadline_phoenix/e2e/support/operator-journey-inventory.json",
  "lib/threadline/operator_surface/stress_fixtures.ex",
  "lib/threadline/operator_surface/presentation.ex",
  "lib/threadline/operator_surface/style/01_tokens.css",
  "lib/threadline/retention.ex",
  "test/threadline/brandbook_token_parity_test.exs",
  "test/threadline/operator_surface/presentation_test.exs",
  "test/threadline/operator_surface/surface_header_test.exs",
  ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md",
  ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-RESEARCH.md",
  ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-SUMMARY.md",
  ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-03-SUMMARY.md",
  ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-PROBE-RECORD.md",
  ".planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-04-PLAN.md",
  ".planning/research/v1.48-SUMMARY.md",
  "examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts",
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
const scenarioStateCriteria = ["empty", "loading", "error", "populated", "partial", "overflow", "zero-one-many", "long-text"];
const criteriaForScenario = scenarioStateCriteria;

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
type ScenarioState = {
  status?: string;
  meaning?: string;
  reason?: string;
  sourceRefIds?: string[];
  proofRefIds?: string[];
};
type SemanticScenario = {
  id?: string;
  name?: string;
  class?: string;
  jobId?: string;
  selection?: { resetCommand?: string; correlation?: string; routeIds?: string[]; [key: string]: unknown };
  identity?: {
    organization?: { slug?: string };
    actor?: { email?: string };
    ticket?: { number?: number };
    correlation?: string;
    record?: { table?: string; key?: string };
    action?: string;
    [key: string]: unknown;
  };
  clocks?: { eventTime?: string; recordedTime?: string; [key: string]: unknown };
  duplicateLabelExamples?: Array<{ label?: string; identity?: string }>;
  fixtureRefs?: SemanticReference[];
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
  stateCriteria?: Record<string, ScenarioState>;
};
type BrandRole = {
  roleId?: string;
  consumer?: string;
  job?: string;
  currentStatus?: string;
  laterOwner?: string;
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
  assetPaths?: string[];
  consumerRefs?: string[];
  jobIds?: string[];
  proofGap?: string;
  u3Criteria?: Record<string, ScenarioState>;
};
type BrandContract = {
  id?: string;
  topic?: string;
  consumerJobs?: string[];
  laterOwners?: string[];
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
};
type BrandAssetFamily = {
  id?: string;
  paths?: string[];
  sourceRefs?: SemanticReference[];
};
type CarryDisposition = {
  id?: string;
  status?: string;
  disposition?: string;
  laterOwners?: string[];
  sourceRefs?: SemanticReference[];
  proofRefs?: SemanticReference[];
  proofGap?: string;
};
type SemanticInventory = {
  surfaces?: SemanticSurface[];
  resourceDispositions?: SemanticResource[];
  scenarios?: SemanticScenario[];
  brandReferences?: { contracts?: BrandContract[]; assetFamilies?: BrandAssetFamily[]; roles?: BrandRole[] };
  carryDispositions?: CarryDisposition[];
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
  const sourcesForInventory = sources;
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

  const requiredScenarioIds = [
    "scenario.acme-4521-investigation",
    "scenario.acme-4518-reply-close-delete",
    "scenario.globex-2001-ordinary-close",
    "scenario.offboarded-co-retention-boundary",
    "scenario.state-empty",
    "scenario.state-export-failed",
    "scenario.state-permission-denied",
    "scenario.state-pagination-boundary",
    "scenario.state-long-content",
    "scenario.state-unicode",
    "scenario.state-duplicate-labels",
  ];
  for (const requiredId of requiredScenarioIds) {
    if (!scenarioIds.includes(requiredId)) errors.push(`missing named scenario ${requiredId}`);
  }
  if (scenarioIds.some((id) => !requiredScenarioIds.includes(id))) errors.push("unknown named scenario");

  for (const candidate of scenarios) {
    const sources = candidate.sourceRefs ?? [];
    const fixtures = candidate.fixtureRefs ?? [];
    const proofs = candidate.proofRefs ?? [];
    const sourceIds = new Set(sources.map((ref) => ref.id ?? ""));
    const proofIds = new Set(proofs.map((ref) => ref.id ?? ""));
    if (!candidate.name?.trim() || !candidate.jobId?.trim() || !candidate.selection ||
        (!candidate.selection.resetCommand && !candidate.selection.catalog) ||
        !candidate.identity || !candidate.clocks || !sources.length || !fixtures.length || !proofs.length) {
      errors.push(`incomplete named scenario ${candidate.id ?? "<missing>"}`);
    }
    if (sourceIds.size !== sources.length || sourceIds.has("") || proofIds.size !== proofs.length || proofIds.has("")) {
      errors.push(`duplicate or missing scenario references for ${candidate.id ?? "<missing>"}`);
    }
    for (const reference of [...sources, ...fixtures, ...proofs]) {
      const unsafePath = !reference.path || reference.path.startsWith("/") || reference.path.split(/[\\/]/).includes("..");
      const source = reference.path ? sourcesForInventory[reference.path] : undefined;
      if (unsafePath || !source || !reference.locator || !source.includes(reference.locator)) {
        errors.push(`invalid named scenario reference ${reference.path ?? "<missing>"}#${reference.locator ?? "<missing>"}`);
      }
    }
    for (const proof of proofs) {
      if (!proof.kind?.includes("owner") || !proof.owner?.trim() || !proof.limitation?.trim() ||
          proof.owner !== proof.path?.split("/").at(-1)) {
        errors.push(`wrong or incomplete scenario proof owner for ${candidate.id ?? "<missing>"}`);
      }
    }
    const stateCriteria = candidate.stateCriteria ?? {};
    if (criteriaForScenario.some((criterion) => !stateCriteria[criterion]) ||
        Object.keys(stateCriteria).some((criterion) => !criteriaForScenario.includes(criterion))) {
      errors.push(`missing U2 criteria for ${candidate.id ?? "<missing>"}`);
    }
    for (const [criterion, state] of Object.entries(stateCriteria)) {
      const hasKnownRefs = (ids: string[] | undefined, known: Set<string>) =>
        Array.isArray(ids) && ids.length > 0 && ids.every((id) => known.has(id));
      if (state.status === "mapped") {
        if (!state.meaning?.trim() || !hasKnownRefs(state.sourceRefIds, sourceIds) || !hasKnownRefs(state.proofRefIds, proofIds)) {
          errors.push(`unproven U2 ${criterion} for ${candidate.id ?? "<missing>"}`);
        }
      } else if (state.status === "not_applicable") {
        if (!state.reason?.trim() || !hasKnownRefs(state.sourceRefIds, sourceIds) || !hasKnownRefs(state.proofRefIds, proofIds)) {
          errors.push(`unexplained U2 ${criterion} for ${candidate.id ?? "<missing>"}`);
        }
      } else {
        errors.push(`invalid U2 ${criterion} disposition for ${candidate.id ?? "<missing>"}`);
      }
    }
    if (candidate.class === "ordinary" && sources.some((ref) => ref.path?.includes("stress_fixtures") || ref.path?.includes("storybook/fixtures"))) {
      errors.push(`ordinary scenario uses stress data ${candidate.id ?? "<missing>"}`);
    }
    if (candidate.id === "scenario.state-duplicate-labels") {
      const examples = candidate.duplicateLabelExamples ?? [];
      if (examples.length < 2 || new Set(examples.map((example) => example.label)).size !== 1 ||
          new Set(examples.map((example) => example.identity)).size !== examples.length) {
        errors.push("duplicate-label fixture identities are not distinct");
      }
    }
  }

  const brand = inventory.brandReferences;
  const requiredRoleIds = ["body", "descriptor", "caption", "application-copy", "hero", "link", "focus", "artwork"];
  const requiredAssetFamilies = [
    "assets.light-lockups-and-marks",
    "assets.dark-lockups-and-marks",
    "assets.favicon-variants",
    "assets.supplied-web-fonts-and-licenses",
  ];
  const requiredBrandContracts = [
    "brand-contract.identity-language",
    "brand-contract.operation-value-truth",
    "brand-contract.dark-light-system",
  ];
  if (!brand) return [...errors, "brand crosswalk"];
  const brandRoles = brand.roles ?? [];
  const roleIds = brandRoles.map((role) => role.roleId ?? "");
  if (new Set(roleIds).size !== roleIds.length) errors.push("duplicate brand role identity");
  for (const roleId of requiredRoleIds) {
    if (!roleIds.includes(roleId)) errors.push(`missing approved brand role ${roleId}`);
  }
  for (const role of brandRoles) {
    const sourceRefs = role.sourceRefs ?? [];
    const proofRefs = role.proofRefs ?? [];
    const sourceIds = new Set(sourceRefs.map((ref) => ref.id ?? ""));
    const proofIds = new Set(proofRefs.map((ref) => ref.id ?? ""));
    if (!role.consumer?.trim() || !role.job?.trim() || !role.laterOwner?.trim() || !role.proofGap?.trim() ||
        !role.currentStatus?.toLowerCase().includes("reference-only") || !sourceRefs.length || !proofRefs.length ||
        !role.consumerRefs?.length || !role.jobIds?.length) {
      errors.push(`missing brand role consumer, proof, or later owner ${role.roleId ?? "<missing>"}`);
    }
    const sourcePaths = new Set(sourceRefs.map((ref) => ref.path ?? ""));
    const knownJobIds = new Set(surfaces.map((surface) => surface.jobId ?? ""));
    for (const consumerPath of role.consumerRefs ?? []) {
      if (!sourcePaths.has(consumerPath)) errors.push(`unlinked brand consumer ${consumerPath} for ${role.roleId ?? "<missing>"}`);
    }
    for (const jobId of role.jobIds ?? []) {
      if (!knownJobIds.has(jobId)) errors.push(`unknown brand consumer job ${jobId} for ${role.roleId ?? "<missing>"}`);
    }
    for (const reference of [...sourceRefs, ...proofRefs]) {
      const source = reference.path ? sourcesForInventory[reference.path] : undefined;
      if (!reference.path || reference.path.startsWith("/") || reference.path.split(/[\\/]/).includes("..") ||
          !source || !reference.locator || !source.includes(reference.locator)) {
        errors.push(`invalid brand role source ${reference.path ?? "<missing>"}#${reference.locator ?? "<missing>"}`);
      }
    }
    for (const proof of proofRefs) {
      if (!proof.kind?.includes("owner") || !proof.owner?.trim() || !proof.limitation?.trim() ||
          proof.owner !== proof.path?.split("/").at(-1)) errors.push(`wrong brand proof owner ${role.roleId ?? "<missing>"}`);
    }
    const u3 = role.u3Criteria ?? {};
    if (["empty", "loading", "error", "populated", "overflow", "long-text"].some((key) => !u3[key]) ||
        Object.keys(u3).some((key) => !["empty", "loading", "error", "populated", "overflow", "long-text"].includes(key))) {
      errors.push(`missing U3 criteria for ${role.roleId ?? "<missing>"}`);
    }
    for (const [criterion, state] of Object.entries(u3)) {
      const refsKnown = (ids: string[] | undefined, known: Set<string>) => Array.isArray(ids) && ids.length > 0 && ids.every((id) => known.has(id));
      if (state.status === "mapped") {
        if (!state.meaning?.trim() || !refsKnown(state.sourceRefIds, sourceIds) || !refsKnown(state.proofRefIds, proofIds)) errors.push(`unproven U3 ${criterion} for ${role.roleId}`);
      } else if (state.status === "not_applicable") {
        if (!state.reason?.trim() || !refsKnown(state.sourceRefIds, sourceIds) || !refsKnown(state.proofRefIds, proofIds)) errors.push(`unexplained U3 ${criterion} for ${role.roleId}`);
      } else errors.push(`invalid U3 ${criterion} for ${role.roleId}`);
    }
  }
  const families = brand.assetFamilies ?? [];
  const familyIds = families.map((family) => family.id ?? "");
  for (const requiredId of requiredAssetFamilies) if (!familyIds.includes(requiredId)) errors.push(`missing brand asset family ${requiredId}`);
  if (new Set(familyIds).size !== familyIds.length) errors.push("duplicate brand asset family identity");
  for (const family of families) {
    const refs = family.sourceRefs ?? [];
    if (!family.paths?.length || !refs.length) errors.push(`incomplete brand asset family ${family.id ?? "<missing>"}`);
    for (const reference of refs) {
      const source = reference.path ? sourcesForInventory[reference.path] : undefined;
      if (!source || !reference.locator || !source.includes(reference.locator)) errors.push(`invalid asset source ${reference.path ?? "<missing>"}#${reference.locator ?? "<missing>"}`);
    }
    for (const assetPath of family.paths ?? []) {
      const filename = assetPath.split("/").at(-1) ?? "";
      if (!assetPath.startsWith("brand/assets/") || assetPath.split("/").includes("..") ||
          !existsSync(resolve(root, assetPath)) ||
          !(sources["brand/assets/README.md"]?.includes(filename) || sources["brand/brand.json"]?.includes(filename))) {
        errors.push(`missing or unreferenced brand asset ${assetPath}`);
      }
    }
  }
  const knownAssetPaths = new Set(families.flatMap((family) => family.paths ?? []));
  for (const role of brandRoles) {
    for (const assetPath of role.assetPaths ?? []) {
      if (!knownAssetPaths.has(assetPath)) errors.push(`unlinked brand role asset ${assetPath} for ${role.roleId ?? "<missing>"}`);
    }
  }
  const contracts = brand.contracts ?? [];
  const contractIds = contracts.map((contract) => contract.id ?? "");
  for (const requiredId of requiredBrandContracts) if (!contractIds.includes(requiredId)) errors.push(`missing brand contract ${requiredId}`);
  for (const contract of contracts) {
    if (!contract.topic?.trim() || !contract.consumerJobs?.length || !contract.laterOwners?.length ||
        !contract.sourceRefs?.length || !contract.proofRefs?.length) errors.push(`incomplete brand contract ${contract.id ?? "<missing>"}`);
    for (const reference of [...(contract.sourceRefs ?? []), ...(contract.proofRefs ?? [])]) {
      const source = reference.path ? sourcesForInventory[reference.path] : undefined;
      if (!source || !reference.locator || !source.includes(reference.locator)) errors.push(`invalid brand contract reference ${reference.path ?? "<missing>"}#${reference.locator ?? "<missing>"}`);
    }
    for (const proof of contract.proofRefs ?? []) {
      if (!proof.kind?.includes("owner") || !proof.owner?.trim() || !proof.limitation?.trim()) errors.push(`incomplete brand contract proof ${contract.id ?? "<missing>"}`);
    }
  }

  const carry = inventory.carryDispositions ?? [];
  const requiredCarryIds = [
    "seed008.drawer-title-overlap",
    "seed008.dense-typography",
    "seed008.redaction-empty-copy",
    "seed008.screenshot-provenance",
    "seed008.degraded-timeline",
    "adm06.descriptorless-intent",
    "proof-scope.local-only",
  ];
  const carryIds = carry.map((entry) => entry.id ?? "");
  if (new Set(carryIds).size !== carryIds.length) errors.push("duplicate carry disposition identity");
  for (const requiredId of requiredCarryIds) if (!carryIds.includes(requiredId)) errors.push(`missing carry disposition ${requiredId}`);
  for (const entry of carry) {
    if (!entry.id || !entry.status?.trim() || !entry.disposition?.trim() || !entry.laterOwners?.length ||
        !entry.sourceRefs?.length || !entry.proofGap?.trim()) errors.push(`incomplete carry disposition ${entry.id ?? "<missing>"}`);
    for (const reference of [...(entry.sourceRefs ?? []), ...(entry.proofRefs ?? [])]) {
      const source = reference.path ? sourcesForInventory[reference.path] : undefined;
      if (!reference.path || reference.path.startsWith("/") || reference.path.split(/[\\/]/).includes("..") ||
          !source || !reference.locator || !source.includes(reference.locator)) {
        errors.push(`invalid carry reference ${reference.path ?? "<missing>"}#${reference.locator ?? "<missing>"}`);
      }
    }
    for (const proof of entry.proofRefs ?? []) {
      if (!proof.kind?.includes("owner") || !proof.owner?.trim() || !proof.limitation?.trim() ||
          proof.owner !== proof.path?.split("/").at(-1)) errors.push(`wrong carry proof owner ${entry.id}`);
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

test("brand crosswalk maps every approved role, asset family, and later owner without copying tokens", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));
  assert.deepEqual(semanticInventoryErrors(inventory, fixture, semanticSources), []);

  const missingRole = structuredClone(inventory);
  missingRole.brandReferences.roles = missingRole.brandReferences.roles.filter((role: BrandRole) => role.roleId !== "artwork");
  assert.ok(semanticInventoryErrors(missingRole, fixture, semanticSources).includes("missing approved brand role artwork"));

  const missingAsset = structuredClone(inventory);
  missingAsset.brandReferences.assetFamilies = missingAsset.brandReferences.assetFamilies.filter((family: { id?: string }) => family.id !== "assets.favicon-variants");
  assert.ok(semanticInventoryErrors(missingAsset, fixture, semanticSources).includes("missing brand asset family assets.favicon-variants"));

  const wrongOwner = structuredClone(inventory);
  wrongOwner.brandReferences.roles[0].proofRefs[0].owner = "unrelated-owner.exs";
  assert.ok(semanticInventoryErrors(wrongOwner, fixture, semanticSources).includes("wrong brand proof owner body"));

  const unsafeAsset = structuredClone(inventory);
  unsafeAsset.brandReferences.assetFamilies[0].paths[0] = "brand/assets/../../mix.exs";
  assert.ok(semanticInventoryErrors(unsafeAsset, fixture, semanticSources).some((error) => error.includes("missing or unreferenced brand asset")));

  const missingCarry = structuredClone(inventory);
  missingCarry.carryDispositions = missingCarry.carryDispositions.filter((entry: CarryDisposition) => entry.id !== "seed008.screenshot-provenance");
  assert.ok(semanticInventoryErrors(missingCarry, fixture, semanticSources).includes("missing carry disposition seed008.screenshot-provenance"));
});

test("named scenarios reject missing state links, duplicate-label identities, unsafe paths, and wrong proof owners", () => {
  const inventory = JSON.parse(readFileSync(semanticInventoryPath, "utf8"));
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8"));

  const missingScenario = structuredClone(inventory);
  missingScenario.scenarios = missingScenario.scenarios.filter((candidate: SemanticScenario) => candidate.id !== "scenario.state-empty");
  assert.ok(semanticInventoryErrors(missingScenario, fixture, semanticSources).includes("missing named scenario scenario.state-empty"));

  const missingState = structuredClone(inventory);
  delete missingState.scenarios[0].stateCriteria.empty;
  assert.ok(semanticInventoryErrors(missingState, fixture, semanticSources).includes("missing U2 criteria for scenario.acme-4521-investigation"));

  const repeatedIdentity = structuredClone(inventory);
  repeatedIdentity.scenarios.find((candidate: SemanticScenario) => candidate.id === "scenario.state-duplicate-labels").duplicateLabelExamples[1].identity = "synthetic_change(1)";
  assert.ok(semanticInventoryErrors(repeatedIdentity, fixture, semanticSources).includes("duplicate-label fixture identities are not distinct"));

  const unsafePath = structuredClone(inventory);
  unsafePath.scenarios.find((candidate: SemanticScenario) => candidate.id === "scenario.state-empty").sourceRefs[0].path = "../mix.exs";
  assert.ok(semanticInventoryErrors(unsafePath, fixture, semanticSources).some((error) => error.includes("invalid named scenario reference")));

  const wrongOwner = structuredClone(inventory);
  wrongOwner.scenarios.find((candidate: SemanticScenario) => candidate.id === "scenario.state-empty").proofRefs[0].owner = "unrelated-owner.exs";
  assert.ok(semanticInventoryErrors(wrongOwner, fixture, semanticSources).includes("wrong or incomplete scenario proof owner for scenario.state-empty"));
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
