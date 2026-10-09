---
phase: 238-current-main-preview-and-acceptance-baseline
plan: "02"
subsystem: testing
tags: [playwright, operator-ui, evidence, provenance, themes, interactions]
requires:
  - phase: 238-01
    provides: Guarded isolated runner and strict source/asset/output provenance contracts.
provides:
  - Eleven independently inventoried direct routes with desktop/intermediate/narrow shell and content evidence.
  - Bounded dark and compile-time System/light state evidence with ranked failures and explicit limitations.
  - Small final-candidate evidence index with reproducible manifest/output custody hashes.
affects: [238-03, phase-239-tokens, phase-240-layout, phase-241-details, phase-242-interactions]
actuals:
  tokens: 15358
  tasks: 2
  commits: 4
plan_head_before: cb76439b821761367df8b6571e88b04c5ff03eaa
plan_head_after: 27c3b04391bd6dbdf80c8db24a76db294373d96c
tech-stack:
  added: []
  patterns: [independent router-set contract, reusable source-bound browser capture, bounded observed-state matrix, explicit project forwarding]
key-files:
  created:
    - test/fixtures/operator_surface/route-inventory.json
    - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
    - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
    - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
    - .planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
    - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - examples/threadline_phoenix/e2e/run-e2e.sh
key-decisions:
  - Keep the degraded Timeline as an extra state; compare the eleven-route fixture independently against the actual router.
  - Record product failures as observed evidence for later refinement phases without changing UI behavior.
  - Distinguish checked preference, mounted theme attribute and computed effective color scheme.
  - Preserve explicit runner selectors and keep all existing light-project spec matches.
  - Accept only the final route recapture after all tooling edits, with the same effective digest as both accepted state lanes.
  - Carry actual browser-chrome zoom and clipboard denial as unverified conditions; do not substitute viewport/DPR or host authorization denial.
requirements-completed: [UIB-01, UIB-02]
coverage:
  - id: D1
    description: Eleven exact direct routes at three widths with verified shell/content/observation/scorecard outputs and a separate degraded Timeline state.
    requirement: UIB-01
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts#route inventory exactly matches the independently read eleven router paths"
        status: pass
      - kind: e2e
        ref: "MIX_TEST_PARTITION=operator_routes_final_1791516878_82721 mix verify.example_browser --project=route-capture operator-page-capture.spec.ts (THREADLINE_E2E_EVIDENCE=1)"
        status: pass
      - kind: other
        ref: "Accepted final route manifest strict serialization and all 135 output/source/asset hash rechecks against committed candidate"
        status: pass
    human_judgment: false
  - id: D2
    description: Reproducible bounded state evidence and explicit failures/limitations in separate dark and compile-time System/light runs.
    requirement: UIB-02
    verification:
      - kind: e2e
        ref: "MIX_TEST_PARTITION=operator_states_1791516768_67927 mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts (THREADLINE_E2E_EVIDENCE=1)"
        status: pass
      - kind: e2e
        ref: "MIX_TEST_PARTITION=operator_system_light_1791516801_73894 mix verify.example_browser_light --project=desktop-chromium-light operator-route-states.spec.ts (THREADLINE_E2E_EVIDENCE=1)"
        status: pass
    human_judgment: false
  - id: D3
    description: Evidence index preserves exact accepted bundle paths, candidate identity, individual manifest hashes and output-set hashes without committing raw screenshots.
    verification:
      - kind: unit
        ref: "18 focused evidence/runner/route contracts, all passing"
        status: pass
      - kind: other
        ref: "Index single manifest_path and every recorded manifest/set hash checked against accepted bundles; source digest retained after scoped commits"
        status: pass
    human_judgment: false
duration: approximately 32 min
completed: 2026-10-09
status: complete
---

# Phase 238 Plan 02: Eleven-route and material-state baseline Summary

**Eleven direct operator routes now have source-bound shell/content evidence at 1280/768/375; separate dark and System/light journeys record real interaction states, existing product failures and precise unverified conditions.**

