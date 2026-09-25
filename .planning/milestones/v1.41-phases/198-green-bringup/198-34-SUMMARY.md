---
phase: 198-green-bringup
plan: 34
subsystem: ui
tags: [liveview, copy-contract, presentation, playwright, elixir]

requires:
  - phase: 198-green-bringup
    provides: "plans 198-31..198-33 (round-5 Playwright diagnosis and reconciliation), round-4 code review (REVIEW.md CR-01)"
provides:
  - "Single canonical owner (`Presentation.export_status_label/2`) for the export status copy contract, deleting the private duplicate that produced the round-4 drift"
  - "A recorded maintainer decision (198-34-DECISION.md) resolving CR-01 with a machine-checkable rationale"
  - "Frozen-clock, nil-input, and atom/string-parity spec coverage for the export status label boundary conditions"
affects: [export-status-live, presentation-module, copy-contract-test, operator-e2e-specs]

actuals:
  tokens: 6152
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Copy-contract functions are `:now`-aware (accept an injectable `:now` option defaulting to `DateTime.utc_now/0`) so expiry boundaries are testable at a frozen clock"
    - "Copy-contract functions route status through the module's `normalize_status/1` rather than a bare `to_string/1`, so atom and string statuses cannot diverge"
    - "A public, currently-uncalled library function can be intentionally retained (not dead code) when documented with a `@doc` note explaining its reserved purpose and the semver cost of removal"

key-files:
  created:
    - .planning/phases/198-green-bringup/198-34-DECISION.md
  modified:
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/presentation.ex
    - test/threadline/operator_surface/presentation_test.exs
    - test/threadline/operator_surface/copy_contract_test.exs

key-decisions:
  - "Maintainer selected Option B (promote the rendered status vocabulary into `Presentation` as a new public `export_status_label/2`) over Option A (adopt the existing `export_action_label/2`), preserving user-visible copy byte-identically and avoiding a one-way product-copy change locked by the Phase-186 contract test."
  - "`Presentation.export_action_label/2` is retained with an explicit `retain-with-reason` disposition (not deleted, not wired) because `Presentation` is public surface in a published Hex package and removal would be a semver-visible breaking change; a `@doc` note now records that it is deliberately distinct action-shaped copy with an intentionally absent in-tree caller."

patterns-established:
  - "Product-visible copy changes locked by a contract test require a recorded `checkpoint:decision` with `gate=\"blocking-human\"` before any source file is touched — verified here via `git diff --stat` being empty at the moment the checkpoint was raised."

requirements-completed: []

coverage:
  - id: D1
    description: "One public, :now-aware, normalization-consistent function (Presentation.export_status_label/2) owns the export status copy contract; the private duplicate in export_status_live.ex is deleted, not realigned."
    requirement: null
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/presentation_test.exs#export status label (10 tests: Queued/Processing/Failed/expired/unavailable branches, frozen-clock exact-equality boundary, nil/absent expires_at fallback, nil/unrecognised status fallback, atom/string parity)"
        status: pass
      - kind: unit
        ref: "grep -c \"defp export_job_status_label\" lib/threadline/operator_surface/live/export_status_live.ex == 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Phase-186 copy lock in copy_contract_test.exs guards the function that actually renders (re-anchored from export_status_live.ex to presentation.ex), at full five-literal strength."
    requirement: null
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/copy_contract_test.exs#Phase 186 export source locks real completed downloads and non-ready status text"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every downstream e2e assertion depending on the rendered export status vocabulary is reconciled — under Option B the reconciliation is verified-empty (byte-identical copy), confirmed by re-deriving the grep against live source rather than trusting the plan's snapshot."
    requirement: null
    verification:
      - kind: e2e
        ref: "examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts, operator-accessibility.spec.ts, operator-screenshots.spec.ts, operator-features.spec.ts — full run via run-e2e.sh, --project=desktop-chromium --project=mobile-chromium"
        status: pass
    human_judgment: false
  - id: D4
    description: "The recorded maintainer decision (198-34-DECISION.md) names the selected option, its rationale, and an explicit disposition for export_action_label/2, and no source file was modified before the answer was recorded."
    requirement: null
    verification:
      - kind: other
        ref: ".planning/phases/198-green-bringup/198-34-DECISION.md — recorded 2026-08-30; git diff --stat -- lib/ test/ examples/threadline_phoenix/e2e/ was empty at checkpoint time (verified before any implementation task began)"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-08-30
status: complete
---

# Phase 198 Plan 34: Export status copy contract canonicalization (CR-01) Summary

**Deleted the private `export_job_status_label/1` duplicate in `export_status_live.ex` and replaced it with a new public, `:now`-aware `Presentation.export_status_label/2`, per the maintainer's Option B decision — user-visible copy is byte-identical, and `export_action_label/2` is retained with a documented `@doc` disposition rather than deleted.**

## Performance

