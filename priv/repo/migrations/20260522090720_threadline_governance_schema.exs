defmodule ThreadlineGovernanceSchema do
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
  end

  def down do
    execute "DROP TABLE IF EXISTS threadline_saved_views"
    execute "DROP TABLE IF EXISTS threadline_retention_runs"
    execute "DROP TABLE IF EXISTS threadline_export_jobs"
  end
end
