# Phase 222: SEED-006 Change-Aware Lanes (conditional) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 222-seed-006-change-aware-lanes-conditional
**Areas discussed:** Materiality gate and re-measure, Latest-lane trim promise (220 D-07), Seed closure artifacts
**Method:** research-then-recommend (standing default). Three advisor researchers ran in parallel at calibration tier minimal_decisive. The maintainer was asked only the high-impact item, and replied "what do u recommend lets go with that".

---

## Materiality gate and re-measure

| Option | Description | Selected |
|--------|-------------|----------|
| A. Two-part gate (share ≥ 20% in rolling 30d with n ≥ 10, AND saving ≥ 10% of billed PR minutes); a tool copy with new windows; a non-voting ceiling row | Covers post-214 PRs, weights by minutes, and answers "is the allowlist too strict" | ✓ |
| B. Re-run the 214 tool unchanged (fixed windows) | Byte-identical, but it cannot see #55–#65, so SC1 is not really met | |

**User's choice:** Recommended (A).
**Notes:** The scratch re-measure found 0 of 28 strict in 30d, 0 of 9 since 214, and 1 of 49 overall. `.github`-only was 0 of 28. The docs-only ceiling was 6 of 28, about 7–8% of billed PR minutes, all release/sync bot PRs. The thresholds were chosen after seeing the scratch numbers; the record must say so.

## Latest-lane trim promise (220 D-07)

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Keep latest on every run; record the measured cost and supersede D-07 | No coverage loss; keeps the `rule=lane-skip` contract; $0 on a public repo; zero wall clock | ✓ |
| (b/c) Trim latest from PRs (conditional `if:`, dynamic matrix, or nightly) | Saves about 6 notional min per PR run, but needs `allowed-skips` or hides a matrix row, undoes 220's contract, and nightly catches breaks after they reach main | |

**User's choice:** "what do u recommend lets go with that". Option (a).
**Notes:** Measured at about 6 billed min warm (run 36501481301, n=1) and about 7 cold (runs 36502353440, 36487483472, 36484105399).

## Seed closure artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| 222-DECISION.md + seed `status: closed` with numeric `reopen_when` + tool left in phase dir + SCOPE-01 Complete + no new test | Mirrors 220's "not yet" recording; closure is already pinned by `required_gate_errors/1` and `@ci_job_ids` | ✓ |
| Alternatives: decision inline in the seed; `status: dormant`; promote the tool to `bin/` with a test; a new closure contract test | Rejected: they miss SC1/SC4 wording, invite re-litigation, or add redundant maintained surface | |

**User's choice:** Recommended set.

## Claude's Discretion

- Decision-record layout, tool flag names, re-open trigger wording, plan count.

## Deferred Ideas

- Todo `2026-09-28-ci-suite-sync-bound-parallelism.md`, deferred to v1.44 (reviewed, not folded).
- Trimming latest from PRs: rejected; revisit if the repo goes private or pins stop being exact.
- Dev-env `_build` cache for credo/dialyzer (219 deferred).
