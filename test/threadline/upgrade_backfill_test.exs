defmodule Threadline.UpgradeBackfillTest do
  @moduledoc """
  Proves, on real PostgreSQL, that the published `guides/upgrading-to-0.11.md`
  upgrade procedure and its marker-wrapped backfill SQL work against a seeded
  0.10.x install.

  The SQL executed here is extracted from the guide's own
  `threadline:backfill-sql:start`/`-composite:start` marker pairs, with only
  the guide's own documented angle-bracket placeholders substituted — never
  duplicated by hand — so this test is a live proof of exactly the text an
  adopter would paste, not of a hand-copied approximation of it (D-07/D-08).

  Each fixture table is seeded as a 0.10.2-shaped install would be: a real
  applied migration installs the frozen `LegacyTriggerSQL.v0_10_2_create_trigger/3`
  trigger, calling the storage-qualified frozen 0.10.2 global function body
  (`LegacyTriggerSQL.v0_10_2_install_function/2`), so rows captured before the
  upgrade carry the same shape a real pre-0.11 install would have written.
  """

  use Threadline.DataCase, async: false

  alias Mix.Tasks.Threadline.Gen.RowHistoryIndex
  alias Threadline.Capture.{Naming, RowHistoryIndexSQL, TriggerSQL}
  alias Threadline.Health
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @guide_path "guides/upgrading-to-0.11.md"

  @single_marker_start "<!-- threadline:backfill-sql:start -->"
  @single_marker_end "<!-- threadline:backfill-sql:end -->"
  @composite_marker_start "<!-- threadline:backfill-sql-composite:start -->"
  @composite_marker_end "<!-- threadline:backfill-sql-composite:end -->"

  # The non-id-keyed tracer table (Task 1).
  @doc_table "upg_documents"

  # Task 2 fixture shapes.
  @acct_table "upg_accounts"
  @tags_table "upg_tags"
  @widget_table "upg_widgets"
  @readings_table "upg_readings"
  @public_pair {"public", "billing_invoices"}
  @schema_pair {"billing", "invoices"}
  @shared_function "threadline_capture_changes_billing_invoices"

  @fixture_tables [
    {"public", "upg_documents"},
    {"public", "upg_accounts"},
    {"public", "upg_tags"},
    {"public", "upg_widgets"},
    {"public", "upg_readings"},
    {"public", "billing_invoices"},
    {"billing", "invoices"}
  ]

  setup do
    storage = StorageSchema.get()
    previous_shell = Mix.shell()
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-upgrade-backfill-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)
    drop_fixtures!(storage)

    # A real 0.10.x install has the frozen global body installed at the real
    # global function name; a default-mode regenerated migration refreshes
    # it, so seeding it here reproduces that starting state exactly.
    Repo.query!(
      LegacyTriggerSQL.v0_10_2_install_function(
        StorageSchema.function("threadline_capture_changes"),
        storage
      )
    )

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_capture do
        {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
        :error -> Application.delete_env(:threadline, :trigger_capture)
      end

      # Restore the current-release global body, so later tests never see the
      # frozen 0.10.2 body left behind.
      Repo.query!(TriggerSQL.install_function([]))

      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!(storage)
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp, storage: storage}
  end

  defmodule UpgDocument do
    use Ecto.Schema

    @primary_key false
    schema "upg_documents" do
      field(:doc_key, :string, primary_key: true)
      field(:title, :string)
    end
  end

  describe "Task 1 (tracer): a non-id-keyed table through the whole documented path" do
    test "the guide's own single-column backfill SQL resolves legacy rows, leaves DELETE alone, is idempotent, and history/3 finds them",
         %{tmp: tmp, storage: storage} do
      Repo.query!("""
      CREATE TABLE #{@doc_table} (
        doc_key text PRIMARY KEY,
        title   text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @doc_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      write_fixture_migration!(
        tmp,
        "20240301000000_threadline_triggers_upg_documents.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersUpgDocuments",
        [
          LegacyTriggerSQL.v0_10_2_create_trigger(
            "public",
            @doc_table,
            StorageSchema.function("threadline_capture_changes") <> "()"
          )
        ],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@doc_table} ON #{@doc_table}"]
      )

      # Seed pre-upgrade rows: an INSERT, an UPDATE, a DELETE (on distinct
      # rows), and one row kept live for the post-upgrade comparison.
      Repo.query!(
        "INSERT INTO #{@doc_table} (doc_key, title) VALUES ('doc-insert', 'Insert doc')"
      )

      Repo.query!(
        "INSERT INTO #{@doc_table} (doc_key, title) VALUES ('doc-update', 'Before update')"
      )

      Repo.query!("UPDATE #{@doc_table} SET title = 'After update' WHERE doc_key = 'doc-update'")

      Repo.query!(
        "INSERT INTO #{@doc_table} (doc_key, title) VALUES ('doc-delete', 'To be deleted')"
      )

      Repo.query!("DELETE FROM #{@doc_table} WHERE doc_key = 'doc-delete'")

      Repo.query!("INSERT INTO #{@doc_table} (doc_key, title) VALUES ('doc-live', 'Live doc')")

      assert pre_upgrade_table_pks(storage, @doc_table) |> Enum.all?(&(&1 == %{"id" => nil}))

      file = Harness.generate!(tmp, ["--tables", @doc_table])
      assert {:ok, _log} = Harness.migrate_up(file)

      Repo.query!(
        "UPDATE #{@doc_table} SET title = 'Live after regen' WHERE doc_key = 'doc-live'"
      )

      reference_pk = latest_table_pk(storage, @doc_table, "update")
      assert reference_pk == %{"doc_key" => "doc-live"}

      sql =
        extract_marker(@guide_path, @single_marker_start, @single_marker_end)
        |> substitute(%{
          "<storage_schema>" => storage,
          "<host_schema>" => "public",
          "<host_table>" => @doc_table,
          "<key_col>" => "doc_key",
          "<batch_size>" => "1"
        })

      run_batched!(sql)

      insert_pk = table_pk_for(storage, @doc_table, "doc-insert", "insert")
      assert insert_pk == %{"doc_key" => "doc-insert"}

      update_pk = table_pk_for(storage, @doc_table, "doc-update", "update")
      assert update_pk == %{"doc_key" => "doc-update"}

      live_backfilled_pk = table_pk_for(storage, @doc_table, "doc-live", "insert")
      assert live_backfilled_pk == %{"doc_key" => "doc-live"}

      # history/3 for the live row returns both eras.
      history_rows = Threadline.history(UpgDocument, "doc-live", repo: Repo)
      assert length(history_rows) == 2
      assert Enum.map(history_rows, & &1.op) |> Enum.sort() == ["insert", "update"]

      # DELETE row is untouched: still {"id": null}, still nil data_after.
      delete_change = change_for(storage, @doc_table, "delete")
      assert delete_change.table_pk == %{"id" => nil}
      assert delete_change.data_after == nil

      # Idempotency: a rerun returns 0 rows on its first iteration and leaves
      # every row unchanged.
      before_snapshot = table_pk_snapshot(storage, @doc_table)
      rerun_result = Repo.query!(sql)
      assert rerun_result.num_rows == 0
      after_snapshot = table_pk_snapshot(storage, @doc_table)
      assert before_snapshot == after_snapshot
    end
  end

  defmodule UpgAccount do
    use Ecto.Schema

    schema "upg_accounts" do
      field(:name, :string)
    end
  end

  defmodule UpgTag do
    use Ecto.Schema

    @primary_key false
    schema "upg_tags" do
      field(:post_id, :integer, primary_key: true)
      field(:tag_id, :integer, primary_key: true)
      field(:label, :string)
    end
  end

  describe "Task 2: the full seeded 0.10.x fixture" do
    test "id, composite, shared-function pair, timestamptz, index, health, interruption",
         %{tmp: tmp, storage: storage} do
      # --- Fixture setup: every shape as a real applied 0.10.2-shaped migration ---

      Repo.query!("""
      CREATE TABLE #{@acct_table} (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @acct_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      write_fixture_migration!(
        tmp,
        "20240302000000_threadline_triggers_upg_accounts.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersUpgAccounts",
        [
          LegacyTriggerSQL.v0_10_2_create_trigger(
            "public",
            @acct_table,
            StorageSchema.function("threadline_capture_changes") <> "()"
          )
        ],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@acct_table} ON #{@acct_table}"]
      )

      Repo.query!("""
      CREATE TABLE #{@tags_table} (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        label   text,
        PRIMARY KEY (post_id, tag_id)
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @tags_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      write_fixture_migration!(
        tmp,
        "20240303000000_threadline_triggers_upg_tags.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersUpgTags",
        [
          LegacyTriggerSQL.v0_10_2_create_trigger(
            "public",
            @tags_table,
            StorageSchema.function("threadline_capture_changes") <> "()"
          )
        ],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@tags_table} ON #{@tags_table}"]
      )

      Repo.query!("""
      CREATE TABLE #{@widget_table} (
        widget_key text PRIMARY KEY,
        name       text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @widget_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      write_fixture_migration!(
        tmp,
        "20240304000000_threadline_triggers_upg_widgets.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersUpgWidgets",
        [
          LegacyTriggerSQL.v0_10_2_create_trigger(
            "public",
            @widget_table,
            StorageSchema.function("threadline_capture_changes") <> "()"
          )
        ],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@widget_table} ON #{@widget_table}"]
      )

      Repo.query!("""
      CREATE TABLE #{@readings_table} (
        recorded_at timestamptz PRIMARY KEY,
        note        text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @readings_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      write_fixture_migration!(
        tmp,
        "20240305000000_threadline_triggers_upg_readings.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersUpgReadings",
        [
          LegacyTriggerSQL.v0_10_2_create_trigger(
            "public",
            @readings_table,
            StorageSchema.function("threadline_capture_changes") <> "()"
          )
        ],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@readings_table} ON #{@readings_table}"]
      )

      # Shared per-table function pair, reproducing the 0.10.x shape where two
      # tables shared one capture function (the phase-209 issue).
      Repo.query!("CREATE SCHEMA IF NOT EXISTS billing")

      for {schema, table} <- [@public_pair, @schema_pair] do
        Repo.query!("""
        CREATE TABLE #{ref(schema, table)} (
          id     bigserial PRIMARY KEY,
          email  text,
          secret text
        )
        """)
      end

      shared_fixture_sql =
        LegacyTriggerSQL.v0_10_2_install_function_for_table(
          @shared_function,
          storage,
          mask: ["secret"]
        )

      assert shared_fixture_sql =~ StorageSchema.function(@shared_function) <> "()"
      Repo.query!(shared_fixture_sql)

      shared_function_ref = StorageSchema.function(@shared_function) <> "()"

      for {schema, table} <- [@public_pair, @schema_pair] do
        Repo.query!(LegacyTriggerSQL.v0_10_2_create_trigger(schema, table, shared_function_ref))
      end

      shared_drops =
        for {schema, table} <- [@public_pair, @schema_pair],
            do:
              ~s|DROP TRIGGER IF EXISTS "threadline_audit_billing_invoices" ON #{ref(schema, table)}|

      write_fixture_migration!(
        tmp,
        "20240306000000_threadline_triggers_billing_invoices_invoices.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersBillingInvoicesInvoices",
        for(
          {schema, table} <- [@public_pair, @schema_pair],
          do: LegacyTriggerSQL.v0_10_2_create_trigger(schema, table, shared_function_ref)
        ),
        shared_drops
      )

      # --- Seed pre-upgrade rows ---

      %{rows: [[acct_id_1]]} =
        Repo.query!("INSERT INTO #{@acct_table} (name) VALUES ('a') RETURNING id")

      %{rows: [[acct_id_2]]} =
        Repo.query!("INSERT INTO #{@acct_table} (name) VALUES ('b') RETURNING id")

      Repo.query!("INSERT INTO #{@tags_table} (post_id, tag_id, label) VALUES (1, 5, 'a')")
      Repo.query!("INSERT INTO #{@tags_table} (post_id, tag_id, label) VALUES (1, 6, 'b')")
      Repo.query!("UPDATE #{@tags_table} SET label = 'a2' WHERE post_id = 1 AND tag_id = 5")

      Repo.query!(
        "INSERT INTO #{@widget_table} (widget_key, name) VALUES ('widget-insert', 'W1')"
      )

      Repo.query!(
        "INSERT INTO #{@widget_table} (widget_key, name) VALUES ('widget-update', 'W2 before')"
      )

      Repo.query!(
        "UPDATE #{@widget_table} SET name = 'W2 after' WHERE widget_key = 'widget-update'"
      )

      Repo.query!(
        "INSERT INTO #{ref("public", "billing_invoices")} (email, secret) VALUES ('e1', 's1')"
      )

      Repo.query!("INSERT INTO #{ref("billing", "invoices")} (email, secret) VALUES ('e2', 's2')")

      # Pre-upgrade table_pk assertions: id-keyed is already correct;
      # non-id-keyed and composite are still unresolved.
      assert account_table_pks(storage) == %{
               acct_id_1 => %{"id" => Integer.to_string(acct_id_1)},
               acct_id_2 => %{"id" => Integer.to_string(acct_id_2)}
             }

      assert pre_upgrade_table_pks(storage, @tags_table) |> Enum.all?(&(&1 == %{"id" => nil}))
      assert pre_upgrade_table_pks(storage, @widget_table) |> Enum.all?(&(&1 == %{"id" => nil}))

      # --- Step 2: regenerate the default-mode tables together ---

      default_file =
        Harness.generate!(tmp, ["--tables", "#{@acct_table},#{@tags_table},#{@widget_table}"])

      assert {:ok, _log} = Harness.migrate_up(default_file)

      # --- Step 2: regenerate the shared pair together, under per-table config ---

      Application.put_env(:threadline, :trigger_capture,
        tables: %{
          "billing_invoices" => [mask: ["secret"]],
          "billing.invoices" => [mask: ["secret"]]
        }
      )

      shared_file = Harness.generate!(tmp, ["--tables", "billing_invoices,billing.invoices"])
      assert {:ok, _shared_log} = Harness.migrate_up(shared_file)

      public_fn = Harness.trigger_function("public", "billing_invoices")
      schema_fn = Harness.trigger_function("billing", "invoices")
      assert public_fn != schema_fn

      # --- Step 2: the timestamptz table is refused, naming the column ---

      readings_file = Harness.generate!(tmp, ["--tables", @readings_table])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(readings_file) end)
      assert error.postgres.message =~ "recorded_at"

      refute migrated?(readings_file)

      assert Harness.trigger_function("public", @readings_table) ==
               {storage, "threadline_capture_changes"}

      assert Harness.threadline_triggers("public", @readings_table) == [
               {"threadline_audit_upg_readings", "O"}
             ]

      File.rm!(readings_file)

      # --- Step 4: the row-history index ---

      index_file =
        File.cd!(tmp, fn ->
          RowHistoryIndex.run([])
          drain_shell()
        end)

      [index_migration] =
        [tmp, "priv", "repo", "migrations", "*_threadline_row_history_index.exs"]
        |> Path.join()
        |> Path.wildcard()

      refute index_file == nil
      assert {:ok, _index_log} = Harness.migrate_up(index_migration)
      assert row_history_index_valid?(storage) == true

      # --- Step 5: health ---

      fixture_table_names = Enum.map(@fixture_tables, fn {_s, t} -> t end)

      findings =
        Health.trigger_findings(repo: Repo)
        |> Enum.filter(&(&1.table in fixture_table_names))

      error_findings = Enum.filter(findings, &(&1.severity == :error))
      assert Enum.map(error_findings, & &1.table) == [@readings_table]
      assert hd(error_findings).code == :pk_drift

      coverage =
        Health.trigger_coverage(repo: Repo, schema: "public")
        |> Enum.filter(fn {_status, table} -> table in fixture_table_names end)

      for table <- [@acct_table, @tags_table, @widget_table, "billing_invoices"] do
        assert {:covered, ^table} = Enum.find(coverage, fn {_s, t} -> t == table end)
      end

      # --- Step 6: backfill the non-id and composite tables ---

      single_sql =
        extract_marker(@guide_path, @single_marker_start, @single_marker_end)
        |> substitute(%{
          "<storage_schema>" => storage,
          "<host_schema>" => "public",
          "<host_table>" => @widget_table,
          "<key_col>" => "widget_key",
          "<batch_size>" => "5000"
        })

      run_batched!(single_sql)

      widget_insert_pk =
        table_pk_for(storage, @widget_table, "widget-insert", "insert", "widget_key")

      assert widget_insert_pk == %{"widget_key" => "widget-insert"}

      widget_update_pk =
        table_pk_for(storage, @widget_table, "widget-update", "insert", "widget_key")

      assert widget_update_pk == %{"widget_key" => "widget-update"}

      composite_sql =
        extract_marker(@guide_path, @composite_marker_start, @composite_marker_end)
        |> substitute(%{
          "<storage_schema>" => storage,
          "<host_schema>" => "public",
          "<host_table>" => @tags_table,
          "<key_col_1>" => "post_id",
          "<key_col_2>" => "tag_id",
          "<batch_size>" => "5000"
        })

      run_batched!(composite_sql)

      composite_rows = Threadline.history(UpgTag, [post_id: 1, tag_id: 5], repo: Repo)
      assert length(composite_rows) == 2
      assert Enum.all?(composite_rows, &(&1.table_pk == %{"post_id" => "1", "tag_id" => "5"}))

      other_composite_row = Threadline.history(UpgTag, [post_id: 1, tag_id: 6], repo: Repo)
      assert length(other_composite_row) == 1
      assert hd(other_composite_row).table_pk == %{"post_id" => "1", "tag_id" => "6"}

      # --- id-keyed table: untouched by backfill, no unresolved rows to begin with ---
      assert account_table_pks(storage) == %{
               acct_id_1 => %{"id" => Integer.to_string(acct_id_1)},
               acct_id_2 => %{"id" => Integer.to_string(acct_id_2)}
             }
    end
  end

  describe "Task 2: interruption edge" do
    test "stopping after one batch and rerunning to completion resolves the same keys as one uninterrupted run",
         %{tmp: tmp, storage: storage} do
      Repo.query!("""
      CREATE TABLE #{@doc_table} (
        doc_key text PRIMARY KEY,
        title   text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          @doc_table,
          StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      write_fixture_migration!(
        tmp,
        "20240301000000_threadline_triggers_upg_documents.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersUpgDocuments",
        [
          LegacyTriggerSQL.v0_10_2_create_trigger(
            "public",
            @doc_table,
            StorageSchema.function("threadline_capture_changes") <> "()"
          )
        ],
        ["DROP TRIGGER IF EXISTS threadline_audit_#{@doc_table} ON #{@doc_table}"]
      )

      Repo.query!("INSERT INTO #{@doc_table} (doc_key, title) VALUES ('interrupt-a', 'A')")
      Repo.query!("INSERT INTO #{@doc_table} (doc_key, title) VALUES ('interrupt-b', 'B')")
      Repo.query!("INSERT INTO #{@doc_table} (doc_key, title) VALUES ('interrupt-c', 'C')")

      file = Harness.generate!(tmp, ["--tables", @doc_table])
      assert {:ok, _log} = Harness.migrate_up(file)

      sql =
        extract_marker(@guide_path, @single_marker_start, @single_marker_end)
        |> substitute(%{
          "<storage_schema>" => storage,
          "<host_schema>" => "public",
          "<host_table>" => @doc_table,
          "<key_col>" => "doc_key",
          "<batch_size>" => "1"
        })

      first_batch = Repo.query!(sql)
      assert first_batch.num_rows == 1

      run_batched!(sql)

      final_snapshot = table_pk_snapshot(storage, @doc_table)

      expected =
        final_snapshot
        |> Enum.map(fn {_id, pk} -> pk end)
        |> Enum.sort()

      assert expected == [
               %{"doc_key" => "interrupt-a"},
               %{"doc_key" => "interrupt-b"},
               %{"doc_key" => "interrupt-c"}
             ]
    end
  end

  # ---------------------------------------------------------------------
  # Shared helpers
  # ---------------------------------------------------------------------

  # Extracts the exact text between one marker pair (parts: 2 each side),
  # strips the surrounding ```sql fence lines, and returns the raw SQL text
  # exactly as the guide publishes it.
  defp extract_marker(path, marker_start, marker_end) do
    content = File.read!(path)
    [_before, rest] = String.split(content, marker_start, parts: 2)
    [block, _after] = String.split(rest, marker_end, parts: 2)

    block
    |> String.split("\n")
    |> Enum.reject(&(String.trim(&1) in ["```sql", "```", ""]))
    |> Enum.join("\n")
  end

  # Substitutes only the guide's own documented angle-bracket placeholders,
  # with String.replace/3 — no other edit to the published text.
  defp substitute(sql, replacements) do
    Enum.reduce(replacements, sql, fn {placeholder, value}, acc ->
      String.replace(acc, placeholder, value)
    end)
  end

  # Runs a `LIMIT <batch_size>`-bounded statement in a bounded loop until it
  # reports 0 rows changed, flunking if the bound is hit — proves the guide's
  # documented "run it repeatedly until UPDATE 0" batch pattern actually
  # terminates.
  defp run_batched!(sql) do
    result =
      Enum.reduce_while(1..50, :not_done, fn _i, _acc ->
        {:ok, result} = Repo.query(sql)

        if result.num_rows == 0 do
          {:halt, :done}
        else
          {:cont, :not_done}
        end
      end)

    if result != :done do
      flunk("backfill did not converge to 0 rows within 50 batches")
    end
  end

  defp pre_upgrade_table_pks(storage, table) do
    %{rows: rows} =
      Repo.query!(
        "SELECT table_pk FROM #{StorageSchema.qualify(storage, "audit_changes")} WHERE table_name = $1",
        [table]
      )

    Enum.map(rows, fn [pk] -> pk end)
  end

  defp latest_table_pk(storage, table, op) do
    %{rows: [[pk]]} =
      Repo.query!(
        """
        SELECT table_pk FROM #{StorageSchema.qualify(storage, "audit_changes")}
        WHERE table_name = $1 AND op = $2
        ORDER BY captured_at DESC, id DESC
        LIMIT 1
        """,
        [table, op]
      )

    pk
  end

  defp table_pk_for(storage, table, key_value, op, key_col \\ "doc_key") do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT table_pk, data_after FROM #{StorageSchema.qualify(storage, "audit_changes")}
        WHERE table_name = $1 AND op = $2
        """,
        [table, op]
      )

    [pk] =
      rows
      |> Enum.filter(fn [_pk, data_after] ->
        is_map(data_after) and data_after[key_col] == key_value
      end)
      |> Enum.map(fn [pk, _data_after] -> pk end)

    pk
  end

  # `{id, table_pk}` for every audit_changes row of an id-keyed table, keyed
  # by the real (integer) id read from data_after — sorted comparison is
  # unnecessary because a map comparison ignores key order.
  defp account_table_pks(storage) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT data_after, table_pk FROM #{StorageSchema.qualify(storage, "audit_changes")}
        WHERE table_name = $1
        """,
        [@acct_table]
      )

    Map.new(rows, fn [data_after, pk] -> {data_after["id"], pk} end)
  end

  defp migrated?(file) do
    {version, "_" <> _} = file |> Path.basename() |> Integer.parse()

    %{rows: [[count]]} =
      Repo.query!("SELECT count(*) FROM schema_migrations WHERE version = $1", [version])

    count > 0
  end

  defp drain_shell do
    receive do
      {:mix_shell, :info, [msg]} -> msg
    after
      0 -> nil
    end
  end

  defp row_history_index_valid?(storage) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT i.indisvalid
        FROM pg_index i
        JOIN pg_class c ON c.oid = i.indexrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1 AND c.relname = $2
        """,
        [storage, RowHistoryIndexSQL.index_name()]
      )

    case rows do
      [] -> nil
      [[valid?]] -> valid?
    end
  end

  defp change_for(storage, table, op) do
    %{rows: [[table_pk, data_after]]} =
      Repo.query!(
        """
        SELECT table_pk, data_after FROM #{StorageSchema.qualify(storage, "audit_changes")}
        WHERE table_name = $1 AND op = $2
        """,
        [table, op]
      )

    %{table_pk: table_pk, data_after: data_after}
  end

  defp table_pk_snapshot(storage, table) do
    %{rows: rows} =
      Repo.query!(
        """
        SELECT id, table_pk FROM #{StorageSchema.qualify(storage, "audit_changes")}
        WHERE table_name = $1
        ORDER BY id
        """,
        [table]
      )

    Enum.map(rows, fn [id, pk] -> {id, pk} end)
  end

  defp write_fixture_migration!(tmp, basename, module, creates, drops) do
    migrations = Path.join([tmp, "priv", "repo", "migrations"])
    File.mkdir_p!(migrations)

    File.write!(
      Path.join(migrations, basename),
      LegacyTriggerSQL.migration_source(module, creates, drops)
    )
  end

  defp drop_fixtures!(_storage) do
    for {schema, table} <- @fixture_tables do
      Repo.query!("""
      DO $$ BEGIN
        IF to_regclass('#{ref(schema, table)}') IS NOT NULL THEN
          EXECUTE 'DROP TRIGGER IF EXISTS #{StorageSchema.quote_ident(Naming.trigger_name(%{schema: schema, table: table}))} ON #{ref(schema, table)}';
        END IF;
      END $$
      """)
    end

    for {schema, table} <- @fixture_tables do
      functions = [
        Naming.function_name(%{schema: schema, table: table}),
        Naming.legacy_function_name(%{schema: schema, table: table})
      ]

      for name <- Enum.uniq(functions) do
        Repo.query!("DROP FUNCTION IF EXISTS " <> StorageSchema.function(name) <> "()")
      end
    end

    Repo.query!("DROP FUNCTION IF EXISTS " <> StorageSchema.function(@shared_function) <> "()")

    for {schema, table} <- @fixture_tables do
      Repo.query!("DROP TABLE IF EXISTS #{ref(schema, table)}")
    end

    Repo.query!("DROP SCHEMA IF EXISTS billing")
  end

  defp ref(schema, table),
    do: StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)
end
