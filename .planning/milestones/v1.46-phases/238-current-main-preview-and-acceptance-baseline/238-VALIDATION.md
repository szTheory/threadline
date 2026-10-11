---
phase: "238"
slug: "current-main-preview-and-acceptance-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-08"
---

# Phase 238 — Validation Strategy

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Existing ExUnit and Playwright Test; resolve versions from isolated current main |
| Config | `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick check | `examples/threadline_phoenix/e2e/node_modules/.bin/tsx --test examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts`; clean-checkout `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs` uses only committed generic fixtures and source anchors |
| Existing discovery | From `examples/threadline_phoenix/e2e`: `./node_modules/.bin/playwright test --list` |
| Browser suite | Evidence mode uses `THREADLINE_E2E_EVIDENCE=1` and a unique `MIX_TEST_PARTITION`; `mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts` and `mix verify.example_browser_light --project=desktop-chromium-light operator-route-states.spec.ts` each require nonzero intended tests; ordinary aliases/CI retain their invocation behavior |
| Capture suite | Evidence mode uses a unique `MIX_TEST_PARTITION`; `mix verify.example_browser --project=route-capture operator-page-capture.spec.ts` (runner forwarding and exact test discovery are gates) |
| Feedback target | Fast artifact/contract checks under 30 seconds; browser batch latency measured separately |

## Sampling Rate

- After each tooling task: run its focused contract and inspect the changed-file diff.
- For each capture batch: run targeted browser evidence in a fresh output directory against an isolated synthetic database; validate source, asset and fixture identity.
- At the phase gate: validate all eleven routes, every inventory disposition, non-overwriting reference baselines and bounded rendered review. Run relevant named browser/component checks once; do not repeatedly run unrelated suites.
- A passing metadata contract or successful test discovery is not rendered proof. A passing browser exit with missing/zero intended tests is not acceptance.

## Per-Task Verification Map

The first row is an **orchestrator-owned blocking prerequisite**, not a task inside the stale checkout. All commands below run from the isolated current-main worktree after that gate. Evidence-mode browser commands require a new unique partition, derived test DB target check and loopback port before any reset; existing normal browser aliases and CI callers retain their safe default invocation. The immutable refreshed-main SHA is an ancestry anchor; each atomic task commit advances the candidate HEAD and updates the receipt plus relevant binary diff digest. `fails_when` in each PLAN task names the observable nonzero/zero-test/identity failure signal. All six tasks and the isolation prerequisite have executed. See the summaries, final evidence index and integration notes for command results and limits.

| Task / wave | Requirement | Secure behavior and threat refs | Automated command or executable gate | Observable failure signal | Status |
|---|---|---|---|---|---|
| Isolation prerequisite / before Wave 1 | UIB-01 | GSD `worktree create --base <fresh origin/main SHA>` and concrete `inspect-dispatch-isolation --cwd-target`; copied approved context byte hashes including preflight/research/guide/AGENTS; T-238-02 | Execute-phase checks original-checkout `238-WORKTREE-MANIFEST.json`, immutable base ancestry, expected task commits, adapter descriptor, context-copy hashes and matching `238-ISOLATION-RECEIPT.json` copies before dispatch | Unexpected candidate commit or diff, changed original dirty byte hash, missing context or Codex cwd descriptor blocks implementation | Passed |
| 238-01 Task 1 / Wave 1 | UIB-01 | One safe, authenticated, source/asset-bound full-shell capture; T-238-01/02/03 | `THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_baseline_$(date +%s)_$$ mix verify.example_browser --project=route-capture operator-page-capture.spec.ts --grep "home"` | Reset before evidence-mode test-target check, zero intended browser tests, invalid output/hash/asset mapping or nonzero exit | Passed |
| 238-01 Task 2 / Wave 1 | UIB-01 | Manifest negative controls, no reference mutation/secrets; T-238-01/02/03 | `examples/threadline_phoenix/e2e/node_modules/.bin/tsx --test examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts` | Zero tests or known-bad mutation passes | Passed |
| 238-02 Task 1 / Wave 2 | UIB-01, UIB-02 | Eleven exact direct-entry route patterns and full-shell widths; T-238-04/05 | `THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_routes_$(date +%s)_$$ mix verify.example_browser --project=route-capture operator-page-capture.spec.ts` | Under eleven distinct route tests, bad seed path, missing shell, hash mismatch or reference overwrite | Passed |
| 238-02 Task 2 / Wave 2 | UIB-01, UIB-02 | Real state/theme/input probes, truthful actual zoom/limitation and durable small index; T-238-04/05 | `THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_states_$(date +%s)_$$ mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts` **and** `THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_system_light_$(date +%s)_$$ mix verify.example_browser_light --project=desktop-chromium-light operator-route-states.spec.ts`; after final tooling edits rerun all routes with a third unique partition and `--project=route-capture`; orchestrator syncs final-candidate evidence index | Either state lane has zero tests or fails, final route run has fewer than eleven intended tests or stale candidate digest, System/light mount/effective theme unproved, mislabeled state/zoom, absent limitation, source/asset mismatch or missing index | Passed |
| 238-03 Task 1 / Wave 3 | UIB-02 | Source/test declaration scan reconciled to generic checklist and inventory; preflight candidates reconciled to phase findings; T-238-06/07 | Plain `mix test test/threadline/operator_surface/operator_evidence_contract_test.exs` uses committed static inputs and scans source/test declarations; explicit live mode supplies manifest and findings paths from `238-EVIDENCE-INDEX.md` and fails on missing evidence | Zero static tests, unmapped route/component/control/state declaration, missing/duplicate generic ID or source anchor; live mode missing finding/disposition/manifest, invalid hash or source-only defect assertion | Passed |
| 238-03 Task 2 / Wave 3 | UIB-01, UIB-02 | Live guarded loopback preview and durable evidence custody; T-238-01/07/08 | Explicit `THREADLINE_OPERATOR_EVIDENCE_MODE=live THREADLINE_OPERATOR_PREVIEW_REQUIRED=1` contract with manifest path from index and preview receipt path; local URL/PID/readiness and dirty-file hash check | Missing/changed preview identity, dead or non-loopback server, bad inventory, baseline mutation or nonzero exit | Passed |

## Wave 0 Requirements

- [x] 238-01 orchestrator prerequisite creates supported isolated worktree and context-transfer receipt without modifying the original dirty config.
- [x] 238-01 Tasks 1–2 create focused manifest contract, guarded unique-partition fixture target, one real full-shell tracer and preview lifecycle mode; all targets are created before their commands run.
- [x] 238-02 Tasks 1–2 cover all eleven routes, bounded conditions and actual browser-chrome zoom probe with honest limitation semantics.
- [x] 238-03 Task 1 creates generic source/test checklist and inventory fixtures, a clean-checkout domain-named contract, explicit fail-closed live-evidence mode, and exhaustive phase findings; Task 2 leaves a usable preview and custody index.

## Agent Review and Limitations

Bounded visual review is performed by the agent against source-bound renders. No routine human UAT or paid critic is required. Keyboard/touch, theme, failure and reconnect states require actual browser evidence or explicit coverage limitations. Any unobserved state remains unobserved; it cannot be called passed. Baseline classification may record a limitation without claiming later refinement acceptance is satisfied.

## Validation Sign-Off

- [x] All tasks have runnable verification or explicit Wave 0 dependencies.
- [x] Commands include observable failure signals and cannot pass on zero tests.
- [x] No three consecutive tasks lack automated verification.
- [x] Wave 0 supplies every missing verification target.
- [x] Normal verification leaves baseline files unchanged.
- [x] Execution evidence justifies any future `nyquist_compliant: true` or `wave_0_complete: true` value.

## Source and edge coverage audit

| Source | Item | Planned coverage |
|---|---|---|
| GOAL | Reproducible current-main preview and rendered classification before UI source fixes | 238-01 tracer, 238-02 route/state expansion, 238-03 inventory and preview |
| REQ | UIB-01 | 238-01, 238-02, 238-03 |
| REQ | UIB-02 | 238-02, 238-03 |
| RESEARCH | GSD explicit-base isolation, Codex cwd adapter, copied context, safety receipt | 238-01 orchestrator prerequisite |
| RESEARCH | Unique test DB/loopback fixture, seed identity, non-overwriting output | 238-01 Tasks 1–2; 238-03 Task 2 |
| RESEARCH | Eleven routes, full shell, widths, themes, real interaction/zoom states | 238-02 Tasks 1–2 |
| RESEARCH | Runtime Playwright identity, served asset hashes and capture integrity | 238-01 Tasks 1–2; 238-02 Task 1 |
| RESEARCH | Independently source/test-grounded route/control/state checklist, generic inventory, linked phase findings, preflight candidates | 238-03 Task 1 |
| CONTEXT | D-01, D-02 | 238-01 prerequisite/Tasks 1–2; 238-03 Task 2 |
| CONTEXT | D-03, D-04, D-05 | 238-02 Tasks 1–2; 238-03 Task 1 |
| CONTEXT | D-06, D-07, D-08 | 238-02 Tasks 1–2; 238-03 Tasks 1–2 |

The deterministic spec-less edge probe supplied six applicable rows. UIB-01 adjacency/empty/ordering appear as explicit truths in 238-01; UIB-02 adjacency/empty/ordering appear as explicit truths in 238-03. Six surfaced, six authored; none dismissed. Prohibition recall retains the bespoke no-historical-defect, no-user-data-fixture and no-false-coverage rules in `must_haves.prohibitions`, descriptor-less and flagged for judgment; generic security concerns are assigned to the threat model. Actual browser-chrome zoom remains a named execution uncertainty, not a green claim.

**Approval:** Validated 2026-10-09 against executed commands and actual negative controls. UIB-01 and UIB-02 are COVERED for the baseline goal. All six tasks have behavior checks; there are no missing Wave 0 targets. Named coverage limitations are retained, not converted to acceptance passes.

## Executed evidence

- Isolation: exact base/branch/first-parent ancestry, copied context and original dirty-byte hashes verified after each scoped commit.
- 238-01: actual home shell/content tracer; manifest/target mutations. The final Node run has 23 passing tests on both Bash 3 and Bash 5 including guarded stop regressions.
- 238-02: all eleven direct routes at 1280/768/375 plus degraded Timeline; 12 passes and one intentional legacy-reference-writer skip. Dark and System/light state lanes each have 11 passes (final pointers in evidence index).
- 238-03: independent 355-ID scan; static and clean-files-only execution, real missing-manifest/corrupt-output failures, actual preview PID/port/database/auth/deep-link/assets proof. Initial 9-test contract expanded to 10 with nested receipt regression; focused contract plus CI topology: 36 passes.
- Full phase integration after last source repair: 32 properties, 3075 tests, 0 failures, 3 standard exclusions; seed 524535. Log `/tmp/threadline-238-final-bash5-tests.log` (141.9 seconds; Bash 5 required by unchanged repository hygiene tooling).
- Browser-chrome 200% zoom, clipboard-denial behavior and cross-browser/physical-device coverage remain explicitly unverified. They are inputs to later refinement acceptance, not baseline coverage holes disguised as passes.

No maintainer UAT is required; bounded visual judgment is assigned to agent UI review.

## Validation Audit 2026-10-09

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Final review: all four findings resolved and independently rechecked. Partial focused browser selection passes 1/1; full route/state lanes remain 12/11/11. Live 10/10 now includes selected-manifest renamed positive and actual forged metadata/output negatives. Worktree-relative paths preserve actual source/output/PID/auth verification; current live contract passes after portability cleanup.
