defmodule Threadline.Capture.TriggerPKOverrideTest do
  @moduledoc """
  Proves the CONF-01 capture half: a declared `primary_key:` override for a
  table with no primary key is loaded, carried into the generated `DO`
  block as a literal array, enforced at migrate time against a qualifying
  unique index, and captured with the declared columns through the
  adopter's own migration path (`mix threadline.gen.triggers` +
  `Ecto.Migrator.up/4`), on real PostgreSQL.
  """

  use Threadline.DataCase, async: false

  alias Threadline.Capture.{TriggerCaptureConfig, TriggerSQL}
  alias Threadline.Test.MigrationHarness, as: Harness

  @public_tables ~w(
    posts_tags
    pk_reordered
    pk_override_has_pk
    pk_override_missing_col
    pk_override_no_index
    pk_override_subset
    pk_override_superset
    pk_override_partial
    pk_override_deferrable
    pk_override_expr
    pk_override_nullable
    pk_override_include
    pk_override_tstz
  )

  setup do
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-pk-override-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    drop_fixtures!()

    on_exit(fn ->
      case previous_capture do
        {:ok, value} -> Application.put_env(:threadline, :trigger_capture, value)
        :error -> Application.delete_env(:threadline, :trigger_capture)
      end

      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!()
    end)

    %{tmp: tmp}
  end

  defp drop_fixtures! do
    for table <- @public_tables do
      Repo.query!("DROP TABLE IF EXISTS #{table} CASCADE")
    end
  end

  describe "TriggerCaptureConfig.load/1" do
    test "exposes the override as a string list in declared order, atoms included" do
      loaded =
        TriggerCaptureConfig.load(tables: %{"posts_tags" => [primary_key: [:post_id, "tag_id"]]})

      assert Keyword.get(loaded["posts_tags"], :primary_key) == ["post_id", "tag_id"]
    end
  end

  describe "the generated DO block" do
    test "contains a literal declared array" do
      sql = TriggerSQL.create_trigger("posts_tags", :default, primary_key: ["post_id", "tag_id"])
      assert sql =~ "ARRAY['post_id', 'tag_id']::text[]"
    end
  end

  describe "a posts_tags join table with a declared override, config key \"posts_tags\"" do
    test "installs with declared trigger arguments and captures the declared key", %{tmp: tmp} do
      create_posts_tags!()

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"posts_tags" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "posts_tags") == ["post_id", "tag_id"]

      Repo.query!("INSERT INTO posts_tags (post_id, tag_id) VALUES (1, 2)")
      Repo.query!("UPDATE posts_tags SET post_id = 1 WHERE post_id = 1 AND tag_id = 2")
      Repo.query!("DELETE FROM posts_tags WHERE post_id = 1 AND tag_id = 2")

      [insert_row, update_row, delete_row] = capture_rows("public", "posts_tags")
      expected = %{"post_id" => "1", "tag_id" => "2"}
      assert insert_row.table_pk == expected
      assert update_row.table_pk == expected
      assert delete_row.table_pk == expected
    end
  end

  describe "a posts_tags join table with a declared override, config key \"public.posts_tags\"" do
    test "behaves identically", %{tmp: tmp} do
      create_posts_tags!()

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"public.posts_tags" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "posts_tags") == ["post_id", "tag_id"]

      Repo.query!("INSERT INTO posts_tags (post_id, tag_id) VALUES (1, 2)")

      [row] = capture_rows("public", "posts_tags")
      assert row.table_pk == %{"post_id" => "1", "tag_id" => "2"}
    end
  end

  describe "declared order becomes trigger-argument order" do
    test ~s|primary_key: ["tag_id", "post_id"] against a (post_id, tag_id) index installs tag_id, post_id|,
         %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_reordered (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL
      )
      """)

      Repo.query!("CREATE UNIQUE INDEX pk_reordered_uniq ON pk_reordered (post_id, tag_id)")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_reordered" => [primary_key: ["tag_id", "post_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_reordered"])
      assert {:ok, _} = Harness.migrate_up(file)

      assert trigger_args("public", "pk_reordered") == ["tag_id", "post_id"]

      Repo.query!("INSERT INTO pk_reordered (post_id, tag_id) VALUES (1, 2)")

      [row] = capture_rows("public", "pk_reordered")
      assert row.table_pk == %{"post_id" => "1", "tag_id" => "2"}
    end
  end

  describe "an override on a table that already has a primary key" do
    test "refuses, naming the discovered columns, even when the override equals them", %{
      tmp: tmp
    } do
      Repo.query!("""
      CREATE TABLE pk_override_has_pk (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        PRIMARY KEY (post_id, tag_id)
      )
      """)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_has_pk" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_has_pk"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "pk_override_has_pk"
      assert error.postgres.message =~ "already has a primary key"
      assert error.postgres.hint =~ "Remove primary_key:"
      assert error.postgres.hint =~ "post_id"
      assert error.postgres.hint =~ "tag_id"
      assert Harness.threadline_triggers("public", "pk_override_has_pk") == []
    end
  end

  describe "a declared column that does not exist" do
    test "refuses naming the missing column, including a column dropped after the table was created",
         %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_missing_col (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL
      )
      """)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_missing_col" => [primary_key: ["post_id", "tag_ref"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_missing_col"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.message =~ "tag_ref"

      Repo.query!("ALTER TABLE pk_override_missing_col ADD COLUMN dropped_col bigint")
      Repo.query!("ALTER TABLE pk_override_missing_col DROP COLUMN dropped_col")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_missing_col" => [primary_key: ["post_id", "dropped_col"]]}
      )

      file2 = Harness.generate!(tmp, ["--tables", "pk_override_missing_col"])
      error2 = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file2) end)
      assert error2.postgres.message =~ "dropped_col"
    end
  end

  describe "no unique index at all" do
    test "refuses; DETAIL says no unique index exists", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_no_index (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL
      )
      """)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_no_index" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_no_index"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.detail =~ "no unique index exists"
    end
  end

  describe "a unique index whose key set is a subset or superset of the declared columns" do
    test "refuses; DETAIL names each index with column-set mismatch", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_subset (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL
      )
      """)

      Repo.query!("CREATE UNIQUE INDEX pk_override_subset_uniq ON pk_override_subset (post_id)")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_subset" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_subset"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.detail =~ "column-set mismatch"

      Repo.query!("""
      CREATE TABLE pk_override_superset (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        extra   bigint NOT NULL
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_override_superset_uniq ON pk_override_superset (post_id, tag_id, extra)"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_superset" => [primary_key: ["post_id", "tag_id"]]}
      )

      file2 = Harness.generate!(tmp, ["--tables", "pk_override_superset"])
      error2 = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file2) end)
      assert error2.postgres.detail =~ "column-set mismatch"
    end
  end

  describe "a partial, deferrable, expression or nullable-column index never qualifies" do
    test "partial index refuses, DETAIL says partial", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_partial (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        active  boolean NOT NULL DEFAULT true
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_override_partial_uniq ON pk_override_partial (post_id, tag_id) WHERE active"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_partial" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_partial"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.detail =~ "partial"
    end

    test "DEFERRABLE unique constraint refuses, DETAIL says deferrable", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_deferrable (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL
      )
      """)

      Repo.query!(
        "ALTER TABLE pk_override_deferrable ADD CONSTRAINT pk_override_deferrable_uniq UNIQUE (post_id, tag_id) DEFERRABLE"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_deferrable" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_deferrable"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.detail =~ "deferrable"
    end

    test "expression index refuses, DETAIL says expression", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_expr (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_override_expr_uniq ON pk_override_expr (post_id, (tag_id + 0))"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_expr" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_expr"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.detail =~ "expression"
    end

    test "a nullable indexed column refuses, DETAIL says nullable column", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_nullable (
        post_id bigint NOT NULL,
        tag_id  bigint
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_override_nullable_uniq ON pk_override_nullable (post_id, tag_id)"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_nullable" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_nullable"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.detail =~ "nullable column"
    end
  end

  describe "a qualifying unique index with an INCLUDE column" do
    test "is accepted; captures only the declared columns", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_include (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        note    text
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_override_include_uniq ON pk_override_include (post_id, tag_id) INCLUDE (note)"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_include" => [primary_key: ["post_id", "tag_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_include"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_override_include (post_id, tag_id, note) VALUES (1, 2, 'n')")

      [row] = capture_rows("public", "pk_override_include")
      assert row.table_pk == %{"post_id" => "1", "tag_id" => "2"}
    end
  end

  describe "override columns go through the same type allowlist as detected keys" do
    test "a declared timestamptz column refuses naming the column and its type", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_override_tstz (
        post_id     bigint NOT NULL,
        inserted_at timestamptz NOT NULL
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_override_tstz_uniq ON pk_override_tstz (post_id, inserted_at)"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_override_tstz" => [primary_key: ["post_id", "inserted_at"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_override_tstz"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "inserted_at"
      assert error.postgres.message =~ "timestamp with time zone"
    end
  end

  defp create_posts_tags! do
    Repo.query!("""
    CREATE TABLE posts_tags (
      post_id bigint NOT NULL,
      tag_id  bigint NOT NULL
    )
    """)

    Repo.query!(
      "CREATE UNIQUE INDEX posts_tags_post_id_tag_id_index ON posts_tags (post_id, tag_id)"
    )
  end

  # Every audit_changes row for the table, oldest first.
  defp capture_rows(schema, table) do
    import Ecto.Query

    Threadline.Capture.AuditChange
    |> where([c], c.table_schema == ^schema and c.table_name == ^table)
    |> order_by([c], asc: c.captured_at)
    |> Repo.all(repo_opts())
  end

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
        [
          Threadline.StorageSchema.quote_ident(schema) <>
            "." <> Threadline.StorageSchema.quote_ident(table)
        ]
      )

    tgargs
    |> String.split(<<0>>)
    |> Enum.reject(&(&1 == ""))
  end
end
