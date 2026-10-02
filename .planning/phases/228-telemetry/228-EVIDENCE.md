# Phase 228: Telemetry - Evidence

## SC-1 export events

`[:threadline, :export, :completed]` / `[:threadline, :export, :failed]` fire
on both outcome branches of every export unit of work, each carrying
`duration`, `row_count`, and `format` (plus `truncated` or `error_kind`/
`exception`).

Passing tests:

```text
test/threadline/export_test.exs -- to_csv_iodata/2 telemetry (TELE-01),
to_json_document/2 telemetry (TELE-01) (success, truncation, bad-filter
raise on both functions)

test/threadline/export/orchestrator_test.exs -- telemetry assertions on
the success, transaction-failure, completion-failure, invalid-params and
claim-race tests, plus new storage-put-failure and completion_fn-raises
cases

test/threadline/operator_surface/export_controller_telemetry_test.exs --
four tests: the clean >5,000-row stream, the >10,000-row truncation, the
client-closed chunk write (ClosedChunkAdapter), and the <=5,000-row
single-event eager path

test/threadline/telemetry_registry_contract_test.exs --
drive_export_completed!/drive_export_failed! in drive_all!/0, part of
"every registry event fires with exactly its registered keys"
```

Command: `mix test test/threadline/export_test.exs test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/export_controller_telemetry_test.exs test/threadline/telemetry_registry_contract_test.exs`

## SC-2 retention events

`[:threadline, :retention, :purge, :start | :stop | :exception]` spans the
dry-run/real-run branch, and `[:threadline, :retention, :batch_purged]`
fires once per `purge_loop` step, carrying the rows deleted. A test
forces the exception path against a missing storage schema on the real
database.

Passing tests:

```text
test/threadline/retention_test.exs -- span start/stop assertions on the
multi-batch, idempotent and empty-transaction-removal tests; one
batch_purged per purge_loop step counting matching the returned totals
(D-10); dry run emits zero batch_purged events; "purge against a missing
storage schema emits :start then :exception, no :stop or batch_purged, and
re-raises (D-11)"

test/threadline/telemetry_registry_contract_test.exs --
drive_retention_purge!/0 in drive_all!/0
```

Command: `mix test test/threadline/retention_test.exs test/threadline/telemetry_registry_contract_test.exs`

## SC-3 allowlist, redaction observer, and raising-handler isolation

An allowlist test pins the measurement and metadata keys (plus a generic
value-type guard) of every one of the fourteen registered events, and
adding an unlisted key turns it red. A handler attached during the PROP-04
redaction property never observes plaintext on any telemetry surface. A
raising handler does not break export or purge, and `:telemetry` 1.4.2's
documented all-events-in-the-`attach_many`-detach behavior is pinned.

Passing tests:

```text
test/threadline/telemetry_registry_contract_test.exs -- "every registry
event fires with exactly its registered keys" (drives all fourteen events,
asserts key-set equality, assert_measurement_value_types!/2,
assert_metadata_value_types!/2); ":telemetry.execute/:telemetry.span appear
only in lib/threadline/telemetry.ex" (the static scan)

test/threadline/capture/redaction_leak_property_test.exs -- "no canary
survives a redacted trigger/storage/diff/CSV/JSON/NDJSON round trip",
extended with the telemetry observer (setup attaches to every
Threadline.Telemetry.__events__/0 name), assert_export_telemetry_structure!/2
as the vacuity guard, and the telemetry-surface refute call against
canaries(plan) ++ markers(plan)

test/threadline/telemetry_raising_handler_test.exs -- two tests: a raising
handler across all four D-13 events (export :completed/:failed,
batch_purged, purge :stop) does not change the export result, detaches
from every one of those events, and emits [:telemetry, :handler,
:failure]; a second raising handler on only batch_purged/purge :stop does
not change the purge result or deleted rows and is detached from both
events afterward
```

Command: `mix test test/threadline/telemetry_registry_contract_test.exs test/threadline/capture/redaction_leak_property_test.exs test/threadline/telemetry_raising_handler_test.exs`

## SC-4 docs

The `Threadline.Telemetry` moduledoc and `guides/telemetry.md` both carry
the same hand-written event table; a parity test derives the documented
list from `__events__` rather than from a hand-typed literal. The guide
includes the host-repo `[:my_app, :repo, :query]` recipe, every caveat of
which is proven against a real database.

