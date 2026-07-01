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