## Performance

- **Started:** approximately 2026-10-09T03:08:00Z, from this execution interval.
- **Completion checks:** 2026-10-09T03:39:28Z; summary closeout approximately 03:40Z.
- **Duration:** approximately 32 minutes.
- **Tasks:** 2/2 accepted.
- **Files changed:** nine task-owned source/fixture/index files, plus this summary.
- **Actuals:** 61,430 characters in the scoped ledger-base-to-task-GREEN diff, rounded up at chars/4 = 15,358. Four task/TDD commits measured from the persisted ledger before this separate summary commit; capture-time HEAD remains distinct from committed HEAD.

## Accomplishments

- Exact router-derived eleven-path inventory with independent equality checking, stable capture IDs and documented seed role/scope. AuditTransaction and its tickets AuditChange resolve transaction, direct row and drawer paths; service-account ActorRef resolves the actor route. The degraded Timeline is an extra state, never another route.
- Eleven separately named browser tests directly enter each route at desktop/intermediate/narrow widths, checking intended mounted content. The final bundle contains 33 route cells and one degraded twin: 68 PNGs, 34 observations and 33 scorecards, totaling 135 hashed outputs. Existing useful scorecard fields are preserved.
- Eleven focused state tests execute in each of two separately compiled theme lanes. Each lane supplies 21 observed cells/63 outputs across twelve manifests. Tests distinguish pending/empty/error/status, real HTTP denial, Copy, disconnect/reconnect, keyboard/focus/touch, long values, preferred/effective theme and reduced motion without asserting that recorded product failures are acceptable.
- A small committed evidence index records exact retained directories, all individual manifest hashes, output-set hashes, source identity, ranked findings and acceptance limitations. No raw screenshot/DOM/trace set was bulk-added.

The frontmatter copies this plan's required `[UIB-01, UIB-02]` IDs verbatim. This summary establishes **only plan 02's contribution** to those shared requirements. Plan 03 still owns the live preview and classified inventory; no complete UIB/milestone acceptance claim is made.

## Task Commits

1. **Task 1: RED** `1ab560f63a07299e1dd7c7226b7c76da24ebd3a1` — `test(238-02): require exact independently grounded eleven-route inventory`.
2. **Task 1: GREEN** `322f84ee5fa4782e05d43ebb823763b461483289` — `feat(238-02): capture eleven direct operator routes with source-bound shell evidence`.
3. **Task 2: RED** `aed99dfad3efdc536f06f0c2622b1344f01ef201` — `test(238-02): expose System runner project-selector pollution`.
4. **Task 2: GREEN** `27c3b04391bd6dbdf80c8db24a76db294373d96c` — `feat(238-02): record bounded dark and System state evidence with final route custody`.

5. **Task 2: Integration boundary fix** — `e36bd1f84332e7fea1145714652f272b512fbf2f` separates the two exact generic source-inventory filenames from the frozen rendered corpus. Fifteen focused tests pass, including an unknown-reference negative control. All 427 existing reference bytes and manifest entries remain unchanged.

**Plan metadata:** Separate summary-only commit after these checks. Each known scoped commit was appended to the delegated local receipt only after exact prefix/scope validation. Base stayed fixed at `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`.

## Files Created/Modified

