---
phase: 196-forward-only-net-positive-gate-first-proven-iteration
plan: 04
subsystem: testing
tags: [critic, forward-only-gate, proof-01, route-capture, doc-contract, runbook, rho-ranking]

# Dependency graph
requires:
  - phase: 196-forward-only-net-positive-gate-first-proven-iteration
    plan: 03
    provides: "gate.ts full forward-only decision engine (critic:gate) + ROUTE_PAGE_TWIN; critic_panel.trust_floors ledger block"
  - phase: 196-forward-only-net-positive-gate-first-proven-iteration
    plan: 01
    provides: "route.* capture lane skeleton (operator-page-capture.spec.ts, route.timeline only) + critic:gate run.ts arm"
  - phase: 194-tier-a-mechanical-floor
    provides: "committed page.*.happy scorecards in mechanical_floors (the deterministic twins the gate gates on)"
provides:
  - "route.* capture lane expanded to the five weakest-page candidates (timeline, coverage, retention, actor, evidence), each backed by a committed page.<x>.happy mechanical-floor twin"
  - "CONTRIBUTING.md 'Forward-only gate — run one iteration' maintainer runbook (capture→score→gate→floor→ratify→commit) + route↔page twin table"
  - "corrected CONTRIBUTING.md trust bar: Spearman ρ ≥ 0.70 (Phase-195 pivot) replacing the stale Krippendorff α ≥ 0.67 phrasing"
  - "forward_only_gate_doc_contract_test.exs pinning the runbook commands, twin table, and ρ bar; wired into verify.doc_contract; asserts the critic never leaks into guides/"
affects: [196-05, 196-06, 197]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "route.* live cell ↔ committed page.<x>.happy twin mapping made explicit in the runbook (the deterministic floor the gate gates on — Pattern 3)"
    - "doc-contract test refutes the critic runbook leaking into guides/**/*.md (RESEARCH A1 information-disclosure boundary)"
    - "real router paths confirmed, not guessed: retention at /audit/policy/retention; actor at a deterministic seeded /audit/actors/service_account/zendesk-sync"

key-files:
  created:
    - test/threadline/forward_only_gate_doc_contract_test.exs
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
    - CONTRIBUTING.md
    - mix.exs

key-decisions:
  - "route.retention → /audit/policy/retention and route.actor → /audit/actors/service_account/zendesk-sync are the REAL router mounts; the plan's illustrative /audit/retention and /audit/actors do not resolve (retention lives under /policy; the actor route needs a concrete :kind/:id). The plan explicitly instructed confirming the seeded actor path in the router."
  - "The stale α-bar fix is scoped to CONTRIBUTING.md:132 (the verify.critic_trust CI-gate description, which is ρ-based post-pivot). The doc-contract refute targets the exact unique parenthetical 'Krippendorff α ≥ 0.67, N ≥ 20, raw agreement ≥ 0.80' so it does not collide with the legitimate human-golden-oracle α computation described later in Step 3."
  - "The runbook is placed as a sibling ## section after the oracle-validation maintainer section (it is the loop you run AFTER the oracle is validated), kept in CONTRIBUTING.md and never guides/ (RESEARCH A1 / 196-D9 / T-196-04-01)."

patterns-established:
  - "Forward-only gate maintainer runbook = capture:pages → critic:score --page route.<x> → critic:gate --page route.<x> --lens <blocking> → mix verify.mechanical (committed twin) → ratchet.signoffs append + reviewed commit"

requirements-completed: [PROOF-01]

coverage:
  - id: T1
    description: "route.* capture lane expanded to the five weakest-page candidates, each twin-backed; --list enumerates the set without a browser"
    requirement: PROOF-01
    verification:
      - kind: e2e
        ref: "cd examples/threadline_phoenix/e2e && npx playwright test --project=route-capture --list operator-page-capture.spec.ts"
        status: pass
      - kind: static
        ref: "node check: route.coverage/retention/actor/evidence present in spec AND page.<x>.happy twin present in mechanical_floors for all five"
        status: pass
    human_judgment: false
  - id: T2
    description: "Forward-only gate runbook documented + pinned; ρ ≥ 0.70 bar replaces stale α ≥ 0.67 phrasing; new doc-contract test wired into verify.doc_contract"
    requirement: PROOF-01
    verification:
      - kind: unit
        ref: "mix test test/threadline/forward_only_gate_doc_contract_test.exs (6 tests, 0 failures)"
        status: pass
      - kind: static
        ref: "grep critic:gate + page.coverage.happy in CONTRIBUTING.md; grep forward_only_gate_doc_contract_test in mix.exs; no guides/ diff"
        status: pass
    human_judgment: false

