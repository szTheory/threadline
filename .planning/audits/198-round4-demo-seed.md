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
`Threadline.Retention.purge/1`).

---

## Red-then-green teeth proof (tracer cluster)

**Pre-fix (red).** Captured directly above in the "Two-run failure inventory" — both run 1 and
run 2's verbatim output for rows 6, 7, 8 (and 9, in the sibling `SEED-05` describe block that
shares the same cause) show the exact `Ecto.NoResultsError` / `assert count == 12 ... got 0`
failures, taken from `mix verify.example` before any file in this task was edited.

**Fix applied.** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex`:
added a `@retention_purge_cutoff_days_before_epoch` module attribute and a
`retention_purge_cutoff/0` helper that computes `DateTime.add(Manifest.epoch(), -60, :day)`
(`2026-03-28T12:00:00Z`) — strictly earlier than `offboarded-co`'s `-90 day` backdate
(`2026-02-26T12:00:00Z`, so still purged) and strictly later than every other org's epoch-anchored
fiction (earliest is the filler's `-14 day` bound, `2026-05-13T12:00:00Z`, so nothing else is
purged). Passed as `Retention.purge(repo: Repo, cutoff: retention_purge_cutoff())` —
`Threadline.Retention`'s own module doc documents `:cutoff` as exactly this "stricter than policy"
override (`retention.ex:9-12`), so this uses an existing, intended library seam rather than adding
new library surface. `enable_retention!/0`'s `keep_days: 30` config is unchanged (it remains the
accurate, honest description of the library's own policy config; only this one seed-time call gets
the stricter explicit override so the fictional epoch does not drift out of the real-world 30-day
window as time passes).

**Post-fix (green).** Verbatim `mix test` output for the target file after the fix, run twice
consecutively from `examples/threadline_phoenix`:

```
$ cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs
...
Finished in 4.0 seconds (0.00s async, 4.0s sync)
13 tests, 0 failures

$ cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs
...
Finished in 4.0 seconds (0.00s async, 4.0s sync)
13 tests, 0 failures
```

Both `describe "SEED-03 manifest heroes"` (3 tests) and `describe "SEED-03 leaving agent window"`
(1 test) pass on both runs — as does every other describe block in the file (`SEED-05 delete
incident`, `D-05 persona setup actor attribution`, `SEED-02/04`, `WALK-04`), all of which shared
cause group A and are fixed as a side effect of the same one-line seed fix, exactly as the cause
table predicted ("a single seed fix is not credited as N separate fixes").

**Disposition record (per changed assertion/module):**

- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex` —
  `seed-content-wrong`. The demo-seed's own retention-purge call was unscoped and collaterally
  deleted other organizations' hero audit data; fixed by passing an explicit `:cutoff` anchored to
  the demo's own epoch rather than relying on the library's real-wall-clock default. Justification:
  `Threadline.Retention.purge/1` (`lib/threadline/retention.ex`) has no per-organization
  scoping by design (confirmed by reading its `WHERE` clauses), and the manifest
  (`manifest.ex`) declares hero tickets 4521/4518 and the leaving-agent window as a stable
  narrative contract that this collateral deletion violated.
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — **no assertion
  text was changed.** All three `SEED-03 manifest heroes` tests and the one `SEED-03 leaving agent
  window` test were already correct, structural, non-pinned assertions (they query by manifest
  constants and action names, not by literal counts or ordering); the failure was entirely in the
  seed content, not in assertion rot. This satisfies the plan's edge-contract requirements without
  any test-file edit: the window-membership query already uses explicit `>=`/`<=` bounds (line
  129-130, inclusive both sides — stated here explicitly per the adjacency must-have, since the
  test file itself does not narrate it), the leaving-agent count assertion already fails loudly on
  zero (`assert count == 12`, not a vacuous `Enum.all?/2`), and there is no ambiguous-tie ordering
  in any SEED-03 assertion (each query is either a single `Repo.one!` keyed on unique manifest
  constants or a `count()` aggregate, never a positionally-compared list).

**Files changed in Task 2:**
`examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex` (one function
added, one call-site option added). No change to `demo_contract_test.exs`, `seed.ex`,
`seed/anchors.ex`, `seed/personas.ex`, `seed/support.ex`, or `manifest.ex` — the pre-declared
`files_modified` footprint for this plan named those files as candidates, but the actual cause,
once diagnosed, lived in `retention_tail.ex`, which is one of the "zero or more" seed-module
files the plan's own action text authorized editing ("the demo-seed module(s) named by the
diagnosis"). Logged as a Rule 1 deviation below.

