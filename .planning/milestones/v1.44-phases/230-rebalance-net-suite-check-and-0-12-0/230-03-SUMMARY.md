---
phase: 230-rebalance-net-suite-check-and-0-12-0
plan: "03"
subsystem: release
tags: [changelog, upgrade-path, release-please, doc-contract, repo-hygiene, dialyzer]

requires:
  - phase: 230-rebalance-net-suite-check-and-0-12-0
    provides: "230-01's SUITE-04 rebalance and 230-02's SUITE-06 gate formula/table, both reused as the unchanged tree this plan gates"
provides:
  - "Dated ## [0.12.0] CHANGELOG entry (human-written highlights, three Fix-lined Breaking changes) with a fresh Unreleased placeholder"
  - "guides/upgrade-path.md 0.11.x -> 0.12.x coverage (table row, bullet with three sub-bullets, extended opening narrative) and no separate upgrading-to-0.12.md (D-13)"
  - "mix verify.bump_rehearsal proof that the 0.12.0 CHANGELOG heading and upgrade-path coverage are real, human-written content, not rehearsal stand-ins"
  - "SC5 ID sweep: 9 phase/plan/threat-plan ID tokens scrubbed from 7 lib/ files, with every remaining look-alike (date literals, legacy pre-v1.44 requirement anchors, version-history headings) reviewed and reasoned in evidence"
  - "Pre-land gate: mix ci.all green (318/0/26, Dialyzer 0 errors), bin/verify-repo-hygiene + self-test green, merge-base == origin/main"
affects: [230-04]

actuals:
  tokens: 6033
  tasks: 3
  commits: 4
  plan_head_before: "18cd443c82186a9690c1960f1b0657f28da2ce16"
  plan_head_after: "243679a8b1550eafa8be0082dd7b5d9b7a34cc29"

tech-stack:
  added: []
  patterns:
    - "mix verify.bump_rehearsal clones HEAD, so proving 'nothing synthesised' for release content requires committing the content FIRST, then re-running the rehearsal against that commit — not before"
    - "SC5 ID sweep: scrub only comment/@doc text, never code or string literals outside docs; reviewed exclusions get a pinning-test citation (or 'unpinned, candidate for later cleanup') rather than a silent skip"

key-files:
  created: []
  modified:
    - CHANGELOG.md
    - guides/upgrade-path.md
    - lib/threadline/health.ex
    - lib/threadline/health/coverage_schemas.ex
    - lib/threadline/operator_surface/ui/page.ex
    - lib/threadline/operator_surface/stress_fixtures.ex
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - .planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md

key-decisions:
  - "Verification-ordering fix (Rule 3): ran mix verify.bump_rehearsal AFTER committing CHANGELOG.md/guides/upgrade-path.md (not before, as the plan's action text literally orders it) because the rehearsal clones HEAD — running it pre-commit only sees the prior tree and (correctly but unhelpfully) synthesises stand-ins instead of proving the real content."
  - "Privacy-grep false positives treated as reviewed non-issues, not a STOP: the plan's literal whoami/home-path greps over tracked .planning/ hit 2+6 pre-existing, out-of-scope files (a 'jones_knowles_ritchie' URL-slug substring, PNG binary bytes, and /home/runner CI-log excerpts already in bin/verify-repo-hygiene's allowlist per 217-RESEARCH.md). The authoritative bin/verify-repo-hygiene guard reports all tracked files clean; the unqualified whoami/home-path greps are a less precise superset, not a second privacy signal. No phase-230 file is among the hits."
  - "Legacy pre-v1.44 requirement-shaped anchors (STG-01..03, PERF-01..03, IDX-02, XPLO-03-API-ROUTING, CAP-10, CTX-05) and version-history headings ((v1.17), (v1.10+)) are excluded from the SC5 sweep per the plan's own expected-exclusions list; STG-02, STG-03 and CAP-10 are recorded as unpinned (no test cites them) and flagged as candidates for later cleanup rather than silently excluded."

