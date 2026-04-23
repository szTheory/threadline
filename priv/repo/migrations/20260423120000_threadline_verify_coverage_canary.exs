defmodule ThreadlineVerifyCoverageCanary do
  use Ecto.Migration

  @doc """
  Creates canary tables for `mix threadline.verify_coverage` in test/CI:
  one with a Threadline capture trigger (expected to pass) and one without
  (used only when `THREADLINE_VERIFY_COVERAGE_FAILURE_TEST=1`).
  """

  def up do
    execute("""
    CREATE TABLE IF NOT EXISTS threadline_ci_coverage_canary (
      id bigserial PRIMARY KEY
    )
    """)

    execute(Threadline.Capture.TriggerSQL.create_trigger("threadline_ci_coverage_canary"))

    execute("""
    CREATE TABLE IF NOT EXISTS threadline_verify_cov_uncovered (
      id bigserial PRIMARY KEY
    )
    """)
  end

  def down do
    execute(Threadline.Capture.TriggerSQL.drop_trigger("threadline_ci_coverage_canary"))
    execute("DROP TABLE IF EXISTS threadline_ci_coverage_canary")
    execute("DROP TABLE IF EXISTS threadline_verify_cov_uncovered")
  end
end