# Metrics
duration: ~25min
completed: 2026-07-28
status: complete
---

# Phase 196 Plan 04: Wire the Loop End-to-End — Route Lane + Maintainer Runbook Summary

**The forward-only loop is now runnable and documented: the `route.*` capture lane covers the five weakest `/audit` pages (each backed by a committed `page.<x>.happy` mechanical-floor twin), CONTRIBUTING.md carries a pinned `capture→score→gate→floor→ratify→commit` maintainer runbook with an explicit route↔page twin table, the stale Krippendorff-α trust bar is corrected to the Spearman ρ ≥ 0.70 ranking bar, and a new drift-guard doc-contract test keeps the runbook honest while asserting the critic never leaks into published adopter guides.**

## Performance
- **Duration:** ~25 min
- **Tasks:** 2 (both `type="auto"`)
- **Files created:** 1 (`forward_only_gate_doc_contract_test.exs`)
- **Files modified:** 3 (`operator-page-capture.spec.ts`, `CONTRIBUTING.md`, `mix.exs`)

## Accomplishments
- **Task 1 — route capture lane expanded.** Grew `ROUTES` in `operator-page-capture.spec.ts` from `route.timeline` (+ its degraded twin) to the five weakest-page candidates named in 196-D8: `route.coverage`, `route.retention`, `route.actor`, `route.evidence`. Each new route uses the REAL router mount and is backed by an already-committed `page.<x>.happy` twin in `mechanical_floors` (verified for all five). The `id`/`path`/`degrade?` shape and `cellId(...)` naming are unchanged so `critic:score`/`critic:gate` resolve them without any runner change. No `page.*`-style twin was added here (the twins already exist — Pattern 3). Route PNGs/JSON stay gitignored and never enter CI.
- **Task 2 — runbook + ρ-fix + doc-contract pin.** Added a "Forward-only gate — run one iteration" maintainer subsection to CONTRIBUTING.md documenting the repeatable loop with canonical commands (`npm run capture:pages`, `npm run critic:score -- --page route.<x>`, `npm run critic:gate -- --page route.<x> --lens <blocking>`, `mix verify.mechanical`, then the `ratchet.signoffs` append + reviewed commit), an explicit **route↔page twin mapping table**, and the inline invariants (LLM local-only/out of CI, only the 4 validated lenses block, advisory findings verified vs ground truth, `route.*`/`CRITIQUE.md` stay uncommitted). Corrected the stale trust-bar line to **Spearman ρ ≥ 0.70** with α/AUC/raw as reported-only companions. Created `forward_only_gate_doc_contract_test.exs` (mirrors the existing doc-contract idiom) pinning the canonical commands, the twin table, and the ρ bar, refuting the stale α phrasing, and asserting the critic never appears in `guides/**/*.md`. Wired the new file into the `verify.doc_contract` alias in `mix.exs`.

## Task Commits
1. **Task 1: Expand the route capture lane to the five weakest-page candidates** — `a4037e8c` (feat)
2. **Task 2: Forward-only gate runbook + ρ-line fix + doc-contract pin** — `051f4cd3` (docs)

## Files Created
- `test/threadline/forward_only_gate_doc_contract_test.exs` — 6 pins: runbook heading + step order, canonical capture/score/gate commands, route↔page twin table (all five `page.<x>.happy` twins + the two non-obvious real paths), ρ ≥ 0.70 present / stale α parenthetical absent, blocking-panel + local-only invariants, and a no-leak-into-guides guard.

## Files Modified
- `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` — `ROUTES` expanded to five candidates + updated leading comment documenting the real router paths.
- `CONTRIBUTING.md` — corrected the `verify.critic_trust` trust-bar description (α→ρ) and appended the forward-only gate runbook section.
- `mix.exs` — appended `forward_only_gate_doc_contract_test.exs` to the `verify.doc_contract` alias (surgical; all other aliases and the [196-D9] critic-out-of-`ci.all` invariant untouched).

