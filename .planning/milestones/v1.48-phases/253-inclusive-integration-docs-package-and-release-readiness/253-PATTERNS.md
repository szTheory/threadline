# Phase 253: Inclusive Integration, Docs, Package and Release Readiness - Pattern Map

**Mapped:** 2026-11-13  
**Files analyzed:** 41 proposed files, including conditional inventory updates  
**Analogs found:** existing owner patterns for all areas; no tracked runtime bootstrap or forced-colors assertion exists yet

## File Classification

| Proposed file or owner group | Role | Data flow | Closest analog | Match quality |
|---|---|---|---|---|
| `examples/threadline_phoenix/e2e/run-e2e.sh` | runner / process lifecycle | batch setup → request-response server → browser run | Same runner: post-reset launch and readiness checks at lines 416-505 | exact owner; new Pruner bootstrap has no implementation analog |
| `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts` | test / runner contract | process argv and filesystem lifecycle | Same test: ordinary runner lifecycle at lines 373-402 | exact |
| `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `operator-responsive-mobile-first.spec.ts`, `operator-phase-173-uat.spec.ts`, `operator-phase-178-uat.spec.ts`, `operator-zoom-proof.spec.ts`, `operator-route-states.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-prove-mobile.spec.ts` under `examples/threadline_phoenix/e2e/tests/` | mounted-browser tests | request-response, keyboard, touch, viewport and visual state | `operator-route-states.spec.ts` retention preview/focus/cancel flow at lines 1404-1450; `operator-accessibility.spec.ts` focus and dialog semantics at lines 702-724 | exact for current modal journey; role-match for each spec's own assertion |
| Actual 200% zoom and embedded-container proof in the existing E2E owners | browser test / geometry observation | browser tab state → DOM measurement | `support/operator-tab-zoom.ts` lines 26-48, 51-93; `operator-route-states.spec.ts` lines 1576-1612 | exact for tab zoom; partial for geometry (current assertions focus on document/selected element) |
| Selected forced-colors proof in an existing accessibility/route spec | browser test / media-state assertion | emulated media → mounted DOM and semantics | `operator-accessibility.spec.ts` lines 702-724; `operator-route-states.spec.ts` lines 640-685 | partial; no current `forcedColors` assertion |
| `test/fixtures/operator_surface/route-inventory.json`, `test/fixtures/operator_surface/source-surface-checklist.json`, `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`, and `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` (only if a source anchor or declaration changes) | static inventories / contract test | file I/O → transform and anchor validation | `operator-route-evidence.test.ts` lines 881-920; `operator_surface_fixture_contract_test.exs` | exact for current registry and static integrity |
| README/example discovery batch: `README.md`, `examples/threadline_phoenix/README.md`, `test/threadline/readme_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs`, `test/threadline/persona_routing_doc_contract_test.exs` | adopter documentation / contract tests | static copy and link contract | `readme_doc_contract_test.exs` lines 49-89, 180-200 | exact |
| Package metadata and Admin mount batch: `mix.exs`, `lib/threadline.ex`, `guides/operator-surface.md`, `test/threadline/operator_surface_doc_contract_test.exs`, `test/threadline/release_artifact_contract_test.exs` | config, module docs, guide, contract tests | static docs plus package archive construction | `operator_surface_doc_contract_test.exs` lines 25-80; `release_artifact_contract_test.exs` lines 84-115 | exact |
| Brand/history batch: `DESIGN-SYSTEM.md`, `brandbook/README.md`, `brandbook/brand-book.md`, `brandbook/pressure-test.md`, `test/threadline/brandbook_token_parity_test.exs` | design docs / contract test | static authority and token parity | `brandbook_token_parity_test.exs` lines 5-17, 47-74; `release_artifact_contract_test.exs` lines 88-115 | exact for authority boundary and current palette checks |
| Architecture/integration batch: `guides/how-threadline-works.md`, `guides/integration-contracts.md`, `test/threadline/how_threadline_works_doc_contract_test.exs`, `test/threadline/integration_contracts_doc_contract_test.exs`, `test/threadline/code_walkthrough_doc_contract_test.exs` | guide docs / contract tests | static copy and stable source/API anchors | `how_threadline_works_doc_contract_test.exs` lines 7-23, 47-80; `operator_surface_doc_contract_test.exs` lines 42-60 | exact |
| Evaluator batch: `guides/evaluating-threadline.md`, `test/threadline/evaluating_threadline_doc_contract_test.exs` | evaluator documentation / contract test | static current copy with historical release links | Same contract at lines 22-47, 58-80 | exact |
| Migration/theme batch: `guides/upgrade-path.md`, `test/threadline/upgrade_path_doc_contract_test.exs`, `test/threadline/operator_surface/style_contract_test.exs`, `priv/fonts/README.md` | migration guide, style contract, historical asset note | static compatibility matrix/theme contract | `upgrade_path_doc_contract_test.exs` lines 5-38, 40-72, 101-120; `brandbook_token_parity_test.exs` lines 5-17 | exact |

The documentation batches follow the ownership split in `2026-11-13-phase253/docs-package.md`. Keep each implementation batch at five files or fewer. Historical brand/font files remain in place and become clearly superseded; the active asset allowlist stays unchanged unless a concrete archive/rendered-doc mismatch is found.

## Pattern Assignments

### E2E runner and its argv/readiness contract

**Owner:** `examples/threadline_phoenix/e2e/run-e2e.sh`  
**Contract owner:** `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts`

The tracked runner already owns ordering, process management and fail-closed readiness. Migrations and fixture reset precede the managed server; it waits for the actual listener, validates that the listener is the example app's VM, and checks the mounted `/audit` surface before Playwright. Preserve that flow and put the private bootstrap only in this runner after `mix ecto.migrate` and `mix demo.reset`.

**Existing lifecycle pattern** (`run-e2e.sh`, lines 416-456, 458-505):

```bash
if [[ "$PREVIEW_MODE" != "1" ]]; then cleanup_exports; fi

