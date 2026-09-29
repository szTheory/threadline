---
phase: 221-ci-names-and-order
fixed_at: 2026-09-29T00:00:00Z
review_path: .planning/phases/221-ci-names-and-order/221-REVIEW.md
iteration: 1
findings_in_scope: 15
fixed: 15
skipped: 0
status: all_fixed
---

# Phase 221: Code Review Fix Report

**Fixed at:** 2026-09-29
**Source review:** .planning/phases/221-ci-names-and-order/221-REVIEW.md, plus the two gaps in 221-VERIFICATION.md
**Iteration:** 1

**Summary:**
- Findings in scope: 15. That is the 13 review findings (WR-01..06, IN-01..07) and the 2 verification gaps (VG-01, VG-02).
- Fixed: 15
- Skipped: 0

Every rule change is proven by a mutation control in the existing `{control, mutate, fragment}` harness. Each control must change its input, must stay valid YAML, and must report its own rule fragment. No fix needs human verification. For WR-03, I also confirmed the new controls are live by removing a branch: with the `gate-pin` branch short-circuited, the tag-pin control went red ("must report rule=gate-pin, got []"). I then restored the file byte-for-byte.

No real workflow uses any key the new rules forbid, so no rule was weakened. None of the following appears in any `.github/workflows/*.yml`:
- `BASH_ENV`
- an expression-valued job `name:`
- a workflow-level `env` or `defaults` in ci.yml
- an extra ci-required job key
- an extra gate step key

## Fixed Issues

### WR-01: A verify-test `matrix.exclude` drops a lane, and no contract notices (name-static, roster, voting lanes)

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** a2174069
**Applied fix:** `composed_check_names/1` now reads the parsed job block instead of two raw lines. The work moved into two new helpers, `posted_lanes/1` and `matrix_row_lanes/2`:
- `exclude` removes a lane before `include` runs.
- An `include` row may only extend a kept lane.
- Any unmodelled shape composes nothing, so `name-static` and `roster` fail closed. That covers a second axis, an exclude row keyed on anything but `lane`, an include row that would add a combination, and an expression matrix.

New controls:
- `exclude: - lane: latest` reports `rule=name-static` and `rule=roster`.
- The same exclude, added to the D-17 matrix-construction test, stops composing `Build and test (latest)`.

The now-unused `yaml_value_at/2` was removed.

### WR-02: A second workflow can post `CI required` through an expression-valued `name:` (gate-name uniqueness bypass)

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 3ca4038b (shared with VG-01)
**Applied fix:** See VG-01. Two changes:
- Any job `name:` that contains `${{`, in any workflow, reports `rule=gate-name-expression`.
- Literal carriers are now compared trimmed, whitespace-collapsed and case-folded.

Controls:
- `name: ${{ 'CI required' }}`
- `name: ${{ matrix.n }}` with `n: [CI required]`
- `name: "ci  required"`

I did not change the ruleset's `integration_id` suggestion. It is a ruleset edit outside this test file, and it is a push-side scope decision for the maintainer.

### WR-03: Gate mutation controls share `rule=gate-step` / `rule=gate-name`, so the SHA-pin and own-name/strategy sub-rules are untested

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 24e5ffb3
**Applied fix:** The sub-rules now have distinct fragments:
- `rule=gate-step-guard` (step `if`/`run`)
- `rule=gate-pin`
- `rule=gate-name-own`
- `rule=gate-name-unique`

`rule=gate-step` is kept for "exactly one step". New controls, each asserting its own fragment:
- `uses: re-actors/alls-green@release/v1` reports `gate-pin`.
- `uses: evil/alls-green@<same 40-hex SHA>` reports `gate-pin`.
- `strategy: {matrix: {x: [1]}}` added to ci-required reports `gate-name-own`.
- ci-required renamed to `CI gate` reports `gate-name-own`.

The existing controls were re-pointed at `gate-step-guard` and `gate-name-unique`.

### WR-04: `evaluator_doc_errors/1` is line-local, so any hard-wrapped hex.pm claim passes

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** fcbe7f4a
**Applied fix:** The rule now scans per block using a new `doc_blocks/1`, which joins lines. A block ends at a blank line or where the next bullet, numbered item, table row or heading starts. The tokens were widened to `~r/hex[ _.-]?evaluator/i` and `~r/hex\.?pm|public hex registry/i`.

Controls:
- the one-line claim
- the review's wrapped bullet
- a reworded wrapped paragraph ("The Hex evaluator installs threadline / from the public Hex registry.")
- a positive control: an evaluator bullet next to a separate hex.pm bullet must stay green

