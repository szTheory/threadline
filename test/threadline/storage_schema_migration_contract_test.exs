defmodule Threadline.StorageSchemaMigrationContractTest do
  use ExUnit.Case, async: false

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

  defp put_storage_schema!(schema) do
    Application.put_env(:threadline, :storage_schema, schema)
  end
end
