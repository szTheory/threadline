Invariant: every capture in one transaction gets a distinct, strictly increasing captured_at.

## Mutation control: capture_clock.patch

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

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 2 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}, {:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}]]
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
