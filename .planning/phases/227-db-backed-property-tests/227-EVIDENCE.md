# Phase 227: DB-Backed Property Tests - Evidence

## SC-4 mutation controls

Each control below was produced and verified with the hardened, re-runnable
runner (D-23):

`bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh <patch> <red-file> [K]`

Every run refuses to start on a dirty `lib/`, reverses the patch via a trap,
and re-checks `git diff --quiet -- lib` after reverting, so no mutated `lib/`
was ever committed.

### PROP-04 redaction leak

#### changed_from mask

Invariant: a masked column's prior value never appears in changed_from.

```diff
diff --git a/lib/threadline/capture/trigger_sql.ex b/lib/threadline/capture/trigger_sql.ex
index 9c06d291..4c594791 100644
--- a/lib/threadline/capture/trigger_sql.ex
+++ b/lib/threadline/capture/trigger_sql.ex
@@ -580,14 +580,11 @@ defmodule Threadline.Capture.TriggerSQL do
     """
   end

-  defp per_table_changed_from_sql(mask_array_sql, placeholder_expr) do
+  defp per_table_changed_from_sql(_mask_array_sql, _placeholder_expr) do
     """
           SELECT jsonb_object_agg(
                    u.k,
-                   CASE
-                     WHEN u.k = ANY(#{mask_array_sql}) THEN #{placeholder_expr}
-                     ELSE to_jsonb(OLD) -> u.k
-                   END
+                   to_jsonb(OLD) -> u.k
                  )
           INTO v_changed_from
           FROM unnest(v_changed_fields) AS u(k);
```

Command: `mix test test/threadline/capture/redaction_leak_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 0 successful runs):

         * Clause:    plan <- op_plan_gen()
           Generated: %{insert: %{secret_excluded: {"ZQXSECRET_excluded_s0_ZQX", "ZQXSECRET_excluded_s0_ZQX"}, secret_masked: {"ZQXSECRET_masked_s0_ZQX", "ZQXSECRET_masked_s0_ZQX"}, profile_masked: {"ZQXSECRET_profile_s0_ZQX", "ZQXSECRET_profile_s0_ZQX"}, bio: {"ZQXVISIBLE_plain_s0_ZQX", "ZQXVISIBLE_plain_s0_ZQX"}}, steps: [%{values: %{secret_excluded: {"ZQXSECRET_excluded_s1_ZQX", "ZQXSECRET_excluded_s1_ZQX"}, secret_masked: {"ZQXSECRET_masked_s1_ZQX", "ZQXSECRET_masked_s1_ZQX"}}, kind: :touch_redacted, bio: {"ZQXVISIBLE_plain_s1_ZQX", "ZQXVISIBLE_plain_s1_ZQX"}}], paired: nil, delete?: true, include_action_metadata: false}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_changed_from_mask.patch test/threadline/capture/redaction_leak_property_test.exs`

#### exclude change-detect

Invariant: an excluded column never enters changed_fields or changed_from,
even when it changes. This is the mutant the pre-existing example suite
missed before D-13 (see below).

```diff
diff --git a/lib/threadline/capture/trigger_sql.ex b/lib/threadline/capture/trigger_sql.ex
index 9c06d291..162b3239 100644
--- a/lib/threadline/capture/trigger_sql.ex
+++ b/lib/threadline/capture/trigger_sql.ex
@@ -398,7 +398,7 @@ defmodule Threadline.Capture.TriggerSQL do
          store_changed_from,
          opts
        ) do
-    except_sql = changed_fields_except_array_sql(except_columns, exclude)
+    except_sql = changed_fields_except_array_sql(except_columns, [])
     fn_name = per_table_function_name(table_name, opts)
     redact_after_new = data_after_redaction_statements("v_data_after", exclude, mask, placeholder)
     mask_array_sql = mask_array_sql_fragment(mask)
```

