---
phase: 216-ci-platform-currency
plan: 01
subsystem: ci
status: complete
tags: [ci, toolchain, setup-beam, cache-keys, contract-tests]
requires: []
provides:
  - "Tracked .tool-versions as the CI current-lane toolchain SSOT"
  - "13 non-matrix ci.yml setup-beam steps on version-file + version-type strict (id: beam)"
  - "Resolved-output (steps.beam.outputs.*) deps and PLT cache keys in every non-matrix job"
  - "Toolchain pin contract classifiers in ci_workflow_parity_contract_test.exs"
affects:
  - "216-02 (verify-test matrix: fills the MATRIX clause of setup_beam_errors/3 and deletes @pending_matrix_jobs)"
  - "Node 24 action-version plan (actions/cache@v4 refs untouched here)"
tech-stack:
  added: []
  patterns:
    - "setup-beam version-file strict + step id `beam`; cache keys interpolate steps.beam.outputs.otp-version / elixir-version after the literal runner label"
    - "Pure classifier functions asserted == [] live and non-empty on named mutation controls"
key-files:
  created:
    - .tool-versions
  modified:
    - .github/workflows/ci.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
    - CONTRIBUTING.md
    - bin/verify-bump-rehearsal
key-decisions:
  - "CONTRIBUTING names ASDF_ERLANG_VERSION / ASDF_ELIXIR_VERSION: `ASDF_ELIXIR_VERSION=1.15.8-otp-26 asdf current elixir` (asdf 0.16.4) reported Source = ASDF_ELIXIR_VERSION, so the named-variable branch was taken"
  - "Classifiers strip comment lines before inspecting steps, so the CACHE KEY CONTRACT prose (which now names steps.beam.outputs) cannot satisfy or break the rules"
  - "Save steps are accepted on the cache-primary-key reuse only when they are actions/cache/save; an unknown cache path or a multi-line key fails closed"
  - "CONTRIBUTING states Node.js 22.14.0 is a local-shell pin only; CI's setup-node steps still request the 22 line (OD-5 deferral left untouched)"
requirements-completed: [PLAT-01]
duration: "~5 min (4 min measured from the recorded start, which was taken after context loading)"
completed: 2026-09-27
plan_head_before: 3dc4d29389764305c052058c57a3cee2c00f8028
actuals:
  tokens: 9700
  tasks: 2
  commits: 2
coverage:
  - deliverable: ".tool-versions tracked, content unchanged, parsed consistently"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#.tool-versions is tracked and names one consistent erlang/elixir build"
        status: pass
      - kind: command
        ref: "git ls-files --error-unmatch .tool-versions && git show HEAD:.tool-versions == the three pre-phase lines"
        status: pass
  - deliverable: "13 non-matrix setup-beam steps on version-file strict with resolved-output deps/PLT keys"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#every non-matrix ci.yml job installs the committed toolchain and keys caches on it"
        status: pass
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#verify-format installs the committed toolchain and keys its deps cache on it"
        status: pass
      - kind: command
        ref: "actionlint -shellcheck= ; grep counts version-file=13, strict=13, deps prefix=20, PLT prefix=2, legacy=0, playwright=4"
        status: pass
  - deliverable: "Dialyzer topology contract re-pinned with literal-OTP-pin and restore-boundary mutation controls"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_topology_contract_test.exs#Dialyzer is one blocking local and current-lane CI path with an exact measured PLT cache"
        status: pass
  - deliverable: "CONTRIBUTING toolchain policy and lane sentences; dated Dialyzer evidence byte-identical"
    human_judgment: false
    verification:
      - kind: command
        ref: "grep -c 34642915672 CONTRIBUTING.md == 2 (pre-task 2); git show HEAD -- CONTRIBUTING.md removes no 27.0.1 line"
        status: pass
      - kind: test
        ref: "test/threadline/ci_topology_contract_test.exs (dated evidence assertions)"
        status: pass
  - deliverable: "bin/verify-bump-rehearsal clone inherits the committed .tool-versions"
    human_judgment: false
    verification:
      - kind: command
        ref: "bash -n bin/verify-bump-rehearsal; grep -cF 'cp \"$ROOT/.tool-versions\"' == 0"
        status: pass
---

# Phase 216 Plan 01: Non-matrix CI toolchain pin Summary

**`.tool-versions` is now committed, and all 13 non-matrix ci.yml jobs install it through setup-beam `version-file` in strict mode (step `id: beam`). The pin moves from the old loose `"27.0"` request, which actually resolved to 27.0.1, to exactly OTP 27.3.4.15 / Elixir 1.17.3-otp-27. Every non-matrix deps and PLT cache key names the toolchain setup-beam resolved, and offline classifier tests with 14 mutation controls go red on any reversion.**

## Performance

- Started: 2026-09-27T02:21:35Z (recorded after context loading)
- Completed: 2026-09-27T02:26:01Z
- Tasks: 2/2
- Files changed: 6

## Accomplishments

