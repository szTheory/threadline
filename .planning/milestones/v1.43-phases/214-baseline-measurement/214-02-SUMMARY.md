---
phase: 214-baseline-measurement
plan: 02
subsystem: ci-measurement
tags: [baseline, project-md, advisories, flake-detection, dialyzer, repo-hygiene]
status: complete
requires: []
provides:
  - "raw/base02/facts.json: every BASE-02 fact with the command that produced it"
  - "tools/measure-base02.sh (steps flake, advisories, paths, xref), read-only toward GitHub"
  - "tools/check-project-baseline.sh: PROJECT.md baseline vs facts.json, plus the Out of Scope byte-identity re-check against ff8e53e9"
  - "tools/measure-local.sh (steps env, slowest, live-dialyzer, ci-steps) and raw/local captures for plan 03"
  - "Corrected PROJECT.md `## Current Milestone` baseline block"
affects: [214-03, 215, 217, 218]
tech-stack:
  added: []
  patterns:
    - "Checker reads expected values from facts.json with jq; nothing is hard-coded"
    - "PLT move-aside with an EXIT/INT/TERM trap restore for cold-PLT timing"
key-files:
  created:
    - .planning/phases/214-baseline-measurement/tools/measure-base02.sh
    - .planning/phases/214-baseline-measurement/tools/check-project-baseline.sh
    - .planning/phases/214-baseline-measurement/tools/measure-local.sh
    - .planning/phases/214-baseline-measurement/tools/fixtures/project-bad-streak.md
    - .planning/phases/214-baseline-measurement/raw/base02/facts.json
    - .planning/phases/214-baseline-measurement/raw/local/live-dialyzer.json
    - .planning/phases/214-baseline-measurement/raw/local/slowest-25.txt
    - .planning/phases/214-baseline-measurement/deferred-items.md
  modified:
    - .planning/PROJECT.md
decisions:
  - "Flake fast-failure streak is 79 scheduled runs, 06-26→09-12 (not 08-18→09-12): measured over all 118 scheduled runs, and measured fact wins over the research and ROADMAP wording"
  - "The tracked local-path count is the union of the absolute and home-relative regexes: 387 files at e58aa067. It includes 2 .github runner-cache paths, which are named as not maintainer paths rather than excluded"
  - "The 5 runtime xref cycles are not all Ecto association edges: 2 are Ecto schema pairs and 3 are module call pairs. PROJECT.md wording was corrected to match"
  - "The :live_dialyzer test passes vacuously with no PLT. cold_plt_s is recorded but labelled as not a cold-analysis cost, and mix dialyzer --plt (33.0 s) is captured as the real local PLT build cost"
metrics:
  duration: "~17 min"
  completed: 2026-09-26
estimate:
  tokens: 85000
  tasks: 3
actuals:
  tokens: 10000   # chars/4 over the scripts, fixture, deferred-items and PROJECT.md diff (~40k chars); raw captures (~644 KB, generated) excluded
  tasks: 3
  commits: 3
plan_head_before: 7f829eab37a50a562fd42181c26f166e93223a13
---

# Phase 214 Plan 02: BASE-02 re-measure and local BASE-01 captures Summary

PROJECT.md's `## Current Milestone` baseline now matches re-measured fact, and a checker enforces it by reading facts.json. The corrected facts are: a 79-run Flake Detection fast-failure streak 06-26→09-12 under the current 180-min timeout; 2 root advisories plus 8 in bench (3 HIGH); 387 tracked local-path files at `e58aa067` (2 in `prompts/prior-art/`); `tmp_dir hygiene`; and no runtime-cycle gate. Out of Scope is byte-identical to ff8e53e9. The local captures are also done: slowest-25 (2207 tests, 0 failures) and the isolated `:live_dialyzer` timings. The live-Dialyzer run showed that the test passes vacuously when no PLT exists.

## What was built

- **Task 1 (tracer, e58aa067):** `measure-base02.sh flake` and `check-project-baseline.sh`. The negative fixture `project-bad-streak.md` changes the streak start to 07-01. The tracer gate (auto mode) re-ran `<verify>` green before expanding.
- **Task 2 (5e461412):** added the `advisories`, `paths` and `xref` steps, the PROJECT.md baseline edits, checker assertions for every fact, a negative `tmp_dir flakes` assertion and the Out of Scope re-check. The Out of Scope check requires the section to be byte-identical to ff8e53e9 and to keep both required clauses. A mutated copy of PROJECT.md made the checker exit 1 on both.
- **Task 3 (1186f1c4):** `measure-local.sh` with env, slowest-25, live-Dialyzer warm/cold and CI test-step captures. `.dialyzer` was restored and no `.dialyzer.214-warm` is left behind.

## Measured facts (raw/base02/facts.json)

| Fact | Measured | Pre-plan PROJECT.md / research |
|------|----------|--------------------------------|
| Flake fast-failure streak | 79 runs, 06-26→09-12 (28225855438 → 34679766829), threshold under 10 min | "from 08-18" (research: 08-18 → 09-12) |
| verify-flake timeout | 180 min | 180 min |
| Root advisories | 2: mint 1.10.0 (MEDIUM), lazy_html 0.1.12 (LOW) | 2 (same) |
| Bench advisories | 8: 3 HIGH (postgrex ×1, plug ×2), 3 MEDIUM, 2 LOW; packages decimal 2.3.0, plug 1.19.1, postgrex 0.22.0 | "3 HIGH in bench" |
| Example lockfile | clean (hex.audit exit 0) | not stated |
| Tracked local-path files (HEAD `e58aa067`) | 387 union (383 `.planning/`, 2 `prompts/prior-art/`, 2 `.github/`); 303 absolute-only | "About 295–298", all under `.planning/` |
| Tracked local-path files (origin/main `5e78b2f0`) | 345 union (292 absolute-only) | n/a |
| xref compile-connected / runtime cycles | 0 / 5, capture↔semantics edge present | same counts |
| hex version | 2.5.1 | n/a |

