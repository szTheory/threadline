---
phase: 216-ci-platform-currency
plan: 02
subsystem: ci
status: complete
tags: [ci, toolchain, setup-beam, matrix, runner-image, contract-tests]
requires:
  - "216-01 (toolchain pin contract helpers, @pending_matrix_jobs stub)"
provides:
  - "verify-test setup-beam step strict (id: beam) fed by matrix.version-file / matrix.otp / matrix.elixir"
  - "Min lane at the exact floor build OTP 26.2.5.21 / Elixir 1.15.8 on ubuntu-24.04; current lane reads .tool-versions on ubuntu-24.04"
  - "Resolved-output matrix deps key; toolchain contract over all of ci.yml with no exclusion"
  - "verify_test_matrix_errors/2, MATRIX clause of setup_beam_errors/3, runner_image_errors/2, os_family_context_errors/2"
affects:
  - "Next plan widens runner_image_errors/2 to every workflow"
  - "Plan 06 collects the run-ID proof of the min lane on ubuntu-24.04 after the push gate"
tech-stack:
  added: []
  patterns:
    - "Matrix rows set exactly one toolchain source (version-file OR otp/elixir pins); absent matrix keys render as empty setup-beam inputs"
    - "Min row tied to the mix.exs `elixir: \"~> X.Y\"` floor by a parsed-value classifier"
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
key-decisions:
  - "actionlint accepted `matrix.version-file` (the key exists on the current row), so the RESEARCH fallback (literal current-row pins) was not needed"
  - "The MATRIX clause accepts only job id verify-test and exactly four inputs (version-file, otp-version, elixir-version from matrix values, plus version-type: strict)"
  - "The OS-family check scans the whole file including comments; runner_image_errors/2 scans comment-stripped lines, so explanatory prose may still mention the old image generically"
requirements-completed: [PLAT-01, PLAT-03]
duration: "22 min"
completed: 2026-09-27
plan_head_before: eca9b3f5469262fc2643775ab96993447e5e1d5c
actuals:
  tokens: 5400
  tasks: 2
  commits: 2
coverage:
  - deliverable: "verify-test matrix: strict matrix-fed step, exact floor pins, both lanes on ubuntu-24.04"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#each lane installs one exact toolchain: the floor build or the committed .tool-versions"
        status: pass
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#the verify-test setup-beam step is strict and fed only by matrix values"
        status: pass
      - kind: command
        ref: "actionlint -shellcheck= ; grep counts strict=14, id beam=14, resolved deps=22, legacy matrix key=0, runner 24.04 in verify-test=2"
        status: pass
  - deliverable: "Toolchain contract over the full ci.yml with no exclusion list"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#every ci.yml job installs an exact toolchain and keys caches on it"
        status: pass
  - deliverable: "Guards against the deprecated runner image and the OS-family cache-key segment"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#ci.yml runs no job on the deprecated runner image"
        status: pass
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#ci.yml never names the OS-family runner context, comments included"
        status: pass
      - kind: command
        ref: "full mix test: 9 properties, 2301 tests, 0 failures, 2 excluded"
        status: pass
---

# Phase 216 Plan 02: Strict verify-test matrix and min lane on ubuntu-24.04 Summary

**The verify-test matrix now installs exact toolchains through one strict setup-beam step (`id: beam`). The min lane pins the floor build OTP 26.2.5.21 / Elixir 1.15.8, the current lane reads the committed `.tool-versions`, and both run on ubuntu-24.04. Its deps key names the resolved OTP/Elixir, the toolchain contract covers all of ci.yml with no exemption, and new classifiers fail on the deprecated runner image or any OS-family runner context in ci.yml.**

## Performance

- Started: 2026-09-27T02:28:21Z
- Completed: 2026-09-27T02:50:46Z (most of the elapsed time was the full `mix test` run)
- Tasks: 2/2
- Files changed: 2

## Accomplishments

- ci.yml verify-test:
  - rows: min `elixir: "1.15.8"`, `otp: "26.2.5.21"`, `pg: "14"`, `runner: "ubuntu-24.04"`; current `version-file: ".tool-versions"`, `pg: "16"`, `runner: "ubuntu-24.04"`
  - setup-beam step: `id: beam`, inputs `version-file` / `otp-version` / `elixir-version` from matrix values, `version-type: strict`
  - deps key/restore-key: `${{ matrix.runner }}-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-…`
  - `lane: [min, current]`, `name: Run test suite`, `CI required`, services and checkout unchanged
