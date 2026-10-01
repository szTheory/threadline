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

pending (no grant). Exact commands, to be run once the maintainer grants
the push and dispatch named in this plan's checkpoint task:

`git push origin milestone/v1.44`

`gh workflow run ci.yml --ref milestone/v1.44`

`gh run list --workflow ci.yml --branch milestone/v1.44 --limit 20`

`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare <before-run-id> <after-run-id>`

### Flake Detection at scale 5 (D-12)

pending (no grant). Exact command, to be run once the maintainer grants
the dispatch named in this plan's checkpoint task, after the ci.yml dispatch above
completes:

`gh workflow run flake-detection.yml --ref milestone/v1.44`

Until a THREADLINE_PROPERTY_SCALE=5 run is cited (via `gh workflow run flake-detection.yml`), the flake-classifier sizing test's ceilings in
`test/threadline/flake_classifier_contract_test.exs` and the budget
comment in `.github/workflows/flake-detection.yml` remain unchanged from
phase 225's measured values, so D-12's re-derivation at the scaled run count stays open.

## Partition weights (D-24)

At the unscaled run every one of the seven new files' own median module
cost (recorded in the local-timing evidence fragment) stays well under the two-second-per-file
threshold for a solo append, so `test/partition_weights.txt` is left
untouched. `bin/ci-test-partitions --write-weights` was never run.