## Local BASE-01 captures (raw/local)

- `mix test --slowest 25`: 2207 tests, 9 properties, 0 failures, 2 excluded, wall 130.32 s. ExUnit reports 129.3 s (12.1 s async, 117.1 s sync); the top 25 take 95.8 s, 74.2% of the total. `--slowest` turns on trace mode (`max_cases: 1`), so this is a serial time and not the default parallel suite time.
- Isolated `:live_dialyzer`: warm PLT 3.11 s (warm-up 3.20 s); with the PLT moved aside, 1.21 s. The raw Dialyzer command takes 2.18 s warm and 0.41 s with no PLT. A fresh `MIX_ENV=dev mix dialyzer --plt` takes 32.99 s. Local hardware: Darwin arm64, 18 CPUs, PostgreSQL 14.17.
- CI context: `ci-test-steps.json` holds step timings for green push run 36258719902 ("Run test suite (min)" and "(current)"). These are GitHub-hosted runner timings, so they are not comparable to local hardware.
- The stale `public.threadline_capture_changes()` function is present in the local test DB. It was recorded, not fixed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The cold-PLT measurement measured nothing**
- **Found during:** Task 3
- **Issue:** The first cold run (1.38 s) was faster than warm. The test's command passes `--no-check`, so Dialyzer fails with "Could not read PLT file … no_such_file", and `--ignore-exit-status` turns that into a pass.
- **Fix:** In the cold phase, measure-local.sh now also captures the raw Dialyzer output with no PLT and times `mix dialyzer --plt`, the command in CI's verify-dialyzer cache-miss step. live-dialyzer.json records `cold_plt_vacuous_pass: true` with the error text and a `finding`. The cold label no longer claims that the PLT was rebuilt.
- **Files modified:** tools/measure-local.sh, raw/local/*
- **Commit:** 1186f1c4

**2. [Rule 1 - Bug] The PROJECT.md xref wording was wrong**
- **Found during:** Task 2
- **Issue:** The block said "the 5 runtime cycles are Ecto association edges by design". Only 2 are Ecto schema pairs (`AuditTransaction`↔`AuditAction`, `AuditTransaction`↔`AuditChange`, verified by `belongs_to`/`has_many`). The other 3 are module pairs: `MechanicalChecker`↔`Contrast`, `Threadline`↔`Investigation`, and `RepositoryBoundary`↔`critic.measure`.
- **Fix:** Reworded the text to match the measurement.
- **Commit:** 5e461412

**3. [Rule 2 - Privacy] The PROJECT.md wording would have matched its own regexes**
- **Found during:** Task 2
- **Issue:** Writing `/Users/<name>/` and a tilde-slash literal into PROJECT.md would have added PROJECT.md to the count it reports.
- **Fix:** Described the patterns in words. `git grep` with both regexes finds no match in PROJECT.md.
- **Commit:** 5e461412

### Disagreements with research or ROADMAP wording (measured fact wins)

- The flake streak starts on **06-26**, not 08-18 (research) or 08-27 (the 214-01 regime table, which was limited to `--since 2026-08-27`). All 118 scheduled runs were seen, fewer than the 200 limit, so this is the full history. The research's broken-main cause is confirmed only for the late runs (for example 34679766829). PROJECT.md now claims that cause only for the last run. The cause of the 06-26…08-17 failures was not investigated.
- The bench HIGH count matches the ROADMAP's "3 HIGH". Bench has 8 advisories in total.
- The local-path count is **387**, not "about 295–298", and the files are not all under `.planning/`: 2 are `.github/` runner-cache paths and 2 are in prompts/prior-art. The absolute-only count at origin/main (292) is close to the old range. The difference comes from counting home-relative paths and from the phase's own new `.planning` files.
- GitHub's advisory database returns 404 for 6 of the 10 GHSA ids, including both root advisories. Severity therefore comes from `mix hex.audit` (EEF), and advisories.json records each 404 as "not found via gh api /advisories".

## Known Stubs

None.

## Deferred Issues

Logged in `.planning/phases/214-baseline-measurement/deferred-items.md`:
- `:live_dialyzer` passes vacuously when no PLT exists. Plan 03 or Phase 218 should check whether the CI test lanes, which do not restore `.dialyzer`, take the same path. The verifier should fail closed.
- The Phase 217 guard needs an allowlist decision for the runner Playwright cache paths in `.github/workflows/`.

## Threat Flags

None. All gh calls are `gh run list`, `gh run view` or default-GET `gh api`. `git fetch origin main` only reads.

## Verification

- `check-project-baseline.sh` exits 0 on PROJECT.md and 1 on the bad-streak fixture. A mutated Out of Scope also exits 1.
- The Out of Scope diff against ff8e53e9 is empty, and the base section is 16 lines.
- `git diff --quiet ff8e53e9 -- mix.exs mix.lock bench/mix.lock examples/threadline_phoenix/mix.lock .github test lib` exits 0.
- `.dialyzer` is present and `.dialyzer.214-warm` does not exist.
- The raw/base02 and raw/local captures contain no `/Users/`, `/home/<x>` or tilde-slash paths, and no local username.

## Self-Check: PASSED
