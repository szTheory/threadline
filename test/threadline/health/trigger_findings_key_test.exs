defmodule Threadline.Health.TriggerFindingsKeyTest do
  @moduledoc """
  Real-PG fixtures for `:legacy_trigger_no_pk_args` and `:pk_drift`, each with
  a clean negative control (HLTH-02, HLTH-03).
  """

  use Threadline.DataCase

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.TriggerSQL
  alias Threadline.Health
  alias Threadline.Health.Finding
  alias Threadline.Test.LegacyTriggerSQL

  @repo Threadline.Test.Repo
  @schema "hlth_key"

  setup do
    SQL.query!(@repo, "DROP SCHEMA IF EXISTS #{@schema} CASCADE", [])
    SQL.query!(@repo, "CREATE SCHEMA #{@schema}", [])

    on_exit(fn ->
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS #{@schema} CASCADE", [])
    end)

    :ok
  end

  describe "legacy_trigger_no_pk_args — id table" do
    setup do
      SQL.query!(@repo, "CREATE TABLE #{@schema}.legacy_id (id bigserial PRIMARY KEY)", [])
      :ok
    end

    test "a 0.10.2 no-argument trigger yields exactly one warning naming the fix" do
      SQL.query!(
        @repo,
        LegacyTriggerSQL.v0_10_2_create_trigger(
          @schema,
          "legacy_id",
          ~s|"threadline"."threadline_capture_changes"()|
        ),
        []
      )

      assert [%Finding{} = finding] = Health.trigger_findings(repo: @repo, schema: @schema)

      assert finding.code == :legacy_trigger_no_pk_args
      assert finding.severity == :warning
      assert finding.schema == @schema
      assert finding.table == "legacy_id"
      assert finding.message =~ "hlth_key.legacy_id"
      assert finding.message =~ "mix threadline.gen.triggers --tables hlth_key.legacy_id"
      assert finding.message =~ "mix ecto.migrate"

      assert finding.details == %{
               trigger: "threadline_audit_hlth_key_legacy_id",
               recorded_key: ["id"],
               expected_key: ["id"]
             }
    end

    test "regenerating the trigger clears the warning" do
      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.legacy_id"), [])

      assert Health.trigger_findings(repo: @repo, schema: @schema)
             |> Enum.filter(&(&1.table == "legacy_id")) == []
    end
  end

  describe "pk_drift — legacy trigger on a non-id table" do
    setup do
      SQL.query!(@repo, "CREATE TABLE #{@schema}.legacy_code (code text PRIMARY KEY)", [])
      :ok
    end

    test "yields :pk_drift with reason legacy_trigger_on_non_id_key" do
      SQL.query!(
        @repo,
        LegacyTriggerSQL.v0_10_2_create_trigger(
          @schema,
          "legacy_code",
          ~s|"threadline"."threadline_capture_changes"()|
        ),
        []
      )

      assert [%Finding{code: :pk_drift, severity: :error} = finding] =
               Health.trigger_findings(repo: @repo, schema: @schema)

      assert finding.details.reason == :legacy_trigger_on_non_id_key
      assert finding.details.recorded_key == ["id"]
      assert finding.details.expected_key == ["code"]
      assert finding.message =~ "hlth_key.legacy_code"
      assert finding.message =~ "mix threadline.gen.triggers --tables hlth_key.legacy_code"
    end

    test "regenerating the trigger clears the finding" do
      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.legacy_code"), [])

      assert Health.trigger_findings(repo: @repo, schema: @schema)
             |> Enum.filter(&(&1.table == "legacy_code")) == []
    end
  end

  describe "pk_drift — composite key mismatch" do
    setup do
      SQL.query!(
        @repo,
        "CREATE TABLE #{@schema}.comp (a int NOT NULL, b int NOT NULL, c int NOT NULL, PRIMARY KEY (a, b))",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.comp"), [])
      :ok
    end

    test "changing the live primary key yields :key_mismatch" do
      SQL.query!(
        @repo,
        "ALTER TABLE #{@schema}.comp DROP CONSTRAINT comp_pkey, ADD PRIMARY KEY (a, b, c)",
        []
      )

      assert [%Finding{code: :pk_drift} = finding] =
               Health.trigger_findings(repo: @repo, schema: @schema)

      assert finding.details.reason == :key_mismatch
      assert finding.details.recorded_key == ["a", "b"]
      assert finding.details.expected_key == ["a", "b", "c"]
    end

    test "regenerating the trigger after the PK change clears the finding" do
      SQL.query!(
        @repo,
        "ALTER TABLE #{@schema}.comp DROP CONSTRAINT comp_pkey, ADD PRIMARY KEY (a, b, c)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.comp"), [])

      assert Health.trigger_findings(repo: @repo, schema: @schema) == []
    end
  end

  describe "pk_drift — order-insensitive comparison" do
    test "trigger args in a different order than the live PK yields no finding" do
      SQL.query!(
        @repo,
        "CREATE TABLE #{@schema}.ord (a int NOT NULL, b int NOT NULL, PRIMARY KEY (a, b))",
        []
      )

      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER threadline_audit_hlth_key_ord AFTER INSERT OR UPDATE OR DELETE ON #{@schema}.ord FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"(\'b\', \'a\')',
        []
      )

      assert Health.trigger_findings(repo: @repo, schema: @schema) == []
    end
  end

  describe "pk_drift — byte-exact encoding, no case folding" do
    setup do
      SQL.query!(@repo, ~s'CREATE TABLE #{@schema}.mixed ("Code" text PRIMARY KEY)', [])
      :ok
    end

    test "the trigger recording the exact-case column yields no finding" do
      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER threadline_audit_hlth_key_mixed AFTER INSERT OR UPDATE OR DELETE ON #{@schema}.mixed FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"(\'Code\')',
        []
      )

      assert Health.trigger_findings(repo: @repo, schema: @schema) == []
    end

    test "the trigger recording the lowercased column yields :key_mismatch, never case-folded" do
      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER threadline_audit_hlth_key_mixed AFTER INSERT OR UPDATE OR DELETE ON #{@schema}.mixed FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"(\'code\')',
        []
      )

      assert [%Finding{code: :pk_drift} = finding] =
               Health.trigger_findings(repo: @repo, schema: @schema)

      assert finding.details.reason == :key_mismatch
      assert finding.details.recorded_key == ["code"]
      assert finding.details.expected_key == ["Code"]
    end
  end

  describe "pk_drift — configured primary_key: overrides (D-10)" do
    setup do
      previous = Application.get_env(:threadline, :trigger_capture)

      on_exit(fn ->
        case previous do
          nil -> Application.delete_env(:threadline, :trigger_capture)
          value -> Application.put_env(:threadline, :trigger_capture, value)
        end
      end)

      :ok
    end

    defp put_override(entries) do
      base = Application.get_env(:threadline, :trigger_capture, [])
      tables = Keyword.get(base, :tables, %{})
      merged = Map.merge(tables, entries)
      Application.put_env(:threadline, :trigger_capture, Keyword.put(base, :tables, merged))
    end

    defp findings_for(table) do
      Health.trigger_findings(repo: @repo, schema: @schema)
      |> Enum.filter(&(&1.table == table))
    end

    test "a real DO-block-accepted override with a qualifying index yields no finding" do
      SQL.query!(
        @repo,
        "CREATE TABLE #{@schema}.join_t (left_id bigint NOT NULL, right_id bigint NOT NULL)",
        []
      )

      SQL.query!(
        @repo,
        "CREATE UNIQUE INDEX join_t_pair ON #{@schema}.join_t (left_id, right_id)",
        []
      )

      put_override(%{"#{@schema}.join_t" => [primary_key: ["left_id", "right_id"]]})

      SQL.query!(
        @repo,
        TriggerSQL.create_trigger("#{@schema}.join_t", :default,
          primary_key: ["left_id", "right_id"]
        ),
        []
      )

      assert findings_for("join_t") == []
    end

    test "dropping the qualifying index yields :override_without_qualifying_index" do
      SQL.query!(
        @repo,
        "CREATE TABLE #{@schema}.join_t (left_id bigint NOT NULL, right_id bigint NOT NULL)",
        []
      )

      SQL.query!(
        @repo,
        "CREATE UNIQUE INDEX join_t_pair ON #{@schema}.join_t (left_id, right_id)",
        []
      )

      put_override(%{"#{@schema}.join_t" => [primary_key: ["left_id", "right_id"]]})

      SQL.query!(
        @repo,
        TriggerSQL.create_trigger("#{@schema}.join_t", :default,
          primary_key: ["left_id", "right_id"]
        ),
        []
      )

      SQL.query!(@repo, "DROP INDEX #{@schema}.join_t_pair", [])

      assert [%Finding{code: :pk_drift} = finding] = findings_for("join_t")
      assert finding.details.reason == :override_without_qualifying_index
    end

    test "a partial index over the declared columns still yields :override_without_qualifying_index" do
      SQL.query!(
        @repo,
        "CREATE TABLE #{@schema}.join_t (left_id bigint NOT NULL, right_id bigint NOT NULL)",
        []
      )

      SQL.query!(
        @repo,
        "CREATE UNIQUE INDEX join_t_pair ON #{@schema}.join_t (left_id, right_id)",
        []
      )

      put_override(%{"#{@schema}.join_t" => [primary_key: ["left_id", "right_id"]]})

      SQL.query!(
        @repo,
        TriggerSQL.create_trigger("#{@schema}.join_t", :default,
          primary_key: ["left_id", "right_id"]
        ),
        []
      )

      SQL.query!(@repo, "DROP INDEX #{@schema}.join_t_pair", [])

      SQL.query!(
        @repo,
        "CREATE UNIQUE INDEX join_t_pair ON #{@schema}.join_t (left_id, right_id) WHERE left_id > 0",
        []
      )

      assert [%Finding{code: :pk_drift} = finding] = findings_for("join_t")
      assert finding.details.reason == :override_without_qualifying_index
    end

    test "an override on a table that already has a primary key yields :override_on_table_with_primary_key" do
      SQL.query!(
        @repo,
        "CREATE TABLE #{@schema}.pk_and_override (id bigserial PRIMARY KEY, x int NOT NULL UNIQUE)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.pk_and_override"), [])

      put_override(%{"#{@schema}.pk_and_override" => [primary_key: ["x"]]})

      assert [%Finding{code: :pk_drift} = finding] = findings_for("pk_and_override")
      assert finding.details.reason == :override_on_table_with_primary_key
    end

    test "no primary key and no override yields :no_primary_key with a config snippet" do
      SQL.query!(@repo, "CREATE TABLE #{@schema}.nopk (a int NOT NULL PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.nopk"), [])
      SQL.query!(@repo, "ALTER TABLE #{@schema}.nopk DROP CONSTRAINT nopk_pkey", [])

      assert [%Finding{code: :pk_drift} = finding] = findings_for("nopk")
      assert finding.details.reason == :no_primary_key

      assert finding.message =~
               ~s(config :threadline, :trigger_capture, tables: %{"hlth_key.nopk" => [primary_key: [)
    end

    test "a renamed recorded column yields :recorded_column_missing" do
      SQL.query!(@repo, "CREATE TABLE #{@schema}.renamed (code text PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("#{@schema}.renamed"), [])
      SQL.query!(@repo, "ALTER TABLE #{@schema}.renamed RENAME COLUMN code TO sku", [])

      assert [%Finding{code: :pk_drift} = finding] = findings_for("renamed")
      assert finding.details.reason == :recorded_column_missing
      assert finding.details.missing_columns == ["code"]
    end

    test "a malformed :trigger_capture config makes trigger_findings/1 raise ArgumentError" do
      put_override(%{"#{@schema}.join_t" => [primary_key: "left_id"]})

      assert_raise ArgumentError, fn ->
        Health.trigger_findings(repo: @repo, schema: @schema)
      end
    end
  end
end
