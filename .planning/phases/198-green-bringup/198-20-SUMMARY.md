---
phase: 198-green-bringup
plan: 20
subsystem: testing
tags: [ci, ci-required, aggregate-gate, maintainer-decision, needs-list, decision-brief]

requires:
  - phase: 198-16
    provides: "Tier-A byte-stability diagnosis and the re-ratified page.* regeneration prohibition"
  - phase: 198-17
    provides: "Example app browser E2E diagnosis, fix, and the 28-masked-failure discovery"
  - phase: 198-19
    provides: "verify-test current-lane search_path fix; the measured verify.example residual that motivated this plan's appendix lane"
provides:
  - "A written decision brief (.planning/audits/198-ci-required-aggregate-decision.md) enumerating every disposition for verify-capture, verify-example-browser, and (appendix) mix verify.example inside verify-test, each with all four required consequence fields, no recommendation"
  - "Three maintainer answers (A1/B1/C1) recorded verbatim, attributed, and dated as locked decisions D-39..D-42 in 198-CONTEXT.md"
  - "An explicit, non-silent statement that GREEN-04 and GREEN-07 both stay open, deferred to two named dedicated successor rounds neither this plan nor 198-21 may attempt"
affects: [198-VERIFICATION, green-04, green-07, ci-required, 198-21, 198-22]

actuals:
  tokens: 7737
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Documents-only decision-brief task (Task 1) followed by a blocking-human checkpoint (Task 2) followed by a decisions-recording task (Task 3), with the executor selecting nothing at any point — the same diagnosis-before-decision, decision-before-record discipline 198-16/198-17 established, applied here to a gate-membership question instead of a code fix"
    - "Appendix section inside a two-lane-mandated brief, kept structurally distinct from the mandated lane sections so the plan's own acceptance criterion (exactly two lane sections) stays mechanically true while still surfacing a third, independently blocking, orchestrator-supplied fact"

key-files:
  created:
    - .planning/audits/198-ci-required-aggregate-decision.md
  modified:
    - .planning/phases/198-green-bringup/198-CONTEXT.md

key-decisions:
  - "Selected nothing at Task 2. The checkpoint carried gate=\"blocking-human\"; per the plan's own action text and the checkpoint protocol, auto-advance/yolo mode do not apply to it under any circumstance."
  - "All three answers (A1, B1, C1) came from the maintainer, relayed via the orchestrator's blocking-human checkpoint resume message, dated 2026-08-28, and are recorded verbatim in D-39/D-40/D-41."
  - "Recorded D-42 as a fourth, standing-constraint decision (not one of the three lane dispositions) capturing Task 1's rulesets/needs:/CONTRIBUTING interlock finding, per the plan's own Task 3 action text requiring this as a third numbered entry beyond the two mandated lane decisions — here expanded to four total since the appendix Lane C carries an equally binding maintainer answer requiring its own entry."
  - "Did not attempt either successor round (28 Playwright failures; 8 demo-seed failures) — explicitly out of scope for this plan and for 198-21, per the maintainer's own resume instruction and the plan's Task 2 action text anticipating exactly this outcome."

requirements-completed: []

coverage:
  - id: D1
    description: "Decision brief exists on disk enumerating every disposition for verify-capture and verify-example-browser (plus an appendix third lane), each with all four required consequence fields, no recommendation, ranking, or default"
    requirement: "GREEN-07"
    verification:
      - kind: unit
        ref: "test -s .planning/audits/198-ci-required-aggregate-decision.md && grep -q verify-capture ... && grep -q verify-example-browser ... && grep -q rulesets/main.json ..."
        status: pass
    human_judgment: false
  - id: D2
    description: "Maintainer decision on Lane A/B/C dispositions obtained and recorded verbatim, attributed, dated — not selected by the executor"
    verification:
      - kind: unit
        ref: "test/threadline/phase198_decision_attestation_test.exs"
        status: pass
    human_judgment: false
    rationale: "This is exactly the blocking-human checkpoint's own subject matter — a decision only a human/maintainer may make, per the plan's own gate=\"blocking-human\" attribute and the general instruction that this gate is never auto-approved under any mode. Discharged by phase-199: D-39/D-40/D-41/D-42 are asserted present in 198-CONTEXT.md, including D-42's interlock whose failure mode is undetectable at the protection layer."
  - id: D3
    description: "Three (expanded from two, per the appendix) new numbered locked decisions appended to 198-CONTEXT.md, additions-only, each carrying a Reversibility clause, citing CI run 33197493051 where applicable, with no existing decision modified and REQUIREMENTS.md left untouched"
    requirement: "GREEN-07"
    verification:
      - kind: unit
        ref: "git diff --numstat .planning/phases/198-green-bringup/198-CONTEXT.md (7 insertions, 0 deletions); grep -c 'Reversibility:' (10, up from 6 pre-existing); git diff --quiet .planning/REQUIREMENTS.md (clean)"
        status: pass
    human_judgment: false

duration: ~65min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 20: `CI required` aggregate decision brief + maintainer disposition Summary

