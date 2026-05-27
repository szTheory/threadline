defmodule ThreadlineEvidenceRecords do
  use Ecto.Migration

  def up do
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
  end
end
