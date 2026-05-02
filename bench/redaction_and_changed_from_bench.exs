Code.require_file("bench_helper.exs", __DIR__)
Bench.Helper.setup()

alias Threadline.Test.Repo
alias Threadline.Capture.TriggerSQL

tables = [
  "bench_baseline",
  "bench_redacted",
  "bench_changed_from",
  "bench_both"
]

Enum.each(tables, fn t ->
  Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS #{t} CASCADE", [])
  Ecto.Adapters.SQL.query!(Repo, "CREATE TABLE #{t} (id bigserial PRIMARY KEY, public text, secret text, value integer)", [])
end)

# 1. Baseline
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.install_function())
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.create_trigger("bench_baseline"))

# 2. Redacted
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.install_function_for_table("bench_redacted", exclude: ["secret"], store_changed_from: false))
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.create_trigger("bench_redacted", :per_table))

# 3. Changed From
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.install_function_for_table("bench_changed_from", store_changed_from: true))
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.create_trigger("bench_changed_from", :per_table))

# 4. Both
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.install_function_for_table("bench_both", exclude: ["secret"], store_changed_from: true))
Ecto.Adapters.SQL.query!(Repo, TriggerSQL.create_trigger("bench_both", :per_table))

Bench.Explain.capture(
  "UPDATE bench_both SET value = value + 1, public = 'updated' WHERE id = 1",
  "cost_knobs_update.json"
)

# Seed an initial row for each table so UPDATE works
Enum.each(tables, fn t ->
  Repo.query!("INSERT INTO #{t} (public, secret, value) VALUES ('pub', 'sec', 1)")
end)

Benchee.run(
  %{
    "update_baseline" => fn ->
      Repo.query!("UPDATE bench_baseline SET value = value + 1, public = 'updated', secret = 'updated' WHERE id = 1")
    end,
    "update_redacted" => fn ->
      Repo.query!("UPDATE bench_redacted SET value = value + 1, public = 'updated', secret = 'updated' WHERE id = 1")
    end,
    "update_changed_from" => fn ->
      Repo.query!("UPDATE bench_changed_from SET value = value + 1, public = 'updated', secret = 'updated' WHERE id = 1")
    end,
    "update_both" => fn ->
      Repo.query!("UPDATE bench_both SET value = value + 1, public = 'updated', secret = 'updated' WHERE id = 1")
    end
  },
  time: 2,
  warmup: 1,
  formatters: Bench.Helper.formatters("redaction_and_changed_from_bench")
)
