defmodule Threadline.StorageSchemaPrefixContractTest do
  use ExUnit.Case, async: true

  @owned_schemas [
    {Threadline.Capture.AuditTransaction, "lib/threadline/capture/audit_transaction.ex",
     "audit_transactions"},
    {Threadline.Capture.AuditChange, "lib/threadline/capture/audit_change.ex", "audit_changes"},
    {Threadline.Semantics.AuditAction, "lib/threadline/semantics/audit_action.ex",
     "audit_actions"},
    {Threadline.Governance.EvidenceRecord, "lib/threadline/governance/evidence_record.ex",
     "threadline_evidence_records"},
    {Threadline.Governance.ExportJob, "lib/threadline/governance/export_job.ex",
     "threadline_export_jobs"},
    {Threadline.Governance.RetentionRun, "lib/threadline/governance/retention_run.ex",
     "threadline_retention_runs"},
    {Threadline.Governance.SavedView, "lib/threadline/governance/saved_view.ex",
     "threadline_saved_views"}
  ]

  test "owned Threadline schemas do not force the default storage prefix" do
    for {module, _path, source} <- @owned_schemas do
      assert module.__schema__(:source) == source
      assert module.__schema__(:prefix) == nil
    end
  end

  test "owned schema source files cannot reintroduce the default prefix attribute" do
    for {_module, path, _source} <- @owned_schemas do
      source = File.read!(path)

      refute source =~ ~s(@schema_prefix "threadline"),
             "#{path} must rely on Repo prefix options, not a fixed schema prefix"
    end
  end
end

defmodule Threadline.StorageSchemaCaseContractTest do
  use ExUnit.Case, async: false

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}
  alias Threadline.StorageSchemaCase
  alias Threadline.Test.Repo

  setup do
    StorageSchemaCase.ensure_storage_schema!("audit")
    StorageSchemaCase.clean_storage_schemas!(["threadline", "audit"])

    on_exit(fn ->
      StorageSchemaCase.clean_storage_schemas!(["threadline", "audit"])
    end)

    :ok
  end

  test "repo option helpers support insert, fetch, delete, and clean for custom storage" do
    opts = StorageSchemaCase.repo_opts("audit")
    txn = insert_transaction!(opts, %{txid: System.unique_integer([:positive])})

    assert %AuditTransaction{id: id} = Repo.get!(AuditTransaction, txn.id, opts)

    {1, nil} = Repo.delete_all(from(at in AuditTransaction, where: at.id == ^id), opts)
    assert Repo.get(AuditTransaction, id, opts) == nil
  end

  test "temporary storage schema helper restores application config after success and errors" do
    original = Application.get_env(:threadline, :storage_schema)

    assert "audit" =
             StorageSchemaCase.with_storage_schema("audit", fn ->
               Application.get_env(:threadline, :storage_schema)
             end)

    assert Application.get_env(:threadline, :storage_schema) == original

    assert_raise RuntimeError, "boom", fn ->
      StorageSchemaCase.with_storage_schema("audit", fn ->
        raise "boom"
      end)
    end

    assert Application.get_env(:threadline, :storage_schema) == original
  end

  test "cleanup removes default and custom storage rows in FK-safe order" do
    for schema <- ["threadline", "audit"] do
      opts = StorageSchemaCase.repo_opts(schema)

      action = insert_action!(opts)
      txn = insert_transaction!(opts, %{action_id: action.id})
      insert_change!(txn, opts)

      assert Repo.aggregate(AuditChange, :count, :id, opts) == 1
      assert Repo.aggregate(AuditTransaction, :count, :id, opts) == 1
      assert Repo.aggregate(AuditAction, :count, :id, opts) == 1
    end

    StorageSchemaCase.clean_storage_schemas!(["threadline", "audit"])

    for schema <- ["threadline", "audit"] do
      opts = StorageSchemaCase.repo_opts(schema)

      assert Repo.aggregate(AuditChange, :count, :id, opts) == 0
      assert Repo.aggregate(AuditTransaction, :count, :id, opts) == 0
      assert Repo.aggregate(AuditAction, :count, :id, opts) == 0
    end
  end

  defp insert_action!(opts) do
    {:ok, actor_ref} = ActorRef.new(:user, "storage-schema-case")

    %{
      name: "storage_schema.case",
      actor_ref: actor_ref,
      status: :ok
    }
    |> AuditAction.changeset()
    |> Repo.insert!(opts)
  end

  defp insert_transaction!(opts, attrs) do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    defaults
    |> Map.merge(attrs)
    |> AuditTransaction.changeset()
    |> Repo.insert!(opts)
  end

  defp insert_change!(txn, opts) do
    %{
      transaction_id: txn.id,
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "storage-schema-case"},
      op: "insert",
      data_after: %{"id" => "storage-schema-case"},
      changed_fields: ["id"],
      captured_at: DateTime.utc_now()
    }
    |> AuditChange.changeset()
    |> Repo.insert!(opts)
  end
