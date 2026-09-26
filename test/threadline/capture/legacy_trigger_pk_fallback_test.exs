defmodule Threadline.Capture.LegacyTriggerPKFallbackTest do
  @moduledoc """
  Proves CAP-04 on real PostgreSQL: a frozen pre-0.11 trigger statement
  calling the new global capture function keeps its exact output on tables
  with a usable `id` column, and any primary key the new body cannot
  resolve — a missing column, a NULL value, a renamed column, or a partial
  composite key — stores `table_pk = {}` instead of failing the host write.

  Every `table_pk` assertion decodes the stored jsonb and compares with
  `==`, never the jsonb containment operator: containing an empty object is
  true for every row, which would make an unresolved-key assertion pass
  vacuously.
  """

  use Threadline.DataCase, async: false

  alias Threadline.Capture.{AuditChange, TriggerSQL}
  alias Threadline.StorageSchema
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @legacy_function "legacy_capture_v0_10_2"

  @public_tables ~w(
    legacy_id_a
    legacy_id_b
    legacy_code_items
    legacy_nullable_id
    legacy_renamed
    legacy_partial
    legacy_regen
  )

  setup do
    storage = StorageSchema.get()

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-legacy-pk-fallback-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    drop_fixtures!(storage)

    Repo.query!(TriggerSQL.install_function([]))

    Repo.query!(
      LegacyTriggerSQL.v0_10_2_install_function(
        function_literal(storage, @legacy_function),
        storage
      )
    )

    on_exit(fn ->
      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!(storage)
      File.rm_rf!(tmp)
    end)

    %{storage: storage, tmp: tmp}
  end

  describe "a frozen 0.10.2 trigger on an id table, refreshed with the new global function" do
    test "stores the same output as the frozen 0.10.2 function body", %{storage: storage} do
      Repo.query!("""
      CREATE TABLE legacy_id_a (
        id   bigserial PRIMARY KEY,
        name text,
        qty  int
      )
      """)

      Repo.query!("""
      CREATE TABLE legacy_id_b (
        id   bigserial PRIMARY KEY,
        name text,
        qty  int
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_id_a",
          function_ref(storage, @legacy_function)
        )
      )

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_id_b",
          function_ref(storage, "threadline_capture_changes")
        )
      )

      Repo.query!("INSERT INTO legacy_id_a (id, name, qty) VALUES (1, 'a', 1)")
      Repo.query!("INSERT INTO legacy_id_b (id, name, qty) VALUES (1, 'a', 1)")

      Repo.query!("UPDATE legacy_id_a SET qty = 2 WHERE id = 1")
      Repo.query!("UPDATE legacy_id_b SET qty = 2 WHERE id = 1")

      Repo.query!("DELETE FROM legacy_id_a WHERE id = 1")
      Repo.query!("DELETE FROM legacy_id_b WHERE id = 1")

      rows_a = capture_rows("public", "legacy_id_a")
      rows_b = capture_rows("public", "legacy_id_b")

      assert length(rows_a) == 3
      assert length(rows_b) == 3

      for {row_a, row_b} <- Enum.zip(rows_a, rows_b) do
        assert row_a.op == row_b.op
        assert decode(row_a.table_pk) == %{"id" => "1"}
        assert decode(row_a.table_pk) == decode(row_b.table_pk)
        assert decode(row_a.data_after) == decode(row_b.data_after)
        assert row_a.changed_fields == row_b.changed_fields
        assert row_a.changed_from == row_b.changed_from
      end
    end
  end

  describe "a uuid-keyed table with no id column, on a no-argument trigger" do
    test "the new function stores {} on every write; the frozen function stores {id: nil}",
         %{storage: storage} do
      Repo.query!("""
      CREATE TABLE legacy_code_items (
        code uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_code_items",
          function_ref(storage, "threadline_capture_changes")
        )
      )

      %{rows: [[code]]} =
        Repo.query!("INSERT INTO legacy_code_items (name) VALUES ('a') RETURNING code")

      Repo.query!("UPDATE legacy_code_items SET name = 'b' WHERE code = $1", [code])
      Repo.query!("DELETE FROM legacy_code_items WHERE code = $1", [code])

      new_rows = capture_rows("public", "legacy_code_items")
      assert length(new_rows) == 3

      for row <- new_rows do
        assert decode(row.table_pk) == %{}
      end

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_code_items",
          function_ref(storage, @legacy_function)
        )
      )

      Repo.query!("INSERT INTO legacy_code_items (name) VALUES ('c')")

      frozen_row = capture_rows("public", "legacy_code_items") |> List.last()
      assert decode(frozen_row.table_pk) == %{"id" => nil}
    end
  end

  describe "a no-argument trigger on a table with a nullable id column and no primary key" do
    test "a NULL id stores {id: nil} under both the frozen and the new function",
         %{storage: storage} do
      Repo.query!("""
      CREATE TABLE legacy_nullable_id (
        id   bigint,
        name text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_nullable_id",
          function_ref(storage, "threadline_capture_changes")
        )
      )

      Repo.query!("INSERT INTO legacy_nullable_id (id, name) VALUES (NULL, 'new')")

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_nullable_id",
          function_ref(storage, @legacy_function)
        )
      )

      Repo.query!("INSERT INTO legacy_nullable_id (id, name) VALUES (NULL, 'frozen')")

      [new_row, frozen_row] = capture_rows("public", "legacy_nullable_id")
      assert decode(new_row.table_pk) == %{"id" => nil}
      assert decode(frozen_row.table_pk) == %{"id" => nil}
    end
  end

  describe "a composite-argument trigger whose declared column is renamed after install" do
    test "the write succeeds and stores {}" do
      Repo.query!("""
      CREATE TABLE legacy_renamed (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        PRIMARY KEY (post_id, tag_id)
      )
      """)

      Repo.query!(TriggerSQL.create_trigger("legacy_renamed"))
      assert trigger_args("public", "legacy_renamed") == ["post_id", "tag_id"]

      Repo.query!("ALTER TABLE legacy_renamed RENAME COLUMN tag_id TO tag_ref")

      Repo.query!("INSERT INTO legacy_renamed (post_id, tag_ref) VALUES (1, 2)")

      [row] = capture_rows("public", "legacy_renamed")
      assert decode(row.table_pk) == %{}
    end
  end

  describe "a hand-written trigger with two argument columns, one optional" do
    test "a NULL optional column stores {}; both set stores the full two-key map",
         %{storage: storage} do
      Repo.query!("""
      CREATE TABLE legacy_partial (
        code    text PRIMARY KEY,
        opt_col text
      )
      """)

      Repo.query!("""
      CREATE TRIGGER threadline_audit_legacy_partial
      AFTER INSERT OR UPDATE OR DELETE ON legacy_partial
      FOR EACH ROW EXECUTE FUNCTION #{function_literal(storage, "threadline_capture_changes")}('code', 'opt_col')
      """)

      Repo.query!("INSERT INTO legacy_partial (code, opt_col) VALUES ('a', NULL)")
      Repo.query!("UPDATE legacy_partial SET opt_col = 'b' WHERE code = 'a'")

      [insert_row, update_row] = capture_rows("public", "legacy_partial")
      assert decode(insert_row.table_pk) == %{}
      assert decode(update_row.table_pk) == %{"code" => "a", "opt_col" => "b"}
    end
  end

  describe "regenerating a table with a frozen 0.10.2 trigger" do
    test "upgrades to a one-argument trigger and captures the real key",
         %{storage: storage, tmp: tmp} do
      Repo.query!("""
      CREATE TABLE legacy_regen (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "legacy_regen",
          function_ref(storage, "threadline_capture_changes")
        )
      )

      write_fixture_migration!(
        tmp,
        "20230101000000_threadline_triggers_legacy_regen.exs",
        "Threadline.Test.Repo.Migrations.ThreadlineTriggersLegacyRegen",
        [LegacyTriggerSQL.v0_10_2_create_trigger("public", "legacy_regen")],
        ["DROP TRIGGER IF EXISTS threadline_audit_legacy_regen ON legacy_regen"]
      )

      file = Harness.generate!(tmp, ["--tables", "legacy_regen"])
      assert {:ok, _log} = Harness.migrate_up(file)

      assert Harness.threadline_triggers("public", "legacy_regen") ==
               [{"threadline_audit_legacy_regen", "O"}]

      assert tgnargs("public", "legacy_regen") == 1
      assert trigger_args("public", "legacy_regen") == ["id"]

      %{rows: [[id]]} = Repo.query!("INSERT INTO legacy_regen (name) VALUES ('a') RETURNING id")

      [row] = capture_rows("public", "legacy_regen")
      assert decode(row.table_pk) == %{"id" => Integer.to_string(id)}
    end
  end

  describe "the bench fixture copy of the frozen 0.10.2 function body" do
    test "equals LegacyTriggerSQL.v0_10_2_install_function/2 rendered for the bench function name" do
      fixture =
        "bench/fixtures/threadline_capture_changes_v0_10_2.sql"
        |> Path.expand(Path.join(__DIR__, "../../.."))
        |> File.read!()
        |> drop_leading_comment_lines()

      rendered =
        LegacyTriggerSQL.v0_10_2_install_function(
          ~s|"threadline"."bench_capture_v0_10_2"|,
          "threadline"
        )

      assert fixture == rendered
    end
  end

  # ---- helpers -----------------------------------------------------------

  # Strips every leading `-- ...` comment line (and the blank lines between
  # them, if any) so the remaining text is exactly what
  # `LegacyTriggerSQL.v0_10_2_install_function/2` renders.
  defp drop_leading_comment_lines(text) do
    text
    |> String.split("\n")
    |> Enum.drop_while(&String.starts_with?(&1, "--"))
    |> Enum.join("\n")
  end

  # The fully quoted, schema-qualified function target with no parens, as
  # `LegacyTriggerSQL.v0_10_2_install_function/2` expects.
  defp function_literal(storage, name), do: ~s|"#{storage}"."#{name}"|

  # The same, with a trailing `()`, as `LegacyTriggerSQL.v0_10_2_create_trigger/3`
  # expects for its `function_ref`.
  defp function_ref(storage, name), do: function_literal(storage, name) <> "()"

  # Every audit_changes row for the table, oldest first.
  defp capture_rows(schema, table) do
    AuditChange
    |> where([c], c.table_schema == ^schema and c.table_name == ^table)
    |> order_by([c], asc: c.captured_at)
    |> Repo.all(repo_opts())
  end

  defp decode(nil), do: nil
  defp decode(value) when is_map(value), do: value
  defp decode(value) when is_binary(value), do: Jason.decode!(value)

  # The decoded trigger-argument list from pg_trigger.tgargs: a bytea of
  # NUL-separated argument strings with a trailing empty element.
  defp trigger_args(schema, table) do
    %{rows: [[tgargs]]} =
      Repo.query!(
        """
        SELECT t.tgargs
        FROM pg_trigger t
        WHERE t.tgrelid = $1::text::regclass
          AND NOT t.tgisinternal
          AND t.tgname LIKE 'threadline_audit_%'
        """,
        [StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)]
      )

    tgargs
    |> String.split(<<0>>)
    |> Enum.reject(&(&1 == ""))
  end

  defp tgnargs(schema, table) do
    %{rows: [[nargs]]} =
      Repo.query!(
        """
        SELECT t.tgnargs
        FROM pg_trigger t
        WHERE t.tgrelid = $1::text::regclass
          AND NOT t.tgisinternal
          AND t.tgname LIKE 'threadline_audit_%'
        """,
        [StorageSchema.quote_ident(schema) <> "." <> StorageSchema.quote_ident(table)]
      )

    nargs
  end

  defp write_fixture_migration!(tmp, basename, module, creates, drops) do
    migrations = Path.join([tmp, "priv", "repo", "migrations"])
    File.mkdir_p!(migrations)

    File.write!(
      Path.join(migrations, basename),
      LegacyTriggerSQL.migration_source(module, creates, drops)
    )
  end

  defp drop_fixtures!(storage) do
    for table <- @public_tables do
      Repo.query!("DROP TABLE IF EXISTS #{table} CASCADE")
    end

    Repo.query!(~s|DROP FUNCTION IF EXISTS "#{storage}"."#{@legacy_function}"() CASCADE|)
  end
end
