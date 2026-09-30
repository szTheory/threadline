# Phase 218: CI Economy: Remove Waste - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-27
**Phase:** 218-ci-economy-remove-waste
**Areas discussed:** live Dialyzer disposition, ECON-07 measurement method. Recommendations were presented for the other four areas: flake repeat count, the green-SHA skip mechanism, the ECON-03 guard, and docs/tarball dominance.

---

## live Dialyzer disposition (ECON-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Move and fail closed | Run in `verify-dialyzer` after the PLT restore. A missing or unreadable PLT turns it red, and a negative test proves that. | ✓ |
| Move as-is | Saves the minutes, but the proof is only as honest as the PLT cache hit | |

**User's choice:** Move it and make it fail closed.
**Notes:** 214-BASELINE §8 showed the test passes vacuously with no PLT.

---

## ECON-07 measurement method

| Option | Description | Selected |
|--------|-------------|----------|
| Cited dispatch runs plus cadence arithmetic | Dispatch each changed workflow once, take at least 5 post-landing CI runs, and label monthly projections `[inference]`. No waiting. | ✓ |
| Wait for real scheduled runs | At least 2 weekly flake runs and about 2 weeks of nightlies. Holds up 219–222 for about 2 weeks. | |

**User's choice:** Cited dispatch runs plus cadence arithmetic.

---

## Recommendations presented and locked without objection

- Flake: 15 repeats (about 46 min), step timeout about 55 min, job timeout about 70 min.
- Green-SHA skip: a `gh api` lookup of the last successful run, with the logic in a table-tested `bin/` script. It serves both the flake and Browser-full nightlies.
- ECON-03: dispatch only when no PAT is configured, exposed through a step output.
- ECON-06 docs/tarball: removed only if proven dominated, otherwise recorded as kept.

## Claude's Discretion

- Commit and plan granularity, exact timeout values, the skip script's name, and whether to capture `--trace` CI evidence before the `:live_dialyzer` move.

## Deferred Ideas

- Re-checking the projections against real weekly and nightly samples later, possibly in Phase 222's decision record.
