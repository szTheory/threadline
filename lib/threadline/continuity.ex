defmodule Threadline.Continuity do
  @moduledoc """
  `Threadline.Continuity` documents the post-install capture boundary that
  starts each table's audit history at its first trigger-fired mutation.

  **T₀** means there are no `AuditChange` rows for a table until the first
  real trigger-fired mutation **after** capture is installed. There is **no
  pre-trigger history** — operators must not expect retroactive audit rows for
  data that existed before triggers were live.

  Consequently, `Threadline.row_history/3` returns **`[]`** for a primary key until
  that first post-install mutation produces an `audit_changes` row.

  Coverage checks reuse `Threadline.Health.trigger_coverage/1` (catalog queries
  only); this module does not duplicate `pg_trigger` / `pg_tables` inspection.

  See `guides/brownfield-continuity.md` for the operator checklist and
  compliance notes.
  """

  alias Ecto.Adapters.SQL
  alias Threadline.Health.CoverageSchemas
  alias Threadline.StorageSchema

  @typedoc "An option accepted by `explain_cutover/1`."
  @type explain_cutover_opt :: Threadline.repo_opt()

  @typedoc "An option accepted by `assert_capture_ready!/2`."
  @type assert_capture_ready_opt :: Threadline.repo_opt() | {:schema, String.t()}

  @doc """
  Returns `{:ok, iodata()}` containing a human-readable, read-only explanation
  of brownfield cutover steps. Raises `KeyError` when the required `:repo`
  option is missing.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required for compatibility with continuity checks.

  ## Returns

  - `{:ok, iodata()}` — the cutover checklist as newline-separated text.

  Other option keys are ignored.
  """
  @spec explain_cutover([explain_cutover_opt()]) :: {:ok, iodata()}
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
        "there is no pre-trigger history; `Threadline.row_history/3` may return `[]` for existing PKs."
      ]

    {:ok, Enum.intersperse(lines, ?\n)}
  end

  @doc """
  Returns `:ok` when `table_name` exists and has a Threadline capture trigger;
  raises `ArgumentError` when the table, schema, or trigger is missing, and
  `KeyError` when the required `:repo` option is missing.

  Bare table names resolve to the public host schema by default. Pass
  `schema: "support"` for a selected host schema, or pass a schema-qualified
  identifier such as `"support.tickets"`.

  ## Options

  - `:repo` — `Ecto.Repo` module. Required.
  - `:schema` — host schema string. Optional. Selects the schema for a bare table name.

  ## Returns

  - `:ok` — the table exists and has an enabled Threadline capture trigger.
  - Raises `ArgumentError` when the table or schema is unknown or the trigger is absent.

  Other option keys are ignored.
  """
  @spec assert_capture_ready!(String.t(), [assert_capture_ready_opt()]) :: :ok
  def assert_capture_ready!(table_name, opts) when is_binary(table_name) do
    repo = Keyword.fetch!(opts, :repo)
    parsed = StorageSchema.parse_table_identifier(table_name)
    schema = selected_schema!(parsed, opts)
    table_name = parsed.table

    schema = validate_schema!(repo, schema)

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
    selected = StorageSchema.validate_identifier!(selected, :host_schema)

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
      SQL.query!(
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
