Invariant: `test/threadline/telemetry_registry_contract_test.exs`'s runtime allowlist fails whenever an emitted event carries a metadata (or measurement) key that is not listed in its `Threadline.Telemetry` registry entry (`__events__`) — an unlisted key can never silently ship.

## Mutation control: telemetry_unlisted_key.patch

```diff
diff --git a/lib/threadline/telemetry.ex b/lib/threadline/telemetry.ex
index 03995259..c160452e 100644
--- a/lib/threadline/telemetry.ex
+++ b/lib/threadline/telemetry.ex
@@ -271,7 +271,7 @@ defmodule Threadline.Telemetry do
     :telemetry.execute(
       [:threadline, :operator_surface, :actor_ref_mismatch],
       %{count: 1},
-      %{}
+      %{extra: 1}
     )
   end
 
```

Command: `mix test test/threadline/telemetry_registry_contract_test.exs --seed <seed>`

```text
seed=1 exit=2 n=n/a first="  1) test every registry event fires with exactly its registered keys (Threadline.TelemetryRegistryContractTest)"
seed=2 exit=2 n=n/a first="  1) test every registry event fires with exactly its registered keys (Threadline.TelemetryRegistryContractTest)"
seed=3 exit=2 n=n/a first="  1) test every registry event fires with exactly its registered keys (Threadline.TelemetryRegistryContractTest)"
seed=4 exit=2 n=n/a first="  1) test every registry event fires with exactly its registered keys (Threadline.TelemetryRegistryContractTest)"
seed=5 exit=2 n=n/a first="  1) test every registry event fires with exactly its registered keys (Threadline.TelemetryRegistryContractTest)"
```

```text
Shrunk counterexample (seed 1):
  1) test every registry event fires with exactly its registered keys (Threadline.TelemetryRegistryContractTest)
```

Failure excerpt (seed 1, captured from a direct `mix test ... --seed 1` run against the same applied patch) — the key-set mismatch:
```text
     [:threadline, :operator_surface, :actor_ref_mismatch] metadata keys [:extra] do not match registry []
```

```text
Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.
```
