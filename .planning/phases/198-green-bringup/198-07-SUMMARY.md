---
phase: 198-green-bringup
plan: 07
subsystem: infra
tags: [github, branch-protection, rulesets, ci, git, tags, shell, gh-api]

requires:
  - phase: 198-04
    provides: "The honest 80-failure baseline and the diagnosis of the 79 test-side search_path defects — the named, sized cause of CI required being red"
  - phase: 198-05
    provides: "The CI cost surgery whose effect this plan measured on origin/main for the first time: 6m07s"
  - phase: 198-06
    provides: "The two verified annotated archive tags this plan pushed, the deleted hazard workflows that made the push safe, and the single-worktree repository"
provides:
  - "origin/main carrying every local commit, fast-forwarded with history intact"
  - "The first measurement of post-surgery CI wall clock on origin/main: run 33138291361, 6m07s"
  - "A git-tracked branch-protection contract: .github/rulesets/main.json, live as ruleset 21702804"
  - "bin/verify-branch-protection — a three-block script proving configuration, emission, and non-stacking"
  - ".github/workflows/branch-protection.yml, deliberately outside the required aggregate"
  - "Both archive/* tags durable on origin (GREEN-12 closed)"
  - "Classic branch protection deleted — the ruleset is the sole protection on main"
affects: [199-decouple, 200-public-surface, 202-release-0-10-0, 203-real-gates]

actuals:
  tokens: 10000
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Protection-as-committed-JSON, applied via the raw API, with the live state asserted by a script rather than a runbook"
    - "A verifier that asserts both configuration AND emission, so a configured-but-never-emitted required check cannot masquerade as protection"
    - "A verification job kept OUT of the required aggregate's needs list, because a skipped required check scores as passing"

key-files:
  created:
    - bin/verify-branch-protection
    - .github/rulesets/main.json
    - .github/workflows/branch-protection.yml
    - .planning/audits/198-branch-protection-migration.md
  modified: []

key-decisions:
  - "Protection applied AFTER the push, not before as the plan sequenced it — an enforcing ruleset with a red required check would have deadlocked the very push this phase exists to perform"
  - "Landed the commits by fast-forward push, not by merging PR #27 — that PR was 22 commits behind, and required_linear_history left only squash (destroys the history) or rebase (rewrites every SHA)"
  - "Classic protection DELETED rather than kept alongside the ruleset: GitHub applies the union, so a stale classic rule would have silently re-armed strict:true and the unsatisfiable 'Run test suite' context"
  - "Maintainer decision: push everything — 2,190 tracked .planning/ files made permanently public, an informed reversal of the milestone-history-stays-local policy"
  - "Maintainer decision: apply the ruleset as designed and accept the lock — with bypass_actors [] and CI required red, nothing merges into main until the 79 test-side defects are retired"
  - "GREEN-07 recorded as PARTIAL with a three-way split, not collapsed to a single verdict — the budget half was genuinely met at 6m07s and the success half genuinely was not"

patterns-established:
  - "When a plan's task order would deadlock its own irreversible step, record an ordering correction in the artifact and reorder — never bypass the gate to preserve the sequence"
  - "Two ruleset ids in one artifact (proven-then-withdrawn, then re-applied) are annotated so a reader matching ids against live state is not confused by a 404"

requirements-completed: [GREEN-08, GREEN-12]

