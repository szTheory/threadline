Code.require_file("bench_helper.exs", __DIR__)
Bench.Helper.setup()

alias Threadline.Test.Repo

# Setup table
Ecto.Adapters.SQL.query!(Repo, "DROP TABLE IF EXISTS bench_capture_target CASCADE", [])
Ecto.Adapters.SQL.query!(Repo, "CREATE TABLE bench_capture_target (id bigserial PRIMARY KEY, name text, value integer, inserted_at timestamp, updated_at timestamp)", [])

Ecto.Adapters.SQL.query!(Repo, Threadline.Capture.TriggerSQL.install_function())
Ecto.Adapters.SQL.query!(Repo, Threadline.Capture.TriggerSQL.create_trigger("bench_capture_target"))

Bench.Explain.capture(
  "INSERT INTO bench_capture_target (name, value, inserted_at, updated_at) VALUES ('test', 1, now(), now())",
  "audit_capture_insert.json"
)

# Benchmark Capture
Benchee.run(
  %{
    "insert" => fn _ ->
      Repo.query!("INSERT INTO bench_capture_target (name, value, inserted_at, updated_at) VALUES ('test', 1, now(), now())")
    end,
    "update" => fn _ ->
      Repo.query!("UPDATE bench_capture_target SET value = value + 1, updated_at = now() WHERE id = (SELECT id FROM bench_capture_target LIMIT 1)")
    end,
    "delete" => fn _ ->
      Repo.query!("DELETE FROM bench_capture_target WHERE id = (SELECT id FROM bench_capture_target LIMIT 1)")
    end
  },
  before_scenario: fn scenario ->
    # Ensure there is data for update/delete
    if scenario == "update" or scenario == "delete" do
      Repo.query!("INSERT INTO bench_capture_target (name, value, inserted_at, updated_at) VALUES ('test', 1, now(), now())")
    end
  end,
  time: 2,
  warmup: 1,
  formatters: Bench.Helper.formatters("audit_capture_bench")
)