cd "$EXAMPLE"
mix ecto.migrate --quiet
mix demo.reset

PHX_PID=$(python3 -c 'import os, subprocess, sys; log = open(sys.argv[1], "ab", buffering=0); child = subprocess.Popen(["mix", "phx.server"], cwd=sys.argv[2], env=os.environ, stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT, start_new_session=True); print(child.pid)' "$LOG_FILE" "$EXAMPLE")

ready=0
for _ in $(seq 1 120); do
  if server_ready "${PORT}"; then ready=1; break; fi
  if ! kill -0 "$PHX_PID" 2>/dev/null; then fail_with_log "phx.server exited before port ${PORT} opened; log follows:"; fi
  sleep 1
done
```

**Exact process-argv test owner** (`operator-evidence-manifest.test.ts`, lines 373-402):

```typescript
test("ordinary runner lifecycle forwards arguments and removes only ignored export files", (t) => {
  // ...fixture installs a fake `mix` on PATH...
  writeFileSync(join(bin, "mix"), '#!/usr/bin/env bash\nprintf "mix %s\\n" "$*" >> "$RUNNER_SENTINEL"\nif [[ "$*" == "phx.server" ]]; then exec sleep 30; fi\n');
  // ...runner is exercised; npm argv and export cleanup are asserted...
});
```

This is the exact tracked owner that currently pins `mix phx.server`; research's conditional pointer to this file is confirmed. Update its fake process/argv assertion in the same batch so it accepts the bootstrap command actually emitted by the tracked runner. Do not hand-copy a substitute bootstrap into the test. A readiness test should observe the runner-generated command and require its worker/schema marker before the fake browser command can proceed.

No tracked implementation of the proposed `mix run --no-start --no-halt -e` server bootstrap exists. The new runner command must set existing private Export housekeeping options before app startup (24-hour cleanup interval, 12000-hour abandoned-running cutoff), start the app with its existing endpoint environment, wait until `ThreadlinePhoenix.Repo` and the migrated storage schema are usable, then start the actual Pruner under `Threadline.Application.Supervisor`. Keep existing Retention values (`enabled`, `keep_days: 30`, `delete_empty_transactions: true`, `interval_ms: 86_400_000`, `sleep_ms: 0`); verify the worker's own `target_snapshot()` binds its actual PID/Repo/schema/sleep before writing the marker. Marker absence or any startup/identity failure must remain a runner failure via `fail_with_log`, before `npm test`. Preserve disabled Retention in `examples/threadline_phoenix/config/test.exs`. Record these fixture overrides as test setup, not evidence of default Export cleanup.

For the target API and safe refusal style, use the tracked ExUnit owners `test/threadline/retention/pruner_test.exs` lines 67-90 and `test/threadline/operator_surface/live/retention_history_live_test.exs` lines 130-148: they obtain `Pruner.target_snapshot()`, compare the exact PID and Repo, keep the snapshot stable across acceptance, and assert mismatches do not create a run. Those tests are API/DB analogs only; the runner must verify the public snapshot and actual schema rather than inspect process state or fake a Repo.

### Retention entry affordances across existing browser specs

**Primary analog:** `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`  
**Focus/semantics analog:** `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`

Migrate the old direct-entry locator only where the test's intent is to open the confirmation. The accessible sequence is Preview retention → verify preview → Review and confirm → verify dialog. Preserve cancel/no-write, focus return, touch, zoom and screenshot intent. The final dialog submit remains “Prune now.” A test that only asserts the entry affordance should assert “Preview retention” and stop there; it should not invent a delete flow.

**Mounted focus/cancel/touch pattern** (`operator-route-states.spec.ts`, lines 1404-1450):

```typescript
const preview = page.getByRole("button", { name: "Preview retention", exact: true });
const open = page.getByRole("button", { name: "Review and confirm", exact: true });
const prepare = async () => {
  await preview.click();
  await expect(page.getByTestId("retention-preview")).toBeVisible();
};
await prepare();
await open.focus();
await page.keyboard.press("Enter");
const dialog = page.locator("#prune-confirm-focus");
await expect(dialog.getByRole("textbox", { name: "Policy name to confirm" })).toBeFocused();
await page.keyboard.press("Escape");
await expect(dialog).toBeHidden();
await expect(preview).toBeFocused();
await expect(page.getByTestId("retention-preview")).toHaveCount(0);
```

Keep the deliberate positive mutation test in `operator-route-states.spec.ts` lines 1960-2008 behind its existing exact mutation-app URL and proof-directory controls. That test separately demonstrates disconnect/no-replay, an intentional valid confirmation, persisted run creation and deleted rows; it must not move onto the ordinary preview browser fixture. `operator-accessibility.spec.ts` lines 702-724 supplies the focused-target/dialog semantic checks; keep the required-empty-token and focus trap/return behavior there where asserted.

The nine affected specs share selectors but have distinct purposes: accessibility (reachability and dialog snapshot), motion (reduced-motion interaction), responsive (target size/table layout), phase 173/178 UAT (historical journey assertions), zoom (dialog remains usable at verified zoom), route states (focus/cancel/touch and separate mutation proof), screenshot regression (visibility only), and prove-mobile (bounded mobile dialog). Keep each local assertion and selected route intact; do not create a new spec or broad route × theme × viewport product.

### Zoom, container reflow and forced colors

**Actual zoom helper:** `examples/threadline_phoenix/e2e/support/operator-tab-zoom.ts`  
**Existing consumers:** `operator-route-states.spec.ts`, `operator-zoom-proof.spec.ts`

```typescript
export async function withIsolatedZoomContext<T>(
  browserType: BrowserType,
  run: (context: BrowserContext, page: Page) => Promise<T>,
): Promise<T> {
  const userDataDir = mkdtempSync(join(tmpdir(), "threadline-zoom-proof-"));
  // persistent headless Chromium context loads the tracked zoom extension
  // and closes the context/removes its temporary profile in `finally`.
}

