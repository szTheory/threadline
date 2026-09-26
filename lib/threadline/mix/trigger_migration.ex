defmodule Threadline.Mix.TriggerMigration do
  @moduledoc false

  # Ecto names a migration by the text after the version in its file name and
  # refuses to run two pending files with the same name. A module defined in
  # two migration files also clashes when both are loaded. So the name and
  # module of a generated trigger migration are chosen together: the
  # table-derived name is tried first, then numbered candidates, until both
  # the name and the module are unused in the migrations directory.
  #
  # Host migration files are only read as text and matched with regular
  # expressions. They are never compiled or evaluated, so an unparseable or
  # side-effecting host file cannot break or hijack generation. A false match
  # only moves the choice on to the next number.

  alias Threadline.Capture.Naming
  alias Threadline.Mix.MigrationVersion

  @defmodule ~r/^\s*defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do\b/m

  @type scan :: %{
          names: MapSet.t(String.t()),
          modules: MapSet.t(String.t()),
          sources: [String.t()]
        }

  @doc false
  @spec scan(Path.t()) :: scan()
  def scan(path) do
    existing = MigrationVersion.existing(path)

    sources =
      Enum.flat_map(existing, fn {_version, _name, file} ->
        case File.read(file) do
          {:ok, source} -> [source]
          {:error, _} -> []
        end
      end)

    modules =
      for source <- sources, [_, module] <- Regex.scan(@defmodule, source), into: MapSet.new() do
        module
      end

    %{
      names: MapSet.new(existing, fn {_version, name, _file} -> name end),
      modules: modules,
      sources: sources
    }
  end

  @doc false
  @spec resolve_name([String.t() | %{schema: String.t(), table: String.t()}], %{
          required(:names) => MapSet.t(String.t()),
          required(:modules) => MapSet.t(String.t()),
          optional(:sources) => [String.t()]
        }) :: {String.t(), String.t()}
  def resolve_name(tables, %{names: names, modules: modules}) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.find_value(fn ordinal ->
      {name, module} = Naming.migration_name(tables, ordinal)

      if MapSet.member?(names, name) or MapSet.member?(modules, module) do
        nil
      else
        {name, module}
      end
    end)
  end

  # A table already has a trigger migration when some earlier migration creates
  # a Threadline trigger ON that table. The match is on the table named in the
  # statement's ON clause, never on the trigger name: two tables can share a
  # trigger name (public.a_b and a.b, or long names cut to the same 63 bytes),
  # and older releases wrote long names uncut.
  #
  # Every release wrote each statement as `execute` plus the inspected SQL, so
  # escaped quotes are unescaped and escaped newlines, tabs and carriage
  # returns become spaces before matching. Identifiers follow PostgreSQL: a
  # quoted one keeps its exact case with doubled quotes unescaped, an unquoted
  # one is lowercased. Only CREATE TRIGGER statements whose trigger name starts
  # with threadline_audit_ count, in up or in down; DROP statements do not.
  #
  # A schema-qualified ON clause matches only that exact schema and table.
  # Releases before 0.10 wrote an unqualified ON clause, which matches the
  # table in any schema. When in doubt the answer is a rerun, because a
  # rerun's rollback keeps the existing trigger, while a missed rerun would
  # let a rollback drop live capture.
  @trigger_prefix "threadline_audit_"

  # A source, not a compiled regex, so the module compiles on OTP releases
  # that refuse regexes in module attributes.
  @identifier ~S/"(?:[^"]|"")+"|[A-Za-z_][A-Za-z0-9_$]*/
  @create_trigger ~S/\bCREATE\s+(?:OR\s+REPLACE\s+)?(?:CONSTRAINT\s+)?TRIGGER\s+(/ <>
                    @identifier <>
                    ~S/)\s+(?:AFTER|BEFORE|INSTEAD\s+OF)\b[^;]{0,300}?\bON\s+(/ <>
                    @identifier <>
                    ~S/)(?:\s*\.\s*(/ <> @identifier <> ~S/))?/

  @type parsed_trigger :: %{trigger: String.t(), schema: String.t() | nil, table: String.t()}

  @doc false
  @spec parse_triggers([String.t()]) :: [parsed_trigger()]
  def parse_triggers(sources) do
    regex = Regex.compile!(@create_trigger, "i")

    for source <- sources,
        captures <- Regex.scan(regex, normalize_source(source), capture: :all_but_first) do
      case captures do
        [trigger, schema, table] when table != "" ->
          %{trigger: identifier(trigger), schema: identifier(schema), table: identifier(table)}

        # An unqualified ON clause: the optional group did not take part.
        [trigger, table | _unmatched] ->
          %{trigger: identifier(trigger), schema: nil, table: identifier(table)}
      end
    end
  end

  @doc false
  @spec rerun?(Naming.pair(), [String.t()]) :: boolean()
  def rerun?(%{schema: schema, table: table}, sources) do
    sources
    |> parse_triggers()
    |> Enum.any?(fn parsed ->
      String.starts_with?(parsed.trigger, @trigger_prefix) and parsed.table == table and
        parsed.schema in [nil, schema]
    end)
  end

  # Every table an earlier migration creates a Threadline trigger on, as a
  # pair. An unqualified ON clause, as releases before 0.10 wrote it, is read
  # as the table in public. A name that is not a valid identifier is skipped,
  # because nothing can be derived from it.
  @doc false
  @spec covered_pairs([String.t()]) :: [Naming.pair()]
  def covered_pairs(sources) do
    sources
    |> parse_triggers()
    |> Enum.filter(&String.starts_with?(&1.trigger, @trigger_prefix))
    |> Enum.flat_map(fn parsed ->
      try do
        [Naming.pair(%{schema: parsed.schema || "public", table: parsed.table})]
      rescue
        ArgumentError -> []
      end
    end)
    |> Enum.uniq()
  end

  defp normalize_source(source) do
    source
    |> String.replace(~S(\"), ~S("))
    |> String.replace([~S(\n), ~S(\t), ~S(\r)], " ")
  end

  defp identifier(~S(") <> _ = quoted) do
    quoted
    |> binary_part(1, byte_size(quoted) - 2)
    |> String.replace(~S(""), ~S("))
  end

  defp identifier(unquoted), do: String.downcase(unquoted, :ascii)
end
