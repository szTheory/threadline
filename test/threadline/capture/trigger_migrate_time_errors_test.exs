defmodule Threadline.Capture.TriggerMigrateTimeErrorsTest do
  @moduledoc """
  Proves CAP-03 and CAP-05 on real PostgreSQL: a generated trigger migration
  refuses at migrate time — before any host write — when a table has no
  primary key, when a primary-key column's type has no stable text form, or
  when a detected primary-key column is listed in `mask` or `exclude`. Every
  refusal rolls the whole migration back: no trigger, no per-table function,
  no `schema_migrations` row, and the host write it would have guarded keeps
  working exactly as it did before the migration was attempted.
  """

  use Threadline.DataCase, async: false

  alias Threadline.Capture.{Naming, TriggerSQL}
  alias Threadline.Test.LegacyTriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @public_tables ~w(
    posts_tags
    pk_masked_code
    pk_masked_composite
    pk_quoted_col
    pk_type_tstz
    pk_type_numeric
    pk_type_double
    pk_type_jsonb
    pk_type_intarray
    pk_type_bytea
    pk_type_domain_tstz
    pk_type_smallint
    pk_type_integer
    pk_type_bigint
    pk_type_text
    pk_type_varchar
    pk_type_char
    pk_type_citext
    pk_type_uuid
    pk_type_date
    pk_type_timestamp
    pk_type_enum
    pk_type_domain_int
    parted_events
  )

  setup do
    previous_capture = Application.fetch_env(:threadline, :trigger_capture)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-migrate-time-errors-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    drop_fixtures!()
    Repo.query!("CREATE SCHEMA billing")

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

    Repo.query!("DROP TABLE IF EXISTS billing.pk_less_invoices CASCADE")
    Repo.query!(~s|DROP TABLE IF EXISTS "PkLess" CASCADE|)
    Repo.query!("DROP SCHEMA IF EXISTS billing CASCADE")
    Repo.query!("DROP DOMAIN IF EXISTS pk_tstz_domain")
    Repo.query!("DROP DOMAIN IF EXISTS pk_int_domain")
    Repo.query!("DROP TYPE IF EXISTS pk_status")
  end

  # citext is a shared, database-wide extension: only this helper's own
  # creation of it is torn down, so a suite that already relies on citext
  # elsewhere is left untouched.
  defp with_citext_extension(fun) do
    %{rows: existing} = Repo.query!("SELECT 1 FROM pg_extension WHERE extname = 'citext'")
    created_here = existing == []

    if created_here, do: Repo.query!("CREATE EXTENSION citext")

    try do
      fun.()
    after
      if created_here do
        Repo.query!("DROP TABLE IF EXISTS pk_type_citext CASCADE")
        Repo.query!("DROP EXTENSION IF EXISTS citext")
      end
    end
  end

  describe "a PK-less join table (the flagship posts_tags case)" do
    test "refuses at migrate time with a paste-ready config fix, and nothing is applied", %{
      tmp: tmp
    } do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint NOT NULL,
        tag_id       bigint NOT NULL,
        inserted_at  timestamp
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX posts_tags_post_id_tag_id_index ON posts_tags (post_id, tag_id)"
      )

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ ~r/^threadline:/
      assert error.postgres.message =~ "public.posts_tags"
      assert error.postgres.message =~ "primary_key:"

      assert error.postgres.hint =~ "config/config.exs"

      assert error.postgres.hint =~
               ~s|config :threadline, :trigger_capture, tables: %{"posts_tags" => [primary_key: ["post_id", "tag_id"]]}|

      assert error.postgres.hint =~ "mix threadline.gen.triggers --tables posts_tags"

      assert Harness.threadline_triggers("public", "posts_tags") == []
      refute_schema_migrations_row(file)

      Repo.query!("INSERT INTO posts_tags (post_id, tag_id) VALUES (1, 2)")
      assert capture_rows("public", "posts_tags") == []
    end

    test "in per-table (mask) mode, the per-table function is never installed either", %{
      tmp: tmp
    } do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint NOT NULL,
        tag_id       bigint NOT NULL,
        inserted_at  timestamp
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX posts_tags_post_id_tag_id_index ON posts_tags (post_id, tag_id)"
      )

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"posts_tags" => [mask: ["inserted_at"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      refute Harness.function_exists?(Naming.function_name("posts_tags"))
    end
  end

  describe "a PK-less schema-qualified table" do
    test "the message and HINT name the qualified table", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE billing.pk_less_invoices (
        number text NOT NULL,
        amount bigint NOT NULL
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX pk_less_invoices_number_index ON billing.pk_less_invoices (number)"
      )

      file = Harness.generate!(tmp, ["--tables", "billing.pk_less_invoices"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "billing.pk_less_invoices"
      assert error.postgres.hint =~ ~s|"billing.pk_less_invoices"|

      assert error.postgres.hint =~
               "mix threadline.gen.triggers --tables billing.pk_less_invoices"
    end
  end

  describe "a PK-less mixed-case table" do
    test "the message names the table in its exact case", %{tmp: tmp} do
      Repo.query!(~s|CREATE TABLE "PkLess" (code text NOT NULL)|)
      Repo.query!(~s|CREATE UNIQUE INDEX "PkLess_code_index" ON "PkLess" (code)|)

      file = Harness.generate!(tmp, ["--tables", "PkLess"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "public.PkLess"
    end
  end

  describe "a PK-less table whose qualifying-index column name contains a double quote" do
    # WR-02 (210-REVIEW.md): the paste-ready primary_key: snippet in the
    # HINT is built by manually double-quoting each column name
    # (`chr(34) || attname || chr(34)`). A column name that itself contains
    # a double quote (legal Postgres DDL via `CREATE TABLE t ("weird""col"
    # ...)`) must come back with that embedded quote doubled, so the
    # snippet stays valid Elixir/config syntax instead of producing
    # `"weird"col"`.
    test "the HINT snippet doubles the embedded quote instead of breaking config syntax", %{
      tmp: tmp
    } do
      Repo.query!(
        ~s|CREATE TABLE pk_quoted_col ("weird""col" bigint NOT NULL, tag_id bigint NOT NULL)|
      )

      Repo.query!(
        ~s|CREATE UNIQUE INDEX pk_quoted_col_uniq ON pk_quoted_col ("weird""col", tag_id)|
      )

      file = Harness.generate!(tmp, ["--tables", "pk_quoted_col"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.hint =~ ~s|"weird""col", "tag_id"|
      refute error.postgres.hint =~ ~s|"weird"col"|
    end
  end

  describe "a PK-less table with no qualifying unique index" do
    test "the HINT says to create a unique index over NOT NULL columns first", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint,
        tag_id       bigint
      )
      """)

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.hint =~ "unique index"
      assert error.postgres.hint =~ "NOT NULL"
    end

    test "a partial unique index does not qualify", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint NOT NULL,
        tag_id       bigint NOT NULL,
        active       boolean NOT NULL DEFAULT true
      )
      """)

      Repo.query!(
        "CREATE UNIQUE INDEX posts_tags_partial ON posts_tags (post_id, tag_id) WHERE active"
      )

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.hint =~ "unique index"
      assert error.postgres.hint =~ "NOT NULL"
    end

    test "a nullable-column unique index does not qualify", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint NOT NULL,
        tag_id       bigint
      )
      """)

      Repo.query!("CREATE UNIQUE INDEX posts_tags_nullable ON posts_tags (post_id, tag_id)")

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.hint =~ "unique index"
      assert error.postgres.hint =~ "NOT NULL"
    end

    test "a deferrable unique index does not qualify", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint NOT NULL,
        tag_id       bigint NOT NULL
      )
      """)

      Repo.query!(
        "ALTER TABLE posts_tags ADD CONSTRAINT posts_tags_uniq UNIQUE (post_id, tag_id) DEFERRABLE"
      )

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.hint =~ "unique index"
      assert error.postgres.hint =~ "NOT NULL"
    end

    test "an expression unique index does not qualify", %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE posts_tags (
        post_id      bigint NOT NULL,
        tag_id       bigint NOT NULL
      )
      """)

      Repo.query!("CREATE UNIQUE INDEX posts_tags_expr ON posts_tags (post_id, (tag_id + 0))")

      file = Harness.generate!(tmp, ["--tables", "posts_tags"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.hint =~ "unique index"
      assert error.postgres.hint =~ "NOT NULL"
    end
  end

  describe "a primary key column type outside the allowlist" do
    test "refuses, naming the column and its format_type text", %{tmp: tmp} do
      cases = [
        {"pk_type_tstz", "timestamptz", "timestamp with time zone"},
        {"pk_type_numeric", "numeric", "numeric"},
        {"pk_type_double", "double precision", "double precision"},
        {"pk_type_jsonb", "jsonb", "jsonb"},
        {"pk_type_intarray", "integer[]", "integer[]"},
        {"pk_type_bytea", "bytea", "bytea"}
      ]

      for {table, type_sql, expected_type_text} <- cases do
        Repo.query!("CREATE TABLE #{table} (id #{type_sql} PRIMARY KEY)")

        file = Harness.generate!(tmp, ["--tables", table])
        error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

        assert error.postgres.message =~ "id", "expected column id in message for #{table}"

        assert error.postgres.message =~ expected_type_text,
               "expected #{inspect(expected_type_text)} in message for #{table}: #{error.postgres.message}"
      end
    end

    test "a domain over timestamptz as the key type is refused", %{tmp: tmp} do
      Repo.query!("CREATE DOMAIN pk_tstz_domain AS timestamptz")
      Repo.query!("CREATE TABLE pk_type_domain_tstz (id pk_tstz_domain PRIMARY KEY)")

      file = Harness.generate!(tmp, ["--tables", "pk_type_domain_tstz"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "id"
    end
  end

  describe "a primary key column type inside the allowlist" do
    test "smallint, integer, bigint, text, varchar, char, uuid, date and timestamp are captured",
         %{tmp: tmp} do
      cases = [
        {"pk_type_smallint", "smallint", "42", %{"id" => "42"}},
        {"pk_type_integer", "integer", "42", %{"id" => "42"}},
        {"pk_type_bigint", "bigint", "42", %{"id" => "42"}},
        {"pk_type_text", "text", "'abc'", %{"id" => "abc"}},
        {"pk_type_varchar", "varchar(20)", "'abc'", %{"id" => "abc"}},
        {"pk_type_char", "char(4)", "'abcd'", %{"id" => "abcd"}},
        {"pk_type_uuid", "uuid", "'11111111-1111-1111-1111-111111111111'",
         %{"id" => "11111111-1111-1111-1111-111111111111"}},
        {"pk_type_date", "date", "'2026-01-02'", %{"id" => "2026-01-02"}},
        {"pk_type_timestamp", "timestamp", "'2026-01-02 03:04:05'",
         %{"id" => "2026-01-02T03:04:05"}}
      ]

      for {table, type_sql, insert_value, expected} <- cases do
        Repo.query!("CREATE TABLE #{table} (id #{type_sql} PRIMARY KEY)")

        file = Harness.generate!(tmp, ["--tables", table])
        assert {:ok, _} = Harness.migrate_up(file)

        Repo.query!("INSERT INTO #{table} VALUES (#{insert_value})")

        [row] = capture_rows("public", table)
        assert row.table_pk == expected, "table_pk mismatch for #{table}"
      end
    end

    test "citext is captured", %{tmp: tmp} do
      with_citext_extension(fn ->
        Repo.query!("CREATE TABLE pk_type_citext (id citext PRIMARY KEY)")

        file = Harness.generate!(tmp, ["--tables", "pk_type_citext"])
        assert {:ok, _} = Harness.migrate_up(file)

        Repo.query!("INSERT INTO pk_type_citext VALUES ('AbC')")

        [row] = capture_rows("public", "pk_type_citext")
        assert row.table_pk == %{"id" => "AbC"}
      end)
    end

    test "an enum type is captured", %{tmp: tmp} do
      Repo.query!("CREATE TYPE pk_status AS ENUM ('active', 'archived')")
      Repo.query!("CREATE TABLE pk_type_enum (id pk_status PRIMARY KEY)")

      file = Harness.generate!(tmp, ["--tables", "pk_type_enum"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_type_enum VALUES ('active')")

      [row] = capture_rows("public", "pk_type_enum")
      assert row.table_pk == %{"id" => "active"}
    end

    test "a domain over integer is captured", %{tmp: tmp} do
      Repo.query!("CREATE DOMAIN pk_int_domain AS integer")
      Repo.query!("CREATE TABLE pk_type_domain_int (id pk_int_domain PRIMARY KEY)")

      file = Harness.generate!(tmp, ["--tables", "pk_type_domain_int"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_type_domain_int VALUES (7)")

      [row] = capture_rows("public", "pk_type_domain_int")
      assert row.table_pk == %{"id" => "7"}
    end
  end

  describe "a table with a frozen 0.10.2 no-argument trigger and an unsupported-type key column" do
    test "regenerating raises naming inserted_at; the legacy trigger keeps capturing under id",
         %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE parted_events (
        id          bigint NOT NULL,
        inserted_at timestamptz NOT NULL,
        PRIMARY KEY (id, inserted_at)
      )
      """)

      Repo.query!(TriggerSQL.install_function([]))

      Repo.query!(
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "public",
          "parted_events",
          Threadline.StorageSchema.function("threadline_capture_changes") <> "()"
        )
      )

      original_tgnargs = trigger_tgnargs("public", "parted_events")
      assert original_tgnargs == 0

      file = Harness.generate!(tmp, ["--tables", "parted_events"])

      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)
      assert error.postgres.message =~ "inserted_at"

      assert Harness.threadline_triggers("public", "parted_events") ==
               [{"threadline_audit_parted_events", "O"}]

      assert trigger_tgnargs("public", "parted_events") == 0

      %{rows: [[id]]} =
        Repo.query!("INSERT INTO parted_events (id, inserted_at) VALUES (1, now()) RETURNING id")

      [row] = capture_rows("public", "parted_events")
      assert row.table_pk == %{"id" => Integer.to_string(id)}
    end
  end

  describe "a detected primary key column listed in mask or exclude" do
    test "mask refuses, naming the column", %{tmp: tmp} do
      Repo.query!("CREATE TABLE pk_masked_code (code text PRIMARY KEY, email text)")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_masked_code" => [mask: ["code"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_masked_code"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "code"
      assert error.postgres.message =~ "mask or exclude"
    end

    test "exclude refuses, naming the column", %{tmp: tmp} do
      Repo.query!("CREATE TABLE pk_masked_code (code text PRIMARY KEY, email text)")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_masked_code" => [exclude: ["code"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_masked_code"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "code"
      assert error.postgres.message =~ "mask or exclude"
    end

    test "except_columns overlap is harmless: the table migrates and captures the key", %{
      tmp: tmp
    } do
      Repo.query!("CREATE TABLE pk_masked_code (code text PRIMARY KEY, email text)")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_masked_code" => [except_columns: ["code"], mask: ["email"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_masked_code"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_masked_code (code, email) VALUES ('c1', 'a@example.com')")

      [row] = capture_rows("public", "pk_masked_code")
      assert row.table_pk == %{"code" => "c1"}
    end

    test "comparison is exact and case-sensitive: mask: [\"Code\"] does not match column code", %{
      tmp: tmp
    } do
      Repo.query!("CREATE TABLE pk_masked_code (code text PRIMARY KEY, email text)")

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_masked_code" => [mask: ["Code"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_masked_code"])
      assert {:ok, _} = Harness.migrate_up(file)

      Repo.query!("INSERT INTO pk_masked_code (code, email) VALUES ('c1', 'a@example.com')")

      [row] = capture_rows("public", "pk_masked_code")
      assert row.table_pk == %{"code" => "c1"}
    end

    # WR-01 (210-REVIEW.md): the redaction-overlap refusal claims to name
    # "the first offending column in key order". Prove that ordering with a
    # composite key where BOTH columns are redacted, declared in the
    # opposite order from the key, so a test would catch a regression to
    # unordered `unnest()` naming whichever column the planner happens to
    # visit first.
    test "more than one redacted key column: names the first in key order, not declaration order",
         %{tmp: tmp} do
      Repo.query!("""
      CREATE TABLE pk_masked_composite (
        post_id bigint NOT NULL,
        tag_id  bigint NOT NULL,
        PRIMARY KEY (post_id, tag_id)
      )
      """)

      Application.put_env(:threadline, :trigger_capture,
        tables: %{"pk_masked_composite" => [mask: ["tag_id", "post_id"]]}
      )

      file = Harness.generate!(tmp, ["--tables", "pk_masked_composite"])
      error = assert_raise(Postgrex.Error, fn -> Harness.migrate_up(file) end)

      assert error.postgres.message =~ "post_id"
      refute error.postgres.message =~ "tag_id"
      assert error.postgres.message =~ "mask or exclude"
    end
  end

  describe "the redaction literal in TriggerSQL.create_trigger/3" do
    test "no redacted_columns emits no redaction array" do
      refute TriggerSQL.create_trigger("posts", :per_table) =~ "::text[]"
    end

    test "redacted_columns emits an ARRAY literal in declaration order" do
      sql =
        TriggerSQL.create_trigger("posts", :per_table, redacted_columns: ["notes", "email"])

      assert sql =~ "ARRAY['notes', 'email']::text[]"
    end
  end

  defp trigger_tgnargs(schema, table) do
    %{rows: [[tgnargs]]} =
      Repo.query!(
        """
        SELECT t.tgnargs
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

    tgnargs
  end

  # audit_changes rows captured for the table, if any (there should be none
  # after a refusal, since no function or trigger was installed).
  defp capture_rows(schema, table) do
    import Ecto.Query

    Threadline.Capture.AuditChange
    |> where([c], c.table_schema == ^schema and c.table_name == ^table)
    |> Repo.all(repo_opts())
  end

  defp refute_schema_migrations_row(file) do
    version =
      file
      |> Path.basename()
      |> String.split("_")
      |> hd()
      |> String.to_integer()

    %{rows: rows} =
      Repo.query!("SELECT 1 FROM schema_migrations WHERE version = $1", [version])

    assert rows == []
  end
end
