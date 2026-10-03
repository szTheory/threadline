Invariant: as_of at exactly a change's captured_at includes that change.

## Mutation control: as_of_le.patch

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

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 0 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}]]
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
