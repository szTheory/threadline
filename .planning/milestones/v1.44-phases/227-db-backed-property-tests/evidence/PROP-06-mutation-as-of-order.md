Invariant: as_of returns the latest change at or before the timestamp, not the earliest.

## Mutation control: as_of_order.patch

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

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 2 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}, {:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "O'Brien", "note" => nil}, [:name]}]]
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
