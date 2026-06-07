defmodule ThreadlineStorageSchemaDefault do
  use Ecto.Migration

  @tables ~w(
    audit_transactions
    audit_changes
    audit_actions
    threadline_export_jobs
    threadline_retention_runs
    threadline_saved_views
    threadline_evidence_records
  )

  def up do
    execute("CREATE SCHEMA IF NOT EXISTS threadline")

    Enum.each(@tables, fn table ->
      execute("""
      DO $$
      BEGIN
        IF to_regclass('public.#{table}') IS NOT NULL
           AND to_regclass('threadline.#{table}') IS NULL THEN
          EXECUTE 'ALTER TABLE public.#{table} SET SCHEMA threadline';
        END IF;
      END $$;
      """)
    end)

    execute("""
    DO $$
    DECLARE
      fn record;
    BEGIN
      FOR fn IN
        SELECT p.oid::regprocedure AS signature
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname LIKE 'threadline_capture_changes%'
      LOOP
        EXECUTE 'ALTER FUNCTION ' || fn.signature || ' SET SCHEMA threadline';
      END LOOP;
    END $$;
    """)

    execute(Threadline.Capture.TriggerSQL.install_function(storage_schema: "threadline"))
  end

  def down do
    :ok
  end
end
