Column names that differ only by surrounding whitespace are the same
column, so a padded overlap is still an overlap.

## Mutation control: redaction_policy.patch

```diff
diff --git a/lib/threadline/capture/redaction_policy.ex b/lib/threadline/capture/redaction_policy.ex
index f2d5a141..12f0371d 100644
--- a/lib/threadline/capture/redaction_policy.ex
+++ b/lib/threadline/capture/redaction_policy.ex
@@ -76,7 +76,6 @@ defmodule Threadline.Capture.RedactionPolicy do
   defp normalize_columns(list, _key) when is_list(list) do
     list
     |> Enum.map(&to_string/1)
-    |> Enum.map(&String.trim/1)
     |> Enum.reject(&(&1 == ""))
   end

```

Command: `mix test test/threadline/capture/redaction_policy_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=6 first="     Failed with generated values (after 6 successful runs):"
seed=3 exit=2 n=4 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=4 exit=2 n=9 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=5 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
