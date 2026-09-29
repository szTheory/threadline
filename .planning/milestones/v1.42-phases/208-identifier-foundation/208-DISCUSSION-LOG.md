# Phase 208: Identifier Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-25
**Phase:** 208-identifier-foundation
**Areas discussed:** Hashed-identifier format; migration file/module caps; migrations path; host-identifier errors; 208/209 split; REL-01

Mode: advisor + text. There were two parallel research passes (gsd-advisor-researcher, minimal_decisive tier). One recommendation set was presented and confirmed with a single roll-up answer.

---

## Trigger-name format

| Option | Description | Selected |
|--------|-------------|----------|
| A. Research rule: legacy when it fits, else `threadline_audit_<stem≤33>_<h12>` | Injective across tables, but creates a second trigger on 0.10.x long-name installs (double capture; breaks NAME-03) | |
| B. Legacy name byte-cut to 63 in Elixir, never hashed | Byte-identical to what PostgreSQL already stored; per-table scope makes cross-table uniqueness unnecessary | ✓ |

## Per-table function names / hash

| Option | Description | Selected |
|--------|-------------|----------|
| 12-hex sha256 over the parsed `"schema.table"`; legacy only for public, ≤36 bytes, not ending in `_<12hex>`; else `<stem≤23>_<h12>` | Injective except for 48-bit hash collisions; SQL-reproducible | ✓ |
| MD5 / phash2 | FIPS problems, or a range too small to reproduce in SQL | |

## Migration file/module names

| Option | Description | Selected |
|--------|-------------|----------|
| A. 63-byte stem cap with an h12 tail over the sorted qualified list; rerun matcher unchanged in 208 | Keeps 208 small; the matcher changes once, in 209 | ✓ |
| B. Cap plus the `rerun?` rewrite now | Tests against names nothing emits yet; churn in 209 | |

## Migrations path

| Option | Description | Selected |
|--------|-------------|----------|
| A. Shared `MigrationsPath` with `--migrations-path` and a single `--repo` on both tasks | Same resolution in both tasks; matches Ecto flag names | ✓ |
| B. Full `ecto.gen.migration` parity (multi-repo fan-out) | Writes triggers into the wrong repos; relies on private `Mix.EctoSQL` | |

## Host-identifier errors

| Option | Description | Selected |
|--------|-------------|----------|
| A. `ArgumentError` with a role-aware `validate_identifier!/2`, re-raised through `Mix.raise` in the task | Fixes the wording everywhere; existing tests keep working | ✓ |
| B. New `Threadline.InvalidIdentifierError` | New public API before 1.0 | |

## REL-01 (HIGH-IMPACT: semver)

| Option | Description | Selected |
|--------|-------------|----------|
| Flip `bump-minor-pre-major: true` in a first non-releasable `ci:` commit | Keeps breaks on 0.x minor bumps up the ladder to 1.0 | ✓ |
| Keep `false` and ban `!` / `BREAKING CHANGE` | Easy to get wrong; a single slip proposes 1.0.0 | |

**User's choice:** "1": accept all recommendations, with REL-01 option 1.

## Claude's Discretion
- StreamData dependency and property configuration, internal `Naming` API names, test layout.

## Deferred Ideas
- `rerun?` rewrite, hashed-function emission and orphan-safe drops go to Phase 209.
- Structured exception type: revisit at the 1.0 API review.
- The umbrella-root install fallback is pre-existing and out of scope.
