Rows tied on the timestamp are ordered by id descending, the same direction as the keyset predicate.

## Mutation control: cursor_sql.patch

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

Command: `mix test test/threadline/query_test.exs --seed <seed>`

```text
seed=1 exit=2 n=n/a first="  1) test timeline_page/2 concatenated pages match eager timeline order exactly (Threadline.QueryTest)"
seed=2 exit=2 n=n/a first="  1) test actor_history/2 — QUERY-02 pages across occurred_at ties forward and backward without duplicates or skips (Threadline.QueryTest)"
seed=3 exit=2 n=n/a first="  1) test timeline_page/2 concatenated pages match eager timeline order exactly (Threadline.QueryTest)"
seed=4 exit=2 n=n/a first="  1) test timeline_page/2 advances safely across captured_at ties without duplicates or skips (Threadline.QueryTest)"
seed=5 exit=2 n=n/a first="  1) test timeline_page/2 concatenated pages match eager timeline order exactly (Threadline.QueryTest)"
```

Kill rate: 5/5
Reproduce: seed 1 reproduces the same counterexample on a second run.
Green after restore: RED_FILE passes at seed 1 after reverting the patch; `git diff --quiet -- lib` is clean.

PROP-01 is a pure property over the real `Cursors` slicing/cursor code against an in-memory model of the keyset SQL; the SQL ordering and predicate are pinned by DB example tests that compare real query output to the same model on fixed tie-heavy fixtures.
