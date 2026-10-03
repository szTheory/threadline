# Phase 226: Pure Property Tests and Run Budget - Evidence

## SC-4 mutation controls

Each control below was produced and verified with the re-runnable runner
(D-20):

`bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh <patch> <red-file> [K]`

Every run refuses to start on a dirty `lib/`, reverses the patch via a
trap, and re-checks `git diff --quiet -- lib` after reverting, so no
mutated `lib/` was ever committed.

### PROP-01 cursor

Paging backward with before: returns exactly the rows adjacent to the
cursor.

```diff
diff --git a/lib/threadline/query/cursors.ex b/lib/threadline/query/cursors.ex
index 2f95a7ca..c000d7f9 100644
--- a/lib/threadline/query/cursors.ex
+++ b/lib/threadline/query/cursors.ex
@@ -77,7 +77,7 @@ defmodule Threadline.Query.Cursors do
   end
 
   defp trim_actor_history(entries, _limit, true, true),
-    do: entries |> Enum.reverse() |> Enum.drop(1)
+    do: entries |> Enum.drop(1) |> Enum.reverse()
 
   defp trim_actor_history(entries, limit, true, false), do: Enum.take(entries, limit)
   defp trim_actor_history(entries, _limit, false, true), do: Enum.reverse(entries)
```

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/cursor.patch test/threadline/query/cursors_property_test.exs`

### PROP-01 cursor_sql

Rows tied on the timestamp are ordered by id descending, the same
direction as the keyset predicate. This control is inverted (D-06): the
property is expected to stay green under the mutant, while the DB
agreement example tests go red.

```diff
diff --git a/lib/threadline/query.ex b/lib/threadline/query.ex
index 94ba11f1..b273902f 100644
--- a/lib/threadline/query.ex
+++ b/lib/threadline/query.ex
@@ -357,7 +357,7 @@ defmodule Threadline.Query do
   defp timeline_order(query) do
     query
     |> order_by([ac], desc: ac.captured_at)
