---
phase: 198-green-bringup
plan: 01
subsystem: infra
tags: [ci, github-actions, credo, static-analysis, mechanical-checker, audit, measurement]

requires:
  - phase: 194-tier-a-capture
    provides: MechanicalChecker and the committed Tier-A scorecard corpus this plan probes
  - phase: 196-forward-only-iteration
    provides: the MODE-B ratchet floors in .planning/design-system-ledger.json
provides:
  - Preserved verbatim failing logs of the last observed red CI run (28214113903) with the D-36 staleness caveat
  - A measured Credo full-default per-check histogram and per-file concentration table sizing Phase 203
  - An executed, evidence-based answer to GREEN-03 sizing Phase 201 Tier 2
  - The .planning/audits/ directory as a tracked artifact home
affects: [199-decouple-planning, 201-operator-surface-tier-2, 203-real-credo-gate, 198-02-triage]

actuals:
  tokens: 354775
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "External-config measurement: run a tool against a config held outside the repo via a named --config-file flag, so the repo's own config is provably unmodified"
    - "One-dimensional variant probe: answer a sensitivity question by varying exactly one dimension per synthetic input, with a positive control in the same run to prove the harness has teeth"

key-files:
  created:
    - .planning/audits/198-ci-run-28214113903-logs.md
    - .planning/audits/198-credo-full-default.json
    - .planning/audits/198-credo-histogram.md
    - .planning/audits/198-mechanical-sensitivity.md
  modified:
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Sourced the stock full-default Credo config from deps/credo/.credo.exs — the exact file credo.gen.config embeds at compile time — rather than risking a generator write into the repo root"
  - "Added a MODE-B geometry positive control alongside the planned MODE-A token control, so the GREEN-03 verdict is backed by teeth on both checker paths"
  - "Recorded the absent-directory case alongside the required empty-directory case, surfacing that a misconfigured :scorecard_dir passes silently"

patterns-established:
  - "Measurement artifacts live under .planning/audits/ and are never read by a gate (DECOUPLE-01)"
  - "A prohibition (do not modify file X) is discharged with a recorded content hash before and after plus git diff --exit-code, not with a claim"

requirements-completed: [GREEN-01, GREEN-02, GREEN-03]

coverage:
  - id: D1
    description: "Run 28214113903's failing logs are readable from the repository, with run metadata, a per-job conclusion table, and the D-36 staleness caveat attached"
    requirement: GREEN-01
    verification:
      - kind: other
        ref: "test -f .planning/audits/198-ci-run-28214113903-logs.md && grep -q '28214113903' && grep -qi 'predates'"
        status: pass
      - kind: other
        ref: "gh run view 28214113903 --log-failed (exit 0, 8856 lines, 1218469 bytes captured verbatim)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A per-check Credo histogram and a per-file concentration table, produced from a full-default config held outside the repo, with .credo.exs provably unmodified"
    requirement: GREEN-02
    verification:
      - kind: other
        ref: "git diff --exit-code .credo.exs (exit 0) + .credo.exs content hash a5f0e0df... identical before and after"
        status: pass
      - kind: other
        ref: "jq -e '.issues | length > 0' .planning/audits/198-credo-full-default.json (377 issues vs baseline 0 — proves --config-file was honored)"
        status: pass
    human_judgment: false
  - id: D3
    description: "An executed answer to whether MechanicalChecker is sensitive to rendered text content and text width, with no scorecard touched"
    requirement: GREEN-03
    verification:
      - kind: other
        ref: "mix run /tmp/198-work/probe.exs — control == text-content : true; control == text-width : true; token control {:error, 2}; MODE-B control {:error, 1}"
        status: pass
      - kind: other
        ref: "git status --porcelain .planning/scorecards/ (empty output)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The sizing implication drawn for Phase 201 Tier 2 — that copy work is cheap to gate but unprotected against layout consequences"
    requirement: GREEN-03
    verification: []
    human_judgment: true
    rationale: "The measurement is proven; the estimate drawn from it is a planning judgment the maintainer must ratify when Phase 201 is planned."

duration: 25min
completed: 2026-08-27
status: complete
---

# Phase 198 Plan 01: Read-Only Measurement Sweep Summary

**Three decision-grade measurements captured without mutating a single non-artifact file: the last red CI run's 8856 failing log lines preserved verbatim against the 90-day purge, Credo's full-default surface measured at 377 issues against a vacuous baseline of 0, and an executed proof that the mechanical checker is blind to both rendered text content and text width.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-08-27T19:45:00Z
- **Completed:** 2026-08-27T20:10:00Z
- **Tasks:** 3
- **Files created:** 4 (plus 1 modified)

## Accomplishments

