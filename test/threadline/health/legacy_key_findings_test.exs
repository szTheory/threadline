defmodule Threadline.Health.LegacyKeyFindingsTest do
  @moduledoc """
  Focused direct-fixture tests for `Threadline.Health.legacy_key_findings/1`:
  the `{}` variant, the count cap, storage-schema prefix correctness,
  `:schema` filtering, a no-key-args trigger, redacted/absent key columns,
  DELETE exclusion, the statement-timeout raise, option validation, and the
  no-telemetry / no-leaked-value guarantees (D-19..D-23, D-26).

  Rows are seeded through a real current-release trigger (so `table_pk`
  starts resolved), then directly rewritten on the storage-schema-qualified
  `audit_changes` table to the unresolved shapes a pre-0.11 install would
  have written — the same direct-rewrite technique
  `test/threadline/upgrade_backfill_test.exs` uses for its fixtures, applied
  here to isolated single-column tables so each behavior is exercised in
  one small table rather than the full upgrade fixture.
  """

  use Threadline.DataCase, async: false

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.TriggerSQL
  alias Threadline.Health
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL

  import Threadline.TelemetryHelpers

  @host_schema "lkf_host"

  setup do
    drop_host_schema!()
    SQL.query!(Repo, "CREATE SCHEMA #{StorageSchema.quote_ident(@host_schema)}", [])

    on_exit(fn -> drop_host_schema!() end)

    :ok
  end

  describe "the {} variant" do
    test "rows rewritten to '{}' are counted the same as '{\"id\": null}'" do
      table = "t_brace"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")
      rewrite_table_pk!(table, %{})

      [finding] =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema)
        |> Enum.filter(&(&1.table == table))

      assert finding.code == :unresolved_legacy_keys
      assert finding.details["unresolved_count"] == 1
      assert finding.details["key_columns"] == ["item_key"]
    end
  end

  describe "the count cap" do
    test "caps the reported count and sets capped true when exceeded" do
      table = "t_cap_exceeded"
      create_table!(table, "item_key")
      install_trigger!(table)

      for key <- ["k1", "k2", "k3"], do: insert_row!(table, "item_key", key, "v")

      rewrite_table_pk!(table, %{})

      [finding] =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema, count_cap: 2)
        |> Enum.filter(&(&1.table == table))

      assert finding.details["unresolved_count"] == 2
      assert finding.details["capped"] == true
      assert finding.message =~ "at least 2"
    end

    test "does not mark capped when the count is exactly at the cap" do
      table = "t_cap_boundary"
      create_table!(table, "item_key")
      install_trigger!(table)

      for key <- ["k1", "k2"], do: insert_row!(table, "item_key", key, "v")

      rewrite_table_pk!(table, %{})

      [finding] =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema, count_cap: 2)
        |> Enum.filter(&(&1.table == table))

      assert finding.details["unresolved_count"] == 2
      assert finding.details["capped"] == false
    end
  end

  describe "storage schema prefix correctness" do
    test "probes the configured storage schema, not the default" do
      prepare_storage_schema!("audit", Repo)

      with_storage_schema("audit", fn ->
        table = "t_storage_schema"
        create_table!(table, "item_key")
        install_trigger!(table)
        insert_row!(table, "item_key", "k1", "v")
        rewrite_table_pk!(table, %{})

        findings =
          Health.legacy_key_findings(repo: Repo, schema: @host_schema)
          |> Enum.filter(&(&1.table == table))

        assert [finding] = findings
        assert finding.details["unresolved_count"] == 1

        %{rows: [[count]]} =
          SQL.query!(
            Repo,
            """
            SELECT count(*) FROM #{StorageSchema.qualify("audit", "audit_changes")}
            WHERE table_schema = $1 AND table_name = $2
            """,
            [@host_schema, table]
          )

        assert count == 1
      end)
    end
  end

  describe ":schema filtering" do
    test "findings appear with the requested schema and are absent for another" do
      table = "t_schema_filter"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")
      rewrite_table_pk!(table, %{})

      in_schema =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema)
        |> Enum.filter(&(&1.table == table))

      assert [finding] = in_schema
      assert finding.schema == @host_schema

      out_of_schema =
        Health.legacy_key_findings(repo: Repo, schema: "public")
        |> Enum.filter(&(&1.table == table))

      assert out_of_schema == []
    end

    test "a non-string :schema raises ArgumentError" do
      assert_raise ArgumentError,
                   ~r/:schema must be a string or a non-empty list of strings/,
                   fn ->
                     Health.legacy_key_findings(repo: Repo, schema: 123)
                   end
    end
  end

  describe "no key args" do
    test "a table whose trigger has no key args yields no finding, even with {\"id\": null} rows" do
      table = "t_noargs"
      create_table!(table, "item_key")
      install_legacy_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")

      findings =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema)
        |> Enum.filter(&(&1.table == table))

      assert findings == []
    end
  end

  describe "redacted/missing key columns and DELETE rows" do
    test "a redacted key column is not counted, and a table with only such rows yields no finding" do
      table = "t_redacted"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")
      rewrite_table_pk!(table, %{})
      strip_key_from_data_after!(table, "item_key")

      findings =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema)
        |> Enum.filter(&(&1.table == table))

      assert findings == []
    end

    test "DELETE rows are never counted" do
      table = "t_delete"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")
      delete_row!(table, "item_key", "k1")
      rewrite_table_pk!(table, %{})

      [finding] =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema)
        |> Enum.filter(&(&1.table == table))

      assert finding.details["unresolved_count"] == 1
    end
  end

  describe "statement timeout" do
    test "a cancelled probe raises Postgrex.Error with code :query_canceled" do
      table = "t_timeout"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")
      rewrite_table_pk!(table, %{})

      test_pid = self()
      storage = StorageSchema.get()

      {:ok, lock_pid} =
        Task.start(fn ->
          Repo.transaction(fn ->
            SQL.query!(
              Repo,
              "LOCK TABLE #{StorageSchema.qualify(storage, "audit_changes")} IN ACCESS EXCLUSIVE MODE",
              []
            )

            send(test_pid, :locked)

            receive do
              :release -> :ok
            after
              5_000 -> :ok
            end
          end)
        end)

      assert_receive :locked, 2_000

      error =
        assert_raise Postgrex.Error, fn ->
          Health.legacy_key_findings(repo: Repo, schema: @host_schema, statement_timeout: 200)
        end

      assert error.postgres.code == :query_canceled

      send(lock_pid, :release)
      ref = Process.monitor(lock_pid)
      assert_receive {:DOWN, ^ref, :process, ^lock_pid, _reason}, 2_000
    end
  end

  describe "option validation" do
    test "an invalid :statement_timeout raises ArgumentError" do
      for bad <- [0, -1, "15s"] do
        assert_raise ArgumentError, ~r/:statement_timeout must be a positive integer/, fn ->
          Health.legacy_key_findings(repo: Repo, schema: @host_schema, statement_timeout: bad)
        end
      end
    end

    test "an invalid :count_cap raises ArgumentError" do
      for bad <- [0, -1, "10"] do
        assert_raise ArgumentError, ~r/:count_cap must be a positive integer/, fn ->
          Health.legacy_key_findings(repo: Repo, schema: @host_schema, count_cap: bad)
        end
      end
    end
  end

  describe "no telemetry" do
    test "legacy_key_findings/1 emits no [:threadline, :health, :findings_checked] event" do
      table = "t_notelemetry"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "k1", "v")
      rewrite_table_pk!(table, %{})

      ref = attach_telemetry!([[:threadline, :health, :findings_checked]])

      Health.legacy_key_findings(repo: Repo, schema: @host_schema)

      refute_receive {[:threadline, :health, :findings_checked], ^ref, _measurements, _metadata},
                     200
    end
  end

  describe "no leaked values" do
    test "no seeded data value appears in the finding's message or details" do
      table = "t_noleak"
      create_table!(table, "item_key")
      install_trigger!(table)
      insert_row!(table, "item_key", "super-secret-key-9f3a", "classified-value-7b2c")
      rewrite_table_pk!(table, %{})

      [finding] =
        Health.legacy_key_findings(repo: Repo, schema: @host_schema)
        |> Enum.filter(&(&1.table == table))

      refute finding.message =~ "super-secret-key-9f3a"
      refute finding.message =~ "classified-value-7b2c"
      refute inspect(finding.details) =~ "super-secret-key-9f3a"
      refute inspect(finding.details) =~ "classified-value-7b2c"
    end
  end

  # ---------------------------------------------------------------------
  # Fixture helpers
  # ---------------------------------------------------------------------

  defp create_table!(table, key_col) do
    SQL.query!(
      Repo,
      """
      CREATE TABLE #{StorageSchema.qualify(@host_schema, table)} (
        #{key_col} text PRIMARY KEY,
        value text
      )
      """,
      []
    )
  end

  defp install_trigger!(table) do
    SQL.query!(Repo, TriggerSQL.create_trigger("#{@host_schema}.#{table}"), [])
  end

  defp install_legacy_trigger!(table) do
    SQL.query!(
      Repo,
      LegacyTriggerSQL.v0_10_2_create_trigger(
        @host_schema,
        table,
        StorageSchema.function("threadline_capture_changes") <> "()"
      ),
      []
    )
  end

  defp insert_row!(table, key_col, key_value, value) do
    SQL.query!(
      Repo,
      "INSERT INTO #{StorageSchema.qualify(@host_schema, table)} (#{key_col}, value) VALUES ($1, $2)",
      [key_value, value]
    )
  end

  defp delete_row!(table, key_col, key_value) do
    SQL.query!(
      Repo,
      "DELETE FROM #{StorageSchema.qualify(@host_schema, table)} WHERE #{key_col} = $1",
      [key_value]
    )
  end

  # pk_term is bound as the raw Elixir term (never pre-JSON-encoded): Postgrex's
  # jsonb extension already encodes the term it receives, so passing a
  # pre-encoded string here would double-encode it into a jsonb scalar string
  # instead of the intended object (the same pitfall 229-01's independent
  # oracle hit with `table_pk`).
  defp rewrite_table_pk!(table, pk_term) do
    storage = StorageSchema.get()

    SQL.query!(
      Repo,
      """
      UPDATE #{StorageSchema.qualify(storage, "audit_changes")}
      SET table_pk = $1::jsonb
      WHERE table_schema = $2 AND table_name = $3
      """,
      [pk_term, @host_schema, table]
    )
  end

  defp strip_key_from_data_after!(table, key_col) do
    storage = StorageSchema.get()

    SQL.query!(
      Repo,
      """
      UPDATE #{StorageSchema.qualify(storage, "audit_changes")}
      SET data_after = data_after - $1
      WHERE table_schema = $2 AND table_name = $3
      """,
      [key_col, @host_schema, table]
    )
  end

  defp drop_host_schema! do
    SQL.query!(
      Repo,
      "DROP SCHEMA IF EXISTS #{StorageSchema.quote_ident(@host_schema)} CASCADE",
      []
    )

    for storage <- ["threadline", "audit"] do
      if storage_schema_exists?(storage) do
        SQL.query!(
          Repo,
          "DELETE FROM #{StorageSchema.qualify(storage, "audit_changes")} WHERE table_schema = $1",
          [@host_schema]
        )
      end
    end
  end

  defp storage_schema_exists?(schema) do
    %{rows: [[exists?]]} =
      SQL.query!(
        Repo,
        "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = $1)",
        [schema]
      )

    exists?
  end
end
