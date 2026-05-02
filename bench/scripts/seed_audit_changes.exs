# Run with: MIX_ENV=test mix run scripts/seed_audit_changes.exs

unless Mix.env() == :test do
  IO.puts(:stderr, "Use MIX_ENV=test")
  System.halt(1)
end

{:ok, _} = Application.ensure_all_started(:postgrex)
{:ok, _} = Application.ensure_all_started(:ecto_sql)

# Ensure threadline is started to load the Repo
{:ok, _} = Application.ensure_all_started(:threadline)

# Start your target Repo
{:ok, pid} = Threadline.Test.Repo.start_link()

try do
  preset = System.get_env("BENCH_PRESET") || "cold_single_table"

  IO.puts("Threadline: seeding benchmark for preset: #{preset}")

  now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

  Threadline.Test.Repo.query!("TRUNCATE TABLE audit_transactions CASCADE")

  # Base transaction for seeding
  {1, [%{id: tx_id}]} =
    Threadline.Test.Repo.insert_all(
      "audit_transactions",
      [
        %{
          id: Ecto.UUID.bingenerate(),
          txid: 1,
          occurred_at: now,
          source: "bench",
          meta: %{"actor_ref" => "bench_actor"}
        }
      ],
      returning: [:id]
    )

  case preset do
    "cold_single_table" ->
      IO.puts("Seeding cold_single_table...")

      changes =
        for i <- 1..1000 do
          %{
            id: Ecto.UUID.bingenerate(),
            transaction_id: tx_id,
            table_schema: "bench_tables",
            table_name: "users",
            table_pk: %{"id" => "#{i}"},
            op: "insert",
            data_after: %{"name" => "bench_user"},
            changed_fields: nil,
            changed_from: nil,
            captured_at: now
          }
        end

      Threadline.Test.Repo.insert_all("audit_changes", changes)

    "warm_loaded" ->
      IO.puts("Seeding warm_loaded...")

      changes =
        for i <- 1..5000 do
          %{
            id: Ecto.UUID.bingenerate(),
            transaction_id: tx_id,
            table_schema: "bench_tables",
            table_name: "posts",
            table_pk: %{"id" => "#{i}"},
            op: "update",
            data_after: %{"title" => "new"},
            changed_fields: ["title"],
            changed_from: %{"title" => "old"},
            captured_at: now
          }
        end

      Threadline.Test.Repo.insert_all("audit_changes", changes)

    "concurrent_purge" ->
      IO.puts("Seeding concurrent_purge...")
      # Generate lots of old data for purge test
      old_now = DateTime.add(now, -90, :day)

      {1, [%{id: old_tx_id}]} =
        Threadline.Test.Repo.insert_all(
          "audit_transactions",
          [
            %{
              id: Ecto.UUID.bingenerate(),
              txid: 2,
              occurred_at: old_now,
              source: "bench_old",
              meta: %{"actor_ref" => "bench_actor"}
            }
          ],
          returning: [:id]
        )

      changes =
        for i <- 1..10000 do
          %{
            id: Ecto.UUID.bingenerate(),
            transaction_id: old_tx_id,
            table_schema: "bench_tables",
            table_name: "logs",
            table_pk: %{"id" => "#{i}"},
            op: "insert",
            data_after: %{"status" => "ok"},
            changed_fields: nil,
            changed_from: nil,
            captured_at: old_now
          }
        end

      # Chunk inserts
      Enum.chunk_every(changes, 1000)
      |> Enum.each(fn chunk ->
        Threadline.Test.Repo.insert_all("audit_changes", chunk)
      end)

    _ ->
      IO.puts(:stderr, "Unknown preset: #{preset}")
      System.halt(1)
  end

  IO.puts("Threadline: benchmark seeding complete")
after
  GenServer.stop(pid, :normal, :infinity)
end