// setAndReadTabZoom checks the active loopback test tab and requires zoomFactor === 2.
await chrome.tabs.setZoom(tab.id, 2);
const zoomFactor = await chrome.tabs.getZoom(tab.id);
```

The helper uses TypeScript ESM imports and `.js` relative specifiers (`operator-tab-zoom.ts` lines 1-10), and rejects a non-loopback or mismatched tab (lines 51-93). Keep actual tab zoom proof routed through it; `operator-investigation-pair.ts`'s capture zoom field is explicitly unverified and is not a replacement.

For reflow, `operator-route-states.spec.ts` lines 674-682 measures document width and a selected element's box/scroll width. The phase gap is the intended host/content container at actual 200% zoom. Extend the existing selected journey to measure the actual mounted container's `clientWidth` and `scrollWidth` plus relevant control bounds; do not treat document-root overflow alone or a shrink-wrapped child as container evidence. `operator-zoom-proof.spec.ts` lines 265-288 already visits Retention at actual 200%, opens the dialog and checks focus return on cancel.

There is no current forced-colors assertion. Add one selected `page.emulateMedia({ forcedColors: "active" })` case to an existing accessibility or route-state owner, following its semantic locator/focus assertions rather than inventing a new runner. Assert visible focus plus operation/status meaning independent of color. Keep native clipboard, default browser lanes and current proof limits unchanged.

### Source and semantic inventory anchors

**Closest analog:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts`  
**Static fixture contract:** `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs`

