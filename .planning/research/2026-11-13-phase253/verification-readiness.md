# Phase 253: Verification and release-readiness research

**Researched:** 2026-11-13
**Scope:** ADM-32–34, evidence reconciliation, canonical CI/package gates and measured efficiency; ADM-31 only where it affects proof ordering.
**Confidence:** HIGH for repository behavior and accepted records; MEDIUM for the proposed E2E bootstrap shape until implemented and exercised.

## Recommendation

Keep one source-bound evidence ledger and the existing test/CI topology. Reuse accepted Phase 252 proof only where the source, behavior and environment boundaries have not changed. Migrate the remaining Retention entry probes to the existing preview-first sequence, and make the actual Pruner available to normal browser tests through a runner-only post-Repo startup hook. Keep the tracked test default disabled and the positive typed-delete proof on its existing isolated mutation fixture. For final acceptance, run the smallest affected local gates before the exact-candidate independent reviews; let the existing required CI workflow establish the candidate at its natural authorized PR boundary. Do not use a local full-root repeat or a workflow dispatch to manufacture a readiness receipt.

## Project Constraints (from AGENTS.md)

- Preserve the capture, semantics and exploration/operations boundaries. An AuditTransaction is not a request or action; an AuditChange is not an AuditAction.
- Prefer named `mix verify.*` / `mix ci.*` entrypoints; default tests stay honest; existing GitHub Actions job IDs remain stable; expensive path-filtered jobs still run on `main`; docs and example docs remain under contract tests.
- Do not add a public config/API/route, dependency, CI job, second registry or new demo application. Keep Phoenix LiveView/HEEx and PhoenixStorybook in the example dev/test boundary.
- Keep real mounted routes as the owners of URL lifecycle, authorization, downloads and mutations. Storybook, static images and digests do not prove those behaviors.
- Routine verification is automated. Keep the consumed full-root repeat stop, native clipboard, foreground, hosted dispatch, push, version, merge, publish and risk-acceptance boundaries intact. A local readiness record cannot discharge REL-01.
- Measure before proposing CI optimization. Prefer removing duplicated work to adding caches, concurrency, dependencies or retries. Preserve actual runner exit status and first-attempt failures.

## Phase Requirements

| ID | Research support |
|---|---|
| ADM-31 | Reuse matched source/asset/fixture/clock/browser/theme/viewport/zoom capture contracts; capture only the changed visual batches and refresh after relevant source or copy changes. |
| ADM-32 | Reconcile every existing inventory row against its actual route, LiveView/HTTP, DB, browser, static or pixel proof boundary; record status and limits rather than treating inventory presence as a pass. |
| ADM-33 | Keep the existing named gates and `ci-required` topology, run affected local checks only, then use natural required CI for the exact candidate. Record actual timings if a relevant CI run occurs; do not add jobs or run a cross-product. |
| ADM-34 | Separate local package shape/evaluator/bump rehearsal from package version changes and live publication. Carry REL-01 forward as pending until its natural first release PR proves the specific obligation. |

Phase goal and criterion source: `.planning/ROADMAP.md:173-186`; requirement wording and REL-01 source: `.planning/REQUIREMENTS.md:60-76`.

## Retained evidence and invalidation rules

| Accepted input | Reuse | Does not establish |
|---|---|---|
| Phase 252 accepted 39/39 scoped truths; source review clean; security 12/12 mitigations with no open threat; UI 22/24 plus a fresh 5-case final-width closure; production source `74fe8df2b2520868d464eca93054492fc93a2cad` | Reuse unchanged product/backend claims and their exact boundary-specific receipts. The final width closure is current for the Phase 252 source it names. | New inclusive use, current Phase 253 source, docs/package correctness, current required-CI status, or full Admin completeness. A passing digest is not a fresh judgment. |
| Phase 248 accepted local repeat and issue #61/#90 disposition | Retain the historical disposition and issue ownership without reopening settled work absent a defect. | Current hosted advisory/issue closure or a new full-root repeat. |
| Current route/state inventories and their existing route/evidence validators | Continue using `test/fixtures/operator_surface/route-inventory.json`, `source-surface-checklist.json`, and `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` as the one registry and journey authority. | Runtime behavior from a row's existence or locator; a validator pass on mapping completeness alone does not mean each behavior passed. |
| Existing PhoenixStorybook and capture manifests | Reuse static composition and exact-image identity checks for static/rendered claims only. | Host routing, authorization, DB state, downloads, persisted mutations or reconnect behavior. |