Command: `mix test test/threadline/capture/redaction_leak_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 0 successful runs):

         * Clause:    plan <- op_plan_gen()
           Generated: %{insert: %{secret_excluded: {"ZQXSECRET_excluded_s0_ZQX", "ZQXSECRET_excluded_s0_ZQX"}, secret_masked: {"ZQXSECRET_masked_s0_ZQX", "ZQXSECRET_masked_s0_ZQX"}, profile_masked: {"ZQXSECRET_profile_s0_ZQX", "ZQXSECRET_profile_s0_ZQX"}, bio: {"ZQXVISIBLE_plain_s0_ZQX", "ZQXVISIBLE_plain_s0_ZQX"}}, steps: [%{values: %{secret_excluded: {"ZQXSECRET_excluded_s1_ZQX", "ZQXSECRET_excluded_s1_ZQX"}, secret_masked: {"ZQXSECRET_masked_s1_ZQX", "ZQXSECRET_masked_s1_ZQX"}}, kind: :touch_redacted, bio: {"ZQXVISIBLE_plain_s1_ZQX", "ZQXVISIBLE_plain_s1_ZQX"}}], paired: nil, delete?: true, include_action_metadata: false}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

**Before the example fix.** `--inverted` run: `redaction_leak_property_test.exs`
(RED_FILE) must go red on every seed while `trigger_redaction_test.exs` (the
pre-D-13 example suite, GREEN_FILE) must stay green on every seed. This is
the coverage gap the property closes: the current example suite misses this
mutant.

Command: `mix test test/threadline/capture/redaction_leak_property_test.exs --seed <seed>` (RED), with
`trigger_redaction_test.exs` run inverted (asserted green) at the same seed.

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean. `--inverted`
GREEN_FILE (`trigger_redaction_test.exs`, pre-D-13) exited 0 at every seed —
the existing example suite did not notice this mutant.
```

**After the example fix.** D-13 added two assertions to
`trigger_redaction_test.exs`'s UPDATE example (`refute "password" in
change.changed_fields`, `refute Map.has_key?(change.changed_from,
"password")`). `mix test test/threadline/capture/trigger_redaction_test.exs`
is green on unmutated `lib/`. Re-running the same mutation control against
the now-fixed example file:

Command: `mix test test/threadline/capture/trigger_redaction_test.exs --seed <seed>`

```text
seed=1 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=2 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=3 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=4 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=5 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_exclude_change_detect.patch test/threadline/capture/redaction_leak_property_test.exs`

#### update path

Invariant: an UPDATE stores the masked/excluded form, exactly like an INSERT.

```diff
diff --git a/lib/threadline/capture/trigger_sql.ex b/lib/threadline/capture/trigger_sql.ex
index 9c06d291..cf12f3a8 100644
--- a/lib/threadline/capture/trigger_sql.ex
+++ b/lib/threadline/capture/trigger_sql.ex
@@ -452,7 +452,6 @@ defmodule Threadline.Capture.TriggerSQL do
         v_row := to_jsonb(NEW);
     #{PrimaryKeySQL.row_key_statements()}
         v_data_after := v_row;
-    #{redact_after_new}

         SELECT array_agg(n.key ORDER BY n.key)
         INTO   v_changed_fields
```

Command: `mix test test/threadline/capture/redaction_leak_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 0 successful runs):

         * Clause:    plan <- op_plan_gen()
           Generated: %{insert: %{secret_excluded: {"ZQXSECRET_excluded_s0_ZQX", "ZQXSECRET_excluded_s0_ZQX"}, secret_masked: {"ZQXSECRET_masked_s0_ZQX", "ZQXSECRET_masked_s0_ZQX"}, profile_masked: {"ZQXSECRET_profile_s0_ZQX", "ZQXSECRET_profile_s0_ZQX"}, bio: {"ZQXVISIBLE_plain_s0_ZQX", "ZQXVISIBLE_plain_s0_ZQX"}}, steps: [%{values: %{secret_excluded: {"ZQXSECRET_excluded_s1_ZQX", "ZQXSECRET_excluded_s1_ZQX"}, secret_masked: {"ZQXSECRET_masked_s1_ZQX", "ZQXSECRET_masked_s1_ZQX"}}, kind: :touch_redacted, bio: {"ZQXVISIBLE_plain_s1_ZQX", "ZQXVISIBLE_plain_s1_ZQX"}}], paired: nil, delete?: true, include_action_metadata: false}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/redaction_update_path.patch test/threadline/capture/redaction_leak_property_test.exs`

### PROP-06 as_of replay

#### as_of_le

Invariant: as_of at exactly a change's captured_at includes that change.

```diff
diff --git a/lib/threadline/query.ex b/lib/threadline/query.ex
index 94ba11f1..0a730233 100644
--- a/lib/threadline/query.ex
+++ b/lib/threadline/query.ex
@@ -487,7 +487,7 @@ defmodule Threadline.Query do

     AuditChange
     |> where_row(matched)