## Decisions Made
- **Real router paths over the plan's illustrative paths.** `route.retention → /audit/policy/retention` (retention is mounted under `/policy/retention`, not `/retention`) and `route.actor → /audit/actors/service_account/zendesk-sync` (the actor route is `/actors/:kind/:id`, so it needs a concrete actor — the deterministic seeded `service_account/zendesk-sync` from the demo Manifest, a valid `@actor_kinds` member). The plan explicitly told me to "confirm the actual seeded path in the router" for the actor. Documented as a deviation below.
- **α-fix scoped to the CI-gate description only.** The stale bar at CONTRIBUTING.md:132 describes `verify.critic_trust` (the ρ-based CI gate) and was corrected. The later Step-3 α wording describes the human-golden-oracle's Krippendorff inter-rater computation (a different, legitimate path), so the doc-contract refute targets the exact unique parenthetical rather than a bare "α ≥ 0.67" to avoid a false collision.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected two route paths that would not resolve as the plan wrote them**
- **Found during:** Task 1
- **Issue:** The plan's `<action>` illustrated `route.retention → /audit/retention` and `route.actor → /audit/actors`, but the real operator-surface router (`lib/threadline/operator_surface/router.ex:115-125`) mounts retention at `/audit/policy/retention` and actor at `/audit/actors/:kind/:id` (a bare `/audit/actors` and `/audit/retention` would 404).
- **Fix:** Used the real mounts — `/audit/policy/retention` and the deterministic seeded `/audit/actors/service_account/zendesk-sync` (demo `Manifest.actor_id(:zendesk_sync)`, kind `service_account`, both confirmed against `ActorLive`'s `@actor_kinds`). The plan itself instructed confirming the seeded actor path in the router, so this is the sanctioned confirmation for actor; the retention correction is the genuine path fix.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts`
- **Commit:** `a4037e8c`

## Verification
- `npx playwright test --project=route-capture --list operator-page-capture.spec.ts` → enumerates the expanded route set (single looped capture test) without error, no browser required.
- `node` checks: all four new `route.*` ids present in the spec; all five `page.<x>.happy` twins present in `mechanical_floors`; no `route.*` scorecard staged (gitignored).
- `npx tsc --noEmit` (e2e) → exit 0.
- `mix test test/threadline/forward_only_gate_doc_contract_test.exs` → 6 tests, 0 failures.
- `mix verify.doc_contract` → the new test passes green; the ONE failure is the pre-existing, unrelated `V123CharterDocContractTest` (asserts a `PROJECT.md` milestone string "v1.38…" while the file is at v1.40 — a file this plan did not touch, flagged as pre-existing in the orchestrator baseline).
- `mix format --check-formatted` on the new/edited Elixir files → clean.
- [196-D9] invariant preserved: the `mix.exs` diff only appends one deterministic pure-Elixir test to `verify.doc_contract`; no critic/LLM gate was added to any `mix` alias and `ci.all` is unchanged.

## Deferred Issues
None from this plan. (The repo carries ~11 pre-existing, unrelated Elixir test failures — the `storage_schema` search_path cluster, StressLedger/LedgerSplice, FormlessPages, Phase06NyquistCIContract, and V123CharterDocContract — in files this plan did not touch; per the orchestrator baseline these are not this plan's regressions.)

## Known Stubs
None. The runbook documents the live keyed loop (which requires `ANTHROPIC_API_KEY` + a running seeded app), consistent with 196-03's local-only posture; the first real keyed iteration lands in 196-05. This plan's deliverables — the expanded route lane, the runbook, the ρ-fix, and the doc-contract pin — are all complete and verified on the deterministic path.

## Self-Check: PASSED
- `test/threadline/forward_only_gate_doc_contract_test.exs` — FOUND
- `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` (expanded ROUTES) — FOUND
- `CONTRIBUTING.md` (runbook + ρ bar) — FOUND
- `mix.exs` (verify.doc_contract wired) — FOUND
- Commit `a4037e8c` (Task 1) — FOUND
- Commit `051f4cd3` (Task 2) — FOUND

---
*Phase: 196-forward-only-net-positive-gate-first-proven-iteration*
*Completed: 2026-07-28*