Phase 252's final disposition expressly leaves the older Retention selectors and positive Pruner startup for Phase 253; it says not to run the default local 5432/install/full-suite path. Its final gate order requires current sampling/reviews and closeout records before the last verifier fingerprint. See `252-REVIEW-DISPOSITION.md:23-40`, `252-VALIDATION.md`, `252-PAIR-EVIDENCE.md`, and `252-04-SUMMARY.md`. Preserve the current production/runtime identity separately from the planning checkout SHA; the accepted Phase 252 record distinguishes them.

### Evidence-owner boundaries

Keep the already-declared route and journey inventories as the crosswalk. The generic inventory is the owner for source-anchored primitives/components/routes/seams/states. The semantic journey inventory is the owner for complete operator jobs and the two-project browser execution receipt. Existing route evidence tests validate declarations/refs, while the owning ExUnit/ConnCase, Playwright and capture tests establish behavior at their own boundary. The final matrix should annotate each existing row with current status, source/runtime identity, exact proof receipt, fixture/clock and relevant browser conditions, claim limit, and a rerun trigger. It is an acceptance reconciliation of the existing inventories, not another route/state catalog.

For every truth, distinguish these claims:

| Boundary | Existing proof owner | What it can prove |
|---|---|---|
| Static composition/story | Storybook story and story contracts | Shared component rendering and fixed example state. |
| Mounted route/query lifecycle | Phoenix LiveView / ConnCase tests and mounted-route browser journey | URL, state transitions, authorization and operator interaction. |
| Database/retention/export outcome | ExUnit against the real configured Repo plus the isolated actual-worker browser mutation proof | Persisted records and actual backend result for the named fixture. |
| Browser keyboard, focus, zoom, touch, theme and motion | Existing Playwright owners and evidence receipts | Only the exercised browser/project/state/viewport/zoom conditions. |
| Visual comparison | Existing capture/pair manifest and bounded independent review | Matched rendered appearance and reviewed copy for the precise source/asset/fixture conditions. |
| Package contents/docs | Archive/unpack contracts, ExDoc, package evaluator and docs contracts | The built archive and declared documentation surface, not a published Hex release. |

Use route/job language from the current inventories and current source. Static-story assertions, PNG count, screenshots and checksums never fill a missing behavioral or database cell.

## Retention worker startup and destructive-path audit

### Exact current behavior

The example test config source currently states `retention: [enabled: false, keep_days: 30, delete_empty_transactions: true]` (`examples/threadline_phoenix/config/test.exs:138-139`). Preserve that quoted default. The example ExUnit helper creates/migrates its host Repo and then stops/restarts the Threadline dependency so cleanup children start against the migrated schema (`examples/threadline_phoenix/test/test_helper.exs:7-33`). The browser runner instead exports `THREADLINE_E2E=1`, compiles, creates/migrates the example DB, runs `mix demo.reset`, then launches its managed server process (`e2e/run-e2e.sh:14-20,418-456`). The example supervisor starts `ThreadlinePhoenix.Repo` before Oban and Endpoint (`lib/threadline_phoenix/application.ex:9-27`). Since the Threadline dependency application is started before the example host application, flipping the tracked retention default to enabled would attempt worker startup before the host Repo is ready. Also, an application-tree E2E child would run when Mix tasks start the app for ecto.migrate/demo.reset, before the initial schema is guaranteed ready. Keep the config default disabled and bootstrap after both commands have completed.

