---
phase: 223-close-v1-43-audit-debt
plan: 01
subsystem: ci-release-control-plane
tags: [ci, release, security, contract-test]
status: complete
dependency-graph:
  requires: []
  provides:
    - "release.yml: persist-credentials: false on release-please, publish-hex target and smoke-published target checkouts"
    - "release_control_plane_contract_test.exs: @persisted_checkout_jobs, checkout_credential_errors/1, persisted_checkout_errors/1"
  affects:
    - .github/workflows/release.yml
    - test/threadline/release_control_plane_contract_test.exs
tech-stack:
  added: []
  patterns:
    - "per-STEP (not per-job) checkout credential contract, mirroring ci_token_permissions_contract_test.exs's mutate!/stale_errors idiom"
    - "command-position mix_invocation?/1 matcher, narrower than a substring test, to avoid firing on prose"
key-files:
  created: []
  modified:
    - .github/workflows/release.yml
    - test/threadline/release_control_plane_contract_test.exs
decisions:
  - "D-07..D-12 (216 CR-01) closed exactly as scoped: default-deny persist-credentials on release.yml checkouts, per-step contract, mutation controls"
  - "mix_invocation?/1 is a command-position matcher (line start, after ;/&&/||/|/$(, after an unescaped backtick, after a shell keyword, after NAME=value assignments, plus a colon for YAML run: prefixes) rather than a substring test, so it does not misfire on distribution-sync's own PR-body prose (an escaped-backtick \`mix verify.test\`)"
  - "The per-job checkout_count/credential_free counting block in the sync-release-pr-pins test was removed (D-10) — superseded by the per-step rule and its own mutation control, keeping every other assertion in that test unchanged"
metrics:
  duration: "~35min"
  completed: 2026-09-29
actuals:
  tokens: 4410
  tasks: 2
  commits: 2
  plan_head_before: d6a8e9365a45b6229b5c2f6db85bc15e130f3d9e
  plan_head_after: e61bc12eeed18e74d57ad3824bafcb5d9284b6b1
---

# Phase 223 Plan 01: Close release.yml checkout credentials (216 CR-01) Summary

Default-deny `persist-credentials: false` on every release.yml checkout outside a two-entry
reasoned allowlist, backed by a per-step contract test with six mutation/positive controls.

## What was built

**Task 1 (`ci(223-01)`, commit `3f2dd472`):**
- Added `persist-credentials: false` plus a `# 216 CR-01:` comment to three checkouts in
  `.github/workflows/release.yml`: the `release-please` job checkout, the `publish-hex`
  target-ref checkout, and the `smoke-published` target-ref checkout. `release.yml` now has 7
  `persist-credentials: false` lines (4 pre-existing + 3 new) and 3 new `216 CR-01` comments.
  The `dispatch-bootstrap` and `distribution-sync` checkouts were left untouched (confirmed
  byte-identical to `787da941` via `git diff`).
- Added `@persisted_checkout_jobs` (a 2-entry `%{job => reason}` map: `dispatch-bootstrap`,
  `distribution-sync`), `release_job_ids/1`, `checkout_step?/1`, `job_steps/1` and `yaml_value/2`
  (the latter two copied verbatim from `ci_workflow_parity_contract_test.exs`), and
  `checkout_credential_errors/1` — a per-STEP rule (`rule=checkout-credential-free`) that holds
  on the live file. One mutation control proved it can fail (stripping the flag from the
  publish-hex target checkout).

