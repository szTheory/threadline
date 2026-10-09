---
phase: 238-current-main-preview-and-acceptance-baseline
plan: "01"
subsystem: testing
tags: [playwright, operator-ui, evidence, provenance, postgres]
requires: []
provides:
  - Authenticated home shell/content captures bound to effective source, served assets, synthetic fixture and browser identity.
  - Guarded evidence/preview fixture setup and 16 focused provenance/safety contracts.
affects: [phase-238-preview, operator-browser-evidence]
actuals:
  tokens: 13110
  tasks: 2
  commits: 5
plan_head_before: 9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2
plan_head_after: 137b0870cce78b78a0299e9405ba7a095a446f6d
tech-stack:
  added: []
  patterns: [isolated database preflight, source and served-asset manifest, contained per-run capture output, mutation-controlled integrity checks]
key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts
    - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
  modified:
    - examples/threadline_phoenix/e2e/run-e2e.sh
    - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
key-decisions:
  - Keep evidence mode opt-in; ordinary route capture skips the new home evidence test and still runs its original browser test.
  - Request uncached browser assets and await all response-body checks before publishing capture metadata.
  - Save screenshots and allowlisted metadata; omit the HTML dump containing a CSRF field.
  - Keep immutable base fixed; record effective file bytes/modes and exact expected ancestry separately from candidate HEAD.
requirements-completed: [UIB-01]
coverage:
  - id: D1
    description: Authenticated home shell/content capture with verified source, fixture, CSS/JavaScript and output identity.
    requirement: UIB-01
    verification:
      - kind: e2e
        ref: "THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_baseline_1791514752_53330 mix verify.example_browser --project=route-capture operator-page-capture.spec.ts --grep home"
        status: pass
      - kind: other
        ref: "Strict serialization and committed-source/output hash recheck of operator_baseline_1791514752_53330/manifest.json"
        status: pass
    human_judgment: false
  - id: D2
    description: Focused negative controls reject invalid provenance, unsafe targets, secret metadata, reference writes and changed outputs while preserving ordinary runner behavior.
    requirement: UIB-01
    verification:
      - kind: unit
        ref: "examples/threadline_phoenix/e2e/node_modules/.bin/tsx --test examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts"
        status: pass
      - kind: e2e
        ref: "THREADLINE_E2E_EVIDENCE=0 MIX_TEST_PARTITION=operator_compat_<fresh> mix verify.example_browser --project=route-capture operator-page-capture.spec.ts"
        status: pass
    human_judgment: false
duration: 2h 9m
completed: 2026-10-09
status: complete
---

# Phase 238 Plan 01: Current-main preview and acceptance baseline Summary

**Authenticated home shell/content captures now bind real browser-served CSS/JavaScript to an isolated source candidate and synthetic fixture; 16 negative-control contracts fail closed on invalid evidence and reset targets.**

## Performance

- **Duration:** Approximately 2h 9m elapsed including the interruption; previous attempt reported 15m active. Resumed proof interval: 12m 37s from the first resumed browser command to closeout checks.
- **Started:** 2026-10-09T00:54:00Z (approximate, retained from the halted summary).
- **First resumed browser command:** 2026-10-09T02:50:43Z.
- **Completion checks:** 2026-10-09T03:03:20Z.
- **Tasks:** 2/2 accepted.
- **Source files modified/created:** 4.
- **Actuals:** 13,110 chars/4 tokens over the scoped base-to-candidate source diff; 5 commits measured before this closing metadata commit. The measurement includes the retained partial implementation and halted-summary commits.

## Accomplishments

- Produced a genuine authenticated `/audit` full-shell PNG and content PNG after root/content/font and connected-LiveView readiness. Both output hashes, runtime versions, observed dark preference/theme, source identity and four asset comparisons validated.
- Added strict, deterministic manifest validation and 16 behavioral contracts covering missing/forged metadata, altered asset/output bytes, duplicate IDs, equal-content records, ordered serialization, containment, reference separation, first-time tracked/untracked edits, executable modes/deletions, unsafe targets, copied-context/ancestry tampering, partition reuse and ordinary runner cleanup/forwarding.
- Proved ordinary route capture still works with evidence mode off: its original browser test passed and the home evidence test skipped intentionally. Both actual named Mix aliases retained project/spec/grep forwarding.

