# 198-23: Demo-seed tracer — two-run failure inventory, cause attribution, fix, re-measure

**Written per plan 198-23.** Task 1 measures the real `mix verify.example` failure set over two
independent runs before any code changes. Task 2 fixes the `SEED-03 manifest heroes` /
`SEED-03 leaving agent window` clusters at their cause with a red-then-green proof. Task 3
re-measures and writes the fix protocol for plans 198-24..28.

---

## Two-run failure inventory

Both runs executed from the repository root: `mix verify.example` (which runs, per
`mix.exs`'s `verify_example/1`: `cd examples/threadline_phoenix && mix deps.get && mix compile
--warnings-as-errors && mix ecto.create --quiet -r ThreadlinePhoenix.Repo && mix test` under
`MIX_ENV=test`).

**Run 1:** `109 tests, 9 failures` (full output captured to `/tmp/verify_example_run1.log`).
**Run 2:** `109 tests, 8 failures` (full output captured to `/tmp/verify_example_run2.log`).

| # | Module | Describe | Test name | Line | Failure class | Verbatim message | Run 1? | Run 2? |
|---|--------|----------|-----------|------|----------------|-------------------|--------|--------|
| 1 | `Mix.Tasks.Threadline.EvidenceShowExampleTest` | (module-level) | `mix threadline.evidence.show prints seeded retention_run row from example fiction` | `test/mix/tasks/threadline_evidence_show_example_test.exs:20` | `ExUnit.TimeoutError` | `test timed out after 60000ms` (stacktrace: `Postgrex.Protocol.msg_recv` blocked inside `ThreadlinePhoenix.Demo.Seed.Exports.run/1`'s `insert_all`, called from `ThreadlinePhoenix.Demo.Seed.run/0`, from the test's own setup) | yes | **no — non-deterministic** |
| 2 | `ThreadlinePhoenixWeb.WalkthroughEvidenceTest` | `§5 evidence plane (WALK-04-01..03)` | `WALK-04-02 redaction_policy evidence and #4521 row history shows [REDACTED]` | `test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` (helper at `:105`) | `Ecto.NoResultsError` | `expected at least one result but got none in query: from a0 in Threadline.Capture.AuditTransaction, join: c1 in assoc(a0, :changes), where: c1.table_name == "tickets", where: c1.op == "update", where: fragment("?->>'id' = ?", c1.table_pk, ^"<ticket-4521-uuid>"), where: fragment("?->>'status' = ?", c1.data_after, "closed"), order_by: [desc: a0.occurred_at], limit: 1` | yes | yes |
| 3 | `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` | `§3 daily use (WALK-02-01..03)` | `admin export status shows seeded job states` | `test/threadline_phoenix_web/walkthrough_happy_path_test.exs:145` (assertion at `:158`) | Assertion mismatch (`=~`) | `Assertion with =~ failed / code: assert html =~ "Export expired" / right: "Export expired"` (full rendered page HTML on the left, "Export expired" string absent) | yes | yes |
| 4 | `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` | `§4 operator incidents (WALK-03-01..04)` | `WALK-03-04 deleter hard-delete on #4518 visible to admin` | `test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` (assertion at `:236`) | Assertion mismatch | `Expected false or nil, got true / code: refute is_nil(at)` | yes | yes |
| 5 | `ThreadlinePhoenix.DemoContractTest` | `D-05 persona setup actor attribution` | `org_memberships setup rows have non-null actor_ref on transaction` | `test/threadline_phoenix/demo_contract_test.exs:269` | Assertion mismatch | `expected ≥1 org_memberships AuditChange with non-null actor_ref, got 0` | yes | yes |
| 6 | `ThreadlinePhoenix.DemoContractTest` | **`SEED-03 manifest heroes`** | `close reply insert is redacted on #4521` | `test/threadline_phoenix/demo_contract_test.exs:70` | `Ecto.NoResultsError` | `expected at least one result but got none in query: from a0 in Threadline.Capture.AuditTransaction, join: c1 in assoc(a0, :changes), where: c1.table_name == "tickets", where: c1.op == "update", where: fragment("?->>'id' = ?", c1.table_pk, ^"<ticket-4521-uuid>"), where: fragment("?->>'status' = ?", c1.data_after, "closed"), order_by: [desc: a0.occurred_at], limit: 1` | yes | yes |
| 7 | `ThreadlinePhoenix.DemoContractTest` | **`SEED-03 manifest heroes`** | `ticket_replied_and_closed action on #4521 close transaction` | `test/threadline_phoenix/demo_contract_test.exs:40` | `Ecto.NoResultsError` | same query shape as #6, against ticket 4521's close transaction | yes | yes |
| 8 | `ThreadlinePhoenix.DemoContractTest` | **`SEED-03 leaving agent window`** | `agent2 audit transactions fall within demo_last_tuesday through demo_epoch` | `test/threadline_phoenix/demo_contract_test.exs:105` | Assertion mismatch | `Assertion with == failed / code: assert count == 12 / left: 0 / right: 12` | yes | yes |
| 9 | `ThreadlinePhoenix.DemoContractTest` | `SEED-05 delete incident` | `hard delete on ticket_replies for #4518 by deleter not closer` | `test/threadline_phoenix/demo_contract_test.exs:156` | `Ecto.NoResultsError` | `expected at least one result but got none in query: from a0 in Threadline.Capture.AuditChange, join: t1 in assoc(a0, :transaction), where: a0.table_name == "ticket_replies", where: a0.op == "delete", where: fragment("?->>'organization_id' = ?", t1.meta, ^"<acme-org-uuid>"), where: t1.occurred_at == ^~U[2026-05-20 16:30:00Z]` | yes | yes |

**Union size: 9** (rows 1–9). **Intersection size: 8** (rows 2–9; row 1 present only in run 1).
Row 1 is marked **non-deterministic** — it is an `ExUnit.TimeoutError` on a `Postgrex` receive
inside `Seed.Exports.run/1`'s `insert_all`, consistent with ordinary connection-pool contention
during a fresh `mix ecto.create` + full-suite run, not a stable defect. This round's baseline is
the **union (9)**, not the run-2-only figure (8), per the plan's explicit instruction not to
average non-determinism away.

## Measured before-count

- **Run 1:** `109 tests, 9 failures`
- **Run 2:** `109 tests, 8 failures`
- **Baseline used for this round: 9** (the union size, stated explicitly per the plan's
  instruction — the run-to-run non-determinism is on the timeout test, not on any of this task's
  target cluster).

## Cause attribution

| # | Test | Cause | Justification |
|---|------|-------|----------------|
| 1 | `mix threadline.evidence.show` timeout | `undiagnosed` | Single-run `ExUnit.TimeoutError` on a Postgrex receive during `Seed.Exports.run/1`'s bulk insert; did not reproduce on run 2. Diagnosing a one-off connection-pool timeout is out of this task's scope (measurement only) and the failure did not recur to attribute further. |
| 2 | WALK-04-02 redaction_policy / #4521 row history | `seed-content-wrong` | Same root cause as rows 6–7 below (shared cause group A) — `hero_4521_close_reply_ids!/0` queries the identical close-transaction shape that rows 6/7 query, and it is empty for the identical reason. |
| 3 | admin export status "Export expired" | `undiagnosed` | `Threadline.OperatorSurface.Presentation`'s `"Export expired"` label requires `status == "completed"` and `expired?(expires_at, opts)` on the demo's `completed-expired` `ExportJob` row. `ExportJob` is a `Threadline.Governance` table, never touched by `Threadline.Retention.purge/1` (which only deletes `audit_changes`/orphan `audit_transactions`), so this is **not** part of cause group A. Root cause not established in this task — out of the `SEED-03` scope this task fixes; flagged for a future round. |
| 4 | WALK-03-04 deleter hard-delete on #4518 visible to admin | `seed-content-wrong` | Same root cause as row 9 (shared cause group A) — the #4518 hard-delete `AuditChange`/`AuditTransaction` this test looks up is the same row `SEED-05`'s own test looks up, and it does not exist for the identical reason. |
| 5 | D-05 org_memberships actor_ref | `seed-content-wrong` | Shares cause group A. `org_memberships` role-change is backdated to `epoch - 7 days` (`seed_variety_membership_role_change/3` in `anchors.ex`) — well inside the purge's collateral-damage window (see group A below). |
| 6 | **SEED-03 manifest heroes** — close reply insert is redacted on #4521 | `seed-content-wrong` | **Cause group A.** The #4521 close transaction (`seed_acme_close/1` in `anchors.ex`, timestamped `Manifest.last_tuesday()` = `2026-05-20T14:30:00Z`) never appears in `audit_changes` because `ThreadlinePhoenix.Demo.Seed.RetentionTail.run/1` calls `Threadline.Retention.purge(repo: Repo)` with **no cutoff override**, so the library's default policy cutoff (`DateTime.utc_now() - keep_days(30)`, real wall clock) is used. `Threadline.Retention.purge/1` has **no org-scoping** — it is a library-level global-age delete over `audit_changes.captured_at` (`lib/threadline/retention.ex:205-222`), by design (confirmed by reading the implementation). The demo intends this call to purge only org Y's (`offboarded-co`) deliberately-backdated audit footprint (`backdate_org_y_audit!/1` sets it to `epoch - 90 days`), but because the call is unscoped, it also deletes **every other org's** epoch-anchored fiction (hero close/delete, leaving-agent window, globex sample) once real wall-clock time has drifted more than `keep_days` (30) past the frozen `Manifest.epoch()` (`2026-05-27T12:00:00Z`) — which it now has (today is 2026-08-28, ~93 days past epoch). This is a genuine seed-content defect: the seed's own retention step destroys data the manifest declares as a stable contract. |
| 7 | **SEED-03 manifest heroes** — ticket_replied_and_closed action on #4521 close transaction | `seed-content-wrong` | Same cause group A as row 6 — identical missing transaction. |
| 8 | **SEED-03 leaving agent window** — agent2 audit transactions fall within demo_last_tuesday through demo_epoch | `seed-content-wrong` | Cause group A. All 12 of `seed_leaving_agent_window/1`'s transactions (`anchors.ex`, timestamped `last_tuesday() + n minutes`, `n` in `1..12`) are inside the purge's collateral window and are deleted before the test runs, so the count query returns 0 instead of 12. |
| 9 | SEED-05 delete incident — hard delete on ticket_replies for #4518 | `seed-content-wrong` | Cause group A. The #4518 delete transaction (`seed_acme_delete/1`, timestamped `last_tuesday() + 2 hours`) is inside the collateral window. |

**Shared-cause grouping:** rows 2, 4, 5, 6, 7, 8, 9 (7 of the 9 union failures, including both of
this task's target describe blocks) share **one single root cause ("cause group A")** — the
demo-seed's `RetentionTail.run/1` invoking `Threadline.Retention.purge/1` without an explicit,
demo-appropriate `:cutoff`. **A single seed fix (Task 2) addresses all seven, not seven separate
fixes.** Rows 1 and 3 are independent, `undiagnosed`, and out of this task's scope (row 1 is a
non-deterministic performance timeout; row 3 touches a non-audit-capture table).

## Explicitly not the cause

`grep -c "undefined_table" /tmp/verify_example_run1.log /tmp/verify_example_run2.log` → **`0`** in
both captured run outputs. The search_path defect closed by plan 198-19 (and independently
confirmed absent again in round 3, `198-CI-MEASUREMENT.md`) is not re-opened or re-blamed by any
failure in this inventory — every failure here is either a `Ecto.NoResultsError`, an assertion
mismatch, or one `ExUnit.TimeoutError`, never a `Postgrex.Error 42P01`.

---

## Root-cause confirmation (manual reproduction, before any file edit)

Reproduced interactively via `mix run` scripts against the real `MIX_ENV=test` database (not
`ExUnit`, to inspect intermediate seed state without sandbox rollback):

1. After a fresh `ThreadlinePhoenix.Demo.Reset.run()`, ticket 4521's `status` column is
   genuinely `"closed"` in the database (the DML happened), but `audit_changes` has **zero** rows
   for `table_name = "tickets"` matching ticket 4521's id — confirming the row-level DML
   succeeded but its `AuditChange` capture is absent from the final state.
2. A full dump of `audit_transactions` after seeding showed **only 15 rows total**, and every one
   of their `occurred_at` values fell in a narrow wall-clock-recent band (`2026-08-28
   15:18Z`–`21:18Z` — hours before the dump, matching `seed_active_agent_window/1`'s and the
   variety-pack stories' `DateTime.utc_now()`-relative timestamps). **Zero** rows carried any of
   the manifest's epoch-anchored timestamps (`2026-05-20`..`2026-05-27` range) — not even
   with a backdated value, meaning the epoch-anchored rows were never present at dump time, not
   merely mistimed.
3. Read `lib/threadline/retention.ex`: `Threadline.Retention.purge/1` deletes
   `audit_changes` rows via `WHERE ac.captured_at < ^cutoff` with no organization predicate
   anywhere in the query (`delete_change_batch/4`), and the default `cutoff` comes from
   `Threadline.Retention.Policy.cutoff_utc_datetime_usec!/0`, which is `DateTime.utc_now(:microsecond)`
   minus the configured `keep_days` — i.e., it is unconditionally global and it is unconditionally
   anchored to **real** wall-clock time, never to the demo's fictional epoch.
4. `ThreadlinePhoenix.Demo.Seed.RetentionTail.run/1` (`enable_retention!/0` +
   `Retention.purge(repo: Repo)`, no `:cutoff` option passed) therefore purges every
   `audit_changes` row older than 30 real days — which, since the demo epoch (`2026-05-27`) is now
   roughly 93 real days in the past, is **all** of the demo's epoch-anchored fiction across every
   organization, not just `offboarded-co`'s deliberately-backdated `-90 day` footprint the demo
   narrative intends to purge.

This is confirmed as `seed-content-wrong`, attributable to one function:
**`ThreadlinePhoenix.Demo.Seed.RetentionTail.run/1`** (specifically its unscoped call to
`Threadline.Retention.purge/1`).
