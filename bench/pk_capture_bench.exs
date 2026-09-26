Code.require_file("bench_helper.exs", __DIR__)
Bench.Helper.setup()

# CAP-06: an in-server A/B benchmark of per-row capture overhead.
#
# Installs the frozen 0.10.2 global capture body (from bench/fixtures) and
# the current body as two differently named functions in one database, plus
# a sensitivity-control body whose key extraction reads pg_index per row.
# Each variant runs on its own freshly created table: INSERT ... SELECT
# generate_series, then UPDATE every row, then DELETE every row, timed
# in-server with clock_timestamp() via a single EXECUTE per statement.
# Variant order alternates each rep so machine drift does not favor one
# side. Medians are reported in microseconds per row.
#
# Pass bar (D-07): current/baseline <= 1.10x on every operation, and
# catalog/baseline >= 1.25x on every operation (proving the bench can see a
# regression of the size the bar guards). The composite/current ratio is
# reported only, with no bar.

alias Threadline.Test.Repo
alias Threadline.Capture.TriggerSQL

rows = String.to_integer(System.get_env("BENCH_PK_ROWS") || "50000")
reps = String.to_integer(System.get_env("BENCH_PK_REPS") || "5")

fixture_path = Path.expand("fixtures/threadline_capture_changes_v0_10_2.sql", __DIR__)
baseline_sql = File.read!(fixture_path)

baseline_fn = ~s|"threadline"."bench_capture_v0_10_2"|
catalog_fn = ~s|"threadline"."bench_capture_catalog"|

assignment_regex =
  ~r/v_table_pk\s+:= jsonb_build_object\('id', \(to_jsonb\((OLD|NEW)\) ->> 'id'\)\);/

match_count = assignment_regex |> Regex.scan(baseline_sql) |> length()

unless match_count == 3 do
  IO.puts(
    :stderr,
    "bench: expected 3 id-extraction assignments in the fixture, found #{match_count}"
  )

  System.halt(1)
end

catalog_sql =
  Regex.replace(
    assignment_regex,
    String.replace(baseline_sql, baseline_fn, catalog_fn),
    fn _whole, row_var ->
      "v_table_pk := (SELECT coalesce(jsonb_object_agg(a.attname, (to_jsonb(#{row_var}) ->> a.attname)), '{}'::jsonb) " <>
        "FROM pg_index i " <>
        "CROSS JOIN LATERAL unnest(i.indkey::int2[]) WITH ORDINALITY AS k(attnum, ord) " <>
        "JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = k.attnum " <>
        "WHERE i.indrelid = TG_RELID AND i.indisprimary AND k.ord <= i.indnkeyatts);"
    end
  )

# ---- install the three function bodies ------------------------------------

Repo.query!(TriggerSQL.install_function())
Repo.query!(baseline_sql)
Repo.query!(catalog_sql)

Repo.query!("""
CREATE OR REPLACE FUNCTION bench_elapsed_us(sql text) RETURNS double precision AS $$
DECLARE
  t0 timestamptz;
  t1 timestamptz;
BEGIN
  t0 := clock_timestamp();
  EXECUTE sql;
  t1 := clock_timestamp();
  RETURN extract(epoch FROM (t1 - t0)) * 1000000;
END;
$$ LANGUAGE plpgsql;
""")

# ---- variant table shapes and trigger install ------------------------------

