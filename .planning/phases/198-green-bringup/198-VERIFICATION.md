---
phase: 198-green-bringup
verified: 2026-09-09T15:26:26Z
status: gaps_found
round: 10
score: 2/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirements_verified: 8/12
requirements_failed: [GREEN-04, GREEN-06, GREEN-07, GREEN-12]
security_status: blocked
security_blocking_open: 5
review_findings: {critical: 2, warning: 1, info: 0}
re_verification:
  previous_status: gaps_found
  previous_score: 4/6
  gaps_closed: []
  gaps_remaining:
    - "origin/main ancestry and exact-main CI are not green"
  regressions:
    - "Required tests added after the last green branch run are not portable to a clean GitHub runner"
    - "Browser mount preflight accepts an unrelated cross-origin redirect"
    - "Three merged Phase-198 measurement branches remain locally and remotely with open PRs"
gaps:
  - truth: "The current test lane is green and portable on the clean CI runner"
    status: failed
    reason: "Two required tests rely on state absent from the default GitHub checkout: a developer-global GSD executable and annotated archive tags/full history."
    artifacts:
      - path: "test/threadline/phase198_zero_human_uat_contract_test.exs"
        issue: "Requires gsd-tools from PATH or ~/.codex; CI installs neither."
      - path: "test/threadline/phase198_nyquist_contract_test.exs"
        issue: "Resolves annotated archive tags, but verify-test uses the default shallow actions/checkout configuration."
      - path: ".github/workflows/ci.yml"
        issue: "verify-test does not install a project-owned classifier or fetch archive tag objects."
    missing:
      - "Use a committed project-owned coverage classifier in the required test lane."
      - "Fetch the registered annotated tags/history required by the archive contract."
  - truth: "origin/main carries every local commit and its exact-main CI concludes success within the budget"
    status: failed
    reason: "Live origin/main is 280 commits behind HEAD, and the canonical run for the exact remote-main SHA concludes failure."
    artifacts:
      - path: "bin/observe-main-ci"
        issue: "Correctly reports failure for run 33138291361; the observer cannot make the remote predicate true."
    missing:
      - "A separately authorized landing operation that makes origin/main contain the intended commits."
      - "A successful canonical CI run on that exact main SHA within 20 minutes."
  - truth: "Required checks make PR #26 mergeable and a broken browser mount aborts early"
    status: failed
    reason: "The exact required-context contract is correct, but PR #26 is BLOCKED; the browser preflight also accepts an unrelated cross-origin /users/log_in redirect."
    artifacts:
      - path: "examples/threadline_phoenix/e2e/run-e2e.sh"
        issue: "The */users/log_in* match does not require a local or same-origin redirect."
    missing:
      - "Require a relative local login target or validate an absolute target against BASE_URL."
      - "Satisfy GREEN-07 so the correctly configured required check can become green on main."
  - truth: "Repository hygiene leaves one worktree and no stale local Phase-198 branches"
    status: failed
    reason: "One worktree exists, but ci/198-gap-closure, ci/198-round5, and ci/198-round6 remain as old merged local branches; all three remote refs and PRs #29/#32/#33 also remain open."
    artifacts:
      - path: ".planning/ARCHIVE-REGISTER.md"
        issue: "Documents two older archived refs but does not disposition the three surviving Phase-198 measurement branches."
    missing:
      - "Record a current keep/close/archive recommendation and retire stale local branches without silently discarding unmerged work."
  - truth: "Phase 198 satisfies its plan-authored security gate"
    status: failed
    reason: "198-SECURITY.md is blocked with 5 high-severity blocking threats and 8 total open threats."
    artifacts:
      - path: ".planning/phases/198-green-bringup/198-SECURITY.md"
        issue: "T-198-44-02, T-198-44-05, T-198-45-01, T-198-45-02, and T-198-46-01 remain blocking."
    missing:
      - "Close or explicitly authorize the five blocking security controls; do not infer acceptance for the two new accept dispositions."
deferred:
  - truth: "The required test suite must not depend on a developer-global GSD executable"
    addressed_in: "Phase 199"
    evidence: "Phase 199 goal explicitly requires every test and CI gate to be self-contained in the source tree."
human_verification: []
---

# Phase 198: Green Bringup Verification Report (Authoritative Round 10)

