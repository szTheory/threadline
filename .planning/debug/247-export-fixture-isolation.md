---
status: verified_locally
trigger: "Main run 40452833440, min partition 1, seed 856063: Orchestrator setup failed removing priv/threadline_exports with file already exists."
created: 2026-10-27
updated: 2026-10-27
audit_acknowledged:
  milestone: v1.47
  at: 2026-10-29
  status: verified_locally
---

## Finding

`Threadline.Storage.Local` resolves one directory under the application's priv
directory. All partition VMs share it. `OrchestratorTest` and `LocalTest` remove
that directory in setup. `CleanupTest` and `ExportControllerTest` also create
files there. The captured minimum assignment put these users in partitions 1,
2 and 4. The cleanup test's `:storage_dir` setting does not redirect Local.

The captured CI exception is retained as historical evidence; its exact syscall
interleaving was not recorded. The cross-process ownership defect is reproduced
independently by the production runner's shared-root exclusion harness.

## Hypotheses and recommendation

Ranked before the fix: cross-partition directory deletion; async module overlap
inside the colocated partition; storage adapter defect. Independent local
research recommended the existing colocation mechanism and synchronous LocalTest.
No product configuration or adapter API change is needed.

All four modules now share a colocation group, and LocalTest is synchronous.
ExUnit runs tests within a module sequentially; `async: false` also serializes
that module with other synchronous modules in its partition.

## Verification

The topology regression copies the four real test files, committed weights,
colocation and production runner into a temporary project. The runner launches
real OS processes. Each claims an atomic shared-root directory and holds it
until every nonempty partition has attempted the claim. This rendezvous makes
the negative control independent of timing luck.

- Before the group fix: 31 topology tests, one failure. Three other partition
  processes reported `export fixture overlap` (exit 41).
- After the fix: topology plus the four export modules, seed 856063: 81 tests,
  zero failures. The same runner with colocation removed detects overlap.
- After replacing an initial sleep-based probe with a deterministic rendezvous:
  the focused regression passes, with its split-group negative control.

No application source, assertion, retry count, scope inventory, weights,
acceptance threshold or workflow was changed. New-source main evidence is still
required. Runs 40452150109 and 40452833440 remain failed and excluded; the old
six-run B4 budget remains exhausted.