The normal browser suite already contains an active no-delete path that requires the real worker: the `Retention confirmation focus and cancel preserve state; Chromium touch navigation works` case is an explicit exception to the evidence-only skip list and uses Preview → Review and confirm (`operator-route-states.spec.ts:14-42,1404-1427`). It clicks the final button with the required confirmation field empty, checks the dialog remains and the retention row count is unchanged, then cancels with Escape; its second pass cancels with Keep and its touch pass does the same (`:1428-1450,1460-1480`). The read-only preview checks the Pruner PID/repo/schema target and enabled policy, then calls `Retention.purge(..., dry_run: true)` (`lib/threadline/operator_surface/live/retention_history_live.ex:266-278,199-218`). An unavailable Pruner therefore makes this ordinary selected CI case fail closed before it can establish preview/focus/cancel behavior.

Audit of selected/default E2E Retention activations:

| Active/opt-in path | Actual action | Mutation risk with enabled worker |
|---|---|---|
| `operator-route-states.spec.ts`, ordinary focus/cancel case | Read-only preview, open dialog, blank required submit attempt, Escape/Keep; row count asserted unchanged. | No accepted prune request because no canonical text is entered; this must work with the actual worker so the read-only preview is real. |
| `operator-accessibility.spec.ts:702-744` | Open the legacy entry modal, inspect consequence/copy/focus, Escape. | No typed submit; entry control must migrate to Preview → Review. |
| `operator-accessibility.spec.ts:1396-1412` and `operator-phase-173-uat.spec.ts:123-147` | Open/snapshot or Escape/outside-click dismiss the modal. | No typed submit; selectors are stale entry probes, not destructive activations. |
| `operator-phase-178-uat.spec.ts`, `operator-motion.spec.ts`, `operator-zoom-proof.spec.ts`, `operator-prove-mobile.spec.ts` | Open/focus/check/snapshot then Escape or Keep; zoom's retention action keeps audit data. | No canonical text plus final submit; migrate stale opener labels while preserving cancellation and focus/zoom assertions. |
| `operator-screenshot-regression.spec.ts` and responsive/prove-mobile visibility checks | Inspect the old button label, position or style. | No activation. Update the tested entry affordance to Preview retention; retain the final action label inside confirmation. |
| Phase 252 browser mutation test in `operator-route-states.spec.ts:1949-2008` | Fills `default`, proves offline/reconnect no replay, then deliberately submits and asserts a completed run and deleted rows. | Destructive by design. It is gated by exact mutation app URL `http://127.0.0.1:60154` and a proof directory rooted at `/private/tmp/private252mutationevidence/`; it is not the normal browser fixture. Keep its separate DB and records. |

No selected/default Playwright case was found that fills the policy name and submits the valid Retention form. Root ExUnit does have actual valid-confirmation tests in `test/threadline/operator_surface/live/retention_history_live_test.exs`; those use the root test Repo and clean storage schemas in `DataCase` before each test, distinct from the example's seeded browser database. Preserve their existing role.

### Smallest safe normal-browser fixture

Use the existing managed process launch in `e2e/run-e2e.sh` as the only startup owner: after `mix ecto.migrate` and `mix demo.reset`, replace the spawned server argv with an inline `mix run --no-start --no-halt -e` bootstrap. Before starting the apps, apply the existing private Export housekeeping options with a 24-hour cleanup interval and a 12000-hour abandoned-running cutoff. Then start the example app with its existing E2E/PHX_SERVER endpoint configuration; after the actual host Repo is up and its migrated schema is readable, set the in-memory Retention policy to enabled with unchanged `keep_days: 30` and `delete_empty_transactions: true`, `interval_ms: 86_400_000`, `sleep_ms: 0`, and add the actual Pruner child to the already-running `Threadline.Application.Supervisor` using `ThreadlinePhoenix.Repo`. Verify the actual worker target and emit a readiness marker the existing runner waits for before starting Playwright. This pattern follows Phase 252's accepted private bootstrap and avoids a new app module, public setting, config/test edit, or runner.