- `test/fixtures/operator_surface/route-inventory.json` — exact router surface, deterministic seed references and distinct degraded-state metadata.
- `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` — independently read router equality and real System runner argument contract.
- `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` — reusable login/seed resolution, uncached awaited served bytes, verified inline CSS, shell/content/allowlisted observations and contained output hashing.
- `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` — includes route-inventory bytes in relevant source identity; existing strict integrity checks remain intact.
- `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` — individual direct routes, three-width cells, preserved scorecards and strict final aggregation; legacy reference writer remains available with evidence mode off.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` — bounded observed-state journeys with truthful failure/limitation records.
- `examples/threadline_phoenix/e2e/playwright.config.ts` — retains existing light matches, adds state spec, sets reduced motion through supported route-project context options.
- `examples/threadline_phoenix/e2e/run-e2e.sh` — forwards explicit selectors without injecting another light selector, retaining default System alias behavior and original guard/cleanup boundaries.
- `238-EVIDENCE-INDEX.md` — durable small custody handoff; raw generated bundles remain in the retained isolated worktree.

`examples/threadline_phoenix/e2e/` paths above are under `examples/threadline_phoenix/`; planning index/summary are under this phase directory.

## Evidence and Verification

Accepted directories under `examples/threadline_phoenix/e2e/artifacts/operator-evidence/`:

- **Final routes:** `operator_routes_final_1791516878_82721`. 11 distinct route tests + degraded twin passed, 1 legacy reference writer intentionally mode-skipped; runtime 27.7s.
- **Dark states:** `operator_states_1791516768_67927`. 11 intended tests passed, none skipped; runtime 9.0s.
- **System/light states:** `operator_system_light_1791516801_73894`. 11 intended tests passed, none skipped; runtime 9.1s. Initial checked preference/mounted attribute are System and computed effective theme is light; background is `rgb(247, 249, 252)`.

All three actual named Mix runs used `THREADLINE_E2E_EVIDENCE=1`, their unique `operator_` partitions and `PATH=/tmp/threadline-238-bin:$PATH` for installed Bash 5. Each also passed the existing 21 unit preflight tests. No Cartesian browser expansion was run.

- Final route manifest SHA-256: `29c9d02eb80a2130b22908c64929bf5c0208de1a4bfeb07a3efe6081a03c46d4`.
- Capture-time HEAD: `aed99dfad3efdc536f06f0c2622b1344f01ef201`; relevant diff digest: `78db5478e57c8cb41ec16d673ecd360ceace786dc51a99f610440131386517b8`. Post-GREEN check at `27c3b04391bd6dbdf80c8db24a76db294373d96c` proves identical effective source bytes/modes/digest across all accepted bundles.
- Strict serialization and all 261 unique output byte hashes across route/dark/light bundles passed. Every referenced CSS/JavaScript served hash matches current local asset bytes, including all nine inline operator CSS segments. Fixture identity agrees across fresh partitions; all relevant source entries agree with the current candidate.
- 18 focused evidence/source/asset/output/runner/route contracts passed, zero skipped/failed. Runner tests include ordinary and default System forwarding, explicit selector preservation, target safety, read-only references and exact ancestry/context tamper rejection.
- Scoped TypeScript check of new helper, route contract and state spec passed; Bash 5 syntax and `git diff --check` passed. A repository-wide TypeScript cleanup was not needed for this evidence-only scope.
- GSD `check evaluation-scope --plan 238-02 --commits-only --raw` resolved all four task commits on this branch. File existence and ancestry self-checks passed; task ledger gives four measured commits.
- Representative final PNGs were actually inspected: dark home 375, coverage 768, drawer 375, Exports 1280, dark empty/long Timeline 375, and System/light initial home. These show real mounted shell/content; inspection informs classification candidates rather than certifying final design quality.
- Product rendering source, routes/auth/public API/tenant scope and existing reference fixtures have no plan diff. Copied context still matches its receipt, including the original isolated `use_worktrees` override. No copied planning/config/AGENTS/PRODUCT inputs were staged.

## Observed Findings and Limitations

Both state lanes agree on three fresh-entry Copy failures: Evidence, Exports and Retention have no delegated binding and do not produce the exact copied value. Timeline exact-copy succeeds as a positive control. Export queue controls stay enabled while LiveView is disconnected; pointer and keyboard activation each produce zero observed new jobs after reconnect, with no duplicate job observed and no completion claim. The long-filter empty Timeline at 375px has document scroll width 1928 dark / 1924 light, visibly clipping controls and the active-filter summary. These are ranked high in the index for Phases 240–242.

The final narrow drawer PNG shows its heading/Close area beneath the shell header/navigation; the index carries this medium classification candidate for confirmation in the live preview. Computed paper/ink tokens are empty in both initial themes while background/text resolve; this is medium token/test debt for Phase 239, not a blanket visible contrast finding. The inspected home/coverage wording (“Check audit readiness”, “Coverage”, “Audit coverage”) is retained as a low terminology candidate, without a comprehensive consistency pass.

Positive observations include actual delayed-query loading followed by a real empty result, seeded export pending/failed/completed/unavailable groups, invalid-subject alert, separate host HTTP 403 under Acme support, working Light/Dark/System submissions, reduced-motion media plus home card duration `0.001s`, retention modal focus/return, and 375px emulated touch navigation.

**Actual browser-chrome 200% zoom remains unverified.** Computer Use denied access to the exact installed Google Chrome for Testing app: “Computer Use was not approved to use Google Chrome for Testing”. No visible browser UI zoom setting was observed. Viewport/DPR/CSS screenshot scale and manifest compatibility `input.zoom=1` are not browser-zoom proof; every capture condition explicitly records unverified zoom. This is the plan's permitted explicit acceptance limitation.

**Clipboard denial/unavailability remains unverified.** Clearing permissions and context-specific CDP denied configuration still reports `prompt`. Subsequent copied feedback does not prove Clipboard API denial or failed legacy fallback. Unbound fresh-entry controls never attempt clipboard access. No missing-API/fallback failure was fabricated; the actual probe and specific limitation are retained. Real host HTTP 403 is separate authorization proof.

Other bounds are explicit in the index: Exports, not every Timeline mutation control, was sampled offline; newly queued worker completion is not observed; motion proof is representative, focus proof is retention-specific, touch is emulated; no physical device, Safari/Firefox, full keyboard audit or every route/theme/state combination is claimed. The intentional legacy-reference skip protects immutable references and is not missing route discovery.

## TDD Gate Compliance

- **Task 1: RED** `route inventory exactly matches the independently read eleven router paths` actually executed and failed the planned equality assertion because the fixture was absent; it did not fail discovery/syntax/setup. Actual TAP and record are retained at `examples/threadline_phoenix/e2e/artifacts/operator-evidence/red-238-02-task1.json`. GSD returned `RED_EVIDENCE_OK`; semantic inspection confirmed the intended assertion failure.
- **Task 1: GREEN** independently grounded fixture/seed mapping and browser expansion pass exact equality and all eleven route captures. No reference fixture was overwritten.
- **Task 2: RED** `System runner preserves an explicit project selector without adding its default` actually executed against the real runner argument probe. Of two tests, one passed and this target failed: expected only explicit `--project=route-capture`, observed an added `--project=desktop-chromium-light`. Actual TAP record is `examples/threadline_phoenix/e2e/artifacts/operator-evidence/red-238-02-task2.json`; GSD returned `RED_EVIDENCE_OK`, with semantic assessment of the string-equality failure.
- **Task 2: GREEN** project forwarding contract and all existing runner contracts pass; both nonzero state lanes and final route recapture pass after the final tooling edit.
- **REFACTOR:** no additional refactor commit was necessary. Each task has an executed RED commit followed by its verified GREEN commit.

## Decisions Made

Use one reusable capture helper to retain strict source/asset/output proof across a finite matrix. Let browser observations expose product failures instead of changing the UI in this phase. Compute effective theme independently from preference/mounted attribute. Preserve capture-time HEAD honestly and verify identical bytes after committing. Retain all accepted raw bundles locally and transfer only the small index/receipt through the parent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Capture expansion required reusable helper and fixture source identity**
- **Found during:** Task 1.
- **Issue:** Repeating the home-only recorder across route/state tests would duplicate integrity logic; the new route fixture was not in the relevant source digest. Seed row-history links also include an `as_of` query, so a pathname-only regex applied to the entire URL rejected a valid fixture link.
- **Fix:** Extracted source-bound capture into the reusable helper, included the fixture in source enumeration, resolved scalar row identity from URL pathname while retaining the drawer query, and placed Playwright trace configuration at supported top-level scope.
- **Files:** browser helper, evidence manifest helper, route capture spec, inventory fixture.
- **Verification:** independent route contract, strict provenance tests, all eleven direct captures and final custody checks.
- **Commit:** `322f84ee` (Task 1 GREEN).

**2. [Rule 1 - Bug] State/capture appearance and reduced-motion configuration needed runtime-correct facts**
- **Found during:** Task 2.
- **Issue:** A mounted `system` attribute is not effective light/dark; this installed Playwright exposes reduced motion through `contextOptions` in test/project use rather than a direct fixture option. The initial direct option did not establish media reduction for all captures.
- **Fix:** Recorded mounted theme separately from computed color scheme, used supported context options for the owned state suite and route project, retained an actual home animation-duration assertion, then reran both state lanes and every route after the last edit.
- **Files:** browser helper, state spec, Playwright config.
- **Verification:** focused TypeScript check; observed reduced media on every final cell; dark/System-light initial theme assertions; final source/asset/output recheck.
- **Commit:** `27c3b043` (Task 2 GREEN).

**3. [Rule 3 - Blocking] Parent-synced planning bytes had stale receipt hashes**
- **Found during:** Task 1 preflight, before browser reset.
- **Issue:** Receipt retained pre-plan-01 STATE/ROADMAP hashes after parent synchronized plan-01 completion bytes. Strict preflight rejected those mismatches.
- **Fix:** Independently verified both local files matched the original planning checkout, then reconciled only their local receipt hash entries, preserving prior values and the reconciliation reason. No context files changed, no guard was weakened, and immutable base/exact prior commit prefix remained fixed.
- **Verification:** every subsequent runner preflight and final custody check accepted exact context/ancestry. The receipt's separately documented config override was honored, not modified.
- **Commit:** none; explicitly delegated local receipt maintenance, retained as a parent-synchronized operational artifact.

**Total deviations:** three auto-fixed clusters (two Rule 3, one Rule 1). Helper/config changes are evidence dependencies; product UI and unrelated edits remain preserved. Runner selector correction and explicit zoom/clipboard limitations were planned work, not scope expansion.

## Issues Encountered

Unsupported real-zoom control and clipboard-denial configuration are carried as precise acceptance limitations, not substitute passes. Earlier exploratory capture attempts were superseded by the three accepted final runs. Playwright regenerates `test-results`, so historical failure traces are not claimed as retained accepted evidence; final evidence disables credential-bearing traces and HTML dumps. No unresolved tooling/provenance blocker remains for this plan.

## User Setup Required

None. Existing locked dependencies and installed Chromium/Bash were used; no package additions, secrets, spend, push or publication occurred.

## Next Phase Readiness

Ready for **238-03** after the parent validates/synchronizes the receipt and evidence index. The original planning checkout is untouched; STATE/ROADMAP/REQUIREMENTS, copied context and product files were not modified by this executor. The retained worktree and raw evidence remain available. Parent must carry ranked findings and unresolved actual zoom/clipboard denial into classification. This executor stops at plan 02 and does not launch plan 03.

## Self-Check: PASSED

- Both tasks satisfy their acceptance criteria with real nonzero browser discovery and exact eleven-route inventory.
- All nine owned task source/fixture/index files exist, all four task commits are reachable, and GSD evaluation scope resolved them on this branch.
- Accepted final routes and both state lanes share the current effective source digest; every output and served asset hash passed after Task 2 GREEN.
- Actual System preference/effective light and representative reduced-motion/focus/touch/denial facts are asserted; unsupported zoom/clipboard conditions are explicitly limited.
- Representative final PNGs were inspected; existing product findings were recorded without UI fixes.
- No product/reference/copy-context drift, unrelated staged files, generated screenshot commits or destructive git/worktree operations occurred. Exact receipt prefix and immutable base remain valid.
