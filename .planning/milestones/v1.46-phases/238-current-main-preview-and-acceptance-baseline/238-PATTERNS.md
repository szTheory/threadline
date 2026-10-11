# Phase 238: Current-main preview and acceptance baseline — Pattern Map

**Mapped:** 2026-10-08  
**Source basis:** `origin/main` at `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`; checkout is stale and dirty. Excerpts below are from `git show origin/main:<path>`, with source line numbers. Every analog was confirmed tracked by `git ls-tree -r --name-only origin/main`.
**Files analyzed:** 6 proposed additions/modifications  
**Analogs found:** 6 / 6

The CONTEXT and RESEARCH do not lock new implementation filenames. “Proposed path” below is a concrete planning target inferred from the Wave 0 gaps; keep names adjustable in PLAN.md. New artifacts must use product/domain terms such as route, control, state, capture, and evidence. Avoid internal workflow labels in shipped source and tests.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` (modify) | test / browser capture | request-response, file I/O | same file at `origin/main` | exact |
| `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` (new, proposed) | utility | transform, file I/O | `e2e/support/operator-surface-paths.ts` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-inventory-contract.spec.ts` (new, proposed if browser-side inventory contract is needed) | test | transform | `e2e/support/operator-surface-paths.test.ts` | role-match |
| `test/fixtures/operator_surface/route-inventory.json` (new, proposed) | config/data artifact | transform | `test/fixtures/operator_surface/design-system-ledger.json` and route scorecard schema in capture spec | partial |
| `test/threadline/operator_surface/phase_238_inventory_contract_test.exs` (new, proposed) | test | transform | `test/threadline/operator_surface/component_contract_test.exs`; `test/threadline/playwright_fail_fast_contract_test.exs` | role-match |
| `examples/threadline_phoenix/e2e/run-e2e.sh` (modify only if isolation controls are missing) | utility / runner | request-response, file I/O | same file at `origin/main`; wrapper in root `mix.exs` | exact |

## Pattern Assignments

### `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` (modify)

**Analog:** Same tracked file, read from `origin/main`.

**Imports, roots, and capture setup** (lines 1–7, 28–37):
```typescript
import { expect, Page, test } from "@playwright/test";
import { existsSync, mkdirSync } from "node:fs";
import {
  atomicWriteFile,
  currentOperatorSurfacePaths,
  resolveContainedPath,
} from "../support/operator-surface-paths.js";

const paths = currentOperatorSurfacePaths();
const routeScorecardsDir = paths.routeScorecardsDir;
const artifactsRoot = resolveContainedPath(paths.e2eRoot, "artifacts/routes");
const SCHEMA_VERSION = 1;
const BREAKPOINTS = [1280] as const;
```

Retain the adapter and contained output paths. Replace the single-width/content-only assumptions with the bounded route and shell coverage agreed in CONTEXT. `ROUTES` at lines 92–99 currently contains `timeline`, its degraded duplicate, coverage, retention, actor, and evidence: five distinct paths. Extend the route contract to the eleven host-relative routes from RESEARCH; do not count a duplicate state as another route.

**Authenticated direct-entry pattern** (lines 119–125):
```typescript
async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(ADMIN_EMAIL);
  await form.getByLabel("Password").fill(ADMIN_PASSWORD);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}
```

Use the seeded local identity through host authentication. Keep credentials and cookies out of evidence metadata. The current capture loop logs in once (lines 378–390); for captures requiring isolated permissions, use fresh browser contexts and preserve the actual role/scope in the manifest.

**Wait, capture, and output pattern** (lines 287–327, 328–375):
```typescript
await page.setViewportSize({ width: breakpoint, height: 900 });
await page.goto(path, { waitUntil: "load" });
const root = page.locator(ROOT).first();
await root.waitFor({ state: "visible", timeout: 15_000 });
const content = page.locator(CONTENT).first();
await content.waitFor({ state: "visible", timeout: 15_000 });
await page.waitForLoadState("networkidle");
await page.evaluate(() => (document as unknown as { fonts: { ready: Promise<unknown> } }).fonts.ready);
```

