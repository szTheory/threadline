# Phase 218: CI Economy: Remove Waste - Context

**Gathered:** 2026-09-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove CI work that repeats a signal another job already proves, and measure the savings against the Phase 214 baseline. There are six cuts:

- Flake Detection goes from nightly and unbounded to weekly and bounded.
- Release PRs get one CI run, not two.
- Browser-full stops re-running CI's Playwright projects.
- The vacuous `:live_dialyzer` test leaves default `mix test` and becomes a real proof inside `verify-dialyzer`.
- The mechanical-check duplicates go.
- Docs and tarball proofs are removed only where the evidence shows another proof dominates them.

ECON-01..07. No new capabilities. Caching is Phase 219, renames are Phase 221, and change-aware skipping is Phase 222.

</domain>

<decisions>
## Implementation Decisions

### Already locked upstream (carry forward, do not re-open)
- The ROADMAP Phase 218 success criteria 1–5 and REQUIREMENTS ECON-01..07 are the contract. The research resolution table (`.planning/research/SUMMARY.md`, "Researcher disagreements, resolved") settles flake cadence, the `verify-mechanical` removal and the Browser-full set difference.
- The milestone's cross-cutting invariants apply to every commit:
  - **Same-commit roster rule.** A roster change updates the `ci.yml` header comment, the job key, CONTRIBUTING's job table and roster, `ci-required` `needs:` and the topology contract test together.
  - **Immutable ids.** Job `id:`s never change, and `CI required` stays byte-exact.
  - **No laundering.** No trigger-level `paths:`, no static `allowed-skips`, no `continue-on-error` on a voting job.
  - **Justified removals.** Every removal carries a "failure class X is still caught by job Y on trigger Z" line.
  - **Explicit staging.** Stage explicit file lists and never `git add .planning/`.

### Flake Detection (ECON-01)
- **D-01:** **15 repeats** (`--repeat-until-failure 15`). This is sized from measured iteration time in the `flake-detection.yml` header comment, run 35967937335: a 288 s cold first run plus about 165 s per repeat, so about 46 min total.
  - The step timeout is about 55 min and the job timeout about 70 min, so the classify, upload and issue steps always run. The planner may tune these within that shape if a fresh measurement moves the iteration time.
  - Record the arithmetic in the workflow header comment.
- **D-02:** Cadence is weekly (`schedule`) plus `workflow_dispatch`, replacing the 07:00 UTC nightly.
- **D-03:** **Green-SHA skip.** The workflow looks up the head SHA of its own last successful run through `gh api` and skips when HEAD matches.
  - The decision logic lives in a table-tested `bin/` script, following the `bin/classify-flake-run` precedent, not in YAML.
  - Querying past runs is acceptable here. The "no run queries" rule applies only to ECON-03.
  - The same mechanism serves the Browser-full nightly skip (D-07).
- **D-04:** A red CI on the same SHA exits `broken-upstream`. A step timeout is classified as `inconclusive` (budget exhausted, clean so far), never `unknown`, and the report stops claiming "no header".
- **D-05:** Fix the `runner.os`-only cache key to the contract-compliant shape, meaning the resolved OTP/Elixir shape from Phase 216. Widen the anti-regression grep to all workflows.

### Tracking issues and release (ECON-02, ECON-03)
- **D-06:** `bin/upsert-ci-issue` gains a close-on-green path, covered by a table test. Issues #28 ("Browser (full project set) is failing", OPEN) and #36 ("Flake Detection: test suite reported unknown", OPEN) are resolved by that path or by cited green runs.
- **D-06a:** **ECON-03 guard: dispatch only when no PAT is configured.**
  - `bootstrap-release-pr-ci` dispatches only when `RELEASE_PLEASE_TOKEN` is absent.
  - Secrets cannot appear in `if:`, so PAT presence reaches the job through a step or job output.
  - With a PAT, release-please's own push already triggers the release PR's CI. That is the cause of the double-dispatch pair, runs 36256339043 and 36256344029.
  - The guard is deterministic and never queries runs.
  - The job wiring and the `always()` failed-sync rationale stay. With no PAT, a failed sync must still produce a red run.
  - Extend `test/threadline/release_control_plane_contract_test.exs`.