Record the exact fixture overrides; they are not proof of default Export cleanup behavior. Root `config/config.exs` currently sets Export cleanup to `cleanup_interval_ms: :timer.hours(1)`, `stale_running_cutoff_hours: 24`, and `retention_ttl_hours: 24 * 7` (`config/config.exs:14-25`). The demo Export seeder includes a `"running"` row whose `started_at` is relative to the fixed 2026-05-27 epoch (`examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex:47-53`); the default 24-hour bootstrap reconciliation would mark it failed at current wall-clock time. Phase 252's private pair already used a 24-hour cleanup interval and 12000-hour cutoff so startup would not rewrite retained operational rows, and explicitly says this is not default-cleanup proof (`252-PAIR-EVIDENCE.md:37`). Retain that cutoff or seed after startup; prefer the existing private 252 setting and make the limitation explicit. Bind ExportJob and RetentionRun rows before/after startup as well as canonical audit rows.

Before the runner proceeds, bind `Pruner.target_snapshot()` to the actual worker PID, Repo, configured storage schema and zero sleep; assert the schema exists and capture the actual seeded RetentionRun/ExportJob and canonical audit-row state. Do not substitute `:sys.get_state`, a fake Repo, a test adapter, or an inferred target for the worker's own snapshot. Keep `keep_days` and the demo seed's explicit cutoff behavior unchanged.

Why this preserves ordinary Retention rows: `Pruner.init/1` only changes stale `"running"`/`"queued"` RetentionRun statuses older than 24 hours and schedules its next purge after the configured interval (`lib/threadline/retention/pruner.ex:93-120,319-320`). The current ordinary seed statuses are exactly `"completed"`, `"failed"`, `"completed"`, and `"pending"` (`examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_runs.ex:38-67`), so startup cleanup does not rewrite them. The browser worker's first scheduled prune is 24 hours out; the selected default case only reads a dry-run preview and cancels. The intentional demo `RetentionTail` is separate: it applies its existing explicit epoch-anchored cutoff during `mix demo.reset` and restores the previous retention env on both success and failure (`demo/seed/retention_tail.ex:79-110,183-189`). Do not suppress deletion by changing `keep_days`.

Keep the positive deletion/no-replay proof on a disposable, uniquely owned mutation database. The ordinary pair/capture data and normal two-project browser DB are not its workspace. Reuse accepted Phase 252 mutation evidence only if its source and target still match; do not rerun or relabel its destructive invocation under the normal suite. A separate positive startup proof can verify worker readiness/target and seeded-row invariance without submitting the valid confirmation.

## Canonical gates and environment

The project aliases currently define `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix verify.example`, `mix verify.example_browser`, `mix verify.example_browser_light`, `mix verify.release`, `mix verify.hex_evaluator` and `mix verify.bump_rehearsal` (`mix.exs:128-181,331-353,410-452`). The exact `mix ci.all` chain includes root/example tests, Dialyzer and both voting browser projects, but is a full-root gate and is explicitly out of bounds under the consumed repeat stop (`mix.exs:212-242`; Phase 252 final disposition). `mix verify.example` contains dependency fetch, warnings-as-errors compile, host DB create and the entire nested suite. Example `mix precommit` contains compile, unused dependency check, formatting and test (`examples/threadline_phoenix/mix.exs:91-98`); if touching example code, satisfy this nested AGENTS contract once and avoid accidental duplicate full-suite invocations.

