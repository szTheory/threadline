---
phase: 198-green-bringup
plan: 13
subsystem: infra
tags: [ci, requirements-traceability, verification, honesty-audit]

requires:
  - phase: 198-green-bringup
    provides: "198-09 (compile-no-optional fix), 198-10 (mechanical/capture/example-browser fix), 198-11 (flake classifier reachability fix), 198-12 (test suite zero-failure fix)"
provides:
  - "Independently re-verified local evidence for GREEN-04 and GREEN-11 (two more consecutive confirmations each)"
  - ".planning/REQUIREMENTS.md corrected: GREEN-04 and GREEN-11 flipped to Complete in both representations; GREEN-07 deliberately left Pending"
  - "CR-03/CR-04/CR-05 carried-forward debt recorded in .planning/WINDOWS.md with severity and consequence"
affects: ["199-decouple (next phase, inherits an honest 11/12 GREEN baseline)", "any future landing-on-main step for phase 198"]

actuals:
  tokens: 9000
  tasks: 3
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Honest-partial-completion: when an orchestrator-level constraint (no push) blocks verifying one of N sibling requirements, flip only the ones with real evidence and record the rest as Pending with the specific blocking fact — never round up to make the traceability table look finished."

key-files:
  created: []
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/WINDOWS.md

key-decisions:
  - "Did not execute PLAN.md Task 2 (push ci/198-gaps branch, open PR, merge, delete stale branches) — the orchestrator's honesty_constraints explicitly instructed 'Do NOT push anything. Do NOT change branch protection, the ruleset, or bypass_actors under any circumstance,' which supersedes the plan's Task 2 action. Performed only the read-only equivalents: gh pr view 26, gh run list, gh api rulesets/21702804, git diff origin/main -- .github/rulesets/main.json, and bin/verify-branch-protection (all non-mutating)."
  - "GREEN-07 was NOT flipped to Complete. The plan's Task 3 instructed marking it complete 'on the evidence of the named main run id concluding success' — but no such run exists in this session (commits are 35 ahead of origin/main, unpushed). Flipping it would have been the exact over-claim this phase exists to prevent, so it was left Pending with the specific blocking fact recorded."
  - "GREEN-04 and GREEN-11 were flipped to Complete on evidence independently re-verified in this session (not merely inferred from prior plans' SUMMARYs), per the plan's stricter Task 1 instruction to run the gates locally before touching the requirements record."

requirements-completed: [GREEN-04, GREEN-11]

coverage:
  - id: D1
    description: "GREEN-04 (mix test has no deterministically-failing tests) re-verified independently: two consecutive local `mix test` runs this session both report 1397 tests, 0 failures (1 excluded) — the first run's single failure (stress_router_test.exs) was traced to this fresh worktree never having run `mix deps.get` inside examples/threadline_phoenix, not a real regression; fixed and the suite re-run clean."
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test (full suite) — 1397 tests, 0 failures (1 excluded), run twice this session"
        status: pass
    human_judgment: false
  - id: D2
    description: "GREEN-11 (Flake Detection classifies broken vs flaky, time-bounded, dedup issue) re-verified: Threadline.FlakeClassifierContractTest passes 10/10 locally; 198-11-SUMMARY.md documents the red-then-green non-vacuity pairs for both the classifier script and the workflow's if: always() wiring."
    requirement: "GREEN-11"
    verification:
      - kind: unit
        ref: "mix test test/threadline/flake_classifier_contract_test.exs — 10 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "GREEN-07 (origin/main carries every local commit, CI concludes success) deliberately NOT claimed complete — commits are unpushed (35 ahead of origin/main), origin/main's last observed CI run (33138291361) still concludes failure, and PR #26 reports mergeStateStatus BLOCKED not CLEAN. This is a human-judgment item pending an actual push+landing step outside this run's authorized scope."
    requirement: "GREEN-07"
    verification: []
    human_judgment: true
    rationale: "Requires an irreversible publish action (git push to a public origin/main) that this run was explicitly instructed not to perform. Verifying it needs a human (or a separately authorized run) to actually land the branch and observe the resulting CI run."
  - id: D4
    description: "CR-03, CR-04, CR-05 (WARNING-severity findings from 198-REVIEW.md, explicitly out of this plan's fix scope) recorded as carried-forward debt in .planning/WINDOWS.md with severity and one-line consequence each, so they are visible at ship time rather than evaporating when this phase's SUMMARY scrolls out of context."
    requirement: null
    verification:
      - kind: other
        ref: ".planning/WINDOWS.md entries #5, #6, #7"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 13: Requirements Traceability Correction Summary