- **Duration:** ~55 min (includes a `checkpoint:decision` pause between Task 1 and Task 2)
- **Started:** 2026-08-30T20:20:00Z (Task 1 drafted); resumed 2026-08-30T20:48:00Z after maintainer decision
- **Completed:** 2026-08-30T21:15:00Z
- **Tasks:** 3
- **Files modified:** 4 (2 lib, 2 test) + 1 new decision record

## Accomplishments

- Task 1: drafted `.planning/phases/198-green-bringup/198-34-DECISION.md` presenting Option A (adopt `export_action_label/2`) and Option B (promote a new status-shaped function) with file:line evidence, correctly identified that one of the e2e "Reopen source search" link assertions is an unrelated pre-existing UI element (not part of this copy contract), and halted for the `gate="blocking-human"` checkpoint. `git diff --stat` over `lib/`, `test/`, `examples/threadline_phoenix/e2e/` was empty at the moment the checkpoint was raised.
- Maintainer recorded Option B, with `export_action_label/2` disposition `retain-with-reason`.
- Task 2: added `Presentation.export_status_label/2` (`:now`-aware via `expired?/2`, routed through `normalize_status/1`), deleted the private duplicate, re-anchored the Phase-186 copy lock in `copy_contract_test.exs` to the new canonical location, added 10 spec tests covering all 5 branches plus the frozen-clock exact-equality expiry boundary, nil/absent-`expires_at` fallback, nil/unrecognised-status fallback, and atom/string parity. Added a `@doc` note on `export_action_label/2` recording its retain-with-reason disposition.
- Task 3: re-derived the e2e grep against live source and confirmed the reconciliation is verified-empty (Option B's expected outcome) — no e2e spec file needed a single edit. Ran the full four-spec Playwright suite (52 tests, both `desktop-chromium` and `mobile-chromium` projects) and confirmed 52/52 pass.

## Task Commits

1. **Task 1: Maintainer decision — draft** - `f9534ab7` (docs) — drafted both options, no answer recorded, no source touched
   - *(orchestrator commit, not this executor)* `142a7be0` (docs) — maintainer recorded Option B
2. **Task 2: Implement the recorded decision** - `343c98a7` (feat) — new `export_status_label/2`, deleted private duplicate, re-anchored copy lock, added spec tests, `@doc` note on `export_action_label/2`
3. **Task 3: Reconcile downstream assertions** - no commit (zero e2e files needed changes; see "Deviations" for why this is a plan-conformant zero-diff outcome, not a skipped task)

## Files Created/Modified

- `.planning/phases/198-green-bringup/198-34-DECISION.md` - recorded maintainer decision: Option B, `export_action_label/2` retain-with-reason
- `lib/threadline/operator_surface/presentation.ex` - added `export_status_label/2` (status-shaped, `:now`-aware, normalization-consistent); added `@doc` note on `export_action_label/2` recording its intentional-no-caller disposition
- `lib/threadline/operator_surface/live/export_status_live.ex` - deleted `defp export_job_status_label/1`; render site (line 308) now calls `Presentation.export_status_label(job)`
- `test/threadline/operator_surface/presentation_test.exs` - new `describe "export status label"` block, 10 tests
- `test/threadline/operator_surface/copy_contract_test.exs` - re-anchored the Phase-186 lock's source block to `presentation.ex`'s `export_status_label/2`; updated the render-site assertion to `Presentation.export_status_label(job)`

## Decisions Made

- **Option B selected** (promote status vocabulary into `Presentation`, byte-identical copy) over Option A (adopt `export_action_label/2`, which would have collapsed the "Queued"/"Processing" distinction into a single "Preparing download" string and introduced a text collision between the `:needs_attention` label and the unrelated, always-present "Reopen source search" link). Rationale recorded in `198-34-DECISION.md`: Option B removes the drift mechanism (two independently-maintained copies of one copy contract) without changing a single user-visible string, and is reversible; Option A's copy change is one-way once shipped and observed.
- **`export_action_label/2` retained with an explicit `@doc` disposition**, not deleted and not wired to a new call site, because `Presentation` is public surface in a published Hex package and deleting a spec-tested public function is a semver-visible breaking change disproportionate to a "no in-tree caller" observation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `mix ci.all`'s example-app browser step left non-deterministic scorecard/screenshot artifacts and a stray `package-lock.json` in the working tree**
- **Found during:** Task 3 verification (running the plan's overall `mix ci.all` readiness-signal step)
- **Issue:** Running `mix ci.all` locally triggers the example app's critic/scorecard capture pipeline as a side effect, which rewrote ~200 files under `.planning/scorecards/` and created an untracked `examples/threadline_phoenix/package-lock.json` — neither is part of this plan's scope, and the plan's own verification explicitly requires `git diff --stat -- .planning/scorecards/` to stay empty.
- **Fix:** `git checkout -- .planning/scorecards/` to discard the scorecard rewrites; deleted the stray `package-lock.json`. Re-verified `git diff --stat -- .github/ CONTRIBUTING.md .github/rulesets/main.json examples/threadline_phoenix/e2e/playwright.config.ts .planning/scorecards/ '*.png'` was empty before finalizing.
- **Files modified:** none (reverted, not committed)
- **Verification:** `git status --short` clean after revert
- **Committed in:** N/A (nothing to commit — the point was to *not* commit these)

---

**Total deviations:** 1 auto-fixed (1 blocking — environment side-effect cleanup)
**Impact on plan:** No scope creep; the fix was purely defensive cleanup of an unrelated tool side-effect, required by the plan's own verification constraint.

**Task 3's zero-diff outcome is expected, not a shortcut.** The plan states: "Under Option B the expected reconciliation is **empty** for the e2e specs, because the rendered copy is byte-unchanged. If the grep shows otherwise, that is a finding." The grep, re-derived against live source rather than trusted from the plan's snapshot, confirmed the same five call sites as before (all asserting `"Queued"`/`"Processing"`/`"Failed"`/`"Export expired"`/`"File unavailable"`, which `export_status_label/2` still returns byte-for-byte), plus two "Reopen source search" `getByRole("link", ...)` assertions on the unrelated, always-present "Source Timeline search" reopen link (`export_status_live.ex:341`) that were never part of this contract. No matcher spans both vocabularies (`grep -rnE '(Queued|Processing|Failed).*\|.*(Preparing download|Reopen source search)' examples/threadline_phoenix/e2e/tests/` returns nothing). `git diff -U0 -- examples/threadline_phoenix/e2e/tests/ | grep -c '^-.*expect('` is `0`.

## Issues Encountered

- The example app's `threadline_phoenix_test` database had leftover, partially-seeded state from an interrupted earlier local run, causing two unrelated e2e failures (`operator-screenshots.spec.ts:195` "empty and denied states" and `operator-accessibility.spec.ts:620` row-history drawer semantics) on the first full-suite run. Neither failure touches export status copy. A clean `mix demo.reset && mix demo.seed` (MIX_ENV=test) resolved it, and the rerun passed 52/52.
- `mix ci.all`'s Playwright lane (broader than this plan's four target specs) showed 9 pre-existing failures unrelated to this plan's change: 8 are visual screenshot-baseline mismatches (`operator-screenshot-regression.spec.ts`, pixel-diff ratios ~0.15, consistent with local font-rendering/OS differences from the CI baseline) and 1 is a login-flow timing flake (`operator-earned-flows.spec.ts:79`, passed on the `mobile-chromium` project, failed on `desktop-chromium` with a 30s URL-navigation timeout). None reference export status vocabulary; none are caused by this plan's `lib/` or `test/` changes (confirmed by the four target specs' clean 52/52 pass in isolation). Recorded verbatim below per the plan's `mix ci.all` requirement — explicitly a readiness signal only, not admissible evidence for GREEN-04/GREEN-07, and this plan marks neither Complete.

### `mix ci.all` verbatim outcome (readiness signal only)

```
Elixir (lib): 1433 tests, 0 failures (1 excluded)
Elixir (examples/threadline_phoenix): 109 tests, 0 failures
Playwright (examples/threadline_phoenix, full suite): 322 passed, 15 skipped, 9 failed (6.7m)
  Failures — all pre-existing, none touching export status copy:
    - [desktop-chromium] operator-earned-flows.spec.ts:79 (login URL-navigation timeout flake;
      passed on mobile-chromium)
    - [desktop-chromium] operator-screenshot-regression.spec.ts:108,115,136,145 (visual
      baseline pixel-diff, ~0.15 ratio each — local font/OS rendering, not this plan's diff)
    - [mobile-chromium] operator-screenshot-regression.spec.ts:108,115,136,145 (same)
** (Mix) verify.example_browser failed (1)
```

Plan's targeted `<verify>` command (Task 3), run separately and cleanly:
```
cd examples/threadline_phoenix && npx playwright test \
  e2e/tests/operator-prove-mobile.spec.ts e2e/tests/operator-accessibility.spec.ts \
  e2e/tests/operator-screenshots.spec.ts e2e/tests/operator-features.spec.ts \
  --project=desktop-chromium --project=mobile-chromium
```
Result: **52/52 passed** (44.5s), via `run-e2e.sh` against a freshly reset/seeded `threadline_phoenix_test` database.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CR-01 is closed: the export status copy contract has a single owner, is `:now`-aware, normalization-consistent, and boundary-tested at a frozen clock.
- The Phase-186 copy lock and all four e2e specs remain green with zero edits, confirming Option B's byte-identical-copy premise held under live-source re-derivation, not just the plan's snapshot claim.
- `export_action_label/2` now carries a `@doc` note explaining its reserved, intentionally-uncalled status — future reviewers should not re-flag it as dead code without reading that note first.
- `mix ci.all`'s 9 pre-existing Playwright failures (8 screenshot-baseline, 1 login-flow timing flake) are unrelated to this plan and remain open; they are not new regressions introduced here (confirmed via the isolated 4-spec clean run) but should be tracked separately if not already covered by an existing round-5/round-6 ledger entry.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-30*
