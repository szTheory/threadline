---
phase: 214-baseline-measurement
plan: 03
subsystem: ci-measurement
tags: [baseline, inert-paths, seed-006, dialyzer, verification-gate]
status: complete
requires: ["214-01", "214-02"]
provides:
  - "214-BASELINE.md sections 6-10: inert-path share, mix test --slowest 25, isolated :live_dialyzer (warm/cold PLT), BASE-02 facts, research vs re-measured"
  - "tools/inert-share.py: fail-closed inert classifier over merged-PR file lists (--window all|30d, --self-test)"
  - "tools/inert-allowlist.txt: 22 proven entries, each with an empty-output proof command, and a rejected-candidate block"
  - "tools/check-baseline-complete.py: completeness gate for the eight BASE-01 elements with n >= 10 and per-job coverage from ci.yml"
  - "tools/verify-phase.sh: the single phase gate later phases (218 ECON-07, 222 SCOPE-01) re-run"
  - "raw/prs: 40 merged PRs into main with full file lists"
affects: [218, 222]
tech-stack:
  added: []
  patterns:
    - "Allowlist entries carry their own proof command; unmatched paths are non-inert (fail-closed)"
    - "Gate greps fail closed on grep errors (exit 2 is not read as no match)"
key-files:
  created:
    - .planning/phases/214-baseline-measurement/tools/inert-share.py
    - .planning/phases/214-baseline-measurement/tools/inert-allowlist.txt
    - .planning/phases/214-baseline-measurement/tools/check-baseline-complete.py
    - .planning/phases/214-baseline-measurement/tools/fixtures/incomplete.md
    - .planning/phases/214-baseline-measurement/tools/verify-phase.sh
    - .planning/phases/214-baseline-measurement/raw/prs/index.json
  modified:
    - .planning/phases/214-baseline-measurement/214-BASELINE.md
    - .planning/phases/214-baseline-measurement/deferred-items.md
decisions:
  - "Inert-path share is 1 of 40 merged PRs overall (#8, planning-only) and 0 of 20 in the 30-day window. Path-based lane skipping has no material share at the current PR mix, which is the SEED-006 input for Phase 222"
  - "release/sync-* distribution PRs are not inert: all 8 touch guides/adoption-pilot-backlog.md, which ships in the Hex package and is read by doc-contract tests"
  - ".dockerignore rejected despite 0 grep hits, because docker build reads it implicitly and grep cannot rule that out"
  - "CI test lanes most likely run :live_dialyzer vacuously (no .dialyzer restore, no Dialyzer output in run 36258719902). Labelled [inference] and carried to the CI-economy phase"
metrics:
  duration: "~12 min"
  completed: 2026-09-26
estimate:
  tokens: 80000
  tasks: 3
actuals:
  tokens: 12700   # chars/4 over the new tools, allowlist, fixture and the doc/deferred-items additions (~51k chars); raw/prs (generated) excluded
  tasks: 3
  commits: 3
plan_head_before: 84f5bb84b294b6eab3d7ca4e44a12dd501789b46
---

# Phase 214 Plan 03: Inert-path share, local captures and the phase gate Summary

The inert-path share of merged PRs is 1 of 40 overall and 0 of 20 in the last 30 days. It was measured with a fail-closed classifier over read-only PR file lists and a 22-entry allowlist in which every entry carries its own proof command. 214-BASELINE.md now contains all eight BASE-01 elements plus the BASE-02 facts, every figure cited. `verify-phase.sh` proves the whole phase in one command, including its negative self-tests.

## What was built

- **Task 1 (6751c296):**
  - raw/prs holds 40 merged PRs into main. Their file lists come from `gh api --paginate`, and every list's line count equals `changedFiles`.
  - `inert-allowlist.txt` has 22 entries: exact `.planning/` top-level files and single `.planning/` subdirectories. Each has a proof command, and every proof prints nothing at HEAD. A comment block records every rejected candidate: the blanket `.planning/*`, audits, phases, milestones, ROADMAP.md.bak, every package path, `.dockerignore`, and all extension globs.
  - `inert-share.py` supports `--window all|30d` and has 7 self-test cases. It exits 2 on a proof-less entry or on file-list/count drift.
  - Doc section 6 covers the result.
