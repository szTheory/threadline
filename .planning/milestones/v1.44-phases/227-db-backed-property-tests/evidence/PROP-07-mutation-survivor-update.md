Invariant: survivors keep their content byte-for-byte.

## Mutation control: retention_survivor_update.patch

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..7bcc6ed3 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -171,6 +171,17 @@ defmodule Threadline.Retention do
       Enum.reduce_while(1..max_batches, {0, 0, 0}, fn idx, {tc, tt, _} ->
         n1 = delete_change_batch(repo, cutoff, batch_size, storage_opts)
 
+        repo.update_all(
+          from(ac in AuditChange,
+            where: ac.captured_at >= ^cutoff,
+            update: [
+              set: [captured_at: fragment("? + interval '1 microsecond'", ac.captured_at)]
+            ]
+          ),
+          [],
+          storage_opts
+        )
+
         n2 =
           if delete_empty? do
             drain_orphan_batches(repo, batch_size, storage_opts)
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 0 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[0]], delete_empty?: true, batch_size: 1}
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