One live paragraph was a false positive. The CONTRIBUTING build-cache table first read as one block and matched, because its `smoke-published` row names hex.pm. Splitting blocks at table rows resolved it.

### WR-05: ci.yml comment says the browser job's name is "byte-identical to its pre-split value", but 221 renamed it

**Files modified:** `.github/workflows/ci.yml`
**Commit:** b8b489bf
**Applied fix:** The sentence now reads: "The branch-protection context is `CI required` alone. This job's `name:` is free to change and is pinned only by the phase 221 name contract (`@ci_check_names`); it votes through `ci-required`'s needs list." No test pinned the old wording, and `ci_coverage_doc_contract_test.exs` stays green.

### WR-06: `Dependency audit (all lockfiles)` is pinned as the truthful name, but the job audits only the three Mix lockfiles

**Files modified:** `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `test/threadline/ci_workflow_parity_contract_test.exs`, `.planning/phases/221-ci-names-and-order/tools/time-to-red.py`
**Commit:** 82e8d9c8
**Applied fix:** The job is renamed to `Dependency audit (Mix lockfiles)`, in one commit covering:
- the ci.yml `name:`
- the CONTRIBUTING roster bullet
- `@ci_check_names`
- `@retired_check_names`, which gains the old name, so `name-retired` catches it coming back

In `time-to-red.py`:
- `NAME_HISTORY` gains the new name, and the old one stays for pre-rename runs.
- `POST_221_NAMES` includes the new name.
- `DEPS_AUDIT_RENAME_ERA_RUN = None` records the second era boundary as pending until the commit lands on main.
- The self-check gains `live_name_errors/1`: every job `name:` in the live ci.yml must be in `NAME_HISTORY` and be a current-era name, so a future rename that skips `NAME_HISTORY` fails `check`.

Job ids and `CI required` are byte-unchanged. No guide or evaluator doc referenced the name. `deps-health.yml`'s `Weekly hex.audit + hex.outdated (all lockfiles)` is another workflow's name, outside 221's rename scope (D-04), so I left it alone. It carries the same overstatement; see Notes.

### IN-01: The `name-verb` rule is a three-word denylist, and two pinned names lead with verbs

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 9b3f870f
**Applied fix:** I took the review's first option: a comment above `name_verb_errors/2`. It records that the rule is a denylist of the pre-221 imperative verbs, and that `Build and test` and `Compile without optional deps` are a deliberate D-02 exception (Build/Compile read as subject nouns), pinned by `name-exact`. I did not rename them. That would be another check rename and a scope call.

### IN-02: `required_gate_errors/1` silently skips sibling workflows that do not parse

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 70758c0d
**Applied fix:** `gate_name_errors/3` now emits `<path> rule=yaml-parse` for any workflow that does not parse. Control: adding `zz-broken.yml` reports `.github/workflows/zz-broken.yml rule=yaml-parse`.

### IN-03: `rule=order-reader` has no mutation control

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 06ec19f5
**Applied fix:** Added a "duplicate job id" control: a second copy of the verify-format block, inserted above ci-required. It asserts `rule=order-reader`.

### IN-04: `parsed_job_order/1` and `parsed_job_keywords/1` duplicate the keyword-mode read

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 448cbd8d
**Applied fix:** `parsed_job_order/1` is now `parsed_job_keywords/1`, then the ids, then `Enum.reverse/1`. The error tuples are unchanged, and the a,b,c ordering fixture and the merge-key control still pass.

### IN-05: `time-to-red.py job_id/1` applies the lane-suffix fallback to every name, not just matrix names

**Files modified:** `.planning/phases/221-ci-names-and-order/tools/time-to-red.py`
**Commit:** 64eb8cf7
**Applied fix:** Added `MATRIX_BASES = ("Run test suite", "Build and test")`, and only those bases get the ` (<lane>)` fallback. Checked:
- `job_id("Formatting (docs)")` returns `?`.
- `Build and test (min)` and `Run test suite (latest)` still map to `verify-test`.
- `check` still matches.

### IN-06: `time-to-red.py` era-boundary metadata: stale comment, and a RENAME_SHA on a deleted branch

**Files modified:** `.planning/phases/221-ci-names-and-order/tools/time-to-red.py`
**Commit:** a6684a3c
**Applied fix:** The comments now name `MAIN_MERGE_SHA` (67572c12, the PR #63 squash on main) as the canonical anchor, set by plan 04 at landing. The stale "set in the first planning sync" wording is gone. `RENAME_SHA` is marked informational only: it is a land-branch SHA that stops resolving after a prune and gc. A new `MILESTONE_RENAME_SHA = 194eee6a…` is the durable milestone-branch copy of the rename commit.

### IN-07: `reorder-ci-jobs.py prove` never checks the resulting order, and assumes `jobs:` is the last top-level key

**Files modified:** `.planning/phases/221-ci-names-and-order/tools/reorder-ci-jobs.py`
**Commit:** 23c86f6a
**Applied fix:**
- `prove` now also requires the after file's job ids, in file order, to equal `TARGET`.
- `split_jobs/1` refuses any line after `jobs:` that starts at column 0 and is not a comment.

Checked against the real move, c72e13a7^ to c72e13a7: exit 0, and it prints "14 ids in TARGET order". Two negative checks:
- proving a file against itself in the old order: exit 1, order differs
- a trailing `env:` after the jobs: exit 1, "top-level content after `jobs:`"

## Verification Gaps (221-VERIFICATION.md)

### VG-01: Naming a second job `CI required` in any workflow turns the parity contract red with rule=gate-name

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** 3ca4038b (shared with WR-02)
**Applied fix:** Every job `name:` in every workflow that contains `${{` fails with `rule=gate-name-expression`. No workflow uses one today, and verify-test's name is already forced static by `rule=name-static`, so no exception is needed.

This also closes the matrix spoof. A `CI required` context through a matrix needs an expression name such as `${{ matrix.n }}`, which is now banned. A static name under a matrix always posts `<name> (<values>)`, which can never equal `CI required`.

Literal carriers are compared trimmed, whitespace-collapsed and case-folded, which can only over-report. Controls: `${{ 'CI required' }}`, `${{ matrix.n }}` with `n: [CI required]`, and `"ci  required"`.

### VG-02: The `CI required` aggregate decides: no ci.yml edit can make the alls-green step exit 0 without running while every contract stays green

**Files modified:** `test/threadline/ci_workflow_parity_contract_test.exs`
**Commit:** e9cce20a
**Applied fix:** `required_gate_errors/1` now pins the gate's whole shape through allowlists over parsed YAML, with keys case-folded through `yaml_key/1`:
- ci-required job keys ⊆ `{name, if, needs, runs-on, timeout-minutes, steps}`, reported as `rule=gate-job-keys`
- the gate step's keys ⊆ `{name, uses, with}`, reported as `rule=gate-step-keys`
- no workflow-level `env` or `defaults` in ci.yml, reported as `rule=gate-workflow-keys`
- no `BASH_ENV` key at any depth of any workflow, reported as `rule=gate-bash-env`

Controls, each asserting its own fragment:
- job `env: BASH_ENV` on ci-required: `gate-job-keys`
- job `container:`: `gate-job-keys`
- step `env:`: `gate-step-keys`
- workflow `env:`: `gate-workflow-keys`
- workflow `defaults:`: `gate-workflow-keys`
- `BASH_ENV` in a second workflow's job env: `gate-bash-env`, and only that fragment

Your brief filed the `BASH_ENV` rule under "VG-01 / WR-02". I recorded it here because the `BASH_ENV` short-circuit is the verification's second gap (truth 6). The rule itself is as specified.

## Verification

All gates ran in the **main checkout** on `milestone/v1.43`, with no worktree (`workflow.use_worktrees` handling was skipped at the orchestrator's direction, because worktrees have no deps/_build). The numbers can be reproduced from this tree.

- Quick command (parity + topology + release_control_plane): green after every commit; 49 parity tests at the end.
- ci.yml-reader sweep (the 13 files in 221-VALIDATION.md): 208 tests, 0 failures.
- `mix format --check-formatted`: clean. `mix verify.credo`: 4417 mods/funs, no issues. `MIX_ENV=test mix compile --warnings-as-errors`: exit 0.
- `python3 .planning/phases/221-ci-names-and-order/tools/time-to-red.py check`: "time-to-red order matches". This now includes the live-name self-check.
- `bin/verify-repo-hygiene`: clean before every commit that touched `.planning`.
- Full `mix test`: 9 properties, 2515 tests, 0 failures, 3 excluded.

## Notes

- WR-06 renames a posted check, so the next CI run on main is the second era boundary. Set `DEPS_AUDIT_RENAME_ERA_RUN` in `time-to-red.py` once it lands.
- `deps-health.yml`'s job name `Weekly hex.audit + hex.outdated (all lockfiles)` makes the same "all lockfiles" overstatement. It is outside 221's rename scope (D-04: other workflows keep their names), so I left it for a scope decision.

---

_Fixed: 2026-09-29_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
