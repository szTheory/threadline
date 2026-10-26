Invariant: a CSV field containing a comma, quote or line break is quoted so the record count is preserved.

## Mutation control: export_csv_join.patch

```diff
diff --git a/lib/threadline/export.ex b/lib/threadline/export.ex
index c5b7a6b7..91d17b40 100644
--- a/lib/threadline/export.ex
+++ b/lib/threadline/export.ex
@@ -275,9 +275,7 @@ defmodule Threadline.Export do
   end
 
   defp dump_csv_to_iodata(rows) do
-    rows
-    |> CSV.dump_to_iodata()
-    |> Enum.map(&IO.iodata_to_binary/1)
+    Enum.map(rows, fn row -> Enum.join(Enum.map(row, &to_string/1), ",") <> "\r\n" end)
   end
 
   @doc """
```

Command: `mix test test/threadline/export_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil correlation id and nil action id become "" with include_action_metadata: true (Threadline.ExportPropertyTest)"
seed=2 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil correlation id and nil action id become "" with include_action_metadata: true (Threadline.ExportPropertyTest)"
seed=3 exit=2 n=0 first="  1) property PROP-05: CSV round-trip every generated row round-trips through the independent strict decoder (Threadline.ExportPropertyTest)"
seed=4 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil data_after becomes "{}" in CSV but stays JSON null (Threadline.ExportPropertyTest)"
seed=5 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil data_after becomes "{}" in CSV but stays JSON null (Threadline.ExportPropertyTest)"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
