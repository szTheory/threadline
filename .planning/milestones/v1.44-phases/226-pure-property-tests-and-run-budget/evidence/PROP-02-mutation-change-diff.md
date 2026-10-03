A column whose stored prior value is JSON null reports before: null, never prior_state: omitted.

## Mutation control: change_diff.patch

```diff
diff --git a/lib/threadline/change_diff.ex b/lib/threadline/change_diff.ex
index b78ba545..e22534ba 100644
--- a/lib/threadline/change_diff.ex
+++ b/lib/threadline/change_diff.ex
@@ -187,7 +187,7 @@ defmodule Threadline.ChangeDiff do
         base
 
       is_map(cf) ->
-        if map_has_field?(cf, name) do
+        if map_get(cf, name) != nil do
           Map.put(base, "before", map_get(cf, name))
         else
           Map.put(base, "prior_state", "omitted")
```

Command: `mix test test/threadline/change_diff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=20 first="     Failed with generated values (after 20 successful runs):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