Passing tests:

```text
test/threadline/telemetry_doc_contract_test.exs -- "the moduledoc table is
non-vacuous and matches the registry exactly"; "the guide table is
non-vacuous and matches the registry exactly"

test/threadline/telemetry_repo_query_recipe_test.exs -- five tests: the
three capture/semantics schema sources are exactly the documented
allowlist; Repo.all on AuditChange with the storage prefix emits source ==
"audit_changes" (no prefix); raw SQL and a subquery-rooted count both
report source == nil; an insert into a trigger-audited host table reports
only the host table as source (capture's own writes never appear);
metadata.params carries a pinned bind value verbatim

test/threadline/guide_graph_contract_test.exs -- "all 20 guides form one
complete intent-led graph"
```

Command: `mix test test/threadline/telemetry_doc_contract_test.exs test/threadline/telemetry_repo_query_recipe_test.exs test/threadline/guide_graph_contract_test.exs`

## SC-3 mutation controls

Two controls were produced and verified with the hardened, re-runnable
runner (phase 226 D-23):

`bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh <patch> <red-file> [K]`

Every run refuses to start on a dirty `lib/`, reverses the patch via a
trap, and re-checks `git diff --quiet -- lib` after reverting, so no
mutated `lib/` was ever committed.

```text
Both fragments below are filed in this phase's evidence directory
(plan 228-04).
```

### telemetry export leak

Invariant: no `[:threadline, :export, ...]` telemetry event ever carries
row data.

```text
See evidence/TELE-03-mutation-telemetry-export-leak.md, filed alongside
this doc, for the full diff and failure excerpt.
```

Summary:

```text
Kill rate: 5/5. The mutant forwards the CSV bytes into
emit_export_completed/4's metadata; the shrunk counterexample's failure
names the telemetry:threadline.export.completed surface and the leaked
plain marker (the generated bio value). Green after restore: the red file
passes at seed 1 after reverting the patch; git diff --quiet -- lib is
clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/228-telemetry/tools/mutations/telemetry_export_leak.patch test/threadline/capture/redaction_leak_property_test.exs`

### telemetry unlisted key

Invariant: an emitted event carrying a metadata key not listed in its
registry entry can never silently ship.

```text
See evidence/TELE-03-mutation-unlisted-key.md, filed alongside this doc,
for the full diff and failure excerpt.
```

Summary:

```text
Kill rate: 5/5. emit_actor_ref_mismatch/0 gains an unlisted extra: 1
metadata key; the key-set mismatch fails on
"[:threadline, :operator_surface, :actor_ref_mismatch] metadata keys
[:extra] do not match registry []". Green after restore: the red file
passes at seed 1 after reverting the patch; git diff --quiet -- lib is
clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/228-telemetry/tools/mutations/telemetry_unlisted_key.patch test/threadline/telemetry_registry_contract_test.exs`

### Additional red-then-reverted checks (plans 01, 03, 05)

```text
Unlike the two controls above, these were single-shot red/green checks
recorded inline in each plan's SUMMARY.md, not a multi-seed
mutation-control.sh run; they are recorded here as what they are, not
re-labeled as a kill rate.

Plan 01: a mutation control adding an unlisted :foo key to
emit_actor_ref_mismatch/0 was confirmed to turn the registry allowlist
test red, then reverted.

Plan 03: the generic metadata value-type guard was proven to bite twice --
first by adding an unlisted note: "x" key to emit_batch_purged/3's
metadata (red on the existing key-equality assertion), then by also
registering :note in the entry and re-running (red specifically on the new
value-type assertion, since "x" is a binary, not an allowed value type) --
both reverted after confirming red.

Plan 05: the doc-parity test was proven red locally by mutating one guide
table row to add an extra measurement key, confirming the guide-table test
failed with a clear diff, then reverted before committing.
```

## SC-5 no query or Mix-task event

The static scan and the registry both prove no `[:threadline, :query, ...]`
event and no Mix-task-specific event exist.

Static scan test: `test/threadline/telemetry_registry_contract_test.exs` —

```text
":telemetry.execute/:telemetry.span appear only in
lib/threadline/telemetry.ex"
```

