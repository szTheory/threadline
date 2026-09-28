---
phase: 208-identifier-foundation
fixed_at: 2026-09-25T15:30:00Z
review_path: .planning/phases/208-identifier-foundation/208-REVIEW.md
iteration: 1
fix_scope: critical_warning
findings_in_scope: 5
findings_fixed: 5
findings_skipped: 0
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 208: Code Review Fix Report

**Fixed at:** 2026-09-25
**Source review:** .planning/phases/208-identifier-foundation/208-REVIEW.md
**Iteration:** 1
**Where it ran:** in the main checkout `/Users/<user>/projects/threadline` on branch
`milestone/v1.42`, with no worktree. Every gate below can be reproduced from that tree.

**Summary:**
- Findings in scope: 5 (CR-01 and WR-01 to WR-04)
- Fixed: 5
- Skipped: 0
- The hashed-name format (D-01 to D-06) and its golden values are unchanged.

## Verification

All of these ran in the main checkout after the last fix commit:

| Gate | Result |
|------|--------|
| `mix test test/threadline/mix/ test/mix/tasks/threadline/ test/threadline/capture/ test/threadline/storage_schema_test.exs` | 7 properties, 168 tests, 0 failures |
| `mix test` (full suite) | 7 properties, 1923 tests, 0 failures, 1 excluded |
| `mix compile --warnings-as-errors --force` | clean |
| `mix format --check-formatted` | clean |
| `mix credo --strict` | no issues |
| `mix test test/threadline/changelog_contract_test.exs` | 8 tests, 0 failures |

Regression check: the pre-fix `migrations_path.ex` and `threadline.gen.triggers.ex`
were put back temporarily and the new tests were run against them. All 5 new WR-03
and WR-04 tests failed. The fixed files were then restored with `git checkout`.

## Fixed Issues

### CR-01: Rerun detection misses overflowed trigger names from releases before 0.10.0

**Files modified:** `lib/threadline/mix/trigger_migration.ex`, `test/threadline/mix/trigger_migration_test.exs`
**Commit:** ceb11302 (verified in this pass)
**Applied fix:**
- `rerun?/2` requires an identifier boundary after the trigger name only when the
  name is shorter than 63 bytes. A 63-byte name is what PostgreSQL stored for every
  longer name with that prefix, so any source that continues past it counts as a match.
- The test's `longer` assertion was inverted.
- Two tests were added: a regression test for the v0.9.0 unquoted, uncut form
  (67 bytes), and a test showing that a 62-byte name still needs the boundary.
- The review's two-clause suggestion was expressed as a single conditional boundary.
- Verified by the targeted and full suites above.

### WR-01: `Naming.pair/1` accepts any map

**Files modified:** `lib/threadline/capture/naming.ex`, `test/threadline/capture/naming_test.exs`
**Commit:** 69657d43 (verified in this pass)
**Applied fix:**
- The map clause checks `schema` again with `StorageSchema.validate_identifier!/2`
  under the `:host_schema` role, and `table` under the `:host_table` role.
- The test covers an invalid schema, which fails as "host schema" and not "storage schema".
- It also covers a 70-byte table, which fails as "host table" and reports its 70 bytes.
- A valid map still equals the result of `parse_table_identifier/1`.
- Golden values are unaffected.

### WR-02: `mix threadline.install` silently ignores positional arguments

**Files modified:** `lib/mix/tasks/threadline.install.ex`
**Commit:** d98f6746 (verified in this pass)
**Applied fix:**
- This was fixed in the docs rather than the code. The install moduledoc now says
  that unknown flags raise and that positional arguments are ignored.
- The CHANGELOG "Breaking changes" entry already said this.
- As a result, neither the moduledoc nor the CHANGELOG claims that install rejects
  everything it does not recognise.
- The task still ignores positional arguments. Making them an error was not done
  here; it is a possible future change.

### WR-03: A configured but unloadable default repo silently falls back to `priv/repo/migrations`

