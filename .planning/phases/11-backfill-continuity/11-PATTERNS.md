# Phase 11 — Pattern map (PATTERNS.md)

**Phase:** 11 — Backfill / continuity  
**Purpose:** Closest analogs in repo for new Mix module, public API, tests, and docs.

---

## New: `lib/mix/tasks/threadline.continuity.ex`

**Role:** Operator CLI for brownfield semantics; thin delegation.

**Analog:** `lib/mix/tasks/threadline.verify_coverage.ex`

**Excerpts / conventions:**

- `use Mix.Task`; `@shortdoc` one line; `@moduledoc` with Usage, warnings, link to guide.
- `run/1`: `Mix.Task.run("app.config", [])`, `Application.ensure_all_started` for `:ssl`, `:postgrex`, `:ecto_sql` (match verify_coverage).
- Repo resolution: `Application.get_env(:threadline, :ecto_repos)` → first repo; `Mix.raise` with actionable substring on misconfig.
- Optional `--dry-run` / `--explain`: print steps only (CONTEXT D-10).

---

## New: `lib/threadline/continuity.ex` (name per plan — TBD)

**Role:** Public programmatic API (`repo:`, options).

**Analog:** Logic split like `Threadline.Verify.CoveragePolicy` (pure) + task (I/O); for continuity, a single small module may suffice if no policy split is needed.

**Conventions:** `@moduledoc` references `guides/brownfield-continuity.md`; functions accept `repo:` keyword.

---

## New: `test/threadline/continuity_brownfield_test.exs` (filename TBD)

**Role:** PostgreSQL integration — rows exist before trigger; empty audit until post-install mutation.

**Analog:** `test/threadline/capture/trigger_test.exs`

**Pattern:**

- `use Threadline.DataCase`
- `setup_all`: `CREATE TABLE`, `INSERT` rows, **then** `Threadline.Capture.TriggerSQL.create_trigger("…")`
- `on_exit`: drop trigger, drop table
- `setup`: `TRUNCATE` target + `Repo.delete_all` audit tables (FK order per `DataCase`)

---

## New: `guides/brownfield-continuity.md`

**Role:** Canonical operational narrative (CONTEXT D-12).

**Analog:** `guides/domain-reference.md` — section structure, cross-links, code fences for SQL bundles (`BEGIN`…`COMMIT` per D-07).

---

## Modified: `README.md`

**Analog:** Phase 10 README edits for `verify_coverage` — short bullets + link to deep doc.

---

## Modified: `mix.exs`

**Analog:** Existing `extras:` and `groups_for_modules` entries for `Mix.Tasks.Threadline.VerifyCoverage` — add new task + guide path.

---

## Modified: `guides/domain-reference.md`

**Analog:** Cross-links to other guides; add one paragraph + link to brownfield guide under capture / operator section.
