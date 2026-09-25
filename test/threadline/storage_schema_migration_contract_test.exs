defmodule Threadline.StorageSchemaMigrationContractTest do
  use ExUnit.Case, async: false

  # Byte pins for the governance migration that `mix threadline.install` writes
  # into an adopter's app. `nil` is the library default (no :storage_schema
  # configured, so "public"); "AuditLog" exercises mixed-case identifier quoting.
  # Change these only together with an intended change to the generated
  # migration, and say why in the commit.
  @governance_default_sha256 "f8364c7398b30ea454350e346162d4411c7ea4799e85eea68da7cf34df3d5956"
  @governance_default_bytes 3377
  @governance_auditlog_sha256 "ed742ee9fece935788acbe23f319491c1f2ed27ea9d37544dd68ff391d7194cb"
  @governance_auditlog_bytes 3407

  setup do
    previous = Application.get_env(:threadline, :storage_schema)
    on_exit(fn -> Application.put_env(:threadline, :storage_schema, previous) end)
    :ok
  end

  test "generated capture migration quotes the configured Threadline storage schema" do
    migration = Threadline.Capture.Migration.migration_content()

    assert migration =~ ~S|CREATE SCHEMA IF NOT EXISTS "threadline"|
    assert migration =~ ~S|CREATE TABLE IF NOT EXISTS "threadline"."audit_transactions"|
    assert migration =~ ~S|CREATE TABLE IF NOT EXISTS "threadline"."audit_changes"|
    assert migration =~ ~S|REFERENCES "threadline"."audit_transactions"(id)|
    refute migration =~ "threadline.audit_transactions"
  end

  test "generated semantics and governance migrations quote the configured storage schema" do
    semantics = Threadline.Semantics.Migration.migration_content()
    governance = Threadline.Governance.Migration.migration_content()

    assert semantics =~ ~S|CREATE TABLE IF NOT EXISTS "threadline"."audit_actions"|
    assert semantics =~ ~S|ALTER TABLE "threadline"."audit_transactions"|
    assert governance =~ ~S|CREATE TABLE IF NOT EXISTS "threadline"."threadline_export_jobs"|
    assert governance =~ ~S|CREATE TABLE IF NOT EXISTS "threadline"."threadline_evidence_records"|
    refute semantics =~ "threadline.audit_actions"
    refute governance =~ "threadline.threadline_export_jobs"
  end

  test "generated migration content preserves mixed-case schemas at generation time" do
    put_storage_schema!("AuditLog")

    capture = Threadline.Capture.Migration.migration_content()
    semantics = Threadline.Semantics.Migration.migration_content()
    governance = Threadline.Governance.Migration.migration_content()

    assert capture =~ ~S|CREATE SCHEMA IF NOT EXISTS "AuditLog"|
    assert capture =~ ~S|CREATE TABLE IF NOT EXISTS "AuditLog"."audit_transactions"|
    assert semantics =~ ~S|ALTER TABLE "AuditLog"."audit_transactions"|
    assert governance =~ ~S|CREATE TABLE IF NOT EXISTS "AuditLog"."threadline_saved_views"|

    put_storage_schema!("_audit1")

    regenerated = Threadline.Capture.Migration.migration_content()

    assert capture =~ ~S|"AuditLog"."audit_transactions"|
    refute capture =~ ~S|"_audit1"."audit_transactions"|
    assert regenerated =~ ~S|"_audit1"."audit_transactions"|
  end

  test "generated governance migration output is byte-identical to its pins" do
    for {schema, sha256, bytes} <- [
          {nil, @governance_default_sha256, @governance_default_bytes},
          {"AuditLog", @governance_auditlog_sha256, @governance_auditlog_bytes}
        ] do
      if schema,
        do: put_storage_schema!(schema),
        else: Application.delete_env(:threadline, :storage_schema)

      migration = Threadline.Governance.Migration.migration_content()
      measured = :sha256 |> :crypto.hash(migration) |> Base.encode16(case: :lower)

      if measured != sha256 do
        flunk(
          "the generated governance migration changed for storage schema " <>
            "#{inspect(schema || "public (library default)")}: pinned #{bytes} bytes " <>
            "sha256 #{sha256}, measured #{byte_size(migration)} bytes sha256 #{measured}. " <>
            "Compare `Threadline.Governance.Migration.migration_content/0` against the " <>
            "last commit that touched it; the pinned output is what adopters already ran."
        )
      end

      assert byte_size(migration) == bytes
    end
  end

  test "generated migrations reject invalid storage schema before emitting SQL" do
    for invalid <- ["", "foo.bar", "bad-name", "threadline;drop schema public", "   "] do
      put_storage_schema!(invalid)

      assert_raise ArgumentError, fn ->
        Threadline.Capture.Migration.migration_content()
      end

      assert_raise ArgumentError, fn ->
        Threadline.Semantics.Migration.migration_content()
      end

      assert_raise ArgumentError, fn ->
        Threadline.Governance.Migration.migration_content()
      end
    end
  end

  test "generated capture migration quotes every storage table reference" do
    put_storage_schema!("_audit1")

    migration = Threadline.Capture.Migration.migration_content()

    assert_generated_migration_parses!(migration)

    assert migration =~
             ~S|CREATE INDEX IF NOT EXISTS audit_changes_transaction_id_idx ON "_audit1"."audit_changes"|

    assert migration =~ ~S|DROP TABLE IF EXISTS "_audit1"."audit_changes"|
    refute_unquoted_storage_refs!(migration, "_audit1", ["audit_transactions", "audit_changes"])
  end

  test "generated semantics migration quotes every storage table reference" do
    put_storage_schema!("AuditLog")

    migration = Threadline.Semantics.Migration.migration_content()

    assert_generated_migration_parses!(migration)

    assert migration =~
             ~S|ALTER TABLE "AuditLog"."audit_transactions" DROP COLUMN IF EXISTS action_id|

    assert migration =~ ~S|DROP TABLE IF EXISTS "AuditLog"."audit_actions"|
    refute_unquoted_storage_refs!(migration, "AuditLog", ["audit_transactions", "audit_actions"])
  end

  test "generated governance migration quotes every storage table and index reference" do
    put_storage_schema!("audit")

    migration = Threadline.Governance.Migration.migration_content()

    assert_generated_migration_parses!(migration)

    for table <- [
          "threadline_export_jobs",
          "threadline_retention_runs",
          "threadline_saved_views",
          "threadline_evidence_records"
        ] do
      assert migration =~ ~s|"audit"."#{table}"|
    end

    assert migration =~
             ~S|DROP INDEX IF EXISTS "audit"."threadline_evidence_records_subject_ref_idx"|

    assert migration =~ ~S|DROP TABLE IF EXISTS "audit"."threadline_evidence_records"|

    refute_unquoted_storage_refs!(migration, "audit", [
      "threadline_export_jobs",
      "threadline_retention_runs",
      "threadline_saved_views",
      "threadline_evidence_records",
      "threadline_evidence_records_subject_idx",
      "threadline_evidence_records_recorded_at_idx",
      "threadline_evidence_records_subject_ref_idx"
    ])
  end

  defp put_storage_schema!(schema) do
    Application.put_env(:threadline, :storage_schema, schema)
  end

  defp assert_generated_migration_parses!(migration) do
    assert {:ok, _quoted} = Code.string_to_quoted(migration)
  end

  defp refute_unquoted_storage_refs!(migration, schema, identifiers) do
    for identifier <- identifiers do
      refute migration =~ "#{schema}.#{identifier}"
    end
  end
end
