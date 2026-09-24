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
  @spec resolve_name([String.t()], %{
          required(:names) => MapSet.t(String.t()),
          required(:modules) => MapSet.t(String.t()),
          optional(:sources) => [String.t()]
        }) :: {String.t(), String.t()}
  def resolve_name(suffixes, %{names: names, modules: modules}) do
    Stream.iterate(1, &(&1 + 1))
    |> Enum.find_value(fn ordinal ->
      parts = if ordinal == 1, do: suffixes, else: suffixes ++ [Integer.to_string(ordinal)]
      name = "threadline_triggers_" <> Enum.join(parts, "_")
      module = "ThreadlineTriggers" <> Enum.map_join(parts, "", &Macro.camelize/1)

      if MapSet.member?(names, name) or MapSet.member?(modules, module) do
        nil
      else
        {name, module}
      end
    end)
  end
end
