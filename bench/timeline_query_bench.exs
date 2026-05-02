Code.require_file("bench_helper.exs", __DIR__)
Bench.Helper.setup()

alias Threadline.Test.Repo

# Note: seed_audit_changes.exs must be run before this for meaningful results

Bench.Explain.capture(
  "SELECT * FROM audit_changes c JOIN audit_transactions t ON c.transaction_id = t.id ORDER BY c.captured_at DESC, c.id DESC LIMIT 10",
  "timeline_query.json"
)

Benchee.run(
  %{
    "timeline_unfiltered" => fn ->
      Threadline.timeline([], repo: Repo)
    end,
    "timeline_by_table" => fn ->
      Threadline.timeline([table: "users"], repo: Repo)
    end
  },
  time: 2,
  warmup: 1,
  formatters: Bench.Helper.formatters("timeline_query_bench")
)