coverage:
  - id: D1
    description: "origin/main contains every local commit, with full history intact"
    requirement: GREEN-07
    verification:
      - kind: other
        ref: "git rev-list --count origin/main..main -> 0; push reported 67998e0b..a97f527e (fast-forward, not squash or rebase)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The post-push run on main completes inside the 20-minute feedback budget"
    requirement: GREEN-07
    verification:
      - kind: other
        ref: "gh run view 33138291361 --json startedAt,updatedAt -> 03:13:58Z..03:20:05Z = 6m07s, against a 20-min ceiling and 12-min target"
        status: pass
    human_judgment: false
  - id: D3
    description: "The post-push run on main concludes success"
    requirement: GREEN-07
    verification:
      - kind: other
        ref: "gh run view 33138291361 --json conclusion -> failure; 8 of 14 jobs red including both verify-test lanes"
        status: fail
    human_judgment: true
    rationale: "NOT MET and deliberately not manufactured. The cause is the 79 test-side search_path defects 198-04 filed as real bugs outside its declared scope, plus 1 unowned CONTRIBUTING.md List 1 drift. Nothing was skipped, excluded, tagged out, downgraded to continue-on-error, or removed from the required-check definition to change this number. A maintainer must decide who owns the 79, since retiring them is also the condition that unlocks the merge gate."
  - id: D4
    description: "Branch protection on main requires exactly one context, the string `CI required`, and that name has provably been emitted on a real run — both asserted by a committed script"
    requirement: GREEN-08
    verification:
      - kind: other
        ref: "bash bin/verify-branch-protection exits 0 on live state: 'required contexts are exactly [CI required], that name has been emitted 1 time(s) on head a97f527e…, and no classic protection is stacking'"
        status: pass
      - kind: other
        ref: "gh api /repos/szTheory/threadline/rules/branches/main -> single required_status_checks rule, context list [CI required]"
        status: pass
    human_judgment: false
  - id: D5
    description: "The protection configuration is git-tracked and auditable as committed JSON rather than living only on GitHub's servers"
    requirement: GREEN-08
    verification:
      - kind: other
        ref: ".github/rulesets/main.json committed (e34d19d9); applied live as ruleset 21702804, enforcement active, bypass_actors []"
        status: pass
    human_judgment: false
  - id: D6
    description: "The up-to-date-branch requirement is OFF and administrator enforcement is ON (D-14)"
    requirement: GREEN-08
    verification:
      - kind: other
        ref: "strict_required_status_checks_policy false on the live ruleset; classic protection (which carried strict:true and enforce_admins:false) DELETED -> gh api branches/main/protection returns 'Branch not protected'; bypass_actors [] means no actor can walk past"
        status: pass
    human_judgment: false
  - id: D7
    description: "Whether classic protection remains alongside the ruleset is an explicitly recorded decision, not an accident of migration"
    requirement: GREEN-08
    verification:
      - kind: other
        ref: "'## Classic protection disposition' in the migration artifact: DELETE, with the union-evaluation rationale; the verifier's third assertion block fails if classic protection exists at all, so the decision cannot rot silently"
        status: pass
    human_judgment: false
  - id: D8
    description: "Archive tags exist on origin, so a laptop loss cannot destroy the only copy of real unmerged work"
    requirement: GREEN-12
    verification:
      - kind: other
        ref: "git ls-remote --tags origin 'refs/tags/archive/*' lists both tags, dereferencing to dd5b48be / 50374eb7; both pushed by name, never --tags; no milestone tag published as a side effect"
        status: pass
    human_judgment: false
  - id: D9
    description: "The verifier has teeth — it fails on a wrong live configuration, not only on a staged one"
    verification:
      - kind: unit
        ref: "test/threadline/branch_protection_comparison_contract_test.exs + bin/compare-required-contexts"
        status: pass
      - kind: other
        ref: "Edge 1 (empty required-context list) RED on real live state; edge 3 (name never emitted on head) RED on real live state; edge 2 (singleton match) PASS"
        status: pass
    human_judgment: false
    rationale: "Edge 4 — the extra-context comparison — is NOT demonstrated. It was refused by the execution environment before the ruleset was live, and was deliberately not retried afterwards, because adding a second required context to the branch's sole live protection purely to exercise a test is a change to production protection with no operational justification. The comparison shares a code path with edges 1 and 2, but 'the same code path' is an argument, not a demonstration, and this is carried as an open verification gap rather than laundered into a pass. Discharged by phase-199: edge 4 is now demonstrated, not argued. The pure comparison was extracted into bin/compare-required-contexts (the bin/classify-flake-run pattern), so the extra-context case runs against fixtures with no network and nothing live touched - honouring this entry's own reason for refusing to mutate production protection."

duration: ~1h 20m
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 07: Land on origin, migrate protection to a committed ruleset Summary

**636 commits fast-forwarded onto a public `origin/main` with history intact, `main`'s decorative six-context classic protection deleted and replaced by a git-tracked ruleset requiring exactly the one check CI emits — with a committed three-block script proving on live state that the context list is right, that the name has actually been emitted, and that nothing is stacking behind it. GREEN-08 and GREEN-12 closed; GREEN-07 partial: the ≤20-minute budget met at 6m07s, the `success` conclusion not.**

## Performance

- **Duration:** ~1h 20m (across a permission gate and a continuation)
- **Tasks:** 3 of 3
- **Files created:** 4; **modified:** 0

## Accomplishments

