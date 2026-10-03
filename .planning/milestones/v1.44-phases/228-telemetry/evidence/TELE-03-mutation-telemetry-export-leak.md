Invariant: no `[:threadline, :export, ...]` telemetry event ever carries row data — the PROP-04 observer's `"telemetry:<event>"` surfaces refute every canary and plain marker exactly like the stored/diff/export/stream surfaces do.

## Mutation control: telemetry_export_leak.patch

```diff
diff --git a/lib/threadline/export.ex b/lib/threadline/export.ex
index a7d285fe..85603d4c 100644
--- a/lib/threadline/export.ex
+++ b/lib/threadline/export.ex
@@ -97,7 +97,13 @@ defmodule Threadline.Export do
       iodata = dump_csv_to_iodata([header | data_rows])
       returned_count = length(rows)
 
-      Threadline.Telemetry.emit_export_completed(:csv, returned_count, truncated, started_at)
+      Threadline.Telemetry.emit_export_completed(
+        :csv,
+        returned_count,
+        truncated,
+        started_at,
+        IO.iodata_to_binary(iodata)
+      )
 
       {:ok,
        %{
diff --git a/lib/threadline/telemetry.ex b/lib/threadline/telemetry.ex
index 03995259..c0ef03f3 100644
--- a/lib/threadline/telemetry.ex
+++ b/lib/threadline/telemetry.ex
@@ -285,7 +285,7 @@ defmodule Threadline.Telemetry do
   cap. `started_at` is a `System.monotonic_time/0` value captured by the
   caller before the export began; this helper computes `duration` from it.
   """
-  def emit_export_completed(format, row_count, truncated, started_at)
+  def emit_export_completed(format, row_count, truncated, started_at, data \\ nil)
       when format in [:csv, :json, :ndjson] and is_integer(row_count) and row_count >= 0 and
              is_boolean(truncated) and is_integer(started_at) do
     duration = System.monotonic_time() - started_at
@@ -293,7 +293,7 @@ defmodule Threadline.Telemetry do
     :telemetry.execute(
       [:threadline, :export, :completed],
       %{duration: duration, row_count: row_count},
-      %{format: format, truncated: truncated}
+      %{format: format, truncated: truncated, data: data}
     )
   end
 
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

Failure excerpt (seed 1, captured from a direct `mix test ... --seed 1` run against the same applied patch):
```text
     LeakOracle: redaction leak detected.

     surface: telemetry:threadline.export.completed
     canary:  "ZQXVISIBLE_plain_s0_ZQX"
     window:  "secret_masked\"\"]\",\"{\"\"bio\"\":\"\"ZQXVISIBLE_plain_s0_ZQX\"\",\"\"secret_masked\"\":\"\"[REDACTED"
```

The leak is a plain marker (the generated `bio` value), not a redaction canary: the mutant forwards the already-redacted CSV bytes into telemetry metadata, and CSV already masks `secret_masked`/`profile_masked` and omits `secret_excluded`, but `bio` is unredacted data and the mutant surfaces it on the `telemetry:threadline.export.completed` surface — exactly the row-data side door the PROP-04 telemetry observer and its `canaries(plan) ++ markers(plan)` refute call exist to catch.

```text
Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
```

Note: `mutation-control.sh`'s own byte-for-byte reproduce check (its internal second run of seed one, distinct from this evidence) intermittently failed across repeated script invocations, on the pre-existing map-key print-order flake CLAUDE.md already documents against a different file ("compat check against `change_diff_property_test.exs` (map key print order)"): `inspect` of the generated plan map printed its keys in a different order between two otherwise-identical runs — same keys, same values, different Erlang map iteration order. This is unrelated to the mutant: each seed above independently killed the mutant, and the figures in this fragment were captured from a script invocation that completed end to end (every seed killed, reproduced, green after restore, `lib` clean) with a byte-identical report both times it succeeded.