- Comments rewritten to stay true: the verify-test header (exact floor build, one toolchain source per row), the key-bug history (no image label, no OS-family expression), and the CACHE KEY CONTRACT matrix clause (matrix values select what to install; segments come from `beam` outputs).
- Parity test:
  - `@pending_matrix_jobs` deleted; the live contract runs over the full ci.yml and counts 14 setup-beam steps
  - MATRIX clause of `setup_beam_errors/3` implemented (verify-test only, exact inputs, `id: beam`)
  - `verify_test_matrix_errors/2` with 7 mutation controls plus a raised-floor mix.exs control
  - a verify-test step test with 6 mutation controls plus a "matrix step moved into verify-docs" control
  - `runner_image_errors/2` and `os_family_context_errors/2` with 2 mutation controls each; needles built by concatenation

## Task Commits

1. Task 1 (tracer): `6f7d40ca` ci(toolchain): pin the test matrix strictly and run the min lane on ubuntu-24.04
2. Task 2: `7a7e93ee` test(ci): forbid the deprecated runner image and the OS-family cache key in ci.yml

## Verification

- The Task 1 `<verify>` passed after the commit. It was re-run as the tracer feedback gate (end-of-phase mode, automated-only verify): "Tracer verified end-to-end — expanding".
- The Task 2 `<verify>` passed:
  - four contract files: 56 tests, 0 failures
  - full `mix test`: 9 properties, 2301 tests, 0 failures, 2 excluded
  - `mix verify.format` and `mix verify.credo` clean
  - HEAD touches only the parity test
- `actionlint -shellcheck=` is clean. It did not flag `matrix.version-file`.
- All acceptance criteria pass:
  - verify-test `runner: "ubuntu-24.04"` = 2; min pins 1/1; version-file 1
  - strict = 14, `id: beam` = 14
  - legacy `otp${{ matrix.otp }}` = 0; resolved deps segment = 22
  - "they come from the matrix values" = 0; `@pending_matrix_jobs` = 0
  - lane / name / CI required = 1/1/1
  - `defp runner_image_errors` = 1; concatenated needles present (2 and 1); literal image label in the test = 0
- No ci.yml line contains the deprecated image label or the OS-family runner context.

## TDD / RED evidence

- Task 1: the new tests were run against the unedited ci.yml and failed in 3 places: the matrix classifier, the verify-test step test, and the full-file live contract. The errors named the missing `id: beam`, the wrong input set, 0 beam steps, and 4 key segments without resolved outputs. All pass after the workflow edit.
- Task 2: the guards are test-only and pass live. Their mutation controls prove they can go red. There was no workflow change to drive a RED.

## Deviations from Plan

**1. [Rule 3 - Blocking] Module attribute ordering**
- **Found during:** Task 1
- **Issue:** The new verify-test step test sits in the existing `verify-test matrix construction` describe. That describe comes before the `@resolved_otp` / `@resolved_elixir` attribute definitions, so the compiler warned that the attributes were undefined and the control did not change its input.
- **Fix:** The control spells out the resolved-output expressions inline.
- **Files modified:** test/threadline/ci_workflow_parity_contract_test.exs
- **Commit:** 6f7d40ca

Additional controls beyond the plan's minimum: a third-matrix-row control, a raised mix.exs floor control, and a verify-test step test with its own controls. These include the plan's "same step in another job id is an error" behavior.

**Total deviations:** 1 auto-fixed (blocking). **Impact:** none on scope. No toolchain version changed except as the plan specified. No job id, check name or `.tool-versions` changed.

## Known Stubs

None. The plan 01 fail-closed MATRIX stub is now implemented.

## Next Phase Readiness

Ready for the next plan in phase 216 (widen `runner_image_errors/2` to every workflow). The run-ID proof that the min lane works on ubuntu-24.04 still has to be collected after the maintainer push gate (plan 06).

## Self-Check: PASSED

- FOUND: .github/workflows/ci.yml, test/threadline/ci_workflow_parity_contract_test.exs
- FOUND: 6f7d40ca, 7a7e93ee (git rev-list --count eca9b3f5..HEAD = 2 before this SUMMARY commit)
