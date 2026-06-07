defmodule Threadline.StorageSchema do
  @moduledoc """
  Resolves and validates the PostgreSQL schema that stores Threadline-owned data.

  Threadline defaults to the dedicated `threadline` schema. Hosts may set
  `config :threadline, storage_schema: "audit"` or `"public"` when they need a
  different footprint.
  """

  @default "threadline"
  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/

  @threadline_tables ~w(
    audit_transactions
    audit_changes
    audit_actions
    threadline_export_jobs
    threadline_retention_runs
    threadline_saved_views
    threadline_evidence_records
  )

  @doc "Returns the configured storage schema, defaulting to `threadline`."
  def get(opts \\ []) when is_list(opts) do
    opts
    |> Keyword.get(:storage_schema, Application.get_env(:threadline, :storage_schema, @default))
    |> validate!()
  end

  @doc "Validates a PostgreSQL identifier used as a schema, table, or function name."
  def validate!(value) when is_atom(value), do: value |> Atom.to_string() |> validate!()

  def validate!(value) when is_binary(value) do
    value = String.trim(value)

    if Regex.match?(@identifier, value) do
      value
    else
      raise ArgumentError,
            "Threadline storage schema must be a non-empty PostgreSQL identifier " <>
              "matching #{@identifier.source}, got: #{inspect(value)}"
    end
  end

  def validate!(value) do
    raise ArgumentError,
          "Threadline storage schema must be a string or atom, got: #{inspect(value)}"
  end

  @doc "Returns a safely double-quoted PostgreSQL identifier."
  def quote_ident(identifier), do: ~s("#{validate!(identifier)}")

  @doc "Returns a schema-qualified SQL identifier."
  def qualify(schema, name), do: "#{quote_ident(schema)}.#{quote_ident(name)}"

  @doc "Returns a Threadline-owned table qualified with the configured storage schema."
  def table(name, opts \\ []) when name in @threadline_tables do
    qualify(get(opts), name)
  end

  @doc "Returns repo options that target Threadline-owned storage."
  def repo_opts(opts \\ []), do: [prefix: get(opts)]

  @doc "Returns a Threadline-owned function qualified with the configured storage schema."
  def function(name, opts \\ []) do
    qualify(get(opts), name)
  end

  @doc """
  Parses a host table identifier.

  Plain names resolve to `public`. Qualified names must be `schema.table`.
  """
  def parse_table_identifier(value) when is_binary(value) do
    case String.split(value, ".", trim: true) do
      [table] -> %{schema: "public", table: validate!(table)}
      [schema, table] -> %{schema: validate!(schema), table: validate!(table)}
      _ -> raise ArgumentError, "table must be NAME or SCHEMA.NAME, got: #{inspect(value)}"
    end
  end

  @doc "Returns a quoted host table identifier."
  def qualified_host_table(value) do
    %{schema: schema, table: table} = parse_table_identifier(value)
    qualify(schema, table)
  end

  @doc "Returns a stable suffix for trigger/function names derived from a host table."
  def host_table_suffix(value) do
    %{schema: schema, table: table} = parse_table_identifier(value)

    if schema == "public" do
      table
    else
      "#{schema}_#{table}"
    end
  end

  @doc "Returns whether the name is one of Threadline's storage tables."
  def threadline_table?(value) do
    %{table: table} = parse_table_identifier(value)
    table in @threadline_tables
  end
end
