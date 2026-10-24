Paging backward with before: returns exactly the rows adjacent to the cursor.

## Mutation control: cursor.patch

```diff
diff --git a/lib/threadline/query/cursors.ex b/lib/threadline/query/cursors.ex
index 2f95a7ca..c000d7f9 100644
--- a/lib/threadline/query/cursors.ex
+++ b/lib/threadline/query/cursors.ex
@@ -77,7 +77,7 @@ defmodule Threadline.Query.Cursors do
   end
 
   defp trim_actor_history(entries, _limit, true, true),
-    do: entries |> Enum.reverse() |> Enum.drop(1)
+    do: entries |> Enum.drop(1) |> Enum.reverse()
 
   defp trim_actor_history(entries, limit, true, false), do: Enum.take(entries, limit)
   defp trim_actor_history(entries, _limit, false, true), do: Enum.reverse(entries)
```

Command: `mix test test/threadline/query/cursors_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
