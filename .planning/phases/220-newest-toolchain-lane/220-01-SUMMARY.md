---
phase: 220-newest-toolchain-lane
plan: 01
subsystem: infra
tags: [elixir-1.20, otp-29, postgres-18, ci, warnings-as-errors, pre-spike]

requires:
  - phase: 219
    provides: "verify-test matrix (min/current) and cache key shape the latest lane extends"
provides:
  - "Zero Elixir 1.20 compile warnings in our own lib/ and test/support/ (six D-08 dead-code removals)"
  - "Local pre-spike evidence: full suite green on Elixir 1.20.4 / OTP 29.1.1 against PostgreSQL 18.6"
  - "Re-verified D-01 pins (1.20.4 / 29.1.1 / 18.6) for plan 02"
affects: [220-02, 220-03, ci.yml verify-test latest lane]

actuals:
  tokens: 15300
  tasks: 2
  commits: 1
plan_head_before: 1934d82d3c210d9ca13cc675651418ae80355a37
plan_head_after: 17a7faa5

tech-stack:
  added: []
  patterns:
    - "Version-neutral binary slicing via binary_part/3 instead of a size-bound bitstring match (compiles 1.15.8 through 1.20.4)"
    - "On macOS, spell an out-of-tree MIX_BUILD_ROOT under /private/tmp, not /tmp"

key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.incident.ex
    - test/support/migration_harness.ex
    - lib/threadline/critic_trust/ledger_splice.ex
    - lib/threadline/operator_surface/live/export_status_live/components.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex

key-decisions:
  - "Pins unchanged at execution time: Elixir 1.20.4, OTP 29.1.1, PostgreSQL 18.6 (18.7 absent). Plan 02 pins these values"
  - "Pre-spike ran on the exact D-01 pair (1.20.4 / 29.1.1), not the 1.20.2 / 29.0.5 fallback"
  - "The isolated build root is /private/tmp/threadline-220-latest-build (same physical directory as /tmp/...). The /tmp spelling breaks Mix's relative dep symlinks on macOS"

patterns-established:
  - "D-08 bar: an Elixir-1.20 warning fix is dead-code removal or a version-neutral rewrite, never Version.match? branching"

requirements-completed: [LANE-01]

coverage:
  - id: D1
    description: "Six D-08 warnings removed with no behaviour change; lib/ compiles clean under --warnings-as-errors on 1.20.4 / 29.1.1 and on the committed 1.17.3 / 27.3.4.15"
    requirement: "LANE-01"
    verification:
      - kind: other
        ref: "ASDF_ERLANG_VERSION=29.1.1 ASDF_ELIXIR_VERSION=1.20.4-otp-29 MIX_ENV=test MIX_BUILD_ROOT=/private/tmp/threadline-220-latest-build mix compile --warnings-as-errors --force"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix compile --warnings-as-errors --force && mix format --check-formatted && mix verify.credo"
        status: pass
      - kind: unit
        ref: "mix test ledger_splice_test.exs actor_live_test.exs export_status_live_test.exs evidence_live_test.exs threadline.incident_test.exs (62 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Local pre-spike: full suite on Elixir 1.20.4 / OTP 29.1.1 against a dedicated postgres:18.6 container is green; committed-toolchain full suite is green"
    requirement: "LANE-01"
    verification:
      - kind: integration
        ref: "DB_HOST=localhost DB_PORT=55418 <new-toolchain prefix> mix test (2509 passed, 3 excluded)"
        status: pass
      - kind: integration
        ref: "mix test (committed toolchain, shared PG: 9 properties, 2503 tests, 0 failures, 3 excluded)"
        status: pass
    human_judgment: false

duration: 21min
completed: 2026-09-28
status: complete
---

# Phase 220 Plan 01: Newest-toolchain pre-spike Summary

**Removed the six Elixir 1.20 type-checker warnings (unused `require Logger` x2, a size-bound bitstring match rewritten with `binary_part/3`, two never-matching clauses, one always-true guard). The full 2509-test suite then passes on Elixir 1.20.4 / OTP 29.1.1 against PostgreSQL 18.6 with 0 failures, before any paid CI minute.**

