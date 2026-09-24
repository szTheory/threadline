---
phase: 206-installer-migration-versions
plan: 02
subsystem: release-docs
tags: [changelog, installer, migrations, phase-gate]
status: complete
requires:
  - 206-01 (shared migration-version helper, install + gen.triggers rewired, advice branches)
provides:
  - CHANGELOG.md Unreleased entry for the installer migration-version fix
  - phase gate evidence over the combined 206 change
affects:
  - CHANGELOG.md
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - CHANGELOG.md
decisions:
  - "CHANGELOG entry keeps the meaning of the corrected partial re-run advice but drops the WR-03/CR-01 IDs, because the packaged-file vocabulary test bans them (recorded D-12 wording deviation)"
metrics:
  duration: "~12 min"
  completed: 2026-09-24
  tasks: 2
  files: 1
actuals:
  tokens: 650
  tasks: 2
  commits: 2
plan_head_before: 8374f851e7d616770c0e4b48d451dd9774ff231d
---

# Phase 206 Plan 02: CHANGELOG Entry and Phase Gate Summary

The Unreleased CHANGELOG entry quotes Ecto's exact duplicate-version error. It says
every release through 0.10.1 is affected and gives the semantics-then-governance
rename workaround. It also covers the gen.triggers fix and the corrected partial
re-run advice. Every phase gate passes on the combined phase change. Credo passed
only after an orchestrator fix to plan 01's test file.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 | dc1c5e7a | docs(changelog): note the installer migration-version fix |
| (orchestrator) | e4559c0f | test(install): alias the gen.triggers task in the install test |

`commits: 2` is measured as `git rev-list --count 8374f851..HEAD`, taken before this
SUMMARY's docs commit. The count includes the orchestrator's e4559c0f.

## Task 1: CHANGELOG entry

- Only the `_Nothing yet for the next release._` line was replaced. The
  `## Unreleased — highlights` heading and its paragraph are unchanged. The heading
  appears exactly once.
- The entry follows the file's template, in this order: lead prose, `### Breaking changes`
  (None), `### Required action`, `### Fixed` (3 `- ` bullets: install versions,
  gen.triggers, partial re-run advice).
- Contract batch: install, changelog, release_artifact, public_surface,
  code_walkthrough, getting_started_saas and upgrade_path. Result: **101 tests,
  0 failures**.
- Region grep (`/Users/jon/.claude/jobs/77cf1bdd/tmp/206-unreleased.md`) exited 0.
  - All required strings are present: `migrations can't be executed, migration version`,
    `is duplicated`, `0.10.1`, both schema filenames and `mix threadline.gen.triggers`.
  - None of the forbidden identifiers appear: the helper module name, WR/CR/D- IDs,
    phase references, v1.40/v1.41, and `hex.retire`.

## Task 2: Phase gate

Outputs are saved ANSI-stripped under `/Users/jon/.claude/jobs/77cf1bdd/tmp/206-02-gate-*.txt`.

| Gate | Result | Summary line |
|------|--------|--------------|
| `mix test` (full suite) | PASS | 1800 tests, 0 failures, 1 excluded (1787 baseline + 13) |
| `mix verify.format` | PASS | exit 0 (re-run after e4559c0f: exit 0) |
| `MIX_ENV=test mix verify.credo` | RED, then PASS | first run: 1 issue at install_test.exs:235 (exit 2). After e4559c0f: 3487 mods/funs, found no issues |
| `MIX_ENV=dev mix verify.dialyzer` | PASS | Total errors: 0, Skipped: 0 (no PLT rebuild needed) |
| `mix verify.xref_cycles` | PASS | No cycles found |
| `MIX_ENV=dev mix release.pins --check` | PASS | 0 pin site(s) differ from the derived pin (`~> 0.10.0`) |
| `MIX_ENV=dev mix docs --warnings-as-errors` | PASS | exit 0, html/markdown/epub written |
| End-to-end probe (install, then gen.triggers) | PASS | 4 files, 4 distinct, strictly increasing 14-digit prefixes |

After e4559c0f, `install_test.exs` and `migration_version_test.exs` together give
17 tests, 0 failures. e4559c0f changes only a test file, with no lib/ changes, so the
suite, dialyzer, xref, docs and probe results above still apply.

Probe filenames, in write order:

```
20260924175414_threadline_audit_schema.exs
20260924175415_threadline_semantics_schema.exs
20260924175416_threadline_governance_schema.exs
20260924175417_threadline_triggers_posts.exs
```

`git status --porcelain -- lib test CHANGELOG.md mix.exs` was empty after the gates.

## Deviations from Plan

**1. [D-12 wording, recorded in the plan] No planning IDs in the CHANGELOG**
- D-12 asked for a mention that the partial re-run advice was corrected (WR-03).
  CHANGELOG.md ships in the Hex tarball, and `release_artifact_contract_test.exs`
  bans `WR-\d{2,}`. The entry keeps the meaning and drops the ID. The same applies
  to CR-01.

**2. [Gate failure in plan 01's code, fixed by the orchestrator] Credo red at install_test.exs:235**
- **Found during:** Task 2, `MIX_ENV=test mix verify.credo`.
- **Issue:** `[D] Nested modules could be aliased at the top of the invoking module.`
  The flagged line is plan 01 commit 2d6cf376, which calls
  `Mix.Tasks.Threadline.Gen.Triggers.run(...)` by its full name. Plan 01's summary
  reported credo clean on its own files. The repo alias runs `credo --strict`
  across all files, and that run caught the issue.
- **Fix:** The plan forbids patching plan 01's files here, so the executor halted
  and reported. The orchestrator committed e4559c0f, which adds
  `alias Mix.Tasks.Threadline.Gen.Triggers` and calls `Triggers.run(...)`. The
  executor re-ran credo afterwards: found no issues.

## D-13 confirmation

No `mix hex.retire` step, no new Troubleshooting guide section, and
`guides/getting-started-saas.md` was not touched. Nothing was pushed, and no
release or tag state changed.

## Known Stubs

None.

## Threat Flags

None. CHANGELOG text only. T-206-05 is mitigated by the vocabulary test and the region
grep. T-206-07 is mitigated by the docs build with warnings as errors.

## Self-Check: PASSED

- FOUND: CHANGELOG.md with the Unreleased entry
- FOUND commits: dc1c5e7a, e4559c0f