- **Origin carries everything.** `67998e0b..a97f527e`; `git rev-list --count origin/main..main` → **0**. A plain fast-forward — no squash, no rebase — so all 636 commits of planning history survive individually, which is the record the maintainer explicitly authorised publishing.
- **The CI cost surgery is proven on origin.** Run `33138291361`: **6m 07s** against a 20-minute ceiling, on a milestone that opened against a **1h 33m** run. First measurement on `origin/main` rather than a staging PR. Sharding is not needed, and 6m07s is the number that settles it.
- **A real, live protection defect found and fixed.** Classic protection required a context named `Run test suite`. Run `33138291361` emitted `Run test suite (min)` and `Run test suite (current)` — and never the bare name. That required context was **provably unsatisfiable** and had been sitting on `main` unnoticed. This is the exact deadlock half (b) of the verifier exists to catch, now confirmed with run evidence rather than inferred.
- **Protection is git-tracked, enforced, and machine-verified.** Ruleset `21702804` live, `enforcement: active`, `bypass_actors: []`, one required context. Classic protection deleted. `bin/verify-branch-protection` exits 0 against reality.
- **GREEN-12 closed.** Both `archive/*` tags on origin, pushed explicitly by name. No milestone tag published as a side effect — `v1.35`, `v1.40`, `v1.41` remain local, so the deferred milestone-tag question stays genuinely open.

## Task Commits

1. **Task 1: D-34 step 5 authorization gate** — `95e0c290` (docs)
2. **Task 2: Protection contract, ruleset, and verifier** — `e34d19d9` (feat)
3. **Task 3: Archive tags on origin + migration evidence** — `a97f527e` (docs)
4. **Task 3 write-up: push, run, live ruleset, GREEN-07 partial** — `a347a07c` (docs)

**Plan metadata:** see the `docs(198-07): complete` commit.

## Files Created

- `bin/verify-branch-protection` — three assertion blocks: (a) the live required-context list equals `[CI required]` by sorted exact string equality, failing on an empty list; (b) that name has actually been emitted as a check run on `main`'s head; (c) no classic protection is stacking. Built as a sibling of `bin/verify-release-shape` — same strict-mode header, same repository-root resolution, same compute-then-assert shape.
- `.github/rulesets/main.json` — the protection contract as committed JSON. Required status checks (one context, `strict` false), non-fast-forward, deletion, required linear history, pull request with zero required approvals and required thread resolution. **No signed-commits rule** (breaks bot PRs) and **no merge queue** (overkill at solo throughput).
- `.github/workflows/branch-protection.yml` — job id `verify-branch-protection`, on push to main / schedule / manual dispatch, with `timeout-minutes`. In its **own** workflow, deliberately outside `CI required`'s needs list: a job restricted to `main` inside the main workflow would be a conditionally-skipped member of the aggregate, and a skipped required check scores as passing.
- `.planning/audits/198-branch-protection-migration.md` — the full evidence record: the authorization gate, the ordering correction, the ruleset payload proof, the D-14 before/after, the classic-protection disposition, verifier teeth, the push, the measured run, the live verifier pass, the lock decision, GREEN-07's three-way split, and what remains not done.

## Decisions Made

### Two maintainer decisions, both put explicitly and answered explicitly

**1. Publish the planning history — "push everything, plan as written."**

The maintainer was told, before answering, that `szTheory/threadline` is a **public** repository; that **2,190 tracked `.planning/` files** — the complete GSD planning history, including LLM spend figures, vendor and model names, internal quality assessments, and findings that in places contradict the repository's own documentation — become permanently public and mirrorable; and that the action is **one-way**, since D-30's accepted posture forbids a history rewrite as the remedy.

They chose to push everything. This is an **informed, auditable reversal** of the prior "milestone history stays local" policy, recorded as a decision rather than left to look like an accident. The narrower half of that policy survives intact and was verified: `git ls-remote --tags origin` confirms **no milestone tag** (`v1.35`, `v1.40`, `v1.41`) was published.

**2. The ruleset lock — "apply as designed, accept the lock."**

The maintainer was asked directly whether to apply `bypass_actors: []` knowing that with `CI required` red, **nothing can merge into `main`** — not a pull request, not an administrator, not release-please's PR #26 — until the 79 test-side defects are retired. They chose to apply as designed.

This is simultaneously **GREEN-08 working exactly as designed** (a gate nobody can walk past is the entire point) and a **deliberate hard operational lock**. Collapsing it to either one alone would misrepresent it. **Unlock condition, recorded explicitly so it is not rediscovered under pressure:** either (a) the 79 defects are retired and `CI required` goes green on its merits, or (b) a bypass actor is added as a separate, explicit, recorded decision. Silently relaxing or redefining the required check is not a third option.

### Three decisions that corrected the plan

