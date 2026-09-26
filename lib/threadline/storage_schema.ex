defmodule Threadline.StorageSchema do
  @moduledoc """
  Resolves and validates the PostgreSQL schema that stores Threadline-owned data.

  Threadline defaults to the host's `public` schema — the schema every install
  that predates this module already uses. Threadline cannot detect where an
  existing install put its audit tables, so the default has to be the one that
  is true for installs that already exist.

  A dedicated schema is an explicit opt-in, and is the recommended choice for a
  NEW install:

      config :threadline, storage_schema: "threadline"

  Any other single-segment PostgreSQL identifier works too (`"audit"`, for
  example). The choice is frozen at migration-generation time: the generated
  triggers and tables are written into whichever schema was configured when
  `mix threadline.install` ran, so changing the key afterwards requires a
  migration, not just a config edit.
  """

  @default "public"
  @identifier ~r/^[A-Za-z_][A-Za-z0-9_]*$/
  @max_identifier_bytes 63

  @threadline_tables ~w(
    audit_transactions
    audit_changes
    audit_actions
    threadline_export_jobs
    threadline_retention_runs
    threadline_saved_views
    threadline_evidence_records
  )

  @doc """
  Returns the configured storage schema, defaulting to the host's `public` schema.

  A dedicated schema is opted into with
  `config :threadline, storage_schema: "threadline"`, or per-call via the
  `:storage_schema` option.
  """
  def get(opts \\ []) when is_list(opts) do
    opts
    |> Keyword.get(:storage_schema, Application.get_env(:threadline, :storage_schema, @default))
    |> validate!()
  end

  @role_labels %{
    storage_schema: "storage schema",
    host_schema: "host schema",
    host_table: "host table",
    derived: "derived identifier",
    primary_key_column: "primary key column"
  }

  @typedoc false
  @type role :: :storage_schema | :host_schema | :host_table | :derived | :primary_key_column

  @doc "Validates a PostgreSQL identifier used as a schema, table, or function name."
  def validate!(value), do: validate_identifier!(value, :storage_schema)

  @doc false
  # Validates an identifier for a named role. The error names the role, the
  # offending value and its size in bytes (PostgreSQL's limit is in bytes, not
  # characters). `input` is the original user input when the value is one
  # segment of it, such as the table half of "schema.table".
  @spec validate_identifier!(term(), role(), String.t() | nil) :: String.t()
  def validate_identifier!(value, role, input \\ nil)

  def validate_identifier!(nil, role, input), do: invalid_identifier!(nil, role, input)

  def validate_identifier!(value, role, input) when is_boolean(value),
    do: invalid_identifier!(value, role, input)

  def validate_identifier!(value, role, input) when is_atom(value),
    do: value |> Atom.to_string() |> validate_identifier!(role, input)

  def validate_identifier!(value, role, input) when is_binary(value) do
    value = String.trim(value)

    if Regex.match?(@identifier, value) and byte_size(value) <= @max_identifier_bytes do
      value
    else
      invalid_identifier!(value, role, input)
    end
  end

  def validate_identifier!(value, role, input), do: invalid_identifier!(value, role, input)

  defp invalid_identifier!(value, :storage_schema, _input) do
    raise ArgumentError,
          "Threadline storage schema must be a non-empty PostgreSQL identifier " <>
            "matching #{@identifier.source} and at most #{@max_identifier_bytes} bytes, " <>
            "got: #{inspect(value)}"
  end

  defp invalid_identifier!(value, role, input) do
    label = Map.fetch!(@role_labels, role)
    from = if is_nil(input) or input == value, do: "", else: " (from #{inspect(input)})"

    rule =
      "a PostgreSQL identifier matching #{@identifier.source} " <>
        "and at most #{@max_identifier_bytes} bytes"

    detail =
      if is_binary(value),
        do: " is #{byte_size(value)} bytes; it must be ",
        else: " must be "

    raise ArgumentError, "Threadline #{label} #{inspect(value)}#{from}#{detail}#{rule}"
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
    value = String.trim(value)

    case String.split(value, ".", trim: false) do
      [table] when table != "" ->
        %{schema: "public", table: validate_identifier!(table, :host_table, value)}

      [schema, table] when schema != "" and table != "" ->
        %{
          schema: validate_identifier!(schema, :host_schema, value),
          table: validate_identifier!(table, :host_table, value)
        }

      _ ->
        raise ArgumentError, "table must be NAME or SCHEMA.NAME, got: #{inspect(value)}"
    end
  end

  @doc "Returns a quoted host table identifier."
  def qualified_host_table(value) do
    %{schema: schema, table: table} = parse_table_identifier(value)
    qualify(schema, table)
  end

  @doc """
  Returns the legacy suffix used in 0.10.x trigger and function names derived
  from a host table: the table name for `public`, `schema_table` otherwise.
  """
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