The route inventory is derived from `lib/threadline/operator_surface/router.ex`; the semantic journey inventory points to source and proof locators. Update those existing files only if the owner path, declaration or locator actually changes. Do not add another route/job/state registry.

```typescript
test("route inventory exactly matches the independently read eleven router paths", () => {
  const fixture = existsSync(fixturePath) ? JSON.parse(readFileSync(fixturePath, "utf8")) : { routes: [] };
  assert.equal(routerPaths.length, 11);
  assert.deepEqual(fixture.routes.map((r) => r.pattern).sort(), routerPaths);
  for (const route of fixture.routes) assert.ok(route.seedResolution && route.role && route.scope);
});

test("Acme #4521 investigation links Home, Timeline, transaction, drawer, and direct row history", () => {
  assert.deepEqual(semanticInventoryErrors(inventory, fixture, semanticSources), []);
  // negative mutations prove a missing route/source/proof locator is rejected
});
```

`operator-route-evidence.test.ts` lines 881-920 demonstrates the current contract: route path parity and source/proof anchor integrity. It does not establish mounted behavior, authorization or database outcomes; those claims stay attached to the owning ExUnit/LiveView/browser proof.

### Documentation, public names and stable anchors

**README pattern:** `test/threadline/readme_doc_contract_test.exs`  
**Mount/API pattern:** `test/threadline/operator_surface_doc_contract_test.exs`

The README contract reads the real tracked files, asserts approved copy/logo and canonical destination paths, and keeps the Admin intro beside the library description (`readme_doc_contract_test.exs` lines 49-89). Its example README contract protects stable link destinations and rejects copying the developer runbook (`lines 191-200`). When renaming visible headings, retain incoming anchors and update every contract that splits or links on the old heading together; keep technical module/API/config/route names compatible.

For the mount and migration prose, preserve the current public contract. Existing tests lock technical headings, `authorize_fn`, the explicit unauthenticated acknowledgement, host-pipeline limitation, export HTTP auth and generated release pin:

```elixir
for heading <- [
  "# Operator Surface",
  "## 1-Minute Mount",
  "### Theme",
  "### `:actor_fn`",
  "## Available Screens (v1.17)"
] do
  assert String.contains?(guide, heading)
end

assert String.contains?(guide, ~s({:threadline, "~> #{Pins.target_pin_version()}"}))
```

Source: `test/threadline/operator_surface_doc_contract_test.exs` lines 25-80. Its cross-guide assertion at lines 42-60 is the closest contract for `guides/integration-contracts.md` and `guides/code-walkthrough.md`: each mount guide names usable authorization and says `pipe_through` alone does not authorize. Preserve `Threadline.OperatorSurface`, `threadline_operator_surface/2`, `operator_surface_*`, `/audit`, and technical guide headings even where user-facing copy changes to Threadline Admin.

Other contract-owner analogs: `how_threadline_works_doc_contract_test.exs` lines 7-23/47-80 locks architecture reading order, vocabulary and module anchors; `integration_contracts_doc_contract_test.exs` lines 5-22/53-76 locks supported seam names and literal examples; `evaluating_threadline_doc_contract_test.exs` lines 30-47 keeps current verification claims separate from the historical 0.6.0 packaging link; `upgrade_path_doc_contract_test.exs` lines 5-38/40-72 locks compatibility-matrix shape, supported lanes and proof anchors. Keep 248 and 252 migration consequences in the current guide and update each owning test in the same batch. Do not rewrite `CHANGELOG.md` or historical release claims to erase old terminology.

### Package, brand authority and optional boundaries

**Archive analog:** `test/threadline/release_artifact_contract_test.exs`  
**Token authority analog:** `test/threadline/brandbook_token_parity_test.exs`  
**Optional integration boundary:** `test/threadline/optional_deps_contract_test.exs`

