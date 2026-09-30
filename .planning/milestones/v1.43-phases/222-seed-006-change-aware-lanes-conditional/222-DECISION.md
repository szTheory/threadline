# Phase 222: SEED-006 decision

## Verdict

CLOSE

Strict fail-closed inert share in the `30d-now` window is 0 of 28 merged PRs (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`). Part 1 (share vs threshold) fails at 0.0% against the ≥20% floor; part 2 (saving vs threshold) fails at 0.0% against the ≥10% floor. Both parts must pass to build; neither does, so the seed closes as measured, not worth it.

## Gate (D-02)

Two parts, both must pass to build, as coded in `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`:

1. Strict fail-closed inert share ≥ 20% of merged PRs in `30d-now`, with n ≥ 10 (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`).
2. Projected saving ≥ 10% of that window's billed PR runner-minutes (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`).

Measured (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`):

- n = 28, k = 0 strict-inert (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`).
- Part 1: 0 of 28 = 0.0% (need n≥10 and ≥20%) — FAIL (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`).
- Part 2: saving 0×19 = 0 of 1553 billed min = 0.0% (need ≥10%) — FAIL (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`).

**Denominator.** One representative `ci.yml` `pull_request` run per merged PR, the highest run id on the PR's final head SHA. PRs without such a run are excluded, which shrinks the denominator and so favours BUILD (a smaller denominator makes any given saving a larger percentage). None were excluded here: all 28 `30d-now` PRs had a matching run (`no ci.yml pull_request run: none`, `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`).

**Per-skip saving.** 19 billed min, from the three fixed 219 warm skip-eligible runs — Browser E2E 10 (run 36455432448), Capture 7 (run 36450388764), PgBouncer 2 (run 36457705448) — `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py skip-saving`. Push and dispatch runs never skip (they are not `pull_request` events, so classify-and-skip has nothing to act on there), so only `pull_request` runs count toward this gate.

**Honesty note (mandatory).** The 20% and 10% thresholds were chosen after a scratch measurement had been seen during discussion, so they are not pre-registered against a blind future measurement (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now` is where the thresholds live in code, added this phase). Said plainly: this is a post-hoc gate, not a pre-registered trial. The margin argument is offered as compensation — the measured strict share (0.0%, same command) sits 20 percentage points below the part-1 floor, and 0.0% saving sits 10 points below the part-2 floor. No threshold in a plausible range (10-30% for part 1, 5-15% for part 2) would flip either part under the strict fail-closed classifier, because the measured value is exactly 0.

Against the D-03 ceiling (non-voting, admissibility reasons below): the most lenient *admissible* row, docs-only, is 6 of 28 = 7.3% of billed minutes (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now`) — still below the 10% part-2 floor, so even relaxing the classifier to an admissible-but-broader shape does not flip the verdict. The broadest ceiling row, no-product-code, is 15 of 28 = 53.6% of PRs and 18.4% of billed minutes (same command), which *would* flip both parts — but that row is inadmissible (D-03: it launders skips onto exactly the CI/test changes the lanes exist to gate), so it is excluded from the margin argument, not counted toward "no reasonable threshold changes the verdict." The honest statement is narrower than the discussion draft: **no reasonable threshold changes the verdict under any admissible classifier**; an inadmissible classifier could flip it, which is exactly why D-03 requires each ceiling row to carry a stated inadmissibility reason rather than voting on numbers alone.

## Baseline (214 §6)

