defmodule Threadline.StorageSchemaMigrationContractTest do
  use ExUnit.Case, async: true

  test "generated capture migration defaults Threadline storage to threadline schema" do
    migration = Threadline.Capture.Migration.migration_content()

    assert migration =~ "CREATE SCHEMA IF NOT EXISTS threadline"
    assert migration =~ "CREATE TABLE IF NOT EXISTS threadline.audit_transactions"
    assert migration =~ "CREATE TABLE IF NOT EXISTS threadline.audit_changes"
    assert migration =~ "REFERENCES threadline.audit_transactions(id)"
  end

  test "generated semantics and governance migrations use threadline schema" do
    semantics = Threadline.Semantics.Migration.migration_content()
    governance = Threadline.Governance.Migration.migration_content()

    assert semantics =~ "CREATE TABLE IF NOT EXISTS threadline.audit_actions"
    assert semantics =~ "ALTER TABLE threadline.audit_transactions"
    assert governance =~ "CREATE TABLE IF NOT EXISTS threadline.threadline_export_jobs"
    assert governance =~ "CREATE TABLE IF NOT EXISTS threadline.threadline_evidence_records"
  end
end
