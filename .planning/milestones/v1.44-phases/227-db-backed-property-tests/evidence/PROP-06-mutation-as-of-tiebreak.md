Expected survivor of the property, unreachable by design: real capture never ties (0 duplicate captured_at in 9,001 same-row captures; 38-46 us minimum gap), so the uuid tiebreak is only reachable with synthetic ties; its control is the D-17 example.

## Mutation control: as_of_tiebreak.patch

```diff
diff --git a/lib/threadline/query.ex b/lib/threadline/query.ex
index 94ba11f1..9179eb37 100644
--- a/lib/threadline/query.ex
+++ b/lib/threadline/query.ex
@@ -490,7 +490,7 @@ defmodule Threadline.Query do
     |> where([ac], ac.captured_at <= ^timestamp)
     |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
     |> order_by([ac], desc: ac.captured_at)
-    |> order_by([ac], desc: ac.id)
+    |> order_by([ac], asc: ac.id)
     |> limit(1)
   end
```

## Before the fix: the property stays green under this mutant (expected survivor)

`--inverted` run: `test/threadline/query_test.exs:234` (the D-17 example, RED_FILE)
must go red on every seed while `as_of_property_test.exs` (GREEN_FILE, the PROP-06
property) must stay green on every seed. This is the honestly-recorded gap D-16/D-17
name: real capture never produces a `captured_at` tie, so the property's own
generated histories cannot reach the tiebreak order_by at all, and the mutant
survives the property by design.

Command: `mix test test/threadline/query_test.exs:234 --seed <seed>` (RED), with
`as_of_property_test.exs` run inverted (asserted green) at the same seed.

```text
seed=1 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=2 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=3 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=4 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
seed=5 exit=2 n=n/a first="  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)"
```

Shrunk counterexample (seed 1):
```text
  1) test as_of/4 — ASOF-01/02/05 pins deterministic, not causal, tie behaviour: same captured_at resolves to the higher id (Threadline.QueryTest)
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
`--inverted` GREEN_FILE (`as_of_property_test.exs`, the PROP-06 property) exited 0 at
every seed 1-5 — the property never notices this mutant, as expected (unreachable by
design).