| Claim | Existing command/gate | Environment and custody | Limit/selection rule |
|---|---|---|---|
| Source formatting / focused root contract | `mix verify.format`; `mix verify.test test/threadline/<affected_owner>.exs` | Locked root deps, exact candidate source, managed background process. PostgreSQL still starts through root helper for selected tests. | Use owner-level test selectors for touched claims; do not call `mix ci.all` or a repeat alias locally. |
| Example contract and mounted integration | `mix verify.example` when required by touched example owners; otherwise nested `mix precommit` once at the end of example-code work | Create/migrate a unique example test DB before first Mix test; use the task-owned supported PostgreSQL service, correct `DB_HOST`/`DB_PORT`, current locked deps, and managed logs/exit status. | Do not silently omit the example tests. Avoid rerunning the same full example suite as both precommit and verify.example without a distinct reason. |
| Browser selector/preview/focus/touch/theme/zoom | `mix verify.example_browser operator-route-states.spec.ts --grep "Retention confirmation focus and cancel preserve state; Chromium touch navigation works" --project=desktop-chromium --project=mobile-chromium`; affected specs can be selected through the same alias. Use `mix verify.example_browser_light operator-accessibility.spec.ts --grep "inspection routes retain context and reachable controls in Light"` for the existing light lane. | `run-e2e.sh` resets its target DB, compiles the app and installs locked E2E packages/browser unless preview mode is used. Local runs require unique `MIX_TEST_PARTITION`, loopback only, task-owned DB and port, browser cache and current Node/OTP/Elixir toolchain. Keep the exact test owner/title and actual Playwright report. The CI browser job's `5432` is its job-owned ephemeral PostgreSQL service, not authorization to use a shared local 5432. | Run only selected affected cases locally; normal exact candidate CI remains the current desktop/mobile voting pair and receipt. Do not use the separate mutation URL/proof directory for a normal case. |
| Current package shape / ExDoc | `mix verify.release` | Clean committed candidate required; Mix/Hex/ExDoc deps available. This gate runs release shape, release artifact/topology contracts, dev ExDoc warnings-as-errors and `mix hex.build`. | Local archive build is not a publish or version bump. Capture the archive contract's unpacked contents, not only the allow-list source. |
| Package consumer integration | `mix verify.hex_evaluator` | Existing local rehearsal registry/evaluator and its prepared deps; no network publication. | Proves local package-resolution/compile/test path only. |
| Next-minor compatibility rehearsal | `mix verify.bump_rehearsal` | Existing scratch rehearsal path and clean candidate, as required by the current alias. | Not a real package version edit and not permission to change release metadata. |
| Required exact-candidate CI | Existing `.github/workflows/ci.yml` and `ci-required` | Actual natural PR/push authorization and the CI runner's owned PostgreSQL16 service/browser artifacts. Workflow trigger includes `push` and `pull_request` on `main`; workflow dispatch exists technically but is not authorized here. | Keep immutable job IDs and the two-project browser matrix. No new job, path filter, manual dispatch or “green” claim from old CI receipts. |

Before any long local gate, preflight exact Elixir, OTP, PostgreSQL version/support floor, lock/cache access, DB capacity and formatting; this research turn did not run environment checks or tests. Preserve actual local Postgres host/port and partition/DB identity in the future evidence. The root `mix verify.example_browser` default points at local DB port 5432, so an authorized local run must override it to an owned loopback Postgres instance and unique partition. CI's container service is separately job-owned and unaffected by that local stop.

### CI topology and measured efficiency