-    |> order_by([ac], desc: ac.id)
+    |> order_by([ac], asc: ac.id)
   end
 
   @doc """
diff --git a/lib/threadline/query/cursors.ex b/lib/threadline/query/cursors.ex
index 2f95a7ca..c312cc40 100644
--- a/lib/threadline/query/cursors.ex
+++ b/lib/threadline/query/cursors.ex
@@ -54,19 +54,19 @@ defmodule Threadline.Query.Cursors do
   # cursor pages toward newer records, so it reads ascending and the caller
   # reverses the page; it wins over an `after` cursor when both are given.
   def actor_history_window(query, nil, nil) do
-    {order_by(query, [at], desc: at.occurred_at, desc: at.id), false}
+    {order_by(query, [at], desc: at.occurred_at, asc: at.id), false}
   end
 
   def actor_history_window(query, nil, after_cursor) do
     {query
      |> actor_history_after_cursor(after_cursor)
-     |> order_by([at], desc: at.occurred_at, desc: at.id), false}
+     |> order_by([at], desc: at.occurred_at, asc: at.id), false}
   end
 
   def actor_history_window(query, before_cursor, _after_cursor) do
     {query
      |> actor_history_before_cursor(before_cursor)
-     |> order_by([at], asc: at.occurred_at, asc: at.id), true}
+     |> order_by([at], asc: at.occurred_at, desc: at.id), true}
   end
 
   # The query fetched `limit + 1` rows; the extra row only signals that more
```

```text
seed=1 exit=2 n=n/a first="  1) test timeline_page/2 concatenated pages match eager timeline order exactly (Threadline.QueryTest)"
seed=2 exit=2 n=n/a first="  1) test actor_history/2 — QUERY-02 pages across occurred_at ties forward and backward without duplicates or skips (Threadline.QueryTest)"
seed=3 exit=2 n=n/a first="  1) test timeline_page/2 concatenated pages match eager timeline order exactly (Threadline.QueryTest)"
seed=4 exit=2 n=n/a first="  1) test timeline_page/2 advances safely across captured_at ties without duplicates or skips (Threadline.QueryTest)"
seed=5 exit=2 n=n/a first="  1) test timeline_page/2 concatenated pages match eager timeline order exactly (Threadline.QueryTest)"
```

```text
Kill rate: 5/5 (on the DB agreement file — the inverted expectation). The
cursors property itself stays green on every seed, as expected for an
inverted control. Reproduce: seed 1 reproduces the same counterexample on
a second run. Green after restore: the DB agreement file passes at seed 1
after reverting the patch; `git diff --quiet -- lib` is clean.
```

PROP-01 is a pure property over the real `Cursors` slicing/cursor code
against an in-memory model of the keyset SQL; the SQL ordering and
predicate are pinned by DB example tests that compare real query output
to the same model on fixed tie-heavy fixtures.

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --inverted test/threadline/query/cursors_property_test.exs .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/cursor_sql.patch test/threadline/query_test.exs`

### PROP-02 change_diff

A column whose stored prior value is JSON null reports before: null,
never prior_state: omitted.

```diff
diff --git a/lib/threadline/change_diff.ex b/lib/threadline/change_diff.ex
index b78ba545..e22534ba 100644
--- a/lib/threadline/change_diff.ex
+++ b/lib/threadline/change_diff.ex
@@ -187,7 +187,7 @@ defmodule Threadline.ChangeDiff do
         base
 
       is_map(cf) ->
-        if map_has_field?(cf, name) do
+        if map_get(cf, name) != nil do
           Map.put(base, "before", map_get(cf, name))
         else
           Map.put(base, "prior_state", "omitted")
```

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
seed=4 exit=2 n=20 first="     Failed with generated values (after 20 successful runs):"
seed=5 exit=2 n=1 first="     Failed with generated values (after 1 successful run):"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/change_diff.patch test/threadline/change_diff_property_test.exs`

### PROP-03 trim

Column names that differ only by surrounding whitespace are the same
column, so a padded overlap is still an overlap.

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

```text
seed=1 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
seed=2 exit=2 n=6 first="     Failed with generated values (after 6 successful runs):"
seed=3 exit=2 n=4 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=4 exit=2 n=9 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=5 exit=2 n=2 first="     Failed with generated values (after 2 successful runs):"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/redaction_policy.patch test/threadline/capture/redaction_policy_property_test.exs`

### PROP-03 length

A placeholder of exactly two hundred graphemes is valid (the maximum
allowed length).

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

```text
seed=1 exit=2 n=4 first="  1) test D-18 regression examples a placeholder of exactly 200 multibyte graphemes is accepted (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=2 exit=2 n=4 first="  1) test D-18 regression examples a placeholder of exactly 200 multibyte graphemes is accepted (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=3 exit=2 n=1 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=4 exit=2 n=0 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
seed=5 exit=2 n=1 first="  1) property validate!/1 accepts every generated valid policy and rejects every tagged invalid one (Threadline.Capture.RedactionPolicyPropertyTest)"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/redaction_policy_length.patch test/threadline/capture/redaction_policy_property_test.exs`

### PROP-05 datetime

Invariant: captured_at survives export at microsecond precision.

```diff
diff --git a/lib/threadline/export.ex b/lib/threadline/export.ex
index c5b7a6b7..a01fcb43 100644
--- a/lib/threadline/export.ex
+++ b/lib/threadline/export.ex
@@ -453,7 +453,7 @@ defmodule Threadline.Export do
   defp actor_json_value(%ActorRef{} = ref), do: ActorRef.to_map(ref)
   defp actor_json_value(_), do: nil
 
-  defp datetime_iso(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
+  defp datetime_iso(%DateTime{} = dt), do: dt |> DateTime.truncate(:second) |> DateTime.to_iso8601()
   defp datetime_iso(nil), do: nil
 
   defp generated_at_iso do
```

```text
seed=1 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=2 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=3 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=4 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
seed=5 exit=2 n=0 first="     Failed with generated values (after 0 successful runs):"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/export.patch test/threadline/export_property_test.exs`

### PROP-05 csv join

Invariant: a CSV field containing a comma, quote or line break is quoted
so the record count is preserved.

```diff
diff --git a/lib/threadline/export.ex b/lib/threadline/export.ex
index c5b7a6b7..91d17b40 100644
--- a/lib/threadline/export.ex
+++ b/lib/threadline/export.ex
@@ -275,9 +275,7 @@ defmodule Threadline.Export do
   end
 
   defp dump_csv_to_iodata(rows) do
-    rows
-    |> CSV.dump_to_iodata()
-    |> Enum.map(&IO.iodata_to_binary/1)
+    Enum.map(rows, fn row -> Enum.join(Enum.map(row, &to_string/1), ",") <> "\r\n" end)
   end
 
   @doc """