### Browser-full (ECON-04)
- **D-07:** On push, Browser-full runs the computed set difference: the Playwright config's projects minus CI's `--project` list, which is `desktop-chromium` and `mobile-chromium` in `ci.yml` today.
  - The list is not hand-maintained.
  - A contract test proves that CI's projects plus Browser-full's equal the full config project set.
  - The nightly uses the D-03 green-SHA skip.

### live Dialyzer (ECON-05), user decision
- **D-08:** **Move `:live_dialyzer` into `verify-dialyzer` and make it fail closed.**
  - Exclude it from default `mix test` in `test/test_helper.exs`. It is not excluded there today; only `pgbouncer_topology` is.
  - In `verify-dialyzer`, run it after the PLT cache restore.
  - Change `bin/verify-dialyzer-slice` so that a Dialyzer run error turns the test red. That covers a missing or unreadable PLT, the "Could not read PLT file" case, and any other error that `--ignore-exit-status` currently masks into "0 live warnings".
  - A negative test proves the red: a missing PLT must fail, built at runtime rather than by moving the maintainer's PLT.
  - `test_helper`, CONTRIBUTING and the topology test change in the same commit.
  - Background: the test passes vacuously today (214-BASELINE §8, `deferred-items.md` 214-02/214-03). Relocating a vacuous test would save minutes but prove nothing.

### Dominated proofs (ECON-06)
- **D-09:** Remove the `verify-mechanical` job and `verify-capture`'s trailing "Assert mechanical checker clean over real evidence" step (`ci.yml` around lines 545–586 and 701–702). Keep the `verify.mechanical` alias. Write the "still caught by" line for each removal.
- **D-10:** **Docs and tarball proofs are removed only if the evidence proves them dominated.** For `verify-docs` (about 75 s) and `verify-hex-package` (about 16 s), compare against the `release.yml` `hex.build` path and any other docs build.
  - If another proof dominates on the same triggers, remove it with a "still caught by" line.
  - Otherwise record "checked, not dominated, kept" with the reason.
  - There is no default removal.

### Re-measurement (ECON-07), user decision
- **D-11:** **Cited dispatch runs plus cadence arithmetic. Do not wait for real scheduled runs.**
  - After the changes land, dispatch each changed workflow once (Flake Detection, Browser-full) and collect at least 5 post-landing ci.yml PR/push runs.
  - Per-run figures cite run IDs.
  - Monthly figures are `measured run × cadence`, labeled `[inference]`.
  - Record runner-minute and critical-path deltas against 214-BASELINE (BASE-01), reusing the 214 tooling (`.planning/phases/214-baseline-measurement/tools/summarize-ci.py`, `collect-ci-runs.sh`).
  - The phase closes without waiting weeks for weekly or nightly samples.

### Claude's Discretion
- Commit and plan granularity. One ECON item per commit or plan is the natural shape, but the roster changes (`verify-mechanical` removal) must be single commits under the roster rule.
- The exact step and job timeout values within D-01's shape.
- Whether to capture `--trace` output of the `:live_dialyzer` test on CI before the move, as the confirming evidence 214 deferred.
- The name and location of the green-SHA skip script.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and contract
- `.planning/ROADMAP.md` §"Phase 218: CI Economy: Remove Waste" — goal and success criteria 1–5, plus the milestone cross-cutting invariants
- `.planning/REQUIREMENTS.md` — ECON-01..07
- `.planning/research/SUMMARY.md` — the T3/T5/T6/T7/T10 items and the "Researcher disagreements, resolved" table (flake cadence, `verify-mechanical`)
- `.planning/research/ARCHITECTURE.md` — each CI change mapped to file:line and to the contract tests it disturbs
- `.planning/research/PITFALLS.md` — committed vs regenerated mechanical inputs, and the flake tagged-subset and timeout pitfalls

