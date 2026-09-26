defmodule Threadline.Query.RowKeyTypesTest do
  @moduledoc """
  Proves every allowlisted key type round-trips capture -> `Threadline.history/3`:
  bigint, uuid, text, date, a fractional-second timestamp, char(n) padding, a
  PostgreSQL enum (given as an atom and as a string), and a domain over
  integer. Each case is also proven inside a transaction with
  `SET LOCAL DateStyle = 'SQL, DMY'`, since only `to_jsonb(...) #>> '{}'`
  (never a `::text` cast) is documented to ignore `DateStyle`.
  """

  use Threadline.DataCase

  alias Threadline.Capture.TriggerSQL
  alias Threadline.Test.MigrationHarness, as: Harness

  @tables ~w(rk_t_bigint rk_t_uuid rk_t_text rk_t_date rk_t_ts rk_t_char rk_t_enum rk_t_domain
             rk_t_enum_quoted)

  setup do
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(
        System.tmp_dir!(),
        "threadline-row-key-types-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(tmp)

    Repo.query!(TriggerSQL.install_function([]))
    drop_fixtures!()
    create_fixtures!()

    file = Harness.generate!(tmp, ["--tables", Enum.join(@tables, ",")])
    assert {:ok, _} = Harness.migrate_up(file)

    on_exit(fn ->
      Mix.shell(previous_shell)
      Harness.cleanup!(Harness.migration_files(tmp))
      drop_fixtures!()
      File.rm_rf!(tmp)
    end)

    :ok
  end

  defp drop_fixtures! do
    for table <- @tables do
      Repo.query!("DROP TABLE IF EXISTS #{table} CASCADE")
    end

    Repo.query!("DROP TYPE IF EXISTS rk_t_status CASCADE")
    Repo.query!("DROP DOMAIN IF EXISTS rk_t_pos_int CASCADE")
    Repo.query!("DROP TYPE IF EXISTS \"rk t weird status\" CASCADE")
  end

  defp create_fixtures! do
    Repo.query!("CREATE TYPE rk_t_status AS ENUM ('active', 'archived')")
    Repo.query!("CREATE DOMAIN rk_t_pos_int AS integer")

    # A type name requiring double-quoting (contains spaces), so
    # `format_type/2` returns a quoted identifier — proves
    # `validate_type_text!/1`'s allowlist (WR-01) still accepts the shape
    # PostgreSQL itself produces for an otherwise-unremarkable enum.
    Repo.query!("CREATE TYPE \"rk t weird status\" AS ENUM ('active', 'archived')")

    Repo.query!("CREATE TABLE rk_t_bigint (id bigint PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_uuid (id uuid PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_text (id text PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_date (id date PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_ts (id timestamp PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_char (id char(8) PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_enum (id rk_t_status PRIMARY KEY, name text)")
    Repo.query!("CREATE TABLE rk_t_domain (id rk_t_pos_int PRIMARY KEY, name text)")

    Repo.query!("CREATE TABLE rk_t_enum_quoted (id \"rk t weird status\" PRIMARY KEY, name text)")
  end

  defmodule RkTBigint do
    use Ecto.Schema

    schema "rk_t_bigint" do
      field(:name, :string)
    end
  end

  defmodule RkTUuid do
    use Ecto.Schema

    @primary_key {:id, :binary_id, autogenerate: false}
    schema "rk_t_uuid" do
      field(:name, :string)
    end
  end

  defmodule RkTText do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "rk_t_text" do
      field(:name, :string)
    end
  end

  defmodule RkTDate do
    use Ecto.Schema

    @primary_key {:id, :date, autogenerate: false}
    schema "rk_t_date" do
      field(:name, :string)
    end
  end

  defmodule RkTTimestamp do
    use Ecto.Schema

    @primary_key {:id, :naive_datetime_usec, autogenerate: false}
    schema "rk_t_ts" do
      field(:name, :string)
    end
  end

  defmodule RkTChar do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "rk_t_char" do
      field(:name, :string)
    end
  end

  defmodule RkTEnum do
    use Ecto.Schema

    @primary_key false
    schema "rk_t_enum" do
      field(:id, Ecto.Enum, values: [:active, :archived], primary_key: true)
      field(:name, :string)
    end
  end

  defmodule RkTDomain do
    use Ecto.Schema

    @primary_key {:id, :integer, autogenerate: false}
    schema "rk_t_domain" do
      field(:name, :string)
    end
  end

  defmodule RkTEnumQuoted do
    use Ecto.Schema

    @primary_key false
    schema "rk_t_enum_quoted" do
      field(:id, Ecto.Enum, values: [:active, :archived], primary_key: true)
      field(:name, :string)
    end
  end

  # Runs `assertion.()` twice: once plainly, and once inside a transaction
  # after `SET LOCAL DateStyle = 'SQL, DMY'`, proving the render step ignores
  # DateStyle either way.
  defp assert_round_trip(assertion) do
    assertion.()

    Repo.transaction(fn ->
      Repo.query!("SET LOCAL DateStyle = 'SQL, DMY'")
      assertion.()
    end)
  end

  test "bigint key queried as a numeric string returns the row" do
    Repo.query!("INSERT INTO rk_t_bigint (id, name) VALUES (42, 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTBigint, "42", repo: Repo)) == 1
    end)
  end

  test "uuid key queried with the canonical string returns the row" do
    uuid = Ecto.UUID.generate()
    Repo.query!("INSERT INTO rk_t_uuid (id, name) VALUES ($1, 'a')", [Ecto.UUID.dump!(uuid)])

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTUuid, uuid, repo: Repo)) == 1
    end)
  end

  test "text key compares exactly: 'Abc' is not found by 'abc'" do
    Repo.query!("INSERT INTO rk_t_text (id, name) VALUES ('Abc', 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTText, "Abc", repo: Repo)) == 1
      assert Threadline.history(RkTText, "abc", repo: Repo) == []
    end)
  end

  test "date key found by a Date struct" do
    Repo.query!("INSERT INTO rk_t_date (id, name) VALUES ('2026-09-25', 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTDate, ~D[2026-09-25], repo: Repo)) == 1
    end)
  end

  test "a .5-fractional-second timestamp key found by a matching NaiveDateTime" do
    Repo.query!("INSERT INTO rk_t_ts (id, name) VALUES ('2026-09-25 12:00:00.5', 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTTimestamp, ~N[2026-09-25 12:00:00.500000], repo: Repo)) ==
               1
    end)
  end

  test "char(8) key holding 'ab' found by the unpadded string" do
    Repo.query!("INSERT INTO rk_t_char (id, name) VALUES ('ab', 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTChar, "ab", repo: Repo)) == 1
    end)
  end

  test "a PostgreSQL enum key found by an atom and by a string" do
    Repo.query!("INSERT INTO rk_t_enum (id, name) VALUES ('active', 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTEnum, :active, repo: Repo)) == 1
      assert length(Threadline.history(RkTEnum, "active", repo: Repo)) == 1
    end)
  end

  test "a domain-over-integer key found by a plain integer" do
    Repo.query!("INSERT INTO rk_t_domain (id, name) VALUES (7, 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTDomain, 7, repo: Repo)) == 1
    end)
  end

  test "an enum type name requiring quoting still renders (WR-01)" do
    Repo.query!("INSERT INTO rk_t_enum_quoted (id, name) VALUES ('active', 'a')")

    assert_round_trip(fn ->
      assert length(Threadline.history(RkTEnumQuoted, :active, repo: Repo)) == 1
      assert length(Threadline.history(RkTEnumQuoted, "active", repo: Repo)) == 1
    end)
  end
end