This is the accepted plan-01 contribution to shared UIB-01. It does **not** establish eleven-route completeness, expanded conditions, a durable live review preview or milestone acceptance; plans 238-02/03 still own that work. No requirement/state/roadmap files were updated.

## Task Commits

1. **Task 1: Retained partial implementation** `19d6a45e` — `feat(238-01): add guarded operator evidence capture`.
2. **Retained halt/recovery record:** `55c99f1d` — `docs(238-01): record halted browser acceptance`.
3. **Task 1: Acceptance fixes** `8b8e8d9b` — `fix(238-01): verify uncached home assets and effective source identity`.
4. **Task 2: RED** `486134b4` — `test(238-01): expose fail-open operator evidence metadata and target guards`.
5. **Task 2: GREEN** `137b0870` — `feat(238-01): enforce operator evidence integrity and safe target contracts`.

**Plan metadata:** Separate summary-only closing commit after all acceptance checks. No copied planning/config/product inputs were staged.

## Files Created/Modified

- `examples/threadline_phoenix/e2e/run-e2e.sh` — opt-in target/context/ancestry guards, temporary caches, preview lifecycle and scoped ignored-export cleanup.
- `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` — separately selectable home evidence capture, uncached/awaited response hashes, actual theme preference and runtime versions, seed pipeline/manifest/config digest, screenshots without session-bearing HTML.
- `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` — effective candidate path/mode/hash list, exact static asset URL mapping, allowlisted validation, stable ordering and contained output-byte verification.
- `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts` — focused metadata/source/asset/output/runner contracts using disposable synthetic roots.

## Evidence and Verification

Final bundle: `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_baseline_1791514752_53330/`.

- `home-shell.png`, `home-content.png`, `manifest.json`, `run.json` and `run-identity.json` remain local generated evidence. Output references in the final manifest are portable relative paths.
- Captured HEAD: `486134b4283248cf521343c07684989061176bb4`; effective source digest: `735b22d67de3cd76e0916bba9ec7dd7389635590a92a8da411932425f672c755`.
- Post-commit recheck proved the same effective digest at GREEN HEAD `137b0870cce78b78a0299e9405ba7a095a446f6d`. Captured HEAD remains the honest capture-time identity; committing identical bytes did not change the digest.
- Fixture scenario/version: `threadline-demo-seed` / `seed-pipeline-v1`. Seed digest: `c657f19bedf54433ef86ff0d8698b26995046cd77c07f47a83c04dad4b053a30`; semantic ID: `86a43988888299a0981077a0950599aef52016cbf05d55c3d9350a060a264029`. Identity hashes the seed modules, pipeline, scenario manifest and deterministic test configuration; generated partition/database names do not enter it.
- Asset proof: real `app.js`, `phoenix.mjs`, `phoenix_live_view.esm.js` HTTP bodies and the inline operator stylesheet each matched their exact local bytes.
- Final evidence-mode browser command: **1 intended test passed**, plus **21 existing unit preflight tests passed**. Full-shell PNG was inspected; strict final manifest serialization and both PNG hashes passed.
- Focused contract: **16 tests passed, 0 skipped, 0 failed**. Final run duration: 7.3s.
- Legacy evidence-off route capture: **1 original browser test passed, 1 intended mode-gated home test skipped**, plus **21 existing unit tests passed**. This compatibility result is not new eleven-route evidence.
- Actual `mix verify.example_browser` and `mix verify.example_browser_light` argument-only probes preserved project/spec/grep arguments; System/light selected `desktop-chromium-light`. This proves forwarding, not rendered light-theme acceptance.
- Scoped strict TypeScript checking of helper/tests, Bash syntax and `git diff --check` passed.
- No product rendering source or reference fixtures changed from the immutable base. Original initially dirty file bytes still matched the isolation receipt. Exact root, branch and expected first-parent ancestry checks passed.

Runtime: Bash **5.2.37** from the installed Homebrew Bash, Node **22.14.0**, Mix/Elixir **1.17.3**, OTP **27** (ERTS **15.2.7.11**), Playwright **1.60.0**, Chromium **148.0.7778.96**. Browser commands used normal narrow escalation; no sudo, launch-flag addition or hook bypass.

