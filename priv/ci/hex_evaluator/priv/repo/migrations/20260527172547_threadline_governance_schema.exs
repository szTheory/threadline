defmodule HexEvaluator.Repo.Migrations.ThreadlineGovernanceSchema do
  use Ecto.Migration

  def up do
    execute """
    CREATE TABLE IF NOT EXISTS threadline_export_jobs (
      id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
      status         text        NOT NULL,
      query_params   jsonb       NOT NULL,
      actor_ref      jsonb,
      file_path      text,
      error_message  text,
      started_at     timestamptz,
      completed_at   timestamptz,
      expires_at     timestamptz,
      inserted_at    timestamptz NOT NULL DEFAULT now(),
      updated_at     timestamptz NOT NULL DEFAULT now()
    )
    """

    execute """
    CREATE TABLE IF NOT EXISTS threadline_retention_runs (
      id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
      status         text        NOT NULL,
      deleted_count  integer,
      duration_ms    integer,
      error_message  text,
      started_at     timestamptz,
      completed_at   timestamptz,
      inserted_at    timestamptz NOT NULL DEFAULT now(),
      updated_at     timestamptz NOT NULL DEFAULT now()
    )
    """

    execute """
    CREATE TABLE IF NOT EXISTS threadline_saved_views (
      id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
      name           text        NOT NULL,
      actor_ref      jsonb       NOT NULL,
      filters        jsonb       NOT NULL,
      inserted_at    timestamptz NOT NULL DEFAULT now(),
      updated_at     timestamptz NOT NULL DEFAULT now()
    )
    """

    execute("""
    CREATE TABLE IF NOT EXISTS threadline_evidence_records (
      id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
      subject        text        NOT NULL,
      subject_ref    jsonb       NOT NULL,
      summary_status text        NOT NULL,
      recorded_at    timestamptz NOT NULL,
      actor_ref      jsonb,
      provenance     jsonb       NOT NULL DEFAULT '{}'::jsonb,
      detail         jsonb       NOT NULL DEFAULT '{}'::jsonb,
      schema_version integer     NOT NULL DEFAULT 1,
      inserted_at    timestamptz NOT NULL DEFAULT now()
    )
    """)

    execute("""
    CREATE INDEX IF NOT EXISTS threadline_evidence_records_subject_idx
      ON threadline_evidence_records (subject)
    """)

    execute("""
    CREATE INDEX IF NOT EXISTS threadline_evidence_records_recorded_at_idx
      ON threadline_evidence_records (recorded_at)
    """)

    execute("""
    CREATE INDEX IF NOT EXISTS threadline_evidence_records_subject_ref_idx
      ON threadline_evidence_records
      USING gin (subject_ref)
    """)
  end

  def down do
    execute("DROP INDEX IF EXISTS threadline_evidence_records_subject_ref_idx")
    execute("DROP INDEX IF EXISTS threadline_evidence_records_recorded_at_idx")
    execute("DROP INDEX IF EXISTS threadline_evidence_records_subject_idx")
    execute("DROP TABLE IF EXISTS threadline_evidence_records")
    execute("DROP TABLE IF EXISTS threadline_saved_views")
    execute("DROP TABLE IF EXISTS threadline_retention_runs")
    execute("DROP TABLE IF EXISTS threadline_export_jobs")
  end
end