```

```text
seed=1 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil correlation id and nil action id become "" with include_action_metadata: true (Threadline.ExportPropertyTest)"
seed=2 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil correlation id and nil action id become "" with include_action_metadata: true (Threadline.ExportPropertyTest)"
seed=3 exit=2 n=0 first="  1) property PROP-05: CSV round-trip every generated row round-trips through the independent strict decoder (Threadline.ExportPropertyTest)"
seed=4 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil data_after becomes "{}" in CSV but stays JSON null (Threadline.ExportPropertyTest)"
seed=5 exit=2 n=0 first="  1) test PROP-05: D-19 export_defaults are pinned, not changed nil data_after becomes "{}" in CSV but stays JSON null (Threadline.ExportPropertyTest)"
```

```text
Kill rate: 5/5. Reproduce: seed 1 reproduces the same counterexample on a
second run. Green after restore: the red file passes at seed 1 after
reverting the patch; `git diff --quiet -- lib` is clean.
```

Command: `bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/export_csv_join.patch test/threadline/export_property_test.exs`

## SC-5 wall clock before and after

### Local (local, noisy)

See the local-timing evidence fragment filed alongside this doc, in this
phase's `evidence/` directory, for the full per-run and per-module
figures. Summary:

```text
file: .planning/phases/226-pure-property-tests-and-run-budget/evidence/SC5-local.md

new files' own cost, unscaled, median Finished-in:            1.6s
new files' own cost, THREADLINE_PROPERTY_SCALE=5, median Finished-in: 96.6s
whole-suite local, noisy, median Finished-in, base: 226.5s
whole-suite local, noisy, median Finished-in, head: 144.9s
```

local, noisy: this machine's own documented load-noise floor (phase 224's
evidence doc, D-18) is on the same order of magnitude as the head-vs-base
gap recorded above, so the local whole-suite figure is not read as a
per-test regression or improvement on its own; see that evidence fragment
for the full restatement.

### CI

The maintainer granted, in their own words, `git push origin milestone/v1.44`
(incl. follow-ups), `gh workflow run ci.yml --ref milestone/v1.44`, and
`gh workflow run flake-detection.yml --ref milestone/v1.44`; the push and both
dispatches below were carried out under that grant.

```text
Before run selection (gh run list --workflow ci.yml --branch milestone/v1.44 --limit 20):
run 36820084560 is the latest successful ci.yml run on milestone/v1.44
before this phase's first commit. First 226 commit 679544d5 landed
2026-10-01 08:06:47-04:00 = 12:06:47 UTC; run 36820084560 completed
2026-10-01T05:30:21Z, which is before that.

After run: run 36887218675 (ci.yml on commit b4200f44, dispatched under
the grant above): conclusion success, all three lanes success.
```

`ci-job-timing.py`'s `--compare` mode needs two or more after runs: (`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare 36820084560 36887218675`).

```text
python3 .../ci-job-timing.py --compare 36820084560 36887218675 exits 1:
"INSUFFICIENT (need at least 2 after runs)". This phase only dispatched
one post-226 ci.yml run, so --compare's two-after-run design (built for
225, which had two after samples) cannot run here. Single-run mode on
each run id reads the same per-lane figures --compare would, so the
before/after table below comes from two single-run invocations instead.
```

```
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36820084560 --cache-state

## run 36820084560

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | 217 | 4 | 170 | hit |
| current | 299 | 5 | 131 | hit |
| latest | 176 | 3 | 129 | hit |
| **total** | | **12** | |

python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36887218675 --cache-state

## run 36887218675

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | 201 | 4 | 143 | hit |
| current | 314 | 6 | 143 | hit |
| latest | 221 | 4 | 170 | hit |
| **total** | | **14** | |
```

(`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36820084560 --cache-state`, `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36887218675 --cache-state`)

```text
Per-lane Run tests delta, before (run 36820084560) -> after (run 36887218675):
  min:     170s -> 143s  (-27s / -15.9%), build cache hit -> hit
  current: 131s -> 143s  (+12s / +9.2%),  build cache hit -> hit
  latest:  129s -> 170s  (+41s / +31.8%), build cache hit -> hit
  proxy (min, total): 12 -> 14 (+2)

