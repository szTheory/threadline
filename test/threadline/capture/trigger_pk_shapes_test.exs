defmodule Threadline.Capture.TriggerPKShapesTest do
  @moduledoc """
  Proves that generated triggers capture a table's real primary key —
  whatever its name, type, or column count — through the adopter's own
  migration path (`mix threadline.gen.triggers` + `Ecto.Migrator.up/4`), on
  real PostgreSQL.

  Every `table_pk` assertion decodes the stored jsonb and compares with
  `==`, never the jsonb containment operator: containing an empty object is
  true for every row, which would make an unresolved-key assertion pass
  vacuously.
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, TriggerSQL}
  alias Threadline.Mix.TriggerMigration
  alias Threadline.StorageSchema
  alias Threadline.Test.MigrationHarness, as: Harness

  @public_tables ~w(
    pk_uuid_items
    pk_uuid_rerun
    pk_bigint_items
    pk_text_items
    pk_mixed_case
    posts_tags_pk
    posts_tags_incl
    pk_reordered
    pk_default_ids
    pk_masked_items
    pk_parted
  )

  setup do
    previous_shell = Mix.shell()
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-pk-shapes-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    Repo.query!(TriggerSQL.install_function([]))
    drop_fixtures!()
    Repo.query!("CREATE SCHEMA pkshape")

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_capture do
        {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
        :error -> Application.delete_env(:threadline, :trigger_capture)
      end

      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!()
      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end

  defp drop_fixtures! do
    for table <- @public_tables do
      Repo.query!("DROP TABLE IF EXISTS #{table} CASCADE")
    end

    Repo.query!("DROP SCHEMA IF EXISTS pkshape CASCADE")
  end

  describe "a uuid code-keyed table, captured end to end through the generator" do
    test "table_pk stores the real code, not id", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_uuid_items (
        code uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "pk_uuid_items"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "pk_uuid_items") == ["code"]

      migration_source = File.read!(file)
      assert migration_source =~ "CREATE OR REPLACE FUNCTION"
      function_index = :binary.match(migration_source, "CREATE OR REPLACE FUNCTION") |> elem(0)
      trigger_index = :binary.match(migration_source, "CREATE OR REPLACE TRIGGER") |> elem(0)
      assert function_index < trigger_index

      %{rows: [[code]]} =
        Repo.query!("INSERT INTO pk_uuid_items (name) VALUES ('a') RETURNING code")

      code_text = code_to_text(code)

      Repo.query!("UPDATE pk_uuid_items SET name = 'b' WHERE code = $1", [code])
      Repo.query!("DELETE FROM pk_uuid_items WHERE code = $1", [code])

      [insert_row, update_row, delete_row] = capture_rows("public", "pk_uuid_items")

      assert insert_row.op == "insert"
      assert update_row.op == "update"
      assert delete_row.op == "delete"

      for row <- [insert_row, update_row, delete_row] do
        assert decode(row.table_pk) == %{"code" => code_text}
      end
    end
  end

  describe "TriggerMigration.rerun?/2 detects the DO-block trigger form" do
    test "a regenerated uuid-keyed table is a rerun of itself", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_uuid_rerun (
        code uuid PRIMARY KEY DEFAULT gen_random_uuid()
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "pk_uuid_rerun"])
      source = File.read!(file)

      assert TriggerMigration.rerun?(
               %{schema: "public", table: "pk_uuid_rerun"},
               [source]
             )
    end
  end

  describe "a bigint key that exceeds the JavaScript-safe integer range" do
    test "the exact PostgreSQL text output is stored, not a rounded float", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_bigint_items (
        account_number bigint PRIMARY KEY,
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "pk_bigint_items"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_bigint_items VALUES (9007199254740993, 'a')")
      Repo.query!("UPDATE pk_bigint_items SET name = 'b' WHERE account_number = 9007199254740993")
      Repo.query!("DELETE FROM pk_bigint_items WHERE account_number = 9007199254740993")

      for row <- capture_rows("public", "pk_bigint_items") do
        assert decode(row.table_pk) == %{"account_number" => "9007199254740993"}
      end
    end

    test "installing via TriggerSQL.create_trigger/1 directly also resolves the key" do
      Repo.query!("""
      CREATE TABLE pk_bigint_items (
        account_number bigint PRIMARY KEY,
        name text
      )
      """)

      Repo.query!(TriggerSQL.install_function([]))
      Repo.query!(TriggerSQL.create_trigger("pk_bigint_items"))

      assert trigger_args("public", "pk_bigint_items") == ["account_number"]

      Repo.query!("INSERT INTO pk_bigint_items VALUES (42, 'a')")
      [row] = capture_rows("public", "pk_bigint_items")
      assert decode(row.table_pk) == %{"account_number" => "42"}
    end
  end

  describe "a text key with a quote and non-ASCII byte" do
    test "the value is stored byte-for-byte", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_text_items (
        slug text PRIMARY KEY
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "pk_text_items"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_text_items VALUES ($1)", ["O'Brien ü"])

      [row] = capture_rows("public", "pk_text_items")
      assert decode(row.table_pk) == %{"slug" => "O'Brien ü"}
    end
  end

  describe "a mixed-case quoted column name" do
    test "the key is stored under its exact-case name", %{tmp: tmp} do
      Repo.query!(~s|CREATE TABLE pk_mixed_case ("AccountId" int PRIMARY KEY)|)

      file = Harness.generate!(tmp, ["--tables", "pk_mixed_case"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "pk_mixed_case") == ["AccountId"]

      Repo.query!(~s|INSERT INTO pk_mixed_case ("AccountId") VALUES (7)|)

      [row] = capture_rows("public", "pk_mixed_case")
      assert decode(row.table_pk) == %{"AccountId" => "7"}
    end
  end

  describe "a composite primary key" do
    test "both columns are stored, with adjacency and ordering told apart", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags_pk (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        PRIMARY KEY (post_id, tag_id)
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "posts_tags_pk"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "posts_tags_pk") == ["post_id", "tag_id"]

      Repo.query!("INSERT INTO posts_tags_pk VALUES (1, 2), (1, 23), (12, 3), (1, 3)")

      rows = capture_rows("public", "posts_tags_pk")
      keys = Enum.map(rows, &decode(&1.table_pk))

      assert %{"post_id" => "1", "tag_id" => "2"} in keys
      assert %{"post_id" => "1", "tag_id" => "23"} in keys
      assert %{"post_id" => "12", "tag_id" => "3"} in keys
      assert %{"post_id" => "1", "tag_id" => "3"} in keys

      # Adjacency: (1, 23) and (12, 3) are distinct despite sharing digits.
      assert Enum.at(keys, 1) != Enum.at(keys, 2)
      # (1, 2) and (1, 3) are distinct.
      assert Enum.at(keys, 0) != Enum.at(keys, 3)
    end
  end

  describe "a composite primary key with an INCLUDE column" do
    test "only the key columns are stored and become trigger arguments", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags_incl (
        post_id    bigint NOT NULL,
        tag_id     bigint NOT NULL,
        sort_order int NOT NULL DEFAULT 0,
        PRIMARY KEY (post_id, tag_id) INCLUDE (sort_order)
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "posts_tags_incl"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "posts_tags_incl") == ["post_id", "tag_id"]

      Repo.query!("INSERT INTO posts_tags_incl (post_id, tag_id) VALUES (1, 2)")

      [row] = capture_rows("public", "posts_tags_incl")
      assert decode(row.table_pk) == %{"post_id" => "1", "tag_id" => "2"}
    end
  end

  describe "a primary key declared in non-storage order" do
    test "trigger arguments follow declaration order, table_pk equality ignores it", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_reordered (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        PRIMARY KEY (tag_id, post_id)
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "pk_reordered"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "pk_reordered") == ["tag_id", "post_id"]

      Repo.query!("INSERT INTO pk_reordered VALUES (1, 2)")

      [row] = capture_rows("public", "pk_reordered")
      assert decode(row.table_pk) == %{"post_id" => "1", "tag_id" => "2"}
    end
  end

  describe "a default Ecto bigserial id table regenerated by this release" do
    test "output is unchanged from 0.10.x", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_default_ids (
        id   bigserial PRIMARY KEY,
        name text
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "pk_default_ids"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "pk_default_ids") == ["id"]

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO pk_default_ids (name) VALUES ('a') RETURNING id")

      [row] = capture_rows("public", "pk_default_ids")
      assert decode(row.table_pk) == %{"id" => Integer.to_string(id)}
    end
  end

  describe "per-table redaction mode with a non-id key" do
    test "table_pk is still resolved alongside the mask", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_masked_items (
        code  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        email text
      )
      """)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_masked_items" => [mask: ["email"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_masked_items"])
      assert {:ok, _} = Harness.migrate_up(file)

      %{rows: [[code]]} =
        Repo.query!("INSERT INTO pk_masked_items (email) VALUES ('a@example.com') RETURNING code")

      code_text = code_to_text(code)

      [row] = capture_rows("public", "pk_masked_items")
      assert decode(row.table_pk) == %{"code" => code_text}
      assert decode(row.data_after)["email"] == "[REDACTED]"
    end
  end

  describe "a schema-qualified table" do
    test "table_pk resolves and table_schema is the real schema", %{tmp: tmp} do
      Repo.query!(~s|CREATE TABLE pkshape.items (sku text PRIMARY KEY)|)

      file = Harness.generate!(tmp, ["--tables", "pkshape.items"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("pkshape", "items") == ["sku"]

      Repo.query!(~s|INSERT INTO pkshape.items VALUES ('widget-1')|)

      [row] = capture_rows("pkshape", "items")
      assert row.table_schema == "pkshape"
      assert decode(row.table_pk) == %{"sku" => "widget-1"}
    end
  end

  describe "a partitioned table" do
    test "an insert through the parent resolves the key on the partition's cloned trigger",
         %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_parted (
        id     bigint NOT NULL,
        region text NOT NULL,
        PRIMARY KEY (id, region)
      ) PARTITION BY LIST (region)
      """)

      Repo.query!("CREATE TABLE pk_parted_default PARTITION OF pk_parted DEFAULT")

      file = Harness.generate!(tmp, ["--tables", "pk_parted"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "pk_parted") == ["id", "region"]

      Repo.query!("INSERT INTO pk_parted VALUES (1, 'us')")

      [row] = capture_rows("public", "pk_parted_default")
      assert row.table_name == "pk_parted_default"
      assert decode(row.table_pk) == %{"id" => "1", "region" => "us"}

      assert cloned_trigger_args("pk_parted_default") == ["id", "region"]
    end
  end

  # Every audit_changes row for the table, oldest first.
  defp capture_rows(schema, table) do
    import Ecto.Query

    AuditChange
    |> where([c], c.table_schema == ^schema and c.table_name == ^table)
    |> order_by([c], asc: c.captured_at)
    |> Repo.all(repo_opts())
  end

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

  # PostgreSQL clones a row trigger onto each partition; the clone is
  # internal, so it is read directly rather than through trigger_args/2's
  # `NOT t.tgisinternal` filter.
  defp cloned_trigger_args(partition) do
    %{rows: [[tgargs]]} =
      Repo.query!(
        """
        SELECT t.tgargs
        FROM pg_trigger t
        WHERE t.tgrelid = $1::text::regclass AND t.tgparentid <> 0
        """,
        [StorageSchema.quote_ident(partition)]
      )

    tgargs
    |> String.split(<<0>>)
    |> Enum.reject(&(&1 == ""))
  end

  defp code_to_text(<<_::128>> = uuid), do: Ecto.UUID.cast!(uuid)
  defp code_to_text(code) when is_binary(code), do: code

  defp decode(value) when is_map(value), do: value
  defp decode(value) when is_binary(value), do: Jason.decode!(value)
end
