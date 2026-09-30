---
phase: 221-ci-names-and-order
verified: 2026-09-29T15:52:51Z
status: passed
score: 7/7 must-haves verified
covered_files:
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/deps-health.yml
  - .planning/phases/221-ci-names-and-order/221-01-PLAN.md
  - .planning/phases/221-ci-names-and-order/221-01-SUMMARY.md
  - .planning/phases/221-ci-names-and-order/221-02-PLAN.md
  - .planning/phases/221-ci-names-and-order/221-02-SUMMARY.md
  - .planning/phases/221-ci-names-and-order/221-03-PLAN.md
  - .planning/phases/221-ci-names-and-order/221-03-SUMMARY.md
  - .planning/phases/221-ci-names-and-order/221-04-PLAN.md
  - .planning/phases/221-ci-names-and-order/221-04-SUMMARY.md
  - .planning/phases/221-ci-names-and-order/tools/reorder-ci-jobs.py
  - .planning/phases/221-ci-names-and-order/tools/time-to-red.py
  - CONTRIBUTING.md
  - guides/adoption-evidence-playbook.md
  - guides/evaluating-threadline.md
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
covered_digest: "v2:sha256:637e8345536d478a7602f7e37d66ff1d6a40c1d057bd1c8c6b3ab8f4cb4d32f2"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/7
  gaps_closed:
    - "Naming a second job `CI required` in any workflow turns the parity contract red (VG-01: rule=gate-name-expression plus normalized rule=gate-name-unique)"
    - "The CI required aggregate decides: no ci.yml edit can make the alls-green step exit 0 without running while contracts stay green (VG-02: gate-job-keys, gate-step-keys, gate-workflow-keys, gate-bash-env)"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "`CI required` can be posted as a commit status or check run through the API, not only as a job name. The main ruleset requires the context `CI required` with no source (integration) pin. A workflow that grants `statuses: write` and runs `gh api .../statuses/<sha> -f context='CI required' -f state=success` keeps all 19 workflow-contract files green (305/0). So can anyone with repo write access posting the same status from a laptop."
    category: security
    reason: "New scope, not a job-name spoof. The bigger hole is in repository settings, not in ci.yml, so no contract can close it alone. What would resolve it: the maintainer pins the ruleset's required check to the GitHub Actions app (integration_id 15368). Optionally, add a contract that no workflow grants `statuses: write`, `checks: write` or `write-all` (none does today; the repo default token is read)."
    evidence_status: "contract-side reproducible (scratch probe and real-file mutation, 305/0 green); the GitHub-side acceptance is documented platform behavior, not run live"
  - finding: "gate-bash-env's comment says 'no workflow may set BASH_ENV'. Two lane-level spellings evade it: an expression-valued job `env: ${{ fromJSON('{\"BASH_ENV\":...}') }}` on verify-test, and a new verify-test step that writes `BASH_ENV=...` to `$GITHUB_ENV`. Both keep 305/0 green. Neither can reach the CI required job: its job keys and step keys are allowlisted, it has a single `uses` step, and cross-job GITHUB_ENV writes do not persist."
    category: other
    reason: "This is lane integrity (phase 220 D-15 voting-lane scope), not the 221 gate. The same class includes a GITHUB_PATH shim for `mix`. What would resolve it: an allowlist of verify-test's step list, or reword the gate-bash-env comment to say it covers key-spelled BASH_ENV only. Whether GitHub accepts an expression-valued job `env` mapping was not proven live."
    evidence_status: "contract-side reproducible (real-file mutation, 305/0 green)"
---

# Phase 221: CI Names and Order Verification Report

**Phase Goal:** A contributor can tell from a red check's name what failed, without opening logs
**Verified:** 2026-09-29T15:52:51Z (milestone/v1.43 at 9ad9566b)
**Status:** passed
**Re-verification:** Yes, round 2 after gap closure (a2174069..23c86f6a, plus 9ad9566b)

