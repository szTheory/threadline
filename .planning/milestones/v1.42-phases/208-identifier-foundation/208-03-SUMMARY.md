---
phase: 208-identifier-foundation
plan: 03
subsystem: mix-tasks
status: complete
tags: [mix, install, migrations-path, CONF-02]
requires: ["208-01"]
provides:
  - "Threadline.Mix.MigrationsPath.resolve/1 (@doc false): --migrations-path > --repo/-r :priv > configured repo :priv > priv/<repo>/migrations > priv/repo/migrations"
  - "mix threadline.install --migrations-path / --repo / -r, strict parsing, unknown options raise"
  - "Threadline.TestSupport.CustomPrivRepo and NoPrivRepo stub repos (test/support)"
affects: ["208-05 (gen.triggers adopts MigrationsPath.resolve/1 and reuses the stub repos)"]
tech-stack:
  added: []
  patterns: ["shared resolver module for both generator tasks; strict OptionParser + 'Unknown options' Mix.raise copied from gen.triggers"]
key-files:
  created:
    - lib/threadline/mix/migrations_path.ex
    - test/support/custom_priv_repo.ex
    - test/threadline/mix/migrations_path_test.exs
  modified:
    - lib/mix/tasks/threadline.install.ex
    - test/mix/tasks/threadline/install_test.exs
    - CHANGELOG.md
decisions:
  - "The repeated-repo check runs before --migrations-path short-circuits, so `--repo A --repo B --migrations-path x` still raises"
  - "The CHANGELOG does not claim a :priv behavior change: install already honoured :priv before this plan; only the flags and the unknown-option rejection are new"
requirements-completed: []
coverage:
  - deliverable: "MigrationsPath.resolve/1 precedence matrix"
    human_judgment: false
    verification:
      - kind: test
        ref: test/threadline/mix/migrations_path_test.exs
        status: pass
  - deliverable: "install --migrations-path, --repo/-r, custom :priv, unknown-option rejection"
    human_judgment: false
    verification:
      - kind: test
        ref: test/mix/tasks/threadline/install_test.exs
        status: pass
  - deliverable: "Moduledoc and CHANGELOG describe the flags"
    human_judgment: false
    verification:
      - kind: test
        ref: test/threadline/changelog_contract_test.exs, test/threadline/release_artifact_contract_test.exs
        status: pass
metrics:
  duration: "~5 min"
  completed: 2026-09-25
actuals:
  tokens: 3400
  tasks: 2
  commits: 3
plan_head_before: c4a97de3d931817b79d905bf36585ec97a8a026a
---

# Phase 208 Plan 03: Shared migrations-path resolver and install flags Summary

`mix threadline.install` now gets its directory from `Threadline.Mix.MigrationsPath.resolve/1`. It accepts `--migrations-path` (used as given, repo never loaded) and `--repo`/`-r`, which may be given once. Unknown options raise a `Mix.Error`. With no flags it behaves as before.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 (RED) | Failing --migrations-path and unknown-flag install tests | aa2b5011 | test/mix/tasks/threadline/install_test.exs |
| 1 (GREEN) | MigrationsPath.resolve/1 wired into install | 166a4f45 | lib/threadline/mix/migrations_path.ex, lib/mix/tasks/threadline.install.ex, test/mix/tasks/threadline/install_test.exs |
| 2 | Precedence matrix, stub repos, custom :priv install tests, moduledoc, CHANGELOG | e0d319ef | test/support/custom_priv_repo.ex, test/threadline/mix/migrations_path_test.exs, test/mix/tasks/threadline/install_test.exs, lib/mix/tasks/threadline.install.ex, CHANGELOG.md |

## Verification

- RED: 2 of the 3 new Task 1 tests failed: the files were not under `db/audit_migrations`, and `--bogus` did not raise. The default-directory test passed, as intended, because it pins behavior that must not change.
- Task 1 verify: 13 tests, 0 failures. Tracer gate: the automated verify was re-run and passed, so the plan went on to Task 2.
- Task 2 verify command (migrations_path, install, changelog, release artifact and public surface contracts): 90 tests, 0 failures. The plan-level `test/threadline/mix/` plus install plus contracts run: 113 tests, 0 failures.
- Full `mix test`: 1869 tests, 0 failures, 1 excluded.
- `mix compile --warnings-as-errors` is clean, `mix format --check-formatted` is clean, and `mix credo --strict` on the new and changed files found no issues.

## Deviations from Plan

**1. Task 2's tests were never red.** Task 1 had already implemented the whole resolver (steps 1a-1e), so the Task 2 precedence and install tests passed the first time they ran. They lock in the behavior but did not drive it. No RED commit was made for Task 2.

**2. The `async: false` acceptance grep prints 2, not 1.** The plan requires both `use ExUnit.Case, async: false` and a `# async: false —` rationale comment, and each contains the string. Both are present as asked. Nothing was changed to make the count match.

**3. [Rule 1] CHANGELOG wording corrected before commit.** A first draft said a repo with `:priv` "now" gets its migrations under that directory. The old install already did this, so the entry now says the no-flag directory is chosen as before.

**4. CONF-02 stays Pending.** Plan 05 finishes it by adopting the resolver in gen.triggers.

## Known Stubs

None. `Threadline.TestSupport.CustomPrivRepo`/`NoPrivRepo` are test-only stub repos by design.

## Self-Check: PASSED

- lib/threadline/mix/migrations_path.ex, test/support/custom_priv_repo.ex and test/threadline/mix/migrations_path_test.exs exist.
- Commits aa2b5011, 166a4f45 and e0d319ef are in `git log`.