## TDD Gate Compliance

- **RED:** Actual TAP report executed 14 tests: 8 passed, 6 failed on behavioral assertions. Target `metadata proof rejects absent candidate diff identity` failed because empty digest metadata was accepted. GSD returned `RED_EVIDENCE_OK`; no discovery, syntax or fixture failure was used as RED.
- **GREEN:** Required-field, source-list/digest, fixture, asset, output and runner validation resolved those failures. Additional custody/ordinary-cleanup controls brought the final suite to 16 passing tests.
- **REFACTOR:** No separate refactor was necessary.
- Raw RED evidence: `examples/threadline_phoenix/e2e/artifacts/operator-evidence/red-evidence.json` (generated, not committed).
- The original attempt omitted the per-plan git ledger. Continuation restored its base from the saved summary after checking immutable-base and exact ancestry agreement; measured counts use that recovered per-worktree ledger.

## Decisions Made

Keep strict fixture checks opt-in, ordinary aliases compatible, source and rendered proof separate, and reference evidence read-only. Await actual uncached response bytes; never substitute a guessed source file for an unknown URL. Preserve candidate HEAD and effective bytes as separate identities. Do not persist the session-bearing HTML dump.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Writable dependency/browser caches and permitted Chromium launch**
- Original attempt encountered cache access failures and macOS Chromium launch denial, halted with 0/2 accepted tasks, and committed its recovery summary.
- Parent resolved launch permissions through normal escalation. Continuation consistently used installed Bash 5 and writable temporary caches; actual browser tests ran and passed.
- Commit: original cache setup `19d6a45e`; acceptance fixes `8b8e8d9b`.

**2. [Rule 1 - Bug] Cached JavaScript and fail-open provenance/output checks**
- The first permitted run failed because login cached JavaScript and `/audit` returned 304 responses that the recorder omitted. Effective source enumeration also missed first-time staged/unstaged tracked edits; unknown asset URLs could fall back to unrelated CSS.
- Fixed cache/await/readiness handling and exact mapping, then tightened metadata/source/fixture/output checks with real RED/GREEN negative controls.
- Commits: `8b8e8d9b`, `486134b4`, `137b0870`.

**3. [Rule 2 - Missing Critical] Honest appearance, secret-free artifact selection and cleanup**
- Read the checked preference instead of declaring System. Removed the HTML dump after observing its CSRF field. Expanded seed identity to the actual pipeline/manifest/configuration.
- Replaced the runner's inherited `git clean` cleanup with enumeration/removal of ignored export files only, honoring the worktree prohibition. A lifecycle contract verifies tracked and unrelated generated files survive.
- Commits: `8b8e8d9b`, `137b0870`.

**Total deviations:** 3 auto-fixed issue clusters (Rules 1–3). All changes remain within plan-owned evidence/runner files; product source, public APIs, dependencies and shared orchestration artifacts were preserved.

## Issues Encountered

The previous halted summary is preserved in `55c99f1d`; it was recovery history, not accepted browser proof. Normal Playwright runs regenerate `test-results`, so earlier failure traces are not claimed as current retained evidence. Accepted captures live separately under their unique generated run directories. No unresolved plan-01 acceptance blocker remains.

## User Setup Required

None.

## Next Phase Readiness

Ready for **238-02** after the parent validates ancestry/candidate identity and synchronizes the small receipt to the original planning checkout. Local expected ancestry now includes every known scoped commit; immutable base stays fixed. The parent owns sync and STATE/ROADMAP/requirement advancement. This executor stops at plan 01; no push, publication, branch change or further plan was performed.

## Self-Check: PASSED

- Both task acceptance gates passed with nonzero intended tests and meaningful negative controls.
- Four owned source files and both final screenshot outputs exist.
- All five retained/production/TDD commits are reachable on this branch; evaluation scope resolved.
- Final capture digest matches committed source; strict manifest, asset and output checks passed.
- Product/reference diff is empty and original dirty byte hashes match.
- Summary coverage is backed by passing automated proof; remaining eleven-route/preview work is explicitly reserved for sibling plans.