`captureCell` writes screenshot, DOM, accessibility snapshot, resolved styles/tokens, and a JSON scorecard. It currently screenshots `#tl-main` (318–327), so add a distinct full-shell capture rooted at `.threadline-ui`/page rather than changing the meaning of existing content artifacts. Set per-run output roots before writes; ordinary verification must not rewrite reference fixture PNGs. Current metadata includes route, theme, viewport and declared Playwright version (347–375); source SHA, diff identity, fixture identity, browser runtime, served CSS/JS response hashes, conditions, and output hashes are new manifest fields. Derive package and browser versions from runtime evidence; the existing `PLAYWRIGHT_VERSION` literal at lines 32–33 is stale versus the current lockfile.

### `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` (new, proposed)

**Analog:** `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts` (`origin/main`, tracked).

**Path safety and roots** (lines 15–19, 79–100):
```typescript
const moduleDirectory = dirname(fileURLToPath(import.meta.url));
const repositoryRoot = resolve(moduleDirectory, "../../../..");

const fixtureRoot = canonicalizeExistingParent(
  overrides.fixtureRoot ?? resolve(repositoryRoot, "test/fixtures/operator_surface"),
);
const generatedRoot = canonicalizeExistingParent(
  overrides.outputRoot ?? resolve(repositoryRoot, "test/generated/operator_surface"),
);
assertSeparatedOutputRoot(generatedRoot, [ledgerPath, scorecardsDir, goldenDir, refuteDir]);
```

Reuse its explicit roots and containment helpers (including `resolveContainedPath`, `atomicWriteFile`, lines 79–100 and later exports). Evidence output belongs under a unique generated run directory; immutable fixtures and checked-in screenshot baselines remain read-only during normal checks.

**Manifest behavior:** Keep the new helper narrow: canonical serialization and hashing, explicit required fields, safe path resolution, and atomic writes. Bind each capture ID to source SHA/diff digest, fixture scenario/version digest, route and state, actor role/scope, actual browser/version and theme, viewport and separately observed browser zoom, input/motion conditions, served asset URL/status/content-type/body SHA-256, and artifact hashes. Never serialize passwords, cookies, authorization headers, or sensitive response bodies. A source/served-asset mismatch must make the capture invalid for visual findings.

### `examples/threadline_phoenix/e2e/tests/operator-inventory-contract.spec.ts` (new, proposed)

**Analog:** `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts` (`origin/main`, tracked), especially lines 110–140 and 142–182.

**Contract-test pattern:** use Node's built-in `node:test` and strict assertions; create disposable fixtures with `mkdtemp` under `tmpdir()`, assert the intended invariant and cleanup in `finally`. The existing tests demonstrate exact route/path-root behavior, preservation of unknown arguments after parsing known flags, and failure-closed checks for absent/malformed JSON. Apply that style to exact set equality for the eleven route entries, non-empty IDs/ranks/owner phases, and a valid evidence link or explicit reasoned disposition for every route/primitive/control/state. Avoid snapshot-only assertions that pass while inventory entries silently disappear.

### `test/fixtures/operator_surface/route-inventory.json` and `test/threadline/operator_surface/phase_238_inventory_contract_test.exs` (new, proposed)

**Analogs:** `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts` (`origin/main`) for exact artifact contracts; `test/threadline/playwright_fail_fast_contract_test.exs` (`origin/main`, tracked) lines 1–43 for invoking a local runner with a temporary environment and asserting observable output; `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` (`origin/main`) lines 1–57 for readable, literal document-contract assertions.

**Contract-test pattern:** keep the fast inventory/provenance contract independent from browser rendering. Load the JSON fixture, validate required keys and unique identifiers, compare the route set exactly with the accepted eleven paths, and reject entries with neither capture IDs nor a reasoned disposition. Keep assertions diagnostic and tied to domain language. A passing source/JSON contract establishes completeness/link integrity only; rendered findings still require fresh Playwright evidence. If keeping this ExUnit-side adds a second parser/schema, prefer one authoritative fixture plus one contract test over parallel schemas.

### `examples/threadline_phoenix/e2e/run-e2e.sh` (modify only if required)

**Analog:** Same tracked runner at `origin/main`; wrapper analog is root `mix.exs` at `origin/main`.