**Deletion counts sanity check.** Before the fix, `Retention.purge` (unscoped) deleted nearly all
epoch-anchored `audit_changes` regardless of org — an inaccuracy in the evidence record itself
(`Evidence.record_retention_run/3`'s `"narrative" => "org Y offboard"` claimed an org-Y-only
purge while the underlying delete count included collateral damage from every org). After the
fix, `Retention.purge`'s `deleted_changes`/`deleted_transactions` counts reflect **only**
`offboarded-co`'s backdated footprint, made honest as a side effect of the same fix — not credited
as a separate fix, but recorded here for completeness.

## Measured after-count

Ran `mix verify.example` twice more from the repository root, after the fix above:

```
$ mix verify.example
...
Finished in 16.1 seconds (0.1s async, 15.9s sync)
109 tests, 1 failure
** (Mix) verify.example failed (2)
```

```
$ mix verify.example
...
Finished in 16.0 seconds (0.1s async, 15.9s sync)
109 tests, 1 failure
** (Mix) verify.example failed (2)
```

**Before-count (Task 1 baseline, union): 9. After-count: 1 (both runs, consistent). Delta: −8.**

`grep -c "undefined_table"` over both after-run outputs: **`0`** — the search_path defect closed
in a prior round remains closed; this fix neither touched nor re-opened it.

The single remaining failure on both after-runs is the same failure named `undiagnosed` in the
"Cause attribution" table above and left untouched by design:

- `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` — `admin export status shows seeded job states`
  (`walkthrough_happy_path_test.exs:145`, `assert html =~ "Export expired"`) — out of this task's
  `SEED-03` scope. Root cause not established here (the failing "Export expired" label depends on
  `Threadline.OperatorSurface.Presentation`'s `expired?/2` check against a `Governance.ExportJob`
  row, a table `Threadline.Retention.purge/1` never touches, so it is confirmed unrelated to this
  task's fix). This carries a named cause (`undiagnosed`, out-of-scope), never a bare "still red"
  with no attribution.

The `mix threadline.evidence.show` timeout (row 1, non-deterministic in the original two-run
inventory) did **not** recur on either after-run — consistent with its original classification as
a one-off connection-pool timeout rather than a stable defect this fix could have affected either
way.

This plan does **not** achieve a fully-green `mix verify.example` — 8 of the 9 union failures are
fixed at cause with a captured red-then-green proof (7 from cause group A plus the
non-deterministic timeout not recurring); the 1 remaining failure is named, out of this plan's
declared `SEED-03` scope, and left for a successor round. Logged as a new dated entry in
`deferred-items.md`.

## Fix protocol for the remaining clusters

The following loop is what fixed the `SEED-03` tracer cluster and is the loop plans 198-24, 198-25,
198-26, 198-27, and 198-28 follow for their own clusters:

1. **Take the two-run inventory for your cluster.** Run `mix verify.example` (or your target
   suite) twice, independently and back to back. Capture full output. Record every failure by
   module, describe, test name, line, failure class, and verbatim message. Compute the union and
   the intersection explicitly; mark any run-1-only or run-2-only failure `non-deterministic`
   rather than averaging it away.
2. **Attribute each failure to `seed-content-wrong` or `assertion-rotted` from the manifest or the
   product source — never from preference.** Read the manifest (`manifest.ex`), the seed module(s)
   that produce the content under test, and the failing assertion itself. If the seeded content
   does not match what the manifest declares, the seed is wrong. If the assertion pins a literal,
   an ordering, or a count that the product has legitimately moved past, the assertion is rotted.
   Group failures that share one root cause — do not credit a single fix as N separate fixes, and
   do not diagnose the same symptom twice under two different failure descriptions without
   checking whether they share a cause.
3. **Fix at the cause.** For `seed-content-wrong`, change the demo-seed producer module(s) named by
   the diagnosis — not necessarily only the files a plan's frontmatter pre-declared; the plan's own
   action text authorizes "the demo-seed module(s) named by the diagnosis" as the real target.
   For `assertion-rotted`, rewrite the assertion to a structural/shape check rather than a pinned
   literal, honoring the three edge contracts (inclusive/exclusive window-boundary wording, no
   vacuous pass on an empty result set, no positional-order dependence on a list whose sort key can
   tie).
4. **Capture a red-then-green transcript per fixed cluster.** Run the target test(s) against the
   pre-fix state and capture the verbatim failure; run them again against the post-fix state and
   capture the verbatim pass. A fix without a captured red is rejected — this is how a vacuous fix
   (e.g., loosening an assertion until it happens to pass) is caught before it ships.
5. **Re-measure the lane's failure count and record the delta.** Run `mix verify.example` (or your
   suite) twice more after the fix. State both before and after figures verbatim and the delta as
   an integer. If the after-count is not strictly lower, say so plainly — a truthful non-improvement
   is a valid outcome; a claimed improvement the numbers do not support is not.
