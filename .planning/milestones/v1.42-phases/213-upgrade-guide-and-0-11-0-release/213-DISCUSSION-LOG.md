# Phase 213: Upgrade Guide and 0.11.0 Release - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 213-upgrade-guide-and-0-11-0-release
**Areas discussed:** Upgrade guide shape and backfill, Upgrade and rollback test harness, Release landing mechanics

Mode: advisor (`minimal_decisive`). Three `gsd-advisor-researcher` agents ran in parallel. Following the maintainer's standing instruction "auto follow your recommendations", the recommendations were accepted, apart from the orchestrator syntheses noted below. Push, merge and publish stay with the maintainer, as the roadmap requires.

---

## Upgrade guide shape and backfill

| Option | Description | Selected |
|--------|-------------|----------|
| Extend `upgrade-path.md` only | the per-minor precedent | |
| New `upgrading-to-0.11.md` only | dedicated procedure | |
| New satellite guide plus a required per-minor entry in `upgrade-path.md` | keeps the reference doc lean and satisfies the version-truth Family C contract | ✓ (orchestrator synthesis) |
| Backfill as plain SQL in the guide | SQL-native, no new public surface | ✓ |
| `mix threadline.gen.backfill` task | encoding-safe by construction; new public surface | (deferred) |

**Facts established:** `audit_changes` has no `data_before`, and 0.10.x stored no row image for DELETE (`data_after` is NULL), so DELETE rows are unrecoverable. Redacted key values were never stored. The backfill must use the `->>` text encoding.

## Upgrade and rollback test harness

| Option | Description | Selected |
|--------|-------------|----------|
| LegacyTriggerSQL + MigrationHarness fixture | the established real-PG pattern, used by 11 files | ✓ |
| `git show v0.10.2` at test time | fragile in CI and worktrees | |
| Hex evaluator as the primary proof | heavy; complementary only | |
| Test extracts the SQL from guide markers | no drift by construction | ✓ |
| Duplicate the SQL in the test | drift risk | |
| Root suite, no new entrypoint | honest default tests | ✓ |

**Gap confirmed:** no existing test proves on the live catalog that rollback leaves no orphan functions and keeps foreign triggers. This phase adds that proof.

## Release landing mechanics

| Option | Description | Selected |
|--------|-------------|----------|
| Squash title `feat!:` | honest; `bump-minor-pre-major` gives 0.11.0 | ✓ |
| Squash title `feat:` | hides the breaking changes | |
| Full local pre-land suite including the bump rehearsal | the runbook lesson | ✓ |
| Landing branch via `gsd-pr-branch`, maintainer names it at push time | the 0.10.0 (#43) precedent | ✓ |

**Facts established:**
- `hex-publish.yml` is gone.
- The evaluator's pin is exact by design.
- There are 2 `x-release-please-version` markers.
- No open PRs.
- Stray branches are listed for the maintainer to delete.

## Claude's Discretion

Guide prose, the backfill batch pattern, the test module split, and the squash title and body wording.

## Deferred Ideas

- A `gen.backfill` Mix task
- A health finding that counts unresolved rows
- Items carried from 212: `--strict`, `:invalid_config`, `--all-schemas`