- `.github/workflows/ci.yml` keeps stable job IDs and a single required `ci-required` aggregator. There are no trigger-level path filters; every required check reports on doc-only changes and required jobs stay on `main`.
- The required Playwright matrix is exactly `desktop-chromium` and `mobile-chromium`, with an artifact receipt reconciling both. `route-capture` is an extra main/nightly/manual-dispatch smoke, not the required behavioral browser lane. Do not add a job or stretch the required project matrix into all themes × routes × widths × states.
- Root `mix ci.all` already re-runs the example suite and the two voting browser projects in local sequence. The standalone `verify.example_browser_light` alias exists for a selected light proof; do not imply it is a required CI leg.
- Historical 2026-11-10 CI duration observations are a triage baseline only, not a matched Phase 253 before/after. Phase 252's 3.96-second final width proof is a scoped test, not an end-to-end CI saving. If the natural required workflow runs, inspect current job timings, setup/dependency time, duplicate work and longest critical-path job once; compare only matched measurements and propose changes only if an actual recurring class warrants them. Do not dispatch CI just to measure.
- There is no verified efficiency reason to add caches, concurrency or retries. Keep failure visibility and first-attempt outcomes; inspect flaky/retried browser tests even when the aggregate exits zero.

## Package and release truth

The current package allow-list includes `lib`, guides, README/CONTRIBUTING, approved brand logos/fonts/licenses and package metadata, while excluding maintainer stress modules; the authoritative contract inspects the unpacked Hex archive (`mix.exs:484-508`, `test/threadline/release_artifact_contract_test.exs`). `test/threadline/optional_deps_contract_test.exs` plus `mix verify.compile_no_optional` protect Phoenix/LiveView optional-dependency boundaries; `test/threadline/operator_surface/storybook_boundary_test.exs` guards Storybook in example dev/test. Phase 253 should update the coupled docs/contracts through the docs-package research rather than widen the archive.

No package bump, lock update, dependency addition, release tag, push, merge, Hex publication or residual-risk decision is implied by local package readiness. Report `package ready for review` only when current archive/evaluator/docs gates pass; report publication as unperformed unless separately authorized and observed. REL-01 remains a live first-natural-release-PR obligation: its first CI run must be green without a separate CHANGELOG-dating PR, and the landing change includes its own Unreleased prose. This cannot be proven from a local build and remains pending in every Phase 253 local readiness record.

## Recommended owner batches (maximum five files per task)

Keep the inclusive sibling's exact E2E owner split and add one startup contract batch:

| Batch | Files | Purpose / proof |
|---|---|---|
| Existing runner worker readiness | `examples/threadline_phoenix/e2e/run-e2e.sh`; `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts` only if its existing process-argv contract pins `mix phx.server` | Replace only the existing server spawn with the post-migrate/reset Mix bootstrap; set Export overrides before app startup, start the real worker after Repo readiness, and gate Playwright on the worker marker. Keep `config/test.exs` disabled and use existing server/loopback controls. No new app module or runner. |
| Legacy Retention selectors A | `operator-accessibility.spec.ts`, `operator-motion.spec.ts`, `operator-responsive-mobile-first.spec.ts`, `operator-phase-173-uat.spec.ts`, `operator-phase-178-uat.spec.ts` | Migrate opener assertions to Preview retention → Review and confirm where that test promises a modal; retain the original cancel/focus/zoom/visual intent and do not add valid text submission. |
| Legacy Retention selectors B | `operator-zoom-proof.spec.ts`, `operator-route-states.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-prove-mobile.spec.ts` | Match the new preview-first affordance and use existing bounded preview/cancel paths. Keep the Phase 252 mutation test's DB/proof-dir gate intact. |
| Evidence reconciliation | Reuse existing route inventory, source checklist, semantic journey inventory, route evidence validator, browser receipt and capture manifests; change only the inventory owner whose existing source anchors actually moved. | Mark every existing row by current proof status/authority/limit; do not add a second registry or claim that inventory validation proves behavior. |
| Docs/package | Follow the sibling docs/package ownership table in `docs-package.md`. | Couple README/guides/example/ExDoc prose, asset anchors and archive contracts; do not modify runtime package scope to fix documentation drift. |

The E2E startup design is a recommendation, not yet verified implementation. Keep normal and destructive Retention data separate and record status before proposing any broader worker startup.

## Review schema and final record order