214-BASELINE.md §6: all = 1 of 40 merged PRs inert (2.5%, PR #8), 30d = 0 of 20 (0%), no inert PR — `python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window all` and `--window 30d`.

The 222 copy reproduces this exactly on a fresh, larger snapshot: `at-214` (mergedAt on or before 2026-09-26, the same PR set as 214's `all`) = 1 of 40, inert PR #8 — `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window at-214`. The 40 file lists named in 214's `index.json` are byte-identical to 222's fresh collection of the same PRs (`bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh`, check 5).

## Re-measure

| Window | k of n | Inert PRs | Command | Raw path |
|---|---|---|---|---|
| all | 1 of 49 | #8 | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window all` | `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs` |
| at-214 | 1 of 40 | #8 | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window at-214` | `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs` |
| since-214 | 0 of 9 | none | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window since-214` | `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs` |
| 30d-now (the D-02 gate window) | 0 of 28 | none | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window 30d-now` | `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs` |
| last 20 | 0 of 20 | none | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --last 20` | `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs` |

Collection commands are `gh pr list --repo szTheory/threadline --state merged --base main --limit 500 --json number,title,mergedAt,headRefName,changedFiles` (saved as `raw/prs/index.json`) and `gh api --paginate repos/szTheory/threadline/pulls/<n>/files?per_page=100 --jq '.[].filename'` per PR (saved as `raw/prs/<n>.files.txt`), recorded in `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs/manifest.json`. Collection date: 2026-09-29.

`since-214` (n=9) is below the gate's n≥10 floor and is informational only — it does not vote, per RESEARCH.md Open Question 2. No new inert-looking candidate path was found in the 222-01 SUMMARY beyond the ones already in the allowlist, so nothing new was proposed for admission; the allowlist stays byte-identical to Phase 214's (D-01, `bash .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh` check 2).

## Why SEED-006 was planted

The seed's own breadcrumbs cite run 34757305454, run 34757804720 and run 34758908342: repeated 7-11 minute full matrices observed while landing small branch-protection workflow fixes during the Phase 200 closeout (SEED-006 frontmatter, "Breadcrumbs"). Those PRs are inside the `at-214` snapshot, not the `30d-now` gate window: the CI-only PR mix that motivated the seed was not sustained into the measurement window that decides it.

## Ceiling (D-03, information only, does not vote)

command: `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now` (all figures in this table are this one command's output, cited once here for the whole table):

| Row | Count | Projected saving | % of denominator | Inadmissibility reason |
|---|---|---|---|---|
| github-only | 0 of 28 | 0×19 = 0 billed min | 0.0% | The workflow under test (`.github/*`) is itself changing; skipping the lanes that validate it would let a broken workflow ship unvalidated (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now`). |
| docs-only | 6 of 28 | 6×19 = 114 billed min | 7.3% | Docs files ship in the Hex package and are read by doc-contract tests, so `verify-test` must run on them anyway — skipping would desync coverage from a promise the suite already keeps (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now`). |
| no-product-code | 15 of 28 | 15×19 = 285 billed min | 18.4% | Includes CI and test-file changes; skipping lanes on changes to the lanes' own inputs launders the gate — exactly the class D-02's fail-closed rule exists to forbid (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now`). |

This row exists to answer "was CLOSE just an artifact of a strict allowlist?" — no: even the most lenient *admissible* row (docs-only, `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py ceiling --window 30d-now`) sits under the 10% part-2 floor.

## Minute math

Per-PR billed p50 is 55 min (run 36086466934, BASE-01, `python3 .planning/phases/214-baseline-measurement/tools/summarize-ci.py runner-minutes --unit pr`). Per-skip saving is 19 billed min (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py skip-saving`). The `30d-now` denominator is 1553 billed min over 28 PR runs (`python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py minute-gate --window 30d-now`). Projected saving at the measured strict share (k=0) is 0 of 1553 billed min = 0.0%.

## What we would have built

SCOPE-01's four bullets, on BUILD: a `verify-change-scope` job with a table-tested, fail-closed `bin/classify-ci-lanes` classifier (anything unknown runs the full matrix); a dynamic `allowed-skips` limited to skip-eligible jobs (never `verify-test` or the rehearsal); an empty skip list on push and on dispatch; a `ci-required` step that re-justifies each skip.

The proof cost, per D-09: widening the `required_gate_errors/1` `with:` allowlist (`git grep -n "defp required_gate_errors" -- test/threadline/ci_workflow_parity_contract_test.exs`) to admit `allowed-skips`, adding an id to `@ci_job_ids` (`git grep -n "@ci_job_ids MapSet" -- test/threadline/ci_workflow_parity_contract_test.exs`) checked by `gate_job_id_errors/1` (`git grep -n "defp gate_job_id_errors" -- test/threadline/ci_workflow_parity_contract_test.exs`), and opening a new class of path that can launder the gate, which `voting_lane_errors/1`'s `rule=lane-skip` controls (`git grep -n "defp voting_lane_errors" -- test/threadline/ci_workflow_parity_contract_test.exs`, test cases around lines 555-620, emitted message near line 2046) exist specifically to forbid. `release_control_plane_contract_test.exs` already asserts the required check "launders nothing" (`git grep -n "launders nothing" -- test/threadline/release_control_plane_contract_test.exs`), and `ci.yml` states its no-`paths:` posture deliberately (`git grep -n "deliberately carries no" -- .github/workflows/ci.yml`).

D-09: no new test and no `ci.yml` edit in this phase, because these five pins already make the build branch a reviewed change — a future BUILD phase touches all of them and is scoped there, not smuggled in here.

## Where the latency actually is

Closing SEED-006 does not mean CI latency is solved. The test suite is about 191 of 209 s synchronous (run 36359135268, `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md`), roughly 91% serial across 2460 tests — that serial core is paid on every lane that runs the suite regardless of any change-aware lane skipping, and is deferred to v1.44 rather than folded into this phase (a different, broader risk class than a conditional decision phase).

## Latest lane (D-05, D-06)

The latest lane keeps running and voting on every `ci.yml` run — PRs, pushes to main, and dispatch. This phase does not trim it, superseding 220 D-07's "Phase 222 trims it."

Every trim option is worse than the cost: a trigger-conditional `if:` needs `allowed-skips` (a static one is banned, a dynamic one is exactly the classifier machinery this phase declines to build); a `fromJSON` matrix would hide the row, which is laundering by omission that `rule=lane-skip` exists to forbid; nightly-only would catch a PR's own break only after it lands on `main`, when with exact pins that is the only thing the lane can catch at all.

Cost: about 6 billed min warm (run 36501481301, 331 s, n=1) and about 7 cold (runs 36502353440, 36487483472, 36484105399), so about 12-13 per merged change (PR + push) `[inference: run 36501481301 (PR-side warm), run 36487483472 (PR-side cold), 6+7]`. Wall clock: zero — the latest lane takes 330-380 s against the Browser E2E critical path of about 550 s (`gh run view 36501481301`, `gh run view 36487483472`, cf. Browser E2E critical-path figure in 214-BASELINE.md §2). Money: $0, because the repo is public and these are notional runner-minutes, not billed spend.

## Tooling findings

`bash -c 'node <gsd-core>/bin/gsd-tools.cjs list-seeds'` reports the seed with `"status": "closed"` — the top-level frontmatter `status:` value, not the nested `audit_acknowledged.status` path field, which stays `"dormant"` as the historical v1.41 audit record. `bash -c 'node <gsd-core>/bin/gsd-tools.cjs audit-open --json'` does not list it as an open item (its `seeds` count in `counts` is empty): its unimplemented-seed bucket is `dormant`/`active`/`triggered`, the same mechanism that already excludes the ecosystem-integrations seed's `retired` status, and the new `closed` value falls outside that set the same way, with no gsd-tools change made.