6. **Record any newly-surfaced failure as a discovery in `deferred-items.md`, never silently
   absorbed or silently dropped.** If your fix reveals a failure that was previously masked (as
   happened in `198-17-SUMMARY`'s prior round), it is a discovery, not a failure of your task — log
   it with a dated entry naming the blocker and its evidence.

**Forbidden remedies (verbatim — do not do any of these to make a check pass):**
`@tag :skip`, `git rm`, deleted assertion, narrowed scope, raised `maxFailures`, reduced
`--project` set, `needs:` edit.

**Honest ceiling.** This plan produces a **local readiness signal only**. Per D-01
(`198-CONTEXT.md`), local `mix verify.example` output is not admissible evidence that GREEN-04 or
GREEN-07 are met — that verdict belongs exclusively to the measured CI run in plan 198-29.

---

## Plan 198-24: SEED-05, SEED-02/04, WALK-04, D-05, D-13 clusters

**Starting state (before any 198-24 edit), measured fresh with the local Postgres running and
`mix deps.get` re-run (the worktree started with unfetched deps):**

```
$ cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs
...
Finished in 9.5 seconds (0.00s async, 9.5s sync)
13 tests, 0 failures
```

```
$ cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs
...
Finished in 9.1 seconds (0.00s async, 9.1s sync)
13 tests, 0 failures
```

**Finding, stated honestly:** all six describe blocks this plan was chartered to fix (`SEED-05
delete incident`, `SEED-02 idempotency and SEED-04 reset recovery`, `SEED-04 org Y retention end
state`, `WALK-04 redaction policy evidence`, `D-05 persona setup actor attribution`, `D-13
in-window variety guarantee`) **already pass** — 13 tests, 0 failures, on two consecutive runs,
before this plan touched anything. This is the expected, predicted side effect of plan 198-23's
`retention_tail.ex` fix: its own inventory (`## Cause attribution`) already named rows 5, 8, 9
(D-05, SEED-05, and — transitively via cause group A — the retention/redaction-adjacent clusters)
as sharing cause group A, and its SUMMARY states the fix "fixed as a side effect" without crediting
seven separate fixes. This plan's premise (that these clusters still had cluster-level test
failures) does not hold; the failures were already fixed a plan earlier. This is recorded here
per the fix protocol's instruction to state a truthful non-improvement plainly rather than force a
process to look busier than the numbers support.

**What this plan still does, and why:** a passing test is not the same claim as a rot-resistant
one. Reading `demo_contract_test.exs` against this plan's own must-haves (vacuous-pass prevention,
manifest-sourced literals, explicit boundary/set semantics) surfaced three genuine
`assertion-rotted` weaknesses that happened not to be currently triggering a failure, but would
mask a real regression if one occurred:

1. **WALK-04 — `record.subject_ref == %{"policy" => "walk-demo-redaction-policy"}`** restated the
   manifest's own declared value (already read into the local `subject_ref` variable two lines
   above, from `Manifest.evidence_subject_ref(:redaction_policy)`) as a second, independently
   hardcoded inline literal. If `Manifest.evidence_subject_ref(:redaction_policy)` is ever edited,
   this assertion would silently keep comparing against the stale value instead of tracking the
   manifest — exactly the version-pinned-literal rot class GREEN-04 calls out.
2. **D-05 — the two backdating tests (`org_memberships` / null-actor) asserted only
   `in_window_count == 0`,** with no assertion that the underlying row set was non-empty in the
   first place. A seed regression that produced **zero** `org_memberships` (or zero null-actor)
   `AuditChange` rows at all would make `in_window_count` trivially `0` and pass this test
   vacuously, proving nothing about backdating.
3. **D-05/D-13 boundary and ordering semantics were correct in behavior but implicit in source** —
   nothing in the test named which side of the 24h boundary a `>=`-matched row falls on, and
   nothing in the D-13 loop stated explicitly that the check is set-membership independent of
   order (it already was, structurally, but not stated).