**Files modified:** `lib/threadline/mix/migrations_path.ex`, `lib/mix/tasks/threadline.install.ex`,
`lib/mix/tasks/threadline.gen.triggers.ex`, `test/threadline/mix/migrations_path_test.exs`,
`test/mix/tasks/threadline/gen_triggers_test.exs`, `test/support/custom_priv_repo.ex`, `CHANGELOG.md`
**Commits:** eba9a0fe and 5f18fd48 (first attempt, superseded), defc3fc0 (code, tests and
moduledocs), 8c1ad6d4 (CHANGELOG)
**Applied fix:**
- The first attempt (eba9a0fe, 5f18fd48) made a failed default lookup raise. That broke
  locked decision D-08, which keeps install's fallback to `priv/repo/migrations` when the
  default lookup fails, so behavior does not change in 208. defc3fc0 and 8c1ad6d4 replace it.
- The fallback stays, but it is no longer silent. If the first `:ecto_repos` entry cannot
  be loaded, has no `config/0`, or its `config/0` raises, the resolver still returns
  `priv/repo/migrations`. It also prints a `Mix.shell().error/1` warning that names the
  repo and the reason. For a raising config, the reason includes the exception message.
- The blanket `rescue _ -> @default` is not restored. Only the repo's `config/0` read is
  rescued. With no app (an umbrella root) or no `:ecto_repos`, the directory is
  `priv/repo/migrations` with no warning.
- An explicit `--repo` that cannot be loaded still raises. That part complies with D-08.
- The CHANGELOG "Breaking changes" entry from 5f18fd48 is removed. A one-paragraph note
  under "Changed" says both tasks fall back as before and now print a warning.
- The install and gen.triggers moduledocs say an unloadable configured repo falls back
  to `priv/repo/migrations` with a warning.
- Tests:
  - an unloadable entry returns `priv/repo/migrations` and warns, naming the repo
  - an entry whose config raises returns the fallback and warns, naming the repo and the cause
  - a loadable entry resolves with no warning
  - an unset `:ecto_repos` falls back to `priv/repo/migrations`
  - `--migrations-path` never loads a broken configured repo
  - an explicit `--repo` that cannot be loaded still raises
  - at task level, gen.triggers writes to `priv/repo/migrations` and warns, naming the repo
  - the resolver tests use `Mix.Shell.Process` and assert on `{:mix_shell, :error, _}`
- The test stub `Threadline.TestSupport.BrokenConfigRepo` (from eba9a0fe) is unchanged.
- Gates after the rework, in the main checkout: targeted suites 89 tests, 0 failures.
  Full `mix test`: 7 properties, 1924 tests, 0 failures, 1 excluded.
  `mix compile --warnings-as-errors --force`, `mix format --check-formatted` and
  `mix credo --strict` are clean. The changelog contract test: 8 tests, 0 failures.

### WR-04: `--repo` validation is skipped on `--dry-run`

**Files modified:** `lib/mix/tasks/threadline.gen.triggers.ex`, `test/mix/tasks/threadline/gen_triggers_test.exs`
**Commit:** 2a850800
**Applied fix:**
- `run/1` now calls `MigrationsPath.resolve/1` before the `--dry-run` branch and
  passes the path to `write_migration!/3`. `run/1` stays well under the 120-line cap.
- Tests added: `--dry-run` with a repeated `--repo` raises, and `--dry-run` with an
  unloadable `--repo` raises.
- A dry run with a valid `-r` prints the dry-run line and writes nothing.

## Out of Scope (Info findings, fix_scope = critical_warning)

- **IN-01:** Cut trigger names widen the accepted `rerun?` false positive. The CR-01
  fix widens it a little more at the 63-byte cap, which is the conservative direction
  D-11 accepts. Carry this into Phase 209 NAME-03, where rerun matching moves to the
  `ON` clause.
- **IN-02:** `Naming.suffix/1` duplicates `StorageSchema.host_table_suffix/1`, and
  `TriggerSQL` has its own function-name builder. For Phase 209.
- **IN-03:** The "names are deterministic" property is partly tautological.
- **IN-04:** `migration_name/2` removes duplicates from the hash but not from the
  readable part (`posts,public.posts`).
- **IN-05:** `StorageSchema.validate!/1` still labels every failure "storage schema".
- **IN-06:** An empty `--migrations-path=` is accepted.

---

_Fixed: 2026-09-25_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
