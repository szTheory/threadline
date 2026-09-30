# Phase 222: SEED-006 Change-Aware Lanes (conditional) - Context

**Gathered:** 2026-09-29
**Status:** Ready for planning
**Method:** research-then-recommend (3 parallel researchers). The maintainer accepted the whole recommended set, including the one high-impact item: keep the latest lane on every run, which supersedes 220 D-07's "Phase 222 trims it".

<domain>
## Phase Boundary

SCOPE-01. The phase settles SEED-006 from measured data. There are two acceptable outcomes:
- **Build:** a fail-closed `bin/classify-ci-lanes` classifier and a `verify-change-scope` job, with a dynamic `allowed-skips` limited to skip-eligible jobs.
- **Close:** the seed is closed as "measured, not worth it", with the numbers behind it.

The decision is expected to be **CLOSE**. A scratch re-measure during discussion (not committed, so the phase must re-collect it in-repo) found:
- strict fail-closed inert share: 0 of 28 merged PRs in the rolling 30 days, 0 of 9 since Phase 214 (#55–#65), 1 of 49 overall;
- `.github`-only PRs (SEED-006's original complaint): 0 of 28 in 30 days;
- docs-only ceiling: 6 of 28, about 114 of roughly 1,400–1,540 billed PR minutes (7–8%). All six are release/sync bot PRs whose files ship in the Hex package, so `verify-test` must run on them anyway.

If the in-repo re-measure unexpectedly passes the D-02 gate, stop and return to the maintainer before building anything. The build branch is SC2/SC3 in ROADMAP.md and research/SUMMARY.md §Phase 222; it is not planned in detail here.

**Not in scope:** changes to `ci.yml`, `ci-required`, or any contract test (see D-09). Suite parallelism (see deferred).

</domain>

<decisions>
## Implementation Decisions

### Measurement and the build/close gate
- **D-01: Re-measure with a copy of the 214 tool, not an edit of it.**
  - Copy `.planning/phases/214-baseline-measurement/tools/inert-share.py` and `inert-allowlist.txt` to `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/`. The 214 tool, its `raw/` data, and its fixed windows stay frozen.
  - The copy adds two windows: `since-214` (mergedAt after the last PR in 214's snapshot, 2026-09-26, through the collection date) and `30d-now` (rolling 30 days ending on the collection date). Both bounds are fixed constants in the tool once collected, so re-runs are byte-identical.
  - Collect a fresh `raw/prs/` snapshot in the 222 dir, using the same `gh pr list` and `gh api --paginate .../pulls/<n>/files` commands as 214 §6. Keep the count-drift check.
  - First reproduce 214 exactly with the copy (`all` over the 214 PR set and `30d` = 0 of 20). Then report the new windows.
  - The allowlist is not widened. If a new inert-looking path appears, it needs its own proof command, as in 214.
- **D-02: Two-part gate. Build only if both parts pass:**
  1. the strict fail-closed inert share is at least 20% of merged PRs in `30d-now`, with n ≥ 10; and
  2. the projected saving is at least 10% of that window's billed PR runner-minutes.
  - Saving per skipped PR run = the skip-eligible lanes only (Browser E2E, Capture, PgBouncer, about 19 billed min), from 219 warm runs 36455432448, 36450388764 and 36457705448. Push and dispatch runs never skip, so only `pull_request` runs count.
  - **Honesty note for the record:** the thresholds were chosen after a scratch measurement had been seen. Say so in the record. The record should also say the margin is wide enough (0% against 20%, 7–8% ceiling against 10%) that no reasonable threshold changes the verdict.
- **D-03: Record a ceiling row. It is information only and does not vote.**
  - Measure what broader, non-fail-closed classifiers would have skipped: `.github`-only, docs-only, and "no product code".
  - Explain why each is not admissible. `.github`-only means the workflow under test is itself changing. Docs-only files ship in the Hex package and are read by doc-contract tests. "No product code" would skip lanes on CI and test changes, which is laundering.
  - This row exists to show the CLOSE verdict is not an artefact of a strict allowlist.

### Decision record
- **D-04: `222-DECISION.md` in the phase dir, modelled on 220-SPIKE.md's `## Outcome` / `## Cost` sections and 214-BASELINE.md's citation style.** (220-FINDINGS.md was never created: 220 landed GREEN.) It contains:
  - the verdict line (`CLOSE` or `BUILD`);
  - the D-02 gate, with the honesty note;
  - the 214 §6 baseline (1 of 40 all, 0 of 20 in 30d, the one inert PR #8) and the re-measured windows, each with its exact command and raw path;
  - the SEED-006 motivating runs 34757305454, 34757804720 and 34758908342;
  - the ceiling row (D-03) and the minute math, citing the 219 warm runs and run 36086466934 (the BASE-01 55-billed-minute figure);
  - a "what we would have built" section: SCOPE-01's four bullets, and the proof cost (it widens the `required_gate_errors/1` `with:` allowlist, adds an id to `@ci_job_ids`, and opens a new class of path that can launder the gate);
  - a "where the latency actually is" note: the suite is about 191 of 209 s sync (run 36359135268), pointing at the deferred todo;
  - the D-06 latest-lane section.
  - Use repo-relative paths only. The repo-hygiene guard scans tracked `.planning/`, so no home-path shapes in quoted command output.

### Latest lane (maintainer-decided, supersedes 220 D-07's trim)
- **D-05: The latest lane keeps running and voting on every `ci.yml` run. 222 does not trim it.** — **Reversibility:** reversible — one matrix row, but trimming it later needs an `allowed-skips` design and weakening 220's `rule=lane-skip` contract.
  - Every trim option is worse than the cost. A trigger-conditional `if:` needs `allowed-skips`: a static one is banned, and a dynamic one is the classifier machinery 222 declines to build. A `fromJSON` matrix hides the row, which is laundering by omission that `rule=lane-skip` exists to forbid. Nightly-only catches a PR's own break after it is on `main`; with exact pins, that is the only thing the lane can catch.
- **D-06: Record the measured latest-lane cost and the supersession explicitly.**
  - Cost: about 6 billed min warm (run 36501481301, 331 s, n=1) and about 7 cold (runs 36502353440, 36487483472, 36484105399), so about 12–13 per merged change (PR + push).
  - Wall clock: zero. Latest takes 330–380 s against the Browser E2E critical path of about 550 s.
  - Money: $0. The repo is public, so these runner-minutes are a notional economy metric.
  - Add a one-line forward pointer in `220-CONTEXT.md` D-07 ("Superseded by 222 D-05: kept every-run; see 222-DECISION.md"). Do not rewrite 220's decision text.

### Closure artifacts (on CLOSE)
- **D-07: Seed edit.** In `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md`:
  - set `status: closed` and add `closed_on`, `closed_during: v1.43 Phase 222`, `closed_reason` and `decision: <path to 222-DECISION.md>`, following SEED-003's `retired_*` shape;
  - replace `trigger_when: when relevant` with a numeric `reopen_when`: "strict inert share ≥ 5 of the last 20 merged PRs by `<cited 222 inert-share.py command>`, or a new required lane moves the ci.yml critical path past the Browser E2E bound";
  - keep `audit_acknowledged`, and add an `## Outcome` body section.
  - `closed` is a new status value. Check that gsd-tools' seed listing and milestone audit tolerate it. If they don't, record that as a finding and do not patch gsd-tools.
- **D-08: Requirement and PROJECT.md.**
  - SCOPE-01: mark it `[x]` with an appended `Outcome: closed, measured, not worth it (222-DECISION.md: k of n inert)` line. The traceability row reads Complete; SCOPE-01's own "otherwise" branch makes that honest.
  - PROJECT.md: the SEED-006 milestone bullet (around line 42) becomes past tense. Add one Key Decisions row in 220's format.
  - Hand-check STATE.md and ROADMAP.md after any `state.*` call.

### Closure is already pinned
- **D-09: No new test, and no `ci.yml` edit.** The decision record cites the existing pins:
  - `required_gate_errors/1` (`test/threadline/ci_workflow_parity_contract_test.exs` around line 1792) only allows `jobs` in the alls-green `with:`, so `allowed-skips` fails in any spelling (the quoted variant is tested around line 738);
  - the frozen `@ci_job_ids` (around line 1744) and `gate_job_id_errors/1` (around line 1987) reject a new `verify-change-scope` job without a reviewed edit;
  - `voting_lane_errors/1` `rule=lane-skip` controls (around lines 505-660);
  - `release_control_plane_contract_test.exs` around line 90;
  - `ci.yml`'s "deliberately carries no `paths:`" comment (around line 11).
  - Verify these line references at plan time; they are approximate.

### Claude's Discretion
- The exact layout of `222-DECISION.md`, the tool-copy flag names, and whether the re-check is a `--window` or `--last N` mode.
- Plan count and wave shape. This is a planning-only phase: expect 1–2 plans, no maintainer checkpoint, and no push. Landing rides the next landing branch.
- The re-open trigger's exact second clause wording.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirement
- `.planning/ROADMAP.md` — Phase 222 section (around line 348) and the v1.43 cross-cutting invariants (around lines 37-46)
- `.planning/REQUIREMENTS.md` lines 112-120 — SCOPE-01
- `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md` — the seed being settled
- `.planning/research/SUMMARY.md` lines 245-280 — Phase 222 rationale, the build-branch design, and the "build only if material" rule

### Measurement inputs
- `.planning/phases/214-baseline-measurement/214-BASELINE.md` §6 — inert-path share method, allowlist and proofs, BASE-01 numbers
- `.planning/phases/214-baseline-measurement/tools/inert-share.py` and `tools/inert-allowlist.txt` — the tool to copy (fixed `WINDOWS` at lines 39-41)
- `.planning/phases/218-ci-economy-remove-waste/218-REMEASURE.md` — post-218 ci.yml cost
- `.planning/phases/219-deps-only-build-cache/219-REMEASURE.md` — post-219 warm-run cost and per-lane minutes
- `.planning/phases/221-ci-names-and-order/raw/ci/runs/` — run JSONs, including latest-lane runs 36501481301, 36502353440 and 36487483472, and the pre-lane baseline 36453043277..36467068660
- `.planning/phases/221-ci-names-and-order/` NAME_HISTORY tool — maps old check names to ids across the 221 rename

### Latest lane
- `.planning/phases/220-newest-toolchain-lane/220-CONTEXT.md` lines 57-60 — D-07, which 222 D-05 supersedes
- `.planning/phases/220-newest-toolchain-lane/220-SPIKE.md` — Cost section, run 36484105399

### Precedents for closure artifacts
- `.planning/seeds/SEED-003-ecosystem-integrations.md` — `retired_*` frontmatter shape
- `.planning/phases/220-newest-toolchain-lane/220-04-PLAN.md` around lines 124-125 — the PROJECT.md Key Decisions row and seed format used for "not yet"

### Existing closure pins (cite, do not change)
- `test/threadline/ci_workflow_parity_contract_test.exs` — `required_gate_errors/1`, `@ci_job_ids`, `gate_job_id_errors/1`, `voting_lane_errors/1`
- `test/threadline/release_control_plane_contract_test.exs` — the `allowed-skips` rules
- `.github/workflows/ci.yml` — the `ci-required` job and the no-`paths:` comment

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `inert-share.py` (214): stdlib Python, deterministic, fail-closed, with `--self-test` and count-drift refusal. Copy it; don't rewrite it.
- The 221 time-to-red / NAME_HISTORY tooling, for any run-ID lookups that span the 221 rename.

### Established Patterns
- Phase-local measurement tools and `raw/` snapshots live under the phase dir; figures are cited as `(command)` on the same line (214's `check-citations.py`).
- "Not built / not yet" outcomes are recorded as a findings or decision file plus a seed edit plus a PROJECT.md Key Decisions row (220).
- Never `git add .planning/` wholesale. Stage explicit file lists.

### Integration Points
- No product or CI code changes on the CLOSE branch. The files touched are the 222 phase dir, SEED-006, REQUIREMENTS.md, PROJECT.md, a one-line pointer in 220-CONTEXT.md, STATE.md and ROADMAP.md.
- `mix ci.all` must stay green at phase close; the repo-hygiene guard covers the new planning prose.

</code_context>

<specifics>
## Specific Ideas

- The ceiling row is there to answer the question "was the close just because the allowlist is strict?" with numbers.
- The decision record should say plainly where CI latency actually goes (the sync-bound suite), so closing SEED-006 doesn't read as "CI latency solved".

</specifics>

<deferred>
## Deferred Ideas

- The build branch (classifier, `verify-change-scope`, dynamic `allowed-skips`): it re-opens only via SEED-006 `reopen_when`.
- Trimming the latest lane from PRs: rejected in D-05. Revisit only if the repo goes private (the minutes would then be real money) or the pins stop being exact.
- Dev-env `_build` cache for verify-credo/verify-dialyzer (219 deferred, "revisit with 221/222 data"): still open; not part of settling SEED-006.

### Reviewed Todos (not folded)
- `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md` ("Cut CI wall clock by making the test suite less sync-bound"). Deferred to v1.44, or planted as a seed. It is suite async/partitioning work that touches `test/` broadly, a different risk class from a conditional decision phase. It is cited in 222-DECISION.md as where the real wall-clock lever is.

</deferred>

---

*Phase: 222-seed-006-change-aware-lanes-conditional*
*Context gathered: 2026-09-29*