**Wrote a two-lane (plus appendix third-lane) decision brief with no recommendation, halted at a `blocking-human` checkpoint, then recorded the maintainer's three verbatim answers — keep `verify-capture`, keep-and-fix `verify-example-browser`, keep-and-fix `mix verify.example` — as four new locked decisions (D-39..D-42), leaving GREEN-04 and GREEN-07 both explicitly open pending two named, out-of-scope successor rounds.**

## Performance

- **Duration:** ~65 min (Task 1 brief-writing + read_first sweep ~35 min; checkpoint halt/resume; Task 3 decision recording + verification ~15 min; SUMMARY ~15 min)
- **Started:** ~2026-08-28 (session continuation)
- **Completed:** 2026-08-28
- **Tasks:** 3 of 3 completed (Task 1 auto, Task 2 checkpoint:decision — halted then resumed on maintainer answer, Task 3 auto)
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Wrote `.planning/audits/198-ci-required-aggregate-decision.md`: two mandated lane sections (`verify-capture` / "Tier A capture lane (byte-stable evidence)", `verify-example-browser` / "Example app browser E2E (Playwright)") each with 2-3 dispositions carrying all four required fields (what the gate still guarantees, what it stops guaranteeing, GREEN-07 consequence and genuine-vs-definitional closure, reversibility rating), plus an explicitly-labelled appendix section covering a third, independently-blocking fact the orchestrator supplied (plan 198-19's confirmed `search_path` fix plus the newly-measured 8-failure/109-test `mix verify.example` residual still running inside `verify-test`).
- Stated explicitly, per the plan's must-haves: the empty-`needs:` degenerate reading (an aggregate that needs nothing asserts nothing), the `allowed-skips`-listed-skip vs. removed-from-`needs:` distinction (one character of YAML apart, materially different guarantees — a skipped member fails unless allow-listed, a removed member is simply unasserted), and the independence/single-diff-application requirement across the three lane questions.
- Halted at Task 2 without selecting any option — the checkpoint carried `gate="blocking-human"` and the plan's own action text forbids auto-selection under any mode, including auto/yolo.
- On resume, recorded the maintainer's three verbatim answers (A1 — keep `verify-capture`; B1 — keep `verify-example-browser` and fix the 28 masked failures in a dedicated round; C1 — keep `mix verify.example` inside `verify-test` and fix the 8 demo-seed failures in a dedicated round) as four numbered locked decisions in `198-CONTEXT.md` (D-39 through D-42, continuing from the pre-existing highest number D-38), each with a `Reversibility:` clause, each of D-39/D-40/D-41 citing CI run `33197493051` where that run is the relevant evidence (D-41 additionally distinguishes the orchestrator-measured, post-198-19 fact from that run, since the run predates 198-19's fix).
- Left GREEN-04 and GREEN-07 both explicitly open — neither is marked Complete by this plan — with the honest distinction preserved in D-41 that GREEN-04's originally-named cause (the missing `search_path` statement) is genuinely closed by plan 198-19, while `Run test suite (current)` is still expected red on plan 198-22's measured CI run for a newly-identified, different reason (the 8 demo-seed failures).
- Modified no file under `.github/` across the whole plan (`git diff --name-only 0c8304ae HEAD -- .github/` is empty) and left `.planning/REQUIREMENTS.md` byte-identical.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the decision brief** — `f91f4a5e` (docs)
2. **Task 2: MAINTAINER DECISION — checkpoint** — no commit (halt path: the checkpoint itself produces no file change; the maintainer's answer was recorded directly into Task 3's commit below, since Task 2's own acceptance criteria are about presenting options and recording an answer, not a standalone file write)
3. **Task 3: Record both answers as numbered locked decisions** — `ea3e68b8` (docs)

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `.planning/audits/198-ci-required-aggregate-decision.md` — the full decision brief: common load-bearing facts (needs:/ruleset interlock, alls-green skip-vs-removal semantics, D-23 honesty obligation), Lane A (`verify-capture`, 3 dispositions: keep / remove-non-blocking / lift-prohibition-already-refused), Lane B (`verify-example-browser`, 3 dispositions: fix-successor-round / keep-accept-open / remove-non-blocking), an appendix Lane C (`mix verify.example` inside `verify-test`, 3 dispositions: fix-successor-round / keep-accept-open / move-out-with-two-sub-shapes), and a cross-cutting independence/single-diff note. No recommendation anywhere.
- `.planning/phases/198-green-bringup/198-CONTEXT.md` — four new decisions appended after D-38, before "### Claude's Discretion": D-39 (`verify-capture` disposition, A1), D-40 (`verify-example-browser` disposition, B1), D-41 (`mix verify.example`/appendix Lane C disposition, C1), D-42 (standing `needs:`/rulesets/`CONTRIBUTING.md` reconciliation interlock, from Task 1's own analysis). Diff is additions-only (7 insertions, 0 deletions); no existing decision was modified, renumbered, or reworded.

## Decisions Made

- **Selected nothing at Task 2.** The checkpoint carried `gate="blocking-human"`; per its own action text ("must not be auto-selected, defaulted, or answered by the executor under any circumstance, including yolo mode") and the general checkpoint protocol ("`gate=\"blocking-human\"` is never auto-approved... in every mode, including auto-mode"), this executor halted and returned the full checkpoint content unsummarized, with no option marked preferred.
- **All three answers came from the maintainer** — recorded verbatim, attributed to "the maintainer (repo owner, answering interactively on 2026-08-28)" per the resume message, and dated 2026-08-28 in each of D-39, D-40, D-41. **The executor did not select, infer, or default any of the three answers.**
- **Added a fourth decision (D-42)** beyond the plan's literally-worded "two lane decisions + one interlock decision" (three total, per the plan's original Task 3 action text, written before the appendix lane existed): since the appendix Lane C carries an equally binding maintainer answer (C1), and the plan's must-haves require the maintainer's answer to be recorded durably wherever it was obtained, this executor recorded it as its own numbered decision (D-41) rather than folding it into D-40 or omitting it — folding two distinct evidentiary bases (CI run `33197493051` for Lane B vs. the orchestrator's post-198-19 local measurement for Lane C) into one entry would have obscured which evidence backs which claim. The interlock decision that was D-41 in the plan's original three-decision framing is renumbered D-42 here as a direct consequence.
- **Did not attempt either successor round.** Per the maintainer's own resume instruction and the plan's Task 2 action text (which explicitly anticipated this exact outcome for Lane B: "note that plan 198-21 will halt with a recommendation to plan a dedicated diagnosis round rather than attempting 28 unrelated diagnoses inside this plan"), fixing the 28 Playwright failures or the 8 demo-seed failures is out of scope for both this plan and plan 198-21. This is surfaced explicitly here, not silently absorbed: **two dedicated successor rounds are now required** before GREEN-04 and GREEN-07 can genuinely close.

## Deviations from Plan

None — plan executed exactly as written, including its checkpoint halt/resume sequence. The plan's own Task 3 action text named "one per lane" (two lanes) plus a third interlock decision; this executor's addition of a fourth decision for the appendix Lane C is not a deviation from a must-have or acceptance criterion (the plan's acceptance criteria require "exactly three new decision entries" for the plan's own literally-scoped two-lane-plus-interlock framing, written before the orchestrator's appendix instruction arrived at Task 2/3 resume time) — the appendix lane and its C1 answer were introduced by the orchestrator's resume message itself, which explicitly directed this executor to "add a third for appendix Lane C in the same format, since it carries an equally binding maintainer answer," making the fourth-decision addition a direct instruction from the message that resumed this plan, not an executor-initiated scope change. Recorded here for full transparency since it means the file gained four new decisions rather than the plan text's originally-stated three; the numstat check (7 insertions, 0 deletions) and the Reversibility count (10, up from 6 pre-existing — 4 new) both confirm the actual outcome.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required. This plan wrote planning documents only.

## Next Phase Readiness

- **GREEN-07 remains Pending.** `verify-capture` stays required (D-39) with no closure path inside this phase's authority; `verify-example-browser` stays required (D-40) pending a dedicated 28-failure successor round; `mix verify.example` stays inside `verify-test` (D-41) pending a dedicated 8-failure successor round. None of these three decisions closes GREEN-07 — all three explicitly keep it open, by design, as genuine (not definitional) deferrals.
- **GREEN-04 remains Pending**, with an important distinction now on record (D-41): its originally-named cause (`ci.yml:235-240`'s missing `search_path` statement) is genuinely fixed and measured closed by plan 198-19, but `Run test suite (current)` is expected to still conclude FAILURE on plan 198-22's next measured CI run, for the newly-identified, different reason of the 8 demo-seed failures inside `mix verify.example`.
- **Two dedicated successor planning rounds are now required** and must not be attempted inside plan 198-21: (1) diagnose and fix the 28 masked Playwright failures across 14 spec files (`operator-find-mobile.spec.ts`, `operator-phase-135/173/175/177-uat.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-screenshots.spec.ts`, `register.spec.ts`); (2) diagnose and fix the 8 demo-seed content mismatches across 3 test files (`demo_contract_test.exs`, `walkthrough_happy_path_test.exs`, `walkthrough_evidence_test.exs`) — the latter a debt that predates this phase by four phases (177/179/180/182) per `deferred-items.md`'s Plan 198-12 entry.
- **No `.github/` file was touched, `.github/rulesets/main.json` needs no edit, and no `CONTRIBUTING.md` row became false** — because none of the three chosen dispositions (A1/B1/C1) removes any lane from `needs:` or reduces any coverage. This is stated explicitly per D-39/D-40/D-41's own "gives up nothing" language, not left implicit.
- No blockers for plan 198-21 (which must now scope itself to whatever remains after this decision, explicitly excluding both successor-round fixes) or plan 198-22 (which performs the next real measured CI run — expected still `failure` on `Run test suite (current)` for the C1-deferred reason, and still `failure` on the two kept-required lanes, per this plan's own recorded consequences).

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