## Performance

- **Duration:** about 21 min, including the from-source Erlang 29.1.1 build
- **Started:** 2026-09-28T20:20:58Z
- **Completed:** 2026-09-28T20:42:21Z
- **Tasks:** 2
- **Files modified:** 6

## Pins

Fetched live on **2026-09-28**. Each source was re-checked at execution time, per D-01.

| Component | Newest found | Source | vs CONTEXT D-01 |
|-----------|--------------|--------|-----------------|
| Elixir | `v1.20.4-otp-29` (2026-08-28T10:07:51Z) | builds.hex.pm/builds/elixir/builds.txt, newest `v1.20.*-otp-29` line | unchanged |
| OTP | `OTP-29.1.1` (2026-09-22T08:11:48Z) | builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt, newest `OTP-29` line | unchanged |
| PostgreSQL | `18.6` | `docker manifest inspect postgres:18.6` succeeds; `postgres:18.7` does not exist | unchanged |

**Plan 02 pins `elixir: "1.20.4"`, `otp: "29.1.1"`, `pg: "18.6"`.**

## Baseline warnings

Baseline command: `mix compile --warnings-as-errors --force` on Elixir 1.20.4 / OTP 29.1.1, run before any edit. The log is at `/tmp/threadline-220-baseline-compile.log`. It exited 1 with "Compilation failed due to warnings". These are the own-code warnings, exactly the six D-08 predicted. No 7th warning appeared (Pitfall 1 did not materialise).

| # | file:line | Warning class |
|---|-----------|---------------|
| 1 | `lib/threadline/critic_trust/ledger_splice.ex:85:22` (`find_close/2`) | variable `open` accessed inside `size(...)` of a bitstring but defined outside the match (pin required) |
| 2 | `lib/mix/tasks/threadline.incident.ex:38:7` | unused `require Logger` |
| 3 | `test/support/migration_harness.ex:16:3` | unused `require Logger` |
| 4 | `lib/threadline/operator_surface/live/export_status_live/components.ex:173:10` (`timeline_search_path/2`) | clause is never used |
| 5 | `lib/threadline/operator_surface/live/actor_live.ex:233` (`actor_activity/1`) | type warning: conditional expression `assigns.has_ever_acted` always succeeds (`dynamic(true)`) |
| 6 | `lib/threadline/operator_surface/live/evidence_live.ex:438:10` (`maybe_put/3`) | clause is never used |

The dependency warnings below do not fail the root app, and none is a dependency *error* on OTP 29.1.1:
- `yamerl` (Erlang/rebar3): `'catch ...' is deprecated` at `yamerl_node_binary.erl:65,72` and `yamerl_constr.erl:801`; unused variable `Errors` at `yamerl_errors.erl:55`
- `yaml_elixir`: unused `require Record` (`lib/yaml_elixir/yaml_node_keyword_list.ex:2`)
- `phoenix`: `lib/phoenix/template.ex:505` (`Phoenix.Template.unsuffix/2`)
- `oban`: `lib/oban/job.ex:849` (`Oban.Job.validate_keys/2`)
- `sweet_xml`: `lib/sweet_xml.ex:838` and `:246`
- Two dependency `mix.exs` files print `"xref: [exclude: ...]" ... is deprecated`. Our `mix.exs` has no `xref: [exclude:]`.

## Pre-spike (local)

