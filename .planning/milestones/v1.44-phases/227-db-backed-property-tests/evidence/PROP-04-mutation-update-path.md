Invariant: an UPDATE stores the masked/excluded form, exactly like an INSERT.

## Mutation control: redaction_update_path.patch

```diff
diff --git a/lib/threadline/capture/trigger_sql.ex b/lib/threadline/capture/trigger_sql.ex
index 9c06d291..cf12f3a8 100644
--- a/lib/threadline/capture/trigger_sql.ex
+++ b/lib/threadline/capture/trigger_sql.ex
@@ -452,7 +452,6 @@ defmodule Threadline.Capture.TriggerSQL do
         v_row := to_jsonb(NEW);
     #{PrimaryKeySQL.row_key_statements()}
         v_data_after := v_row;
-    #{redact_after_new}
 
         SELECT array_agg(n.key ORDER BY n.key)
         INTO   v_changed_fields
```

Command: `mix test test/threadline/capture/redaction_leak_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
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
