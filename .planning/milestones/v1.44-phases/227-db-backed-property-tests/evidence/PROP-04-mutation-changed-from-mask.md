Invariant: a masked column's prior value never appears in changed_from.

## Mutation control: redaction_changed_from_mask.patch

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

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 0 successful runs):

         * Clause:    plan <- op_plan_gen()
           Generated: %{insert: %{secret_excluded: {"ZQXSECRET_excluded_s0_ZQX", "ZQXSECRET_excluded_s0_ZQX"}, secret_masked: {"ZQXSECRET_masked_s0_ZQX", "ZQXSECRET_masked_s0_ZQX"}, profile_masked: {"ZQXSECRET_profile_s0_ZQX", "ZQXSECRET_profile_s0_ZQX"}, bio: {"ZQXVISIBLE_plain_s0_ZQX", "ZQXVISIBLE_plain_s0_ZQX"}}, steps: [%{values: %{secret_excluded: {"ZQXSECRET_excluded_s1_ZQX", "ZQXSECRET_excluded_s1_ZQX"}, secret_masked: {"ZQXSECRET_masked_s1_ZQX", "ZQXSECRET_masked_s1_ZQX"}}, kind: :touch_redacted, bio: {"ZQXVISIBLE_plain_s1_ZQX", "ZQXVISIBLE_plain_s1_ZQX"}}], paired: nil, delete?: true, include_action_metadata: false}
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
