Invariant: as_of after a delete reports the row as deleted.

## Mutation control: as_of_delete.patch

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

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 4 successful runs):

         * Clause:    batches <- history_gen()
           Generated: [[{:write, %{"doc" => nil, "flag" => true, "n" => nil, "name" => "plain", "note" => nil}, []}, :delete]]
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