- Tracked `.tool-versions` with its content unchanged (`nodejs 22.14.0` / `erlang 27.3.4.15` / `elixir 1.17.3-otp-27`).
- Converted verify-format first as the tracer (Task 1). Then converted verify-credo, verify-dialyzer, verify-compile-no-optional, verify-hex-evaluator, verify-example-browser, verify-mechanical, verify-capture, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-bump-rehearsal and verify-deps-audit.
- Deps keys (10 steps x key + restore-key = 20) and the PLT restore key/restore-keys (2) now use `ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-…`. The PLT save step still reuses `cache-primary-key`. The Playwright keys, the verify-test job, every `uses:` action version and every `timeout-minutes` are untouched.
- Added `describe "toolchain pin contract"` to the parity test. It adds the classifiers `tool_versions_errors/1`, `setup_beam_errors/3` (its MATRIX clause fails closed until plan 02), `beam_ordering_errors/3`, `cache_key_errors/3` and `toolchain_contract_errors/1`, plus the helpers `workflow_jobs/1`, `workflow_job/2`, `job_steps/1` and `strip_comment_lines/1`. It also adds `@beam_independent_cache_paths` (the single Playwright entry with its reason) and `@pending_matrix_jobs ["verify-test"]`.
- The topology Dialyzer contract now asserts the version-file strict step, via the `setup_beam_step/1` and `committed_toolchain_step?/1` helpers, and the resolved PLT prefix. The restore-boundary control was rewritten against the resolved prefix, and a new "literal OTP pin" control was added.
- CONTRIBUTING now:
  - states that `.tool-versions` is committed and pins the CI current lane
  - says the min lane proves the 1.15 / OTP 26 floor
  - explains the per-shell asdf override
  - names the pins in the verify-dialyzer table row and the Dialyzer lane sentence
- bin/verify-bump-rehearsal no longer copies the working-tree `.tool-versions` into its throwaway clone.

## Task Commits

1. Task 1 (tracer): `8642610e` ci(toolchain): track .tool-versions and read it in the format job
2. Task 2: `ddb0c771` ci(toolchain): install the committed toolchain in every non-matrix CI job

## Verification

- The Task 1 `<verify>` command passed after the commit. It was re-run as the tracer feedback gate (end-of-phase mode, automated-only `<verify>`): "Tracer verified end-to-end — expanding".
- The Task 2 `<verify>` command passed after the commit.
- `actionlint -shellcheck=` is clean. The four CI/release contract files pass: 52 tests, 0 failures (baseline 48, plus the 4 new tests). `mix verify.format` and `mix verify.credo` are clean.
- All acceptance criteria for both tasks pass:
  - deps prefix = 20, PLT prefix = 2, `otp${{ matrix.otp }}` = 2, legacy = 0, playwright = 4
  - `"34642915672"` count unchanged (2) in both files
  - 13 control tuples added in Task 1, `@pending_matrix_jobs` count >= 2

## TDD / RED evidence

The plan prescribes one commit per task, so there is no separate `test(...)` commit. RED was observed before each workflow edit:
- Task 1: running the new parity tests against the unedited tree gave 2 target failures. The verify-format live assertion listed 12 contract errors (missing `id: beam` / `version-file` / `version-type`, literal inputs present, literal-segment keys). `git ls-files` reported ".tool-versions did not match any file(s) known to git".
- Task 2: the widened live input and the re-pinned topology rows were written against the new shape and pass only after the ci.yml edits. The mutation controls prove each assertion can go red.

## Deviations from Plan

**1. [Rule 1 - Credo] Split the nested ordering check**
- **Found during:** Task 1
- **Issue:** `mix verify.credo` flagged `beam_ordering_errors/3` as nested too deep (depth 3).
- **Fix:** Moved the offset comparison into `early_output_errors/3`. Behavior is unchanged.
- **Files modified:** test/threadline/ci_workflow_parity_contract_test.exs
- **Commit:** 8642610e

**2. [Scope clarification] CONTRIBUTING Node.js wording**
- **Found during:** Task 1
- **Issue:** The planned paragraph ("CI and an asdf shell run the same build") would overstate Node.js parity. CI's setup-node still requests `"22"` (OD-5 deferred).
- **Fix:** The paragraph scopes the CI claim to the Erlang/Elixir pins and describes Node.js 22.14.0 as a local-shell pin.
- **Commit:** 8642610e

Two extra tests beyond the plan's minimum were added in the parity file. One pins the Playwright exemption map and proves an unknown cache path fails closed. The other counts exactly 13 non-matrix setup-beam steps so the widened live input cannot pass vacuously.

**Total deviations:** 1 auto-fixed (credo), 1 wording clarification. **Impact:** none on scope; no toolchain version, job id, check name or dated evidence changed.

## Known Stubs

- `setup_beam_errors/3` MATRIX clause (`matrix_setup_beam_errors/3`) always returns an error. This is intentional and fail-closed until plan 02 writes the matrix rule and deletes `@pending_matrix_jobs`.

## Next Phase Readiness

Ready for 216-02 (verify-test matrix + min-lane runner image).

## Self-Check: PASSED

- FOUND: .tool-versions (tracked), .github/workflows/ci.yml, test/threadline/ci_workflow_parity_contract_test.exs, test/threadline/ci_topology_contract_test.exs, CONTRIBUTING.md, bin/verify-bump-rehearsal
- FOUND: 8642610e, ddb0c771 (git rev-list --count 3dc4d293..HEAD = 2 before this SUMMARY commit)
