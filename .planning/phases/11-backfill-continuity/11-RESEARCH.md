# Phase 11 Research — Backfill / continuity (TOOL-02)

**Question answered:** What do we need to know to plan brownfield adoption without false audit history?

---

## Semantics (industry + Threadline alignment)

- **Honest T₀:** Until a row is mutated under an installed capture trigger, the database cannot attribute prior state changes. `Threadline.history/3` returning `[]` for that PK is correct and matches roadmap SC1/CONTEXT D-01.
- **Anti-pattern:** Inserting `AuditChange`-shaped rows from Elixir or migrations that mirror trigger output without a distinguishing marker violates `AuditChange` moduledoc and SC3; CONTEXT locks **trigger-only** rows for real DML.
- **Compliance baseline:** Sidecar exports or app-owned tables are the safe pattern; document explicitly as non-retroactive audit.

## Codebase anchors

- **Mix patterns:** `Mix.Tasks.Threadline.Install`, `Mix.Tasks.Threadline.VerifyCoverage` — `app.config`, repo resolution, `Mix.raise` messages, `@shortdoc` / `@moduledoc`, HexDocs `Mix Tasks` group in `mix.exs`.
- **Triggers:** `Threadline.Capture.TriggerSQL` — `create_trigger/1`, `drop_trigger/1`; tests in `test/threadline/capture/trigger_test.exs` use `DataCase`, raw SQL, `TRUNCATE` cleanup.
- **Query:** `Threadline.history/3` and query modules assume listed changes are real captures — tests should assert **zero** `AuditChange` rows for a PK after pre-data + install + before first post-install mutation.

## Brownfield test recipe

1. `CREATE TABLE` + `INSERT` row(s) **before** `create_trigger`.
2. Apply `threadline.install` migration path (fixture already has audit schema from DataCase migrations — mirror existing test DB setup).
3. Install trigger on table; assert `Repo.all(from ac in AuditChange, where: ac.table_name == ^"table"))` is empty for that PK (or count 0).
4. Run one controlled `UPDATE` or `INSERT`; assert normal `AuditChange` / `AuditTransaction` invariants (op, FK, transaction grouping) match `trigger_test.exs` style.

## API surface choice (research recommendation)

- **`Threadline.Continuity`** (or `Threadline.Capture.Cutover`) as public module with `repo:` and options map; **thin** `Mix.Tasks.Threadline.Continuity` delegating to it — matches CONTEXT D-08/D-09 and Oban-style ergonomics.
- **Mix task name:** `threadline.continuity` — short, discoverable alongside `install`, `gen.triggers`, `verify_coverage`.

## Documentation

- New file `guides/brownfield-continuity.md` (stable anchor); add to `mix.exs` `docs: extras` and `groups_for_extras`; README 3–6 bullets + deep link; `guides/domain-reference.md` cross-link.

---

## Validation Architecture

**Nyquist / execution feedback**

| Dimension | How this phase is validated |
|-----------|----------------------------|
| **Automated** | `MIX_ENV=test mix test` scoped to new `*_continuity*_test.exs` + `mix compile --warnings-as-errors` after each substantive commit; full `mix ci.all` before verify-work. |
| **Integration** | PostgreSQL-only `DataCase` module proving empty `audit_changes` until post-install mutation (brownfield fixture). |
| **Doc drift** | Optional: grep guide for required phrases (`T₀`, `audit_changes`, `history`) — primary bar is human checklist in Plan 11-02. |
| **Regression** | Existing `trigger_test.exs` / `history` tests remain green — no new default path inserts `AuditChange` from Elixir. |

**Quick command:** `MIX_ENV=test mix test test/threadline/continuity_test.exs` (path TBD by executor to match actual filename).

**Full command:** `MIX_ENV=test mix ci.all` (or project-standard CI entrypoint from `CONTRIBUTING.md`).

---

## RESEARCH COMPLETE