end

defmodule Threadline.StorageSchemaMaskContractTest do
  @moduledoc """
  D-02 mask-regression guard (198-08 / T-198-08-01, T-198-08-02).

  `Threadline.StorageSchemaPrefixContractTest` above only proves the schema
  modules themselves carry no fixed `@schema_prefix`. It never observes a repo
  options callback, and it never scans `test/support/repo.ex` or `config/`.
  That is why a database-level `search_path`, or a `Threadline.Test.Repo`
  `default_options/1` callback that injects a default prefix, could silently
  re-mask the 79-test defect class this phase exists to retire, and nothing in
  the suite would notice.

  This module makes the forbidden shortcut a failing test instead of a policy
  sentence. Test 1 is the load-bearing behavioural assertion; Test 2 is its
  positive control (defeats vacuity — without it, Test 1 could also pass
  against a dead connection or a renamed module); Tests 3 and 4 are source
  refutations covering the two routes D-02 forbids.
  """

  use ExUnit.Case, async: false

  alias Threadline.Capture.AuditTransaction
  alias Threadline.StorageSchemaCase
  alias Threadline.Test.Repo

  @repo_path "test/support/repo.ex"

  test "reading an audit table through Threadline.Test.Repo with NO options raises undefined_table (D-02 teeth)" do
    assert_raise Postgrex.Error, ~r/undefined_table/, fn ->
      Repo.all(AuditTransaction)
    end

    error =
      try do
        Repo.all(AuditTransaction)
        nil
      rescue
        e in Postgrex.Error -> e
      end

    refute is_nil(error),
           "D-02: expected the unprefixed read to raise Postgrex.Error; if it succeeds, a " <>
             "repo-level default prefix or a database-level schema search parameter has been " <>
             "restored, and the 79-test defect class this phase retired is silently re-masked."

    assert error.postgres.code == :undefined_table,
           "D-02: expected pg code 42P01 (undefined_table), got #{inspect(error.postgres.code)}"
  end

  test "the SAME read with Threadline.StorageSchemaCase.repo_opts() succeeds and returns a list (positive control)" do
    result = Repo.all(AuditTransaction, StorageSchemaCase.repo_opts())

    assert is_list(result),
           "positive control failed: the prefixed read did not return a list. Without this " <>
             "control, Test 1 above could also pass against a dead connection or a renamed " <>
             "module rather than the D-02 mask actually being absent."
  end

  test "test/support/repo.ex declares no options callback that could inject a default prefix (D-02)" do
    source = File.read!(@repo_path)

    refute source =~ ~r/def(p)?\s+default_options\b/,
           "D-02: #{@repo_path} must not define default_options/1 — an Ecto.Repo " <>
             "default_options/1 callback is exactly the route by which a default `prefix:` " <>
             "could be silently injected into every query, re-hiding the defect class this " <>
             "phase exists to retire."
  end

  test "no config/*.exs file sets a schema search parameter on the repo connection (D-02)" do
    paths = Path.wildcard("config/*.exs")

    assert paths != [],
           "found no config/*.exs files to scan — the glob is broken, and a broken glob " <>
             "would launder a false pass for this guard"

    for path <- paths do
      stripped =
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.reject(fn line -> String.starts_with?(String.trim(line), "#") end)
        |> Enum.join("\n")

      refute stripped =~ ~r/search_path/i,
             "D-02: #{path} references search_path — a database-level schema search " <>
               "parameter on the repo connection is exactly the mask this phase retired. " <>
               "Restoring it re-hides the 79-test defect class rather than fixing the call " <>
               "sites."
    end
  end
end
