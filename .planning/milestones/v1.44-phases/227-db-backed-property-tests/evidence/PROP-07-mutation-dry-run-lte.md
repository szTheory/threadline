Invariant: the dry run selects rows strictly older than the cutoff. Patching this one site alone is caught by the dry/real agreement assertion.

## Mutation control: retention_dry_run_lte.patch

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..35ffb628 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -132,7 +132,7 @@ defmodule Threadline.Retention do
   defp dry_run_result(repo, cutoff, policy, storage_opts) do
     eligible_changes =
       repo.one(
-        from(ac in AuditChange, where: ac.captured_at < ^cutoff, select: count(ac.id)),
+        from(ac in AuditChange, where: ac.captured_at <= ^cutoff, select: count(ac.id)),
         storage_opts
       )
 
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 2 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[0]], delete_empty?: true, batch_size: 1}
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