**Protection is applied AFTER the push, not before.** The plan sequences Task 2 (apply the ruleset) ahead of Task 3 (push), and that order deadlocks its own push: the `pull_request` rule blocks a direct push, the red `CI required` blocks a PR merge, and half (b) of the verifier cannot pass until a run has reported on `main`'s head — which requires the push. Task 2's `<verify>` was literally unsatisfiable before Task 3 ran, and Task 3's own final step ("run it once now that a real run has reported there") concedes as much. The three files were authored and committed in Task 2; the live configuration followed the push. The only way to execute the plan's stated order would have been to bypass or weaken the gate, which the plan forbids.

**Fast-forward push, not the PR #27 merge route.** PR #27's head `2d7abc4a` is an ancestor of local `main` but **22 commits behind it**, so merging it would leave `git log origin/main..main` non-empty — failing the plan's own must-have truth. And `required_linear_history` forbids a merge commit, leaving squash (collapses 636 commits into one, destroying the record this phase authorised publishing) or rebase (rewrites every SHA). A fast-forward was the only route that satisfies the truth the plan actually stated.

**Classic protection deleted, not kept.** GitHub evaluates classic protection and rulesets as a **union**, so keeping both would have silently re-armed `strict: true` and the five collapsed contexts including the unsatisfiable `Run test suite` — the migration would have achieved nothing while appearing to succeed. Compounding it: `GET /rules/branches/main` reports **only** ruleset rules (measured: it returned `[]` with classic protection live), so half (a) of the verifier is structurally blind to classic protection. That is why the script carries a **third** assertion block failing if classic protection exists at all — the disposition cannot rot back to "both stack" without the verifier going red.

## The push, and its bypass line

GitHub reported the push as a bypass:

```
remote: Bypassed rule violations for refs/heads/main:
remote:   - 6 of 6 required status checks are expected
```

Recorded rather than glossed. This was **not** routing around a gate. At that moment `main` was still under **classic** protection, which carried `enforce_admins: false` and no required-PR rule — an administrator pushing directly was an ordinary permitted operation under that configuration, GitHub's wording notwithstanding.

The honest reading is that **the pre-migration protection was decorative**: it announced six required checks, one of which nothing could ever emit, and it let the owner past all six with a warning line. That is exactly the state this plan replaced.

## GREEN-07: partial, reported as three clauses

Reported as a split rather than a single verdict, in the style 198-04 used, because collapsing it either way misrepresents the result.

| Clause | Verdict | Evidence |
|---|---|---|
| `origin/main` contains every local commit | **CLOSED** | `git rev-list --count origin/main..main` → 0 |
| The run completes in ≤ 20 minutes | **MET** | Run `33138291361`, **6m 07s** |
| The run concludes `success` | **NOT MET** | Conclusion `failure`; 8 of 14 jobs red |

**The budget clause is a genuinely earned result and is not diminished by the third clause failing.** 6m07s on a milestone that opened at 1h33m is direct evidence that Plan 198-05's cost surgery worked, measured on `origin/main` for the first time.

**The `success` clause is NOT MET, and was not manufactured.** Local measurement on this tree immediately before the push, unchanged from 198-04's baseline:

| Check | Result |
|---|---|
| `mix compile --warnings-as-errors` | exit 0 |
| `mix format --check-formatted` | exit 0 |
| `mix test test/threadline/ci_topology_contract_test.exs` | 12 tests, 0 failures |
| **`mix test`** | **1380 tests, 80 failures (1 excluded), exit 2** |

Those 80 are **79** real test-side defects in the unprefixed-query / `search_path` family across 15 files, which 198-04 filed as real bugs explicitly outside its declared `files_modified`, plus **1** `CONTRIBUTING.md` List 1 drift that remains **unowned**. Nothing in Phase 198 fixes them.

**No test was skipped, excluded, tagged out, or asserted away; no lane was downgraded to `continue-on-error`; the required-check definition was not loosened so a red suite would score as passing; and no pre-publish gate on the surviving release path was touched.** A manufactured green would be a failure of this plan even if CI reported success.

The plan's `<objective>` claim that "every gate that precedes it is already green" is false, and is corrected in the artifact rather than inherited.

## Verifier teeth

| # | Edge | Induced by | Result |
|---|---|---|---|
| 1 | Half (a), empty-list | Real live state with no ruleset (`GET /rules/branches/main` → `[]`) | **RED**, naming the empty live list and the expected singleton |
| 2 | Half (a), singleton match | Ruleset live | **PASS** |
| 3 | Half (b), never-emitted | Ruleset live; head `67998e0b` predates the aggregate gate | **RED**, naming the head |
| 4 | Half (a), extra-context | *(not performed)* | **NOT DEMONSTRATED** |

