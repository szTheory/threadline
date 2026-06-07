defmodule ThreadlinePhoenix.Repo.Migrations.ThreadlineStorageSchemaDefault do
  use Ecto.Migration

  @threadline_tables ~w(
    audit_transactions
    audit_changes
    audit_actions
    threadline_export_jobs
    threadline_retention_runs
    threadline_saved_views
    threadline_evidence_records
  )

  def up do
    execute "CREATE SCHEMA IF NOT EXISTS threadline"

    Enum.each(@threadline_tables, fn table ->
      execute """
      DO $$
      BEGIN
        IF to_regclass('public.#{table}') IS NOT NULL
           AND to_regclass('threadline.#{table}') IS NULL THEN
          EXECUTE 'ALTER TABLE public.#{table} SET SCHEMA threadline';
        END IF;
      END
      $$;
      """
    end)

    execute """
    DO $$
    DECLARE
      function_name text;
    BEGIN
      FOR function_name IN
        SELECT p.proname
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname LIKE 'threadline_capture_changes%'
      LOOP
        EXECUTE format('ALTER FUNCTION public.%I() SET SCHEMA threadline', function_name);
      END LOOP;
    END
    $$;
    """

    execute Threadline.Capture.TriggerSQL.install_function(storage_schema: "threadline")

    execute(
      Threadline.Capture.TriggerSQL.install_function_for_table("ticket_replies",
        mask: ["internal_note_body"],
        store_changed_from: true,
        storage_schema: "threadline"
      )
    )
  end

  def down do
    :ok
  end
end
