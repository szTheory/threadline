defmodule Mix.Tasks.Threadline.Export do
  @shortdoc "Exports captured audit rows to CSV or JSON (same filters as Threadline.timeline/2)"

  @moduledoc """
  Loads application config, starts the configured Ecto repo, and writes an export file
  using `Threadline.Export` — **no** ad-hoc `Ecto.Query` in this task (parity with
  `mix threadline.retention.purge`).

  ## Flags

  - **`--output PATH` / `-o`** — required when not using `--dry-run` (destination file).
    Do not paste production secrets into shell history; prefer argv from env files or
    wrappers for `--actor-json` payloads.
  - **`--format`** — `csv` or `json` (default **`json`** when writing a file).
  - **`--json-format`** — `wrapped` (default) or `ndjson` (passed as `json_format:` to export).
  - **`--max-rows`** — forwarded as `:max_rows` (default from `Threadline.Export`).
  - **`--dry-run`** — counts matching rows via `Threadline.Export.count_matching/2`; does not write a file.
  - **`--table`** — optional table name filter (string), same as `timeline/2` `:table`.
  - **`--from` / `--to`** — optional inclusive `captured_at` bounds as ISO-8601 UTC strings.
  - **`--actor-json PATH`** — optional UTF-8 file; contents decoded with `Jason.decode!/1` and passed through
    `Threadline.Semantics.ActorRef.from_map/1` as `:actor_ref` in filters.

  ## Examples

      mix threadline.export --dry-run --table users
      mix threadline.export --format csv --output /tmp/audit.csv --table users
      mix threadline.export --format json --json-format ndjson -o /tmp/lines.ndjson --max-rows 5000

  Non-production: always review **`MIX_ENV`**, repo module, and printed counts before writing.
  """

  use Mix.Task

  alias Threadline.Export
  alias Threadline.Semantics.ActorRef

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [
          output: :string,
          format: :string,
          json_format: :string,
          max_rows: :integer,
          dry_run: :boolean,
          table: :string,
          from: :string,
          to: :string,
          actor_json: :string
        ],
        aliases: [o: :output]
      )

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    filters = build_filters(repo, opts)

    if opts[:dry_run] == true do
      {:ok, %{count: count}} = Export.count_matching(filters, [])
      banner(repo, count)
      Mix.shell().info(inspect(%{count: count}, pretty: true))
    else
      output =
        opts[:output] || Mix.raise("threadline.export: pass --output PATH or use --dry-run")

      format =
        case opts[:format] do
          nil -> "json"
          other -> other
        end

      format = String.downcase(format)

      unless format in ["csv", "json"] do
        Mix.raise("threadline.export: --format must be csv or json, got: #{inspect(format)}")
      end

      max_rows_kw = if(n = opts[:max_rows], do: [max_rows: n], else: [])

      json_format_kw =
        case opts[:json_format] do
          nil -> []
          "wrapped" -> [json_format: :wrapped]
          "ndjson" -> [json_format: :ndjson]
          other -> Mix.raise("threadline.export: unknown --json-format #{inspect(other)}")
        end

      {:ok, %{count: count}} = Export.count_matching(filters, [])
      banner(repo, count)

      {:ok, %{data: data}} =
        case format do
          "csv" -> Export.to_csv_iodata(filters, max_rows_kw)
          "json" -> Export.to_json_document(filters, max_rows_kw ++ json_format_kw)
        end

      File.write!(output, IO.iodata_to_binary(data))

      Mix.shell().info(
        "threadline.export: wrote #{byte_size(IO.iodata_to_binary(data))} bytes to #{output}"
      )
    end
  end

  defp banner(repo, count) do
    Mix.shell().info(
      "threadline.export: mix_env=#{Mix.env()} repo=#{inspect(repo)} matching_rows=#{count}"
    )
  end

  defp build_filters(repo, opts) do
    kw = [repo: repo]
    kw = if table = opts[:table], do: Keyword.put(kw, :table, table), else: kw
    kw = if from_s = opts[:from], do: Keyword.put(kw, :from, parse_dt!(:from, from_s)), else: kw
    kw = if to_s = opts[:to], do: Keyword.put(kw, :to, parse_dt!(:to, to_s)), else: kw

    kw =
      case opts[:actor_json] do
        nil ->
          kw

        path ->
          body = File.read!(path)
          map = Jason.decode!(body)

          case ActorRef.from_map(map) do
            {:ok, ref} ->
              Keyword.put(kw, :actor_ref, ref)

            {:error, reason} ->
              Mix.raise("threadline.export: invalid actor JSON (#{inspect(reason)})")
          end
      end

    kw
  end

  defp parse_dt!(name, str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} ->
        DateTime.truncate(dt, :microsecond)

      {:error, _} ->
        Mix.raise("threadline.export: invalid ISO-8601 for --#{name}: #{inspect(str)}")
    end
  end

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise(
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run export."
        )

      [repo | _] ->
        repo
    end
  end

  defp ensure_repo_started!(repo) do
    case repo.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, reason} -> Mix.raise("Could not start #{inspect(repo)}: #{inspect(reason)}")
    end
  end
end
