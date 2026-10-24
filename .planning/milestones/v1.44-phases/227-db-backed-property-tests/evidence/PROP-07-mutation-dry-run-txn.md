Invariant: the dry run counts transactions the purge itself would empty. Caught by the dry/real agreement assertion (dry.deleted_transactions no longer matches the real purge's orphan count once this fix is reverted).

## Mutation control: retention_dry_run_txn.patch

```diff
diff --git a/lib/threadline/retention.ex b/lib/threadline/retention.ex
index 00d2d783..040cdfa7 100644
--- a/lib/threadline/retention.ex
+++ b/lib/threadline/retention.ex
@@ -144,9 +144,7 @@ defmodule Threadline.Retention do
             where:
               not exists(
                 from(c in AuditChange,
-                  where:
-                    c.transaction_id == parent_as(:audit_transaction).id and
-                      c.captured_at >= ^cutoff,
+                  where: c.transaction_id == parent_as(:audit_transaction).id,
                   select: 1
                 )
               ),
```

Command: `mix test test/threadline/retention/cutoff_property_test.exs --seed <seed>`

```text
seed=1 exit=2 n=4 first="     Failed with generated values (after 4 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=4 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=5 exit=2 n=3 first="     Failed with generated values (after 3 successful runs):"
```

Shrunk counterexample (seed 1):
```text
     Failed with generated values (after 4 successful runs):

         * Clause:    fixture <- fixture_gen()
           Generated: %{cutoff: ~U[2001-01-01 00:00:00.000000Z], transactions: [[-1]], delete_empty?: true, batch_size: 1}
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.

Note: an earlier generator (90% general mixed offsets, 10% empty transactions)
reached this mutant only incidentally and surfaced `n`/`WEAK`-style unreliability
across seeds (the generic offset mix only produces a fully-before-cutoff,
non-empty transaction by chance). Per the halt clause's "raise the generator's
cutoff-cluster bias, never weaken the patch" rule, `RetentionCutoffGenerators`
gained a dedicated ~30% "entirely negative" transaction branch so a
purge-orphaned transaction is reliably present; this also strengthened the
other four controls (all re-run 5/5 against the updated generator, same
`transactions: [[0]]` shrunk fixture).