Edges 1 and 3 fired against **genuine live state**, not staged fixtures — `main` really was protected-in-name against a check nothing had emitted.

**Edge 4 is an open gap.** It was refused by the execution environment before the ruleset was live, and was deliberately not retried afterwards: adding a second required context to the branch's sole live protection, purely to exercise a test, is a change to production protection with no operational justification. It shares a code path with edges 1 and 2 — but that is an argument, not a demonstration, and it is carried as an open gap rather than laundered into a pass.

## Deviations from Plan

### Ordering and route corrections (not auto-fixes)

Both are documented above and in the artifact: **protection applied after the push** (the plan's order deadlocks its own irreversible step), and **fast-forward push instead of the PR #27 merge** (the plan's stated mechanism cannot satisfy the plan's stated truth). Each is recorded as a deliberate deviation in service of the plan's own must-haves, not around them.

### Execution gate (normal flow, not a failure)

The prior executor reached a permission gate on the GitHub operations and **stopped rather than routing around it**. That is the correct behaviour: a blocked push is a signal to surface, never to reach for a bypass. The operations were subsequently performed by the orchestrator with the maintainer present for both one-way decisions. Recorded as normal flow.

---

**Total deviations:** 0 auto-fixed. 2 ordering/route corrections, both recorded with rationale.
**Impact on plan:** All three tasks delivered. GREEN-08 and GREEN-12 fully met; GREEN-07 partial with the failing clause traced to a named, sized, out-of-scope cause.

## Issues Encountered

- **`CI required` is red, and `main` is now locked because of it.** This is the designed end state, but it is a state someone will meet under time pressure. The two legitimate remedies are named above; there is no third.
- **The 79 test-side defects still have no owner and no plan.** 198-04 sized them and named three remediation shapes with increasing blast radius. They are now on the critical path for anything that needs to merge.
- **The `CONTRIBUTING.md` List 1 drift remains unowned** (`only-in-jobs=["verify-capture", "verify-mechanical"]`). Two table rows. Still nobody's.
- **`bin/verify-branch-protection` will go red if anyone recreates classic protection**, by design. Worth knowing before someone "restores" it.

## Windows ledger

- **`198-06`'s Flake Detection `unrun-verify` window is now DISCHARGEABLE** — the workflow exists on the remote default branch, which was its only blocker. It is **not discharged**: no dispatch was run and no issue number exists to record. Stated as the distinction it is.
- **New gap: verifier edge 4 not demonstrated.** Carried in the artifact under `## Verifier teeth`.

## Threat Flags

None new. The plan's register is addressed as designed: `T-198-07-01` (the D-14 trade) landed as both halves together with the script asserting the result; `T-198-07-02` (a never-emitted required name) is exactly what half (b) caught on real state; `T-198-07-03` (classic stacking) is closed by deletion plus a third assertion block; `T-198-07-04` (public planning history) proceeded on the PROCEED verdict with explicit recorded authorization; `T-198-07-05` (bypass actor) — none configured, per the research's empirical-first position, and none has been observed necessary.

## Next Phase Readiness

**Ready for Phase 199 in every respect except one, and that one matters:** `main` is protected, git-tracked, machine-verified, and **locked**. Phase 199 can develop freely; it cannot merge until `CI required` is green.

- `origin/main` is current — the precondition every subsequent phase's feedback loop depends on.
- CI feedback is **6m07s**, not 1h33m.
- Archive tags are durable off the laptop.
- Protection is one legible, genuinely-enforced gate that a script proves on every push to main.

**The single blocking item for the milestone:** the 79 test-side defects need an owner and a plan. They are now not merely a quality debt but the lock on the default branch.

## Self-Check: PASSED

- `bin/verify-branch-protection` — FOUND, executable
- `.github/rulesets/main.json` — FOUND
- `.github/workflows/branch-protection.yml` — FOUND
- `.planning/audits/198-branch-protection-migration.md` — FOUND
- Commits `95e0c290`, `e34d19d9`, `a97f527e`, `a347a07c` — all FOUND in `git log`
- `git rev-list --count origin/main..main` → 0 — PASS
- Both `archive/*` tags on origin, no milestone tag published — PASS (verified by the orchestrator via `git ls-remote --tags origin`)
- `bash bin/verify-branch-protection` exits 0 on live state — PASS
- `gh api /repos/szTheory/threadline/branches/main/protection` → "Branch not protected" — PASS
- Latest run on `main` concludes `success` — **NOT MET**, recorded honestly rather than asserted as passing

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
