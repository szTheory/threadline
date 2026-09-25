# Phase 207: Trigger Migration Rerun and Storage-Schema Default Docs - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-09-24
**Phase:** 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
**Areas discussed:** Rerun naming, Rerun SQL (up), Rerun rollback (down), Regression tests, Docs, Release

Mode: advisor (the `minimal_decisive` tier) with text mode. Three parallel
`gsd-advisor-researcher` agents covered naming, SQL/rollback semantics, and
test shape. The orchestrator covered docs and release from the codebase. One
recommendation set was presented with a single confirm/override prompt,
following the user's standing research-then-recommend preference.

---

## Rerun naming

| Option | Description | Selected |
|--------|-------------|----------|
| Ordinal only on collision | Keep `threadline_triggers_<suffix>`. Append `_2`, `_3` when the name or module is taken. The module is derived from the final name | ✓ |
| Always embed version | `..._threadline_triggers_posts_<version>` / `ThreadlineTriggersPosts<version>` | |

## Rerun SQL (up)

| Option | Description | Selected |
|--------|-------------|----------|
| `CREATE OR REPLACE TRIGGER` every run, plus a non-CASCADE drop of the orphaned per-table function | PG14+ (the floor), one statement, no capture gap | ✓ |
| `DROP TRIGGER IF EXISTS` + `CREATE TRIGGER` | Any PG version, but a gap outside a transaction and NOTICE noise | |

## Rerun rollback (down)

| Option | Description | Selected |
|--------|-------------|----------|
| Per-table: a first run drops as today, a rerun keeps capture and carries a comment | Fail-open edge case named (a rolled-back redaction removal) | ✓ |
| Raise (irreversible) | Honest, but blocks `ecto.rollback --step N` | |
| Keep today's drop | Silently leaves the table uncaptured | |

## Regression tests

| Option | Description | Selected |
|--------|-------------|----------|
| Two tiers: a file-level test in a new `gen_triggers_test.exs`, plus a DB scratch-table test of the trigger SQL | Keeps the 206 no-Migrator rule | ✓ |
| Full `Ecto.Migrator.run` on a tmp prefix | Breaks 206 D-10, pollutes the shared DB | |

## Docs

| Option | Description | Selected |
|--------|-------------|----------|
| Fix all 3 wrong-default sites (incl. `how-threadline-works.md:94`, which the audit missed), widen the default test to all guides, update the rerun guidance | | ✓ |

## Release

| Option | Description | Selected |
|--------|-------------|----------|
| `fix(gen.triggers)` → 0.10.2 with the 206 fix, hand-written CHANGELOG entry quoting both errors | The `create_trigger/3` change is treated as a fix, not a breaking change | ✓ |

**User's choice:** "what's your rec? let's go with that". The full recommended set was accepted.

## Claude's Discretion

Helper names and signatures, the exact wording of the comment, guide and CHANGELOG text, where the DB-tier test file goes, and the plan/commit split.

## Deferred Ideas

- W3 custom `:priv` path in gen.triggers
- Storing earlier trigger definitions so a rerun can be truly reversed