requirements-completed: [REL-01]

coverage:
  - id: D1
    description: "CHANGELOG.md carries a dated ## [0.12.0] heading with human-written highlights above ## [0.11.2], and the three Breaking changes entries each carry a Fix line (D-13); guides/upgrade-path.md documents the 0.11.x -> 0.12.x coverage (table row + bullet), with no guides/upgrading-to-0.12.md created"
    requirement: "REL-01"
    verification:
      - kind: unit
        ref: "mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/guide_graph_contract_test.exs (55 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "bin/verify-release-shape (Release shape OK for version 0.11.2); mix verify.bump_rehearsal against commit 73360d72 (both 'nothing synthesised' lines printed verbatim)"
        status: pass
    human_judgment: false
  - id: D2
    description: "SC5 sweep: no phase, plan, threat-plan or decision ID, and no v1.44 requirement ID, remains in lib/, guides/ or the 0.12.0 CHANGELOG block (9 hits scrubbed across 7 files); every remaining look-alike is a reviewed, reasoned exclusion with a pinning-test citation"
    requirement: "REL-01"
    verification:
      - kind: unit
        ref: "sweep grep (45 -> 36 hits, exactly the 36 pre-existing date literals); CHANGELOG 0.12.0 block grep (0 hits); mix compile --warnings-as-errors; mix docs; mix test (coverage_doc_contract, coverage_live, evidence_live, health, release_artifact_contract — 109 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The pre-landing tree passes mix ci.all, bin/verify-repo-hygiene and its self-test, with origin/main unmoved from the branch's merge base"
    requirement: "REL-01"
    verification:
      - kind: unit
        ref: "mix ci.all (318 passed/0 failed/26 skipped, Dialyzer 0 errors); bin/verify-repo-hygiene (4472 files clean); bin/verify-repo-hygiene --self-test (10 cases ok); git merge-base HEAD origin/main == git rev-parse origin/main"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-10-02
status: complete
---

# Phase 230 Plan 03: Pre-land gate — 0.12.0 release content, SC5 ID sweep, ci.all/hygiene Summary

**Dated the 0.12.0 CHANGELOG entry and added 0.11-to-0.12 upgrade-path coverage (proven "nothing synthesised" by mix verify.bump_rehearsal), scrubbed 9 planning-ID tokens from 7 lib/ files for SC5, and proved the pre-landing tree green on mix ci.all, repo hygiene, and the origin/main merge-base check.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-10-02T21:05:00Z (approx)
- **Completed:** 2026-10-02T22:00:00Z (approx)
- **Tasks:** 3
- **Files modified:** 9 (CHANGELOG.md, guides/upgrade-path.md, 7 lib files) + 230-EVIDENCE.md

## Accomplishments