- **Toolchain:** Elixir **1.20.4** (compiled with Erlang/OTP 29), OTP **29.1.1** (erts-17.1). This is the exact D-01 pair, not the fallback. Erlang 29.1.1 was built from source with asdf. Elixir 1.20.4-otp-29 was installed precompiled. Hex 2.5.1 and rebar 3.25.1 were installed for it.
- **Build root:** `/private/tmp/threadline-220-latest-build`. This is the isolated root; the default `_build` was not touched by the new toolchain. See Deviation 1 for why it is not spelled `/tmp/...`.
- **Database:** dedicated container `threadline-220-pg18`, `postgres:18.6`, host port 55418. `show server_version` returned **`18.6 (Debian 18.6-1.pgdg13+2)`**. Image digest: **`postgres@sha256:5a5a84b19854a9ffaa54082c166ff4ec27473a361e496e5ea167f298f2da9722`**. That digest confirms Assumption A3: the bare `18.6` tag resolves.
- **New-toolchain compile** after the fixes: `mix compile --warnings-as-errors --force` exits 0, with zero `warning:`/`error:` lines naming `lib/` or `test/support/`. `mix verify.xref_cycles` reports "No cycles found".
- **Suite** (`DB_HOST=localhost DB_PORT=55418 <prefix> mix test`, log `/tmp/threadline-220-latest-test.log`, 160.5 s): ExUnit summary line **`Result: 2509 passed (9 properties, 2500 tests), 3 excluded`**. That is **0 failures**, so there is nothing to classify.
- **`grep -c 'warning:'` = 25**, split as:
  - **20 test-file warnings** (paths under `test/`). They are non-fatal under D-05, because `verify.test` is plain `mix test`:
    - `public_surface_contract_test.exs:234` and `:286`: 9 comparison-between-distinct-types warnings
    - `release_artifact_contract_test.exs:274`: 5 of the same class
    - `health_findings_doc_contract_test.exs:31`: distinct-types comparison
    - `style_byte_lock_test.exs:153`: distinct-types comparison
    - `ci_workflow_parity_contract_test.exs:2826`: distinct-types comparison
    - `stress_ledger_test.exs:271`: clause will never match
    - `export_test.exs:487`: incompatible types given to `format_changes_iodata/3`. This is a deliberate FunctionClauseError test.
    - `test/mix/tasks/threadline.incident_test.exs:6`: unused `require Logger`
  - **5 other warnings:**
    - 1 is ExUnit's test-load-filter notice for `test/fixtures/deps_audit/vulnerable_lock/mix.exs`.
    - 4 are runtime "log level `:warn` is deprecated" warnings. They originate in the **ecto_sql** dependency: `ecto/adapters/postgres/connection.ex:1448` maps a PG `WARNING` notice to `:warn`. They are dependency warnings, not ours.
- **Committed-toolchain regression run** (1.17.3 / 27.3.4.15, shared PG, default `_build`): **`9 properties, 2503 tests, 0 failures, 3 excluded`** (145.7 s). There was no `too_many_connections` error.
- **Test-count parity.** Both suites were run with `--trace --seed 0` and the executed test names were extracted. Both toolchains ran the same **2509** tests. The two summary lines differ only in formatting: Elixir 1.17 counts the 3 excluded tests inside "2503 tests" (9 + 2503 = 2509 + 3), and 1.20's "passed" count does not. No test is silently skipped on the new lane.
- **Prediction for plan 03:** the latest row should be green on compile `--warnings-as-errors`, `verify.xref_cycles` and `verify.test`. Remaining risk: the CI Linux runner uses setup-beam's prebuilt OTP instead of a macOS source build, and flake noise.
- **Cleanup:** container `threadline-220-pg18` removed. `/private/tmp/threadline-220-latest-build` is kept for plan 03's possible fix cycle.

## Accomplishments
- The Elixir 1.20 warning surface in our own code is zero. No version-conditional code; `.tool-versions`, `mix.lock` and `mix.exs` are byte-identical.
- The newest-toolchain suite result on PostgreSQL 18.6 is known (green) before any CI spend.
- Pins re-verified the same day; no drift.

## Task Commits

1. **Task 1: Tracer: re-check pins, baseline, six D-08 fixes, clean compile on both toolchains** - `17a7faa5` (refactor)
2. **Task 2: Local pre-spike on the new toolchain + PG 18.6, then the committed-toolchain suite** - no tracked-file changes. The evidence is recorded in this SUMMARY.

The tracer feedback gate (row 3: interactive, end-of-phase, automated-only verify) re-ran the new-toolchain compile after the commit and it exited 0. Expansion to Task 2 proceeded.

