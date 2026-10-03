defmodule Threadline.TelemetryRepoQueryRecipeTest do
  @moduledoc """
  Proves every caveat `guides/telemetry.md`'s "Observing Threadline's
  queries" section states about the host repo's own
  `[:my_app, :repo, :query]` event (D-16 step 7). The guide text is derived
  from what this test observes, not asserted independently of it.
  """

  use Threadline.DataCase, async: false

  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Capture.TriggerSQL
  alias Threadline.Export
  alias Threadline.Semantics.AuditAction
  alias Threadline.Test.Repo

  @query_event Keyword.fetch!(Repo.config(), :telemetry_prefix) ++ [:query]
  @table "telemetry_recipe_target"

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@table} (
      id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name  text NOT NULL
    )
    """)

    Repo.query!(TriggerSQL.create_trigger(@table))

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@table))
      Repo.query!("DROP TABLE IF EXISTS #{@table}")
    end)

    :ok
  end

  setup do
    Repo.query!("TRUNCATE #{@table} CASCADE")
    ref = attach_telemetry!([@query_event])
    {:ok, ref: ref}
  end

  defp collect_sources(ref, timeout \\ 200) do
    collect_sources(ref, timeout, [])
  end

  defp collect_sources(ref, timeout, acc) do
    receive do
      {@query_event, ^ref, _measurements, metadata} ->
        collect_sources(ref, timeout, [metadata | acc])
    after
      timeout -> Enum.reverse(acc)
    end
  end

  test "the three capture/semantics schema sources are exactly the documented allowlist" do
    sources =
      [
        AuditChange.__schema__(:source),
        AuditTransaction.__schema__(:source),
        AuditAction.__schema__(:source)
      ]
      |> Enum.sort()

    assert sources == ~w(audit_actions audit_changes audit_transactions)

    guide = File.read!("guides/telemetry.md")

    assert String.contains?(guide, "~w(audit_changes audit_transactions audit_actions)"),
           "guides/telemetry.md must state the exact allowlist literal"
  end

  test "Repo.all on AuditChange with the storage prefix emits source == \"audit_changes\" (no prefix)",
       %{ref: ref} do
    Repo.all(AuditChange, repo_opts("threadline"))

    metadatas = collect_sources(ref)
    assert metadatas != [], "expected at least one repo query event"
    assert Enum.any?(metadatas, &(&1.source == "audit_changes"))
    refute Enum.any?(metadatas, &(is_binary(&1.source) and &1.source =~ "threadline"))
  end

  test "raw SQL and a subquery-rooted count both report source == nil", %{ref: ref} do
    Repo.query!("SELECT 1")
    raw_sql_metadatas = collect_sources(ref)
    assert raw_sql_metadatas != []
    assert Enum.all?(raw_sql_metadatas, &(&1.source == nil))

    {:ok, _} = Export.count_matching([repo: Repo], cap: 1)
    capped_count_metadatas = collect_sources(ref)
    assert capped_count_metadatas != []
    assert Enum.any?(capped_count_metadatas, &(&1.source == nil))
  end

  test "an insert into a trigger-audited host table reports only the host table as source, and captures a change",
       %{ref: ref} do
    # Ecto.Repo.insert_all/3 (not raw Repo.query!/2) so Ecto attaches a
    # `:source` to the one query it submits; the trigger's own inserts into
    # audit_changes/audit_transactions run entirely inside PostgreSQL, as
    # part of executing that single statement, and are invisible to Ecto
    # telemetry regardless of which API submitted it.
    Repo.insert_all(@table, [[name: "alice"]])

    metadatas = collect_sources(ref)
    assert metadatas != [], "expected at least one repo query event from the insert"

    sources = metadatas |> Enum.map(& &1.source) |> Enum.reject(&is_nil/1) |> Enum.uniq()

    assert sources == [@table],
           "capture must never surface as a repo query source: #{inspect(sources)}"

    changes = Repo.all(AuditChange, repo_opts("threadline"))
    assert Enum.any?(changes, &(&1.table_name == @table))
  end

  test "metadata.params carries a pinned bind value verbatim", %{ref: ref} do
    marker = "telemetry-recipe-marker-#{System.unique_integer([:positive])}"

    Repo.query!("INSERT INTO #{@table} (name) VALUES ($1)", [marker])

    metadatas = collect_sources(ref)
    assert metadatas != []

    assert Enum.any?(metadatas, fn metadata ->
             is_list(metadata.params) and marker in metadata.params
           end),
           "expected one repo query event's :params to contain #{inspect(marker)} verbatim"
  end
end
