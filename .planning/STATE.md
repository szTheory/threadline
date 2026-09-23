---
gsd_state_version: "1.0"
milestone: v1.41
milestone_name: Green, Clean, and Honest
current_phase: 204
current_phase_name: Structure
status: executing
stopped_at: Completed 204-08-PLAN.md
last_updated: "2026-09-23T23:21:36.605Z"
last_activity: 2026-09-23
last_activity_desc: Phase 204 execution started
state_head: 0ba60d2ef4c6a8212c733aa742ba66dd039b1d37
progress:
  total_phases: 7
  completed_phases: 6
  total_plans: 145
  completed_plans: 138
  percent: 86
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-09-13 after Phase 200)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Phase 204 — Structure

## Current Position

Phase: 204 (Structure) — EXECUTING
Plan: 9 of 15
Status: Ready to execute

**READ BEFORE PLANNING 202 — the release is NOT a bookkeeping exercise.**
Research found PR #26 (`chore(main): release 0.10.0`, open since 2026-06-26) is
born red for FOUR distinct reasons, not stale red. The decisive one: 0.10.0
introduces `Threadline.StorageSchema`, defaulting to a schema it cannot detect
and threaded through every read path, so an existing 0.9.x adopter would upgrade
into a split brain — triggers still writing to `public`, every query reading
`threadline.*`. Capture continues, exploration breaks, and the symptom is an
empty timeline rather than an error. Every automated gate would have passed it.
DECISION D-01 flips the default to `"public"` to make the release non-breaking;
it is rated one-way because hex.pm has no unpublish beyond a ~1 hour window.

Do not start planning without reading `202-CONTEXT.md` in full.

**Cross-session facts this session established (not in git alone):**

- PR #42 (`auto/verification-debt-closeout`) is OPEN and GREEN — all 15 checks
  including the Elixir 1.15 min lane. It carries the Phase 199/200 automation
  and the ungrouped-module fix. Not merged; merging is the maintainer's call.
- The local branch `fix/branch-protection-actions-capability` carries the
  planning artifacts. Its own PR #41 is already MERGED and the branch is deleted
  on origin, so it is a stale local branch — do not push it as-is.
- `.tool-versions` is deliberately untracked; see CONTRIBUTING for the reason.

**Verification debt CLEARED (2026-09-22). Phases 199 and 200 both report
`passed`.** Phase 202 planning can read the roadmap as settled.

**Phase 199 re-verified: PASSED, 40/40, zero gaps, at `4d893e19`.** Re-measured
from a fresh `git clone --no-local` with `.planning` quarantined before any
command ran, so the decoupling claim was tested rather than assumed: 1677 library
tests, 117 example tests, Dialyzer 0 errors under an empty ignore file and a
zero warning ceiling, and every `verify.*` gate green. Three SHAs the OLD report
cited are dangling — `d6d3baee`, `edb2b240`, `c45b7712` are not ancestors of
HEAD; nothing in the new report rests on them. The Playwright lane is CARRIED,
not re-run, on a checked delta argument: the only library change in the window
is `@moduledoc false` on two modules, so there is no rendered-output delta.

Its last skipped checkpoint (Shared Critic Reader Authority, 199-05-D1) is now
proven deterministically. The skip had been blocked on the parked paid critic
loop, but D1 asserts path authority and fail-closed reads — neither depends on
LLM scoring, so `critic:check` was the wrong instrument and a real-key run was
never what would prove it. The paid loop REMAINS PARKED; scoring quality is a
separate claim.

**Phase 200 debt CLEARED (2026-09-22): PASSED, 8/8, re-measured at `bf42de71`.**
The staleness was an ancestry fact, not a regression: the original target
`833a5965` was squashed out of the history by PR #35. Re-measurement did not
merely retarget — it found a real defect the first pass had recorded as
VERIFIED. `ActorLive` and `TransactionLive` declared neither `@moduledoc` nor
`@moduledoc false`, so ExDoc published both on the public index ungrouped,
falsifying SURFACE-04. The contract meant to enforce grouping could not see
them: it folded "has a doc chunk but no `@moduledoc`" into "absent" and asserted
only over documented modules, excluding precisely the violating class. Both were
hidden (matching all ten sibling operator LiveViews) and the gate was rebuilt to
measure the set ExDoc actually publishes; a differential mutation confirms the
repaired gate rejects what the old one passed. Generated docs now carry 42 module
pages, 0 ungrouped.

Carried forward: a warning-free `mix docs` and an exact `groups_for_modules`
declaration are both true and neither can observe the generated index — ExDoc
emits no warning for an ungrouped module. Any future grouping claim must parse
the built sidebar, not the configuration that feeds it.

Phase 200 also now carries zero human-verification items: its last manual UAT
checkpoint (non-maintainer community-health intake) was automated into a
commit-time issue-forms schema contract plus a scheduled live check, rather than
answered by hand.

**Phase 201 verification (2026-09-21): PASSED, 6/6, zero gaps.** All six RENDER
requirements independently re-derived by the verifier, not accepted from the
summaries. The amended visual gate was judged honest disposition rather than
laundering on four grounds, three of them re-measured. Two facts carried
forward: the 8 screenshot failures sit OUTSIDE `ci.all` (the spec self-skips on
`CI=true`, which is how `ci.all` invokes the lane), so the 82/8 figure is the
stricter local measurement; and `tl-home__earned-flow`
(`start_live.ex:222`, `style.ex:907`/`4233`) still carries planning taxonomy in
a CSS class — NOT a Phase 201 violation, since RENDER-06 requires class
attributes stay byte-identical, so it is a Phase 204 (Structure) candidate.
Report: `.planning/phases/201-rendered-output/201-VERIFICATION.md`.

**Phase 201 close-out state (2026-09-21).** All five plans executed. `mix ci.all`
exits 0 — root 1660/0, example 116/0, Dialyzer 0 errors. The browser lane is
82 passed / 8 failed, where the 8 are screenshot comparisons PROVEN pre-existing
by direct measurement (reverting the phase's five LiveView modules to fecfe684
reproduces the identical 8 failures), recorded as WINDOWS entry 62 and pinned as
an exact non-regression gate in 201-05-PLAN.md. Phase 201's entire production
delta is 21 deleted data-earned-flow/data-persona/data-jtbd attribute lines.
Full evidence: `.planning/audits/201-rendered-output-evidence.md`. Nothing was
regenerated or waived. GSD runtime switched from codex to claude with the
adaptive model profile on 2026-09-21.
Closeout gates — ROUND 6 (run 2026-08-31 after 198-40; supersede the round-5 gates, which are preserved below):

