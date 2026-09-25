# Phase 206: Installer Migration Versions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-24
**Phase:** 206-installer-migration-versions
**Areas discussed:** Version assignment, gen.triggers scope, WR-03 fold, Regression test shape, Release & adopter comms

**Mode:** The user asked for all areas, with parallel subagent research
(5 × gsd-advisor-researcher) and one consistent recommendation so they would
not need to choose. The recommendations below were adopted as locked
decisions.

---

## Version assignment

| Option | Description | Selected |
|--------|-------------|----------|
| max(now, existing max + 1s) + i, computed once | Rails `next_migration_number` pattern. Handles same-second host migrations, clock skew and future-dated hosts | ✓ |
| now + i seconds | The review's minimal fix. Still collides with a host migration generated in the same second | |

**Notes:** Ecto's `ecto.gen.migration` and `phx.gen.auth` have no guard
because each writes one file. Igniter accepts a `:timestamp` override but
does not choose versions. Oban and Carbonite avoid the problem with one
versioned migration (a lesson only).

## gen.triggers scope

| Option | Description | Selected |
|--------|-------------|----------|
| Fix both via a shared `@moduledoc false` helper | Fixes the whole defect class, including `install && gen.triggers` in one second | ✓ |
| Install only; log a todo for gen.triggers | Strict roadmap text, but leaves the identical bug in place | |

## WR-03 fold

| Option | Description | Selected |
|--------|-------------|----------|
| Fold: `{:written, f} \| :skipped`; advice only on fresh install; positive note on partial runs | Same return-shape change CR-01 forces; prevents schema split for pre-governance upgraders | ✓ |
| Defer | Keeps 206 minimal, but touches `generate/4` twice and leaves split-brain advice live | |

## Regression test shape

| Option | Description | Selected |
|--------|-------------|----------|
| File-level prefix contract + future-dated seed + partial re-run + gen.triggers-after-install | No DB or clock needed. Always RED on the current code (3 calls in under 1s cover at most 2 distinct seconds) | ✓ |
| Also run Ecto.Migrator | Its duplicate check is private (`defp`). The `run` path applies DDL to a shared test DB with no sandbox | |
| Injected clock / property test | Over-engineering for a 3-file input space | |

## Release & adopter comms

| Option | Description | Selected |
|--------|-------------|----------|
| `fix(install)` → 0.10.2 + hand-written CHANGELOG entry quoting the exact Ecto error, the workaround, and "no action for migrated apps" | Searchable, honest, cheap | ✓ |
| Also a guide Troubleshooting section + `mix hex.retire` 0.10.x | Every release since v0.1.0 has the bug, so retiring only 0.10.x would be a partial claim. The guide section would go stale after the fix | |

**Notes:** Verified during synthesis that v0.1.0 already wrote audit and
semantics with a shared `timestamp()`, and governance was first released in
v0.6.0. So every release through 0.10.1 is affected, not only 0.10.x. Exact
Ecto error string verified at `deps/ecto_sql/lib/ecto/migrator.ex:711-712`.

## Claude's Discretion

- Helper module name and signature, the exact microcopy wording within the
  locked meaning, and how the commits are split.

## Deferred Ideas

- Collapsing into a single versioned migration (Oban/Carbonite style).
- 205-REVIEW WR-01, WR-02 and WR-04 (release tooling, not the installer).
- Detecting the storage schema from migration file contents (rejected).
