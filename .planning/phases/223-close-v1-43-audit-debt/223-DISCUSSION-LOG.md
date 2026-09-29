# Phase 223: Close v1.43 Audit Debt - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-29
**Phase:** 223-close-v1-43-audit-debt
**Areas discussed:** Mint release vehicle, release.yml checkout credentials, 217 round-2 dispositions

The maintainer asked for research-then-recommend. Three parallel researchers covered one area each, and the maintainer accepted the combined set in a single confirmation.

---

## Mint release vehicle

| Option | Description | Selected |
|--------|-------------|----------|
| New `fix(deps):` PR with a real diff | Matches SC-1 literally, but no honest diff exists: the lock and CHANGELOG are already on main | |
| Empty `fix(deps):` commit | Mislabels an empty commit; squash behavior unverified | |
| `BEGIN_COMMIT_OVERRIDE` on merged #60 | Attributes the fix to the commit that made it; no fake commit; SC-1 wording amended | ✓ |
| `Release-As: 0.11.2` | Still needs a commit, and the notes carry no fix line | |
| Squash-title the B+C PR `fix(deps)` | Repeats #60's mistake in reverse | |

**User's choice:** Accept all (Recommended). Flagged HIGH-IMPACT because it amends SC-1.
**Notes:** 0.11.2 patch. Three advisories, not four (the local milestone branch CHANGELOG is stale). The guard is deferred; CONTRIBUTING gets one sentence instead.

## release.yml checkout credentials

| Option | Description | Selected |
|--------|-------------|----------|
| Only the two named checkouts | Same per-job shape that let CR-01 through | |
| Checkouts "followed by mix" | Brittle dataflow parsing; fails open | |
| Every release.yml checkout, with a 2-job reasoned allowlist | Default-deny; zizmor `artipacked` shape | ✓ |
| All workflows | Beyond phase scope | (deferred) |

**User's choice:** Accept all (Recommended).

## 217 round-2 dispositions

| Option | Description | Selected |
|--------|-------------|----------|
| Fix all six in the guard + tests | Each a few lines; a patched guard dry run stays clean | ✓ |
| Defer the hypothetical ones | WR-03 turned out to be a reproducible bypass | |
| R2-WR-04: narrow the CONTRIBUTING wording | Leaves a real leak path open | |
| R2-WR-04: anchored Linux variant | 0 false positives anchored, 539 unanchored | ✓ |

**User's choice:** Accept all (Recommended).

## Claude's Discretion

Exact regex spelling, test names, error wording, and the plan/task split.

## Deferred Ideas

The release-subject guard; checkout default-deny across all workflows; explicit-URL pushes; HYG-03 temp_leaks enforcement; the remaining 215/216/218/221 audit items.
