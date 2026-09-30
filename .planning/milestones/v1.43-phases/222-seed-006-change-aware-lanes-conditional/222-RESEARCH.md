# Phase 222: SEED-006 Change-Aware Lanes (conditional) - Research

**Researched:** 2026-09-29
**Domain:** CI measurement tooling (Python stdlib), GitHub Actions/`gh` data collection, Elixir contract-test citation, GSD seed lifecycle
**Confidence:** HIGH

## Summary

This phase is a documentation/decision-record phase, not a code-change phase. The expected
outcome is CLOSE: re-run the Phase 214 inert-PR classifier against fresh data, confirm the
scratch numbers from discussion (0 of 28 strict-inert in the rolling 30 days; 6 of 28 on a
non-admissible docs-only ceiling, ~7–8% of billed PR minutes), and write `222-DECISION.md` plus
the closure edits to the seed, REQUIREMENTS.md, PROJECT.md, STATE.md and ROADMAP.md. No `ci.yml`
edit, no new Elixir test, no product code. Everything the planner needs is a **copy-and-extend**
of tooling that already exists twice in this repo (214 originated it, 218 copied it for its own
re-measure), plus a set of exact citations for the "closure is already pinned" claims (D-09).

The two building blocks — `inert-share.py` (BASE-01's fail-closed classifier) and
`check-citations.py` (the citation gate) — are both plain Python 3 stdlib, already proven with
`--self-test`, and already have a documented copy-and-retarget procedure from 218's copy (which
retargeted `check-citations.py`'s self-path strings and phase-number regex, and left the
copied summarizer's arithmetic untouched). 219 extended that same pattern one phase further
(214→218→219) with a `remeasure-N.py` that *imports* the copied summarizer rather than
reimplementing it. 222 should follow the same shape for its own two new windows.

**Primary recommendation:** Copy `inert-share.py` + `inert-allowlist.txt` verbatim (per D-01);
add a *second* file (or extend the copy minimally) that adds the `since-214` and `30d-now`
windows as new fixed-constant entries in a `WINDOWS` dict, mirroring the existing `all`/`30d`
shape exactly — do not invent a new CLI shape. Reuse 214's exact `gh pr list` / `gh api
--paginate .../files` commands unchanged, and write a small companion script (not prose
arithmetic) for the D-02 minute gate, following the `check-citations.py` self-test pattern so
every number in `222-DECISION.md` is reproducible by command.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fresh PR/file-list snapshot collection | CI / measurement tooling (phase-local `tools/`, stdlib + `gh` CLI) | — | Read-only `gh` calls, no maintainer grant needed (network read, no push) |
| Inert-share classification | CI / measurement tooling (copied `inert-share.py`) | — | Fail-closed logic already proven; copy per D-01, do not edit the original |
| Minute-gate arithmetic (D-02 part 2) | CI / measurement tooling (new small script) | — | Must be reproducible by command per the citation convention (214 §0, `check-citations.py`) |
| Decision record | Planning docs (`222-DECISION.md`) | — | Consumed by REQUIREMENTS.md/PROJECT.md/seed edits, not by product code |
| Seed lifecycle edit | Planning docs (`SEED-006-*.md` frontmatter + body) | GSD tooling (`gsd-tools.cjs` list-seeds / milestone-audit) | Frontmatter-only edit; tooling tolerance verified below (no patch) |
| CI contract citation verification | Test suite (existing, read-only citation) | — | D-09 only *cites* existing pins; no new test is written |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCOPE-01 | SEED-006 is decided from measured data: BUILD if BASE-01's inert-PR share (re-checked after ECON-07/CACHE-01) is material, else "measured, not worth it" and close the seed | This document's §1–§4 (measurement mechanics, gate math, citation gate) and §6–§9 (closure artifact mechanics) give every command the CLOSE branch needs; the CONTEXT.md D-02 gate and scratch numbers make CLOSE the expected outcome |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Re-measure with a copy of the 214 tool, not an edit of it.** Copy
  `.planning/phases/214-baseline-measurement/tools/inert-share.py` and `inert-allowlist.txt` to
  `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/`. The 214 tool, its `raw/`
  data, and its fixed windows stay frozen. The copy adds two windows: `since-214` (mergedAt after
  the last PR in 214's snapshot, 2026-09-26, through the collection date) and `30d-now` (rolling
  30 days ending on the collection date). Both bounds are fixed constants in the tool once
  collected, so re-runs are byte-identical. Collect a fresh `raw/prs/` snapshot in the 222 dir,
  using the same `gh pr list` and `gh api --paginate .../pulls/<n>/files` commands as 214 §6. Keep
  the count-drift check. First reproduce 214 exactly with the copy (`all` over the 214 PR set and
  `30d` = 0 of 20). Then report the new windows. The allowlist is not widened. If a new
  inert-looking path appears, it needs its own proof command, as in 214.
- **D-02: Two-part gate. Build only if both parts pass:**
  1. the strict fail-closed inert share is at least 20% of merged PRs in `30d-now`, with n ≥ 10; and
  2. the projected saving is at least 10% of that window's billed PR runner-minutes.
  Saving per skipped PR run = the skip-eligible lanes only (Browser E2E, Capture, PgBouncer, about
  19 billed min), from 219 warm runs 36455432448, 36450388764 and 36457705448. Push and dispatch
  runs never skip, so only `pull_request` runs count. Honesty note for the record: the thresholds
  were chosen after a scratch measurement had been seen. Say so in the record. The record should
  also say the margin is wide enough (0% against 20%, 7–8% ceiling against 10%) that no reasonable
  threshold changes the verdict.
- **D-03: Record a ceiling row. It is information only and does not vote.** Measure what broader,
  non-fail-closed classifiers would have skipped: `.github`-only, docs-only, and "no product
  code". Explain why each is not admissible. This row exists to show the CLOSE verdict is not an
  artefact of a strict allowlist.
- **D-04: `222-DECISION.md` in the phase dir, in 220-FINDINGS style.** Contains: the verdict line
  (`CLOSE` or `BUILD`); the D-02 gate with the honesty note; the 214 §6 baseline (1 of 40 all, 0 of
  20 in 30d, the one inert PR #8) and the re-measured windows, each with its exact command and raw
  path; the SEED-006 motivating runs 34757305454, 34757804720 and 34758908342; the ceiling row
  (D-03) and the minute math, citing the 219 warm runs and run 36086466934 (the BASE-01 55-billed-
  minute figure); a "what we would have built" section: SCOPE-01's four bullets, and the proof
  cost (it widens the `required_gate_errors/1` `with:` allowlist, adds an id to `@ci_job_ids`, and
  opens a new class of path that can launder the gate); a "where the latency actually is" note:
  the suite is about 191 of 209 s sync (run 36359135268), pointing at the deferred todo; the D-06
  latest-lane section. Use repo-relative paths only. The repo-hygiene guard scans tracked
  `.planning/`, so no home-path shapes in quoted command output.
- **D-05: The latest lane keeps running and voting on every `ci.yml` run. 222 does not trim it.**
  Reversibility: reversible — one matrix row, but trimming it later needs an `allowed-skips`
  design and weakening 220's `rule=lane-skip` contract. Every trim option is worse than the cost.
- **D-06: Record the measured latest-lane cost and the supersession explicitly.** Cost: about 6
  billed min warm (run 36501481301, 331 s, n=1) and about 7 cold (runs 36502353440, 36487483472,
  36484105399), so about 12–13 per merged change (PR + push). Wall clock: zero. Money: $0. Add a
  one-line forward pointer in `220-CONTEXT.md` D-07 ("Superseded by 222 D-05: kept every-run; see
  222-DECISION.md"). Do not rewrite 220's decision text.
- **D-07: Seed edit.** In `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md`: set
  `status: closed` and add `closed_on`, `closed_during: v1.43 Phase 222`, `closed_reason` and
  `decision: <path to 222-DECISION.md>`, following SEED-003's `retired_*` shape; replace
  `trigger_when: when relevant` with a numeric `reopen_when`: "strict inert share ≥ 5 of the last
  20 merged PRs by `<cited 222 inert-share.py command>`, or a new required lane moves the ci.yml
  critical path past the Browser E2E bound"; keep `audit_acknowledged`, and add an `## Outcome`
  body section. `closed` is a new status value. Check that gsd-tools' seed listing and milestone
  audit tolerate it. If they don't, record that as a finding and do not patch gsd-tools.
- **D-08: Requirement and PROJECT.md.** SCOPE-01: mark it `[x]` with an appended `Outcome: closed,
  measured, not worth it (222-DECISION.md: k of n inert)` line. The traceability row reads
  Complete; SCOPE-01's own "otherwise" branch makes that honest. PROJECT.md: the SEED-006
  milestone bullet (around line 42) becomes past tense. Add one Key Decisions row in 220's format.
  Hand-check STATE.md and ROADMAP.md after any `state.*` call.
- **D-09: No new test, and no `ci.yml` edit.** The decision record cites the existing pins:
  `required_gate_errors/1` (`test/threadline/ci_workflow_parity_contract_test.exs` around line
  1792) only allows `jobs` in the alls-green `with:`, so `allowed-skips` fails in any spelling
  (the quoted variant is tested around line 738); the frozen `@ci_job_ids` (around line 1744) and
  `gate_job_id_errors/1` (around line 1987) reject a new `verify-change-scope` job without a
  reviewed edit; `voting_lane_errors/1` `rule=lane-skip` controls (around lines 505-660);
  `release_control_plane_contract_test.exs` around line 90; `ci.yml`'s "deliberately carries no
  `paths:`" comment (around line 11). Verify these line references at plan time; they are
  approximate.

### Claude's Discretion

- The exact layout of `222-DECISION.md`, the tool-copy flag names, and whether the re-check is a
  `--window` or `--last N` mode.
- Plan count and wave shape. This is a planning-only phase: expect 1–2 plans, no maintainer
  checkpoint, and no push. Landing rides the next landing branch.
- The re-open trigger's exact second clause wording.

### Deferred Ideas (OUT OF SCOPE)

- The build branch (classifier, `verify-change-scope`, dynamic `allowed-skips`): it re-opens only
  via SEED-006 `reopen_when`.
- Trimming the latest lane from PRs: rejected in D-05. Revisit only if the repo goes private (the
  minutes would then be real money) or the pins stop being exact.
- Dev-env `_build` cache for verify-credo/verify-dialyzer (219 deferred, "revisit with 221/222
  data"): still open; not part of settling SEED-006.
- `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md` ("Cut CI wall clock by
  making the test suite less sync-bound"): deferred to v1.44, or planted as a seed; cited in
  222-DECISION.md as where the real wall-clock lever is.
</user_constraints>

## 1. Copying and extending `inert-share.py` — exact mechanics

**Read this session:** `.planning/phases/214-baseline-measurement/tools/inert-share.py` (175
lines) and `tools/inert-allowlist.txt` (62 lines). `[VERIFIED:
.planning/phases/214-baseline-measurement/tools/inert-share.py:34-42]`:

```python
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PRS_DIR = os.path.join(PHASE_DIR, "raw", "prs")
ALLOWLIST = os.path.join(TOOLS_DIR, "inert-allowlist.txt")
PROOF_SEP = " # proof: "
WINDOWS = {
    "all": (None, None),
    "30d": ("2026-08-27T00:00:00Z", "2026-09-26T23:59:59Z"),
}
```

`PRS_DIR` and `ALLOWLIST` are both derived from `__file__`'s own location (`TOOLS_DIR` = the
copy's own directory, `PHASE_DIR` = its parent). **This means a byte-for-byte copy into
`.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py`
automatically resolves `raw/prs/` and `inert-allowlist.txt` relative to the 222 phase dir, with
zero path edits needed in the copied file itself.** The only edits the copy needs are:

1. The `WINDOWS` dict: add `since-214` and `30d-now` as two more fixed-constant entries,
   collected once and then frozen, exactly like `all`/`30d` today. Do not make the window bounds
   a runtime argument — D-01 requires "both bounds are fixed constants in the tool once
   collected, so re-runs are byte-identical."
2. The docstring's `Usage`/`Inputs` lines, which hardcode the phase-214 path in their example
   invocation strings (lines 4-14) — cosmetic only, but 218's precedent (see below) shows the
   convention is to update these self-referential path strings in the copy.
3. Nothing else. `is_inert_pr`, `load_allowlist`, `load_prs`, `in_window`, `summarize`,
   `self_test` and `main` are pure functions with no phase-214-specific literals except the two
   docstring path strings and the `WINDOWS` dict — copy them unchanged.

**`--self-test` cases** `[VERIFIED: .planning/phases/214-baseline-measurement/tools/inert-share.py:117-154]`:
four `is_inert_pr`/`summarize` assertions (allowlisted+unknown → non-inert; only-allowlisted →
inert; empty file list → non-inert; unmatched sibling `.planning/STATE.md.bak` → non-inert), plus
an empty-PR-set assertion, a zero-in-window assertion, and a proofless-allowlist-entry rejection
assertion. These are all pure-function tests with no window dependency, so **the copy's
`--self-test` reproduces byte-identical output with zero edits** — this is the cheapest possible
proof that the copy is faithful before any live data is collected.

**Count-drift check** `[VERIFIED: .planning/phases/214-baseline-measurement/tools/inert-share.py:73-87]`:
`load_prs` raises `DataError` if a PR's file-list line count differs from `index.json`'s
`changedFiles` field. This is preserved automatically by copying `load_prs` unchanged.

**Reproducing 214 exactly, precisely.** D-01 says "first reproduce 214 exactly with the copy
(`all` over the 214 PR set and `30d` = 0 of 20)". Since the copy resolves `raw/prs/` relative to
*its own* directory (the 222 phase dir, per point 1 above), reproducing 214's numbers means one
of two things, and the planner must pick one explicitly:

- **(a) Point the copy at 214's `raw/` via a symlink or by literally copying the `raw/prs/`
  directory tree into 222's `tools/../raw/prs/` before running `--window all`** — this is the
  more literal reading of "the copy... reproduces 214" and costs nothing extra since `raw/prs/`
  is already committed JSON+text, no network calls; **or**
- **(b) collect 222's own fresh, superset snapshot first (per D-01's third bullet: "collect a
  fresh `raw/prs/` snapshot... using the same commands as 214 §6"), then filter that fresh
  snapshot down to exactly 214's PR set (PRs #1–#40, `jq 'map(select(.number <= 40))'` or by an
  explicit number-list from 214's own `index.json`) as a `--self-test`-adjacent sanity command,
  proving the fresh snapshot agrees with 214 on the PRs both snapshots contain.**

**Recommendation: (b).** D-01's own ordering — "collect a fresh raw/prs/ snapshot... First
reproduce 214 exactly with the copy... Then report the new windows" — reads as one fresh
snapshot, filtered three ways (the 214-reproduction subset, `since-214`, `30d-now`), not two
separate raw trees. It also matches 219's precedent: 219 did **not** re-copy 214's raw data into
its own `raw/`; it collected its own fresh runs and reconciled against the *committed baseline
figures* (a number, e.g. "46.3 min (run 36086466934)"), not against a re-fetched copy of 214's
raw JSON. The 222 tool's `--window all` on the fresh snapshot should reproduce 1 of 40 (or more,
since more PRs have merged since; state the new `all` total honestly and separately from the
214-subset check) — the number that must match exactly is the **214-subset filtered count**, not
the whole-history `all` count, which will legitimately grow. Concretely: add a `--pr-numbers-max
40` mode, or simpler, a fixture/one-off check `jq '[.[] | select(.number <= (last 214 PR
number))]' raw/prs/index.json | count-inert` reproduces 214's `1 of 40`.

**Deterministic commands to propose (concrete):**

```bash
mkdir -p .planning/phases/222-seed-006-change-aware-lanes-conditional/tools
mkdir -p .planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs
cp .planning/phases/214-baseline-measurement/tools/inert-share.py \
   .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py
cp .planning/phases/214-baseline-measurement/tools/inert-allowlist.txt \
   .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-allowlist.txt
# Edit only the WINDOWS dict and the docstring path strings in the copy.

# Fresh snapshot (same commands as 214 §6, `[VERIFIED:
# .planning/phases/214-baseline-measurement/214-BASELINE.md:266]`):
gh pr list --repo szTheory/threadline --state merged --base main --limit 500 \
  --json number,title,mergedAt,headRefName,changedFiles \
  > .planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs/index.json
# For each PR number N in that index:
gh api --paginate "repos/szTheory/threadline/pulls/${N}/files?per_page=100" \
  --jq '.[].filename' | sort \
  > ".planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs/${N}.files.txt"

# Reproduce 214's 214-subset (fixed to 214's exact 40 PRs, do NOT recompute from "all merged so far"):
python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window all-214-subset
python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window 30d   # 214's fixed 30d window, must still read "0 of 20"
python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window since-214
python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window 30d-now
python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --self-test
```

Note the copy must keep 214's original `30d` window entry (fixed dates 2026-08-27→2026-09-26) in
its `WINDOWS` dict alongside the two new ones, specifically so `--window 30d` on the fresh
snapshot re-proves 214's own historical claim (0 of 20) did not change retroactively — this is
the cheapest possible regression check on the fresh collection itself. `[ASSUMED]`: naming a
window `all-214-subset` is a naming choice for the planner; D-01 does not mandate a literal
string, only that reproduction happens before the new windows are reported.

## 2. Fresh-data collection commands (from 214-BASELINE.md §6)

`[VERIFIED: .planning/phases/214-baseline-measurement/214-BASELINE.md:266]` — quoted verbatim:

> **PR data.** Merged PRs into main come from `gh pr list --repo szTheory/threadline --state
> merged --base main --limit 500 --json number,title,mergedAt,headRefName,changedFiles`, saved as
> `raw/prs/index.json`. Each PR's full file list comes from `gh api --paginate
> repos/szTheory/threadline/pulls/<n>/files?per_page=100 --jq '.[].filename'`, saved sorted as
> `raw/prs/<n>.files.txt`. The classifier refuses to run if any list is missing or its line count
> differs from `changedFiles`.

These two commands are read-only GitHub REST calls (`gh pr list`, `gh api ... /files`) — no
`gh pr create`, `gh pr merge`, `gh run rerun`, or any `-X POST/PUT/PATCH/DELETE`. They need no
maintainer push/dispatch grant; they are the same class of call 214's own `verify-phase.sh`
positively enforces is absent from tools (`GH_WRITE` regex at
`.planning/phases/214-baseline-measurement/tools/verify-phase.sh`, quoted below). Executors can
run the collection directly without a checkpoint.

**Field selection matters for repo hygiene.** `[VERIFIED: .planning/phases/214-baseline-measurement/raw/prs/index.json:1-7]`
— the committed `index.json` for PR #1 contains exactly `changedFiles`, `headRefName`,
`mergedAt`, `number`, `title`. No `author`, `url`, `login`, or `avatar_url` field is present,
because the `--json` flag lists only those five fields — `gh pr list --json` fetches only the
named fields, it does not fetch-then-filter. **The 222 collection command must use the identical
`--json number,title,mergedAt,headRefName,changedFiles` field list, unchanged**, both to
reproduce 214's shape exactly and to avoid pulling PII (author logins, avatar URLs) into a
tracked planning file that the repo-hygiene guard does not itself screen for (see §7).

**`raw/prs/<n>.files.txt`** contains one file path per line, sorted, with no metadata beyond the
path (`[VERIFIED: .planning/phases/214-baseline-measurement/raw/prs/8.files.txt:1-2]`: two lines,
`.planning/ROADMAP.md` and `.planning/STATE.md`, nothing else). This format carries no PII risk.

## 3. D-02 part-2 minute gate — where the numbers live, and a deterministic script

**Skip-eligible lane costs (warm), read from 219-REMEASURE.md.** `[VERIFIED:
.planning/phases/219-deps-only-build-cache/219-REMEASURE.md:102-104]` — quoted verbatim (warm
column, run IDs as-is):

> | verify-pgbouncer-topology | PgBouncer transaction topology | 109 s (run 36083676177) | 114 s
> (run 36362405054) | 72 s (run 36457705448) | 112 s (run 36446346094) | −37 s | −42 s |
> `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
> | verify-example-browser | Example app browser E2E (Playwright) | 623 s (run 36256339043) |
> 643 s (run 36362405054) | 547 s (run 36455432448) | 634 s (run 36446346094) | −76 s | −96 s |
> `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set warm` |
> | verify-capture | Tier A capture lane (byte-stable evidence) | 532 s (run 36258071425) | 499 s
> (run 36359132030) | 413 s (run 36450388764) | 325 s (run 36447911272) | −119 s | −86 s, noisy
> (4b) | `python3 .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py jobs --set
> warm` |

The relevant column (warm, third data column) gives: PgBouncer 72 s (run 36457705448), Browser
E2E 547 s (run 36455432448), Capture 413 s (run 36450388764). Summed: 72 + 547 + 413 = 1032 s =
17.2 unrounded minutes. **Billed** per-job (round each job up to a whole minute, per the BASE-01
convention `[VERIFIED: .planning/phases/214-baseline-measurement/214-BASELINE.md:21]`: "billed is
the sum of each job's seconds rounded up to a whole minute"): ceil(72/60)=2, ceil(547/60)=10,
ceil(413/60)=7 → **2 + 10 + 7 = 19 billed minutes.** This reproduces CONTEXT.md D-02's cited "about
19 billed min" figure exactly — confirming the number is a sum of three specific job-level billed
minutes, not a workflow-level total.

**BASE-01 per-PR billed minutes (denominator input).** `[VERIFIED:
.planning/phases/214-baseline-measurement/214-BASELINE.md:163]`: "per PR (one ci.yml pull_request
run) | n=20 | unrounded p50 46.3 min (run 36086466934) | ... | billed p50 55 min (run
36086466934)". This is the run 36086466934 BASE-01 figure D-04 asks the decision record to cite.

**What the D-02 part-2 gate actually needs, precisely.** The gate is "the projected saving is at
least 10% of that window's billed PR runner-minutes" — i.e. `(inert_prs_in_window × 19) /
total_billed_PR_minutes_in_30d-now`, not a comparison against the BASE-01 p50 alone. This means
the 222 tool needs the **sum of billed minutes across every `pull_request` ci.yml run merged (or
opened, per whichever "window" definition the tool's PR-window uses — see the open question
below) in the `30d-now` window**, which is a `gh run list`/`summarize-ci.py`-style aggregation,
not a per-PR constant. There are two ways to get this without a fresh `gh run list` re-collection:

1. **Approximate with the BASE-01/219 p50 as a per-PR constant** (`n_prs_in_window × 55 billed
   min`), citing that this is an approximation and stating the assumption explicitly. This is
   cheap, deterministic, and matches the CONTEXT's own scratch math style ("114 of roughly
   1,400–1,540 billed PR minutes" is exactly `n × p50` arithmetic: 28 PRs × ~50–55 billed min ≈
   1,400–1,540). `[ASSUMED]`: using a constant per-PR minute figure instead of measuring each PR
   run's actual billed minutes individually.
2. **Collect a fresh `gh run list --workflow ci.yml --event pull_request` sample for the window**
   and sum actual billed minutes per run, reusing `summarize-ci.py`'s `runner-minutes` command
   (copied alongside, as 219 did) against the fresh 222 `raw/ci/` snapshot. This is the more
   rigorous option and matches how 214/219 computed real billed-minute totals, rather than
   inferring them from a p50 proxy.

**Recommendation:** copy `summarize-ci.py` and `collect-ci-runs.sh` into 222's `tools/` (as 219
did from 218) so the minute math is computed the same way 214/219 computed it — by real per-run
job seconds, not a p50 proxy — and expose it as `python3
.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py
minute-gate --window 30d-now`, following 219's `remeasure-219.py` pattern of *importing* the
copied summarizer's arithmetic rather than reimplementing it
(`[VERIFIED: .planning/phases/219-deps-only-build-cache/219-REMEASURE.md:9]`, quoted: "the
phase 218 collector, summarizer and citation checker, copied into this phase's `tools/` directory
... Figures: `remeasure-219.py --help` imports the copied summarizer's arithmetic unchanged"). A
self-test in this script (mirroring `inert-share.py`'s `--self-test` and `check-citations.py`'s
fixture-based self-test) should assert the exact 19-billed-min-per-skip constant and the ceiling
arithmetic, so the gate's own math is provable independent of the live `gh` data.

**Open question the planner should resolve:** whether `30d-now`'s "billed PR runner-minutes"
denominator counts every `pull_request` ci.yml run in the window (including ones from PRs that
were later closed unmerged, or re-run after a push) or only the one counted run per *merged* PR
(matching `inert-share.py`'s PR-centric denominator). `inert-share.py`'s numerator is merged PRs;
for the ratio to be apples-to-apples, the denominator should also be "one representative
(p50 or latest) `pull_request` run per merged PR in the window," not every raw CI run. This
should be stated explicitly in `222-DECISION.md`'s honesty note, alongside the pre-seen-threshold
disclosure D-02 already requires.

## 4. `check-citations.py` / `verify-phase.sh` pattern — reuse for a 222 phase gate

`[VERIFIED: .planning/phases/214-baseline-measurement/tools/check-citations.py:1-37]`. The
checker's rule: every non-heading, non-blank line outside a fenced code block that still
contains a digit after stripping ISO dates, `p50`/`p95`, requirement IDs, phase numbers, hex SHAs
and version strings must carry either `run <8+ digit id>` or a backticked command starting with
`gh|mix|MIX_ENV=|git|python3|bash|jq|psql|elixir`. One structural gotcha, already exercised by
218's copy: `check-citations.py`'s phase-number exemption regex is hardcoded per-phase (`[VERIFIED:
.planning/phases/214-baseline-measurement/tools/check-citations.py:31]`, quoted:
`re.compile(r"\b214(?:-0\d)?\b")`, and 218's copy diff shows it becomes `re.compile(r"\b21[4-8](?:-0\d)?\b")`
— `[VERIFIED: diff output, this session, `git diff --no-index
.planning/phases/214-baseline-measurement/tools/check-citations.py
.planning/phases/218-ci-economy-remove-waste/tools/check-citations.py`]`). **222's copy must widen
this regex to admit 222 itself** (e.g. `\b21[4-9]|220|221|222(?:-0\d)?\b` or equivalent), or every
line mentioning "Phase 222" or "222-DECISION.md" with a digit elsewhere on the line will register
as a false-positive uncited-figure hit. This is the single most likely self-inflicted gate failure
if the copy is done too literally.

**218's copy did *not* copy `verify-phase.sh` or `check-baseline-complete.py`/
`check-project-baseline.sh`** — it copied only `check-citations.py`, `collect-ci-runs.sh`,
`summarize-ci.py`, plus its own `remeasure-218.py` and `fixtures/`. 219 followed the identical
subset. **Recommendation for 222: follow the same subset, and write one new
`verify-phase.sh`-shaped gate script (not a copy of 214's, since 214's checks are BASE-01/BASE-02
specific) that runs, in order:**

1. `python3 tools/inert-share.py --self-test`
2. `python3 tools/inert-share.py --window all-214-subset` (reproduction check) and `--window 30d`
   (reproduction check)
3. `python3 tools/check-citations.py --self-test`
4. `python3 tools/check-citations.py 222-DECISION.md`
5. (if built) `python3 tools/remeasure-222.py --self-test` and the minute-gate command
6. A repo-hygiene / machine-path grep over the phase dir's own `raw/` and doc, mirroring 214's
   `verify-phase.sh` closing check (`MACHINE_PATH='/Users/[A-Za-z0-9_]|/home/[a-z]|~/[A-Za-z0-9_.]'`)
   — this is a useful local pre-check before `bin/verify-repo-hygiene` runs on the whole tree in
   `mix ci.all`.
7. A no-write-gh-usage grep over `tools/*.sh` and `tools/*.py`, exactly 214's `GH_WRITE` regex
   (`gh (workflow run|run rerun|run cancel|pr create|pr comment|pr merge|issue)|--method|-X
   (POST|PUT|PATCH|DELETE)`), proving the new tools stay read-only.

This single script becomes the phase's automated Nyquist gate (see Validation Architecture
below) and the natural home for "SCOPE-01 line present" and "seed frontmatter present" checks
(D-04/D-07/D-08 acceptance).

## 5. D-09 pin-line verification (line numbers, verified this session)

`[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:1792]`, quoted:
```
  defp required_gate_errors(yaml_by_path) do
```
`[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:1744]` — `@ci_job_ids` (module
attribute set literal spanning from this line; confirmed present via `grep -n "@ci_job_ids ="`).
`[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:1987]`, quoted:
```
  defp gate_job_id_errors(doc) do
```
`[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:1685]`, quoted:
```
  defp voting_lane_errors(yaml_by_path) do
```
— note this is the function *definition* line; the `rule=lane-skip` string literals it can emit
appear at lines 560, 572, 598, 605, 612, 619 `[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:2046]`,
quoted: `else: ["rule=lane-skip: the step carries `if`, so a lane could skip it (D-15)"]`. CONTEXT's
"around lines 505-660" is the block of *test assertions* exercising `rule=lane-skip`, not the
`voting_lane_errors/1` definition itself (which sits at 1685) — the planner should cite line 1685
for the function and 505-660 (or the more precise 560-619 range found this session) for its
`rule=lane-skip` test coverage, to avoid conflating the two in `222-DECISION.md`.

`[VERIFIED: test/threadline/release_control_plane_contract_test.exs:90]`, quoted:
```
  test "the required check launders nothing: allowed-skips and allowed-failures stay empty" do
```
(with the assertion at line 101: `refute uncommented =~ ~r/^\s*allowed-skips:/m`).

`[VERIFIED: .github/workflows/ci.yml:9-16]`, quoted:
```
# NO TRIGGER-LEVEL PATH FILTERS — a decision, not an omission (Phase 198, D-10 /
# D-20). This workflow deliberately carries no `paths:` key under `on:`.
```

**All six D-09 citations check out at or within one line of CONTEXT's stated approximate
numbers.** No drift found; the planner can cite these as confirmed rather than approximate in
`222-DECISION.md`.

## 6. D-07: does gsd-tools tolerate `status: closed` on a seed?

`[VERIFIED: <home>/.claude/gsd-core/bin/lib/commands.cjs:309-347]`, quoted (the `list-seeds`
handler, `cmdListSeeds`):
```
const status = (fmStr(fm.status) || 'dormant').toLowerCase().trim() || 'dormant';
```
`status` is read as an opaque, free-text string and only defaulted to `'dormant'` when the
frontmatter field is *missing or empty* — `status: closed` passes through unchanged, is bucketed
correctly in the `summary` map, and renders in the seed table with no special-casing or crash
risk. `list-seeds` has no enum/allowlist of known status values.

`[VERIFIED: <home>/.claude/gsd-core/bin/lib/audit.cjs:619-634]`, quoted (the milestone-audit
"unimplemented seeds" scanner, `scanSeeds`):
```
/**
 * Scan .planning/seeds/SEED-*.md for unimplemented seeds.
 * Unimplemented if status in ['dormant', 'active', 'triggered'].
 */
function scanSeeds(planDir) {
    ...
    const unimplementedStatuses = new Set(['dormant', 'active', 'triggered']);
```
`closed` is not in this set (nor is SEED-003's existing `retired`, which is the direct precedent
D-07 asks to follow). A seed with `status: closed` is therefore **correctly excluded** from the
milestone audit's list of open/unimplemented seeds — the same mechanism that already lets
SEED-003's `status: retired` disappear from that list cleanly.

**Finding for the record (no patch needed):** both `gsd-tools` seed surfaces (`list-seeds` and
the milestone-audit `scanSeeds`) tolerate an arbitrary new status string, including `closed`,
without modification. `list-seeds` will display it as its own status bucket; the milestone audit
will treat it as resolved (not flagged), identically to how `retired` is treated today. This
should be recorded as a finding in `222-DECISION.md` or the phase SUMMARY, per D-07's instruction
to "record that as a finding and do not patch gsd-tools" — except here the finding is *positive*
(tolerance confirmed), not a gap.

## 7. Repo-hygiene guard constraints for new tracked planning files

`[VERIFIED: bin/verify-repo-hygiene:1-95]` (header comment, this session). The guard's scope is a
`git grep -I` over every tracked, non-binary file for seven machine-local-path pattern families
(macOS/Linux/Windows home paths, `~/`, macOS per-user temp, Claude-encoded project paths,
JSON-escaped home paths). **It does not scan for PII fields inside JSON** (author logins, emails,
avatar URLs) — that risk is controlled only by *which fields the collection command requests*,
not by any downstream guard. This makes §2's field-list discipline (`--json
number,title,mergedAt,headRefName,changedFiles`, matching 214 exactly, no `author`/`url`/`login`)
the sole control against PII leaking into a newly tracked `raw/prs/index.json`. The guard *does*
apply to every new tracked file the phase adds (the copied tools, the fresh `raw/prs/*`, and
`222-DECISION.md` itself), so:

- Command output quoted inside `222-DECISION.md` must not contain a local absolute path (per
  D-04's own instruction: "Use repo-relative paths only... no home-path shapes in quoted command
  output").
- 214's own `raw/prs/index.json` and `.files.txt` files contain no local paths by construction
  (they are `gh` API output, not local filesystem paths) — the fresh 222 snapshot inherits this
  safety property automatically, as long as the `--json` field list is not widened.

## 8. Precedents for closure artifacts: PROJECT.md row and SEED-003/220 shape

`[VERIFIED: .planning/phases/220-newest-toolchain-lane/220-04-PLAN.md:124]`, quoted (the PROJECT.md
Key Decisions row format used for a "not yet" outcome — 222 should mirror this shape for its
"closed" outcome):
```
3. PROJECT.md Key Decisions: add one row via a scoped Edit at the end of the table: `| Newest-toolchain lane (Elixir 1.20.x / OTP 29.x / PG 18): not yet (Phase 220) | <one-clause failure summary>; see phases/220-newest-toolchain-lane/220-FINDINGS.md | ⚠ Not yet: SEED-007 re-triggers; floor and current unchanged |`.
```
For 222, the equivalent row shape is: `| Change-aware lanes (SEED-006): closed (Phase 222) |
<one-clause "measured, not worth it" summary>; see
phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md | ✓ Closed: k of n inert,
reopen_when <clause> |` — a scoped `Edit` appending one row, not a rewrite of the table.

`[VERIFIED: .planning/seeds/SEED-003-ecosystem-integrations.md:1-8]`, quoted (the `retired_*`
frontmatter shape D-07 explicitly asks to follow):
```
---
id: SEED-003
status: retired
planted: 2026-05-08
retired_on: 2026-05-24
retired_during: v1.20 closeout preparation
retired_reason: Kept as strategic direction in milestone arc and product narrative, but not maintained as an open implementation seed.
scope: Large
---
```
The 222 seed edit should use the parallel `closed_*` field names D-07 specifies
(`closed_on`, `closed_during`, `closed_reason`, plus a `decision:` field SEED-003 doesn't have,
pointing at `222-DECISION.md`) — SEED-003 has no `decision:` field because it predates this
convention, but D-04/D-07 both cite `222-DECISION.md` as the canonical record, so adding
`decision: .planning/phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md` is
consistent with the phase's own emphasis on citable evidence.

`[VERIFIED: .planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md:1-12]`, quoted (the
current SEED-006 frontmatter to be edited):
```
---
id: SEED-006
status: dormant
planted: 2026-09-13
planted_during: v1.41 Phase 201 planning, after Phase 200 closeout
trigger_when: when relevant
scope: unknown
audit_acknowledged:
  milestone: v1.41
  at: 2026-09-25
  status: dormant
---
```
D-07 says "keep `audit_acknowledged`" — note its nested `status: dormant` value will now disagree
with the top-level `status: closed`; this is a historical record of the *prior* audit
acknowledgment (v1.41, when the seed was still dormant) and should not be rewritten to match —
rewriting it would falsify the audit trail of what was true when SEED-006 was acknowledged. This
is worth a one-line note in `222-DECISION.md` or the seed's own `## Outcome` section so a future
reader doesn't read the stale nested value as an inconsistency bug.

`[VERIFIED: .planning/PROJECT.md:42]`, quoted:
```
- SEED-006: change-aware lanes behind a tested fail-closed classifier (last phase, only after the cheap wins are measured)
```
This is the exact bullet D-08 asks to convert to past tense.

`[VERIFIED: .planning/REQUIREMENTS.md:112-120]`, quoted (SCOPE-01, the requirement D-08 asks to
mark `[x]` with an appended Outcome line):
```
### Change-aware lanes (conditional)

- [ ] **SCOPE-01**: SEED-006 is decided from measured data. If BASE-01's inert-PR share, re-checked after ECON-07 and CACHE-01, is material, build:
  - a `verify-change-scope` job with a table-tested, fail-closed `bin/classify-ci-lanes` classifier (anything unknown runs the full matrix);
  - a dynamic `allowed-skips` only for skip-eligible jobs (never `verify-test` or the rehearsal);
  - an empty skip list on push and on dispatch;
  - a `ci-required` step that re-justifies each skip.

  Otherwise record "measured, not worth it" and close the seed.
```

## 9. Validation Architecture

This phase produces no application code and no new Elixir test (D-09). Its "test framework" is
the same Python-stdlib self-test + citation-gate convention 214/218/219 already established, plus
the existing `mix ci.all` suite (unchanged, must stay green per the code-context note).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Python 3 stdlib self-tests (`--self-test` flag convention) + a phase-local `verify-phase.sh`-shaped gate script |
| Config file | none — each tool is a standalone script under `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/` |
| Quick run command | `python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --self-test && python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py --self-test` |
| Full suite command | the phase's own `verify-phase.sh`-shaped script (§4), plus `mix ci.all` for the whole-repo gate (repo-hygiene, planning-dependency, removed-artifact contracts) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCOPE-01 (measurement re-check) | fresh inert-share numbers reproduce 214 and report the two new windows | unit (self-test) + data | `python3 .../tools/inert-share.py --self-test && python3 .../tools/inert-share.py --window 30d-now` | ❌ Wave 0 — tool copy + fresh `raw/prs/` collection is plan 01's own work |
| SCOPE-01 (minute gate) | D-02 part-2 gate computed deterministically, not by prose arithmetic | unit (self-test) + data | `python3 .../tools/remeasure-222.py --self-test && python3 .../tools/remeasure-222.py minute-gate --window 30d-now` | ❌ Wave 0 — new script |
| SCOPE-01 (decision record citation) | every figure in `222-DECISION.md` is cited by run ID or command | mechanical | `python3 .../tools/check-citations.py .../222-DECISION.md` | ❌ Wave 0 — copy of `check-citations.py`, retargeted phase-number regex (§4) |
| D-09 (closure is already pinned) | the six cited contract-test line references still exist and still enforce the named rules | existing, cited only | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/release_control_plane_contract_test.exs` (no new assertions; existing suite) | ✅ already exists, verified this session (§5) |
| D-07 (seed status tolerance) | `status: closed` does not break `list-seeds` or milestone audit | manual code-reading finding (no test needed; confirmed by reading `gsd-tools` source, §6) | n/a — a finding, not a testable phase artifact | n/a |
| whole-repo gate | no product/CI code regressed, no repo-hygiene violation from new tracked files | full suite | `mix ci.all` | ✅ existing |

### Sampling Rate
- **Per task commit:** the tool self-tests (`--self-test` on each copied/new script) plus
  `check-citations.py` against the in-progress `222-DECISION.md`.
- **Per wave merge:** the full phase gate script (§4) plus `mix ci.all`.
- **Phase gate:** `mix ci.all` green, plus every acceptance criterion in D-04/D-07/D-08 satisfied
  before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py` and
      `inert-allowlist.txt` — copied from 214, `WINDOWS` extended with `since-214`/`30d-now`
- [ ] `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py`,
      `collect-ci-runs.sh`, `summarize-ci.py` — copied from 218/219, phase-number regex widened
      to admit 222
- [ ] `.planning/phases/222-seed-006-change-aware-lanes-conditional/tools/remeasure-222.py` — new,
      imports the copied summarizer, implements the D-02 minute-gate arithmetic with its own
      `--self-test`
- [ ] `.planning/phases/222-seed-006-change-aware-lanes-conditional/raw/prs/` — fresh snapshot,
      collected via §2's exact `gh` commands
- [ ] A phase-gate script (verify-phase.sh-shaped, §4) tying the above together into one
      pass/fail command

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fail-closed PR-file classification | a new classifier script | copy of `inert-share.py` (D-01) | already proven fail-closed with `--self-test`; a rewrite risks silently changing the allowlist semantics |
| Citation enforcement on the decision doc | manual review / prose citations | copy of `check-citations.py`, retargeted phase-number regex | mechanical, already proven against fixtures; catches an uncited figure the human eye would miss |
| Job-duration/billed-minute arithmetic | prose arithmetic in `222-DECISION.md` | a copied `summarize-ci.py` + a new `remeasure-222.py` that imports it | 219 already established this exact composition pattern; prose arithmetic has no self-test and cannot be re-run to confirm |
| Seed status-value validation | a `gsd-tools` patch to add `closed` to an enum | nothing — confirmed by reading source (§6) that no patch is needed | patching `gsd-tools` is out of scope per D-07's own instruction, and unnecessary since tolerance is already there |

**Key insight:** every mechanical piece this phase needs (classifier, citation gate, minute
arithmetic, phase gate) already exists as a proven pattern in 214/218/219. The only genuinely new
code is the small `remeasure-222.py` minute-gate script and the `WINDOWS` dict extension — both
additive, not novel design.

## Common Pitfalls

### Pitfall 1: Reproducing "all" against a growing PR history instead of 214's frozen subset
**What goes wrong:** running `--window all` on a fresh snapshot returns a bigger `n` than 214's
40, since more PRs have merged since 2026-09-26, so a literal "does `all` still say `1 of 40`?"
check fails even though nothing regressed.
**Why it happens:** `inert-share.py`'s `all` window is defined as "every merged PR in
index.json" — it is not frozen to 214's specific 40 PRs, only its *date bounds* are unbounded.
**How to avoid:** add an explicit 214-subset filter (§1) as the reproduction check, and report the
fresh, larger `all` total separately and honestly.
**Warning signs:** a reproduction check that asserts `n == 40` will start failing the moment a
single new PR merges after collection.

### Pitfall 2: `check-citations.py`'s hardcoded phase-number regex rejecting valid 222 citations
**What goes wrong:** every line in `222-DECISION.md` that mentions "Phase 222" or a `222-0N` plan
number alongside another digit gets flagged as an uncited figure, because the copied checker's
`EXEMPT` list still only exempts `214` (or `214-218` if copied from 218 verbatim without
re-widening).
**Why it happens:** the regex is phase-number-specific by design (so a 3-digit *measured* figure
that happens to equal a phase number isn't wrongly exempted) — `[VERIFIED:
.planning/phases/214-baseline-measurement/tools/check-citations.py:31]`.
**How to avoid:** widen the regex in the 222 copy before running the checker; verify with the
self-test *and* a positive check that a line with "Phase 222" and no other digit passes.
**Warning signs:** `check-citations.py 222-DECISION.md` reports uncited lines whose only "figure"
is the phase number itself.

### Pitfall 3: Treating the D-02 minute-gate denominator as a p50 proxy without disclosing it
**What goes wrong:** `222-DECISION.md` states a precise percentage (e.g. "7.4% of billed PR
minutes") computed from `n × p50_billed`, which reads as a measured figure but is actually an
extrapolation from a single BASE-01/219 sample point, not from real per-PR-run billed minutes in
the `30d-now` window.
**Why it happens:** it's the cheapest computation and matches the discussion's own scratch-math
style — but the discussion's number was explicitly labeled a "scratch measure," not a phase
deliverable.
**How to avoid:** either collect real per-run billed minutes for the window (§3, option 2,
preferred) or, if using the p50-proxy shortcut, label every such figure `[inference]` per the
citation convention and state the approximation in the honesty note D-02 already requires.
**Warning signs:** `check-citations.py` will not catch this — it only checks *citation presence*,
not *whether the cited method matches the precision implied by the prose*. This is a reviewer/
plan-checker concern, not a mechanical one.

### Pitfall 4: Rewriting `audit_acknowledged.status` to match the new top-level `status: closed`
**What goes wrong:** the seed edit "helpfully" updates the nested `audit_acknowledged.status`
field from `dormant` to `closed` to look consistent, destroying the historical record of what
the v1.41 audit actually acknowledged.
**Why it happens:** the two `status` fields (top-level and nested) look like they should agree.
**How to avoid:** leave `audit_acknowledged` exactly as-is (D-07 says "keep `audit_acknowledged`");
add a note explaining the apparent mismatch is expected (§8).
**Warning signs:** a diff on the seed file touching the `audit_acknowledged:` block at all.

## Code Examples

### Copying a phase's measurement tool and retargeting only its self-references (219's own description of doing this for 218→219)
```
# Source: .planning/phases/219-deps-only-build-cache/219-REMEASURE.md, quoted verbatim, `[VERIFIED]`
Tools: the phase 218 collector, summarizer and citation checker, copied into this phase's tools/
directory so that phase 219 runs never land in the 214 or 218 evidence. The copies differ from
the 218 originals only in their self-path strings and in the checker's phase-number exemption,
which now accepts phases 214 through 219 (`git diff --no-index
.planning/phases/218-ci-economy-remove-waste/tools/check-citations.py
.planning/phases/219-deps-only-build-cache/tools/check-citations.py`).
```

### `inert-share.py`'s self-test shape (copy this unchanged; it needs no window data)
```python
# Source: .planning/phases/214-baseline-measurement/tools/inert-share.py:117-154, `[VERIFIED]`
def self_test():
    globs = [".planning/STATE.md", ".planning/seeds/*"]
    cases = [
        ("allowlisted + unknown file is non-inert",
         is_inert_pr([".planning/STATE.md", "lib/threadline.ex"], globs), False),
        ("only allowlisted files is inert",
         is_inert_pr([".planning/STATE.md", ".planning/seeds/SEED-006.md"], globs), True),
        ("empty file list is non-inert", is_inert_pr([], globs), False),
        ("unmatched sibling of an entry is non-inert",
         is_inert_pr([".planning/STATE.md.bak"], globs), False),
    ]
    ...
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Phase-local measurement tool written from scratch each phase | Copy the prior phase's tool, retarget only self-path strings and the phase-number citation regex | established by 218 (from 214), repeated by 219 (from 218) | 222 is the third generation of this pattern; deviating from it (e.g. rewriting `inert-share.py`) would break D-01's explicit "copy, not edit" instruction |
| Prose arithmetic for CI cost claims | a small `remeasure-N.py` importing the prior summarizer, with its own `--self-test` | established by 219 | keeps every number in a decision doc re-runnable by command, satisfying `check-citations.py`'s citation rule without hand-verifying arithmetic |

**Deprecated/outdated:** none — this is a young, internally-consistent convention with no
superseded predecessor.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The 214-subset reproduction should be done by filtering a fresh superset snapshot down to 214's exact PR numbers, rather than copying 214's `raw/prs/` tree into the 222 dir | §1 | Low — either approach reproduces the same number; choosing the copy-tree approach instead just means an extra committed data tree with no functional difference |
| A2 | The D-02 minute-gate denominator ("that window's billed PR runner-minutes") should be computed from real per-run billed minutes via a copied `summarize-ci.py`, not from `n × BASE-01 p50` | §3 | Medium — if the planner instead uses the p50-proxy shortcut without disclosure, the decision record states a precision it does not have; low overall risk to the verdict itself given the wide margin (0–8% vs a 10% threshold), but affects the honesty-note quality D-02 explicitly asks for |
| A3 | Widening `check-citations.py`'s phase-number regex to admit 222 (not just 214-218) is required, following the exact pattern 218 used to admit itself | §4 | Low — mechanical; if skipped, the citation check will produce false-positive failures that are easy to diagnose and fix during plan execution |
| A4 | The `audit_acknowledged` nested `status: dormant` field should be left untouched even though it will read as stale next to the new top-level `status: closed` | §8 | Low — a documentation clarity issue only; does not affect any gate or tool behavior |

## Open Questions (RESOLVED)

1. **Exact denominator definition for the D-02 part-2 gate ("that window's billed PR
   runner-minutes")**
   - What we know: the numerator (inert-PR count) is PR-centric via `inert-share.py`; the
     per-skip saving (19 billed min) is per skip-eligible *job set* on one `pull_request` run.
   - What's unclear: whether the denominator sums every `pull_request` run in the window (which
     could include re-runs of the same PR, or runs on PRs later closed unmerged) or exactly one
     run per merged PR, matching the numerator's population.
   - Recommendation: use one representative `pull_request` run per merged PR in `30d-now`
     (matching `inert-share.py`'s population exactly), computed via the copied `summarize-ci.py`
     against a fresh `raw/ci/` collection scoped to those PRs' head SHAs — not an unscoped
     `gh run list` over the whole window, which would double-count re-run PRs.
   - RESOLVED: 222-01 must_haves D-02 denominator truth (and Task 2 `minute-gate`): one representative ci.yml `pull_request` run per merged PR in `30d-now`, the highest run id on the PR's final head SHA; PRs with no such run are listed and excluded.

2. **Whether `since-214`'s n is large enough to be informative on its own (D-02 requires n ≥ 10
   for the 30d-now gate; `since-214` per CONTEXT is only 9 PRs, #55–#65)**
   - What we know: CONTEXT.md states "0 of 9 since Phase 214" as a scratch figure; D-02's formal
     gate is defined only over `30d-now`, not `since-214`.
   - What's unclear: whether `222-DECISION.md` should present `since-214`'s 0-of-9 as informational
     only (like the D-03 ceiling row) since n=9 is below the gate's own n≥10 floor, or omit any
     gate-language framing around it entirely.
   - Recommendation: present `since-214` purely as a secondary informational window (like D-03's
     ceiling row), explicitly noting its n is below the gate's n≥10 threshold and it does not
     itself vote — consistent with how D-02 already scopes the formal gate to `30d-now` alone.
   - RESOLVED: 222-02 Task 1: `since-214` is presented as informational only (n below the n≥10 floor) and does not vote; the formal gate stays on `30d-now`.

## Sources

### Primary (HIGH confidence — read directly this session)
- `.planning/phases/214-baseline-measurement/tools/inert-share.py` — full read, self-test cases, `WINDOWS`/path resolution
- `.planning/phases/214-baseline-measurement/tools/inert-allowlist.txt` — full read, allowlist admission rule and rejected candidates
- `.planning/phases/214-baseline-measurement/tools/check-citations.py` — full read, citation rule and phase-number exemption regex
- `.planning/phases/214-baseline-measurement/tools/verify-phase.sh` — full read, phase-gate composition pattern, `GH_WRITE` and `MACHINE_PATH` guards
- `.planning/phases/214-baseline-measurement/214-BASELINE.md` §0, §3a, §6 — collection commands, BASE-01 figures, inert-path share method
- `.planning/phases/219-deps-only-build-cache/219-REMEASURE.md` §0, §2, §4 — copy-and-extend precedent, per-lane warm job durations (PgBouncer/Browser E2E/Capture)
- `.planning/phases/218-ci-economy-remove-waste/tools/check-citations.py` (diffed against 214's) — the phase-number regex widening precedent
- `test/threadline/ci_workflow_parity_contract_test.exs` — `required_gate_errors/1` (1792), `@ci_job_ids` (1744), `gate_job_id_errors/1` (1987), `voting_lane_errors/1` (1685), `rule=lane-skip` assertions (560-619, 2046)
- `test/threadline/release_control_plane_contract_test.exs` — allowed-skips laundering test (90-102)
- `.github/workflows/ci.yml` — no-`paths:` comment (9-16)
- `<home>/.claude/gsd-core/bin/lib/commands.cjs` — `cmdListSeeds` status handling (309-347)
- `<home>/.claude/gsd-core/bin/lib/audit.cjs` — `scanSeeds` unimplemented-status set (619-634)
- `.planning/seeds/SEED-003-ecosystem-integrations.md` — `retired_*` frontmatter shape
- `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md` — current frontmatter to edit
- `.planning/phases/220-newest-toolchain-lane/220-04-PLAN.md` (110-138) — PROJECT.md Key Decisions row format precedent
- `.planning/PROJECT.md:42` — the bullet to convert to past tense
- `.planning/REQUIREMENTS.md:112-120` — SCOPE-01 text
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/222-CONTEXT.md` — D-01..D-09, all locked decisions
- `bin/verify-repo-hygiene` (1-95) — machine-path guard scope and pattern families

### Secondary (MEDIUM confidence)
- None used beyond primary sources; no external documentation lookups were needed for this phase (all research was in-repo).

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack (Python stdlib tooling pattern): HIGH — copied verbatim from a mechanism proven twice already (214→218, 218→219)
- Architecture (copy-and-extend, tool composition): HIGH — directly observed in two prior phases' committed artifacts
- Closure-artifact mechanics (seed/PROJECT.md/REQUIREMENTS.md edits): HIGH — direct precedent from 220 and SEED-003, plus source-verified gsd-tools tolerance
- D-02 minute-gate exact denominator definition: MEDIUM — the components are all verified, but the precise window-scoping choice is left to the planner (Open Question 1)

**Research date:** 2026-09-29
**Valid until:** this phase should execute within days of research (no external dependency drift risk); if delayed past another merged PR or another CI run, the fresh `raw/prs/` snapshot and `since-214`/`30d-now` windows must be re-collected at execution time regardless, since they are explicitly defined as "collected once and then frozen" at collection time, not at research time.