**Task 2 (`test(223-01)`, commit `e61bc12e`):**
- Added `run_scripts/1` (extracts a step's `run:` value, single-line or block-scalar) and
  `mix_invocation?/1` — a command-position matcher for `mix`, narrower than a plain substring
  test, with its own unit test covering every positive/negative string from the CONTEXT
  `<behavior>` block (including the live distribution-sync PR-body prose, which mentions
  `` \`mix verify.test\` `` inside an escaped-backtick string and must NOT fire).
- Added `allowlisted-job-runs-no-mix` and `stale-allowlist-entry` rules, and
  `persisted_checkout_errors/1` combining all three D-09 rules. The live release.yml gives zero
  errors from all three.
- Replaced the single Task-1 mutation control with a data-driven six-case block: five firing
  controls (strip the flag from publish-hex target, from smoke-published target, from the
  sync-release-pr-pins `ref:` checkout; add a mix invocation to distribution-sync; rename an
  allowlisted job) plus one positive control (flagging `dispatch-bootstrap`'s checkout stays
  green).
- Deleted the vacuous per-job `checkout_count`/`credential_free` counting block (and its
  mutation) from "the release PR pin-sync job exists, is scoped, and gates the CI bootstrap",
  per D-10 — the per-step rule and its own control now cover that case (D-11 case 3). Every
  other assertion in that test (`needs`, `mix release.pins`, `--check`, the
  `persist-credentials: false` assert, `concurrency`, `PUSH_TOKEN`, the bootstrap asserts) is
  unchanged.

## Verification

- `mix test test/threadline/release_control_plane_contract_test.exs`: 16 tests, 0 failures.
- `mix compile --warnings-as-errors`: clean.
- `mix credo --strict` on the changed file: no issues (after extracting `block_scalar_lines/3`
  and `block_scalar_member?/2` to satisfy the max-nesting-depth check).
- `awk` counts: 7 `persist-credentials: false` lines, 3 `# 216 CR-01:` comments — matches plan.
- `git show --name-only --format=` on each commit lists exactly the files the plan named.
- `bin/verify-repo-hygiene`: clean (4241 tracked text files, 8 allowlist entries used, 0 inert).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - blocking] `Enum.slice/2` range-step syntax error**
- **Found during:** Task 2, first test run.
- **Issue:** `Enum.slice((index + 1)//1)` is invalid Elixir syntax — the `//` step operator must
  follow a `..` range, not a bare integer.
- **Fix:** Changed to `Enum.slice((index + 1)..-1//1)`.
- **Files modified:** `test/threadline/release_control_plane_contract_test.exs`.
- **Commit:** `e61bc12e` (folded into the task commit; not a separate commit).

**2. [Rule 1 - bug] `run_scripts/1` didn't match a `- run: ...` step whose first line carries
   the list-item dash**
- **Found during:** Task 2, running the "add a mix invocation to distribution-sync" mutation
  control (added as a new first-line step `- run: mix deps.get`).
- **Issue:** `run_scripts/1`'s `run:` line detector anchored on `^\s*run:`, which does not match
  when the dash and `run:` share one line (`      - run: mix deps.get`) — the step's `run:` was
  never found, so `mix_invocation?/1` was never called and the control failed to fire.
- **Fix:** Widened the detector and value-stripping regex to `^\s*(?:- )?run:`, and derived the
  block-scalar indent from the matched key prefix's length (dash included) rather than raw
  leading whitespace.
- **Files modified:** `test/threadline/release_control_plane_contract_test.exs`.
- **Commit:** `e61bc12e` (folded into the task commit).

**3. [Rule 1 - bug] `mix credo --strict` nesting-depth finding on `run_scripts/1`**
- **Found during:** Task 2, pre-commit strengthening check (not a plan-mandated step, but
  routine hygiene before committing a new helper).
- **Issue:** The block-scalar branch nested a `case` → `if` → pipeline → anonymous function four
  levels deep, one over credo's `--strict` max (2).
- **Fix:** Extracted `block_scalar_lines/3` and `block_scalar_member?/2` as named private
  functions, no behavior change (verified: same 16 tests still pass).
- **Files modified:** `test/threadline/release_control_plane_contract_test.exs`.
- **Commit:** `e61bc12e` (folded into the task commit).

No architectural deviations (Rule 4). No auth gates. No package installs.

## Known Stubs

None.

## Threat Flags

None — this plan implements the threat mitigations named in its own `<threat_model>`
(T-223-01..04); it introduces no new unmitigated surface.

## Self-Check: PASSED

- `.github/workflows/release.yml` exists and diffs cleanly against the committed state — FOUND.
- `test/threadline/release_control_plane_contract_test.exs` exists — FOUND.
- Commit `3f2dd472` — FOUND (`git log --oneline --all | grep 3f2dd472`).
- Commit `e61bc12e` — FOUND (`git log --oneline --all | grep e61bc12e`).
- `mix test test/threadline/release_control_plane_contract_test.exs`: 16 tests, 0 failures —
  confirmed on the final tree.