The actual package source is `mix.exs`; the release test reads ExDoc/package config, compares every on-disk guide to ExDoc extras, then inspects built/unpacked archive contents. Its checks already pin required README/CHANGELOG/CONTRIBUTING files, exact approved asset names/bytes, and exclusion of `brandbook/` and `priv/fonts/` (`release_artifact_contract_test.exs` lines 84-115). Keep `version: 1.1.0`, archive allowlist and the ten approved logo/favicon/WOFF2/license files unchanged absent a demonstrated mismatch. A config-only assertion is not an archive check.

The token parity test explicitly separates authorities: `brand/brand.json` owns approved palette facts, `lib/threadline/operator_surface/style/` owns functional UI tokens, and historical `brandbook/tokens.*` is not a second runtime source (`brandbook_token_parity_test.exs` lines 5-17). Preserve current color/contrast and negative-control coverage while relabeling old prose/tests as historical; do not add spacing aliases to brand JSON or rewrite assets without a verified discrepancy.

Phoenix/LiveView remain optional to the root package; PhoenixStorybook remains inside example dev/test. If an implementation edit changes compile-time Phoenix references, retain the file-scope `Code.ensure_loaded?` guard roster pattern in `test/threadline/optional_deps_contract_test.exs` lines 11-24/59-103 and the existing Storybook boundary test. Phase 253 documentation work alone does not justify a runtime dependency, archive expansion or CI topology change.

## Shared Patterns

### Fail-closed process readiness

**Sources:** `examples/threadline_phoenix/e2e/run-e2e.sh` lines 458-505; `test/threadline/retention/pruner_test.exs` lines 67-90; `test/threadline/operator_surface/live/retention_history_live_test.exs` lines 130-148.

Wait on observable server, Repo/schema and worker identity before allowing browser tests. Preserve real PID/Repo/schema/sleep binding and fail with the runner's managed log on any mismatch. `target_snapshot/0` is the worker identity surface; no replacement-worker fallback or state inspection should stand in for it. Keep positive delete/no-replay proof isolated from the ordinary browser preview fixture.

### Copy and anchor contract

**Sources:** `readme_doc_contract_test.exs`, `operator_surface_doc_contract_test.exs`, and each guide-specific `*_doc_contract_test.exs` listed above.

Read the current source file and assert the stable contract: user-facing product terminology, technical API/module/route names, links/anchors, migration consequences and proof limits. Update source and its existing owning test together. Historical release references retain their original source path and provenance.

### Package and asset authority

**Sources:** `mix.exs` lines 484-509; `release_artifact_contract_test.exs` lines 84-115; `brandbook_token_parity_test.exs` lines 5-17.

`mix.exs` is package configuration; the unpacked archive test is the package evidence. `brand/` owns current identity, the functional stylesheet owns spacing/UI tokens, and old font/brandbook directories are unshipped history. Keep the existing allowlist and proof owners unless a current archive/rendered-doc check demonstrates a specific mismatch.

## No Analog Found

| Gap | Guidance |
|---|---|
| Tracked runtime script that bootstraps Phoenix with `mix run --no-start --no-halt -e`, waits for host Repo/schema, starts the existing Pruner and writes readiness | No executable tracked analog found. Extend the existing `run-e2e.sh` process launch, and prove its exact generated invocation through the tracked runner lifecycle contract. Do not maintain a hand-copied test bootstrap or create a new app module/runner. |
| Existing selected forced-colors E2E assertion | No `forcedColors` match exists under current E2E specs. Add the bounded media-state assertion to an existing accessibility/route owner and keep status/operation meaning semantic. |

## Metadata

**Analog search scope:** `examples/threadline_phoenix/e2e/{run-e2e.sh,support,tests}`, `test/threadline`, `test/fixtures/operator_surface`, `mix.exs`, `lib/threadline.ex`, and proposed docs/package owners.  
**Files scanned:** focused runner, retention/zoom/accessibility, inventory validator, package/archive, doc-contract and brand token owners; no broad historical source scan.  
**Tracked-source gate:** every named existing code/test analog was confirmed with `git ls-files --`; no ignored runtime mirror paths are referenced.  
**Pattern extraction date:** 2026-11-13