**Phase Goal:** `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red baseline is retired on its merits; branch protection requires exactly emitted checks; and the Phase-201/203 measurements are on disk.
**Verified:** 2026-09-09T15:26:26Z
**Status:** `gaps_found`
**Re-verification:** Yes — the Round-9 report was checked against the current tree, live read-only GitHub state, the current security audit, and the current code review.

The phase goal is not achieved. The strongest disproof is live: `origin/main..HEAD` contains 280 commits and exact-main run `33138291361` concludes `failure`. The current security and review gates add independent blockers that were absent from the previous authoritative section.

## Goal Achievement

### Observable Truths

| # | Roadmap truth | Status | Evidence |
|---|---|---|---|
| 1 | Red-run logs, Credo histogram/concentration, and mechanical-sensitivity measurement are durable without modifying `.credo.exs` or scorecards | ✓ VERIFIED | All four audit artifacts exist and are substantive; Credo JSON contains 377 issues; the reports contain the required tables/findings. No current `.credo.exs` or scorecard diff exists. |
| 2 | `mix test` has no deterministic failures and the form-policy guard is self-declaring | ✗ FAILED | Focused local tests pass only in this developer environment. `phase198_zero_human_uat_contract_test.exs` reaches outside the repository for GSD, while `phase198_nyquist_contract_test.exs` requires tags unavailable in CI's default shallow checkout. Both are in `mix verify.test`, so the current required lane is not portable. |
| 3 | `origin/main` contains all local commits and exact-main CI succeeds within 20 minutes, with bounded jobs/fail-fast | ✗ FAILED | Live remote main remains `a97f527e...`; HEAD is 280 commits ahead. Exact-SHA observer selects run `33138291361`, which completed in about 6m07s but concluded `failure`; `CI required` is also `failure`. All workflow jobs do have timeout bounds. |
| 4 | Branch protection requires exactly emitted checks so PR #26 is mergeable | ✗ FAILED | Ruleset `21702804` correctly requires only byte-exact `CI required`, with no bypass actors, and `bin/verify-branch-protection` passes. Nevertheless PR #26 is OPEN/BLOCKED, so the complete roadmap outcome is false. |
| 5 | Paid critic scoring is workflow-untriggerable and exactly one gated Hex publisher exists | ✓ VERIFIED | No workflow invokes the paid critic path; only `.github/workflows/release.yml` invokes `mix hex.publish --yes`, behind its release gates. |
| 6 | Flake handling is bounded/deduplicated and repository branch/worktree hygiene is complete | ✗ FAILED | Flake/issue-upsert/fail-fast contracts pass and there is one worktree, but three old merged Phase-198 local branches remain. Their remote refs and PRs #29/#32/#33 also remain open; they are not in the archive register. |

**Score:** 2/6 roadmap truths verified.

### Required Artifacts and Key Links

| Artifact/link | Status | Details |
|---|---|---|
| Measurement artifacts → Phase 201/203 sizing | ✓ VERIFIED | Real JSON/Markdown data exists; reports contain explicit sizing sections. |
| `.github/workflows/ci.yml` → `CI required` → ruleset | ✓ VERIFIED | `ci-required` still needs the real job roster; live protection requires exactly `CI required`, emitted once on remote main. |
| Required test lane → zero-human UAT classifier | ✗ NOT WIRED PORTABLY | Test calls a global Codex/GSD installation not installed by CI. |
| Required test lane → archive tag contract | ✗ NOT WIRED PORTABLY | Contract needs annotated tags; checkout has no `fetch-depth: 0` or explicit tag fetch. |
| Browser preflight → local authentication mount | ⚠️ PARTIAL | Preflight is invoked, but its substring check accepts a cross-origin redirect. |
| Exact remote SHA → main workflow run → aggregate conclusion | ✓ FLOWING | `bin/observe-main-ci` selects exact SHA `a97f527e...`, run `33138291361`, 14 jobs, one aggregate, result `failure`. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Current focused Phase-198 contracts | `mix test` over observer/UAT/policy/Nyquist files | 12 tests, 0 failures locally | ✓ PASS locally; does not refute clean-runner defects |
| Flake/upsert/fail-fast/topology/release/form contracts | focused `mix test` invocation | 32 tests, 0 failures | ✓ PASS |
| Canonical UAT classification | classify all 47 summaries | 47 summaries; 192/192 automated; 0 present; 0 errors | ✓ PASS evaluator only |
| Exact-main observation | `bash bin/observe-main-ci --sha a97f527e... --format json` | state/conclusion/aggregate all `failure` | ✗ FAIL requirement |
| Protection parity | `bash bin/verify-branch-protection` | exactly `[CI required]`, emitted once, no stacked classic protection | ✓ PASS |
| Evidence-policy evaluator | `bash bin/verify-phase198-evidence ...` | exit 0; also honestly reports prediction target miss and non-exact composition | ✓ PASS with security limitations below |

### Probe Execution

No conventional `scripts/**/tests/probe-*.sh` probes exist. Phase-declared executable checks were covered by the focused contracts and `bin/verify-phase198-evidence`; SUMMARY pass narration was not used as probe evidence.

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| GREEN-01 | ✓ VERIFIED | Preserved 1.2 MB failed-run log is present and readable. |
| GREEN-02 | ✓ VERIFIED | Credo JSON/histogram/concentration artifacts exist; 377 findings reconcile at the top level. |
| GREEN-03 | ✓ VERIFIED | Mechanical report contains executed finding and Phase-201 sizing implication. |
| GREEN-04 | ✗ FAILED | The latest required test additions have no hosted-run proof and contain two deterministic clean-runner dependencies identified by CR-01/CR-02. |
| GREEN-05 | ✓ VERIFIED | Derived form-policy contract is present; focused contract passes. |
| GREEN-06 | ✗ FAILED | Timeout/failure-cap contracts pass, but a cross-origin login redirect can bypass the operator-mount preflight and defer failure into browser timeouts. |
| GREEN-07 | ✗ FAILED / Pending | 280 local-only commits; exact-main aggregate is `failure`. The 198-39 option-a disposition records acceptance of non-achievement, not success. |
| GREEN-08 | ✓ VERIFIED narrowly | Live ruleset and emitted context match exactly. This does not make roadmap SC4 true while PR #26 is blocked. |
| GREEN-09 | ✓ VERIFIED | Paid critic billing path is absent from workflows. |
| GREEN-10 | ✓ VERIFIED | Exactly one workflow publisher exists and the release control-plane contract passes. |
| GREEN-11 | ✓ VERIFIED | Flake classifier and deduplicating issue-upsert contracts pass. |
| GREEN-12 | ✗ FAILED | One worktree, but three old merged local Phase-198 branches and their open remote PRs remain. |

**Requirement score:** 8/12 independently verified. `REQUIREMENTS.md` still records 11/12 Complete, but those checkboxes predate the current review findings and are not verification evidence.

### Security Gate

`198-SECURITY.md` is authoritative for the phase threat register: `status: blocked`, 231/239 closed, 8 open, 5 blocking. The blocking rows are T-198-44-02 (strict evaluator schema/evidence joins), T-198-44-05 (declared read-only command allowlist), T-198-45-01 (trace/focus/geometry evidence), T-198-45-02 (missing red-control proof), and T-198-46-01 (exact 15-entry/unchanged-entry guard). Three lower-severity rows also remain open. The two new `accept` dispositions have no explicit maintainer acceptance and are not treated as approved.

These gaps primarily undermine the trustworthiness and safety completeness of the new Round-8 automation layer. A 192/192 classifier result therefore proves that the current classifier accepted every declared row; it does not prove the classifier's schema, negative controls, and exact-row coverage meet the plan-authored threat model.

### Validation Gate

`198-VALIDATION.md` is `status: validated` but explicitly `nyquist_compliant: false`. Its post-Plan-47 audit independently leaves GREEN-07 escalated because remote ancestry and exact-main CI are false. This agrees with the live re-check above; validation coverage is not goal completion.

### Code Review and Test Quality

| Finding | Severity | Verification disposition |
|---|---|---|
| Global GSD classifier dependency in required ExUnit suite | Critical | Confirmed directly in code and absent from `verify-test` setup. BLOCKER. |
| Archive-tag contract under shallow checkout | Critical | Confirmed directly in code/workflow. BLOCKER. |
| Cross-origin redirect accepted by browser preflight | Warning | Confirmed by `*/users/log_in*` case pattern. Weakens GREEN-06 fail-fast claim. |

The requirement-linked focused tests contain no disabled test declarations. Their assertions are value/behavioral level, but local success is environment-assisted: this workstation has the global GSD runtime and full tag history that the clean runner lacks. That is a fixture/environment reliance defect, not proof of portability.

### Anti-Patterns

No unreferenced `TBD`, `FIXME`, or `XXX` blockers were found in the current Phase-198 observer/evaluator/test/workflow files inspected. The material anti-pattern is hidden ambient state: tests pass because this checkout has developer-global tooling and full git metadata.

### Decision Coverage

All 42 trackable `198-CONTEXT.md` decisions are reported honored by the non-blocking decision-coverage checker. This does not override failed outcome evidence or the security/review gates.

### Human Verification

N/A — CI/tooling/foundation phase. The failures are observable programmatically; no visual or manual-UAT item is needed. Any remote mutation or risk acceptance requires a new explicit maintainer decision, but that is remediation authorization, not a verification test.

### Gaps Summary

Five grouped blockers remain: clean-runner test portability, live origin/main plus exact-main CI, the blocked PR/browser-preflight outcome, stale Phase-198 branches, and the blocked security register. Phase 199 explicitly owns source-tree self-containment, so the global-GSD dependency is also listed as deferred there; it remains a present defect and does not improve this phase's verdict.

**Overall verdict: `gaps_found`.** Phase 198 must not be represented as goal-achieved or passed. No remote state was mutated during this verification.

## Archived — Round 6 and earlier (preserved intact)

# Phase 198: Green Bringup Verification Report (Round 6)

**Phase Goal:** `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.
**Verified:** 2026-08-31
**Status:** gaps_found
**Re-verification:** Yes — this is the sixth verification round for Phase 198, following gap-closure round 6 (plans 198-38, 198-39, 198-40). This report supersedes round 5's `198-VERIFICATION.md` and is written against round 6's own final diff and CI evidence, not inherited from round 5.