Both round-1 gaps are closed, and every round-1 bypass now turns the contract red with a named rule. A fresh adversarial hunt found no bypass of the 221 gate contract itself. It found two new-scope findings, recorded as advisory: a ruleset-level status spoof, and lane-level BASH_ENV that belongs to phase 220's scope. This code is not on main yet; see Landing notes.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| G | A red check's name says what failed | VERIFIED | Unchanged since round 1 (PR run 36586103573, 16/16 with the D-02 names), plus WR-06: `Dependency audit (Mix lockfiles)` is now accurate. The job audits the root, bench and example Mix lockfiles only. |
| 1 | SC-1: names state what they prove, rewritten in one pass, CONTRIBUTING quotes in the same commit, under a doc-contract | VERIFIED | `check_name_errors/2` is green. WR-06 updated ci.yml, CONTRIBUTING:893, `@ci_check_names` and NAME_HISTORY in one commit (82e8d9c8). WR-01: a matrix `exclude: lane: latest` now reports `rule=name-static` (probe). |
| 2 | SC-2: ordered by measured p50, no `needs:` preflight, readability only | VERIFIED | `time-to-red.py check` prints "time-to-red order matches". The order contract is green. IN-03 added a duplicate-id control and IN-04 rebuilt the reader on `parsed_job_keywords/1`. The round-1 order-move proofs are unaffected. |
| 3 | SC-3: job ids unchanged; `CI required` byte-exact | VERIFIED | The ci.yml diff since 645add51 touches only the deps-audit name and one comment. `ci-required` and the id set are untouched. |
| 4 | SC-4: gate wiring pinned (`if: always()`, `jobs` input, no `allowed-skips`), each with a mutation control | VERIFIED | Every gate rule has at least one control in the test: gate-if, gate-pin, gate-step-guard, gate-inputs, gate-jobs-input, gate-name-own, gate-name-unique, gate-name-expression, gate-job-keys, gate-step-keys, gate-workflow-keys, gate-bash-env. |
| 5 | 221-01: a second job named `CI required` in any workflow turns the contract red | VERIFIED (gap closed) | `${{ 'CI required' }}` and `${{ matrix.n }}` report `rule=gate-name-expression`. Lower-case `ci required` and a reusable callee named `CI required` report `rule=gate-name-unique`. A non-breaking-space name stays green, but it cannot byte-match the required context. |
| 6 | The aggregate decides: the gate step cannot be short-circuited while contracts stay green | VERIFIED (gap closed) | Each spelling below turns red: job `env: BASH_ENV` (gate-job-keys and gate-bash-env), step `env` (gate-step-keys), job `container` (gate-job-keys), workflow `env` (gate-workflow-keys), job `defaults.run` (gate-job-keys), `Env:` case variant (gate-job-keys), step `<<: *anchor` merging an env (gate-step-keys and gate-bash-env), `with: env:` (gate-inputs), and a local composite `uses: ./.github/actions/...` (gate-pin). |

**Score:** 7/7 truths verified (0 present but behavior-unverified)

### Round-2 Adversarial Probe Results

All probes ran against the current tree, through a scratch copy of the parity module (since deleted) or as real-file mutations restored from backup. "Contract" below means `required_gate_errors`, `voting_lane_errors`, `ci_order_errors` and `check_name_errors`, or, for real-file mutations, the full 19-file workflow-contract set.