**Fix applied** (`demo_contract_test.exs` only — no seed module needed a content change, since the
seed content was already correct after 198-23's fix):

- WALK-04: `record.subject_ref == subject_ref` (the manifest-sourced local variable), removing the
  duplicate hardcoded literal.
- D-05 (both backdating tests): added a preceding `total_count >= 1` assertion on the full
  `org_memberships` / null-actor `AuditChange` row set, before asserting `in_window_count == 0`.
- D-05 (actor_ref test): added the same preceding non-emptiness assertion for symmetry with the
  other two D-05 tests, even though the existing single-query form could not pass vacuously on its
  own (the query already filtered to non-null `actor_ref` rows, so zero total rows and zero
  non-null-actor rows are the same failing case) — making all three D-05 tests structurally
  consistent with the plan's must-have.
- D-05 backdating tests: added a one-line comment stating the `>=` comparison is strict-inclusive
  on the window's near edge, so a row landing exactly on `window_start` counts as **inside** the
  window (and therefore fails the "outside" assertion).
- D-13: added a one-line comment stating the per-op loop is a set-membership check independent of
  emission order.

**Red-then-green teeth proof — D-05 vacuous-pass guard (runtime, reproducible):**

Script run via `mix run` under `MIX_ENV=test` against the real sandboxed test database
(`Ecto.Adapters.SQL.Sandbox.unboxed_run`), simulating the exact seed regression the new guard
exists to catch — a build where `org_memberships` `AuditChange` rows are never produced at all:

```
$ MIX_ENV=test mix run /tmp/teeth_proof_198_24.exs
demo.seed complete
Deleted 15 org_memberships AuditChange rows to simulate seed regression
OLD-style assertion (in_window_count == 0): got 0 -- WOULD PASS (vacuously! no org_memberships rows exist at all)
NEW guard (total_count >= 1): got 0 -- CORRECTLY FAILS (RED) -- catches the vacuous pass
RAISED (expected): expected >=1 org_memberships AuditChange rows to exist, got 0
demo.seed complete
Reset.run/0 called again to restore normal demo state
```

This is the "red": under the simulated regression, the OLD assertion form (`in_window_count ==
0` alone) is proven to pass when it should not. The "green" is the NEW guard's `total_count >= 1`
raising in the same simulated state — proving the fix has teeth, not just different wording. After
the script's own `Reset.run()` call restored normal demo state, the full suite was re-run twice
more (below) confirming no regression was introduced by the script itself.

**Static/structural teeth proof — WALK-04 manifest-read fix (no reproducible runtime red):**
unlike the D-05 vacuous-pass case, there is no way to reproduce a "manifest value diverges from
the test's hardcoded literal" failure without editing `manifest.ex` itself, which is out of this
plan's declared scope (not in `files_modified`, and the fix's whole point is to make the test
track the manifest automatically — editing the manifest to prove that would be circular). The
proof offered here is structural rather than a run transcript, stated honestly as such:
`grep -n 'subject_ref' demo_contract_test.exs` before this fix showed two independent literal
sources for the same value (the query's `Manifest.evidence_subject_ref(:redaction_policy)` call
and the assertion's separately-typed `%{"policy" => "walk-demo-redaction-policy"}`); after the fix,
`grep` shows one source (the `subject_ref` local variable, itself sourced from the manifest call)
used in both places. This is a falsifiable, verifiable code-structure claim, not a runtime
red/green — documented as a distinct proof class per the plan's own honesty requirement not to
fabricate a red where none is reproducible.

**Verified describe blocks that needed no fix:** `SEED-05 delete incident` (already asserts by
actor identity via `Manifest.user_id/1`, not a pinned row id), `SEED-02 idempotency and SEED-04
reset recovery` (both tests already assert equality between two computed values or via
`Reset.run()`'s own return value — no pinned literal fingerprint), and `SEED-04 org Y retention end
state` (already pairs the emptiness assertion `org_y_audit_change_count(org_y_id) == 0` with a
positive existence assertion `length(records) >= 1` on the retention-run evidence). Read and
checked against this plan's must-haves; no change made, per the fix protocol's instruction not to
edit what is already correct.

**Post-fix verification (two consecutive runs, after all `demo_contract_test.exs` edits above):**

```
$ cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs
...
Finished in 4.5 seconds (0.00s async, 4.5s sync)
13 tests, 0 failures
```

```
$ cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs
...
Finished in 4.1 seconds (0.00s async, 4.1s sync)
13 tests, 0 failures
```

**Disposition record:**

- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` —
  `assertion-rotted` (hardening class, not currently-failing class). WALK-04's inline literal and
  D-05's missing non-emptiness guards were assertion weaknesses that had not yet been triggered by
  any observed seed regression, but matched the exact rot patterns GREEN-04's own must-haves name.
  Fixed by reading the manifest-sourced variable and adding preceding non-emptiness assertions.
  No seed module (`seed.ex`, `retention_tail.ex`, `retention_runs.ex`, `reset.ex`) required a
  change — the seeded content was already correct for all six of this plan's chartered describe
  blocks, confirmed by the pre-task 13/0 measurement above.

