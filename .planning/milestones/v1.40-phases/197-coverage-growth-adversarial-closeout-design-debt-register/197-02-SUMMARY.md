---
phase: 197-coverage-growth-adversarial-closeout-design-debt-register
plan: 02
subsystem: operator-surface-ui
tags: [proof-02, forward-only-gate, density, coverage-page, shortfall]
requires:
  - 197-01 (screenshot-keyed cache + before-pole guard — both exercised for real this plan)
provides:
  - fresh 5-route before-pole baseline (capture 2026-08-27, screenshot-keyed)
  - ratified ordered candidate list (5 entries)
  - landed coverage×density edit (842bd737) with flipped LiveView tests
  - maintainer-ratified PROOF-02 shortfall (also covers plans 03–04, which did not run)
affects:
  - 197-05 design-debt register (shortfall + evidence-IA row stay open debt)
  - any future resume of the paid iteration loop (baseline + ranking are ready fuel)
tech-stack:
  added: []
  patterns:
    - c6f9355e density edit + assert-to-refute test flip replicated on coverage_live
    - maintainer gate automation (critic-before-pole.sh + ui-critic.yml CI lane, 196-D9 amended)
key-files:
  created:
    - examples/threadline_phoenix/e2e/critic-before-pole.sh
    - .github/workflows/ui-critic.yml
  modified:
    - lib/threadline/operator_surface/live/coverage_live.ex
    - test/threadline/operator_surface/live/coverage_live_test.exs
decisions:
  - "196-D9 amended by maintainer directive (2026-08-27): paid scoring gates are automated wherever ANTHROPIC_API_KEY is provisioned (repo-root .env locally; CI scoring only on manual dispatch with score=true — push runs are always capture-only/free)"
  - "Iteration-1 target = route.coverage/density (fresh 32 fail), overturning the stale RESEARCH seed (actor/density 54.5) — selection from fresh numbers worked exactly as the plan required"
  - "VOID at N=3 answered with one --n 7 escalation attempt (196-D1 practice); the re-run was aborted when the maintainer paused the loop, so the standing verdict is VOID (REJECT-equivalent), no ledger change"
  - "Phase-185 doc-contract copy ('Fix rows marked Needs capture, …') pins the not-ready next-step sentence; the third planned removal was authored then reverted rather than breaking the locked contract (recorded for Plan-03/maintainer, now folded into the shortfall)"
metrics:
  duration: ~1 day (scoring wall-clock dominated)
  completed: 2026-08-27
status: complete-with-ratified-shortfall
actuals:
  tokens: ~110k (executor) + maintainer-side paid API scoring
  tasks: 3
  commits: 3 (c48faefa tooling, 842bd737 edit, 5bb017b1 merge)
---

# Phase 197 Plan 02: Iteration 1 + Ratified PROOF-02 Shortfall

## Task 1 — Fresh before poles + ratified candidates (checkpoint record)

Executed under the maintainer's automation directive (2026-08-27): fresh seeded
capture (`capture:pages`, all 5 routes + degraded variant), cache-busted
`critic:score --fresh-before` per route. Capture 2026-08-27 ~10:00 local;
scoring 10:06–13:00. Lens value = min of stable dimensions.

| route | density | rhythm | typography | brand_fidelity |
|---|---|---|---|---|
| coverage | **32 fail** | 69 | 76 | 81 |
| actor | 38 weak | 69 | 76 | 79 |
| evidence | 58 | 69 | 63 | 79 |
| retention | 41 (excluded — 196 accept) | 69 | 68 | 79 |
| timeline | 63 | 59 | 60 | 80 |

Ratified ordered candidates (NEW cells only): 1. coverage×density (32) ·
2. actor×density (38) · 3. evidence×density (58, IA restructure only per
196-06) · 4. timeline×rhythm (59, --n 7 only) · 5. timeline×typography (60).
Iteration-1 target: **route.coverage / density**. The fresh sweep overturned
the stale RESEARCH seed ranking (which predicted actor) — the exact failure
mode the fresh-numbers requirement exists to catch.

## Task 2 — Landed edit (commit 842bd737, merged 5bb017b1)

`coverage_verdict/1` only: removed the "Selected schema readiness" eyebrow
self-label (duty → section aria-label + status chip + heading) and the
"selected schema: … · Checked …" meta line (duty → page-header `<:meta>` and
the verdict heading). HEEx rationale comment in place. Tests flipped in the
assert-to-refute pattern incl. a new danger-state semantic-carrier test.
Gates at commit: compile --warnings-as-errors, format, coverage_live_test
21/0, verify.mechanical 18/0, verify.critic_trust 22/0 — all green.

Deviation (documented, not applied): third planned removal reverted because
`coverage_doc_contract_test.exs:135` pins that copy (Phase-185 lock).

## Task 3 — Gate verdict (verbatim) and maintainer ratification

`npm run critic:gate -- --page route.coverage --lens density` (N=3, live):
blast radius 0/1 changed; mechanical floor holds (page.coverage.happy);
held-out ρ green on all four blocking lenses (brand 0.926/0.85, density
0.839/0.78, typography 0.772/0.72, rhythm 0.761/0.72); **[7/7] Verdict: VOID**
— "Targeted-lens verdict (route.coverage__dark-1280/density) is unstable or
null → VOID (not a pass), per 196-D1."

One `--n 7` escalation was started and aborted mid-run when the maintainer
paused the loop (its own [1/7] had already failed on capture:pages with no
server up → predetermined VOID). Standing verdict: **VOID = REJECT-equivalent,
no ledger change, no signoff, no pin.**

## Maintainer-ratified shortfall (covers Plans 03 and 04)

Ratified 2026-08-27 after reviewing before/after screenshots of the landed
coverage edit. Rationale, verbatim in substance: the loop is honest and the
edit is real, but ~80–90% of paid spend goes to measurement/validation rather
than improvement, and the visible delta is small relative to cost. The paid
iteration loop is **parked**: plans 197-03 and 197-04 do not run, 0 NEW
accepts are booked this phase (196's retention accept stands), and this is an
explicit PROOF-02 gap for the phase verifier — not papered over.

Resume fuel (all committed/recorded): fresh 5-route baseline with
overwrite-protected poles, ratified 5-candidate ranking, zero-touch
`critic-before-pole.sh`, and the `ui-critic.yml` dispatch lane. Resuming is
one maintainer command plus the standing candidate list.
