defmodule Threadline.Continuity do
  @moduledoc """
  Brownfield cutover helpers for honest **T₀** semantics with Threadline capture.

  **T₀** means there are no `AuditChange` rows for a table until the first
  real trigger-fired mutation **after** capture is installed. There is **no
  pre-trigger history** — operators must not expect retroactive audit rows for
  data that existed before triggers were live.

  Consequently, `Threadline.history/3` returns **`[]`** for a primary key until
  that first post-install mutation produces an `audit_changes` row.

  Coverage checks reuse `Threadline.Health.trigger_coverage/1` (catalog queries
  only); this module does not duplicate `pg_trigger` / `pg_tables` inspection.

  See `guides/brownfield-continuity.md` for the operator checklist and
  compliance notes.
  """

  @doc """
  Returns a human-readable explanation of brownfield cutover steps (read-only).

  ## Options

  - `:repo` — required `Ecto.Repo` module (used only when future steps need DB
    metadata; today the explanation is static).
  """
  def explain_cutover(opts) do
    _repo = Keyword.fetch!(opts, :repo)

    lines =
      [
        "Brownfield Threadline cutover (honest T0):",
        "",
        "1. Install the audit schema (e.g. `mix threadline.install` then migrate).",
        "2. Generate and apply per-table triggers (`mix threadline.gen.triggers`).",
        "3. Run `mix threadline.verify_coverage` to confirm expected tables are covered.",
        "4. Optionally run `mix threadline.continuity --dry-run` (or with `--table`) before cutover.",
        "",
        "Until the first audited write after triggers exist, `audit_changes` stays empty —",
        "there is no pre-trigger history; `Threadline.history/3` may return `[]` for existing PKs."
      ]

    {:ok, Enum.intersperse(lines, ?\n)}
  end

  @doc """
  Asserts that `table_name` exists in `public` and has a Threadline capture trigger.

  ## Options

  - `:repo` — required `Ecto.Repo` module

  Raises `ArgumentError` if the table is unknown or not covered.
  """
  def assert_capture_ready!(table_name, opts) when is_binary(table_name) do
    repo = Keyword.fetch!(opts, :repo)
    table_name = String.trim(table_name)

    if table_name == "" do
      raise ArgumentError, "table_name must be a non-empty string"
    end

    unless public_table_exists?(repo, table_name) do
      raise ArgumentError,
            "table #{inspect(table_name)} does not exist in schema public"
    end

    coverage = Threadline.Health.trigger_coverage(repo: repo)

    if {:covered, table_name} in coverage do
      :ok
    else
      raise ArgumentError,
            "table #{inspect(table_name)} is not covered by Threadline capture triggers"
    end
  end

  defp public_table_exists?(repo, table_name) do
    %{rows: rows} =
      Ecto.Adapters.SQL.query!(
        repo,
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
        LIMIT 1
        """,
        [table_name]
      )

    rows != []
  end
end
