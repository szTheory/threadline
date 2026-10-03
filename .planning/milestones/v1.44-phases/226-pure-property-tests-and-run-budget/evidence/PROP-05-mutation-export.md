Invariant: captured_at survives export at microsecond precision.

## Mutation control: export.patch

```diff
diff --git a/lib/threadline/export.ex b/lib/threadline/export.ex
index c5b7a6b7..a01fcb43 100644
--- a/lib/threadline/export.ex
+++ b/lib/threadline/export.ex
@@ -453,7 +453,7 @@ defmodule Threadline.Export do
   defp actor_json_value(%ActorRef{} = ref), do: ActorRef.to_map(ref)
   defp actor_json_value(_), do: nil
 
-  defp datetime_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
+  defp datetime_iso(%DateTime{} = dt), do: dt |> DateTime.truncate(:second) |> DateTime.to_iso8601()
   defp datetime_iso(nil), do: nil
 
   defp generated_at_iso do
```

Command: `mix test test/threadline/export_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