## What changed since round 5

Round 5 left exactly two named gaps: (1) GREEN-07/roadmap SC3 structurally unmet under D-39 with **no terminal disposition**, and (2) a genuine unresolved Critical, **CR-01**, from round 5's own code review, with **no closure plan, no maintainer decision, and no `deferred-items.md` entry**. Round 6 (plans 198-38, 198-39, 198-40) targeted exactly these two gaps and nothing else.

**Gap 1 (CR-01) — closed, independently confirmed fixed at cause.** Plan 198-38 rewrote `Reset.with_demo_lock/1` to wrap the entire guarded region — `SET lock_timeout`, the `pg_try_advisory_lock` retry loop, the caller's `fun.()` (including any nested acquire reached through `Demo.Seed.run/0`), and the `pg_advisory_unlock` release — inside a single `Repo.checkout/2` call. This verifier independently traced the actual mechanism through Ecto/DBConnection's own source rather than accepting the plan's or the fresh code review's narrative: `Ecto.Adapters.SQL.checkout/3` pins the checked-out connection in the *process dictionary*, and a nested `Repo.checkout/2` call from the same process resolves against that same entry rather than performing a second pool checkout — so a nested acquire from inside `fun.()` is now provably guaranteed to land on the same backend as the outer acquire, not merely likely to. `Demo.Seed` no longer maintains a second, independently-drifting copy of the guard (`defp with_demo_lock` count in `seed.ex` is `0`; it delegates to `Reset.with_demo_lock/1`), eliminating the exact two-copies drift mechanism CR-01 exploited. A genuine behavioral regression test (`advisory_lock_pinning_test.exs`) was added that deliberately avoids the Sandbox pinning that hid the bug from every prior test, using `Sandbox.mode(Repo, :auto)` to exercise a real pooled-connection code path; it asserts `Repo.checked_out?()` true at both the outer and nested points, backend-PID identity across an intervening `Repo.transaction/1`, and that release actually reaches the holding backend (a fresh acquire succeeds after the guard returns). No `TBD`/`FIXME`/`XXX`/`TODO` markers in any round-6-touched file.