| Probe | Result | Verdict |
|-------|--------|---------|
| R1: job env BASH_ENV / step env / job container / workflow env | red (gate-job-keys, gate-step-keys, gate-workflow-keys, gate-bash-env) | closed |
| R1: spoof by `${{ 'CI required' }}` / `${{ matrix.n }}` | red (gate-name-expression) | closed |
| `Bash_Env`, `" BASH_ENV "`, anchor+merge, alias-valued env, all in a lane | red (gate-bash-env) | pinned |
| gate `defaults.run`, `Env:` case variant, step merge-key env | red | pinned |
| `with: env:` passing to alls-green | red (gate-inputs) | pinned |
| composite swap: local `./.github/actions/alls-green` | red (gate-pin) | pinned |
| composite swap: other 40-hex SHA of alls-green | gate green; real-file: 2 failures in `CiActionRuntimeContractTest` | pinned elsewhere |
| gate `runs-on: [self-hosted]` | green | fails closed (D-12): `gh api .../actions/runners` total_count 0, so the check stays pending |
| GITHUB_ENV write from another job | not reachable | cross-job env does not persist; the gate job has a single `uses` step |
| lane `env: ${{ fromJSON(...BASH_ENV...) }}` | real-file 305/0 green | advisory (lane scope) |
| lane step `echo BASH_ENV=... >> $GITHUB_ENV` | real-file 305/0 green | advisory (lane scope) |
| workflow with `statuses: write` posting context `CI required` | real-file 305/0 green | advisory (ruleset source pin) |
| matrix on verify-format (posts `Formatting (a)`) | green | info: the name stays readable, and it cannot post `CI required` |
| job-level `concurrency:` on verify-test | green | info: outside D-07's `needs` rule, no effect on correctness |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Contract files | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/release_control_plane_contract_test.exs` | 78 tests, 0 failures | PASS |
| ci.yml-reader sweep (19 files) | `mix test $(grep -rl -E "workflows\|ci\.yml" test --include="*_test.exs")` | 305 tests, 0 failures | PASS |
| Order regenerates | `python3 .../tools/time-to-red.py check` | "time-to-red order matches" | PASS |
| Format and credo | `mix format --check-formatted`; `mix verify.credo` | clean; "found no issues" | PASS |
| Repo hygiene | `bin/verify-repo-hygiene` | 4116 tracked text files clean | PASS |

After each real-file mutation, `git status --porcelain .github` printed nothing, and both scratch test files are deleted.

### Probe Execution

No phase-declared or conventional `probe-*.sh`. Step 7c is not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DX-01 | 221-01..04 | A contributor can tell from a red check's name what failed, without opening logs | SATISFIED | Truths G, 1-6 |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| phase-modified files | none | TBD/FIXME/XXX | none | none |
| ci_workflow_parity_contract_test.exs | gate-bash-env comment | over-claims "no workflow may set BASH_ENV" | Info | See advisory 2 |

### Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---------|----------|--------------|
| 1 | `CI required` postable as a commit status or check run; the ruleset has no source pin | security | New scope. The fix is a maintainer ruleset setting (integration_id 15368), optionally backed by a no-`statuses`/`checks`-write contract |
| 2 | Lane-level BASH_ENV via expression env or `$GITHUB_ENV` | other | Phase 220 lane scope; cannot reach the 221 gate |

### Landing Notes (follow-up PR)

- **Scope of the PR.** Land a2174069..23c86f6a plus 9ad9566b, together with the planning sync. The PR's CI run will post `Dependency audit (Mix lockfiles)` instead of `(all lockfiles)`. That is expected (WR-06). The other 15 names are unchanged.
- **No ruleset change needed.** The ruleset requires only `CI required`, which is byte-identical.
- **Record the second era boundary.** `DEPS_AUDIT_RENAME_ERA_RUN = None` in `tools/time-to-red.py` must be set to the first run that posts the new name, whether the PR run or main's push run. NAME_HISTORY already maps both names to `verify-deps-audit`.
- **deps-health rename is safe.** The job name became `Weekly hex.audit + hex.outdated (Mix lockfiles)`. Nothing in the ruleset keys on it, and the 19-file sweep is green.
- **Maintainer decision.** Advisory 1 is a repository-settings decision (pin the required check's source). It is not a blocker for landing.

### Human Verification Required

None. Every judgment row was resolved by review and probes, per the project's zero-human-verification rule.

### Gaps Summary

No gaps. Both round-1 gaps are closed with allowlist-shaped rules and mutation controls, and all 13 review findings are dispositioned as fixed. Two new-scope findings are recorded as advisory with the resolutions above.

---

_Verified: 2026-09-29T15:52:51Z_
_Verifier: Claude (gsd-verifier)_

## Post-verification edit (orchestrator, 2026-09-29)

96181c76 changed only the `gate-bash-env` comment and its rule-message wording in `ci_workflow_parity_contract_test.exs`, to scope the claim to a literal `BASH_ENV` key (verifier advisory 2). Rule logic is unchanged. Re-run: parity contract 49 tests, 0 failures; credo exit 0. `covered_digest` was recomputed after this edit.