- **Code review** (`198-REVIEW.md`, 4 files, standard depth, round-6 source diff `1bda5d1c..HEAD`): **0 Critical** / 1 Warning / 1 Info. CR-01 confirmed FIXED AT CAUSE — the reviewer independently traced `ecto_sql`'s `checkout_or_transaction/4` and confirmed a nested `Repo.checkout/2` from the same process resolves against the process-dictionary-pinned connection rather than a fresh pool checkout; release is guaranteed via `try/after` on every exit path; `Demo.Seed` carries no second guard copy. The new regression test is a real falsifier, not a tautology. New WR-01 (round-6 numbering): `advisory_lock_pinning_test.exs:22-24,32-37` switches `Sandbox.mode(Repo, :auto)` mid-suite, which Ecto's docs warn force-checks-in other processes' connections — safe here only via an unstated ExUnit ordering guarantee the file's comment understates. New IN-02: `reset.ex:79-98` `timeout: :infinity` removes the pool checkout-queue backstop for the whole guarded region, so the docstring's bounding claim holds only for the acquisition phase. Round-5 review preserved verbatim at `198-REVIEW-round5.md`.
- **Verification** (`198-VERIFICATION.md`, round 6): **gaps_found**. Integrity **PASS** on six independently re-derived vectors (CR-01 fix traced by direct code read; GREEN-07 disposition propagation confirmed append-only; D-42 diff empty over `1bda5d1c..HEAD`; `ci-required` `needs:` still names both red lanes; the sealed prediction at `23c16267` byte-identical before/after the push; run `33344382035` re-queried via `gh run view`). Round 5's two gaps are both CLOSED. Remaining: GREEN-07/SC3 is still literally unmet in CI (`CI required` = `failure`) — now a terminal maintainer-accepted gap rather than an open one; and GREEN-08's second clause (PR #26 mergeable) stays BLOCKED downstream of it.
- **Score discrepancy, unreconciled and deliberately not silently fixed:** `198-VERIFICATION.md` frontmatter records `requirements_complete: 10`, counting GREEN-08 as not fully met because its PR-#26-mergeable clause is BLOCKED. `REQUIREMENTS.md` records GREEN-08 as `Complete` with a BLOCKED note, giving 11/12. Round 5 also said 11/12. Two artifacts therefore give two different answers to how many requirements are Complete. This is a maintainer call (the same class of disposition decision 198-39 established must not be executor-selected) and is left OPEN.

Closeout gates — ROUND 5 (run 2026-08-30 after 198-37, superseded above, preserved):

- **Code review** (`198-REVIEW.md`, 19 files, standard depth): 1 Critical / 1 Warning / 1 Info. **CR-01 is new and unresolved** — `Demo.Reset.run/1` (`reset.ex:111`) holds the demo advisory lock and then calls `Demo.Seed.run/0` (`:113`), which re-acquires the SAME lock at `seed.ex:29`; neither `with_demo_lock/1` pins a connection via `Repo.checkout/2`, and Postgres advisory locks are per-backend-session. Verified by hand against both files. Latent, not currently-failing: a single sequential process usually gets the same pooled connection back, which is why CI passed. Under real `mix demo.reset` / `mix demo.seed` (`pool_size: 10`, no sandbox) it can produce a false-positive 45s lock timeout or leak the lock onto an idle pooled connection. Every existing test wraps the call in `Sandbox.unboxed_run/2`, which pins one connection and structurally masks it — so GREEN-04's green CI evidence cannot speak to this defect.
- **Verification** (`198-VERIFICATION.md`): **gaps_found**. 11/12 requirements Complete (up from round 4's 10/12). Integrity PASS — all six laundering vectors re-derived clean; D-42 confirmed independently (`git diff --stat ab412fdd..HEAD` over `.github/`, `CONTRIBUTING.md`, `playwright.config.ts`, `.planning/scorecards/`, `*.png` is empty). Two gaps: (1) GREEN-07 structurally unmet under standing D-39 — not new, honestly reported; (2) CR-01 unresolved, with no round-6 plan, no maintainer decision, and no `deferred-items.md` entry.

Last activity: 2026-09-23 — Phase 204 execution started

Last activity: 2026-09-08 — Planned round 8 to replace all 15 remaining human UAT checkpoints with integration, E2E, smoke, and evidence-contract automation; GREEN-07 remains machine-reported Pending unless its exact-main predicates pass

Last activity: 2026-08-31 — gap-closure round 6 plan 198-40 executed (final plan of Phase 198): pre-push prediction committed (`23c16267`), maintainer pushed `ci/198-round6` and opened draft PR #33 by hand, CI run `33344382035` measured to completion (attempt 1, `failure`, 10m36s). GREEN-04 re-proved Complete strictly from this run; GREEN-07 re-measured unchanged (still Pending, `198-39-DECISION.md` option-a disposition undisturbed); GREEN-01/02/03/05/06/09/10/11/12 carried forward with no new work. D-42 invariants empty over the round-6-specific commit range. All 40 phase-198 plans now executed.

## PROOF-01 outcome (2026-08-26, maintainer-ratified in-session)

- **REJECT (evidence + density)**: three edit variants never beat the noise floor (Δ −1/−2; v3 targeted verdict unstable = VOID per [196-D1]). Edits kept as ordinary unratified UI cleanup (2eca4208) — no signoff claim.
- **ACCEPT (retention + density, pivot)**: duplicated status banner + destructive self-label removed (c6f9355e) → Δ +7 > noise 4.5, no blocking regression, page.retention.happy floor green, oracle stable. First `ratchet.signoffs` forward_only_accept entry + append-only pin (f1610d87).
- Loop hardening: ROUTE_PAGE_TWIN all five routes, dark route-lane maskColor (83db3918).
- Deferred to 197 debt register: verdict cache not screenshot-keyed; score-after-edit overwrites the before pole; Tier-A recapture drift (36k-px fullPage shots vs clipped refute poles); evidence structural density (IA pass).
        Final trust panel (`design-system-ledger.json → critic_trust`): brand_fidelity ρ0.93, density
        ρ0.84, typography ρ0.77, rhythm ρ0.76 = 4 VALIDATED (the blocking panel); color_contrast ρ0.698

        + hierarchy ρ0.42 = advisory (never block; verify vs ground truth — they hallucinate specifics).
        Phase 196 = forward-only net-positive gate, ratified as: GATE-01 RELATIVE/ranking gate on the
        4-lens panel; MechanicalChecker (`verify.mechanical`) = deterministic hard floor, gates on the
        `page.*` Tier-A twin (route.* excluded, mechanical_checker.ex:155); synthetic oracle = held-out
        true-north (GATE-03 divergence halt); GATE-04 guard-the-guards in critic_trust_test.exs
        (`ratchet.signoffs` append-only); GATE-02 mechanical fixes = surface-a-diff this phase (true
        auto-write → 197); PROOF-01 = wire loop + CONTRIBUTING.md runbook + ONE real human-ratified
        improvement on the weakest /audit page (mid-phase checkpoint:decision). Deferred to 197:
        PROOF-02 (2-3 pages), PROOF-03 (adversarial closeout), PROOF-04 (debt register). Locked
        decisions in `196-CONTEXT.md` [196-D1..D9]. ~85% of the phase is WIRING existing machinery.
Last activity: 2026-08-27

Progress: [████████████████████] 130/130 plans ([█████████░] 86% of phases — 6 of 7 complete: 198–203; 204 not started; 199, 200 and 201 carry stale verification)

## Performance Metrics

- **Active Milestone**: v1.41 — Green, Clean, and Honest (opened 2026-08-27; roadmap complete — Phases 198-204, coarse granularity, 53/53 requirements mapped, est. 26-33 plans)
- **Last Milestone Shipped**: v1.40 — Automated Operator-UI Critique & Forward-Only Iteration Harness (2026-08-27, Phases 194-197, 28/29 requirements; PROOF-02 ratified shortfall)
- **Prior Milestone Shipped**: v1.39 — Quality Baseline, Schema Confidence, and CI Efficiency (2026-07-03, Phases 189-193, 15/15 requirements)
- **Scope completion (assessment)**: **~92–95%** for stated narrow audit-platform scope (band: near-done)
- **Hex distribution**: in-repo and hex.pm latest **0.9.0** (tag `v0.9.0`, published 2026-06-03; prior `v0.8.0` 2026-06-03, `v0.7.0` 2026-05-30)
- **Path-to-done thread**: `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`
- **Posture thread**: `.planning/threads/2026-05-29-post-v1.29-posture.md`
- **v1.28 pilot readiness**: `.planning/threads/2026-05-29-v1.28-pilot-readiness.md`

**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 198 P06 | 4h 15m | 4 tasks | 7 files |
| Phase 198 P07 | 1h 20m | 3 tasks | 4 files |
| Phase 198 P38 | 45min | 3 tasks | 5 files |
| Phase 198 P41 | 7min | 2 tasks | 2 files |
| Phase 198 P42 | 6min | 2 tasks | 5 files |
| Phase 198 P47 | 9 min | 2 tasks | 3 files |
| Phase 198 P48 | 18 min | 3 tasks | 8 files |
| Phase 198 P49 | 15 min | 2 tasks | 5 files |
| Phase 198 P50 | 15 min | 2 tasks | 4 files |
| Phase 198 P51 | 30 min | 2 tasks | 5 files |
| Phase 198 P53 | 24 min | 2 tasks | 4 files |
| Phase 198 P54 | 3 min | 1 tasks | 3 files |
| Phase 198 P55 | 27 min | 2 tasks | 5 files |
| Phase 198 P56 | 4 min | 2 tasks | 2 files |
| Phase 198 P57 | 18 min | 2 tasks | 3 files |
| Phase 198 P58 | 9 min | 2 tasks | 4 files |
| Phase 198 P59 | 6 min | 2 tasks | 4 files |
| Phase 198 P60 | 18 min | 2 tasks | 3 files |
| Phase 198 P61 | 24 min | 3 tasks | 7 files |
| Phase 198 P62 | 33 min | 3 tasks | 7 files |
| Phase 198 P64 | 3 min | 2 tasks | 3 files |
| Phase 198 P66 | 9 min | 2 tasks | 3 files |
| Phase 199 P01 | 11 min | 2 tasks | 2 files |
| Phase 199 P03 | 16 min | 2 tasks | 3 files |
| Phase 199 P04 | 10 min | 2 tasks | 4 files |
| Phase 199 P07 | 6 min | 2 tasks | 1 files |
| Phase 199 P09 | 7 min | 2 tasks | 8 files |
| Phase 199 P10 | 7min | 2 tasks | 9 files |
| Phase 199 P12 | 3h 32min | 2 tasks | 18 files |
| Phase 199 P02 | 2h52m | 2 tasks | 10 files |
| Phase 199 P05 | 14 min | 2 tasks | 17 files |
| Phase 199 P06 | 6 min | 2 tasks | 6 files |
| Phase 199 P11 | 11min | 2 tasks | 4 files |
| Phase 199 P08 | 20 min | 2 tasks | 446 files |
| Phase 199 P13 | 8 min | 0 tasks | 5 files |
| Phase 199 P15 | 16 min | 2 tasks | 6 files |
| Phase 199 P16 | 13 min | 2 tasks | 6 files |
| Phase 199 P17 | 15 min | 2 tasks | 6 files |
| Phase 199 P18 | 6 min | 2 tasks | 6 files |
| Phase 199 P19 | 15 min | 3 tasks | 6 files |
| Phase 199 P20 | 17 min | 2 tasks | 2 files |
| Phase 199 P14 | 34min | 3 tasks | 4 files |
| Phase 199 P21 | 1h 8m | 2 tasks | 10 files |
| Phase 200 P01 | 12min | 3 tasks | 5 files |
| Phase 200 P02 | 25min | 2 tasks | 2 files |
| Phase 200 P03 | 4min | 3 tasks | 8 files |
| Phase 200 P04 | 36min | 2 tasks | 14 files |
| Phase 200 P05 | 12min | 2 tasks | 9 files |
| Phase 200 P06 | 7min | 2 tasks | 9 files |
| Phase 200 P07 | 4min | 2 tasks | 6 files |
| Phase 200 P08 | 33min | 2 tasks | 9 files |
| Phase 200 P16 | 32min | 2 tasks | 9 files |
| Phase 200 P17 | 12min | 2 tasks | 10 files |
| Phase 200 P12 | 41min | 2 tasks | 8 files |
| Phase 200 P13 | 5min | 2 tasks | 2 files |
| Phase 201-rendered-output P01 | 13min | 3 tasks | 4 files |
| Phase 201-rendered-output P02 | 11min | 1 tasks | 5 files |
| Phase 201-rendered-output P03 | 7min | 1 tasks | 5 files |
| Phase 201-rendered-output P04 | 8min | 1 tasks | 5 files |
| Phase 202 P01 | 26 min | 3 tasks | 13 files |
| Phase 202 P02 | 12 min | 4 tasks | 5 files |
| Phase 202 P03 | 40 min | 3 tasks | 5 files |
| Phase 202 P08 | 22 min | 1 tasks | 1 files |
| Phase 203 P01 | 6min | 2 tasks | 15 files |
| Phase 203 P02 | 4min | 2 tasks | 9 files |
| Phase 203 P03 | 15min | 2 tasks | 22 files |
| Phase 203 P04 | 3min | 2 tasks | 14 files |
| Phase 203 P05 | 7min | 2 tasks | 20 files |
| Phase 203 P06 | 8min | 2 tasks | 28 files |
| Phase 203 P07 | 6min | 2 tasks | 23 files |
| Phase 203 P08 | 45min | 2 tasks | 28 files |
| Phase 203 P09 | 25min | 3 tasks | 9 files |
| Phase 203 P10 | 40min | 2 tasks | 2 files |
| Phase 204 P01 | 8 min | 3 tasks | 6 files |
| Phase 204 P02 | 35 min | 3 tasks | 16 files |
| Phase 204 P03 | 2h 8m | 3 tasks | 24 files |
| Phase 204 P04 | 26 min | 3 tasks | 17 files |
| Phase 204 P05 | 63 min | 3 tasks | 9 files |
| Phase 204 P06 | 36 min | 3 tasks | 41 files |
| Phase 204 P07 | 12min | 3 tasks | 15 files |
| Phase 204 P08 | 47min | 3 tasks | 10 files |

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| external-pilot | v1.28 pilot unblockers | **Deferred** until sustained real-adopter signal |
| post-v1.29 | Hold mode | **Superseded** by v1.31 polish milestone (2026-06-03) |
| v1.22 DEFER | COMPLIANCE-PACK, LEGAL-HOLD, IMMUTABLE-ARCHIVE | Deferred until procurement pressure |
| host-class | STG-01 host staging depth | Integrator-owned; v1.28 when signal |
| Pow / bearer auth lane | On explicit demand only | Not planned |
| Phase 135-seed-enrichment-ia-lock-in P01 | 3m | 3 tasks | 4 files |
| Phase 135 P02 | 2m | 2 tasks | 3 files |
| Phase 135 P03 | 8m | 3 tasks | 4 files |
| Phase 135 P04 | 5m | 2 tasks | 2 files |
| Phase 144 P02 | 2m16s | 2 tasks | 5 files |
| Phase 144 P03 | 3m47s | 2 tasks | 4 files |
| Phase 144 P04 | 15min | 3 tasks | 8 files |
| Phase 160 P01 | 45min | 4 tasks | 10 files |
| Phase 159 P02 | 35min | 3 tasks | 1 files |
| Phase 159 P03 | 9min | 2 tasks | 1 files |
| Phase 161 P01 | 68min | 4 tasks | 29 files |
| Phase 162 P01 | 17min | 3 tasks | 16 files |
| Phase 162 P02 | 16min | 2 tasks | 5 files |
| Phase 162 P03 | 16min | 3 tasks | 10 files |
| Phase 164 P01 | 10min | 2 tasks | 3 files |
| Phase 163 P01 | 25min | 5 tasks | 6 files |
| Phase 166 P01 | 65min | 5 tasks | 17 files |
| Phase 168 P01 | 25min | 3 tasks | 1 files |
| Phase 170 P01 | 18m | 3 tasks | 5 files |
| Phase 170 P02 | ~9m | 2 tasks | 2 files |
| uat_gap (v1.36 close 2026-06-14) | 169-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| uat_gap (v1.36 close 2026-06-14) | 170-HUMAN-UAT.md — 1 pending scenario | partial — acknowledged & deferred |
| verification_gap (v1.36 close 2026-06-14) | 170-VERIFICATION.md | human_needed — acknowledged & deferred |
| todo (v1.36 close 2026-06-14) | transaction-page-left-push-desktop (operator-surface layout bug) | resolved by Phase 178 |
| todo (v1.36 close 2026-06-14; reframed 2026-06-20) | coverage-schema-card-declutter (operator-surface Coverage IA/schema workflow) | completed as standalone todo; broader Coverage audit-readiness polish now scoped to v1.38 Phase 185 |
| todo (v1.36 close 2026-06-14) | theme-picker-idiomatic-ui (THEME-TOGGLE-01, out of v1 scope per [165-01]) | completed in v1.37 runtime theme picker work |
| deferred [176-05] | T3 redact destructive flow — no runtime redaction backend (codegen-time only); building one would touch the capture layer (v1.37 invariant). Revisit only if a runtime "redact a stored value" op is explicitly scoped without editing capture. | deferred per Task-1 checkpoint (option 1) |
| Phase 174 P06 | 6min | 2 tasks | 2 files |
| Phase 175 P01 | 14min | 2 tasks | 5 files |
| Phase 175 P02 | ~15min | 2 tasks | 4 files |
| Phase 175 P03 | ~30min | 2 tasks | 11 files |
| Phase 175 P04 | ~12min | 2 tasks | 7 files |
| Phase 176 P01 | ~30min | 3 tasks | 9 files |
| Phase 176 P02 | ~40min | 3 tasks | 7 files |
| Phase 176 P03 | ~75min | 3 tasks | 12 files |
| Phase 176 P04 | ~25min | 2 tasks | 5 files |
| Phase 177 P03 | ~5min | 3 tasks | 2 files |
| Phase 177 P04 | ~12min | 2 tasks | 2 files |
| Phase 177 P05 | ~17min | 3 tasks | 7 files |
| Phase 178 P06 | 10m 23s | 3 tasks | 7 files |
| Phase 178 P07 | 8 min | 2 tasks | 1 files |
| Phase 179 P01 | 11m 53s | 3 tasks | 8 files |
| Phase 179 P02 | 8m 9s | 1 tasks | 12 files |
| Phase 179 P03 | 13m 39s | 1 tasks | 12 files |
| Phase 179 P04 | 25min | 1 tasks | 4 files |
| Phase 179 P05 | 28min | 1 tasks | 17 files |
| Phase 179 P06 | 8m | 1 tasks | 5 files |
| Phase 180 P01 | 178m | 2 tasks | 6 files |
| Phase 180 P02 | 10m 27s | 2 tasks | 6 files |
| Phase 180 P03 | 21m 49s | 2 tasks | 5 files |
| Phase 180 P04 | closeout | 3 tasks | guardrail tests + closeout artifacts |
| todo (v1.37 close 2026-06-20) | coverage-schema-card-declutter (functional outcome resolved by Phase 176 and regression-guarded by Phase 180; todo artifact cleanup remains) | completed as todo artifact cleanup; broader Coverage flow polish now scoped to v1.38 Phase 185 |
| todo (v1.37 close 2026-06-20) | operator-shell-nav-ia-and-visibility | completed as post-close todo; broader shell/home polish now scoped to v1.38 Phase 183 |
| todo (v1.37 close 2026-06-20) | demo-login-copy-credentials | completed as post-close demo-login polish |
| Phase 181 P01 | 32 min | 2 tasks | 12 files |
| Phase 181 P02 | 4 min | 1 tasks | 1 files |
| Phase 181-baseline-audit-and-guard-repair P03 | 1028 | 1 tasks | 3 files |
| Phase 181-baseline-audit-and-guard-repair P04 | 7 min | 1 tasks | 8 files |
| Phase 181-baseline-audit-and-guard-repair P05 | 8 min | 1 tasks | 5 files |
| Phase 181-baseline-audit-and-guard-repair P06 | 1h 1m | 1 tasks | 1 files |
| Phase 181-baseline-audit-and-guard-repair P07 | 6 min | 1 tasks | 7 files |
| Phase 181-baseline-audit-and-guard-repair P08 | 4 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P09 | 3 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P10 | 3 min | 1 tasks | 2 files |
| Phase 181-baseline-audit-and-guard-repair P11 | 29m24s | 2 tasks | 37 files |
| Phase 182 P01 | 7 min | 3 tasks | 6 files |
| Phase 182-phoenixstorybook-example-dev-lane P02 | 7 min | 2 tasks | 5 files |
| Phase 182 P03 | 9 min | 2 tasks | 15 files |
| Phase 182 P04 | 18 min | 3 tasks | 9 files |
| Phase 182 P05 | 7 min | 2 tasks | 4 files |
| Phase 183 P01 | 15 min | 2 tasks | 2 files |
| Phase 183 P02 | 68m | 2 tasks | 9 files |
| Phase 183 P03 | 36m | 1 tasks | 3 files |
| Phase 184 P01 | 10 min | 2 tasks | 6 files |
| Phase 184 P02 | 9 min | 2 tasks | 5 files |
| Phase 184 P03 | 49 min | 2 tasks | 5 files |
| Phase 185 P01 | 19m | 3 tasks | 13 files |
| Phase 187 P01 | 5 min | 2 tasks | 3 files |
| Phase 187 P02 | 35min | 2 tasks | 2 files |
| Phase 187 P03 | 28 min | 2 tasks | 3 files |
| Phase 188 P01 | 5min | 2 tasks | 3 files |
| Phase 188 P02 | 3min | 2 tasks | 2 files |
| Phase 188 P03 | 8 min | 2 tasks | 6 files |
| Phase 189 P01 | 6 min | 3 tasks | 2 files |
| Phase 190 P01 | 8m31s | 3 tasks | 9 files |
| Phase 190 P02 | 8min | 2 tasks | 11 files |
| Phase 190 P03 | 7m17s | 2 tasks | 8 files |
| Phase 190 P04 | 15 min | 2 tasks | 6 files |
| Phase 190 P05 | 9 min | 2 tasks | 5 files |
| Phase 190 P07 | 8 min | 2 tasks | 6 files |
| Phase 190 P08 | 9 min | 2 tasks | 8 files |
| Phase 190 P09 | 9m17s | 2 tasks | 6 files |
| Phase 190 P10 | 7m23s | 3 tasks | 3 files |
| Phase 191 P01 | 12min | 3 tasks | 3 files |
| Phase 191 P02 | ~14min | 3 tasks | 4 files |
| Phase 191 P03 | 22min | 3 tasks | 15 files |
| Phase 192 P02 | 15m | 2 tasks | 2 files |
| Phase 192 P03 | 8min | 3 tasks | 4 files |
| Phase 195 P01 | 4m | 3 tasks | 11 files |
| Phase 195 P02 | 4m | 2 tasks | 6 files |
| Phase 195 P3 | multi-session | 2 tasks | 205 files |
| Phase 195 P04 | 11m | 2 tasks | 7 files |
| Phase 195 P06 | 13m | 2 tasks | 2 files |
| Phase 197 P05 | ~50min | 3 tasks | 4 files |
| uat_gap (v1.40 close 2026-08-27) | 169-HUMAN-UAT.md — 1 pending scenario (archived v1.36) | partial — acknowledged & deferred |
| uat_gap (v1.40 close 2026-08-27) | 170-HUMAN-UAT.md — 1 pending scenario (archived v1.36) | partial — acknowledged & deferred |
| uat_gap (v1.40 close 2026-08-27) | 30-HUMAN-UAT.md — 0 pending scenarios (archived v1.9) | partial — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 197-VERIFICATION.md — PROOF-02 shortfall ratified at phase seal (achieved-with-ratified-gap) | gaps_found — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 170-VERIFICATION.md (archived v1.36) | human_needed — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 109-VERIFICATION.md (archived v1.23) | gaps_found — acknowledged & deferred |
| verification_gap (v1.40 close 2026-08-27) | 30-VERIFICATION.md (archived v1.9) | human_needed — acknowledged & deferred |
| deferred_items (v1.40 close 2026-08-27) | Phase 196 deferred-items.md — 1 entry (pre-existing full-suite failures: StressLedgerTest fixture-registry gap, LedgerSplice, FormlessPages, Phase06Nyquist, V123Charter) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 197 deferred-items.md — 1 entry (copy_contract eyebrow red from 197-02 = debt rank 2; 3-module doc-contract baseline = debt rank 8; search_path fix confirmed) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 191 deferred-items.md (archived v1.39) — 3 entries (v1_23_charter_doc_contract_test milestone-literal drift) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 181 deferred-items.md (archived v1.38) — 1 entry (root CI residuals: formless coverage, charter drift, example demo-seed) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 182 deferred-items.md (archived v1.38) — 1 entry (example precommit demo-seed/walkthrough failures) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 176 deferred-items.md (archived v1.37) — 3 entries (format-clean drift ×2, card-nesting coverage RED; table converted to heading entries to carry status) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 177 deferred-items.md (archived v1.37) — 1 entry (example demo-seed 60s setup timeout) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 179 deferred-items.md (archived v1.37) — 5 entries (charter doc-contract + example demo-seed/walkthrough residuals per plan 01/03/04/05/06) | acknowledged in-file (status: acknowledged) |
| deferred_items (v1.40 close 2026-08-27) | Phase 180 deferred-items.md (archived v1.37) — 1 entry (mix precommit demo-seed failures; Status field repurposed, scope note kept) | acknowledged in-file (status: acknowledged) |

## Accumulated Context

### Pending Todos

- No pending todo artifacts remain. The former Coverage, shell/nav, and demo-login todo items were completed or absorbed into the archived v1.38 requirements.
- The next milestone should preserve the standing no-regression rule for operator routes, data-testids, feature gates, capture/query/auth semantics, optional Phoenix dependencies, and host-app-friendly theming unless fresh requirements explicitly change it.

### Roadmap Evolution

- Phase 130.1 inserted after Phase 130: Address tech debt: planning metadata hygiene (URGENT)
- Milestone v1.29 archived 2026-05-29
- **Post-v1.30 direct-PR work (2026-05-30, no milestone):**
  - **0.7.0 release** — unblocked the stuck release-please PR; fixed `bin/verify-release-shape` to accept release-please's CHANGELOG heading; published `v0.7.0` to Hex. Fixed the operator-surface timeline crash on `?correlation_id=` (`FilterParams` `String.to_existing_atom` → compile-time allowlist) that had kept the v1.30 Playwright job red.
  - **Release-pipeline hardening** — generalized `bin/post-publish-distribution-sync` (was 0.5→0.6-pinned); added `workflow_dispatch` to `ci.yml` so "Bootstrap CI on Release PR" stops failing.
  - **Test determinism** — fixed the ~40% retention-pruner flake + a telemetry cross-contamination flake; added `test/support/async_helpers.ex`, `mix verify.flake`, and a nightly **Flake Detection** workflow. See `CONTRIBUTING.md` "Deterministic tests".
- **Direct-PR work (2026-06-03, no milestone):**
  - **Operator surface** — first-class positioning + accessibility pass (#16); deterministic evidence `record_*` export assertions (#18).
  - **0.8.0 + 0.9.0 cuts** — published to Hex via release-please.
  - **Release-please born-red root-cause fix (#22)** — every release PR was born red because release-please bumped `mix.exs` but not the adoption-pilot guide, failing `adoption_pilot_doc_contract_test`. Fixed via `extra-files` + `x-release-please-version` annotation so the SSOT line is bumped atomically in the release commit (green by construction, no manual prep). `bin/post-publish-distribution-sync` now owns only the post-publish Hex row; a guard test enforces the wiring. See memory `release-runbook` and `CONTRIBUTING.md`.
- **Milestone v1.31 opened (2026-06-03):** Hold superseded by a non-signal-gated polish milestone. Ten POLISH-* phases were planned in a fully pre-decided order: measure → enrich → systematize → apply (least-iterated first) → hub → flows → motion → responsive → sweep.
- Phase 144 added: Close gap: POLISH-AUDIT and POLISH-DS
- **v1.31 closeout hygiene (2026-06-05):**
  - The pending "Capture direct demo and UI polish" todo is resolved: the Docker demo is documented in `examples/threadline_phoenix/README.md`, operator-surface polish was absorbed by v1.31, and release notes already cover the automated operator-surface/design-system gate.
  - Phase 135 and Phase 137 HUMAN-UAT records are terminal `status: complete`; their checks are automated by `operator-phase-135-uat.spec.ts` and `operator-prove-mobile.spec.ts` under `mix verify.example_browser`, so no human UAT remains.
- **Milestone v1.33 opened (2026-06-05):** Brand Review + Direction Selection reviews the existing v1.32 `brandbook/` artifacts before public rollout. Phase 150 added `logo-primary-light.svg` after browser preview showed the dark primary logo was too pale on white README/GitHub surfaces.
- **Phase 152 targeted revisions complete (2026-06-06):** Human review selected stand-alone brandbook truth cleanup. `brandbook/` now presents the current brand system without refresh/audit backstory framing.
- **Phase 153 UI-SPEC approved (2026-06-06):** Verification closeout design contract created and checked across copywriting, visuals, color, typography, spacing, and registry safety.
- **Phase 153 verification and closeout complete (2026-06-06):** Current-tree JSON/SVG/HTML parse, direct-open browser, desktop/mobile screenshots, historical-frame scan, binary exclusion, file inventory, and file-size evidence passed. v1.33 is archive-ready with public rollout and legal/trademark work deferred.
- **Milestone v1.33 archived (2026-06-06):** Roadmap, requirements, audit, and phase history are archived under `.planning/milestones/`; fresh requirements are needed before public rollout work.
- **Milestone v1.34 opened (2026-06-06):** Local Docker Admin UI DX focuses on helper-first `bin/demo-up`, localhost-bound dynamic ports, Compose project isolation, cache-friendly Docker behavior, printed `/audit` URLs, lifecycle commands, and docs. Traefik/subdomain routing is deferred; `.localhost` is the future-safe hostname family if proxy support is later added.
- **v1.34 implementation complete (2026-06-06):** `bin/demo-up` now supports project-aware lifecycle commands, `--build`, no-build refreshes when a project image exists, port validation, optional public host, and clearer failure guidance. Compose/Dockerfile now support an overridable demo base image, bundled Dockerfile frontend, `ca-certificates`, localhost-bound ports, project-scoped volumes, and pinned PgBouncer. Docs cover helper-first DX, multi-stack ports, cleanup, cache behavior, and deferred proxy/subdomain routing.
- **Milestone v1.35 roadmap created (2026-06-11):** Unified Logo & Brand Book v2 — phases 159–163 per the approved plan `~/.claude/plans/have-to-compare-it-lexical-shore.md`. 159 (audit+research) ∥ 160 (glyph pipeline) → 161 (tournament, human checkpoint rounds, user picks winner) → 162 (brand book v2 + UAT) → 163 (optional product rollout, decision-gated). 28/28 requirements mapped; operator surface `style.ex` frozen in all core phases.
- **Milestone v1.35 shipped + archived (2026-06-12):** C13 topstitch-geist identity, brand book v2, product rollout, and light-mode strategy decision [165-01] (supersedes [136-01]; v1.36 seeded via SEED-004). Archives under `.planning/milestones/v1.35-*`.
- **Milestone v1.37 roadmap created (2026-06-14):** Operator Surface Design-System Stress Test & Component System — phases 171-180 per the approved plan `~/.claude/plans/design-system-stress-test-fancy-gizmo.md`, continued numbering. Largely linear fractal sequence: 171 (harness: `/audit/__stress` + DESIGN-SYSTEM.md v2 + scored ratchet ledger + ugly-data fixtures) → 172 (foundations/tokens, parity-gated) → 173 (primitive + overlay/disclosure components) → 174 (form components + page adoption + contract tests) → 175 (shell/nav + runtime theme picker, THEME-TOGGLE-01) → 176 (data display, flatten card-in-card) → 177 (component groups) → 178 (per-page stress, all 11 pages, kill footguns) → 179 (microcopy + IA sweep) → 180 (WCAG 2.2 AA + guardrails + adversarial closeout). 33/33 requirements mapped. Carried-todo phase tags: `theme-picker-idiomatic-ui`→175, `coverage-schema-card-declutter`→176, `transaction-page-left-push-desktop`→178. Invariants held: no public component API, zero new runtime deps, inline assets, brand-token parity green, capture/semantics untouched, fail-closed auth.
- **Milestone v1.36 roadmap created (2026-06-12):** Operator Surface Light Mode — phases 166–170 per the approved 165 recommendation's pre-decided breakdown: 166 (unfreeze + 45-token light lane + `data-tl-theme` mechanism, contract amended same-wave) → 167 (component retune, largest) → 168 (accessibility AA mirror) ∥ 169 (`__light__` screenshots + example + docs) → 170 (brand alignment + closeout). 15/15 requirements mapped. Human gates: light-lane design review after 166; end-of-milestone UAT after 170.
- **Milestone v1.38 roadmap created (2026-06-26):** Operator UI Page-by-Page IA & Design-System Polish — phases 181-187. Order is baseline guard repair → PhoenixStorybook example/dev lane → shell/home → Timeline → Coverage → detail/governance/export → accessibility/motion/docs/adversarial closeout. 24/24 requirements mapped, with former post-close todo pressure absorbed into phases 183, 185, and prior demo-login polish.
- **Milestone v1.38 archived (2026-06-30):** Operator UI Page-by-Page IA & Design-System Polish shipped with phases 181-188 complete, 24/24 requirements satisfied, and residual CI/screenshot/environment/Nyquist items explicitly classified in the archive audit.
- **Milestone v1.39 roadmap created (2026-07-01):** Quality Baseline, Schema Confidence, and CI Efficiency — phases 189-193. Order is quality audit → storage-schema proof/fixes → release/version docs trust → CI/CD measurement and efficiency → closeout/next-step decision. 15/15 requirements mapped. Invariants held: no new operator product scope, no public component API, no compliance expansion, no synthetic external pilot, no runtime destructive redaction, no WAL/CDC backend, and no broad CI cleverness before measurement.
- **Milestone v1.41 roadmap created (2026-08-27):** Green, Clean, and Honest — phases 198-204 per the approved plan `~/.claude/plans/so-i-don-t-really-have-quirky-wilkinson.md`, continued numbering. Order is green bringup → decouple (dialyxir lands here) → public surface → rendered output → **release 0.10.0 (deliberately mid-milestone: hex.pm has no undo, so publish once the permanent and rendered surfaces are clean, before the invisible internal work)** → real gates → structure. 53/53 requirements mapped, coarse granularity, est. 26-33 plans. Two workloads are deliberately unmeasured at roadmap time — the full-default Credo backlog (measured in 198 Plan 01) and the dialyzer finding count (measured in 199) — with a pre-committed sizing rule for Phase 203 (<150 → one phase; 150-600 → split mechanical from judgment; >600 or one dominating check → adopt defaults with that check as a counted register row plus a named successor milestone). Phase 201's cost depends on 198 Plan 01's mechanical-sensitivity probe. Highest-variance risk: the `min` CI lane (Elixir 1.15 / OTP 26 / pg14 / ubuntu-22.04) has never executed on origin. Invariants: no operator-UI design/IA/visual change, no Tier-A scorecard regeneration, paid critic scoring stays structurally untriggerable, `.planning/` stays tracked, no git history rewrite, no capture/query/auth semantic change, no version-floor bump; `git mv`/`git rm` for every move/removal, one file per commit where contract tests are involved.

### Decisions

- [202-04]: `ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION` is deliberately NOT set in `environment-protection.yml`. Unlike the branch-protection script's classic-protection field, the live required-reviewer read IS the load-bearing assertion, so passing on an unreadable response would recreate the vacuous gate the check exists to close. A hosted token that cannot read the environment must turn the check red.
- [202-04]: `distribution-sync` required `needs.smoke-published.result == 'success'` in its `if:`, not only a `needs:` entry — the job carries `always()`, under which needs: membership orders execution but does not block. Without the result clause the attestation row could still be written after a FAILED smoke run with every gate green.
- [202-04]: Live API observation (2026-09-22) confirmed the logged endpoint assumption: `GET /repos/{owner}/{repo}/environments/production-hex` returns 200 with `protection_rules[].type == "required_reviewers"` and one reviewer, and `prevent_self_review: false` — which is why the approval is documented as a confirmation step, not peer review.
- [202-04]: RELEASE-05 stays OPEN. It is co-declared by 202-05, and its remaining clause (the smoke job resolving the just-published version from hexpm) is observable only in a real release run — marked `verification: backstop`, not manufactured.
- [197-05]: Debt seed #9 re-measured fresh (2026-08-27 full mix test): (undefined_table) count = 0 — the ALTER DATABASE search_path fix is in effect; register row closed-in-environment with a CI reopen-trigger, not an open ~81-failure row.
- [197-05]: copy_contract_test.exs:249 red (stale "Selected schema readiness" pin vs landed 842bd737) discovered and registered rank 2, not auto-fixed (caused by 197-02, out of 197-05 scope); Phase-185 coverage doc-contract copy lock registered rank 5 with owner + concrete trigger.
- [197-05]: GATE-02 true auto-write stays register-as-debt per OQ-1 with trigger N=3 consecutive accepted iterations where the surfaced mechanical diff was applied verbatim with zero human modification.
- [195-02]: Rubric Anchors pole cell-ids use page-level Tier-A scorecard cells (`page.*__theme-breakpoint` format); `footgun.*` and `primitive.*` are conceptual quality labels in the ledger only, not committed scorecard files. All 11 pole cell-ids (pass + fail across 6 lenses) verified against `.planning/scorecards/`. sha8 placeholder `00000000` is intentional — Plan-04 rubric-hash guard recomputes from disk.
- [193-02]: CLOSE-01 clauses 3 & 4 delivered as `193-RISK-REGISTER.md` + `193-NEXT-STEP.md`. Register is a verify-and-refresh of the 189 ledger (rows 1-3 CLOSED by 190/191/192, rows 6-12 preserved) ranked on the adoption/ops/maintainer lens (D-10/D-12); four post-189 residuals folded in with Owner + reopen-trigger — R-A ship-gated D-17/D-19 (rank 1, ops), R-B/WR-01 alt-schema FK-fixture gap (rank 2), R-C charter-test drift (rank 3), R-D ~81 local failures framed as maintainer-friction NOT a regression (rank 4, below R-A/R-B). Next-step is a single HOLD/thin-polish recommendation backed by three converging gates + config policy (`no_auto_new_milestone` → recommends, does not open v1.40) with five armed flip-triggers (EXT-PILOT-01, OBS-01, UI-REG-01, RECONNECT-01 + CI-depth track). No `/gsd-audit-milestone` run, no `v1.39-MILESTONE-AUDIT.md`, no version/tag change (D-01/D-02/D-03). Commits `92fcb932`, `04dd00e8`.
- [192-03]: Release publish-race serialization scoped to the `publish-hex` job (`group: release-publish-${{ github.ref }}`, `cancel-in-progress: false`); the workflow-level `run_id`-embedding no-op group was removed so release-please bookkeeping stays independent of long publishes (D-24). `gate-ci-green` + the idempotency skip remain the real race guards; no `run_id` in the publish group; no `:latest`.
- [192-03]: CONTRIBUTING two lists reconciled without conflating them — List 1 "Stable job keys" table 8→10 (adds `verify-hex-evaluator`, `verify-example-browser`) mirroring the ci.yml header contract (D-25); List 2 branch-protection required checks renamed `Run test suite (verify-test)` → `Run test suite (min)` / `Run test suite (current)` (D-19) while staying a deliberate subset. The GitHub branch-protection reconfig itself is the human step in Plan 04.
- [192-03]: Version support contract made explicit (Elixir 1.15 floor / 1.17.3 current, OTP 26 min / 27 current, PostgreSQL 14 min / 16 current) in README "Supported versions" + a `mix.exs` comment; `elixir: "~> 1.15"` string unchanged — the floor is honored by the CI min lane, never by raising the requirement (D-13/D-14).
- [192-02]: Cache `deps/` (source only) never `_build`; caches change speed only so `mix ci.all` still reproduces CI byte-identically and every gate keeps its teeth (D-06/D-10/D-12). Playwright/npm caches keyed to the e2e subtree lockfile, never folded into the root `mix.lock` key (D-09).
- [192-02]: `verify-test` gains a base-axis `lane: [min, current]` matrix + `include` (elixir/otp/pg/runner), so GitHub posts exactly `Run test suite (min)`/`(current)` (RESEARCH M1 construction A); min lane = 1.15/otp26/pg14/ubuntu-22.04 runs compile-strict + `mix test` only, heavier steps gated `if: matrix.lane == 'current'` (D-15/D-18/D-19). Branch-protection rename is a human-gated step in Plan 04.
- [192-02]: Pinned `edoburu/pgbouncer:v1.25.2-p0` (no `:latest` in ci.yml) + PR-scoped `concurrency` cancelling only superseded pull_request runs (push-to-main and release-PR dispatch land in distinct groups) (D-22/D-23).
- [191-02]: ADOPT-03 routing uses intent VERBS (Evaluate/Adopt/Operate/Contribute), split by medium (Option C): README `## Start here` owns the routing prose (a three-column "I want to... / Start here / Then read" intent table), ExDoc `groups_for_extras` owns the sidebar structure (four matching verb lanes, explicit per-file regexes, all 20 extras in exactly one lane). The flat `## Documentation` dump is replaced (not deleted) by a collapsed `<details>` all-guides index grouped by the four verbs — no new guide (ADOPT-03/D-191-17 refute holds). New `persona_routing_doc_contract_test` asserts the subset (four keys + each README landing) + refutes start-here/where-to-go-next; `release_artifact_contract_test` owns the exact groups-key equality, updated in lockstep so `verify.release` stays green. P1–P5 operator-UI personas + ia_lock untouched.
- [191-01]: The 0.6.x->0.9.x era was surface/DX/proof-lane only (zero host-DB migrations), so the upgrade guide's affirmative "nothing required" is the factually-correct default per bump. The one migration-shaped expectation is storage-schema freeze-at-generation (Phase 190 D-190-14), kept distinct from host `table_schema`. Backport policy (patch on current minor; minor-crossing is deliberate) now stated in both `guides/upgrade-path.md` and `CONTRIBUTING.md`. Structural doc-contract test owns the theme/per-minor axis; version_truth (plan 03) owns the derived current-minor check.
- [v1.39-01]: v1.39 is a consolidation milestone. Recent work already built the demo, brand, light/system theme, design system, and page-by-page UI polish; the next trust risk is quality evidence, schema confidence, docs/version drift, and CI efficiency.
- [v1.39-02]: `storage_schema: "threadline"` remains the respectful default, with `public` requiring explicit opt-in. v1.39 must prove or fix custom-schema behavior before leaning on that posture publicly.
- [v1.39-03]: CI/CD changes must be measured, boring, and reversible. Baseline first; then fix cache/setup/service/release/version-policy gaps without hiding risk.
- [v1.38-01]: PhoenixStorybook is scoped to `examples/threadline_phoenix` for development/design review only. Root `threadline` keeps optional Phoenix/LiveView dependencies, no public component API, and `/audit/__stress` remains the canonical flow stress harness.
- [v1.38-02]: Page cleanup order starts shell/home/timeline, then Coverage, then detail/governance/export, then closeout. This fixes orientation and task flow first and reuses patterns on lower-traffic pages.
- [176-05] (checkpoint, human-approved option 1): T3 destructive pattern ships via "prune now" ONLY this phase; the redact destructive flow is DEFERRED. Redact has no runtime backend (codegen-time only); building one would touch the capture layer (v1.37 invariant violation). Prune is enforced server-side: secure_compare(typed, server-canonical policy name) + authz re-check + scope fail-closed + audit-the-action; client-only `data-confirm` deleted.
- [Phase 174-02]: Extended `<.field>` properties with global attribute pass-through (e.g. `list`, `maxlength`) rather than rigid structs, accommodating existing advanced filter functionality natively.
- [Phase 174-01]: Form components use explicit `name`, `value`, and `errors` rather than requiring `Phoenix.HTML.Form` structs to maintain isolation and independence from Ecto.
- [Phase 174-01]: Form primitives rely entirely on native HTML5 controls rather than custom JS elements for maximum browser compatibility and accessibility.
- [136-01]: Dark-only remains intentional; no `prefers-color-scheme`, no light mode, no theme toggle. *(Superseded by [165-01] in Phase 166 per THEME-04.)*
- [165-01] supersedes [136-01]: dark remains default and brand-primary; light/system are supported via host `theme:` config; no runtime theme toggle in v1; the `theme-toggle` ban remains.
- [136-01]: Lift muted/status contrast and make hover/focus/disabled states explicit through shared `--tl-*` tokens before per-screen polish.
- **130.1-02 (2026-05-29):** Nyquist waivers for doc-only phases 128–129; 130-VALIDATION superseded footnote; `mix ci.all` green at closeout.
- **130-02 (2026-05-28):** SUMMARY SSOT at `conventions/summary-frontmatter.md`; GAP IDs for 125–127 only; single `mix ci.all` in 130-VERIFICATION.
- **130-01 (2026-05-29):** Phase 125 archived under `milestones/v1.27-phases/`; `125-VALIDATION.md` finalized after Tier 1 green.
- **128-02 (2026-05-28):** phx-gen-auth mount uses `&MyApp.Audit.authorize_operator/1` with scope-first lookup and `is_admin: true` gate.
- **v1.29 posture (2026-05-29):** Hold for milestones; pre-pilot hardening: `mix verify.hex_evaluator`, WALKTHROUGH ConnCase tests; pilot pack queued.
- Full decision log: `.planning/PROJECT.md` Key Decisions table.
- [Phase ?]: Generalize actor helpers
- [Phase ?]: D-05 fix: setup rows actor-attributed and backdated
- [Phase ?]: D-06: named actor literals in Manifest
- [135-03]: Membership role change backdated outside 24h window (D-05 compatible); D-13 UPDATE satisfied by ticket/ticket_replies in-window mutations
- [135-03]: agent2 used for role flip to guarantee Ecto sends real SQL UPDATE (trigger fires)
- [135-03]: SavedView actor_ref uses type: :user (matches Timeline mount query for admin)
- [135-04]: D-03: Recipe table in DEMO-MANIFEST.md backed by demo_manifest_contract_test.exs; 24 rows covering all operator-surface screen states
- [135-04]: D-04 deferred: Coverage fully-covered/all-empty state noted as Phase-138-owned (trigger-registration dependent, not seed-reachable)
- [135-04]: demo_manifest_contract_test.exs kept separate from demo_manifest_test.exs (different concerns: doc vs module)
- [Phase 144]: Operation badge semantics stay in Presentation as pure helpers; no Phoenix component/public UI API expansion.
- [Phase 144]: Unknown operations use string-safe normalization with an empty modifier and uppercase fallback label; no String.to_atom/1.
- [Phase 144-03]: The v1.31 design-system freeze is source-first: style.ex and style_contract_test.exs govern the catalog.
- [Phase 144-03]: Phase 144 documents the local .tl-* and --tl-* system without Tailwind, build tooling, light/system theme support, external dependencies, or a public component API.
- [Phase 144-04]: POLISH-AUDIT and POLISH-DS are closed by Phase 144 verification while preserving the original roadmap-owner assignments.
- [Phase 150]: README/GitHub is the deciding surface for brand readiness; use `logo-primary-light.svg` on light documentation/repo surfaces and keep `logo-primary.svg` for dark/high-signal surfaces.
- [Phase 151]: Targeted revisions selected; alternate logo concepts, public rollout, and runtime UI changes remain out of scope.
- [Phase 152]: Brandbook-facing artifacts should present current brand truth; process history belongs in `.planning/`.
- [Phase 153]: Verification closeout UI remains static brandbook evidence only; no runtime UI, registry, component library, build pipeline, or committed raster export batch.
- [v1.34]: Helper-first dynamic localhost ports are canonical for local demo DX; Traefik is deferred and `.dev` hostnames are rejected for HTTP local demos.
- [v1.34]: Normal `bin/demo-up` refresh skips image rebuilds when the project image exists; `--build` is explicit for Dockerfile/dependency/base-image changes, and `--fresh` remains the volume-reset path.
- [v1.34]: Demo Dockerfile uses Docker/BuildKit's bundled frontend and installs `ca-certificates`; the base image is overridable via `THREADLINE_DEMO_BASE_IMAGE`.
- [v1.35]: Rollout to product surfaces (logo.ex, example-app favicon, README header) is an optional final phase (163), decided at that checkpoint with the winner in hand.
- [v1.35]: Seed drift is free exploration — round 1 may use OFL-safe typefaces and palette shifts; tokens/product UI change only if the winner demands it.
- [v1.35]: Hard logo constraints — no background chips on marks, logotype optically close to the mark, no subtitle in the primary lockup (separate `-subtitle` variant), user always picks the winner (never auto-selected).
- [v1.35]: All logo SVGs are pure paths (fontkit glyph-outline pipeline); zero `<text>` elements anywhere in candidates or final assets.
- [Phase 160]: Overlay baseline alignment via zero half-leading: line-height = (ascent-descent)*scale so live-text and SVG baselines coincide at ascent*scale
- [Phase 160]: Phase scripts reuse existing installs via module.createRequire anchored at the owning dir (fontkit via NODE_PATH, Playwright via e2e dir)
- [Phase 159]: 159-02: GitHub SVG sandbox verified empirically (default-src 'none'; style-src 'unsafe-inline'; sandbox) — pure-path SVGs are the only portable wordmark form; inline-CSS adaptive SVGs (Zig pattern) viable
- [Phase 159]: 159-02: Six technique names locked as Phase 161 motif vocabulary; gradient-dependence and gimmick-dependence (moz://a) named as paired antipatterns
- [Phase 159-03]: Motif distinctness defined at the (technique, letterform hook) pair level — 8 candidates need 8 distinct pairs; no technique repeats within a lane
- [163-01]: User opted IN at the rollout checkpoint ("Roll out now"); C13 shipped to logo.ex, example-app admin favicon, and the README header — style.ex untouched (freeze exception covers logo.ex only)
- [163-01]: logo.ex wordmark renders as pure brandbook paths; one non-rendering display=none `<text>` compat node preserves the in-flight nav-overhaul lane's header test contract until that lane lands (brand assets themselves stay zero-`<text>`)
- [Phase 159-03]: GAP-09/UP-08 raster export descoped to SOCIAL-PNG-01 (future); trademark descoped to human review; all other audit items routed to LOGO-*/TOUR-*/BOOK-* requirements
- [Phase 161]: 161-01: strategy matrix doubles Stroke continuation + Continuous-line mark (different hooks); all six BRIEF techniques used across 3/3/1/1 lanes
- [Phase 161]: 161-01: candidate ink uses currentColor with at most one flat accent (#4781E6 blue / #D9A03F gold); monos generated by color substitution only
- [Phase 161]: 161-01: BRIEF double-l-verticals hook mapped to the adjacent d/l ascender pair (no literal ll in Threadline)
- [Phase ?]: 162-01: Stitch arc stays #4781E6 on dark and light; #4F8CFF remains UI accent; #4781E6 recorded as additive stitch-blue raw token in plan 02
- [Phase ?]: 162-01: favicon uses Ink #0F1728 default strokes with internal prefers-color-scheme dark flip to Fog #D7DEEA (standalone equivalent of C13 currentColor design)
- [Phase ?]: 162-01: tagline outlined at 0.24em (240-unit) tracking, justified to wordmark ink edges; examples pruned to readme-header + docs-page
- [Phase ?]: 162-02: Brand book clear space = half cap height for lockups, quarter-size for mark/favicon; minimums 120px lockups / 180px subtitle / 16px mark+favicon (wordmark legibility governs)
- [Phase ?]: 162-02: Stitch Blue #4781E6 added additively to tokens (raw stitch-blue + semantic logo-arc, both lanes); #4F8CFF stays the interface accent; operator-surface values untouched
- [Phase ?]: 162-02: Misuse specimens live only as inline SVG in index.html; index.html inlines all 8 assets via shared pure-path defs; zero network under file://
- [Phase ?]: 162-03 pressure-test rerun
- [Phase 164]: Brand imagery specimens: pure-path linework with HTML labels over the SVG; Thread Blue carries the followable line, Signal Cyan the change ticks, Stitch Blue stays exclusive to the mark's arc
- [Phase ?]: [170-01]: full token parity = curated-subset parity (name + value equal in dark + light); brandbook corrected to style.ex, never the reverse
- [Phase ?]: [170-01]: brandbook<->style.ex drift now caught by brandbook_token_parity_test in both directions; pressure-test dim #11 bumped 8->9 (total 128->129)
- [Phase ?]: [170-02]: v1.36 audit doc authored; COMP-01/02 built+verified-live source-uncommitted; closeout pending-uat
- [Phase ?]: [170-02]: REQUIREMENTS COMP-01/02 token 'Verified (source pending)' (table + checkboxes); BRAND-01/02 Complete; archival+version bump -> /gsd-complete-milestone post-UAT
- [Phase 174-05]: search/date/number need no dedicated input clause — the generic input(assigns) default already emits type={@type} + tl-control; documented as passthrough and proven by contract tests.
- [Phase 174-05]: New form components compose existing classes/BEM modifiers (tl-error-summary__*, tl-radio__*, tl-switch, tl-combobox__*) rather than add any new --tl-* token, keeping style.ex untouched and brand-parity green.
- [Phase 174-05]: combobox confines JS to ARIA state via Phoenix.LiveView.JS (popover/dropdown precedent) — CSP-safe, degrades to free-text input, no Alpine, no new runtime deps.
- [Phase 174]: [Phase 174-06]: field_group renders the base tl-filter-group class + legend; timeline call sites pass only the --primary/--advanced modifier and drop the duplicated raw legend.
- [Phase 174]: [Phase 174-06]: formless guard scans each page's own source (not surface_header), excluding the legitimate hidden _csrf_token and theme-picker form without an explicit allowlist.
- [Phase ?]: [175-01]: CSP guard combines specific onclick/onchange refutes + explicit handler list + broad on*= regex (mitigates T-175-01); breadcrumb_test drives the live actor drill-down with a legacy-landmark fallback; skip_link_test follows the Timeline mount live_redirect.
- [175-03]: One internal `UI.page_header/1` (single `<h1>`, `:heading`/`:lede`/`:actions`/`:inner_block` slots, ordered `breadcrumbs`) adopted across the operator pages; reuses existing CSS only (no style.ex change, no new `--tl-*` token, no public API). Drill-down pages (Transaction/Actor/standalone Row history) carry location-based breadcrumbs under `<nav aria-label="Breadcrumb">` rooted at "Timeline" and pass `current={nil}` so the single `aria-current="page"` lives only on a shell nav link (the inlined CSS `[aria-current="page"]` selector pinned by style_contract counts page-wide, so nav must mark nothing current on drill-downs). Timeline command toolbar + Coverage command-center state kept bespoke single-`<h1>` (specialized command structures pinned by timeline_live_test / aria-labelledby). D-02 doc-contract back-link assertions re-pointed to the D-13 breadcrumb root (Rule 3). Both NAV-01 Wave-0 RED targets GREEN; transaction_live/skip_link/CSP locks + brand-token parity green. Commits `025e9d3`, `3e4b1c7`.
- [175-04]: One internal `UI.pager/1` (de-emphasized Older/Newer time-axis controls + a `role="status" aria-live="polite"` range caption) over the EXISTING keyset engine — hide-at-zero (D-16), disable-not-hide on boundaries (D-18), capped "10,000+" deep total (D-17); controls emit the host page's existing next-page/prev-page events (no engine change). Adopted next-only on Timeline (cursor stays in socket assign, D-19) and bidirectionally on Actor; Exports/Retention get honest "Showing latest N" cap captions (D-20), Coverage/Redaction none. `pager_test.exs` (the binding RED target) drove the signature (`shown`/`match_count`/`has_older`/`has_newer`), with optional `older_event`/`newer_event` phx-click attrs for adoption (`newer_event` is `:any` so Timeline passes nil). query.ex documents the `(captured_at, id)` keyset tiebreaker as DEFERRED capture-layer perf debt (D-15/Q1, T-175-10 accepted) — doc note only, no migration, capture layer byte-for-byte untouched. Zero new `--tl-*` token (brand-parity green). All 4 NAV-02 Wave-0 RED targets GREEN; verify.test 1008/0; credo clean. Commits `1a230bd`, `ac6f762`.
- [175-02]: Shell is CSP-proof — all three inline handlers removed (theme onchange, nav onclick, skip-link onclick); theme picker rebuilt as visible native radios + explicit "Apply theme" button + pure-CSS `.tl-theme-picker__option:has(:checked)` non-color cue (zero new tokens); mobile nav is native `<details>` keyed on `[open]`; scroll-padding-top reconciled to the per-row scroll-margin-top token + overscroll-behavior:contain + 100svh; router macro doc corrected; theme-toggle ban lifted in style_contract_test for a positive CSP guard; backend untouched (D-09).
- [176-02]: Built the internal `OperatorSurface.UI` data-display + data-state family: `ref/1` (binds `data-tl-copy={full}` on `<code>` + gated button, never `.title`/`.visible` D-02; zero-JS renders full D-06; `copy_label` required no-default D-07), `kv/1` (tl-kv `<dl>` + required `:item key` slot D-08), `data_table/1` (`:col label` feeds `<th>` + every `<td data-label>` from one source, rows|stream `phx-update=stream`, row_id, row_status `data-status` stripe, `:action` kebab, no ARIA table roles D-09), `loading_state/1` (role=status + aria-busy + spinner + text node D-13), `stale_banner/1` (role=status `tl-alert--warning` strip above data with `as_of` + Retry D-14), `empty_state` variants `no_data`/`permission`/`unavailable` + `role`/`icon`/`focus_heading` (D-15 focus rescue = generated heading id + `tabindex=-1` + `phx-mounted={JS.focus}`, CSP-clean), and `data_state/1` typed-reason dispatcher (distinct role+icon SHAPE+heading per reason; unavailable sub-cases state "not a permissions issue" D-16). `data_state/1` was a Rule-2 add — the Plan-01 `data_state_mapping` wave-0 test calls it; it is now GREEN. `copy_label` required-attr enforcement is a compile WARNING (Phoenix attr semantics), asserted via CaptureIO. 10 stress stories (ref/kv/data_table + 7 data-states) registered with matching `.planning/design-system-ledger.json` + `DESIGN-SYSTEM.md` rows (Rule-3 coupling — ledger test requires registry↔ledger↔projection parity). Zero new `--tl-*` token; brand-parity + style_contract green; no style.ex change. No page migrated (plans 03/04/05). 6 cross-plan Wave-0 scaffolds remain RED by design (1 card-nesting→03, 5 retention T3+ref-copy→05). Commits `d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`. Capture/semantics untouched.
- [176-01]: `Presentation.ref/2` → `%{visible, title, full}` reuses `secondary_ref_value/1` for `full` (no value-extraction rebuild, D-01); `title == full`. `truncate_middle/3` gains additive `:tail_min` (≥N tail chars survive verbatim; no-`:tail_min` path byte-for-byte unchanged so `export_summary/1` is unaffected, D-03). `value_token/1` truncates at 56 keeping full in `:title`. Per-kind `truncate_for/2` (uuid/correlation/arn/actor/hash/path/email/url/timestamp; `:timestamp` never truncates). Source-down glyph is `:cloud_off` (not `:plug`); `archive` reused for pruned. The four MISSING Wave-0 tests use a self-contained tokenizer/regex (no Floki — not a project dep, v1.37 zero-new-dep invariant); `RefCopyContract` lives in `test/support` (only `test/support` is on the compile path). card-nesting regression treats the synthetic `tl-coverage-command` shell as a card-family surface so it is genuinely RED on coverage today (literal card>card alone would false-green). 9 new assertions RED (3 data-state + 1 card-nesting + 5 retention/ref-copy), all turning GREEN in Plans 02/03/05. Commits `989f03c`, `45a788d`, `a4a13fa`, `3503fdc`. Capture/semantics untouched. Pre-existing `ui_test.exs` format drift logged to deferred-items (out of scope).
- [176-04]: Flattened the coverage "schema" command shell — the DATA-05 / `coverage-schema-card-declutter` target. The success branch's hand-rolled `<section class="tl-coverage-command">…<h1 class="tl-page__title">` header is replaced with `UI.page_header` (title + `:lede` + `:actions` Refresh + a NEW optional `:meta` slot carrying `Presentation.checked_label`); all three branches now use page_header. The synthetic `tl-coverage-command` shell is demoted so trust-rail / `tl-summary-grid` metric tiles / remediation / table become direct page-stack `<section>` siblings (D-11 one card boundary per logical unit); `tl-card--metric` tiles kept, `__metrics` modifier dropped (bare `.tl-summary-grid` supplies the margin). Dead `tl-coverage-command__*` CSS deleted from style.ex (base + tablet) with the paired `refute String.contains?(src, "tl-coverage-command")` style_contract lock added in the SAME commit (T-176-08). **Rule-2:** added an optional `:meta` slot to `UI.page_header` (the plan's key_links require it but plan-175's component lacked it; defaults to `[]`, backward-compatible for every other call site). **Rule-3:** swapped the 3 style_contract assertions that pinned the deleted CSS for the refute lock. Task 2 (system-wide nesting sweep) needed NO source change beyond Task 1 — the card-nesting regression test (renders all 11 surfaces, refutes card-under-card) went GREEN the moment the shell flattened; coverage_live.ex was the only card-nester, so the plan stayed disjoint from plan 05 (retention/redaction untouched). Full operator_surface suite 545/5 — down from 6 RED (card-nesting now GREEN); the 5 remaining are the plan-05 retention T3 prune (4) + ref-copy (1) Wave-0 scaffolds. Zero new `--tl-*` token; brand-parity + style_contract green. Commit `157398d`. Capture/semantics untouched.
- [177-03]: Wave-3 meta-components + breadcrumb truncation. Shipped `@doc false` `UI.data_panel/1` (state-coordinating SHELL: a cond maps the generic state atom — ok|loading|empty|no_data|error|permission|unavailable — onto the EXISTING named state family; NO variant= switch, NO reinvented focus logic; `:permission`/`:unavailable`→`data_state(@reason)` collapses the body preserving the lock/cloud_off forensic distinction + delegating focus rescue D-06c; `stale_banner` rendered ABOVE the region as a cond-sibling, never replacing :ok data D-176-14; pager only when :ok), `UI.toolbar/1` (role=search + `aria-disabled` via `to_string/1` so it emits "true"/"false" + `is-disabled` affordance on `tl-cluster`; documents the page's HTML-`disabled`-on-controls enforcement contract, Pitfall 6), and `UI.detail_header/1` (`<h2>` not `<h1>` per D-175-03 + `justify=end` actions cluster + `kv` metadata from `<:metadata key=...>` slots). Reconciled breadcrumbs by KEEPING the `page_header` list attr (D-14, not a slot per D-04 literal) and truncating the current crumb via `.tl-transaction__breadcrumbs-current { max-width: clamp(12ch,50vw,40ch) }` so the header never horizontal-scrolls at 320px. Added `.tl-data-panel`/`__region`(opacity cross-fade on `--tl-motion-fast`, D-10.2)/`__pager` + `.tl-toolbar`/`.tl-detail-header` CSS (no new tokens). **Rule-1 (self-caught):** the first draft added a `@media (min-width:768px)` block + a "~1ms" CSS comment, reddening 4 phase-141/142 StyleContractTest source-governance assertions (exact min-width literal set; ungoverned `\d+ms`); replaced with `clamp()` (no new media literal) and rephrased the comment, returning the suite to the 2 RED-by-design Plan-04 scaffolds (verified identical to baseline `ac78693`). All 7 component RED scaffolds GREEN; ui_test+page_header 64/0; full suite 1071/2 (2 = Plan-04 overlay/offline, by design); warnings-as-errors + format + credo (2113 mods/funs) clean; brand parity 4/0. GROUP-01/GROUP-02 deliberately NOT marked complete (phase-spanning, complete at Plan 05). Zero new dep; no public API; capture/semantics untouched. Commits `1f4d6d7`, `2b082f8`, `19ef009`.
- [177-02]: Wave-2 layout primitives + semantic gap tokens. Added `--tl-gap-inline`/`--tl-gap-stack`/`--tl-gap-section` to all three sources (tokens.css/tokens.json/style.ex) in ONE task so brandbook_token_parity_test never drifted (8/16/32px → --tl-space-2/4/8). Shipped `@doc false` `UI.stack/1` (gap: stack|section|inline|tight, default stack; tight→--tl-space-1/4px) and `UI.cluster/1` (justify: start|between|end, default start) following the card/1 class-list idiom, with `.tl-stack`/`.tl-cluster` CSS owning inter-child spacing via flexbox `gap` over --tl-gap-* tokens (no raw child margins, GROUP-01/D-02). Turned the Plan-01 gap-parity + stack/cluster render RED scaffolds GREEN. data_panel/toolbar/detail_header scaffolds left RED by design (Plan 03 owns them per task scope + verification_note, despite some test-name tags reading "[RED — Plan 02]"). Zero new dep; no public API; capture/semantics untouched; format + credo clean. Commits `8d701e8`, `38005a3`.
- [177-01]: Wave-0 conflict resolution + RED test scaffolds (zero production code). **Conflict 1 (offline anchor):** confirmed by grep that all 11 audit LiveViews render `<div class="threadline-ui">` as their render root, so the offline-group CSS (Plan 04) keys off `.threadline-ui.phx-loading`/`.threadline-ui.phx-error` (the LiveView ROOT), NOT `<body>`, and NEVER `.phx-disconnected` (which doesn't exist in LiveView 1.x — the dropped-socket state re-applies `.phx-loading`). Corrects the literal wording of D-08/UI-SPEC per RESEARCH Pitfall 1; resolves Open Q1 / A2. **Conflict 2 (breadcrumbs):** keep `page_header/1`'s existing `attr(:breadcrumbs, :list)`; do NOT add a same-named `:breadcrumbs` slot (Phoenix forbids attr+slot name collision → compile error). Deliberate deviation from D-04's literal "slot" wording, justified by D-14 discretion (breadcrumbs are location DATA, not arbitrary markup) + RESEARCH Pitfall 4; Plan 03 adds narrow-viewport truncation only. **Token decision:** `--tl-gap-section`→`--tl-space-8` (32px), `--tl-gap-inline`→`--tl-space-2` (8px), `--tl-gap-stack`→`--tl-space-4` (16px) (D-09 / RESEARCH A1). Laid 12 RED scaffolds (3 source/parity in brandbook_token_parity_test + style_contract_test; 9 component renders in ui_test for stack/cluster/data_panel×4/toolbar×2/detail_header) + 1 GREEN breadcrumbs-trail test. Full suite 1071/12 — every failure is a new expected RED scaffold; no pre-existing regression. RED is the deliverable (Plans 02–05 turn green). Zero new dep (v1.37 invariant). Commits `bede897`, `4b7e304`.
- [176-03]: Migrated the display/read-only operator pages onto the Plan-02 components (non-destructive consumer migration; coverage/retention/redaction are plans 04/05 and were NOT touched). Transaction copy footgun closed — transaction id + correlation id + diff before/after cells all bind `data-tl-copy={full}` via `UI.ref/1` (never `.title`/`.visible`/`.text`, D-02); transaction metadata → `UI.kv`; diff cells truncate via `value_token` (max 56) + gated per-cell copy bound to the full value (`diff_full/1`, D-04); timestamps in semantic `<time datetime=exact_time>` UTC (D-22). actor/timeline/evidence/export migrated to `UI.ref` (copy=full) + `UI.kv` (export per-job + both export-context `tl-param-list` retired). Per-page data-state: actor + timeline branch ok-empty into `empty_state variant=never` (first-run, history) vs `no_data` (narrowing filter active, funnel) — distinct icon SHAPE (D-17); evidence `no_data`; export `never`; invalid-actor-ref → `error_state`. **Rule-1 bug:** `UI.ref` used `String.to_existing_atom(kind)` which raised for `:correlation`/`:arn`/`:actor`/`:email` (atoms not interned) — added `Presentation.kinds/0` + `kind_from_string/1` (literal `@ref_kinds`, compile-time interned) and switched `UI.ref` to the safe resolver. **Rule-3:** `UI.ref` can't nest in an `<a>` (button-in-anchor) — copyable ref renders standalone, deep-link demoted to sibling Timeline/Actor affordance. `.tl-secondary-ref` CSS double-truncation removed (`text-overflow:ellipsis` gone, `overflow-wrap:anywhere` kept, D-05) with the paired `style_contract_test` assertion (refute ellipsis + assert wrap) updated in the SAME commit. Zero new `--tl-*` token; brand-parity + style_contract green. 213 targeted tests green; the 6 remaining operator_surface failures are the documented cross-plan Wave-0 RED scaffolds owned by plans 04/05 (1 card-nesting + 5 retention T3/ref-copy). Commits `e1650c8`, `32b0977`, `a798147`. Capture/semantics untouched.
- [Phase ?]: [177-04]: Completed the motion + connection-lifecycle layer — overlay JS-transition utility CLASS selectors + modal/drawer/toast shells (overlay motion now real), every overlay JS.show/hide synced to time: 180 (=--tl-motion-base), toast fade-up via show_toast/2; reconnect/offline group keyed off the LiveView ROOT .threadline-ui.phx-loading/.phx-error (NOT body, NEVER the legacy disconnected class — Pitfall 1) with a warning-tinted role=status banner + [data-tl-mutating] disable + UI.reconnect_banner/1 documenting the mutating-link aria-disabled/tabindex=-1 contract (Pitfall 6). Both Plan-01 style_contract RED scaffolds GREEN; full suite 1071/0; compile/format/credo(2115)/brand-parity clean; zero new keyframes/tokens/deps; capture/semantics untouched. GROUP-01/02 NOT closed (Plan 05). Commits da4a36d, f1695a1.
- [Phase 178]: [178-06] D-11 corrected: LiveView lifecycle classes attach to [data-phx-main]; reconnect CSS scopes into .threadline-ui. — Real-engine socket-drop verification proved the prior .threadline-ui lifecycle-anchor premise false.
- [Phase 178]: [178-06] Real socket-drop proof must assert visible banner and computed mutating-control dimming/restoration, not lifecycle-class detection alone. — The closure bug was masked by tests that observed class flips without asserting visible/computed behavior.
- [Phase 179]: Shell IA relabeling changed only visible group labels — Preserved nav ids, route hrefs, current atoms, data-testids, and destination order for adopter/bookmark stability.
- [Phase 179]: Home uses task-led job titles with existing workflow destinations — Matched Phase 179 IA while keeping Timeline, Coverage, Evidence, Redaction, Retention, Exports, row-history, and correlation workflows unchanged.
- [Phase 179]: Shared state grammar stays in existing UI and Unsupported helpers — Plan 179-02 normalized state, validation, unsupported, and export-denied copy without adding a copy registry, dependency, LiveComponent, route, or new capability.
- [Phase 179]: 179-03 kept actor, transaction, row-history, and coverage copy inside existing page modules. — No route, public API, dependency, LiveComponent, or capability was added.
- [Phase 179]: 179-03 uses covered for table status and need capture for remediation. — This preserves audit-readiness language without overclaiming complete timeline answers or proof that capture is complete.
- [Phase 179]: 179-04 keeps Timeline explanatory copy below filters, result status, investigation checks, export actions, saved views, and rows.
- [Phase 179]: 179-04 Timeline invalid-filter and unknown-table copy names the failed object and next action while preserving parser/audited-table details.
- [Phase 179]: 179-04 e2e assertions were aligned to current shell, retention modal, and seeded Timeline row-history contracts.
- [Phase 179]: Evidence/export copy now reserves proof-history language for append-only history/detail contexts while using Evidence for current state and handoff labels.
- [Phase 179]: Redaction LiveView preserves the shared Drift detected status-label contract while rendering Redaction drift detected as page-level governance copy.
- [Phase 179]: Retention destructive actions consistently name the retention window and permanent pruning consequence.
- [Phase 179]: Phase 179 stress copy evidence was added to existing story ids only; no stress story, ledger id, route, selector, density knob, capability, ledger row, or DESIGN-SYSTEM projection was added. — Preserves COPY-03 and D-17 stability while adding durable copy-state evidence for final Phase 179 terminology.
- [Phase 179]: The component matrix remains available for component/state/foundation stress stories, but page, footgun, and future-reserved screenshot targets stay bounded to preserve the Phase 178 ledger baselines. — Keeps ledger-owned screenshot baselines useful while avoiding screenshot churn from unrelated component stress content.
- [Phase 180]: 180-01: Use existing Playwright operator accessibility spec for rendered-state A11Y-01 proof; no axe scan or new dependency was added.
- [Phase 180]: 180-01: Use shared LiveView JS overlay helpers for focus entry/restoration where possible, with stress-route-only fixtures for missing rendered state coverage.
- [Phase 180]: 180-01: Classify examples/threadline_phoenix mix precommit demo seed failures as inherited/non-owned for this plan.
- [Phase 180]: [Phase 180-02]: APG guardrails stay implementation-specific: custom widgets get specific ARIA popup/relationship hooks, while native select/input/table behavior is asserted instead of role-inflated.
- [Phase 180]: [Phase 180-02]: Tabs and segmented controls use actual rendered selectors for target sizing and non-color selected-state cues; stale selector rules are removed.
- [Phase 180]: [Phase 180-02]: No dependencies, audit frameworks, public routes, public component APIs, or stress-route auth behavior were added.
- [Phase 180]: [Phase 180-03]: MOTION-01 guardrails stay in the existing style contract and operator-motion Playwright harness, preserving enabled press feedback while collapsing reduced-motion behavior without new dependencies.
- [Phase 180]: [Phase 180-04]: Replaced the manual screen-reader checkpoint with Playwright accessibility-tree snapshots and explicit proof limits; no real assistive-technology UAT is claimed.
- [Phase 180]: [Phase 180-04]: Dynamic E2E ports require LiveView origin checks to be disabled in Phoenix test config only; production origin behavior is unchanged.
- [Phase 180]: [Phase 180-04]: Screenshot regression guards now discover current `ticket_replies` seeded rows instead of stale #4521 correlation assumptions, and local desktop/mobile baselines were refreshed from current rendered output.
- [Phase 180]: [Phase 180-04]: Retention destructive modal tests must open the conditionally mounted modal before asserting or submitting `form[phx-submit=prune_now]`.
- [Phase 181]: Plan 01 keeps screenshot evidence tiered: partial Tier C PNGs are committed, failed cells are recorded with owners, and CI screenshot allowlist remains bounded. — This preserves D-181-07/D-181-08 while avoiding a full page x path x theme x viewport pixel matrix.
- [Phase 181]: Plan 01 adds a desktop-1024 responsive viewport row without changing operator routes, data-testids, capture/query/auth semantics, public APIs, or dependencies. — The new row extends the bounded rendered-slice matrix required by D-181-07 and records current stale Timeline discovery failures for repair.
- [Phase 181]: [181-02] 181-03 owns stale E2E/demo-seed discovery and copy assertion repair; Timeline/Coverage page polish remains deferred to 184/185. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: [181-02] 181-04 owns active source-test prose that still says RED today/RED until after the guarded behavior landed. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: [181-02] Local screenshot skips and stress bad-param strings are intentional guards/fixtures, not defects. — Recorded in 181-02-SUMMARY.md key-decisions.
- [Phase 181]: 181-03 replaced stale issue-number/correlation E2E contracts with current ticket_replies table-filter discovery, transaction href navigation, row-history redaction, and DELETE-row actor transaction checks. — Recorded in 181-03-SUMMARY.md after the targeted Playwright suite passed 18/18.
- [Phase 181]: 181-03 kept adjacent stale browser families outside the declared file contract as residual ledger ownership instead of editing out-of-scope files. — Plan 03 files were explicitly limited to operator.spec.ts, operator-screenshots.spec.ts, and 181-GUARD-REPAIR.md.
- [Phase 181-04]: Plan 181-04 repairs active source-test prose and failure messages while preserving executable assertions, route paths, feature gates, public APIs, and production source. — Plan scope is documentation/prose in tests and guard ledger; behavior remains unchanged.
- [Phase 181-05]: Route/export/stress/header boundaries are locked through source contracts rather than rendered UI redesign. — Plan 05 protects server route/auth/export and feature-gate invariants without changing operator IA or layout.
- [Phase 181-05]: Feature-gated nav group IDs are additive semantic hooks only. — Existing destination IDs, hrefs, copy, active-state semantics, and public component API remain unchanged.
- [Phase 181-05]: Root threadline continues to exclude PhoenixStorybook/Storybook and production story/stress routes. — Phase 182 owns example-app dev/test Storybook; root optional Phoenix boundaries stay intact.
- [Phase 181-06]: 181-06 leaves .planning/design-system-ledger.json, DESIGN-SYSTEM.md, stress fixtures, stress route source, and stress tests unchanged because the existing source-contract slice is green.
- [Phase 181-06]: The three bounded screenshot allowlist cells remain page.home.happy, page.timeline.empty, and footgun.transaction-page-left-push-desktop; broader screenshot freshness remains owned by 181-07 through 181-10.
- [Phase 181-baseline-audit-and-guard-repair]: Stress CI screenshots now read `.planning/design-system-ledger.json` `screenshot_allowlist.ci` directly instead of a separate hardcoded allowlist. — Bounded stress screenshot guard stays ledger-backed and matrix-bounded while local packet evidence remains outside CI baselines.
- [Phase 181-baseline-audit-and-guard-repair]: The selected happy/error/permission/boundary stress-state PNGs are local-only planning evidence, not CI `toHaveScreenshot` baselines. — D-181-07 needs Tier C evidence without expanding the accepted Tier B screenshot ratchet.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 found all existing operator-screenshot-regression desktop/mobile local PNG baselines current, with no accepted Plan 09 or Plan 10 PNG updates discovered.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 preserved the generic chromium local screenshot-regression skip as intentional platform-sensitive guard behavior rather than expanding CI coverage.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 08 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not local screenshot-regression or PNG baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 left all four Home/dense Timeline PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 did not run --update-snapshots; the bounded Home/dense Timeline subset passed against existing desktop/mobile local baselines.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 09 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not screenshot baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 left all six Row-history/Exports/Retention PNG baselines untouched because Plan 08 classified them as current committed local baselines with no accepted update.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 did not run --update-snapshots; the bounded Row-history/Exports/Retention subset passed against existing desktop/mobile local baselines.
- [Phase 181-baseline-audit-and-guard-repair]: Plan 10 re-recorded the example-app mix precommit residual as inherited demo-seed/walkthrough drift, not screenshot baseline fallout.
- [Phase 181-baseline-audit-and-guard-repair]: 181-11: Full CI remains red but classified; Phase 181 closes on targeted guard evidence plus residual ownership, not by relabeling red gates as green.
- [Phase 181-baseline-audit-and-guard-repair]: 181-11: The local Tier C screenshot packet is complete planning evidence and does not expand the CI screenshot allowlist.
- [Phase 182]: Plan 182-01 is RED-only by design: it locks executable contracts before package, route, story, or documentation implementation. — Phase 182 implementation is split across later plans, so this plan intentionally commits failing contracts first.
- [Phase 182]: Storybook browser coverage stays bounded to index plus representative primitive/form/state/overlay/data-display/group stories; no screenshot matrix or external visual regression service was added. — D-182-20 requires bounded browser smoke rather than broad screenshot or SaaS visual-regression coverage.
- [Phase 182]: Root optional-dependency hygiene remains protected by source contracts and mix verify.compile_no_optional. — The plan adds tests only and proves no root PhoenixStorybook dependency leakage occurred.
- [Phase 182-02]: PhoenixStorybook remains an example-app dev/test dependency only; production compiles through a no-op router macro fallback when the package is absent.
- [Phase 182-02]: The maintainer Storybook lane is mounted at /dev/storybook outside /audit and outside normal operator navigation.
- [Phase 182-03]: Core Storybook category files use PhoenixStorybook page stories to document multiple private UI functions without promoting a public component API. — Plan 03 covers category pages, not one public component story per exported API; private operator components remain private.
- [Phase 182-03]: Storybook fixtures expose static samples plus an explicit StressFixtures allowlist, with no database, dynamic atom, ledger mirror, or full stress registry navigation. — This preserves D-182-06 and D-182-07 while giving stories representative ugly data.
- [Phase 182-03]: Overlays, Data Display, Groups, and Patterns received index metadata now to satisfy the RED category spine while later plans still own their story content. — The existing RED story contract required the full top-level category spine before Plan 04 and Plan 05 add those stories.
- [Phase 182-04]: Storybook coverage remains curated component documentation; /audit/__stress remains the flow-level stress harness.
- [Phase 182-04]: Groups sample StressFixtures only through an explicit Storybook helper allowlist instead of mirroring the ledger or full registry.
- [Phase 182-04]: The light/system Playwright lane includes Storybook only through operator-storybook.spec.ts and asserts that bounded contract.
- [Phase 182]: Phase 182 closes on targeted Storybook/package/route/story/browser/stress/docs evidence while classifying inherited example demo-seed and broad-suite residuals as non-green. — Plan 05 verification found all targeted Phase 182 gates green, while mix precommit and mix ci.all still include pre-existing residuals outside the Storybook/docs scope.
- [Phase 182]: Storybook remains example-app dev/test maintainer component documentation; /audit/__stress remains the authenticated operator-flow stress harness. — Docs contracts and 182-VERIFICATION.md preserve the root optional dependency and production-route boundaries.
- [Phase 182]: No schema push task was required because Plan 05 modified only docs and planning verification artifacts. — No schema, migration, SQL trigger, config, struct field, CLI flag, decorator, or dataclass-style field changed.
- [Phase 183]: Plan 01 remains RED/proof-only: browser failures are actionable Plan 02 evidence, not production retuning scope. — 183-01 adds the browser perception proof before shell/Home implementation polish and the plan explicitly allows actionable browser failures.
- [Phase 183]: The Phase 183 supplement is admitted to the existing system/light lane rather than adding a new Playwright project or screenshot matrix. — The plan forbids screenshot matrix expansion and requires preserving the THREADLINE_E2E_THEME=system desktop-chromium-light lane.
- [Phase 183]: Plan 183-02 kept native mobile details/summary navigation but moved the single nav panel to a sibling so desktop rail visibility does not depend on closed-details internals. — Chromium keeps non-summary descendants hidden in closed details, which broke the Phase 183 desktop browser proof.
- [Phase 183]: Plan 183-02 forced example e2e compilation before browser runs so THREADLINE_E2E_THEME compile-time router gates match the current lane. — The system/light lane reused stale dark-compiled router artifacts until the runner used mix compile --force.
- [Phase 183]: Phase 183 closes as targeted PASS with classified residuals: dedicated source and browser evidence is green, broad command failures remain non-green and scoped.
- [Phase 183]: Generated light screenshot candidates from broad verification were treated as verification byproducts and not committed as baselines.
- [Phase 183]: No package, schema, public API, route, data-testid, or adjacent page content change was accepted during Phase 183 closeout.
- [Phase 184]: Timeline row-history links are emitted only for rows with exactly one nonblank scalar primary-key value; unsafe identities keep the transaction pivot only.
- [Phase 184]: Timeline export handoff remains canonical-query driven through FilterParams and ExportController rather than duplicating filter semantics in the UI.
- [Phase 184]: The Timeline command surface reports result facts once through the facts/filter summary; duplicate status copy and its dead selector were removed.
- [Phase 184]: Timeline empty states now distinguish first-run, filtered no-data, and future-window copy through private reason helpers instead of a single future-window boolean. — This preserves distinct operator meanings for no captured changes, no matches, and future windows without adding a new component family.
- [Phase 184]: Timeline rows expose full table, actor, correlation, and safe row-id values for copy/title use while preserving transaction and row-history pivots. — Full values must remain available under long real data; direct row history remains gated by the existing safe routeable identity helper.
- [Phase 184]: No fake Timeline stale branch was added; stale/last-good proof remains with shared UI.stale_banner/data-state primitives because Timeline has no dedicated stale assign. — The plan explicitly prohibited fabricating Timeline-only stale states for coverage when no real branch exists.
- [Phase 184-03]: Use a narrow Timeline-only Playwright proof for required viewport/keyboard/copy/export/theme/reduced-motion coverage instead of broad screenshot baselines.
- [Phase 184-03]: Create browser proof correlation data through existing authenticated /api/posts setup rather than relying on stale demo seed correlations.
- [Phase 184-03]: Classify broad-suite residuals honestly while treating targeted Phase 184 source and browser gates as the closeout authority.
- [Phase 185]: Coverage now answers readiness through one selected-schema verdict and keeps table rows as triage/action detail. — Phase 185 COV-01/COV-02 required deleting repeated readiness signals while preserving row actions.
- [Phase 185]: Phase 185 browser proof stays narrow in the existing light/system lane; non-public schema link truth remains owned by deterministic LiveViewTest setup. — The plan prohibited broad screenshot matrices and had no deterministic example non-public schema fixture.
- [Phase 187]: DOC-01 source truth follows the current runtime server-posted theme picker, not older host-only theme prose. — Plan 187-01 repaired the operator guide and doc contracts against router, surface header, theme controller, and auth source truth.
- [Phase 187]: Storybook remains example-app dev/test maintainer tooling; /audit/__stress remains authenticated stress proof, not production public component documentation. — Plan 187-01 preserved optional dependency, production exclusion, private component, and stress route boundaries in docs and doc contracts.
- [Phase 187]: Plan 187-02 closed A11Y-01/A11Y-02 proof gaps with focused test-only coverage; no private UI or CSS repair was needed. — The new source/browser assertions passed against existing product behavior after proof-specific locator corrections.
- [Phase 187]: Plan 187-02 made no MOTION-01 source changes because existing source and browser-computed proof already covered the Phase 187 contract. — style_contract_test.exs and operator-motion.spec.ts passed unchanged for token, keyframe, transition, and reduced-motion requirements.
- [Phase 187]: Phase 187 closeout treats targeted source/browser/stress proof as green while preserving standalone screenshot and broad CI failures as classified residuals; no real screen-reader certification or screenshot stability claim is made from non-green evidence. — CLOSE-01 requires exact evidence, residual ownership, and proof limits rather than assertion-only closure.
- [Phase 188]: 188-01 queued export worker replay reuses FilterParams.parse/1 instead of a second parser — This preserves URL-shaped string-keyed ExportJob.query_params while ensuring from/to are DateTime filters before Threadline.Query runs and invalid params fail closed.
- [Phase 188]: .tl-copy uses explicit transition-property source governance — 188-02 replaced token-only shorthand with color, border-color, background-color, and box-shadow declarations, and StyleContractTest now rejects token-only transition shorthand.
- [Phase 188]: Phase 188 closeout used focused ExUnit/source evidence plus equivalent audit classification; no browser or screenshot proof was added because source contracts covered .tl-copy.
- [Phase 188]: Phase 188 preserves legacy broad CI, screenshot, Hex auth/advisory, and older Nyquist residuals as explicit audit residuals instead of relabeling them green.
- [Phase 189]: Phase 189 routes custom storage-schema proof and fixes to Phase 190 based on public docs plus fixed-prefix source evidence.
- [Phase 189]: Phase 189 treats screenshot, external pilot, and host staging claims as proof-boundary residuals instead of implementation scope.
- [Phase 190]: [190-01]: Generated install migration SQL uses Threadline.StorageSchema quoted identifiers for every validated storage-schema table, function, and drop/index reference touched by SCHEMA-03.
- [Phase 190]: [190-01]: Adopter docs now show storage_schema: "audit" before mix threadline.install and state that generated migration files freeze the configured schema name.
- [Phase 190]: [190-02] Threadline-owned Ecto schemas now rely on Repo prefix options instead of fixed @schema_prefix attributes. — SCHEMA-02 requires configurable storage schemas not to silently read from or write to hardcoded threadline.
- [Phase 190]: [190-02] Storage-schema test support is explicit and test-only; it does not add a production fallback or Repo hook. — Tests should make omitted prefix plumbing visible while later Phase 190 plans wire production Repo operations.
- [Phase 190]: [190-03]: Treat the per-transaction storage_schema option as authoritative for core audit writes, action linkage, audit-transaction lookup, and captured-change metadata.
- [Phase 190]: [190-03]: Query and investigation preloads must pass resolved storage options explicitly so association reads cannot fall back to the default threadline schema.
- [Phase 190]: [190-04]: Queued export and cleanup runtimes resolve storage_schema once per run/state instead of re-reading global config for each Repo operation.
- [Phase 190]: [190-04]: Export downloads resolve configured storage_schema before lookup and preserve actor authorization after the prefix-scoped fetch.
- [Phase 190]: [190-05]: Retention direct runs and pruner runtimes resolve storage_schema from explicit opts with global config as the default. — This preserves the Phase 190 global configured storage contract while making selected-storage sentinel proof deterministic for retention/pruner paths.
- [Phase 190]: [190-05]: Retention and pruner tests use audit/threadline dual-storage sentinels for destructive governance paths. — SCHEMA-01 requires wrong-prefix deletes, counts, inserts, and updates to be caught by tests, not inferred from source strings.
- [Phase 190]: [190-07]: Malformed host table identifiers now fail before SQL generation. — Empty or ambiguous dot segments could collapse into valid-looking identifiers and weaken host-schema trigger confidence.
- [Phase 190]: [190-07]: Continuity readiness treats selected support schema values as host table identity only. — `support.tickets` and `schema: "support"` select the host table for readiness checks without changing Threadline storage-schema reads.
- [Phase 190-08]: Selected redaction schema is host-schema only — Policy CLI and LiveView validate --schema/?schema with CoverageSchemas and pass it only to redaction catalog inspection; Threadline-owned storage_schema remains governed separately by repo opts.
- [Phase 190]: Timeline renders table_schema as host schema so operators do not confuse audited host schemas with Threadline storage_schema.
- [Phase 190]: Non-public row-history links require exact schema-qualified schemas keys such as support.tickets; public rows keep bare-table shorthand.
- [191-03]: ADOPT-01 install/version reconciliation — seven install pins flipped to three-segment ~> 0.9.0 (co-committed with four guard tests, no CI/release reddening); evaluating-threadline.md false 0.6.0 SSOT corrected to 0.9.0 + release-please marker/extra-files wiring (historical lines preserved); version_truth_doc_contract_test derives Families A/B/C from mix.exs @version and is registered in verify.doc_contract. Pre-existing v1_23_charter failure left deferred (charter truth out of this plan's task scope).
- [Phase ?]: [195-01]: verify.ui_critique is local-only (excluded from ci.all, exits 0 when ANTHROPIC_API_KEY absent, RUNNER-04). verify.critic_trust is pure-Elixir in ci.all before verify.mechanical. All 6 critic lenses seed validated:false. critic-scores/ tree is gitignored; .planning/golden/ is committed oracle.
- [Phase 198]: [198-38]: Repo.checkout/2 chosen over pg_advisory_xact_lock/Repo.transaction/2 to pin the demo lock critical section — the guarded body issues many independent per-seed Repo.transaction/1 calls by design and an outer transaction would collapse them.
- [Phase 198]: [198-38]: promote — Demo.Seed no longer maintains its own copy of the lock guard trio; Demo.Seed.run/0 delegates to Reset.with_demo_lock/1, eliminating the two-copies drift that produced CR-01.
- [Phase 198]: [198-39]: option-a — maintainer accepted GREEN-07/roadmap SC3 as permanently Pending for v1.41 at a blocking checkpoint:decision; verify-capture and verify-example-browser stay red by construction under D-39 for the whole milestone; no gate narrowed, no baseline regenerated. See 198-39-DECISION.md.
- [Phase 198]: The successful PR run supersedes Round 6's red-lane cause but does not close GREEN-07's separate origin/main exact-ancestry clause. — The run is pinned to an immutable branch subject while final local HEAD includes later mandatory GSD commits.
- [Phase 198]: No remote or ruleset mutation is attempted because mandatory evidence and summary commits postdate any finite in-plan push. — A pre-closeout ref update cannot contain commits that do not yet exist.
- [Phase 198]: GREEN-07 remains Pending because exact ancestry fails first and the canonical exact-SHA main run also concludes failure.
- [Phase 198]: GREEN-08 is re-proved from two identical complete editable-field ruleset digests plus active enforcement, no bypass actors, and one byte-exact required context.
- [Phase 198]: No remote or ruleset mutation is authorized; any future mutation requires a fresh blocking-human maintainer checkpoint.
- [Phase 198]: GREEN-07 remains Pending on exact ancestry and exact-main CI; PR #34 is branch-only evidence. — Preserve the requirement own predicate and the maintainer selected option-a disposition.
- [Phase 198]: GREEN-08 remains Complete for the exact required-context contract while roadmap criterion 4 remains partial. — Ruleset 21702804 is correct, but PR #26 remains BLOCKED downstream of GREEN-07.
- [Phase 198]: Phase 198 freezes its exact evidence compatibility contract while Phase 199 retains the generalized classifier. — Keeps gap closure repository-portable without absorbing the next phase scope.
- [Phase 198]: Operator login redirects must match BASE_URL scheme, host, effective port, and exact path. — A login-looking cross-origin Location is not proof that the local operator mount exists.
- [Phase 198]: Evidence subjects, not copied narrative prose, are the primary keys for policy joins.
- [Phase 198]: The GitHub boundary accepts only list-main-runs and view-run-jobs symbolic operations and constructs every argv token internally.
- [Phase 198]: [198-50] Treat the opt-in obscurer as proof of current assertion sensitivity, not proof of the historical failure's cause.
- [Phase 198]: [198-50] Keep the red-control environment read inside the single named scenario and reject unknown non-empty values explicitly.
- [Phase 198]: [198-50] Persist synthetic DOM identifiers and geometry only; exclude field values, cookies, headers, credentials, and environment data.
- [Phase 198]: Plan 198-51: maintainer selected abort verbatim; no branch, PR, tag, main, ruleset, or protection mutation authority was granted.
- [Phase 198]: Plan 198-52 must not execute: six remote ci/198-* refs exist while its decision authority covers only three and its final predicate requires the complete namespace empty.
- [Phase 198]: A preservation subject is keyed by side plus full SHA, so same-name local and origin refs never collapse. — Distinct handles require collision-free archive and restore paths.
- [Phase 198]: Plan 52 remains preserved but superseded; round-11 production evidence grants no mutation authority. — Fresh exact-subject authority is deferred to Plan 54.
- [Phase 198]: The maintainer selected retire verbatim for the exact nine round-11 side/SHA subjects bound to inventory digest 88888854b44111835d753261eb15332a7c98fae7922d65d0d46e6fc5423a4655.
- [Phase 198]: Plan 54 grants authority only to Plan 55's preservation-first sequence; Plan 54 performed no external mutation.
- [Phase 198]: Every round-11 side/SHA preservation subject has a verified local annotated tag, matching origin peeled object, and D-31 register join before its mutable handle was retired.
- [Phase 198]: GREEN-12 is Complete from empty live ci/198-* namespaces; GREEN-07 remains Pending and protected controls remain unchanged.
- [Phase 198]: Phase 198's audited summary set ends at Plan 59; Plan 60 is the sole non-recursive terminal certification exception.
- [Phase 198]: Normal summary validation accepts the exact present 48-59 subset; explicit final mode requires every audited summary 01-59.
- [Phase 198]: Production ref-disposition authority stages reject fixture adapters and use bounded fresh observations; synthetic lifecycle proof is fixture-* only.
- [Phase 198]: Completed round-11 receipts remain immutable historical evidence and are not retroactively upgraded into argv or timestamp proof.
- [Phase 198]: Plan 198-58: four mechanically knowable prohibitions close only from named passing tests; the historical command-method prohibition remains pending judgment.
- [Phase 198]: Plan 198-58: T-198-55-03 remains irrecoverable, below threshold, open, and not accepted.
- [Phase 198]: The recorded cannot-attest outcome leaves P-198-55-01 pending and is neither new mutation authority nor risk acceptance.
- [Phase 198]: T-198-55-03 remains open below threshold because no missing per-operation receipt fields were supplied.
- [Phase 198]: Phase 198 terminal certification audits summaries 01-59 while Plan 60 remains the sole tested non-recursive summary exception.
- [Phase 198]: Terminal evidence preserves T-198-55-03 open below threshold and GREEN-07 accepted-Pending; canonical re-audits remain orchestrator-owned.
- [Phase 198]: Every Phase-198 terminal source is authorized only by exact certified_head equality plus certified_head:path blob identity and digest.
- [Phase 198]: Classic protection communicates only absent or present; all other HTTP, transport, malformed, or unknown states fail closed.
- [Phase 198]: T-198-55-02 and T-198-55-03 remain open and not accepted; GREEN-07 remains accepted-Pending.
- [Phase 198]: [198-62] Legacy receipt compatibility requires exact canonical Round-11 paths, blobs, byte digests, completed state, and 41-row joins; every failed predicate selects strict validation.
- [Phase 198]: [198-62] Plan 62 is the sole mechanically validated non-recursive summary exception after auditing summaries 01-61 exactly once.
- [Phase 198]: [198-62] T-198-55-02 and T-198-55-03 remain open and not accepted; T-198-57-04 is absent from terminal open findings; GREEN-07 remains accepted-Pending.
- [Phase 198]: The maintainer accepted only T-198-55-02's residual historical argv/non-force proof uncertainty with literal signer YOUR_NAME; no evidence or mitigation is claimed.
- [Phase 198]: Plan 63's decline remains immutable history, while canonical security retains sole authority to change the threat verdict before phase verification runs.
- [Phase 198]: Summaries 01-61 remain the immutable audited-final set; Plan 62 remains the sole terminal-certification exception.
- [Phase 198]: Summaries 63-65 require exact content-bound manifest records; Plan 66 is an explicit non-terminal final-mode repair summary.
- [Phase 198]: Plan 66 restores only current-tree GREEN-04 determinism; GREEN-07 remains accepted-Pending and security dispositions remain unchanged.
- [Phase 199]: [199-01] MechanicalChecker owns evaluation only; repository fixture discovery remains at test and tooling edges.
- [Phase 199]: [199-01] Invalid corpora return distinct tagged errors with expanded paths, repository-only=false, and one recovery call.
- [Phase 199]: Private Mix-task overrides resolve within the loaded repository and generated critic scores remain separate from immutable evidence roots. — Keeps repository discovery at the maintainer edge and prevents path traversal, symlink, prefix, and root-alias writes.
- [Phase 199]: Canonical critic fixture replacement uses exclusive sibling temps with sync, close-before-rename, and unconditional cleanup. — Preserves original bytes on failure while making successful regeneration atomic and review-explicit.
- [Phase 199]: The ESM adapter owns frozen deterministic roots; callers may override fixture and output roots only through explicit CLI flags. — Keeps repository discovery at the TypeScript execution edge and avoids ambient environment service location.
- [Phase 199]: Containment rejects traversal and every symlink component, canonicalizes the nearest existing parent, and compares with path.relative. — Prevents traversal, prefix-confusion, and alias escapes for both existing and prospective targets.
- [Phase 199]: Canonical TypeScript replacement uses an exclusive sibling temp, file sync, close-before-rename, and unconditional cleanup. — Preserves original bytes and prevents temp leakage on forced failure.
- [Phase 199]: Manifest membership comes only from git ls-files; filesystem presence alone never grants evidence authority.
- [Phase 199]: Generated critic-score bytes remain invisible to integrity manifests until explicitly promoted into the Git index.
- [Phase 199]: Active citation detection is derived from executable/current-document classes; a historical live-input citation is allowed only when the same artifact has an exact Phase 199 supersession marker.
- [Phase 199]: Git history plus full recovery commits replaces archive copies or tombstones for all four removed artifacts.
- [Phase 199]: [199-10] PLT policy ignores only .plt and .plt.hash files beneath the anchored .dialyzer producer root.
- [Phase 199]: [199-10] Root formatter delegates bench and examples/threadline_phoenix while child configs retain imports and nested migration ownership.
- [Phase 199]: [199-10] Newly owned benchmark entrypoints are formatted in the same change that adds them to the required formatter surface.
- [Phase 199]: [199-12] Derive planning-history scan inputs from tracked ExUnit, Mix-task, mix.exs, and workflow sources; exclude only the scanner's own synthetic-control file.
- [Phase 199]: [199-12] Keep D-01 operator evidence corpus migration separately owned by Plans 199-02 through 199-08 while blocking executable planning-receipt reads now.
- [Phase 199]: [199-12] Retain live CI recorder, workflow, and artifact invariants while retiring completed planning-prose receipt assertions.
- [Phase 199]: [199-02] StressLive accepts only non-empty decoded ledger-entry maps under exact session key threadline_stress_ledger_entries.
- [Phase 199]: [199-02] ExUnit corpus paths descend from one test-support root that Plan 199-08 can flip atomically.
- [Phase 199]: [199-02] Refute partition checks pass explicit empty mechanical floors because they exercise absolute ceilings only.
- [Phase 199]: Plan 199-05: Every critic consumer resolves immutable and generated evidence through the shared TypeScript adapter; explicit root flags activate centrally.
- [Phase 199]: Plan 199-05: Routine critic:check is deterministic and no-paid while explicit scoring commands retain paid critic behavior.
- [Phase 199]: Plan 199-05: Generated score and cache identifiers are rejected rather than sanitized, preventing traversal and collision aliases.
- [Phase 199]: Capture consumers derive immutable corpus and e2e artifact locations from the shared TypeScript adapter, containing every dynamic output segment.
- [Phase 199]: Playwright owns contained screenshot writes; direct text, JSON, and ARIA evidence replacement uses the shared atomic writer.
- [Phase 199]: Reviewed stress snapshots remain under tests while optional generated stress packets are confined to e2e/artifacts.
- [Phase 199]: [199-11] Cleanup snapshots canonical parent/child lstat identities and rejects every live Git worktree root before removal.
- [Phase 199]: [199-11] Clean-checkout verification detaches a no-local clone at exact committed HEAD and keeps index/untracked state out of the proof.
- [Phase 199]: The immutable evidence root is test/fixtures/operator_surface; generated critic output remains ignored and outside manifest authority.
- [Phase 199]: Live evidence joins use mechanical-floor base IDs with explicit variant matching and the documented veto-ordering exception.
- [Phase 199]: Hex privacy is proven from the unpacked artifact file list rather than inferred solely from configuration.
- [Phase 199]: Plan 199-13 halted on the measured 22-file Dialyzer warning-origin set; the 14-file cap was not reinterpreted or weakened.
- [Phase 199]: No Dialyzer suppression or ignore ceiling is approved until the sealed warning set is re-sliced and individually dispositioned.
- [Phase 199]: Plan 199-15: Hash only normalized raw warnings inside each fixture's authorized origins so disjoint later remediation does not invalidate completed slices.
- [Phase 199]: Plan 199-15: Require exact warning-origin coverage and reject malformed, duplicate, unauthorized, unrecorded, or stale residue evidence.
- [Phase 199]: Plan 199-15: Describe unconditional Mix.raise/1 helpers with truthful private no_return() specs without changing runtime behavior.
- [Phase 199]: Use concrete AuditChange and AuditTransaction struct types where remote schema modules do not export t/0 types.
- [Phase 199]: Thread the validated continuity schema forward and match :code.priv_dir/1's charlist/error-tuple results explicitly.
- [Phase 199]: Normalize CSV and NDJSON rows to binary chunks so serialization contracts remain concrete without widening public APIs to streams.
- [Phase 199]: Log export close and removal failures without replacing the established primary result.
- [Phase 199]: Use concrete source-tree structs where provider modules do not export t/0.
- [Phase 199]: Keep Plug remote-address formatting tuple-only and cover both IPv4 and IPv6.
- [Phase 199]: Require every redaction parser reason to have an explicit operator-facing presentation clause.
- [Phase 199]: Use normalized binary inputs directly in private path, email, and URL presentation helpers.
- [Phase 199]: Consume LiveView timer results explicitly while preserving intervals, message names, and scheduling count.
- [Phase 199]: Match Timeline export counts and transaction value tokens only across result shapes guaranteed by their callees.
- [Phase 199]: Keep .dialyzer_ignore.exs empty and the committed ceiling at zero because every sealed warning is fixed.
- [Phase 199]: Use only the five source fixtures as historical authority; the executable contract reads no planning artifact.
- [Phase 199]: Treat unsealed warnings, origin drift, broad suppressions, and unused filters as fail-closed conditions.
- [Phase 199]: Plan 199-14: Set verify-dialyzer timeout-minutes to 9 from ceil(252-second cold whole-job time × 2.0 / 60).
- [Phase 199]: Plan 199-14: Only an exact PLT primary-key match is a cache hit; same-toolchain partial restores rebuild before analysis.
- [Phase 199]: Plan 199-14: Remove the temporary phase-branch push trigger immediately after immutable miss/hit evidence collection.
- [Phase 199]: Plan 199-21 certifies only an exact committed SHA in a no-local clone with .planning physically absent.
- [Phase 199]: Planning quarantine restoration always precedes recursive cleanup delegated solely to bin/safe-temp-tree.
- [Phase 199]: The planning-free aggregate preserves the committed dev-Dialyzer and desktop/mobile Chromium CI topology.
- [Phase 200]: Public-surface gates derive inventories from AST, compiled docs, Mix configuration, and the unpacked Hex artifact; classifications are exact, disjoint, and non-vacuous. — Prevents accidental compatibility promises and vacuous release gates.
- [Phase 200]: Later Phase 200 plans own bounded red tags; full public-document and archive scans remain final-only aggregates. — Allows independently reviewable slices without weakening the complete consumer artifact gate.
- [Phase 200]: The optional path/1 regression captures UndefinedFunctionError as an assertion value. — Proves the intended missing-callback behavior gap rather than accepting a fixture or load crash as RED.
- [Phase 200]: All fourteen literal :threadline runtime keys are the supported application-environment contract; adapter-module options remain a distinct dynamic key class.
- [Phase 200]: Host projects receive threadline.* Mix tasks, while this repository's verify.*, test.*, and ci.all aliases remain repository-local.
- [Phase 200]: Confirmed :storage_adapter as a supported extension point with binary content as the portable put/2 contract and Local file-path detection as an adapter-specific convenience. — Implements the already-locked D-02 compatibility commitment without a new callback or configuration namespace.
- [Phase 200]: Optional storage path/1 dispatch checks adapter capability and otherwise reuses the existing download_url/2 fallback. — Keeps optional callbacks honest while preserving adapter options, export expiry, authorization, and delivery outcomes.
- [Phase 200]: Use six user-role ExDoc module groups with critic tooling hidden and exactly ten adopter Mix tasks. — Keeps documentation compatibility aligned with supported call paths, return types, and extension roles.
- [Phase 200]: Link repository-only project resources as version-derived ExDoc URL extras outside package.files. — Preserves README-led native HexDocs without expanding the consumer archive or adding a custom docs site.
- [Phase 200]: Rename the planning-specific browser alias to verify.operator_component_contracts with no compatibility alias. — A durable purpose-based name removes release chronology while preserving the same targeted browser behavior.
- [Phase 200]: Style, UI, and Capture.Migration are implementation-only; Evidence.Subject and Mix.Tasks.Threadline.Gen.Triggers remain public because they are supported data and task contracts. — Public documentation follows supported adopter seams rather than raw Elixir callability.
- [Phase 200]: RedactionPolicy, TriggerCaptureConfig, TriggerSQL, and CleanupTask are internal plumbing. — Their call sites are Threadline-owned tasks, migrations, supervision, tests, and benchmarks; no supported direct adopter seam exists.
- [Phase 200]: Plan 200-05 changed documentation visibility only and preserved functions, returned structs, runtime behavior, and supported entrypoints. — The public-surface audit must not widen or break the runtime API.
- [Phase 200]: Governance persistence records and migration generators are internal documentation surfaces; supported facades and return values remain public.
- [Phase 200]: Coverage, redaction, retention scheduling, theme routing, and font helpers remain hidden behind public tasks, facades, configuration, and router contracts.
- [Phase 200]: [200-07] Export delivery and coverage modules are internal router/rendering plumbing; Router and Auth remain the supported public seams.
- [Phase 200]: [200-07] Router-installed export, session, and theme plugs are hidden without changing authorization, session, route, telemetry, or response behavior.
- [Phase 200]: [200-07] Public operator documentation belongs on Router and Auth rather than generated controllers, hooks, state carriers, or plugs.
- [Phase 200]: [200-08] Filename, FilterParams, Scope, Script, and SurfaceHeader are internal operator helpers; Presentation remains hidden and Router remains the supported public mount contract.
- [Phase 200]: [200-08] Exact module visibility derives from compiled packaged lib/ sources, excluding test-support modules absent from HexDocs.
- [Phase 200]: [200-08] All 23 modules documented in 0.9 and now hidden are named in the changelog; visibility changes do not alter runtime callability.
- [Phase 200]: Plan 200-16: Stress provenance uses baseline, page-state, data-display, refute-twin, and graded-ladder cohort names instead of numeric implementation chronology.
- [Phase 200]: Plan 200-16: Fixture and ledger provenance share origin_cohort and reserved_for_cohort with exact round-trip coverage.
- [Phase 200]: Plan 200-16: Stress copy cleanup preserves existing DOM structure, classes, styles, routes, and behavior.
- [Phase 200]: Plan 200-17: Each form-oriented LiveView explains its form capability as a current page invariant beside the persisted module attribute.
- [Phase 200]: Plan 200-17: Coverage and redaction name their schema-selector behavior directly; actor, evidence, and exports remain explicitly formless.
- [Phase 200]: Plan 200-17: Export history documents its recent-only cap as a product fact while retaining the dynamic default limit and rendered count.
- [Phase 200]: Plan 200-12: Integration docs name supported public facades and observable outcomes, not hidden implementation modules.
- [Phase 200]: Plan 200-12: Repository-local external resources resolve as links without becoming nodes in the exact 18-guide graph.
- [Phase 200]: Plan 200-12: Package exactly the two theme-aware README logos and copy them through native ExDoc assets.
- [Phase 200]: Ordinary contributors see the complete issue-to-PR path before specialized test and maintainer reference material.
- [Phase 200]: Missing audit table guidance explains the local-state cause and delegates recovery commands to Local Docker DX.
- [Phase 200]: Generated PostgreSQL triggers installed through host-owned Ecto migrations are the shipped capture boundary.
- [Phase 201]: Canonical receipts mount real routes, fix time-dependent inputs, normalize only nondeterministic CSRF values, and otherwise preserve meaningful structure.
- [Phase 201]: Reference comparison requires exact sorted path identity before any per-path byte digest comparison.
- [Phase 201]: Shell and Home browser coverage uses existing form IDs, accessible labels, roles, and visible hierarchy instead of roadmap taxonomy attributes.
- [Phase 201]: Start browser consumers use existing forms, accessible labels, roles, and visible outcomes; no replacement test IDs or provenance hooks were added.
- [Phase 201]: The focused Start contract rejects planning attributes only after proving both lookup controls remain present and operable.
- [Phase 201]: Existing export-context task IDs and the accessible Carry to Exports link express the complete behavior contract without replacement provenance metadata.
- [Phase 201]: The shared earned-flow browser journey uses roles, visible names, routes, and existing product test IDs for both this cohort and the later Row History/Timeline cohort.
- [Phase 201]: [201-04] Validate exact sorted identity for all seven canonical renders before accepting an empty provenance-offender set.
- [Phase 201]: [201-04] Preserve Row History and Timeline through existing semantic anchors without replacement provenance hooks.
- [Phase 202]: Storage-schema default flipped from "threadline" to "public": 0.10.0 is non-breaking for the entire pre-0.10 adopter population, and a dedicated schema becomes an explicit opt-in steered by mix threadline.install and the getting-started guide. — Threadline cannot detect which schema an existing install put its audit tables in, so the default must be the one already true for installs that exist. Proven by HexEvaluator.LegacyPublicSchemaTest, which installs a packaged build of this tree into a fixture that sets no storage_schema key.
- [Phase 202]: The hex evaluator resolves :threadline from a per-run local rehearsal registry built from this tree's own mix hex.build tarball, with hexpm reserved for the published mode set by the release workflow. — The fixture previously pinned threadline ~> 0.9.0 from hexpm with a committed lock, so it re-proved the last published release instead of the tree under test - a pre-publish gate resting on a post-publish fact. bin/with-rehearsal-registry closes that; the lock is now untracked and gitignored.
- [Phase 202]: Install pins are owned by mix release.pins alone; release automation is test-forbidden from ever owning a pin line
- [Phase 202]: Maintainer-only tooling (11 files, 4706 lines) is excluded from the Hex package via exclude_patterns, proven against the unpacked tarball rather than the config
- [Phase 202]: release-please's changelog-path now names CHANGELOG-GENERATED.md; CHANGELOG.md is human-owned and is the file shipped in the tarball
- [Phase 202]: The 0.10.0 changelog entry ships the complete 25-module undocumented list, not the folded 23 — the two sets were measured, not assumed
- [Phase 202]: The stale hex-evaluator prose stays deferred: the false sentences are 2 of the 6 install-pin sites, so the fix is release-tooling work
- [Phase 203]: 203-01: Query.Scope/FilterParams moved to :module_visibility_domain_tail; released CHANGELOG kept verbatim via explicit @renamed_modules register in public_surface_contract_test
- [Phase 203]: GATE-04: zero compile-connected xref cycles + zero no_warn_undefined; runtime AuditTransaction<->AuditAction edge kept (D-18); mix verify.xref_cycles in ci.all and CI verify-test (both lanes)
- [Phase 203]: 203-03: AliasUsage in lib/ and contract tests paid down to 0 as 22 single-file refactor commits; timeline_live.ex and copy_contract_test.exs pre-existing AliasOrder absorbed (Plans 06/07 each expect one fewer)
- [Phase 203]: 203-04: AliasUsage outside test/threadline/operator_surface/ paid to 0 (116 findings, 14 files, 7 directory-batched refactor commits); Threadline.ExportQueue.Oban aliased as ObanAdapter because bare Oban is the real Oban module in oban_test
- [Phase 203]: 203-05: AliasUsage paid to 0 tree-wide (last 187 findings, 20 operator_surface test files, 3 directory-batched refactor commits); no as: needed; StressRouter alias for Code.compile_quoted routers lives in the enclosing module because quote hygiene blocks an inner alias
- [Phase 203]: 203-06 D-09: retention.ex MissedMetadataKeyInLoggerConfig resolved by .credo.exs metadata_keys: param (Plan 10), never by config/*.exs Logger config
- [Phase 203]: 203-07: StringSigils fixes use ~s with an absent delimiter (never ~S), byte-equality proven by evaluation; GATE-05 stale-location half pinned by source_comment_location_contract_test.exs, requirement checkbox left for Plan 10 (moduledoc delta)
- [Phase 203]: D-31: per-site structural-debt line is '# Structural debt: <reason>' — no phase number or requirement ID in packaged source; Phase 204/STRUCT-07 named only in the test-resident register
- [Phase 203]: 203-09: Credo structural register pinned in source (credo_config_contract_test.exs) at Nesting 26 / CyclomaticComplexity 16 / ceiling 42 / historical max 46, exact equality, successor Phase 204 / STRUCT-07; GATE-02 checkbox left for Plan 10 (Logger finding still open)
- [Phase 203]: 203-10: .credo.exs is credo 1.7.18 scaffolding + 3 extra deltas, disabled: []; Logger finding resolved via metadata_keys param (D-09)
- [Phase 204]: 204-01: CSS byte lock pins golden c7baf51e (119,508 B) and full render b10d6a2c (212,633 B); never re-pin during the phase
- [Phase 204]: 204-01: size gate seeded exact (7 files, 12 functions, 42 banner lines in 7 files); each extraction edits the maps in the same commit
- [Phase 204]: 204-02: ci.all runs test files once (verify.test); hand-listed doc-contract alias deleted; runtime alias-tree guard; bump rehearsal derives 33 doc-contract files by filename (floor 30)
- [Phase 204]: 204-03: <style> tags live in the Elixir concatenation; segment bytes are the golden minus those tags (byte-identical first try)
- [Phase 204]: 204-03: browser-lane gate is the known-8 invariant (326 passed / 8 known / 16 skipped today), not the stale 82-passed literal
- [Phase 204]: 204-04: MechanicalChecker pinned constants stay in the parent and reach its six siblings as argument maps; only unpinned constants moved
- [Phase 204]: 204-04: Governance migration pinned by sha256+bytes under the library default (public) and AuditLog schemas before the split
- [Phase 204]: 204-04: Query.Cursors shares the Query.Scope alias line so no recorded Dialyzer coordinate above the moved code shifts
- [Phase 204]: 204-05: desktop-only lost-input browser failures (Task 2: screenshots:90, timeline:583; Task 3: accessibility:620 focus) were flakes, each cleared by one unchanged orchestrator re-run at exactly 326/8/16
- [Phase 204]: 204-06: ui.ex retired into UI.Form via git mv; six @moduledoc false UI families; cross-family shell mount via <Overlay.reconnect_banner /> alias, never import
- [Phase 204]: 204-07: all 15 non-surface lib register sites drained in place (no per-site fallback); register 38 -> 23 (Nesting 17, CyclomaticComplexity 6)
- [Phase 204]: 204-08: LiveView siblings live under live/<page>/; per-page shell, formless, and doc pins read them via Threadline.Test.SourceFamily; sibling components declare attrs for exactly the assigns they read

### Blockers

-

- Phase 202 Plan 01 Task 1 was a one-way checkpoint:decision (storage-schema default flip) that AUTO-SELECTED under mode:yolo + auto_advance, with no live maintainer confirmation. Its own acceptance criterion required explicit maintainer confirmation. The underlying D-01 decision is recorded in 202-CONTEXT.md, but a maintainer should re-confirm the flip before the publish gate - hex.pm has no unpublish beyond ~1 hour.

## Session Continuity

**Last session:** 2026-09-23T23:21:30.098Z
**Stopped at:** Completed 204-08-PLAN.md
**Resume file:** None

- **Milestone closeout (2026-05-29):** v1.29 archived; tag `v1.29`; REQUIREMENTS.md removed for fresh next milestone.
- **130.1-02 (2026-05-29):** 130-VALIDATION superseded footnote; Nyquist waivers for 128/129; 130.1-VERIFICATION passed; `mix ci.all` green (744+61 tests).
- **Milestone closeout (2026-06-14):** v1.36 Operator Surface Light Mode archived (ROADMAP + REQUIREMENTS + AUDIT under `milestones/v1.36-*`), PROJECT.md evolved, tag `v1.36`, REQUIREMENTS.md removed for fresh next milestone. Finding F1 resolved — entangled `style.ex` light source committed (`b9f8fc1`); suite green at 912 tests. 6 items acknowledged-deferred (see Deferred Items).
- **175-02 (2026-06-17):** CSP-proof operator shell + runtime theme picker. Removed all 3 inline handlers; rebuilt picker as native radios + Apply button + `:has(:checked)` cue; native `<details>[open]` nav; scroll-padding-top/overscroll/100svh hardening; router doc corrected; theme-toggle ban lifted for a positive CSP guard. Plan-01 CSP RED target now GREEN (9 RED -> 8 RED Wave-0 targets remaining for Plans 03/04). Commits `b0a8c9c`, `25a582d`. Backend untouched (D-09); brand-token parity green.
- **175-03 (2026-06-17):** Internal `UI.page_header/1` + drill-down breadcrumbs. Built the one-`<h1>` page header (reusing existing CSS, zero new token, no public API), adopted it across the operator pages, threaded `[Timeline > …]` location breadcrumbs under `<nav aria-label="Breadcrumb">` into the 3 drill-down pages, relabeled away the bespoke "Investigation path" landmark, and set drill-down `current={nil}` so the single `aria-current="page"` stays on a nav link only. Re-pointed the D-02 doc-contract back-link assertions to the new D-13 breadcrumb root. Both NAV-01 Wave-0 RED targets GREEN; only the 4 Plan-04 PagerTest RED targets remain. Commits `025e9d3`, `3e4b1c7`. style.ex + capture/semantics untouched; brand-token parity green.
- **175-04 (2026-06-17):** Internal `UI.pager/1` + honest cap captions. Built the de-emphasized Older/Newer pager (hide-at-zero, disable-not-hide, capped "10,000+", role=status caption) over the existing keyset engine, adopted it next-only on Timeline (cursor in assign, D-19) and bidirectionally on Actor, added "Showing latest N" cap captions on Exports/Retention (D-20, none on Coverage/Redaction), and documented the `(captured_at, id)` keyset tiebreaker as deferred capture-layer perf debt in query.ex (D-15/Q1; no migration, capture layer untouched). All 4 NAV-02 Wave-0 PagerTest RED targets GREEN; verify.test 1008/0; brand-token parity green; zero new token. Commits `1a230bd`, `ac6f762`.
- **176-01 (2026-06-18):** Presentation core + icon contracts + Wave-0 RED scaffolds. Built `ref/2` (3-face, full == complete value), `truncate_middle/3` `:tail_min` (≥8 tail, default unchanged), per-kind `truncate_for/2`, `value_token/1` truncation (56, full in title); added `eye_off`/`funnel`/`lock`/`cloud_off` glyphs; authored the four MISSING Wave-0 tests (card-nesting D-12, typed-reason→state D-16, T3 fail-closed+audit D-21, ref-copy-equals-full Pitfall 4) all RED against current code with zero new deps. Commits `989f03c`, `45a788d`, `a4a13fa`, `3503fdc`, docs `5c18abf`.
- **176-02 (2026-06-18):** UI data-display + data-state component set. Built `ref/1`, `kv/1`, `data_table/1`, `loading_state/1`, `stale_banner/1`, three new `empty_state` variants, and the `data_state/1` typed-reason dispatcher as pure render functions with per-component contract tests + 10 isolated `/audit/__stress` stories (ledger + DESIGN-SYSTEM parity). Turned the Plan-01 `data_state_mapping` wave-0 RED test GREEN at the component level. ui_test 52/0, stress 33/0, parity+style_contract 37/0; warnings-as-errors clean; format clean. No page migrated. 6 cross-plan Wave-0 scaffolds stay RED by design. Commits `d3273d3`, `617eb47`, `8c880a6`, `93a8027`, `9e17e86`.
- **176-04 (2026-06-18):** Coverage flatten + card-nesting regression GREEN. Replaced the coverage success branch's hand-rolled `tl-coverage-command` header with `UI.page_header` (all 3 branches now use it; added an optional `:meta` slot to page_header for the last-checked line), demoted the command shell to plain page-stack siblings (kept `tl-card--metric` tiles), deleted the dead `tl-coverage-command__*` CSS with a paired style_contract refute lock (T-176-08), and turned the Plan-01 card-nesting Wave-0 RED test GREEN across all 11 surfaces (Task 2 needed no source change beyond Task 1's flatten). Operator_surface suite 545/5 (1 card-nesting RED → GREEN; 5 remaining are plan-05 retention T3 + ref-copy). Zero new token; brand-parity green; capture/semantics untouched. Commit `157398d`.
- **177-01 (2026-06-18):** Wave-0 conflict resolution + RED test scaffolds. Bound both locked-decision-vs-reality conflicts in writing (offline anchor = `.threadline-ui` LiveView root, NOT body/`.phx-disconnected`; keep the breadcrumbs list attr, no slot) and laid 12 RED scaffolds (3 source/parity + 9 component renders) + 1 GREEN breadcrumbs-trail test across the three test files. Full suite 1071/12 — all 12 failures are the new expected RED scaffolds; no pre-existing regression; format clean. Zero production code, zero new dep. Commits `bede897`, `4b7e304`.
- **177-02 (2026-06-18):** Layout primitives + semantic gap tokens. Added the three `--tl-gap-*` tokens parity-first across tokens.css/tokens.json/style.ex, then shipped `UI.stack/1` + `UI.cluster/1` (`@doc false`, card/1 idiom) with `.tl-stack`/`.tl-cluster` flexbox-gap CSS owning the spacing rhythm. Turned the Plan-01 gap-parity + stack/cluster RED scaffolds GREEN (gap-parity 4/0; combined gap+ui 66/7 where the 7 are out-of-scope Plan-03 data_panel/toolbar/detail_header scaffolds). Zero new dep; no public API; format + credo clean; capture/semantics untouched. Commits `8d701e8`, `38005a3`.
- **177-03 (2026-06-18):** Meta-components + breadcrumb truncation. Shipped `UI.data_panel/1` (state-coordinating shell composing the existing state family; stale-above-data; focus delegated; pager only :ok), `UI.toolbar/1` (disabled-coordination on cluster, Pitfall 6 contract), and `UI.detail_header/1` (`<h2>` + kv + actions cluster); reconciled breadcrumbs by keeping the list attr (D-14) + `clamp()` current-crumb truncation. Self-caught + fixed a phase-141/142 StyleContractTest governance regression (new `@media` literal + a `~1ms` comment) within the plan. All 7 component RED scaffolds GREEN; full suite 1071/2 (2 = Plan-04 overlay/offline RED-by-design, identical to baseline); compile/format/credo clean. Commits `1f4d6d7`, `2b082f8`, `19ef009`.
- **177-04 (2026-06-18):** Overlay motion + reconnect/offline group. Defined the previously-missing overlay JS-transition utility CLASS selectors (`.tl-fade-in/out`, `.tl-rise-in/out`, `.tl-slide-in/out-right`, `.opacity-0/100`, `.translate-y-0/4`, `.translate-x-0/full`, `.hidden`) + the modal/drawer/toast SHELLS (all were absent from style.ex) so overlay enter/exit motion is real; synced every overlay `JS.show/hide` to explicit `time: 180` (= `--tl-motion-base`, Pitfall 3) and added a toast fade-up entrance via `show_toast/2`. Built the reconnect/offline group keyed off the LiveView ROOT `.threadline-ui.phx-loading/.phx-error` (NOT body, NEVER the legacy disconnected class — Pitfall 1): warning-tinted `role=status` reconnect banner + `[data-tl-mutating]` pointer-events/opacity disable; added `UI.reconnect_banner/1` documenting the mutating-link `aria-disabled`/`tabindex=-1` contract (Pitfall 6). Self-caught + fixed a `.phx-disconnected` literal in a CSS comment that reddened the offline refute (comments are scanned, same gotcha class as Plan 03's `\d+ms`). Both Plan-01 style_contract RED scaffolds GREEN; full suite 1071/0; compile/format/credo(2115)/brand-parity clean. Zero new keyframes/tokens/deps; no public API; no inline `on*=`; capture/semantics untouched. GROUP-01/02 NOT closed (Plan 05). Commits `da4a36d`, `f1695a1`.
- **177-05 (2026-06-18):** GROUP-01 12-config stress mapping + ledger/projection parity (FINAL plan of phase 177). Remapped `@group_stories` from the 6 reserved baselines to the 12 GROUP-01 configurations as `status:current`/`owner_phase:177` via a `group_story/4` builder carrying a `surface` tag (`:live`|`:reference`) in both data + metadata (D-07; 10 live + 2 reference-only). Absorbed all 6 prior reserved baselines (action-bar/filter-bar/kv-list/pagination/status-strip/timeline-list) — zero orphaned `*.reserved` group ids. Synced `design-system-ledger.json` (12 current group entries 62/62/90, surface in `notes` — no new `@entry_keys`; reconciled `locked_ids`/`minimum_scores`/`required_inventory.groups`) + the DESIGN-SYSTEM.md Groups projection in lockstep; ledger parity GREEN. Added a `stress_router_test` assertion rendering all 12 group ids across 320/375/768/1024/1440 × dark/light/system. Marked GROUP-01 + GROUP-02 complete in REQUIREMENTS.md. Full library suite **1074/0** (1 excluded); verify.format/credo(2129)/compile-warnings-as-errors all clean; zero new dep, no public API, capture/semantics untouched. The only `mix ci.all` failure is a **pre-existing** example-app demo-seed 60s setup timeout (proven unrelated to plan 05 via stashed-baseline run; logged to `deferred-items.md`). Commits `8987793`, `8f62d25`, `9ca8453`, `313e52c`, `2a81604`.
- **Last Action**: Completed Phase 190 with 10/10 plans, passed verification, and recorded storage-schema confidence evidence (2026-07-02).
- **Next Step**: Discuss or plan Phase 191.
- **Resume file**: `.planning/ROADMAP.md`

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