Both runs are a full cache hit on every lane, so the deltas above are real
suite-cost movement, not a cold-vs-warm-cache artifact. ci.yml never sets
THREADLINE_PROPERTY_SCALE (that knob is Flake Detection's repeat step only,
per D-09) -- the rise on current/latest is the new pure property files
running at their unscaled max_runs on every PR, the expected SC-5 cost this
phase adds to CI. It is small (well under a minute per lane) next to the
local wall-clock figures above.
```

### Flake Detection at scale 5 (D-12)

Dispatched under the same grant, after the `ci.yml` run above completed, via
`gh workflow run flake-detection.yml --ref milestone/v1.44`: `run 36888506162`
on commit `b4200f44`.

Scale banner (`gh run view 36888506162 --log`): `THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3`.

```text
Classification (gh run view 36888506162 --log, read-only):
"Flake Detection classification: inconclusive (completed iterations: 12,
exit: 124)". The timeout(1) budget expired mid the 12th suite run (the
11th repeat): ELAPSED_S 3300 equals BUDGET_S 3300. inconclusive is not a
failure signal -- every one of the 11 iterations that finished reports
"28 properties, 2649 tests, 0 failures, 3 excluded", and the 12th was
still running, not failing, when the budget cut it off.
```

Every "Finished in" line (`gh run view 36888506162 --log`):

```
Finished in 345.1 seconds (95.4s async, 249.6s sync)   <- cold first run
Finished in 289.0 seconds (86.5s async, 202.5s sync)
Finished in 288.4 seconds (86.2s async, 202.1s sync)
Finished in 291.8 seconds (89.1s async, 202.6s sync)
Finished in 289.0 seconds (86.5s async, 202.4s sync)
Finished in 286.8 seconds (83.5s async, 203.2s sync)
Finished in 290.9 seconds (88.9s async, 202.0s sync)
Finished in 293.5 seconds (91.3s async, 202.1s sync)
Finished in 289.7 seconds (86.9s async, 202.8s sync)
Finished in 287.8 seconds (85.6s async, 202.1s sync)
Finished in 289.6 seconds (86.2s async, 203.4s sync)
```

```text
Raw figures: cold 345.1s, repeats 286.8-293.5s (slowest repeat 293.5s). 12
"Running ExUnit with seed:" headers were printed (the 12th iteration
started before the budget cut it off), but only 11 "Finished in" lines
(1 cold + 10 repeats) appear -- the then-committed 11-repeat count maps
1:1 to "12 suite runs" (1 initial + 11 repeats) everywhere this plan
touches, confirmed by this run: it started all 12 attempted suite runs
and completed 11 of them before the budget ran out. So "N repeats" means
the same thing in mix.exs, the workflow comment, CONTRIBUTING.md and
bin/classify-flake-run: N repeats, 1 + N suite runs.
```

**D-12 re-derivation.** `@cold_first_run_ceiling_s` and `@repeat_ceiling_s` in `test/threadline/flake_classifier_contract_test.exs` Test 6 cite `run 36888506162`: (`mix test test/threadline/flake_classifier_contract_test.exs`).

```text
Ceilings: 345.1s cold and 293.5s slowest repeat, each rounded up with a 1s
margin, give 346s cold / 295s per repeat. The workflow budget comment in
.github/workflows/flake-detection.yml cites the same run, the same
ceilings, and states they were measured with THREADLINE_PROPERTY_SCALE=5.

At the then-committed 11 repeats: 346 + 11 x 295 = 3591s, over the 2970s
usable (the 55-minute budget less 10% headroom). Dropping to 8 repeats:
346 + 8 x 295 = 2706s, leaving about 9% headroom; 9 repeats would be
346 + 9 x 295 = 3001s, still over budget. The repeat count in mix.exs
"verify.flake" dropped from 11 to 8 (9 suite runs), with the same count
mirrored in the workflow budget comment, CONTRIBUTING.md ("full suite,
8 repeats (fresh seed each)") and bin/classify-flake-run's header
comment -- all four pinned together by Test 6. The 55-minute
"timeout --signal=TERM --kill-after=60s 55m mix verify.flake" budget
itself is unchanged.

This measuring run (36888506162) was itself inconclusive by budget, not
by any failure -- the re-derivation above is sized so a confirmation run
at the new 8-repeat count fits inside the 2970s usable window with
margin to spare.
```

**Confirmation run at 8 repeats.** Flake Detection run 36897742852 on `740d6005` (`gh run view 36897742852 --log`) passed.

```text
THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3
Finished in 346.1 seconds (cold)
Finished in 284.3 / 285.8 / 285.3 / 287.5 / 284.7 / 279.6 / 284.6 / 284.3 seconds (repeats)
28 properties, 2649 tests, 0 failures, 3 excluded (all 9 runs)
Flake Detection classification: pass (completed iterations: 9, exit: 0)
```

**Ceiling correction.** The confirmation cold run (346.1s) exceeded the first-cut cold ceiling of 346s, which had also under-applied the stated rule (ceil(345.1 + 1) is 347, not 346). Re-applied over both runs (slowest cold 346.1s, slowest repeat 293.5s, each plus 1s, rounded up), `@cold_first_run_ceiling_s` is 348 and `@repeat_ceiling_s` stays 295 (`mix test test/threadline/flake_classifier_contract_test.exs`).

```text
348 + 8 x 295 = 2708s, within the 2970s usable window (about 9% headroom);
9 repeats would be 348 + 9 x 295 = 3003s, over budget. Repeat count stays 8.
```

## Partition weights (D-24)

At the unscaled run every one of the seven new files' own median module
cost (recorded in the local-timing evidence fragment) stays well under the two-second-per-file
threshold for a solo append, so `test/partition_weights.txt` is left
untouched. `bin/ci-test-partitions --write-weights` was never run.