**Test environment and reset sequence** (`run-e2e.sh`, lines 14–17, 236–248):
```bash
export DB_HOST="${DB_HOST:-localhost}"
export DB_PORT="${DB_PORT:-5432}"
export MIX_ENV=test
export THREADLINE_E2E=1
...
mix ecto.create --quiet -r ThreadlinePhoenix.Repo 2>/dev/null || true
mix ecto.migrate --quiet
mix demo.reset
mix demo.seed
```

The runner already scopes config to test and calls reset then seed. `config/test.exs` lines 10–18 names the database `threadline_phoenix_test#{MIX_TEST_PARTITION}`. Before invoking it, set a unique phase-run partition and verify the derived test database. Never set `DEMO_ALLOW_RESET=1`; `Demo.Reset.assert_dev_or_allowed!/1` (`demo/reset.ex`, lines 142–158) is the existing production guard, and reset truncates demo tables before reseeding (125–139). The deterministic seed is centralized in `Demo.Seed.run/0` (`demo/seed.ex`, lines 25–48), which seeds the random generator and runs the stable personas/exports/anchors/filler/temporal pipeline.

**Readiness and argument forwarding** (`run-e2e.sh`, lines 292–306; `mix.exs`, lines 353–368):
```bash
if ! operator_surface_ready; then
  fail_with_log "Operator surface preflight failed at ${BASE_URL}/audit; log follows:"
fi
...
npm test -- "$@"
```

```elixir
case System.cmd("bash", [script | args], env: env, into: IO.stream(:stdio, :line)) do
  {_output, 0} -> :ok
  {_output, status} -> Mix.raise("verify.example_browser failed (#{status})")
end
```

`mix verify.example_browser` prepends the runner path while preserving each trailing CLI argument as a distinct argv element. The shell runner forwards `"$@"` after `npm test --`; retain both forwarding boundaries so `--project=route-capture` and the spec filter reach Playwright. Do not quote/squash all forwarded arguments into one string.

## Shared Patterns

### Safe generated evidence

**Sources:** `e2e/support/operator-surface-paths.ts` lines 79–100 and capture spec lines 105–117, 315–375. Resolve generated output under an explicit root, enforce containment/separation from fixtures, and serialize deterministically through `atomicWriteFile`. Use a fresh run directory; do not use a reference snapshot path as a normal test output.

### Preview fixture partition and reset

**Sources:** `e2e/run-e2e.sh` lines 14–17, 236–248; `config/test.exs` lines 10–18; `demo/reset.ex` lines 125–158; `demo/seed.ex` lines 25–48. `MIX_ENV=test` plus a unique `MIX_TEST_PARTITION` isolates the demo database. The demo reset deletes only its configured demo tables; the production override is prohibited for this work. Use the existing seed and stable manifest IDs rather than hand-built or external data.

### Evidence classes

**Sources:** `operator-page-capture.spec.ts` lines 287–375; `operator-surface-paths.test.ts` lines 142–182; `test/threadline/playwright_fail_fast_contract_test.exs` lines 23–43. Browser captures establish rendered route/state behavior. Fast contracts establish inventory and manifest completeness. Keep those claims separate in names and assertions.

## No Analog Found

| File/capability | Reason |
|---|---|
| Source-bound served-asset hashing and the full source/fixture/capture manifest | No current tracked analog binds browser response-body hashes to source SHA and capture conditions. Reuse Playwright response events, Node crypto hashing, and the path adapter; this is genuinely new evidence plumbing. |
| Eleven-route exact inventory/disposition artifact | Existing capture `ROUTES` and preflight inventory are partial inputs, not a complete machine-checked route/control/state contract. Define the small schema from RESEARCH and preserve explicit no-render dispositions. |
| Actual 200% browser UI zoom automation | No tracked project helper proves browser-chrome zoom. Do not label viewport/DPR emulation as zoom; implement a verified browser-chrome path if available or record the limitation. |

## Metadata

**Analog search scope:** tracked `origin/main` tree: Phoenix E2E support/tests, demo seed/reset/config, root Mix wrappers, and operator-surface contracts.  
**Files read:** 12 tracked analogs across capture, output safety, browser setup, test contracts, wrapper forwarding, and fixture reset.  
**Tracked-source check:** all named analogs exist in `git ls-tree -r --name-only origin/main`; no runtime mirror paths used.  
**Pattern extraction date:** 2026-10-08