- **GREEN-01 — the red run is no longer perishable.** `gh run view 28214113903 --log-failed` returned 8856 lines (1,218,469 bytes) and is now committed verbatim, with run metadata, a ten-row per-job conclusion table, a failure summary, and the D-36 caveat stating in the artifact's own header that this run predates the unpushed matrix commits and describes the *older* `ci.yml` on `origin/main` (`67998e0b`). Three of ten jobs were red: `Compile without optional deps` (a `CompileError` on `lib/threadline/operator_surface/ui.ex`), `Run test suite` (`1124 tests, 3 failures`), and `Example app browser E2E (Playwright)` — which accounts for 7814 of the 8856 lines and the ≈1h33m wall clock.
- **GREEN-02 — the vacuous credo gate now has a number.** Baseline (the repo's own `.credo.exs`, two checks enabled): **0 issues**. Full default via an out-of-repo `--config-file`: **377 issues**, from **17 of 108** checks, across **99 files**. `.credo.exs` was never modified, not even temporarily — content hash `a5f0e0df907a7ca5c57ab777b8a49a43bcd5cef3` identical before and after, `git diff --exit-code` exits 0, and the commit touches no path outside `.planning/audits/`.
- **GREEN-03 — answered from an executed experiment, not from reading the code.** `MechanicalChecker` is **not** sensitive to rendered text content and **not** sensitive to text width. Varying every text string produced a byte-identical return (`control == text-content : true`); varying every width and bounding box produced a byte-identical return (`control == text-width : true`). Two positive controls fired in the same run, proving the harness has teeth on both MODE-A (2 token violations) and MODE-B (1 ratchet violation).

## Task Commits

Each task was committed atomically:

1. **Task 1: Preserve run 28214113903's failing logs end-to-end** — `43de31de` (docs)
2. **Task 2: Credo full-default histogram and per-file concentration** — `5a6089b9` (docs)
3. **Task 3: Scorecard-free mechanical-sensitivity probe** — `73b70f23` (docs)

**Plan metadata:** see the `docs(198-01): complete read-only measurement sweep` commit.

## Files Created/Modified

- `.planning/audits/198-ci-run-28214113903-logs.md` (1.2 MB) — run metadata, per-job conclusions, failure summary, D-36 staleness caveat, credential pre-scan, and the complete verbatim `--log-failed` capture in a fenced block
- `.planning/audits/198-credo-full-default.json` (169 KB) — raw `mix credo --strict --config-file … --format json` output, 377 issues
- `.planning/audits/198-credo-histogram.md` — measurement conditions, per-check histogram, `lib/`-only histogram, per-file concentration over all 99 files, and the Phase 203 sizing section
- `.planning/audits/198-mechanical-sensitivity.md` — the 21 enumerated signals with `mechanical_checker.ex` line references, the probe design with per-variant leaf diffs, the results table, both positive controls, the empty/absent-directory edges, the `## Finding`, and the Phase 201 Tier 2 sizing section
- `.planning/REQUIREMENTS.md` — GREEN-01, GREEN-02, GREEN-03 marked complete

## Decisions Made

- **The stock full-default Credo config was sourced from `deps/credo/.credo.exs`, not generated in place.** `mix credo.gen.config` writes `.credo.exs` into the current working directory. It was invoked once from the repo root purely to record its behavior — it printed `File exists: .credo.exs, aborted.` and wrote nothing — and the template was then taken from `deps/credo/.credo.exs`, which is byte-identical to what the generator emits (it is the compile-time `@default_config_file` at `gen.config.ex:5`, sha256 `c6e520ba…`). Copied to `/tmp/198-full-default.credo.exs` and only edited there. This discharges the "never modify `.credo.exs`, not even temporarily" prohibition by construction rather than by discipline.
- **A MODE-B geometry positive control was added beyond the plan's single MODE-A token control.** The GREEN-03 claim is that text is invisible while *geometry* is visible. One control proving MODE-A token checks fire would leave the MODE-B ratchet path untested, and the null result would be weaker for it. `mode_b.scroll_cost` was blown from `18.803` to `10017.803` and produced the expected `{:error, [1 violation]}`.
- **The absent-directory case was recorded alongside the required empty-directory case.** Both return `{:ok, []}`. This is documented intent (`mechanical_checker.ex:77-79`) but it means a misconfigured `:scorecard_dir` passes silently — the gate cannot distinguish "nothing is wrong" from "nothing was checked". Recorded in the artifact as a hazard; not fixed here, since this plan is read-only.
- **The text variant was chosen so all three notions of text difference change at once**, and each was measured separately (`"abcdef"` → `"日本語Å"`: 6→11 bytes, 6→4 code points, 6→7 columns). Because the result was byte-identical, the verdict is unconditional rather than "reacted to bytes but not code points".

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched project dependencies in the worktree**
- **Found during:** Task 2 (Credo histogram)
- **Issue:** `mix credo --version` failed with `** (Mix) Can't continue due to errors on dependencies` — the fresh worktree had no `deps/` populated. No credo run was possible.
- **Fix:** Ran `mix deps.get` (fetching already-declared, already-locked dependencies — not adding a new package, so the package-manager exclusion to Rule 3 does not apply).
- **Files modified:** none tracked. `git status --porcelain` was empty afterwards; `mix.lock` was unchanged.
- **Verification:** `mix credo --version` → `1.7.18`; `git status --porcelain` empty.
- **Committed in:** n/a — produced no tracked change.

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** None on scope or output. Required to execute Task 2 at all; produced no tracked change and did not touch any file the plan prohibits.

## Notes on the reported `actuals`

`actuals.tokens: 354775` is `chars/4` over the realized diff and is **not** comparable to the plan's `estimate.tokens: 84000` in the way it looks, so it is stated plainly rather than massaged: **~96% of that figure is machine-captured content**, not authored content — the 1.2 MB verbatim `gh` log capture (which is the entire point of GREEN-01) plus the 169 KB raw Credo JSON. The authored prose across all four artifacts is roughly 31,300 chars, i.e. **~7,800 tokens on the same scale**. Future estimates for "preserve a large external capture" plans should size the capture separately from the authorship, because a single `--log-failed` redirect can move the realized-diff number by an order of magnitude with no corresponding planning or authorship cost.

## Issues Encountered

- **None blocking.** One notable non-issue: run 28214113903's logs had **not** been purged (created 2026-06-26, captured 2026-08-27, ≈62 days into the 90-day window), so the plan's `LOGS UNAVAILABLE` honest-loss backstop was not needed. The remaining window is ≈4 weeks.

## Verification Results

Plan-level `<verification>` block, re-run at close:

| Check | Result |
|---|---|
| `git diff --exit-code .credo.exs` | exit 0 — clean |
| `git status --porcelain .planning/scorecards/` | empty (0 lines) |
| All four artifacts exist under `.planning/audits/` | yes — 4/4 present |
| `git diff --name-only HEAD~3..HEAD` lists only `.planning/audits/` paths | yes — exactly the 4 artifacts, nothing else |

Task-level `<verify>` blocks: Task 1 PASS, Task 2 PASS, Task 3 PASS (each executed verbatim as written in the plan).

## Threat Flags

No new security-relevant surface beyond the plan's `<threat_model>`. On T-198-01-01 (information disclosure via the committed CI log), a pre-check was run and recorded in the artifact: the capture was scanned for `sk-ant-`, `ghp_`, `github_pat_`, `AKIA`, and PEM private-key headers with **no matches**; GitHub's own masking is visible in the log as `token: ***` and `AUTHORIZATION: basic ***`. This is a pre-check only — Plan 06's `gitleaks`/`trufflehog` sweep (D-28) remains the gate before any push.

## Known Stubs

None. No stub, placeholder, skipped test, or unrun `<verify>` was introduced by this plan.

## User Setup Required

None — no external service configuration required. `gh` was already authenticated.

## Next Phase Readiness

- **Phase 203 (GATE-01/GATE-02) can now be sized honestly.** It does *not* face a 377-item backlog: `Design.AliasUsage` is 279 of 377 and **256 of those 279 are in `test/`**, leaving 98 findings total and **77 in `lib/`** once it is excluded. The residual is between 77 and 377 depending entirely on the check set chosen. The `Refactor.*` cluster in `lib/` (`Nesting` 19, `CyclomaticComplexity` 15, `MapJoin` 12) is the genuine quality signal.
- **Phase 201 Tier 2 can now be sized honestly.** Copy changes are free with respect to the mechanical gate and require **no scorecard regeneration** — which matters because recapture is forbidden this milestone. The flip side must be carried into the estimate: the gate offers **zero** protection against text-driven layout breakage (overflow, truncation, wrapping), so any copy work in constrained containers needs a non-mechanical safety net.
- **D-36 is satisfied and this plan unblocks the rest of the phase.** The measurement sweep is on disk and committed before any mutation; wave 2 (Plan 02's tracer) may proceed.
- **Concern to carry forward:** `MechanicalChecker.run/1` returns `{:ok, []}` for both an empty and an absent scorecard directory. A path typo in a future gate wiring would pass silently. Worth a register row when a phase touches the mechanical gate wiring; explicitly out of scope for this read-only plan.

## Self-Check: PASSED

All four created files verified present on disk with `ls -la .planning/audits/` (sizes 1223625 / 169276 / 12972 / 13225 bytes). All three task commits verified in `git log`: `43de31de`, `5a6089b9`, `73b70f23`. `git diff --name-only HEAD~3..HEAD` returns exactly the four artifact paths and nothing else — the plan mutated nothing outside `.planning/audits/`.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-27*
