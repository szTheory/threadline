defmodule Threadline.StorageSchema do
  @moduledoc """
  Resolves storage schema names and builds validated SQL references to Threadline-owned tables.

  `get/1` and `repo_opts/1` apply schema configuration, `table/2` names a
  Threadline table, `validate!/1` checks an identifier, and `threadline_table?/1`
  recognizes Threadline table names.

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

  @typedoc "An identifier accepted for schema validation; booleans and malformed names raise."
  @type identifier_input :: String.t() | atom()

  @typedoc "A parsed host table identifier with validated schema and table names."
  @type parsed_table_identifier :: %{schema: String.t(), table: String.t()}

  @typedoc "Repository options targeting the Threadline storage schema."
  @type repo_opts_result :: [{:prefix, String.t()}]

  @doc """
  Returns the configured storage schema, defaulting to the host's `public` schema.

  A dedicated schema is opted into with
  `config :threadline, storage_schema: "threadline"`, or per-call via the
  `:storage_schema` option.

  ## Options

  - `:storage_schema` — string. Optional. Overrides the application setting.

  ## Returns

  - The validated storage schema name.
  - Raises `ArgumentError` when the configured name is invalid.

  Other option keys are ignored.
  """
  @spec get([Threadline.storage_schema_opt()]) :: String.t()
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

  @doc "Validates a PostgreSQL identifier and returns its trimmed name; raises `ArgumentError` for an invalid identifier."
  @spec validate!(identifier_input()) :: String.t()
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

  @spec invalid_identifier!(term(), role(), String.t() | nil) :: no_return()
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

  @doc false
  @spec quote_ident(identifier_input()) :: String.t()
  def quote_ident(identifier), do: ~s("#{validate!(identifier)}")

  @doc false
  @spec qualify(identifier_input(), identifier_input()) :: String.t()
  def qualify(schema, name), do: "#{quote_ident(schema)}.#{quote_ident(name)}"

  @doc """
  Returns a schema-qualified SQL name for one of Threadline's storage tables.

  The accepted names are `audit_transactions`, `audit_changes`,
  `audit_actions`, `threadline_export_jobs`, `threadline_retention_runs`,
  `threadline_saved_views`, and `threadline_evidence_records`.

  ## Options

  - `:storage_schema` — string. Optional. Selects the configured storage schema.

  ## Returns

  - The quoted, schema-qualified table name.
  - Raises `FunctionClauseError` when `name` is not one of the Threadline tables.
  - Raises `ArgumentError` when the selected storage schema is invalid.

  Other option keys are ignored.
  """
  @spec table(String.t(), [Threadline.storage_schema_opt()]) :: String.t()
  def table(name, opts \\ []) when name in @threadline_tables do
    qualify(get(opts), name)
  end

  @doc """
  Returns Ecto repository options that target Threadline-owned storage.

  ## Options

  - `:storage_schema` — string. Optional. Selects the configured storage schema.

  ## Returns

  - A `:prefix` option containing the validated Threadline storage schema.
  - Raises `ArgumentError` when the selected storage schema is invalid.

  Other option keys are ignored.
  """
  @spec repo_opts([Threadline.storage_schema_opt()]) :: repo_opts_result()
  def repo_opts(opts \\ []), do: [prefix: get(opts)]

  @doc false
  @spec function(String.t() | atom(), [Threadline.storage_schema_opt()]) :: String.t()
  def function(name, opts \\ []) do
    qualify(get(opts), name)
  end

  @doc false
  @spec parse_table_identifier(String.t()) :: parsed_table_identifier()
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

  @doc false
  @spec qualified_host_table(String.t()) :: String.t()
  def qualified_host_table(value) do
    %{schema: schema, table: table} = parse_table_identifier(value)
    qualify(schema, table)
  end

  @doc false
  @spec host_table_suffix(String.t()) :: String.t()
  def host_table_suffix(value) do
    %{schema: schema, table: table} = parse_table_identifier(value)

    if schema == "public" do
      table
    else
      "#{schema}_#{table}"
    end
  end

  @doc "Returns whether a valid host table identifier names one of Threadline's storage tables; raises `ArgumentError` for malformed identifiers."
  @spec threadline_table?(String.t()) :: boolean()
  def threadline_table?(value) do
    %{table: table} = parse_table_identifier(value)
    table in @threadline_tables
  end
end
