---
phase: 196-forward-only-net-positive-gate-first-proven-iteration
plan: 05
subsystem: ui
tags: [operator-surface, liveview, evidence, density, forward-only-gate]

requires:
  - phase: 196-forward-only-net-positive-gate-first-proven-iteration (plans 01-04)
    provides: forward-only ranking gate, expanded 5-page route capture lane, runbook, mechanical floor over page.* twins
provides:
  - Before-score snapshot for the first proven iteration (weakest page route.evidence, target lens density)
  - One real presentation improvement on /audit evidence — per-card inline subject label de-duplicated against the section header
affects: [196-06 ratification checkpoint, operator-surface, design-system-ledger]

actuals:
  tokens: 200
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: ["Density edits remove verbatim header-as-inline-label duplication so each fact renders once per card"]

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/evidence_live.ex

key-decisions:
  - "Edit target = the per-card `<span class=\"tl-evidence__meta\">row.subject</span>`: groups are keyed by subject, so every card verbatim repeated its own section header — removed the inline duplicate, kept the section title as the single label (DOM-verified defect per 196-D2, not an advisory-lens hallucination)"
  - "Page-scoped template edit chosen over any shared `--tl-*` token change (narrow blast radius per plan guidance); `.tl-evidence__meta` CSS rules in style.ex left untouched"

patterns-established:
  - "Forward-only iteration: maintainer-local critic selects weakest page + lens (human checkpoint), executor authors one presentation-only edit, deterministic page.* twin floor re-asserted"

requirements-completed: [PROOF-01]

coverage:
  - id: D1
    description: "Before-score snapshot recorded from the maintainer-local loop (route.evidence, target lens density, 4-blocking-lens scores)"
    requirement: PROOF-01
    verification: []
    human_judgment: true
    rationale: "Selection comes from the paid, maintainer-local LLM critic (196-D9); ratified via the Task-1 checkpoint resume signal 2026-08-26"
  - id: D2
    description: "One real presentation improvement on the evidence page: section-header-repeated-as-inline-label duplication removed so each fact renders once (density / signal-to-chrome)"
    requirement: PROOF-01
    verification:
      - kind: unit
        ref: "mix verify.mechanical (test/threadline/operator_surface/mechanical_checker_test.exs)"
        status: pass
      - kind: unit
        ref: "mix test test/threadline/operator_surface/live/evidence_live_test.exs"
        status: pass
    human_judgment: true
    rationale: "Whether the edit actually raises the density lens is judged by Plan 06's LLM re-eval + maintainer ratification checkpoint, not by the deterministic floor alone"

duration: 25min
completed: 2026-08-26
status: complete
---

# Phase 196 Plan 05: First Proven Iteration — Evidence Page Density Edit Summary

**De-duplicated the /audit evidence page's section-header-repeated-as-inline-label pattern (density lens, weakest page route.evidence) — each card no longer re-prints its section's subject, and the page.evidence.happy mechanical twin stays green**

## Performance

- **Duration:** ~25 min (Task 2 execution; Task 1 was a maintainer checkpoint resolved this session)
- **Completed:** 2026-08-26
- **Tasks:** 2/2 (Task 1 checkpoint resolved by maintainer; Task 2 executed)
- **Files modified:** 1

## Before-Score Snapshot (Task 1 resume signal, ratified 2026-08-26)

- **Weakest page:** `route.evidence` (`/audit` evidence page)
- **Target blocking lens:** **density** (signal-to-chrome)
- **4-blocking-lens before-scores:** brand_fidelity **81** / density **24** / typography **63** / rhythm **66**
- Defect DOM-verified against the real page last session (per 196-D2 — not an advisory-lens hallucination)

## Accomplishments

- Removed the verbatim duplication in `EvidenceLive.render/1`: evidence groups are keyed by subject and each section header (`tl-section__title`) already names the subject, yet every card's meta row re-printed that same subject as `<span class="tl-evidence__meta">`. The inline duplicate is gone; each fact now renders once per card (raises signal-to-chrome).
- Presentation-only, page-scoped template edit — no shared `--tl-*` token change, no public component API change, capture/query/auth untouched (196-D7 invariants held).
- Deterministic floor re-asserted: `mix verify.mechanical` green after the edit (`page.evidence.happy` MODE-A hard checks + MODE-B ratchet floors hold — the floor gates the committed scorecard JSON, unchanged by this edit; the fresh-capture ratchet check is Plan 06's re-eval).

## Task Commits

1. **Task 1: Maintainer selects weakest page + target lens** — checkpoint (no commit; resume signal recorded above)
2. **Task 2: Author one real improvement on the selected weakest page** - `f6c40b6c` (feat)

## Files Created/Modified

- `lib/threadline/operator_surface/live/evidence_live.ex` — removed the per-card inline subject span from `.tl-record-card__meta`; added a template comment explaining the density rationale

## Verification Results

| Gate | Result |
|------|--------|
| `mix verify.mechanical` | PASS — 18 tests, 0 failures (page.evidence.happy twin green) |
| `mix compile --warnings-as-errors` | PASS |
| `mix verify.format` | PASS |
| `mix verify.credo` | PASS — 2691 mods/funs, no issues |
| `mix test` (via ci.all) | 1380 tests, **3 failures** (1 excluded) — exactly the 3 pre-existing doc-contract baseline failures (FormlessPagesTest policy_redaction, V123CharterDocContractTest milestone string, Phase06NyquistCIContractTest 10-vs-12 job keys); none touch evidence |
| `mix test test/threadline/operator_surface/live/evidence_live_test.exs` | PASS — 13 tests, 0 failures |
| Diff scope | Code commit touches ONLY `evidence_live.ex`; no deletions; no `route.*`/CRITIQUE.md committed |

## Decisions Made

- Kept `.tl-evidence__meta` CSS rules in `style.ex` (they are harmless dead rules for this page now; removing them would widen the diff beyond the named target file and they may serve future use). The plan's provisional `files_modified: style.ex` mismatch is expected per the plan's own note — the real target was data-driven from Task 1.

## Deviations from Plan

None on the edit itself — Task 2 executed as specified against the Task-1 resume signal. Environment notes (not plan deviations):

- `mix ci.all`'s `verify.example` step fails locally with a Mix temp-lock error (`could not open .../mix_lock_user501/.../lock_0`) under the sandbox's default TMPDIR; re-running with `TMPDIR=/tmp` gets past it.
- With the lock worked around, the example app suite shows 9 failures (demo-seed/audit-capture data: DemoContractTest, WalkthroughEvidenceTest, WalkthroughHappyPathTest — missing seeded AuditTransaction rows). **Confirmed pre-existing:** reverting `evidence_live.ex` to HEAD reproduces the identical failures (5/13 in demo_contract_test.exs alone). Same local example-DB environment class as the known search_path issue; not caused by this edit, which cannot affect trigger capture or seeding.

## Issues Encountered

- First `mix ci.all` run raced my concurrent mix invocations on the shared temp lock dir; re-ran cleanly to get the authoritative 1380/3 result.

## Next Phase Readiness

- The edit is authored and floor-green; **Plan 06's ratification checkpoint** (maintainer-local full-panel re-eval + forward-only gate) is the required next step before the density improvement counts as proven (196-D1).

## Self-Check: PASSED

- `lib/threadline/operator_surface/live/evidence_live.ex` — FOUND (modified as claimed)
- Commit `f6c40b6c` — FOUND (feat, code edit; only file: evidence_live.ex)

---
*Phase: 196-forward-only-net-positive-gate-first-proven-iteration*
*Completed: 2026-08-26*
