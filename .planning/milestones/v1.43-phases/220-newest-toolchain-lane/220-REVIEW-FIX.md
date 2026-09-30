---
phase: 220-newest-toolchain-lane
fixed_at: 2026-09-28T00:00:00Z
review_path: .planning/phases/220-newest-toolchain-lane/220-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 220: Code Review Fix Report

**Fixed at:** 2026-09-28
**Source review:** .planning/phases/220-newest-toolchain-lane/220-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (WR-01..WR-04 in the first pass; IN-01..IN-03 in a second pass)
- Fixed: 7
- Skipped: 0

**Where verification ran:** in the main checkout, on branch `milestone/v1.43`. No worktree was used, so these results can be reproduced from this tree.

- `mix test test/threadline/ci_workflow_parity_contract_test.exs`: 42 tests, 0 failures, after each fix.
- Every test file that reads CONTRIBUTING.md (18 files, including `ci_topology_contract_test.exs`) ran after WR-04: 255 tests, 0 failures.
- `mix format --check-formatted` passes. `mix compile --warnings-as-errors` is clean.

**Second pass (IN-01..IN-03):** edited and committed in an isolated worktree, with deps shared from the main checkout and a separate `_build`. After the fast-forward onto `milestone/v1.43`, the gates were re-run in the main checkout, so these results can be reproduced from this tree:

- `mix test test/threadline/ci_workflow_parity_contract_test.exs`: 42 tests, 0 failures.
- `mix format --check-formatted` passes. `mix compile --warnings-as-errors` is clean.

**ci.yml:** none of the tightened contracts flagged the real `.github/workflows/ci.yml`, so it was not changed. Every rule was tightened to catch the bypass while leaving the current workflow green.

## Fixed Issues

### WR-01: A voting lane can be made vacuous with a step `if:` or `|| true`, and `voting_lane_errors/1` does not notice

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** a039aff4
**Applied fix:** Added `@every_lane_steps` and `every_lane_step_errors/1`, and wired them into `voting_lane_errors/1`. The verify-test job must contain exactly one each of `Compile (warnings as errors)`, `Verify no compile-connected xref cycles` and `Run tests`. None of them may have an `if:` (`rule=lane-skip`), and each must run exactly its expected command (`rule=lane-command`). A missing or duplicated step reports `rule=lane-step-missing`. New mutation controls in the D-15 test:
- `if: matrix.lane != 'latest'` on `Run tests`
- `if: matrix.lane != 'latest'` on the compile step
- `mix verify.test || true`
- the xref-cycles step removed

**Status:** fixed. Verified automatically: the four mutation controls (an `if:` on `Run tests`, an `if:` on the compile step, `mix verify.test || true`, a removed xref step) each fail the rule, and the real ci.yml passes it (contract file: 42 tests, 0 failures).

### WR-02: `postgres_image_errors/1` misses registry-prefixed, untagged, digest-pinned and expression-suffixed images

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 526ae49c
**Applied fix:** `image:` lines are now parsed whole. The parser strips a trailing comment and surrounding quotes, then removes any registry or namespace path. An image whose last segment starts with `postgres` is checked, and this errs on the side of failing:
- An untagged image (implicit `latest`) or a digest pin is `rule=pg-tag`.
- A tag that has any text around a `${{ … }}` expression is `rule=pg-unresolved`.
- A tag that is exactly `${{ matrix.pg }}` is still resolved through the include rows.

This differs from the review's suggestion in one way. The review proposed scanning only `image:` lines, but that would stop catching a bare `postgres:<tag>` token in a `run: docker run …` or in a `container:` shorthand. So every line that is not an `image:` line is still scanned with the old token regex, which keeps its connection-URL lookbehind. The review's exact regex also could not capture `${{ matrix.pg }}`, because the expression contains spaces and its `[^\s"']*` stops at the first one.

New mutation controls:
- `docker.io/library/postgres:19beta1`
- `postgres:${{ matrix.pg }}rc1`
- bare `postgres`
- `postgres@sha256:…`
- `docker run --rm postgres:19beta1`

