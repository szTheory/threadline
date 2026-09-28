Lands the v1.42 "Capture Correctness for Real Table Shapes" milestone branch on `main`. This PR is meant to be squash-merged, so the commit subjects on the branch stay out of release-please's changelog.

## What adopters get (released as 0.11.0)

- Capture now resolves a table's real primary key, whatever its name, type, or column count: a single column of any name, a composite key of multiple columns, or a configured `primary_key:` override. A table with no usable key fails at migrate time instead of silently keying on a column named `id`.
- `Threadline.history/3`, `Threadline.as_of/4`, and row history accept and match composite keys given as a map or keyword list, and now raise `ArgumentError` for an invalid, `nil`, or mismatched key instead of silently returning nothing.
- New health reporting (`Threadline.Health.trigger_findings/1`, wired into `mix threadline.health.coverage` and `mix threadline.verify_coverage`) finds broken or misconfigured capture: disabled or replica-only triggers, drifted keys, duplicate triggers, and two tables that were silently sharing one capture function.
- `mix threadline.gen.row_history_index` adds the index that `history`, `as_of`, and row history now rely on, for installs that predate it.

## Breaking changes and required action

`trigger_coverage/1` no longer counts a disabled or replica-only trigger as covered; `history`/`as_of` now raise instead of returning `[]`/an error tuple for an invalid key; `mix threadline.install` now rejects unrecognized flags; and trigger generation now requires and enforces a real primary key. Full list, exact fix commands, and the upgrade order are in `CHANGELOG.md`'s `[0.11.0]` entry and `guides/upgrading-to-0.11.md`.

## Security

Releases up to 0.10.2 could give two audited tables one shared per-table capture function, so writes to one table could be captured under the other's redaction rules. This release fixes the sharing for tables regenerated together going forward; it does not rewrite rows already captured. Detect it with `mix threadline.health.coverage` (`shared_capture_function`); see `CHANGELOG.md`'s `[0.11.0]` Security section for the full detection and fix steps.

## Upgrade guide

`guides/upgrading-to-0.11.md` walks through the full 0.10.x -> 0.11.0 procedure: bumping the dependency, regenerating triggers (together, for any table pair that shared a function), migrating, adding the row-history index, verifying coverage, and an optional backfill for existing rows with marker-wrapped, idempotent SQL. It is proven end to end against a seeded 0.10.x fixture on real PostgreSQL, including a full rollback proof that no capture function is orphaned and no foreign trigger is dropped.

## Repository and quality work (not adopter-facing)

- Every local pre-land and pre-release gate re-run on the final tree: full suite, Dialyzer, Credo, the browser lane, `mix verify.release`, a next-minor bump rehearsal, pin checks, ExDoc build, Hex package build, the CHANGELOG/version-truth/upgrade-path doc contracts, and the PgBouncer topology + hex-evaluator lanes.
- New real-PG test coverage for every documented upgrade shape: id-keyed, non-id, composite, shared-function-pair, and refused-type (`timestamptz`) tables, plus a live-catalog rollback-all proof.

Built from 112 cherry-picked commits with every `.planning/` path filtered out, collapsed to one commit.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