## Files Created/Modified
- `lib/mix/tasks/threadline.incident.ex`: dropped the inner `require Logger`. `Logger.configure/1` is a function, so the require was unused.
- `test/support/migration_harness.ex`: dropped the module-level `require Logger`. Every later use is a function call.
- `lib/threadline/critic_trust/ledger_splice.ex`: `find_close/2` now slices with `binary_part(text, open, byte_size(text) - open)`. Same name and arity; no `^`, no `Version.match?`.
- `lib/threadline/operator_surface/live/export_status_live/components.ex`: removed the never-matching `timeline_search_path(base_path, _params)` fallback clause.
- `lib/threadline/operator_surface/live/evidence_live.ex`: removed the never-matching `maybe_put(params, _key, nil)` clause.
- `lib/threadline/operator_surface/live/actor_live.ex`: `if @has_ever_acted and Enum.empty?(...)` became `if Enum.empty?(...)` inside the `else` of `if not @has_ever_acted`.

## Decisions Made
- The D-08 fixes landed as one `refactor(220)` commit (Claude's discretion per CONTEXT).
- Ran the pre-spike on the exact 1.20.4 / 29.1.1 pins, because the source build succeeded on the second attempt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Isolated build root spelled `/private/tmp/...` instead of `/tmp/...`**
- **Found during:** Task 1, step 3 (baseline compile)
- **Issue:** With `MIX_BUILD_ROOT=/tmp/threadline-220-latest-build`, yamerl failed to compile ("can't find include file yamerl_errors.hrl"). The same failure occurred on OTP 29.0.5 and on the committed 1.17.3 / 27.3.4.15, so it was not toolchain-related. Root cause: macOS `/tmp` is a symlink to `/private/tmp`. Mix writes the dep's `include`/`src` links as relative paths computed from the `/tmp/...` spelling, and they resolve to a nonexistent `/private/<home>/...` path.
- **Fix:** Used `MIX_BUILD_ROOT=/private/tmp/threadline-220-latest-build`. It is the same physical directory with a canonical spelling. Deleted the scratch build roots created during diagnosis. The plan's `<verify>` commands were run with this substitution.
- **Files modified:** none (environment only)
- **Verification:** yamerl and all other deps compiled; the root app compiled clean.
- **Relevance to plan 03:** none on CI, where `/tmp` on Linux runners is not a symlink.

**2. [Rule 3 - Blocking] Erlang 29.1.1 asdf build failed on the first attempt**
- **Found during:** Task 1, step 2
- **Issue:** The build hit `No version is set for command erlc` / `deps/deps.mk:1: *** missing separator` because the asdf `erlc` shim was on PATH during the OTP bootstrap, with no version set in the build cwd. The failed run also left an empty `installs/erlang/29.1.1` directory, which made the retry report "already installed".
- **Fix:** Removed that empty directory (`rmdir`) and rebuilt with the asdf shims directory stripped from PATH. The second build succeeded.
- **Files modified:** none (local toolchain only)
- **Verification:** `elixir --version` reports Elixir 1.20.4 compiled with OTP 29, and the OTP_VERSION file reads 29.1.1.

---

**Total deviations:** 2 auto-fixed (both Rule 3, local environment). **Impact on plan:** no code or scope change. They only enabled running the exact pins locally.

## Issues Encountered
None beyond the two environment deviations above. As extra evidence, `--trace` runs on both toolchains confirmed that the test-count difference is formatting only.

## User Setup Required
None. No external service configuration required.

## Next Phase Readiness
- Plan 02 can pin `1.20.4` / `29.1.1` / `18.6` as-is.
- Plan 03's spike should be green on the latest row. The D-08 fixes must also hold on the 1.15.8 / 26.2.5.21 min lane, which is not installed locally; CI proves it. `binary_part/3` and clause removals are available on every supported version.
- STATE.md / ROADMAP.md / REQUIREMENTS.md updates are left to the orchestrator. LANE-01 is shared with plan 03, which supplies the run-ID evidence.

---
*Phase: 220-newest-toolchain-lane*
*Completed: 2026-09-28*

## Self-Check: PASSED

- FOUND: all six modified files; commit 17a7faa5 present; container removed; lib/test/config/mix.exs/mix.lock/.tool-versions clean