### Baseline and evidence
- `.planning/phases/214-baseline-measurement/214-BASELINE.md` — §3 runner-minutes, §4 flake cost, §5 Browser-full cost, §8 isolated `:live_dialyzer` (vacuous pass), §10 research vs re-measured
- `.planning/phases/214-baseline-measurement/deferred-items.md` — the `:live_dialyzer` vacuous-pass items handed to this phase
- `.planning/phases/214-baseline-measurement/tools/` — `summarize-ci.py`, `collect-ci-runs.sh` and `measure-local.sh`, for the ECON-07 re-measure

### Project rules
- `.planning/PROJECT.md` → Constraints → "Zero human verification by default"
- `.planning/MILESTONE-GUIDE.txt` — quality, CI and release bar
- `CONTRIBUTING.md` — the job table, the `ci-required` roster and "## CI Coverage" (Browser-full project wording)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/classify-flake-run` — the table-tested classifier. Extend it for the `broken-upstream` and `inconclusive` outcomes. It is also the precedent for putting logic in `bin/`, not YAML.
- `bin/upsert-ci-issue` — add the close-on-green path here (ECON-02).
- `bin/verify-dialyzer-slice` — make it fail closed on a Dialyzer run error (D-08).
- The Phase 214 measurement tooling under `.planning/phases/214-baseline-measurement/tools/` — reuse it for ECON-07.

### Established Patterns
- Contract tests pin the CI topology:
  - `test/threadline/ci_topology_contract_test.exs`
  - `ci_workflow_parity_contract_test.exs`
  - `ci_coverage_doc_contract_test.exs`
  - `release_control_plane_contract_test.exs`
  - `flake_classifier_contract_test.exs`
  - `dialyzer_slice_contract_test.exs`

  Every workflow change lands with the matching test change.
- `test/test_helper.exs` builds an `exclude` list, which today holds `pgbouncer_topology` only. Add `live_dialyzer: true` there.
- `mix.exs` aliases: `verify.mechanical` (keep it), and `verify.flake` = `test --repeat-until-failure 50`. Decide whether the alias count follows D-01 or stays local-only at 50. Keep them honest and documented.

### Integration Points
- `.github/workflows/flake-detection.yml` — triggers, timeouts, cache key, skip step, classifier outcomes.
- `.github/workflows/browser-full.yml` — push project set, nightly skip.
- `.github/workflows/release.yml:189-206` — `bootstrap-release-pr-ci` guard. PAT usage is at lines 97, 173 and 224.
- `.github/workflows/ci.yml` — the `verify-mechanical` job (around line 545), the `verify-capture` trailing step (around line 701), `ci-required` `needs:` (around line 1005), the header roster comment (line 2), `verify-dialyzer` (`:live_dialyzer` run), and the CI Playwright projects (line 518).

</code_context>

<specifics>
## Specific Ideas

- The maintainer's explicit intent for ECON-05: a moved test must be a real proof. Relocating a vacuous pass is not acceptable.
- The maintainer accepts cadence-arithmetic projections for ECON-07, provided every per-run figure cites a run ID and each projection is labeled `[inference]`.

</specifics>

<deferred>
## Deferred Ideas

- Deps-only `_build` and example-app caching: Phase 219.
- CI job renames and fastest-to-red ordering: Phase 221.
- Change-aware lane skipping (SEED-006): Phase 222. It reuses the ECON-07 numbers.
- Re-checking the ECON-07 projections against real weekly and nightly samples once several weeks accumulate. This could fold into Phase 222's decision record.

</deferred>

---

*Phase: 218-ci-economy-remove-waste*
*Context gathered: 2026-09-27*