Use one independent source/security report for changed implementation, and one UI/copy review that maps each affected claim to current browser/capture proof and states its limit. A single disposition table should record finding, owner, fix, focused new receipt and the same reviewer's bounded delta result. Avoid format-only repeated review rounds. Use one status-aware matrix for route/job/state acceptance and one source/runtime identity per test receipt. A reviewer finding that changes source invalidates only affected proof and review, not every unrelated earlier receipt.

Recommended close order:

1. Freeze an exact candidate and reconcile prior accepted evidence with any changed source boundary.
2. Run cheap affected source, contract and selected browser checks after the last copy/style/source edit; capture the changed visual batches before final review. Phase 252's stale final-width copy demonstrates why fresh cheap checks belong before the final review.
3. Complete source/security and UI/copy reviews against that immutable candidate; classify findings and run only the affected proof/reviewer delta for each fix.
4. Write completed local validation, package, capture and review dispositions plus any UAT automation outcomes. Keep failures/superseded receipts visibly historical.
5. Complete final goal/security verification and fingerprint after records are complete. If only closeout documents change, request the existing verifier's bounded changed-record refresh; do not rerun tests or blanket source audit for docs-only writeback.
6. Stop at the external boundary. Await a naturally authorized PR for actual required CI and REL-01 evidence; no action beyond that boundary is authorized by local readiness.

## Security and operational checks

Security enforcement remains enabled. For this scope, retain V2 Authentication and V4 Access Control on mounted host operations; V5 Input Validation for query/export/Retention parameters and typed confirmation; V3 only if session or auth flow changes; V6 is not implicated absent crypto changes. No raw actor, tenant, database or worker details should be exposed in copied artifacts. Preserve host authorization and event-time checks, the worker's exact Repo/schema/PID binding, audited destructive intent and fail-closed behavior. A dry-run count's accuracy claim remains limited because it is sequential, not an atomic snapshot; do not label estimates as deleted rows. Reuse Phase252 security proof only for unchanged code and trust boundaries.

## Five closest analogs

1. `252-REVIEW-DISPOSITION.md` — exact Phase 253 handoff and required gate order.
2. `252-VALIDATION.md` and `252-PAIR-EVIDENCE.md` — actual worker identity, read-only/positive mutation split, retained fixture custody and source/asset/data limits.
3. `test/threadline/operator_surface/live/retention_history_live_test.exs` — existing actual-target startup, deliberate valid-confirm and refusal coverage at the LiveView/DB seam.
4. `mix.exs` plus `.github/workflows/ci.yml` — canonical aliases, immutable jobs, two browser legs and current aggregate topology.
5. `.planning/research/2026-11-10-brand-admin/milestone-verification-dx.md` — approved proof boundaries, bounded cross-product, static-vs-live distinction and no-new-CI-job default.

Also preserve the accepted Phase 248 issue #61/#90 disposition and the live REL-01 evidence in `.planning/milestones/v1.47-phases/247.1-close-gap-rel-01-rel-02-releasable-type-guard-and-release-pr/247.1-REL01-EVIDENCE.md`.

## Whole-phase research synthesis skeleton

When the parent combines the sibling inclusive and docs/package reports, keep the canonical phase RESEARCH.md concise and ordered as:

1. User constraints and Phase 253 requirement map.
2. One summary/recommendation and one responsibility/evidence-owner map.
3. Inclusive job, route and selected cross-cutting proof; worker readiness prerequisite.
4. Docs, brand asset and package boundary with source/test owner map.
5. Evidence reuse/invalidation matrix and exact-candidate verification gates.
6. Security/threat controls, operational environment and actual local blockers.
7. CI efficiency method and measured-or-unmeasured status.
8. Package/release readiness, REL-01 pending obligation and authorization limits.
9. Review schema, record order, assumptions and open questions.

No new dependency legitimacy audit is needed unless a later authorized change adds a package; no external documentation lookup is needed for these codebase/record-backed facts. This turn did not run any tests, services, database or browser checks.