**Gap 2 (GREEN-07 terminal disposition) — closed, independently confirmed propagated.** Plan 198-39 presented the maintainer with three options at a blocking `checkpoint:decision`; the maintainer selected **option-a** verbatim: GREEN-07 and roadmap success criterion 3 are **accepted as permanently Pending for milestone v1.41**. This is not a pass — `REQUIREMENTS.md`'s GREEN-07 checkbox is independently confirmed still `[ ]`/Pending, and `ROADMAP.md`'s success criterion 3 explicitly states "This criterion is NOT restated as met." The disposition, its two named unblock conditions (per-lane), and the branch/PR consequences it owns are recorded in `198-39-DECISION.md` and propagated via append-only edits (independently confirmed: `git diff` shows zero removed/rewritten lines in `REQUIREMENTS.md`) into `REQUIREMENTS.md`, `ROADMAP.md`, `deferred-items.md`, and `STATE.md`.

**Plan 198-40 then re-measured CI** (run `33344382035`, independently re-confirmed via `gh run view`) to prove GREEN-04 held on a fresh head SHA after 198-38 touched its covered example-app source (it did: `Run test suite (current)` = `success`, `111` example tests up from `109` — the 2 new regression tests), and to confirm GREEN-07's `CI required` conclusion is unchanged (`failure`, same 2 red `needs:` members, same D-39-forced cause) — a measurement, not a re-litigation, of the standing 198-39 disposition.