The full registry of event names
(`bash -c 'MIX_ENV=test mix run -e "Enum.each(Threadline.Telemetry.__events__(), &IO.inspect(&1.name))"'`):

```text
[:threadline, :transaction, :committed]
[:threadline, :action, :recorded]
[:threadline, :health, :checked]
[:threadline, :health, :checked, :error]
[:threadline, :health, :findings_checked]
[:threadline, :operator_surface, :authorize]
[:threadline, :operator_surface, :export_authorize]
[:threadline, :operator_surface, :actor_ref_mismatch]
[:threadline, :export, :completed]
[:threadline, :export, :failed]
[:threadline, :retention, :purge, :start]
[:threadline, :retention, :purge, :stop]
[:threadline, :retention, :purge, :exception]
[:threadline, :retention, :batch_purged]
```

```text
None of these names contains :query, and none is Mix-task-specific (the
two Mix tasks that touch retention/export call the library functions, not
Threadline.Telemetry directly).
```

No Mix task references `Threadline.Telemetry` or calls `:telemetry`
directly:

`bash -c 'grep -rn ":telemetry" lib/mix/'`:

```text
(no matches; exit status 1)
```

## SC-5 wall clock before and after

### Local (local, noisy)

```text
See evidence/SC5-local.md, filed alongside this doc, for the full per-run
and per-module figures.
```

Summary:

```text
file: evidence/SC5-local.md

nine new/extended files' own cost, head total (sum of medians): 4435.5ms
same four pre-existing files' own cost, base total (sum of medians): 1077.0ms
added own cost: ~3.4s (within the plan's 15s Flake Detection threshold)
whole-suite local, noisy, median Finished-in, base: 213.7s
whole-suite local, noisy, median Finished-in, head: 219.0s
```

local, noisy: this machine's own documented load-noise floor (phase 224's
evidence doc, restated by phase 227's evidence) is an order of magnitude
larger than the head-vs-base gap recorded in the figures above, so the
local whole-suite figure is not read as a per-test regression or
improvement on its own; see that evidence fragment for the full
restatement, including the two unrelated long-lived `beam.smp` processes
observed via `ps aux` during both measurement windows.

### CI

```text
The maintainer granted, in their own words, naming
"git push origin milestone/v1.44" (plus that plan's follow-up commits),
then "gh workflow run ci.yml --ref milestone/v1.44", and "gh workflow run
flake-detection.yml --ref milestone/v1.44" only if the new tests add more
than fifteen seconds per suite run ("yes i authorize what u mentioned
above", 2026-10-02); the push and dispatch below were carried out under
that grant.
```

Before run selection
(`gh run list --workflow ci.yml --branch milestone/v1.44 --limit 20`):

```text
run 36903609149 remains the latest successful ci.yml run on
milestone/v1.44 before this phase's first commit (confirmed unchanged
since phase 227's evidence cited the same run as its own after run's
before-run baseline).
```

```text
See the Task 3 dispatch section below for the after run and the
before/after table, filled in once the grant's ci.yml dispatch completes.
```

### Flake Detection

```text
Not requested: added own cost about 3.4 seconds (see evidence/SC5-local.md),
well within the 200-second Test 6 headroom over nine runs documented by
phase 227's evidence. The maintainer's grant names flake-detection.yml only
if the new tests add more than fifteen seconds per suite run; that
threshold was not crossed, so flake-detection.yml is not dispatched and
Test 6's ceilings (@cold_first_run_ceiling_s, @repeat_ceiling_s) are left
exactly as phase 227 re-derived them.
```

Citing phase 227's re-derived ceilings directly: `grep -n "cold_first_run_ceiling_s\|repeat_ceiling_s" test/threadline/flake_classifier_contract_test.exs`:

```text
@cold_first_run_ceiling_s 370
@repeat_ceiling_s 300
(run 36930385324, per 227-EVIDENCE.md D-27 re-derivation)
```

## Partition weights

```text
None of the nine new/extended telemetry files' own median module cost
(evidence/SC5-local.md's head table) exceeds the two-second-per-file
threshold for a solo append -- the slowest, Export.OrchestratorTest, is
1108.7ms.
```

`test/partition_weights.txt` is left untouched. `bin/ci-test-partitions
--write-weights` was never run.
