A placeholder of exactly 200 graphemes is valid.

## Mutation control: redaction_policy_length.patch

```diff
diff --git a/lib/threadline/capture/redaction_policy.ex b/lib/threadline/capture/redaction_policy.ex
index f2d5a141..a1bf88eb 100644
--- a/lib/threadline/capture/redaction_policy.ex
+++ b/lib/threadline/capture/redaction_policy.ex
@@ -54,7 +54,7 @@ defmodule Threadline.Capture.RedactionPolicy do
       raise ArgumentError, "placeholder must not be empty"
     end

-    if String.length(placeholder) > @max_placeholder_length do
+    if String.length(placeholder) >= @max_placeholder_length do
       raise ArgumentError,
             "placeholder exceeds max length (#{@max_placeholder_length} graphemes)"
     end
```

Command: `mix test test/threadline/capture/redaction_policy_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=4 first="  1) test D-18 regression examples a placeholder of exactly 200 multibyte graphemes is accepted (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=2 exit=2 n=4 first="  1) test D-18 regression examples a placeholder of exactly 200 multibyte graphemes is accepted (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=3 exit=2 n=1 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=4 exit=2 n=0 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=5 exit=2 n=1 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
