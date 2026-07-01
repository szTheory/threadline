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

  alias Threadline.Health.CoverageSchemas
  alias Threadline.StorageSchema

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
  Asserts that `table_name` exists and has a Threadline capture trigger.

  Bare table names resolve to the public host schema by default. Pass
  `schema: "support"` for a selected host schema, or pass a schema-qualified
  identifier such as `"support.tickets"`.

  ## Options

  - `:repo` — required `Ecto.Repo` module
  - `:schema` — optional selected host schema for bare table names

  Raises `ArgumentError` if the table is unknown or not covered.
  """
  def assert_capture_ready!(table_name, opts) when is_binary(table_name) do
    repo = Keyword.fetch!(opts, :repo)
    parsed = StorageSchema.parse_table_identifier(table_name)
    schema = selected_schema!(parsed, opts)
    table_name = parsed.table

    validate_schema!(repo, schema)

    unless table_exists?(repo, schema, table_name) do
      raise ArgumentError, missing_table_message(schema, table_name)
    end

    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)

    if {:covered, table_name} in coverage do
      :ok
    else
      raise ArgumentError,
            "table #{inspect(display_table(schema, table_name))} is not covered by Threadline capture triggers"
    end
  end

  defp selected_schema!(%{schema: parsed_schema}, opts) do
    selected = Keyword.get(opts, :schema, parsed_schema)
    selected = StorageSchema.validate!(selected)

    if parsed_schema != "public" and selected != parsed_schema do
      raise ArgumentError,
            "table schema #{inspect(parsed_schema)} does not match selected host schema #{inspect(selected)}"
    end

    selected
  end

  defp validate_schema!(repo, schema) do
    case CoverageSchemas.validate(repo, schema) do
      {:ok, schema} -> schema
      {:error, _message} -> raise ArgumentError, "schema #{inspect(schema)} was not found"
    end
  end

  defp table_exists?(repo, schema, table_name) do
    %{rows: rows} =
      Ecto.Adapters.SQL.query!(
        repo,
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = $1 AND table_name = $2
        LIMIT 1
        """,
        [schema, table_name]
      )

    rows != []
  end

  defp missing_table_message("public", table_name) do
    "table #{inspect(table_name)} does not exist in schema public"
  end

  defp missing_table_message(schema, table_name) do
    "table #{inspect(display_table(schema, table_name))} does not exist"
  end

  defp display_table("public", table_name), do: table_name
  defp display_table(schema, table_name), do: "#{schema}.#{table_name}"
end
