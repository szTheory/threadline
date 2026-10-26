Invariant: a transaction holding a surviving change is never deleted.

## Mutation control: retention_orphan_guard.patch

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..2f32a078 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -232,13 +232,6 @@ defmodule Threadline.Retention do
     subq =
       from(at in AuditTransaction,
         as: :audit_transaction,
-        where:
-          not exists(
-            from(c in AuditChange,
-              where: c.transaction_id == parent_as(:audit_transaction).id,
-              select: 1
-            )
-          ),
         select: at.id,
         limit: ^batch_size
       )
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
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