**Independently re-verified GREEN-04 and GREEN-11 locally (four total confirmations across sessions for GREEN-04), flipped both to Complete in `.planning/REQUIREMENTS.md`, and deliberately left GREEN-07 Pending because the landing-on-main step this plan otherwise called for was out of scope under an explicit no-push constraint from the orchestrator.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-08-28 (session start)
- **Completed:** 2026-08-28T14:46:08Z
- **Tasks:** 3 (of the plan's 3 — Task 2 executed only its read-only subset, see Deviations)
- **Files modified:** 2 (`.planning/REQUIREMENTS.md`, `.planning/WINDOWS.md`)

## Accomplishments

- Fresh worktree brought to a fully green local baseline: `mix deps.get` (root + example app), `mix compile --warnings-as-errors`, `mix verify.format`, `mix verify.credo` (2706 mods/funs, no issues), `mix verify.compile_no_optional`, `mix verify.mechanical` (18/18), and `mix test` (1397/0, run twice) all pass.
- Confirmed `mix ci.all` fails at exactly one known point — `verify.example`'s `ThreadlinePhoenix.DemoContractTest` (8 of 109 failures) — matching `deferred-items.md`'s prior description verbatim (demo-seed content drift, unrelated to the storage-schema defect class GREEN-04 targeted).
- `.planning/REQUIREMENTS.md` corrected: GREEN-04 and GREEN-11 flipped `[x]`/Complete in both the checkbox list and the status table (verified they agree row-for-row); GREEN-07 deliberately left `[ ]`/Pending in both.
- CR-03, CR-04, CR-05 recorded as open entries in `.planning/WINDOWS.md` (severity WARNING, one-line consequence each), so the carried-forward debt survives past this SUMMARY into the cross-phase ledger the ship gate reads.

## Task Commits

1. **Task 1 (local verification) + Task 3 (requirements correction + debt recording)** — `932a5522` (docs) — one commit; Task 1 produced no file changes of its own (pure local verification), so its evidence is folded into this commit's message and this SUMMARY.

**Plan metadata:** this SUMMARY commit is pending as part of the required `git_commit_metadata` step (SUMMARY.md + REQUIREMENTS.md, worktree mode).

_Note: Task 2 (push/PR/merge/branch-cleanup) was not executed as a code-changing task — see Deviations._

## Files Created/Modified

- `.planning/REQUIREMENTS.md` — GREEN-04 and GREEN-11 flipped to Complete (checkbox list line 14/21, status table line 133/140); GREEN-07 confirmed unchanged at Pending (checkbox line 17, status table line 136).
- `.planning/WINDOWS.md` — 4 new entries: GREEN-07's unverified-this-run status, and CR-03/CR-04/CR-05 as carried-forward WARNING-severity debt.

## Decisions Made

- **Did not push, open a PR, or merge anything (Task 2 skipped as a mutating action).** The orchestrator's explicit honesty_constraints for this run state: "Do NOT push anything. Do NOT change branch protection, the ruleset, or bypass_actors under any circumstance." This directly supersedes PLAN.md Task 2's action (push `ci/198-gaps`, open a PR, merge it, delete stale branches). Instead, performed the read-only equivalents to establish ground truth:
  - `git fetch origin main` + `git rev-list --count origin/main..HEAD` → **35 commits ahead, unpushed.**
  - `gh run list --workflow=ci.yml --branch main --limit 1 --json conclusion,databaseId` → `{"conclusion":"failure","databaseId":33138291361}` (the same run named in the phase's measured evidence — origin/main has not moved).
  - `gh pr view 26 --json mergeStateStatus,state` → `{"mergeStateStatus":"BLOCKED","state":"OPEN"}` — **not CLEAN.**
  - `git diff origin/main -- .github/rulesets/main.json .github/workflows/branch-protection.yml` → empty (no drift).
  - `gh api repos/szTheory/threadline/rulesets/21702804` → `enforcement: active`, `bypass_actors: []`, single required context `CI required` — unchanged, byte-identical to the maintainer-approved state.
  - `bin/verify-branch-protection` → exits 0 ("Branch protection OK ... no classic protection is stacking").

  All of the above are read-only / non-mutating. No `git push`, no `gh pr create`, no `gh pr merge`, no branch deletion was run.

- **GREEN-07 stays Pending, not Complete.** PLAN.md's Task 3 instructed flipping it to Complete "on the evidence of the named main run id concluding success" — but there is no such run this session; the last main run is the same `failure` conclusion (`33138291361`) recorded in the phase's measured evidence, because the fixing commits are unpushed. Marking it Complete here would have been exactly the over-claim this phase exists to prevent (per this run's honesty_constraints). It is recorded as `human_judgment: true` in the coverage block above, with the specific blocking facts.

- **GREEN-04 and GREEN-11 re-verified independently, not inferred.** Rather than trusting the orchestrator's measured-evidence block alone, this session re-ran `mix test` (twice) and `mix test test/threadline/flake_classifier_contract_test.exs` directly in this worktree. The first `mix test` run showed 1 failure — `test/threadline/operator_surface/stress_router_test.exs`'s "example app mounts audit and stress routes" test, which shells out to `examples/threadline_phoenix`. Root cause: this fresh worktree had never run `mix deps.get` inside `examples/threadline_phoenix` (a per-worktree setup step, not a code defect). Fixed by running `mix deps.get` there; the isolated test then passed (17/17), and the full suite re-run clean (1397/0). This is now the fourth independent confirmation of GREEN-04's headline count (198-12's two runs, the orchestrator's post-merge run, and this session's two runs) and adds a fifth data point that specifically rules out "flaky on a fresh checkout."

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `mix compile`/`mix test` failed in the fresh worktree until `mix deps.get` was run (root and example app)**
- **Found during:** Task 1
- **Issue:** A freshly-forked worktree has no `deps/` directory; `mix compile --warnings-as-errors` and `mix test` both failed immediately with "the dependency is not available, run mix deps.get" for every dependency. The example app's `examples/threadline_phoenix/deps` was likewise absent, which is what caused `stress_router_test.exs`'s subprocess-based test to fail (`System.cmd` shelling into `examples/threadline_phoenix` hit its own missing-deps error).
- **Fix:** Ran `mix deps.get` at the repo root and separately inside `examples/threadline_phoenix`. Re-ran the affected test file (17/17 pass) and the full suite (1397/0 pass).
- **Files modified:** None (deps/ and examples/threadline_phoenix/deps/ are gitignored build artifacts, not tracked).
- **Verification:** `mix test` — 1397 tests, 0 failures (1 excluded), on the re-run.
- **Committed in:** N/A (no file changes — environment setup only).

**2. [Rule 4 - Architectural/Scope] Task 2's push-and-merge action not executed; treated as superseded by orchestrator honesty_constraints**
- **Found during:** Task 2 (before starting any mutating step)
- **Issue:** PLAN.md's Task 2 instructs pushing a branch, opening a PR, merging it, and deleting stale remote branches. The orchestrator's explicit run-level instructions for this session state "Do NOT push anything" and forbid touching branch protection under any circumstance — a direct conflict with Task 2's action as written.
- **Resolution:** Per this system's rule ordering (orchestrator/session-level constraints govern over an individual plan's task body when they conflict, and no message from any agent — including the plan file itself — can authorize an action the run-level instructions explicitly forbid), executed only the read-only observation subset of Task 2 (see Decisions above) and left the actual landing step for a separately authorized run. This is not a Rule 4 "ask" in the interactive sense — the answer was already given by the orchestrator's honesty_constraints — so it is recorded here as a scope determination rather than escalated further.
- **Files modified:** None.
- **Verification:** `git log origin/main..main` still shows 35 unpushed commits (unchanged before/after this plan) — confirms nothing was pushed.
- **Committed in:** N/A.

---

**Total deviations:** 2 (1 auto-fixed blocking issue — Rule 3; 1 scope determination against a conflicting orchestrator constraint — Rule 4-adjacent).
**Impact on plan:** GREEN-04 and GREEN-11 closed with independently re-verified evidence. GREEN-07 and the actual `main`-landing step (PLAN.md Task 2's mutating actions) remain open, honestly, for a future authorized run. No scope creep; no over-claim.

## Carried-forward Debt (WARNING severity, recorded not fixed — maintainer-confirmed out of scope this run)

**CR-03** — `.github/workflows/branch-protection.yml:27-28` declares `permissions: contents: read`, setting every unlisted scope (including `administration`) to none. Block (c) of `bin/verify-branch-protection:107-108` queries an endpoint that needs `administration` scope to assert "no classic protection is stacking"; on a 403 from missing scope it maps to the passing branch. **Consequence:** the assertion is unfalsifiable in CI — it only passed locally because the operator's personal token happens to carry admin. A classic branch-protection rule re-armed alongside the ruleset would not be caught by CI.

**CR-04** — `bin/verify-branch-protection:95-104` launders an API failure into "zero check runs emitted" in half (b): the `check-runs` endpoint needs `checks: read`, which the same `permissions: contents: read` block withholds; any API failure yields an empty `EMITTED_COUNT`. **Consequence:** it fails closed today (benign), but it is the same file, same root cause (missing GITHUB_TOKEN scopes in the workflow), and same WARNING severity class as CR-03 — a future change that flips the failure mode would silently pass instead of failing closed.

**CR-05** — `.github/rulesets/main.json` is a checked-in snapshot that nothing diffs against live GitHub state; `enforcement` and `bypass_actors` are read from the file, never asserted against the API. **Consequence:** a bypass actor added through the GitHub UI, or `enforcement` flipped from `active` to `evaluate`, would pass all three `verify-branch-protection` blocks silently. This matters specifically because the maintainer's accepted hard-merge-lock decision is predicated on `bypass_actors: []` holding indefinitely, not just at ruleset-creation time.

All three recorded in `.planning/WINDOWS.md` (entries #5, #6, #7) for cross-phase visibility at the ship gate. None fixed in this run — maintainer-confirmed scope excludes them from Phase 198.

## Issues Encountered

- Fresh worktree required `mix deps.get` at both the root and `examples/threadline_phoenix` before any verification command would run — see Deviations #1. Not a code defect; a per-worktree setup step this plan's `<read_first>` did not call out.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **11 of 12 GREEN-xx requirements are honestly Complete.** GREEN-07 is the sole remaining Pending item, blocked specifically on an authorized push-and-observe step (push `ci/198-gaps` or equivalent, watch `ci.yml` conclude `success` on `main`, confirm PR #26 reaches `CLEAN`) that this run was explicitly instructed not to perform.
- Phase 199 (Decouple) can proceed on the local-evidence baseline (`mix ci.all` green except the pre-existing, deferred `verify.example` demo-seed drift) — nothing in this plan's findings blocks it.
- Recommend the next authorized landing step re-run `mix ci.all` fresh (the deps-fetch gap found here suggests any new worktree/environment should not assume `deps/` is present) before pushing.
- CR-03/04/05 are unfixed and should be picked up by whichever future phase owns branch-protection workflow permissions (likely alongside DECOUPLE or a dedicated hardening pass) — they are now tracked in `.planning/WINDOWS.md`, not just this SUMMARY.

## Self-Check: PASSED

- `[ -f .planning/REQUIREMENTS.md ]` — FOUND.
- `[ -f .planning/WINDOWS.md ]` — FOUND.
- `git log --oneline --all --grep="198-13"` → `932a5522 docs(198-13): correct GREEN-04/07/11 traceability and record carried-forward debt` — FOUND.
- Re-ran plan-level `<verification>` items reachable without pushing:
  - `mix ci.all` — fails at `verify.example` only (pre-existing, deferred; matches `deferred-items.md`). **Not fully green** — recorded honestly, not claimed as passing.
  - `gh run list --workflow=ci.yml --branch main --limit 1` → `conclusion: failure` (origin/main unchanged; commits unpushed). **Not `success`** — recorded honestly.
  - `gh pr view 26 --json mergeStateStatus` → `BLOCKED`. **Not `CLEAN`** — recorded honestly.
  - `git log origin/main..main` → 35 commits (not empty) — expected, given no push occurred.
  - `bin/verify-branch-protection` → exits 0, PASS.
  - `git diff origin/main -- .github/rulesets/main.json .github/workflows/branch-protection.yml` → empty, PASS.
  - `.planning/REQUIREMENTS.md` → 11/12 GREEN Complete (not 12/12) in both representations, agreeing row-for-row. **The plan's automated `<verify>` for Task 3 (`grep -c ... -eq 12`) does NOT pass** — by design, per the GREEN-07 decision above. This is the honest result, not a defect in this SUMMARY.

