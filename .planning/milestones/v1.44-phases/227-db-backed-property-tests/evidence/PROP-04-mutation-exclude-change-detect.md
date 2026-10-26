Invariant: an excluded column never enters changed_fields or changed_from, even when it changes.

```diff
diff --git a/lib/threadline/capture/trigger_sql.ex b/lib/threadline/capture/trigger_sql.ex
index 9c06d291..162b3239 100644
--- a/lib/threadline/capture/trigger_sql.ex
+++ b/lib/threadline/capture/trigger_sql.ex
@@ -398,7 +398,7 @@ defmodule Threadline.Capture.TriggerSQL do
          store_changed_from,
          opts
        ) do
-    except_sql = changed_fields_except_array_sql(except_columns, exclude)
+    except_sql = changed_fields_except_array_sql(except_columns, [])
     fn_name = per_table_function_name(table_name, opts)
     redact_after_new = data_after_redaction_statements("v_data_after", exclude, mask, placeholder)
     mask_array_sql = mask_array_sql_fragment(mask)
```

## Mutation control: redaction_exclude_change_detect.patch (property, PROP-04)

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

## Before the example fix: existing example suite stays green under this mutant

`--inverted` run: `redaction_leak_property_test.exs` (RED_FILE) must go red on every
seed while `trigger_redaction_test.exs` (the pre-D-13 example suite, GREEN_FILE) must
stay green on every seed. This is the coverage gap D-12 names: the current example
suite misses this mutant.

Command: `mix test test/threadline/capture/redaction_leak_property_test.exs --seed <seed>` (RED), with
`trigger_redaction_test.exs` run inverted (asserted green) at the same seed.

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
`--inverted` GREEN_FILE (`trigger_redaction_test.exs`, pre-D-13) exited 0 at every seed 1-5 —
the existing example suite did not notice this mutant.

## After the example fix: a fast deterministic example kills it

D-13 added two assertions to `trigger_redaction_test.exs`'s UPDATE example
(`refute "password" in change.changed_fields`, `refute Map.has_key?(change.changed_from, "password")`).
`mix test test/threadline/capture/trigger_redaction_test.exs` is green on unmutated `lib/`.
Re-running the same mutation control against the now-fixed example file:

Command: `mix test test/threadline/capture/trigger_redaction_test.exs --seed <seed>`

```text
seed=1 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=2 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=3 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=4 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
seed=5 exit=2 n=n/a first="  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)"
```

Shrunk counterexample (seed 1):
```text
  1) test per-table capture with exclude and mask UPDATE masks changed_from for masked column and omits exclude from data_after (Threadline.Capture.TriggerRedactionTest)
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
