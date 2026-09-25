---
phase: 206-installer-migration-versions
verified: 2026-09-24T18:05:00Z
status: passed
score: 15/15 must-haves verified
covered_files:
  - .planning/phases/205-release-reconciliation/205-REVIEW.md
  - .planning/phases/206-installer-migration-versions/206-01-PLAN.md
  - .planning/phases/206-installer-migration-versions/206-01-SUMMARY.md
  - .planning/phases/206-installer-migration-versions/206-02-PLAN.md
  - .planning/phases/206-installer-migration-versions/206-02-SUMMARY.md
  - .planning/v1.41-MILESTONE-AUDIT.md
  - CHANGELOG.md
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/threadline/mix/migration_version.ex
  - test/mix/tasks/threadline/install_test.exs
  - test/threadline/mix/migration_version_test.exs
covered_digest: "v1:sha256:14d026a1d7461db257dfa4663fd5d55a8c6db2a9db5b746f507de790a425b19f"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 206: Installer Migration Versions Verification Report

**Phase Goal:** `mix threadline.install` writes its three migrations with strictly increasing version numbers, so a fresh adopter's `mix ecto.migrate` succeeds, with a regression test on the numeric prefixes (205-REVIEW CR-01; shipped since v0.9.0).
**Verified:** 2026-09-24T18:05:00Z
**Status:** passed
**Re-verification:** No. This is the initial verification.

## Goal Achievement

The roadmap entry has no Success Criteria list. The must-haves are the phase goal, split into three clauses, plus the PLAN frontmatter truths (10 in plan 01 and 5 in plan 02). Duplicates are merged below.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| G1 | Install writes three migrations with strictly increasing versions | VERIFIED | `install.ex:46` calls `MigrationVersion.next(path, length(pending))` once, before any `create_file`. Tested by `install_test` "a fresh install writes three distinct versions in family order", which passes. |
| G2 | A fresh adopter's `mix ecto.migrate` succeeds | VERIFIED (real DB) | Verifier probe `/tmp/v206/probe.exs`: `install`, then `gen.triggers --tables posts`, into a scratch app, then a real `Ecto.Migrator.run(:up, all: true)` against a scratch Postgres DB. It applied `[20000101000000, 20260924180101, …180102, …180103, …180104]`, created `audit_transactions`, `audit_changes` and `audit_actions`, and installed the trigger `threadline_audit_posts`. The scratch DB was dropped afterwards. Negative control `/tmp/v206/neg.exs`: the same files renamed to one shared prefix make the real migrator raise `migration version 20260924000000 is duplicated`. |
| G3 | A regression test covers the numeric prefixes | VERIFIED | `assert_valid_increasing!` in `install_test.exs` checks for 14 digits, a valid NaiveDateTime, no duplicates and sorted order. The verifier independently reproduced RED by running the current `install_test.exs` against pre-phase lib (`00022f15`): 9 tests, 5 failures, including "`migration version 20260924180147 is duplicated — got [x3]`" and the same for the four-file install+triggers case. |
| P1-1 | Prefixes are valid, unique and strictly increasing in the order audit < semantics < governance | VERIFIED | Same as G1/G3. `@families` order is fixed at `install.ex:25-32`. |
| P1-2 | Versions are above the highest existing prefix, and 20991231235959 carries to 21000101000000 | VERIFIED | `from_existing/3` uses `NaiveDateTime.add` + `later/2`. The install test asserts `hd(versions) == "21000101000000"`, and the helper unit test checks the carry for all three versions. |
| P1-3 | Versions are computed once by one hidden helper that both tasks call, and the old timestamp/pad functions are gone | VERIFIED | `@moduledoc false` at `migration_version.ex:2`. Call sites: `install.ex:46` and `gen.triggers.ex:136` (`next(path, 1)`). `grep "defp timestamp\|defp pad" lib/mix/tasks/` finds nothing. |
| P1-4 | A non-timestamp max prefix falls back to integer +1 | VERIFIED | `from_existing/3` has an `:error` branch. The unit tests "not a valid timestamp falls back to integer steps" and "small integer … uses the current second" pass. |
| P1-5 | Install then gen.triggers in the same second gives 4 unique increasing prefixes | VERIFIED | `install_test` "install then gen.triggers" passes. The verifier probe produced the four distinct increasing files `…180101…180104`. |
| P1-6 | Results are `{:written, file}` or `:skipped`; fresh advice prints only when all three were written; the existing-installs paragraph is removed | VERIFIED | Covered by `install.ex` `map_reduce`, `generate/3` returning `{:written, file}`, and the `recommend_storage_schema/1` cond. The test "fresh-install advice has no paragraph about existing installs" passes. |
| P1-7 | A partial re-run with the key unset prints `Keep \`:storage_schema\` unset`; nothing written or the key configured prints no advice | VERIFIED | `keep_public_schema/0`. The tests for the partial re-run, the re-run over an existing install, and a configured install all pass. |
| P1-8 | The D-09 cases were RED before the fix, and no test runs Ecto.Migrator | VERIFIED | The verifier reproduced RED itself (see G3). Grepping both test files for `Ecto.Migrator` finds nothing. |
| P1-9 | Each fix commit leaves the install tests green (6, then 8, then 9 tests), and the third also leaves the helper tests green | VERIFIED | The verifier ran each commit's `git archive` in a scratch copy: 9395632a gave 6/0, b620057e gave 8/0, 2d6cf376 gave 17/0 (install plus helper). |
| P1-10 | Code commits use releasable `fix(install)` / `fix(gen.triggers)` subjects | VERIFIED | Commits 9395632a, b620057e and 2d6cf376. |
| P2-1 | The CHANGELOG Unreleased entry follows the template: prose, Breaking changes None, Required action, Fixed | VERIFIED | `CHANGELOG.md:27-62`. |
| P2-2 | The entry contains the literal Ecto error text, says releases through 0.10.1 are affected, and gives the semantics-then-governance workaround | VERIFIED | Lines 28-29, 43-46 and 52. See the note on WR-01 below. |
| P2-3 | The entry mentions gen.triggers and the corrected re-run advice, names no hidden module, and has no planning IDs | VERIFIED | Lines 55-62. Grepping the entry for `WR-`, `CR-`, `D-n`, `MigrationVersion`, `Phase 20`, `v1.4` and `hex.retire` finds nothing. |
| P2-4 | No hex.retire step and no new Troubleshooting section | VERIFIED | The grep above, plus the phase diff touches only CHANGELOG among the docs. |
| P2-5 | The full suite and static gates pass | VERIFIED (partially re-run) | The verifier re-ran `mix test`: 1800 tests, 0 failures, 1 excluded. `MIX_ENV=test mix verify.credo` found no issues, and `mix format --check-formatted` exited 0. The verifier did not re-run dialyzer, xref or docs, because those results come from the SUMMARY gate and commit e4559c0f changed only a test file. |