- Retitled the Unreleased block's content under a dated `## [0.12.0] - 2026-10-02` heading (the #68/#bbfc0d1e shape) with a new 3-sentence human-written highlights paragraph, leaving a fresh `_Nothing yet for the next release._` placeholder; confirmed all three Breaking changes entries carry a `Fix:` line (D-13)
- Added the `0.11.x → 0.12.x` row to the "At a glance, per minor" table and a matching bullet (with three sub-bullets restating each CHANGELOG Fix line) to `guides/upgrade-path.md`, plus an extended opening-narrative sentence naming 0.11.0 and 0.12.0; no `guides/upgrading-to-0.12.md` was created
- Proved via `mix verify.bump_rehearsal` (re-run against the content commit, since the rehearsal clones `HEAD`) that both the CHANGELOG heading and the upgrade-path coverage are real — "nothing synthesised" for either stand-in
- Scrubbed 9 phase/plan/threat-plan ID hits (`HLTH-02` x2, `T-175-09`, `177-05`, `196-05`/`196-06` x3, `T-211-14`, `197-02`) from comment/`@doc` text across 7 lib files, keeping `coverage_live.ex`'s pinned `"Selected schema readiness"` phrase intact; `git show --stat` on the task-2 commit confirms only those 7 files and only comment-line diffs
- Reviewed every remaining sweep hit: 36 date literals (not IDs) plus the legacy pre-v1.44 anchors `STG-01..03`, `PERF-01..03`, `IDX-02`, `XPLO-03-API-ROUTING`, `CAP-10`, `CTX-05` and the version-history headings `(v1.17)`/`(v1.10+)` — each classified with its pinning test or flagged "unpinned, candidate for later cleanup" (`STG-02`, `STG-03`, `CAP-10`)
- Ran `mix ci.all` to completion: 318 passed, 0 failed, 26 skipped (matching the repo's documented healthy browser-lane baseline exactly), Dialyzer 0 errors (no PLT rebuild needed)
- Ran `bin/verify-repo-hygiene` (4472 tracked files clean) and its `--self-test` (10 cases ok); confirmed `git merge-base HEAD origin/main` equals `origin/main` (`fc47af60`) — main has not moved

## Task Commits

1. **Task 1: Tracer — write the 0.12.0 release content and prove the rehearsed bump needs no stand-ins** - `73360d72` (docs, content) + `8e77e244` (docs, evidence)
2. **Task 2: SC5 sweep — scrub planning IDs from lib/, guides/ and the 0.12.0 CHANGELOG block** - `d8ac6e21` (docs)
3. **Task 3: Full pre-land gate — mix ci.all, repo hygiene, privacy grep** - `243679a8` (docs)

_Note: Task 1 split into two commits — content first, then evidence — because `mix verify.bump_rehearsal` clones HEAD and had to run against the real committed content, not before it; see Deviations._

## Files Created/Modified

- `CHANGELOG.md` - dated `## [0.12.0] - 2026-10-02` heading, human-written highlights paragraph, fresh Unreleased placeholder
- `guides/upgrade-path.md` - `0.11.x → 0.12.x` table row and bullet (three sub-bullets), extended opening narrative
- `lib/threadline/health.ex` - removed `(HLTH-02)` from a comment
- `lib/threadline/health/coverage_schemas.ex` - removed `(HLTH-02)` from a `@doc`
- `lib/threadline/operator_surface/ui/page.ex` - removed `mitigates T-175-09` from a comment
- `lib/threadline/operator_surface/stress_fixtures.ex` - removed `the 177-05 group precedent` phrase from a comment
- `lib/threadline/operator_surface/live/transaction_live.ex` - removed `(T-211-14)` from a comment
- `lib/threadline/operator_surface/live/evidence_live.ex` - removed 3x `196-05`/`196-06` tokens from HEEx comments, kept `signal-to-chrome`
- `lib/threadline/operator_surface/live/coverage_live.ex` - removed `197-02` from a HEEx comment, kept `"Selected schema readiness"`
- `.planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md` - appended `## Pre-land gate` with `### Release readiness`, `### SC5 ID sweep`, `### Gate results`

## Decisions Made

- Ran `mix verify.bump_rehearsal` after committing the CHANGELOG/upgrade-path content, not before (Rule 3): the rehearsal clones `HEAD`, so pre-commit it only sees the prior tree and synthesises stand-ins rather than proving the real content. The content commit (`73360d72`) precedes the rehearsal re-run and the evidence commit (`8e77e244`) that records its "nothing synthesised" output.
- Treated the plan's literal whoami/home-path privacy-grep hits as reviewed non-issues rather than a STOP: both hit sets are pre-existing, out-of-scope files (a URL-slug substring, PNG binary bytes, and allowlisted `/home/runner` CI-log excerpts), and the authoritative `bin/verify-repo-hygiene` guard reports the full tracked tree clean. No phase-230 file is among the hits.
- Recorded `STG-02`, `STG-03` and `CAP-10` as unpinned legacy anchors (no test cites them) rather than silently excluding them — flagged as candidates for later cleanup, per the plan's own classification instruction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Verification-ordering fix for mix verify.bump_rehearsal**
- **Found during:** Task 1
- **Issue:** The plan's action text runs "verify commands, then commit" in that order, but `mix verify.bump_rehearsal` clones `HEAD` into a throwaway tree. Run before committing the CHANGELOG/upgrade-path edits, it correctly (but unhelpfully) synthesised rehearsal stand-ins because it could not see uncommitted working-tree changes.
- **Fix:** Committed CHANGELOG.md + guides/upgrade-path.md first (`73360d72`), then re-ran `mix verify.bump_rehearsal` against that commit, which printed both "nothing synthesised" lines as required.
- **Files modified:** None beyond the planned CHANGELOG.md/guides/upgrade-path.md edits — this is a command-ordering fix, not a content change.
- **Verification:** `/tmp/230-rehearsal.log` (second run) contains both required lines; all plan verify commands re-ran green afterward.
- **Committed in:** `73360d72` (content), `8e77e244` (evidence recording the rehearsal output and the ordering note)

**2. [Rule 1 - Non-issue, documented not fixed] Privacy-grep false positives in pre-existing files**
- **Found during:** Task 3
- **Issue:** The plan's literal `git ls-files -z .planning | xargs -0 grep -lF "$(whoami)"` and the broader home-path grep hit 2 and 6 pre-existing tracked files respectively, none from phase 230. Investigation showed these are substring collisions (a `jones_knowles_ritchie` URL slug, PNG binary bytes) and already-allowlisted `/home/runner` CI-log excerpts — not the local username or a real privacy leak.
- **Fix:** No file was changed (there is nothing to fix — no real username appears). Documented the investigation and the authoritative `bin/verify-repo-hygiene` guard's clean result in `230-EVIDENCE.md` `### Gate results`, per the plan's own instruction to report an older-file hit rather than silently pass or silently fail.
- **Files modified:** None (pre-existing files out of this plan's scope; editing them would itself be out-of-scope per the plan's file list).
- **Verification:** `bin/verify-repo-hygiene` (the authoritative guard) reports `4472 tracked text file(s) clean`.
- **Committed in:** `243679a8` (evidence only; no code/doc file changed by this deviation)

---

**Total deviations:** 2 (1 verification-ordering fix, 1 reviewed non-issue). **Impact:** No scope creep — both are documentation/ordering corrections within the plan's own evidence requirements; no production, test, or release-artifact content changed beyond what the plan specified.

## Issues Encountered

None beyond the two deviations above (both resolved within this plan).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `CHANGELOG.md` and `guides/upgrade-path.md` carry real, rehearsal-proven 0.12.0 release content; the release PR release-please opens after landing should pass CI's "CHANGELOG matches version" and `version_truth` Family C checks without edits.
- SC5 holds on the tree as committed: no phase/plan/threat-plan/decision/v1.44-requirement ID remains in `lib/`, `guides/` or the `0.12.0` CHANGELOG block.
- `mix ci.all`, `bin/verify-repo-hygiene` and its self-test are green on HEAD (`243679a8`), and `origin/main` has not moved past the branch's merge base (`fc47af60`) — plan 04 can proceed straight to the landing PR without a merge/rebase step, per D-15.
- No blockers.

## Self-Check: PASSED

- `grep -Eq '^## \[0\.12\.0\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md` — FOUND
- `test ! -e guides/upgrading-to-0.12.md` — FOUND missing (as expected, D-13)
- `git log --oneline --all --grep="230-03"` returns all 4 commits (`243679a8`, `d8ac6e21`, `8e77e244`, `73360d72`) — FOUND
- `.planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md` contains `## Pre-land gate`, `### Release readiness`, `### SC5 ID sweep`, `### Gate results` — FOUND
- All plan-level `<verification>` commands re-run clean during task execution (see Task 1-3 verify blocks above); `mix ci.all` final line `318 passed (4.3m)` with `26 skipped`, 0 failures

---
*Phase: 230-rebalance-net-suite-check-and-0-12-0*
*Completed: 2026-10-02*
