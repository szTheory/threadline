defmodule Threadline.Health.TriggerFindingsTest do
  use Threadline.DataCase

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.{Naming, TriggerSQL}
  alias Threadline.Health
  alias Threadline.Health.{Finding, TriggerCatalog}
  alias Threadline.Test.LegacyTriggerSQL

  @repo Threadline.Test.Repo

  setup do
    SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_state CASCADE", [])
    SQL.query!(@repo, "CREATE SCHEMA hlth_find_state", [])

    on_exit(fn ->
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_state CASCADE", [])
    end)

    :ok
  end

  describe "capture_trigger_disabled — disabled ('D')" do
    setup do
      SQL.query!(
        @repo,
        "CREATE TABLE hlth_find_state.disabled_t (id bigserial PRIMARY KEY)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_state.disabled_t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_state.disabled_t DISABLE TRIGGER threadline_audit_hlth_find_state_disabled_t",
        []
      )

      :ok
    end

    test "returns exactly one :capture_trigger_disabled error with the exact fix" do
      findings = Health.trigger_findings(repo: @repo, schema: "hlth_find_state")

      assert [
               %Finding{
                 code: :capture_trigger_disabled,
                 severity: :error,
                 schema: "hlth_find_state",
                 table: "disabled_t"
               } = finding
             ] = findings

      assert finding.message =~ "hlth_find_state.disabled_t"
      assert finding.message =~ "ENABLE TRIGGER"
      assert finding.details.enabled_state == "D"
    end

    test "re-enabling the trigger returns []" do
      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_state.disabled_t ENABLE TRIGGER threadline_audit_hlth_find_state_disabled_t",
        []
      )

      assert Health.trigger_findings(repo: @repo, schema: "hlth_find_state") == []
    end
  end

  describe "capture_trigger_disabled — replica-only ('R')" do
    setup do
      SQL.query!(
        @repo,
        "CREATE TABLE hlth_find_state.replica_t (id bigserial PRIMARY KEY)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_state.replica_t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_state.replica_t ENABLE REPLICA TRIGGER threadline_audit_hlth_find_state_replica_t",
        []
      )

      :ok
    end

    test "returns the finding with enabled_state R and the replica fix" do
      assert [%Finding{} = finding] =
               Health.trigger_findings(repo: @repo, schema: "hlth_find_state")

      assert finding.details.enabled_state == "R"
      assert finding.message =~ "ENABLE ALWAYS TRIGGER"
      assert finding.message =~ "session_replication_role"
    end

    test "ENABLE ALWAYS TRIGGER returns []" do
      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_state.replica_t ENABLE ALWAYS TRIGGER threadline_audit_hlth_find_state_replica_t",
        []
      )

      assert Health.trigger_findings(repo: @repo, schema: "hlth_find_state") == []
    end
  end

  describe "telemetry" do
    test "emits [:threadline, :health, :findings_checked] once per call" do
      SQL.query!(
        @repo,
        "CREATE TABLE hlth_find_state.telemetry_t (id bigserial PRIMARY KEY)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_state.telemetry_t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_state.telemetry_t DISABLE TRIGGER threadline_audit_hlth_find_state_telemetry_t",
        []
      )

      :telemetry.attach(
        "test-findings-checked",
        [:threadline, :health, :findings_checked],
        fn _name, measurements, _meta, pid -> send(pid, {:telemetry, measurements}) end,
        self()
      )

      on_exit(fn -> :telemetry.detach("test-findings-checked") end)

      Health.trigger_findings(repo: @repo, schema: "hlth_find_state")

      assert_receive {:telemetry, %{errors: 1, warnings: 0}}
    end
  end

  describe "decode_tgargs/1" do
    test "splits on NUL and drops only the trailing empty element" do
      assert TriggerCatalog.decode_tgargs(<<"a", 0, "b", 0>>) == ["a", "b"]
      assert TriggerCatalog.decode_tgargs(<<>>) == []
    end
  end

  describe "Finding struct" do
    test "every severity is :error or :warning" do
      SQL.query!(
        @repo,
        "CREATE TABLE hlth_find_state.severity_t (id bigserial PRIMARY KEY)",
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_state.severity_t"), [])

      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_state.severity_t DISABLE TRIGGER threadline_audit_hlth_find_state_severity_t",
        []
      )

      findings = Health.trigger_findings(repo: @repo, schema: "hlth_find_state")
      assert findings != []

      for finding <- findings do
        assert finding.severity in [:error, :warning]
      end
    end

    test "@enforce_keys raises on a missing key" do
      assert_raise ArgumentError, fn ->
        struct!(Finding, %{code: :pk_drift})
      end
    end
  end

  describe "duplicate_capture_trigger" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_dup CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hlth_find_dup", [])
      SQL.query!(@repo, "CREATE TABLE hlth_find_dup.dup_t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_dup.dup_t"), [])

      on_exit(fn -> SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_dup CASCADE", []) end)

      :ok
    end

    test "a copy trigger calling the global function gives one duplicate finding" do
      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER audit_copy_dup_t AFTER INSERT OR UPDATE OR DELETE ON hlth_find_dup.dup_t FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"()',
        []
      )

      assert [%Finding{code: :duplicate_capture_trigger} = finding] =
               Health.trigger_findings(repo: @repo, schema: "hlth_find_dup")

      assert finding.details.extra == ["audit_copy_dup_t"]
      assert finding.details.canonical == "threadline_audit_hlth_find_dup_dup_t"
      assert finding.message =~ ~s(DROP TRIGGER "audit_copy_dup_t" ON "hlth_find_dup"."dup_t";)
      assert finding.message =~ "mix threadline.gen.triggers --tables hlth_find_dup.dup_t"

      SQL.query!(@repo, "DROP TRIGGER audit_copy_dup_t ON hlth_find_dup.dup_t", [])
      assert Health.trigger_findings(repo: @repo, schema: "hlth_find_dup") == []
    end

    test "an unrelated trigger calling a non-Threadline function is never counted as a duplicate" do
      SQL.query!(
        @repo,
        "CREATE TRIGGER unrelated_trg BEFORE UPDATE ON hlth_find_dup.dup_t FOR EACH ROW EXECUTE FUNCTION suppress_redundant_updates_trigger()",
        []
      )

      assert Health.trigger_findings(repo: @repo, schema: "hlth_find_dup") == []
    end

    test "two triggers where neither is the canonical name lists both as extra" do
      SQL.query!(
        @repo,
        "DROP TRIGGER threadline_audit_hlth_find_dup_dup_t ON hlth_find_dup.dup_t",
        []
      )

      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER audit_copy_a AFTER INSERT OR UPDATE OR DELETE ON hlth_find_dup.dup_t FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"()',
        []
      )

      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER audit_copy_b AFTER INSERT OR UPDATE OR DELETE ON hlth_find_dup.dup_t FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"()',
        []
      )

      assert [%Finding{code: :duplicate_capture_trigger} = finding] =
               Health.trigger_findings(repo: @repo, schema: "hlth_find_dup")

      assert finding.details.extra == ["audit_copy_a", "audit_copy_b"]
    end

    test "a public-schema table's duplicate finding uses the fully qualified fix command" do
      SQL.query!(@repo, "DROP TABLE IF EXISTS hlth_find_dup_public_t", [])
      SQL.query!(@repo, "CREATE TABLE hlth_find_dup_public_t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("public.hlth_find_dup_public_t"), [])

      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER audit_copy_public AFTER INSERT OR UPDATE OR DELETE ON hlth_find_dup_public_t FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"()',
        []
      )

      on_exit(fn -> SQL.query!(@repo, "DROP TABLE IF EXISTS hlth_find_dup_public_t", []) end)

      assert finding =
               Health.trigger_findings(repo: @repo, schema: "public")
               |> Enum.find(
                 &(&1.code == :duplicate_capture_trigger and
                     &1.table == "hlth_find_dup_public_t")
               )

      assert finding.message =~
               "mix threadline.gen.triggers --tables public.hlth_find_dup_public_t"
    end
  end

  describe "pin: LIKE prefixes match Naming's prefixes" do
    alias Threadline.Capture.Naming

    test "trigger_name_like/0 and function_name_like/0 are pinned to Naming's prefixes" do
      trigger_prefix =
        TriggerCatalog.trigger_name_like()
        |> String.replace("\\_", "_")
        |> String.trim_trailing("%")

      function_prefix =
        TriggerCatalog.function_name_like()
        |> String.replace("\\_", "_")
        |> String.trim_trailing("%")

      assert trigger_prefix <> "pin_t" == Naming.trigger_name("pin_t")
      assert function_prefix <> "pin_t" == Naming.function_name("pin_t")
    end
  end

  describe "schema adjacency, filtering and empty edge" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_a CASCADE", [])
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_b CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hlth_find_a", [])
      SQL.query!(@repo, "CREATE SCHEMA hlth_find_b", [])

      for schema <- ["hlth_find_a", "hlth_find_b"] do
        SQL.query!(@repo, "CREATE TABLE #{schema}.same_t (id bigserial PRIMARY KEY)", [])
        SQL.query!(@repo, TriggerSQL.create_trigger("#{schema}.same_t"), [])

        SQL.query!(
          @repo,
          "ALTER TABLE #{schema}.same_t DISABLE TRIGGER threadline_audit_#{schema}_same_t",
          []
        )
      end

      on_exit(fn ->
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_a CASCADE", [])
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_b CASCADE", [])
      end)

      :ok
    end

    test "same-named tables in two schemas each get their own finding" do
      findings = Health.trigger_findings(repo: @repo, schema: ["hlth_find_a", "hlth_find_b"])
      schemas = Enum.map(findings, & &1.schema) |> Enum.sort()

      assert schemas == ["hlth_find_a", "hlth_find_b"]
    end

    test "schema: string filters to only that schema" do
      findings = Health.trigger_findings(repo: @repo, schema: "hlth_find_a")
      assert [%Finding{schema: "hlth_find_a", table: "same_t"}] = findings
    end

    test "omitting :schema returns both among all schemas" do
      findings = Health.trigger_findings(repo: @repo)
      schemas = Enum.map(findings, & &1.schema)

      assert "hlth_find_a" in schemas
      assert "hlth_find_b" in schemas
    end

    test "schema: [] and a non-string schema raise ArgumentError" do
      assert_raise ArgumentError, fn -> Health.trigger_findings(repo: @repo, schema: []) end

      assert_raise ArgumentError, fn ->
        Health.trigger_findings(repo: @repo, schema: :hlth_find_a)
      end
    end

    test "a schema with no Threadline triggers returns []" do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_empty CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hlth_find_empty", [])

      assert Health.trigger_findings(repo: @repo, schema: "hlth_find_empty") == []

      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_empty CASCADE", [])
    end
  end

  describe "ordering" do
    setup do
      SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_order CASCADE", [])
      SQL.query!(@repo, "CREATE SCHEMA hlth_find_order", [])
      SQL.query!(@repo, "CREATE TABLE hlth_find_order.mixed_t (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_find_order.mixed_t"), [])

      SQL.query!(
        @repo,
        ~s'CREATE TRIGGER audit_copy_mixed AFTER INSERT OR UPDATE OR DELETE ON hlth_find_order.mixed_t FOR EACH ROW EXECUTE FUNCTION "threadline"."threadline_capture_changes"()',
        []
      )

      SQL.query!(
        @repo,
        "ALTER TABLE hlth_find_order.mixed_t DISABLE TRIGGER threadline_audit_hlth_find_order_mixed_t",
        []
      )

      on_exit(fn -> SQL.query!(@repo, "DROP SCHEMA IF EXISTS hlth_find_order CASCADE", []) end)

      :ok
    end

    test "one table with both a duplicate and a disabled trigger yields both codes, sorted, and stable across calls" do
      first = Health.trigger_findings(repo: @repo, schema: "hlth_find_order")
      second = Health.trigger_findings(repo: @repo, schema: "hlth_find_order")

      assert [
               %Finding{code: :capture_trigger_disabled},
               %Finding{code: :duplicate_capture_trigger}
             ] = first

      assert first == second
    end
  end

  describe "shared_capture_function" do
    setup do
      for schema <- ["hlth_share", "hlth_share_x", "hlth_share_y"] do
        SQL.query!(@repo, "DROP SCHEMA IF EXISTS #{schema} CASCADE", [])
        SQL.query!(@repo, "CREATE SCHEMA #{schema}", [])
      end

      on_exit(fn ->
        for schema <- ["hlth_share", "hlth_share_x", "hlth_share_y"] do
          SQL.query!(@repo, "DROP SCHEMA IF EXISTS #{schema} CASCADE", [])
        end

        SQL.query!(
          @repo,
          "DROP FUNCTION IF EXISTS #{quote_ident(Naming.function_name("hlth_share.a"))}()",
          []
        )

        SQL.query!(
          @repo,
          "DROP FUNCTION IF EXISTS #{quote_ident(Naming.function_name("hlth_share.parted"))}()",
          []
        )

        SQL.query!(
          @repo,
          "DROP FUNCTION IF EXISTS #{quote_ident(Naming.function_name("hlth_share_x.a"))}()",
          []
        )
      end)

      :ok
    end

    defp quote_ident(name), do: ~s("threadline"."#{name}")

    test "a per-table function shared by two tables yields one finding per table naming both, and the same regenerate-all fix" do
      SQL.query!(@repo, "CREATE TABLE hlth_share.a (id bigserial PRIMARY KEY, note text)", [])
      SQL.query!(@repo, TriggerSQL.install_function_for_table("hlth_share.a", mask: ["note"]), [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_share.a", :per_table, []), [])

      SQL.query!(@repo, "CREATE TABLE hlth_share.b (id bigserial PRIMARY KEY)", [])
      fn_name = Naming.function_name("hlth_share.a")

      SQL.query!(
        @repo,
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "hlth_share",
          "b",
          ~s|"threadline"."#{fn_name}"()|
        ),
        []
      )

      findings =
        Health.trigger_findings(repo: @repo, schema: "hlth_share")
        |> Enum.filter(&(&1.code == :shared_capture_function))

      assert length(findings) == 2

      for finding <- findings do
        assert finding.details.function == "threadline.#{fn_name}"
        assert finding.details.tables == ["hlth_share.a", "hlth_share.b"]
        assert finding.message =~ "mix threadline.gen.triggers --tables hlth_share.a,hlth_share.b"
      end

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_share.b"), [])

      remaining =
        Health.trigger_findings(repo: @repo, schema: "hlth_share")
        |> Enum.filter(&(&1.code == :shared_capture_function))

      assert remaining == []
    end

    test "two tables on the global default function are never reported as shared" do
      SQL.query!(@repo, "CREATE TABLE hlth_share.g1 (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_share.g1"), [])
      SQL.query!(@repo, "CREATE TABLE hlth_share.g2 (id bigserial PRIMARY KEY)", [])
      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_share.g2"), [])

      findings =
        Health.trigger_findings(repo: @repo, schema: "hlth_share")
        |> Enum.filter(&(&1.code == :shared_capture_function))

      assert findings == []
    end

    test "the shared-function check scans the whole catalog even when :schema narrows the return (D-02)" do
      SQL.query!(@repo, "CREATE TABLE hlth_share_x.a (id bigserial PRIMARY KEY, note text)", [])

      SQL.query!(
        @repo,
        TriggerSQL.install_function_for_table("hlth_share_x.a", mask: ["note"]),
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_share_x.a", :per_table, []), [])

      SQL.query!(@repo, "CREATE TABLE hlth_share_y.b (id bigserial PRIMARY KEY)", [])
      fn_name = Naming.function_name("hlth_share_x.a")

      SQL.query!(
        @repo,
        LegacyTriggerSQL.v0_10_2_create_trigger(
          "hlth_share_y",
          "b",
          ~s|"threadline"."#{fn_name}"()|
        ),
        []
      )

      assert [%Finding{code: :shared_capture_function} = finding] =
               Health.trigger_findings(repo: @repo, schema: "hlth_share_x")

      assert finding.table == "a"
      assert finding.message =~ "hlth_share_y.b"
    end

    test "a partitioned table's own per-table function is never reported as shared with its partitions" do
      SQL.query!(
        @repo,
        "CREATE TABLE hlth_share.parted (id bigint, k int, note text, PRIMARY KEY (id, k)) PARTITION BY LIST (k)",
        []
      )

      SQL.query!(
        @repo,
        "CREATE TABLE hlth_share.parted_1 PARTITION OF hlth_share.parted FOR VALUES IN (1)",
        []
      )

      SQL.query!(
        @repo,
        "CREATE TABLE hlth_share.parted_2 PARTITION OF hlth_share.parted FOR VALUES IN (2)",
        []
      )

      SQL.query!(
        @repo,
        TriggerSQL.install_function_for_table("hlth_share.parted", mask: ["note"]),
        []
      )

      SQL.query!(@repo, TriggerSQL.create_trigger("hlth_share.parted", :per_table, []), [])

      findings =
        Health.trigger_findings(repo: @repo, schema: "hlth_share")
        |> Enum.filter(&(&1.table == "parted"))

      assert findings == []
    end
  end
end