defmodule Bench.PKCapture do
  @moduledoc false

  alias Threadline.Test.Repo
  alias Threadline.Capture.TriggerSQL

  def create_single_table!(name) do
    Repo.query!("DROP TABLE IF EXISTS #{name}")

    Repo.query!("""
    CREATE TABLE #{name} (
      id      bigint PRIMARY KEY,
      name    text,
      value   int,
      payload text
    )
    """)
  end

  def create_composite_table!(name) do
    Repo.query!("DROP TABLE IF EXISTS #{name}")

    Repo.query!("""
    CREATE TABLE #{name} (
      a       bigint,
      b       bigint,
      name    text,
      value   int,
      payload text,
      PRIMARY KEY (a, b)
    )
    """)
  end

  def install_no_arg_trigger!(table, function_ref) do
    Repo.query!("""
    CREATE OR REPLACE TRIGGER bench_trigger_#{table}
    AFTER INSERT OR UPDATE OR DELETE ON #{table}
    FOR EACH ROW EXECUTE FUNCTION #{function_ref}()
    """)
  end

  def install_resolved_trigger!(table) do
    Repo.query!(TriggerSQL.create_trigger(table))
  end

  def elapsed_us!(sql) do
    %{rows: [[us]]} = Repo.query!("SELECT bench_elapsed_us($1)", [sql])
    us
  end

  def cleanup!(table) do
    Repo.query!(
      "DELETE FROM #{Threadline.StorageSchema.table("audit_changes")} WHERE table_name = $1",
      [table]
    )

    Repo.query!("""
    DELETE FROM #{Threadline.StorageSchema.table("audit_transactions")} t
     WHERE NOT EXISTS (
       SELECT 1 FROM #{Threadline.StorageSchema.table("audit_changes")} c
        WHERE c.transaction_id = t.id
     )
    """)

    Repo.query!("VACUUM ANALYZE #{Threadline.StorageSchema.table("audit_transactions")}")
    Repo.query!("VACUUM ANALYZE #{Threadline.StorageSchema.table("audit_changes")}")
    Repo.query!("DROP TABLE IF EXISTS #{table}")
  end
end

single_insert = fn table, rows ->
  "INSERT INTO #{table} (id, name, value, payload) " <>
    "SELECT s, 'row' || s, s::int, repeat('x', 50) FROM generate_series(1, #{rows}) AS s"
end

single_update = fn table -> "UPDATE #{table} SET value = value + 1" end
single_delete = fn table -> "DELETE FROM #{table}" end

composite_insert = fn table, rows ->
  "INSERT INTO #{table} (a, b, name, value, payload) " <>
    "SELECT s, 1, 'row' || s, s::int, repeat('x', 50) FROM generate_series(1, #{rows}) AS s"
end

composite_update = fn table -> "UPDATE #{table} SET value = value + 1" end
composite_delete = fn table -> "DELETE FROM #{table}" end

run_composite_variant = fn table ->
  Bench.PKCapture.create_composite_table!(table)
  Bench.PKCapture.install_resolved_trigger!(table)

  insert_us = Bench.PKCapture.elapsed_us!(composite_insert.(table, rows))
  update_us = Bench.PKCapture.elapsed_us!(composite_update.(table))
  delete_us = Bench.PKCapture.elapsed_us!(composite_delete.(table))

  Bench.PKCapture.cleanup!(table)

  %{insert: insert_us, update: update_us, delete: delete_us}
end

# `current` resolves its trigger's primary key from pg_index at install
# time (TriggerSQL.create_trigger/1), so its table must already exist
# before the trigger is installed; baseline and catalog just point a plain
# no-argument trigger at their (differently named) function.
run_variant = fn
  :current, table ->
    Bench.PKCapture.create_single_table!(table)
    Bench.PKCapture.install_resolved_trigger!(table)

    insert_us = Bench.PKCapture.elapsed_us!(single_insert.(table, rows))
    update_us = Bench.PKCapture.elapsed_us!(single_update.(table))
    delete_us = Bench.PKCapture.elapsed_us!(single_delete.(table))

    Bench.PKCapture.cleanup!(table)

    %{insert: insert_us, update: update_us, delete: delete_us}

  variant, table when variant in [:baseline, :catalog] ->
    Bench.PKCapture.create_single_table!(table)

    function_ref = if variant == :baseline, do: baseline_fn, else: catalog_fn
    Bench.PKCapture.install_no_arg_trigger!(table, function_ref)

    insert_us = Bench.PKCapture.elapsed_us!(single_insert.(table, rows))
    update_us = Bench.PKCapture.elapsed_us!(single_update.(table))
    delete_us = Bench.PKCapture.elapsed_us!(single_delete.(table))

    Bench.PKCapture.cleanup!(table)

    %{insert: insert_us, update: update_us, delete: delete_us}
end

# ---- run reps, alternating variant order -----------------------------------

base_order = [:baseline, :current, :catalog]

results =
  for rep <- 1..reps, reduce: %{baseline: [], current: [], catalog: [], composite: []} do
    acc ->
      order = if rem(rep, 2) == 1, do: base_order, else: Enum.reverse(base_order)

      acc =
        Enum.reduce(order, acc, fn variant, acc ->
          table = "bench_pk_single"
          result = run_variant.(variant, table)
          Map.update!(acc, variant, &[result | &1])
        end)

      composite_result = run_composite_variant.("bench_pk_composite")
      Map.update!(acc, :composite, &[composite_result | &1])
  end

