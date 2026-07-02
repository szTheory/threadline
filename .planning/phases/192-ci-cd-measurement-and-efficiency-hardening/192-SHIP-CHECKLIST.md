---
phase: 192
artifact: ship-gated-checklist
scope: external maintainer actions deferred from 192-04-03 (D-17 + D-19)
status: pending — fires when Phase 192 CI changes reach origin/main
trigger: the deliberate clean push/release that lands ci.yml's verify-test matrix on the public repo
owner: maintainer (szTheory)
created: 2026-07-02
---

# Phase 192 — Ship-Gated Checklist (192-04-03 deferred)

The in-repo work of Phase 192 is complete and verified. Task **192-04-03** (D-17 throwaway
min-lane resolution run + D-19 branch-protection reconfig) is **inherently external** and was
deferred at the operator's decision because:

- `origin` is the **public** repo `szTheory/threadline`; local `main` is ~395 commits ahead and
  every one touches `.planning/`. Pushing `main` would leak private planning history — forbidden
  by the local-only convention ([[milestone-tags-stay-local]]).
- The new matrix checks `Run test suite (min)` / `Run test suite (current)` have **never run on
  GitHub**, so branch protection cannot require them yet (would brick PRs), and D-17's resolution
  check needs a real CI run.

## Trigger

Execute this checklist at the moment the Phase 192 `ci.yml` changes (verify-test min/current
matrix) reach `origin/main` — i.e. the next deliberate clean-branch push / release that ships
these workflow edits publicly. **Do NOT run branch-protection reconfig before that push**, or the
required checks will reference names GitHub has never seen and every PR will block forever.

## Steps (in order)

1. **D-17 — Throwaway min-lane resolution run.** On the PR/branch that carries the new `ci.yml`,
   confirm the `Run test suite (min)` job actually provisions: `erlef/setup-beam@v1` resolves
   **elixir 1.15 / otp 26** on **ubuntu-22.04**. If it fails to resolve, bump the OTP patch or the
   runner image before merge. (Only runtime-only unknown; RESEARCH A1/M5.)

2. **D-19 — Branch-protection reconfiguration.** Once the PR has POSTED both
   `Run test suite (min)` and `Run test suite (current)`:
   - GitHub → repo Settings → Branches → `main` → required status checks.
   - **Remove** the old required check `Run test suite (verify-test)` (it stops posting the moment
     the matrix lands, so PRs would otherwise block forever).
   - **Add** `Run test suite (min)` and `Run test suite (current)`.
   - Use just-in-time / admin-merge so the shipping PR is not self-blocked.
   - `gate-ci-green` keys on workflow-run conclusion, not per-job checks — unaffected.

3. **Confirm** both new checks are green on the PR and are the required set on `main`.

## Verification pointer

The in-repo contract test `test/threadline/phase06_nyquist_ci_contract_test.exs` already asserts
the two new check names match CONTRIBUTING's required-checks list (D-26), so the documentation and
workflow stay locked to these names. This checklist only covers the two actions that cannot be
asserted by any in-repo test.