**One residual, non-blocking item this round did not formally triage:** a fresh code review run against round 6's own final diff (`198-REVIEW.md`, superseding the pre-fix review now preserved at `198-REVIEW-round5.md`) confirms CR-01 fixed and finds 0 Critical, but surfaces one new Warning (a `Sandbox.mode/2` mid-suite-switch comment that understates the actual invariant it relies on) and one new Info (a docstring-completeness note). Neither is a code-behavior defect, neither is cited in any triage ledger or `deferred-items.md` entry as of this verification, and neither blocks the phase goal — noted below rather than silently dropped.

**Phase goal: still NOT achieved**, and this round's own records say so accurately. `CI required` still concludes `failure`; `origin/main` remains behind the measured head. **What changed is that the phase's own gap-tracking machinery is now honest and complete about it**: the outstanding literal-truth gap (GREEN-07/SC3) now carries a terminal, explicit, maintainer-selected disposition instead of drifting forward unaddressed, and the round's own new defect (CR-01) was fixed at cause with a real regression test rather than left open. **Process integrity: PASS**, independently re-derived on all applicable vectors for round 6, with one minor non-blocking review-triage gap noted (WR-01/IN-02, round-6 numbering).

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Measurement sweep on disk; `.credo.exs` unmodified; no scorecard touched (GREEN-01/02/03) | ✓ VERIFIED | Unchanged since round 1; round 6 touched no `.credo.exs` or `.planning/scorecards/` file (confirmed by the D-42 diff below) |
| 2 | `mix test` passes with no deterministically-failing tests, fixed on merits not skipped (GREEN-04, GREEN-05) | ✓ VERIFIED | GREEN-04 re-proved (not inherited): `gh run view 33344382035 --json jobs` independently shows `Run test suite (current)` = `success` on a fresh head SHA after 198-38 changed its covered code — `111` example-app tests (up from round 5's `109`, the 2 new regression tests), `1434` root tests, `128` doc-contract tests, all `0` failures. GREEN-05 unchanged since round 1 |
| 3 | `origin/main` carries every local commit and its latest CI run concludes `success` in ≤20 min (GREEN-06, GREEN-07) | ✗ FAILED (terminal disposition recorded) | GREEN-06 met (unchanged). GREEN-07's time clause met (10m36s ≤ 20m, independently timed via `gh run view`'s `createdAt`/`updatedAt`). Success clause NOT met: `CI required` = `failure`, independently re-confirmed on run `33344382035`. **This criterion now carries a terminal, maintainer-selected disposition (option-a, `198-39-DECISION.md`): accepted as permanently Pending for v1.41, not restated as met.** `origin/main` remains behind the measured head (202 commits per 198-39's live measurement; the gap is downstream of the disposition, not independently actionable) |
| 4 | Branch protection requires exactly the emitted check names, so PR #26 is mergeable (GREEN-08) | ⚠️ PARTIAL | First clause met: `ci-required`'s `needs:` list in `.github/workflows/ci.yml` unchanged this round (D-42 diff below), still names exactly the emitted checks including `verify-capture`/`verify-example-browser`. Second clause remains false, now explicitly cited to GREEN-07's disposition rather than left as an unexplained consequence: `REQUIREMENTS.md`'s GREEN-08 note cites `198-39-DECISION.md` |
| 5 | Paid critic scoring untriggerable; exactly one gated Hex publish path (GREEN-09, GREEN-10) | ✓ VERIFIED | Unchanged since round 1; round 6 touched no `.github/workflows/` file (D-42 diff below covers this) |
| 6 | Flake Detection classifies broken vs flaky, dedup issue; one worktree, no stale branches, archive tags recorded (GREEN-11, GREEN-12) | ✓ VERIFIED | Unchanged since round 1. `git worktree list` → exactly one entry, independently re-confirmed. Local branches now include `ci/198-gap-closure`, `ci/198-round5`, `ci/198-round6` — active phase-198 gap-closure/measurement working branches (same reasoning round 5 applied to the first two; `ci/198-round6` is the same class of artifact, not a new stale-branch defect). GREEN-12's "landed or archived, never silently discarded" clause applies at milestone closeout, which has not yet occurred |

**Score:** 10/12 requirements Complete (GREEN-07 is not Complete — it carries a terminal accepted-Pending disposition, which is a closed gap, not a pass); 4/6 roadmap success criteria fully verified, 1 partial, 1 with a terminal not-met disposition.

### Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| GREEN-01 | ✓ Complete | Unchanged; carried forward per `198-40-SUMMARY.md`'s explicit carried-requirement statement, independently spot-checked (no round-6 plan touched its satisfying files) |
| GREEN-02 | ✓ Complete | Unchanged, same basis |
| GREEN-03 | ✓ Complete | Unchanged, same basis |
| GREEN-04 | ✓ Complete (re-proved, not inherited) | `gh run view 33344382035` → `Run test suite (current)` = `success`, independently re-derived, matching `198-CI-MEASUREMENT.md` Round 6 section exactly; `REQUIREMENTS.md` line 15 appended (not rewritten) citing this run |
| GREEN-05 | ✓ Complete | Unchanged |
| GREEN-06 | ✓ Complete | Unchanged; `198-39-DECISION.md` explicitly separates this clause from GREEN-07's disposition |
| GREEN-07 | ✗ Pending (terminal, accepted disposition) | `gh run view 33344382035` → `CI required` = `failure`, independently re-confirmed; `verify-example-browser` and `verify-capture` red, both D-39-forced, unchanged from round 5. `REQUIREMENTS.md` checkbox correctly still `[ ]`. **New this round:** `198-39-DECISION.md`'s option-a terminal disposition is cited (lines 18-19), giving the gap a recorded closure rather than leaving it open-ended |
| GREEN-08 | ✓ Complete | Branch-protection config clause verified unchanged; the "so PR #26 is mergeable" outcome clause remains unmet, now explicitly cited to `198-39-DECISION.md` (line 22) rather than left as an unexplained consequence |
| GREEN-09 | ✓ Complete | Unchanged |
| GREEN-10 | ✓ Complete | Unchanged |
| GREEN-11 | ✓ Complete | Unchanged |
| GREEN-12 | ✓ Complete | Unchanged, see truth #6 note above (three local working branches, not final-state stale branches) |

No orphaned requirements: `REQUIREMENTS.md`'s Phase-198 mapping table lists exactly GREEN-01 through GREEN-12, matching the phase's declared requirement set (independently re-confirmed via `grep`).

### Integrity Audit — Round-6-Specific Vectors, Independently Re-Derived

| # | Vector | Method | Result | Verdict |
|---|--------|--------|--------|---------|
| 1 | CR-01's fix is real, not cosmetic | Direct read of `reset.ex`/`seed.ex`; traced `Ecto.Adapters.SQL.checkout/3`'s process-dictionary pinning mechanism independently rather than trusting the plan's or review's claim; ran the regression test file's assertions by inspection (structural `Repo.checked_out?()` gate + backend-PID identity across an intervening transaction + post-release re-acquire) | `Repo.checkout/2` genuinely wraps the entire guarded region; `defp with_demo_lock` count in `seed.ex` is `0` (delegates, no second copy); the test exercises a real pooled-connection path (`Sandbox.mode :auto`, not `unboxed_run/2`), not a tautology | ✓ CLEAN |
| 2 | GREEN-07's disposition is genuinely terminal and genuinely maintainer-selected, not self-authorized by an agent | Read `198-39-DECISION.md` in full: three options presented with consequences, maintainer's verbatim selection ("option-a") quoted, no target milestone supplied (ruling out option-b-wearing-a-different-label) | Disposition is explicit, recorded, and distinguishable from a silent carry-forward; `deferred-items.md`'s "Round 6 — GREEN-07 milestone disposition" entry names the owner and unblock conditions per lane | ✓ CLEAN |
| 3 | A gate narrowed or evidence regenerated to manufacture progress (D-39/D-42) | `git diff --stat 1bda5d1c..HEAD -- .github/ CONTRIBUTING.md examples/threadline_phoenix/e2e/playwright.config.ts .planning/scorecards/ '*.png'` — independently re-run by this verifier over the full round-6 range | Empty, exit 0 | ✓ CLEAN |
| 4 | `ci-required`'s `needs:` list narrowed to drop a red lane | `grep -n -A20 '"CI required"' .github/workflows/ci.yml` | `verify-capture` and `verify-example-browser` both still present in the `needs:` list | ✓ CLEAN |
| 5 | The round-6 pre-push prediction retro-edited after the run | Extracted the "Round 6 — Prediction stated before the push" section's exact text from commit `23c16267` and from HEAD; diffed byte-for-byte | Identical — zero characters changed; the "Round 6 — Measured CI run" section is appended after it in a later commit (`5127f93e`), never editing the prediction | ✓ CLEAN |
| 6 | The measured run's figures match the phase's own records, not just the phase's own narrative | `gh run view 33344382035 --json attempt,conclusion,createdAt,updatedAt,headSha,jobs`, independently queried fresh | `attempt:1`, `conclusion:failure`, `headSha:23c16267d11a63858aad23eab63c9fbfc385ef4b` (exact match), `Run test suite (current)`=`success`, `Tier A capture lane`=`failure`, `Example app browser E2E (Playwright)`=`failure`, `CI required`=`failure` — all matching `198-CI-MEASUREMENT.md`'s Round 6 section and `REQUIREMENTS.md`'s citations exactly | ✓ CLEAN |

**Verdict: PASS on all six re-derived vectors.** One non-blocking observation, not a laundering vector: the fresh round-6 code review (`198-REVIEW.md`) surfaced one new Warning and one new Info with no dedicated triage-ledger row — see "Untriaged, Non-Blocking Findings" below.

### Untriaged, Non-Blocking Findings

`198-REVIEW.md` (round-6 numbering, reviewed against diff `1bda5d1c..HEAD`, plan 198-38 the only source-touching plan): **0 Critical, 1 Warning, 1 Info.**

- **WR-01 (round-6 numbering):** `advisory_lock_pinning_test.exs`'s `setup`/`on_exit` switches `Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)` mid-suite. This is safe in practice only because ExUnit runs `async: false` modules strictly after every `async: true` module finishes (confirmed by the review's own tracing of `Sandbox.mode/2`'s documented risk), but the test file's own moduledoc comment describes the safety argument as "inheriting a mode setting" rather than naming the actual invariant (concurrent connections being force-checked-in). Doc/comment-quality only; no observed or reproducible test failure. Not cited in any triage ledger or `deferred-items.md` row as of this verification.
- **IN-02 (round-6 numbering, distinct from round-5's IN-02):** `Repo.checkout/2`'s `timeout: :infinity` removes the pool's checkout-queue backstop for the *entire* guarded region (lock retry loop plus the whole seed pipeline body), not only the lock-acquisition wait; the docstring's framing is accurate for the lock-acquisition phase but incomplete for the pipeline-body phase. Documentation-completeness only.

**Neither finding is a blocker or a phase-goal gap** — no code behavior is wrong, no test fails, and both are comment/docstring completeness notes on new round-6 code. They are recorded here, rather than silently absorbed, because Step 7's debt-marker/finding-tracking discipline requires every reviewer finding to be accounted for, and neither has a citation anywhere else in the phase's record as of this verification. This does not change the overall verdict (`gaps_found` is already driven by GREEN-07/SC3) and is not itself elevated to a human-verification item, since both are advisory-tier comment-quality notes with no behavioral stake — a future round-7 (or successor-phase) plan touching either file should fold in a one-line comment fix.

### Anti-Patterns Found

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in any of the four files round 6 touched (`reset.ex`, `seed.ex`, `advisory_lock_pinning_test.exs`, `walkthrough_evidence_test.exs`) — independently grepped. No stub patterns, no empty handlers, no hardcoded-empty return values in the CR-01 fix — the `Repo.checkout/2` region is a real, substantive implementation with a real behavioral regression test, not a cosmetic rename.

### Human Verification Required

None. Both items round 5 routed to human verification are now closed with recorded, terminal dispositions: CR-01 is fixed at cause with a genuine regression test (independently re-derived, not merely claimed), and GREEN-07's D-39-forced red lanes have a maintainer-selected terminal disposition (option-a) rather than an open decision. No new item this round rises to the bar requiring a human decision — the two untriaged findings above (WR-01, IN-02) are advisory-tier comment-quality notes, not risk-acceptance judgment calls.

### Gaps Summary

One gap remains, and it is now correctly recorded as a **closed-terminal** gap rather than an open one:

1. **GREEN-07 / roadmap SC3 remains literally unmet** — `CI required` concludes `failure`, `origin/main` does not carry every local commit. This is not fixable within milestone v1.41: both red lanes are red by construction under standing decision D-39, and the maintainer has explicitly and terminally accepted this outcome (option-a, `198-39-DECISION.md`) rather than leaving it open. It is reported here as `status: failed` in the frontmatter `gaps` block — matching what the codebase literally shows — while the frontmatter `deferred` block records that a terminal, non-blank disposition already exists for it, so a future reader does not mistake this for an unaddressed gap requiring new work.

No other gap exists. Round 6 closed both items round 5 left open, with independent re-derivation (not narrative trust) on every vector checked: CR-01's fix is real and behaviorally tested, GREEN-07's disposition is real, terminal, and correctly not conflated with a pass, and no laundering was found on any of the six D-39/D-42/prediction-integrity vectors this verifier independently re-ran for round 6.

**Overall verdict: `gaps_found`.** This is the correct, expected verdict for a phase whose one remaining literal gap has been permanently and explicitly accepted-unmet by the maintainer rather than closed — accepting a gap is not the same as closing it, and this report does not launder the distinction. Phase 198 should not be marked `passed` on this basis; whoever proceeds past this phase should do so with GREEN-07/roadmap-SC3's accepted-Pending status explicit, exactly as `198-39-DECISION.md`, `ROADMAP.md`, and `REQUIREMENTS.md` already state it.

---

## ARCHIVED — Round 5 and earlier

_Preserved verbatim from the prior `198-VERIFICATION.md` for continuity. Not re-verified in this pass except where explicitly cross-referenced above (CR-01 and GREEN-07's disposition, both closed this round)._

status: gaps_found
round: 5
supersedes: "Round 4 section of this same file (verified 2026-08-29, gaps_found, 3/6 SC / 10/12 requirements, integrity PASS). Round-4 (and earlier rounds') content is PRESERVED VERBATIM below under 'ARCHIVED — Round 4 and earlier' and is reconciled, not discarded. This Round 5 section is authoritative."

**Round 5 closed GREEN-04 for real** — independently re-derived from GitHub: `gh run view 33336651956` confirmed `Run test suite (current)` concluded `success`. **GREEN-07 remained Pending** — `CI required` concluded `failure`, with `verify-example-browser` and `verify-capture` red by construction under D-39. **Integrity: PASS on six named laundering vectors.** **One new, material finding round 5 did not close:** the round-5 code review found a genuine, unresolved Critical (CR-01) — nested demo-seed advisory-lock acquisition without connection pinning — in the exact code path round 5's own headline fix (WR-01/WR-02) shipped, with no round-6 plan, no maintainer decision, and no `deferred-items.md` entry as of the round-5 verification.

Both of round 5's named gaps (CR-01 unresolved; GREEN-07 with no terminal disposition) are addressed in this file's authoritative Round 6 section above — CR-01 fixed at cause by plan 198-38, GREEN-07 given a terminal maintainer-selected disposition by plan 198-39.

_(Full round-5 tables — Roadmap Success Criteria, Requirements Coverage, Integrity Audit, New Unresolved Finding, Anti-Patterns, Human Verification, Gaps Summary — are preserved in this file's git history: `git log -p -- .planning/phases/198-green-bringup/198-VERIFICATION.md`. They are not re-transcribed here to keep this document navigable; the Round 6 section above supersedes them and explicitly cross-references what changed.)_

---

## ARCHIVED — Round 4 and earlier

_Preserved verbatim from the prior `198-VERIFICATION.md` for continuity. Not re-verified in this pass except where explicitly cross-referenced above._

status: gaps_found
round: 4
supersedes: "Round 3 section of this same file (verified 2026-08-28, gaps_found, 3/6 SC / 10/12 requirements). Round-3 content is PRESERVED VERBATIM below under 'ARCHIVED — Round 3' and is reconciled, not discarded. This Round 4 section is authoritative."

**The phase goal is NOT achieved, and the phase's own records say so accurately.** `CI required` concludes the literal string `failure` on the only admissible evidence (run `33253587315`), so the headline sentence — "its CI concludes green" — remains false. Two of twelve requirements (GREEN-04, GREEN-07) are correctly Pending. **On process integrity, however, this round is a clean PASS**: this verifier independently re-derived every one of the six named laundering vectors from primary sources and found no violation. Nothing was narrowed, regenerated, skipped, weakened, or retro-edited to make the number look better; the round's stated target (red `needs:` 3 → 1) was missed, the locked pre-push prediction (2) was falsified, and both are recorded as such in the phase's own ledger with the prediction section left byte-unchanged. **Goal: FAILED. Integrity: PASS.**

_(Full round-4, round-3, and earlier tables are preserved in the prior version of this file via git history — `git log -p -- .planning/phases/198-green-bringup/198-VERIFICATION.md` — and are not re-transcribed here in full to keep this document navigable. The round-4 Roadmap Success Criteria table, Integrity Audit table, and Requirements Coverage table are summarized in the round-5 section above, which supersedes them.)_

---

_Verified: 2026-08-31_
_Verifier: Claude (gsd-verifier), round 6_