-    |> where([ac], ac.captured_at <= ^timestamp)
+    |> where([ac], ac.captured_at < ^timestamp)
     |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
     |> order_by([ac], desc: ac.captured_at)
     |> order_by([ac], desc: ac.id)
```

Command: `mix test test/threadline/query/as_of_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 0 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}]]
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_le.patch test/threadline/query/as_of_property_test.exs`

#### as_of_order

Invariant: as_of returns the latest change at or before the timestamp, not
the earliest.

```diff
diff --git a/lib/threadline/query.ex b/lib/threadline/query.ex
index 94ba11f1..9fd55a6d 100644
--- a/lib/threadline/query.ex
+++ b/lib/threadline/query.ex
@@ -489,7 +489,7 @@ defmodule Threadline.Query do
     |> where_row(matched)
     |> where([ac], ac.captured_at <= ^timestamp)
     |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
-    |> order_by([ac], desc: ac.captured_at)
+    |> order_by([ac], asc: ac.captured_at)
     |> order_by([ac], desc: ac.id)
     |> limit(1)
   end
```

Command: `mix test test/threadline/query/as_of_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 2 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}, {:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "O'Brien", "note" => nil}, [:name]}]]
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_order.patch test/threadline/query/as_of_property_test.exs`

#### as_of_delete

Invariant: as_of after a delete reports the row as deleted.

```diff
diff --git a/lib/threadline/query.ex b/lib/threadline/query.ex
index 94ba11f1..8c69c25b 100644
--- a/lib/threadline/query.ex
+++ b/lib/threadline/query.ex
@@ -473,7 +473,6 @@ defmodule Threadline.Query do
       |> repo.one(storage_opts([], opts))

     case snapshot do
-      %AuditChange{op: "delete"} -> {:error, :deleted_record}
       %AuditChange{data_after: data_after} -> load_as_of_snapshot(schema_module, data_after, opts)
       nil -> {:error, :before_audit_horizon}
     end
