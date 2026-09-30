# Phase 219: Deps-Only Build Cache - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-28
**Phase:** 219-deps-only-build-cache
**Areas discussed:** Key shape, Step order and removal, Coverage, Save policy/budget/security, Contract test and docs, Measurement

**Mode:** research-then-recommend (standing maintainer default).
- Four parallel researchers covered: key correctness, save policy/budget/security, coverage/measurement, and contract/docs. Their reports are in `discuss-research/r1..r4`.
- The findings were synthesized into one coherent set, which was presented once and confirmed with a single roll-up question.

---

## Roll-up confirmation

| Option | Description | Selected |
|--------|-------------|----------|
| Accept set (Recommended) | Write CONTEXT with A–F locked; warm samples taken organically, dispatch top-ups allowed | ✓ |
| Accept, no dispatch spend | Organic runs only; post-landing addendum if fewer than 8 warm samples | |
| Adjust specific picks | Change individual letters | |

**User's choice:** Accept set (Recommended). This also approves the dispatch spend for measurement top-ups, at most about 7 runner-hours.

## Researcher disagreements resolved in synthesis

| Topic | Positions | Resolution |
|---|---|---|
| Example key includes the example `mix.exs` | r3 said yes; r1 and r2 said no (release-bump churn) | No. One rule for both keys; `build-v1` is the fallback (D-03) |
| Where the removal goes relative to the save | r4 put it after the save; r1 and r2 put it before, because `deps.compile` builds the path dep | Before both the save and the compile (D-07) |
| Concurrent saves | r2 wanted a per-job profile key; r1 and r3 wanted a shared key and accepted the race | Shared keys. pgbouncer is restore-only; the benign example-key race is documented (D-11) |
| Unconditional `deps.compile` vs split step | r1 said miss-only; r3 wanted its own step for measurement | Its own named step, run only on a miss (D-07, D-23) |
| deps/`_build` lockstep (PITFALLS bullet) | the milestone research said lockstep; r1 verified it isn't needed | Keep the deps `restore-keys`; PITFALLS bullet superseded |
| No-optional "no cache step" vs "cache-free" | SC3 and CACHE-01 wording differ | Drop its deps cache so SC3 is literally true (D-13) |

## Claude's Discretion

- Key separators and segment order, as long as every segment is present.
- An always-run echo step vs a hit-only report step for the hit/miss label.
- Plan and wave split.

## Deferred Ideas

- Dev-env cache for credo and dialyzer.
- Restore-only caches for flake-detection and browser-full.
- Removing the unused root deps work in browser/capture.
- A composite setup action after Phase 221.
- The Playwright key keyed on version.
