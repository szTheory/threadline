# Phase 245: Supply chain - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-25
**Phase:** 245-supply-chain
**Areas discussed:** SUP-01 Dependabot, SUP-02 SHA pinning, SUP-03 tiered audit, SUP-04 deps-health issue, cross-cutting interactions (research-then-recommend: five parallel researchers, one consolidated set, one confirm)

---

## Recommendation set (single confirm)

| Option | Description | Selected |
|--------|-------------|----------|
| Approve all | Lock the set as presented, reword SUP-01 to actions-only monthly grouped Dependabot | ✓ |
| Approve, weekly actions PR | Same set, weekly cadence (the elixir-lang/hexpm cadence) | |
| Approve, add npm security | Same set, plus a security-only npm entry for the e2e lockfile | |

**User's choice:** Approve all.

## Bot-PR merge scope

| Option | Description | Selected |
|--------|-------------|----------|
| I merge when green | Claude may merge a green grouped actions PR after the cooldown has passed (plus release-shape checks if release.yml changed); never auto-merge | ✓ |
| You merge them | Claude reviews and reports; maintainer merges | |

**User's choice:** Claude merges when green.

## Conflicts between researchers, resolved by synthesis

- **Actions Dependabot cadence:** weekly (SUP-01 researcher) vs monthly (cross-cutting researcher). Chose monthly to stay closest to "no routine noise".
- **e2e npm entry:** security-only (cross-cutting) vs left out (SUP-01). Left out, since it is a test harness.
- **Audit parsing:** SARIF fingerprints (SUP-03) vs human-readable summary lines (SUP-04). Chose SARIF through one shared helper.
- **Deps-health triggers:** daily (SUP-03) vs weekly plus path-filtered push (SUP-04). Chose daily plus path-filtered push plus dispatch.
- **Runtime allowlist key:** `{action, sha}` (cross-cutting) vs `{action, major}` (SUP-02). Chose `{action, major}` so Dependabot PRs stay green.

## Key research finding

GitHub Dependabot does not support Hex security updates, and raises no alerts for SHA-pinned actions. SUP-01 as written was unimplementable, so it was reworded (D-01).

## Claude's Discretion

Rule ids and fixture layout, the shape of the shared helper, exact CONTRIBUTING wording, and the optional hex.outdated job-summary section.

## Deferred Ideas

Service-image digest pinning, OpenSSF Scorecard, the npm e2e Dependabot entry, `verify-action-pins` on PRs, and the ephemeral-Postgres local-gate todo (routed to 246/247).