```

Command: `mix test test/threadline/query/as_of_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=2 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=5 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 4 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}, :delete]]
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_delete.patch test/threadline/query/as_of_property_test.exs`

#### capture_clock

Invariant: every capture in one transaction gets a distinct, strictly
increasing captured_at. Only a real-mutation fixture can catch this
capture-layer mutant.

```diff
diff --git a/lib/threadline/capture/trigger_sql.ex b/lib/threadline/capture/trigger_sql.ex
index 9c06d291..3ae5cd55 100644
--- a/lib/threadline/capture/trigger_sql.ex
+++ b/lib/threadline/capture/trigger_sql.ex
@@ -563,7 +563,7 @@ defmodule Threadline.Capture.TriggerSQL do
         table_pk, op, data_after, changed_fields, changed_from, captured_at
       ) VALUES (
         gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
-        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, NULL::jsonb, clock_timestamp()
+        v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, NULL::jsonb, now()
       );
     """
   end
```

Command: `mix test test/threadline/query/as_of_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 2 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}, {:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}]]
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/capture_clock.patch test/threadline/query/as_of_property_test.exs`

#### as_of tiebreak — expected survivor, unreachable by design

The `order_by([ac], desc: ac.id)` tiebreak is **expected to survive** the
property.

```text
Real capture never ties (0 duplicate `captured_at` in 9,001 same-row
captures; a 38-46 microsecond minimum gap), so the uuid tiebreak is only
reachable with synthetic ties; its control is the D-17 example test, not
the property.
```

```diff
diff --git a/lib/threadline/query.ex b/lib/threadline/query.ex
index 94ba11f1..9179eb37 100644
--- a/lib/threadline/query.ex
+++ b/lib/threadline/query.ex
@@ -490,7 +490,7 @@ defmodule Threadline.Query do
     |> where([ac], ac.captured_at <= ^timestamp)
     |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
     |> order_by([ac], desc: ac.captured_at)
-    |> order_by([ac], desc: ac.id)
+    |> order_by([ac], asc: ac.id)
     |> limit(1)
   end
```

**Before the fix: the property stays green under this mutant (expected
survivor).**

```text
--inverted run: test/threadline/query_test.exs:234 (the D-17 example,
RED_FILE) must go red on every seed while as_of_property_test.exs
(GREEN_FILE, the PROP-06 property) must stay green on every seed. This is
the honestly-recorded gap: real capture never produces a captured_at tie,
so the property's own generated histories cannot reach the tiebreak
order_by at all, and the mutant survives the property by design.
```

Command: `mix test test/threadline/query_test.exs:234 --seed <seed>` (RED), with
`as_of_property_test.exs` run inverted (asserted green) at the same seed.

```text
seed=1 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=2 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=3 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=4 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=5 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean. `--inverted`
GREEN_FILE (`as_of_property_test.exs`, the PROP-06 property) exited 0 at
every seed — the property never notices this mutant, as expected
(**unreachable by design**).
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --inverted test/threadline/query_test.exs:234 .planning/phases/227-db-backed-property-tests/tools/mutations/as_of_tiebreak.patch test/threadline/query/as_of_property_test.exs`

### PROP-07 retention cutoff

#### dry-run lte

Invariant: the dry run selects rows strictly older than the cutoff.
Patching this one site alone is caught by the dry/real agreement assertion.

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..35ffb628 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -132,7 +132,7 @@ defmodule Threadline.Retention do
   defp dry_run_result(repo, cutoff, policy, storage_opts) do
     eligible_changes =
       repo.one(
-        from(ac in AuditChange, where: ac.captured_at < ^cutoff, select: count(ac.id)),
+        from(ac in AuditChange, where: ac.captured_at <= ^cutoff, select: count(ac.id)),
         storage_opts
       )

```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 2 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[0]], delete_empty?: true, batch_size: 1}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_lte.patch test/threadline/retention/cutoff_property_test.exs`

#### delete lte

Invariant: the purge deletes rows strictly older than the cutoff; patching
this one site alone is caught by the dry/real agreement assertion.

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..c4097e62 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -208,7 +208,7 @@ defmodule Threadline.Retention do
   defp delete_change_batch(repo, cutoff, batch_size, storage_opts) do
     subq =
       from(ac in AuditChange,
-        where: ac.captured_at < ^cutoff,
+        where: ac.captured_at <= ^cutoff,
         select: ac.id,
         limit: ^batch_size
       )
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 2 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[0]], delete_empty?: true, batch_size: 1}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/retention_delete_lte.patch test/threadline/retention/cutoff_property_test.exs`

#### orphan guard

Invariant: a transaction holding a surviving change is never deleted.

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..2f32a078 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -232,13 +232,6 @@ defmodule Threadline.Retention do
     subq =
       from(at in AuditTransaction,
         as: :audit_transaction,
-        where:
-          not exists(
-            from(c in AuditChange,
-              where: c.transaction_id == parent_as(:audit_transaction).id,
-              select: 1
-            )
-          ),
         select: at.id,
         limit: ^batch_size
       )
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 0 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[0]], delete_empty?: true, batch_size: 1}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/retention_orphan_guard.patch test/threadline/retention/cutoff_property_test.exs`

#### survivor update (tamper)

Invariant: survivors keep their content byte-for-byte.

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..7bcc6ed3 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -171,6 +171,17 @@ defmodule Threadline.Retention do
       Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
         n1 = delete_change_batch(repo, cutoff, batch_size, storage_opts)

+        repo.update_all(
+          from(ac in AuditChange,
+            where: ac.captured_at >= ^cutoff,
+            update: [
+              set: [captured_at: fragment("? + interval '1 microsecond'", ac.captured_at)]
+            ]
+          ),
+          [],
+          storage_opts
+        )
+
         n2 =
           if delete_empty? do
             drain_orphan_batches(repo, batch_size, storage_opts)
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 0 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[0]], delete_empty?: true, batch_size: 1}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/retention_survivor_update.patch test/threadline/retention/cutoff_property_test.exs`

#### dry-run transaction count (D-20 revert)

Invariant: the dry run counts transactions the purge itself would empty.
Caught by the dry/real agreement assertion (the dry run's
`deleted_transactions` no longer matches the real purge's orphan count once
this fix is reverted). This is the real defect (D-20) the property's own
research probes found, fixed before the agreement assertion was turned on.

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..040cdfa7 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -144,9 +144,7 @@ defmodule Threadline.Retention do
             where:
               not exists(
                 from(c in AuditChange,
-                  where:
-                    c.transaction_id == parent_as(:audit_transaction).id and
-                      c.captured_at >= ^cutoff,
+                  where: c.transaction_id == parent_as(:audit_transaction).id,
                   select: 1
                 )
               ),
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=4 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=5 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
```

```text
Shrunk counterexample (seed 1):

     Failed with generated values (after 4 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[-1]], delete_empty?: true, batch_size: 1}
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

An earlier generator reached this mutant only incidentally and surfaced
seed-dependent unreliability across seeds — the generic mixed-offset bias
only produces a fully-before-cutoff, non-empty transaction by chance. Per
the halt clause's "raise the generator's cutoff-cluster bias, never weaken
the patch" rule, `RetentionCutoffGenerators` gained a dedicated
"entirely negative" transaction branch so a purge-orphaned transaction is
reliably present.

```text
Before the fix: 90% general mixed offsets, 10% empty transactions. After:
an added ~30% entirely-negative-offsets branch. This also strengthened the
other four PROP-07 controls above (all re-run 5/5 against the updated
generator, same transactions: [[0]] shrunk fixture).
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/227-db-backed-property-tests/tools/mutations/retention_dry_run_txn.patch test/threadline/retention/cutoff_property_test.exs`

## SC-4 local acceptance

```text
See the evidence/SC5-local.md fragment, "Local acceptance (D-27)" section,
for the full verbatim output of mix test --repeat-until-failure 20 on the
three property files, one pass at the scaled env var, a full mix test, mix
verify.test_partitioned, mix verify.format, mix verify.credo, and a
warnings-as-errors compile.
```

```text
mix test --repeat-until-failure 20: all 20 repeats green. None of the
commands above was red; none was re-run to get a better figure.
```

## SC-5 wall clock before and after

### Local (local, noisy)

See the local-timing evidence fragment filed alongside this doc, in this
phase's `evidence/` directory, for the full per-run and per-module figures.
Summary:

```text
file: .planning/phases/227-db-backed-property-tests/evidence/SC5-local.md

three files' own cost, unscaled, median Finished-in:                  0.5s
three files' own cost, THREADLINE_PROPERTY_SCALE=5, median Finished-in: 1.2s
whole-suite local, noisy, median Finished-in, base: 133.1s
whole-suite local, noisy, median Finished-in, head: 128.9s
```

local, noisy: this machine's own documented load-noise floor (phase 224's
evidence doc, D-18 local-noise note) is on the same order of magnitude as
the head-vs-base gap recorded above, within the documented D-27 noise
floor, so the local whole-suite figure is not read as a per-test regression
or improvement on its own; see that evidence fragment for the full
restatement.

### CI

pending (no grant) as of this section's authoring. See the task below for
the grant and the dispatched runs, or the exact commands below if still
pending:

```text
gh workflow run ci.yml --ref milestone/v1.44
gh run list --workflow ci.yml --branch milestone/v1.44 --limit 20
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py <run> --cache-state
```

### Flake Detection at scale 5

pending (no grant) as of this section's authoring. See the task below for
the grant and the dispatched run, or the exact command below if still pending:

```text
gh workflow run flake-detection.yml --ref milestone/v1.44
gh run view <id> --log
```

## Partition weights

At the unscaled run every one of the three new property files' own median
module cost (recorded in the local-timing evidence fragment) stays well
under the two-second-per-file threshold for a solo append, so
`test/partition_weights.txt` is left untouched. `bin/ci-test-partitions
--write-weights` was never run.