New positive controls, each of which must still pass and still be scanned as tag `16`:
- a registry-prefixed `postgres:16`
- a quoted `postgres:16`
- `postgres:16` with a trailing comment

### WR-03: A ci.yml job whose id contains an underscore escapes `needs:` coverage

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 72c02314
**Applied fix:** Added `@job_id_pattern "[A-Za-z_][A-Za-z0-9_-]*"`, which is GitHub's job-id grammar. Both `workflow_jobs/1` and `workflow_job/2` now use it for the header and the lookahead, and both accept trailing spaces after the colon. The helper `ci_job_keys/0` matches only `verify-*` names by design and was left unchanged.

New mutation controls:
- A `verify_extra:` job appended to ci.yml must report `rule=needs-coverage`.
- A `VerifyExtra:` job with `continue-on-error: true` must report `job=VerifyExtra rule=continue-on-error`, which proves the job is no longer folded into ci-required.

I confirmed the controls work by temporarily restoring the old pattern: the underscore control failed with `got []`. The file was then restored.

### WR-04: CONTRIBUTING branch-protection list now names three verify-test contexts, but the ruleset requires exactly one

**Files modified:** `CONTRIBUTING.md`
**Commit:** e8550020
**Applied fix:** The "Branch protection (maintainers)" section now opens by saying that `CI required` is the only required status check (`.github/rulesets/main.json`, enforced by `bin/verify-branch-protection`). It tells maintainers not to add the listed checks as separate required contexts. It then presents the list as jobs that `CI required` aggregates through `needs:`. The duplicate trailing paragraph was removed. The strings `Run test suite (min)`, `(current)` and `(latest)` are kept, so the D-17 and List-2 doc-contract assertions still pass.

### IN-01: The `continue-on-error` and `allowed-failures` regexes miss quoted keys and flow mappings

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 4a866007
**Applied fix:** `voting_lane_errors/1` now uses two module attributes, `@continue_on_error_key` and `@allowed_failures_key`. Each matches the key at the start of a line or after whitespace, `{` or `,`, with optional single or double quotes: `~r/(^|[\s{,])["']?continue-on-error["']?\s*:/m`. Comment lines are still stripped first, so the existing comment positive control still passes. The cache-block `continue-on-error` check further down the file is a separate rule that the review did not cite, so it was left unchanged.

New mutation controls in the D-15 test:
- `"continue-on-error": true` on the verify-test job
- a flow-mapped step `- { name: Extra, run: mix help, continue-on-error: true }`
- `'allowed-failures': verify-test` in ci-required

**Status:** fixed. Checked automatically: the real ci.yml passes (42 tests, 0 failures). With the old regexes put back temporarily, the quoted-key control failed with `got []`. A direct regex check showed the old patterns also miss the flow-mapped and quoted `allowed-failures` inputs, and the new ones match both. The file was then restored.

### IN-02: The D-17 assertion on the job's check name is satisfied only by a YAML comment

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** ee3c9983
**Applied fix:** The review offered two options, and the assertion was made behavioural rather than dropped. A new helper, `composed_check_names/1`, strips comment lines, then reads the job-level `name:` and the `lane: [...]` base axis. It composes the names GitHub posts (`"<name> (<lane>)"`). A `${{ … }}` expression in the name turns off the suffix, so in that case the helper returns nothing. The D-17 test now asserts that `"Run test suite (latest)"` is among those composed names.

Controls:
- Positive: the `"Run test suite (latest)"` comment line removed. It must still pass, because the result no longer depends on prose.
- Mutation: the job name changed to `Run tests`.
- Mutation: `latest` dropped from the lane axis.
- Mutation: a matrix expression added to the job name.

Each mutation must stop composing the name. Checked automatically: the contract file ran 42 tests, 0 failures.

### IN-03: The comment above `verify_test_matrix_errors/3` still describes two rows

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** b376fc7d
**Applied fix:** The comment now also says that the latest row pins an exact release strictly newer than current (`latest_row_errors/2`). This is a comment-only change. Format and compile checks pass.

---

_Fixed: 2026-09-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
