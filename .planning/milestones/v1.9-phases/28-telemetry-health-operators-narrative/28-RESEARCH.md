# Phase 28 — Technical research: telemetry & health operator narrative

**Question:** What do we need to know to plan OPS-01 / OPS-02 well?

---

## 1. Shipped telemetry contract (code)

Source: `lib/threadline/telemetry.ex`, `lib/threadline.ex`.

| Event | Emitted from | Measurements | Metadata | Notes |
|-------|----------------|-------------|----------|-------|
| `[:threadline, :transaction, :committed]` | `Threadline.Telemetry.transaction_committed/2` (public) | `table_count` (keyword default 0) | `%{}` | Accurate counts only when integrator calls this **after** a known commit. |
| `[:threadline, :transaction, :committed]` | `Threadline.Telemetry.emit_transaction_committed_proxy/0` | `table_count: 0` | `%{}` | Called from `Threadline.record_action/2` **success** path after `emit_action_recorded(:ok)` — **proxy**; not a substitute for real capture commit counts. |
| `[:threadline, :action, :recorded]` | `Threadline.Telemetry.emit_action_recorded/1` | `status`: `:ok` \| `:error` | `%{}` | Called from `Threadline.record_action/2` success and error paths. |
| `[:threadline, :health, :checked]` | `Threadline.Telemetry.emit_health_checked/2` | `covered`, `uncovered` (integer **counts**, not table lists) | `%{}` | Called at end of `Threadline.Health.trigger_coverage/1` after results computed. |

**Integrator attach point:** `:telemetry.attach/4` with event name list per `Threadline.Telemetry` `@moduledoc` examples.

---

## 2. Health & verify_coverage (code)

**`Threadline.Health.trigger_coverage/1`** (`lib/threadline/health.ex`):

- Requires `repo:` (Ecto repo).
- Enumerates `public` tables from `pg_tables`; finds tables with triggers named like `threadline_audit_%`.
- **Excludes** `audit_transactions`, `audit_changes`, `audit_actions` from the per-table result list (CAP-10 — not expected to have capture triggers).
- Returns `[{:covered, "table"} | {:uncovered, "table"}]` for each non-audit user table.
- Always emits `[:threadline, :health, :checked]` with aggregate counts.

**`mix threadline.verify_coverage`** (`lib/mix/tasks/threadline.verify_coverage.ex`):

- Uses **same** `Threadline.Health.trigger_coverage/1` call.
- Requires `config :threadline, :verify_coverage, expected_tables: [...]` (non-empty strings).
- Delegates violations to `Threadline.Verify.CoveragePolicy.violations/2`: **only expected names** are evaluated; `{:uncovered, name}` for expected = violation; missing from coverage map = `{:missing, name}`.
- Exit **1** if any violation; **0** if all expected covered.

**Doc implication:** Operators must understand: (1) `{:uncovered, "foo"}` in Health output for a table **not** in `expected_tables` does not fail the Mix task; (2) audit catalog tables never appear as rows in Health list; (3) `[:threadline, :health, :checked]` counts are **buckets**, not row-level detail.

---

## 3. Current guide state

**`guides/domain-reference.md`**

- `## Telemetry (operator reference)` — single table with three rows; links to HexDocs; retention note that purge does not emit these events.
- No per-event narrative, no triage playbook, no dedicated trigger-coverage interpretation section (only table row for health event).

**`guides/production-checklist.md`**

- §1 — bullets for `verify_coverage` config, Mix task, and `trigger_coverage/1` wiring (short).
- §6 — observability row links to `domain-reference.md#telemetry-operator-reference`.
- No expanded interpretation of `{:covered,_}` / `{:uncovered,_}` vs Mix policy, no explicit “audit tables excluded” line in §1 (REQ OPS-02 asks for this).

---

## 4. Ecosystem patterns (brief)

- **Phoenix / Plug.Telemetry:** table contract in moduledoc + prose “when to attach” in guides — matches **28-CONTEXT** D-1 split.
- **Oban:** dedicated telemetry guide chapter with failure semantics — supports “what bad looks like” subsections per event.

---

## 5. Planning risks

- **Anchor stability:** New `###` headings under Telemetry will generate GitHub/ExDoc slugs; cross-links from checklist must use matching slugs.
- **Duplication:** Keep tuple semantics aligned verbatim with `Threadline.Health` `@moduledoc` to avoid drift.
- **Scope creep:** No PromQL / vendor dashboards in canonical guides (per CONTEXT D-3).

---

## Validation Architecture

This phase is **documentation-only**; runtime behavior is unchanged.

| Dimension | Strategy |
|-----------|----------|
| Correctness vs code | Planner tasks require `read_first` on `lib/threadline/telemetry.ex`, `lib/threadline/health.ex`, `lib/mix/tasks/threadline.verify_coverage.ex`, `lib/threadline/verify/coverage_policy.ex` before editing guides. |
| Automated | After edits: `mix format`, `mix compile --warnings-as-errors`, `mix test` (full suite per project default). No new doc contract tests in Phase 28 unless optional marker added (CONTEXT D-4). |
| Manual | Spot-check relative links between `guides/domain-reference.md` and `guides/production-checklist.md` in markdown preview. |

**Quick command:** `mix format && mix compile --warnings-as-errors && mix test`  
**Estimated runtime:** order of project’s full test suite (CI parity).

---

## RESEARCH COMPLETE