- **Task 2 (725e9929):**
  - Section 7 is `mix test --slowest 25`: the environment, the stale public function ("recorded, not fixed"), the suite summary labelled as a serial time, and a 25-row table with the `:live_dialyzer` test marked (row 11, 2.42 s).
  - Section 8 is the isolated `:live_dialyzer` run: warm 3.11 s, cold 1.21 s. It states plainly that the cold run is a vacuous pass. The real local PLT build is 32.99 s, and the research CI cold PLT is 148.49 s, run 34731370786.
  - Section 9 lists the BASE-02 facts per `measure-base02.sh` step, plus the checker line.
  - Section 10 compares 12 research figures with the re-measured values. The differences are stated, not reconciled.
- **Task 3 (7338ecc9):**
  - `check-baseline-complete.py` checks the eight headings, the three runner-minute units, n >= 10 on every PR and push row, and a PR row and a push row for every ci.yml job id.
  - The `incomplete.md` fixture produces 28 INCOMPLETE lines and exit 1.
  - `verify-phase.sh` runs 11 checks.

## Verification

- `bash .planning/phases/214-baseline-measurement/tools/verify-phase.sh` exits 0 with 11 PASS lines and no FAIL.
- Negative probes:
  - A doc copy with one row changed to n=8 exits 1.
  - A doc copy without "push-to-main" exits 1.
  - A planted `/home/<x>` file under raw/ turns the machine-path check FAIL. The probe file was removed afterwards.
- The write-verb grep matches only verify-phase.sh, and only its one pattern line.
- `inert-share.py --window all` produces byte-identical output on two runs.
- `git diff --quiet -- .github mix.exs mix.lock test lib` exits 0.
- `git status --porcelain -- .planning/phases/214-baseline-measurement` is empty.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Fail-closed] The machine-path grep could pass on a grep error**
- **Found during:** Task 3
- **Issue:** A piped `grep | grep -v` under pipefail would have read a grep read error (exit 2) as "no match".
- **Fix:** verify-phase.sh now captures the first grep's status and FAILs on exit >= 2 before it applies the facts.json exclusion.
- **Commit:** 7338ecc9

**2. [Rule 2 - Fail-closed] The allowlist is stricter than the plan's three criteria in two places**
- `.dockerignore` passes criteria (a), (b) and (c) but is rejected, because docker build reads it through docker-compose.yml and grep cannot rule out that implicit consumer.
- `.planning/ROADMAP.md` uses an `-E` proof. The `-F` form also matches the separate removed path `.planning/ROADMAP.md.bak`, which is itself rejected.
- **Commit:** 6751c296

**3. [Rule 2 - Evidence] Checked the CI `:live_dialyzer` path (deferred item from 214-02)**
- The log of green push run 36258719902 was read with `gh run view --log`, which is read-only.
- The test jobs print no Dialyzer output, and ci.yml's verify-test job caches only `deps`. Section 8 therefore states that CI most likely takes the vacuous path, labelled [inference].
- deferred-items.md gained a 214-03 entry saying that confirming this needs the test's own output in CI.
- **Commit:** 725e9929

### Notes

- The 30d window is fixed in the tool at mergedAt 2026-08-27 → 2026-09-26, so re-runs are deterministic. Phase 222 should re-collect raw/prs before re-running.
- index.json is a bare JSON array, so `jq length` works as the acceptance check expects. The collection commands are in inert-share.py's docstring and in doc section 6.

## Known Stubs

None.

## Threat Flags

None. Every GitHub call was `gh pr list`, default-GET `gh api` or `gh run view --log`. PR file names are matched only as fnmatch strings.

## Self-Check: PASSED

- FOUND: tools/inert-share.py, tools/inert-allowlist.txt, tools/check-baseline-complete.py, tools/fixtures/incomplete.md, tools/verify-phase.sh, raw/prs/index.json (+40 .files.txt)
- FOUND commits: 6751c296, 725e9929, 7338ecc9