**Score:** 15/15 distinct must-haves verified (0 present but behavior-unverified). The rows above list the goal clauses and plan truths separately; there are 15 after overlap is merged.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/threadline/mix/migration_version.ex` | `next/3` helper | VERIFIED | 91 lines. Recursive `.exs` scan that mirrors Ecto, datetime stepping, integer fallback. |
| `lib/mix/tasks/threadline.install.ex` | versions-once run/1, three-branch advice | VERIFIED | Wired to the helper. |
| `lib/mix/tasks/threadline.gen.triggers.ex` | helper-versioned trigger migration | VERIFIED | Wired to the helper. |
| `test/mix/tasks/threadline/install_test.exs` | D-09 cases 1-4 plus the D-08 absence check | VERIFIED | 9 tests. Contains "is duplicated". |
| `test/threadline/mix/migration_version_test.exs` | `describe "next/3"` unit tests | VERIFIED | 8 tests. |
| `CHANGELOG.md` | Unreleased entry | VERIFIED | Contains "is duplicated". |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| install.ex | MigrationVersion.next/3 | `MigrationVersion.next(path, length(pending))` | WIRED |
| gen.triggers.ex | MigrationVersion.next/3 | `MigrationVersion.next(path, 1)` | WIRED |
| run/1 results | storage-schema advice | `recommend_storage_schema(results)` matches `{:written, _}` / `:skipped` | WIRED |
| CHANGELOG entry | vocabulary/changelog/public-surface contract tests | default `mix test` | WIRED (full suite green) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase test files | `MIX_ENV=test mix test test/mix/tasks/threadline/install_test.exs test/threadline/mix/migration_version_test.exs` | 17 tests, 0 failures | PASS |
| Real install, gen.triggers, then migrate | `MIX_ENV=test mix run --no-start /tmp/v206/probe.exs` (scratch DB, dropped afterwards) | 5 migrations applied, tables and trigger present | PASS |
| Negative control (duplicated prefix) | `MIX_ENV=test mix run --no-start /tmp/v206/neg.exs` | real migrator raises "is duplicated" | PASS (probe is sensitive) |
| RED against pre-phase code | current install_test.exs run over `git archive 00022f15` | 9 tests, 5 failures | PASS (the test catches the defect) |
| Per-commit green | `git archive` of 9395632a, b620057e and 2d6cf376 | 6/0, 8/0 and 17/0 | PASS |
| Full suite | `MIX_ENV=test mix test` | 1800 tests, 0 failures, 1 excluded | PASS |
| Credo | `MIX_ENV=test mix verify.credo` | no issues | PASS |
| Format | `mix format --check-formatted` | exit 0 | PASS |

`git status --porcelain` after all probes showed only the pre-existing `.planning/` and `.tool-versions` entries. No source files were modified.

### Probe Execution

No `scripts/*/tests/probe-*.sh` is declared for this phase. The ad-hoc probes above were run by the verifier in its own process.

### Requirements Coverage

Neither ID that the plans declare is an entry in `.planning/REQUIREMENTS.md`. The ROADMAP lists the phase's requirements as "TBD (tech-debt closure …)". Both IDs are accounted for against their actual sources:

| ID | Source | Description | Status | Evidence |
|----|--------|-------------|--------|----------|
| CR-01 | `205-REVIEW.md:49` and `v1.41-MILESTONE-AUDIT.md:39,143` (tech-debt item 1) | Install stamps all migrations with one second, so `ecto.migrate` raises a duplicate version. The audit asks for "strictly increasing versions plus a regression test on the numeric prefixes". | SATISFIED | G1-G3 and P1-1 through P1-5. The real migrate succeeds, and the regression test is proven RED against the pre-fix code. |
| WR-03 | `205-REVIEW.md:148` | A partial re-run gets dedicated-schema advice that would split the schemas. | SATISFIED | P1-6 and P1-7. The test the review asked for (pre-seed migrations, then `refute "No \`:storage_schema\` is configured"`) exists and passes. |

No REQUIREMENTS.md ID maps to Phase 206 (`grep "Phase 206" REQUIREMENTS.md` finds nothing), so no requirement is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (6 phase files) | none | No TBD, FIXME, XXX, TODO or HACK | none | none |

### Code Review Findings Weighed

- **WR-01 (the CHANGELOG workaround misses the gen.triggers collision). Warning, not goal-blocking.** The finding is real. On 0.10.1 or earlier, running install and gen.triggers in one second gives four files that share one prefix X. The recipe renames only semantics and governance, which leaves audit and triggers sharing X, so migrate still fails. The recipe also does not say that triggers must sort after audit. The finding does not affect the phase goal: the goal is the installer's own behavior, which is fixed and proven against a real DB. Plan 02 truth P2-2 asks only for the "semantics-then-governance rename workaround", and the entry gives exactly that. This is a doc-accuracy follow-up for adopters on old releases who scripted both commands together. The review's suggested general wording ("rename so every prefix is distinct, in the order audit, semantics, governance, then triggers") is a small fix worth making before the 0.10.2 release notes are cut.
- IN-01 through IN-04 are informational. IN-01 and IN-02 predate the phase. IN-02 is also listed as deferred in the 206-01 SUMMARY. None affects the goal.

### Human Verification Required

None. Every truth was checked mechanically, including the real `ecto.migrate` path.

### Gaps Summary

There are no gaps. The installer and gen.triggers now take their versions from one shared helper. The versions are unique, strictly increasing, and later than any existing migration. A real `Ecto.Migrator` run over a fresh install plus triggers succeeds, and the regression test fails against the pre-fix code. One non-blocking warning is carried forward: WR-01, the incomplete CHANGELOG workaround for the four-file collision.

---

_Verified: 2026-09-24T18:05:00Z_
_Verifier: Claude (gsd-verifier)_