median = fn list ->
  sorted = Enum.sort(list)
  n = length(sorted)
  mid = div(n, 2)

  if rem(n, 2) == 1 do
    Enum.at(sorted, mid)
  else
    (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
  end
end

medians =
  for {variant, reps_results} <- results, into: %{} do
    per_op =
      for op <- [:insert, :update, :delete], into: %{} do
        values = Enum.map(reps_results, &Map.fetch!(&1, op))
        {op, median.(values) / rows}
      end

    {variant, per_op}
  end

ops = [:insert, :update, :delete]

current_baseline_ratios =
  for op <- ops, into: %{}, do: {op, medians.current[op] / medians.baseline[op]}

catalog_baseline_ratios =
  for op <- ops, into: %{}, do: {op, medians.catalog[op] / medians.baseline[op]}

composite_current_ratios =
  for op <- ops, into: %{}, do: {op, medians.composite[op] / medians.current[op]}

current_pass? = Enum.all?(ops, &(current_baseline_ratios[&1] <= 1.10))
catalog_pass? = Enum.all?(ops, &(catalog_baseline_ratios[&1] >= 1.25))
overall_pass? = current_pass? and catalog_pass?

fmt = fn us -> :erlang.float_to_binary(us, decimals: 3) end
fmt_ratio = fn r -> :erlang.float_to_binary(r, decimals: 3) end

header =
  "| Operation | baseline (us/row) | current (us/row) | current/baseline | catalog (us/row) | catalog/baseline | composite (us/row) | composite/current |"

divider = "| --- | --- | --- | --- | --- | --- | --- | --- |"

rows_md =
  for op <- ops do
    "| #{op} | #{fmt.(medians.baseline[op])} | #{fmt.(medians.current[op])} | #{fmt_ratio.(current_baseline_ratios[op])} | #{fmt.(medians.catalog[op])} | #{fmt_ratio.(catalog_baseline_ratios[op])} | #{fmt.(medians.composite[op])} | #{fmt_ratio.(composite_current_ratios[op])} |"
  end

table_md = Enum.join([header, divider | rows_md], "\n")

IO.puts(table_md)
IO.puts("")

if overall_pass? do
  IO.puts("PASS: current/baseline <= 1.10x and catalog/baseline >= 1.25x on every operation")
else
  IO.puts("FAIL: current/baseline > 1.10x or catalog/baseline < 1.25x on at least one operation")
end

# ---- record metadata and write the baseline file ---------------------------

{sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
sha = String.trim(sha)

%{rows: [[server_version]]} = Ecto.Adapters.SQL.query!(Repo, "SHOW server_version", [])

{uname, 0} = System.cmd("uname", ["-sm"])
uname = String.trim(uname)

cpu_brand =
  case System.cmd("sysctl", ["-n", "machdep.cpu.brand_string"], stderr_to_stdout: true) do
    {brand, 0} ->
      String.trim(brand)

    _ ->
      case File.read("/proc/cpuinfo") do
        {:ok, contents} ->
          contents
          |> String.split("\n")
          |> Enum.find(&String.starts_with?(&1, "model name"))
          |> case do
            nil -> "unknown"
            line -> line |> String.split(":", parts: 2) |> Enum.at(1, "") |> String.trim()
          end

        _ ->
          "unknown"
      end
  end

machine = "#{uname} (#{cpu_brand})"

baseline_dir = Path.expand("baselines", __DIR__)
File.mkdir_p!(baseline_dir)

markdown = """
# CAP-06 capture overhead benchmark

- **Commit:** #{sha}
- **PostgreSQL server_version:** #{server_version}
- **Elixir:** #{System.version()}
- **OTP:** #{System.otp_release()}
- **Machine:** #{machine}
- **Rows:** #{rows}
- **Reps:** #{reps}

#{table_md}

#{if overall_pass?, do: "PASS", else: "FAIL"}: current/baseline <= 1.10x and catalog/baseline >= 1.25x on every operation (D-07 pass bar).
"""

File.write!(Path.join(baseline_dir, "pk_capture_bench.md"), markdown)

unless overall_pass? do
  System.halt(1)
end
