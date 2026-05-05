defmodule Bench.Helper do
  @baseline_dir Path.expand("baselines", __DIR__)

  def setup do
    unless Mix.env() == :test do
      IO.puts(:stderr, "Use MIX_ENV=test")
      System.halt(1)
    end

    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)
    {:ok, _} = Application.ensure_all_started(:threadline)

    case Process.whereis(Threadline.Test.Repo) do
      nil -> {:ok, _pid} = Threadline.Test.Repo.start_link()
      _pid -> :ok
    end

    :rand.seed(:exsss, {1, 2, 3})

    File.mkdir_p!(@baseline_dir)

    write_metadata()
  end

  defp write_metadata do
    {sha, 0} = System.cmd("git", ["rev-parse", "HEAD"])
    sha = String.trim(sha)

    preset = System.get_env("BENCH_PRESET") || "cold_single_table"
    %{rows: [[postgres_version]]} =
      Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "SHOW server_version", [])

    metadata = %{
      commit_sha: sha,
      elixir_version: System.version(),
      otp_release: System.otp_release(),
      postgres_version: postgres_version,
      preset: preset,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    File.write!(Path.join(@baseline_dir, "metadata.json"), Jason.encode!(metadata, pretty: true))
  end

  def formatters(name) do
    [
      Benchee.Formatters.Console,
      {Benchee.Formatters.HTML, file: Path.join(@baseline_dir, "#{name}.html")},
      {Benchee.Formatters.Markdown, file: Path.join(@baseline_dir, "#{name}.md")}
    ]
  end
end

defmodule Bench.Explain do
  def capture(query, file_path) do
    # Use Ecto to bypass ORM abstraction and grab direct plan
    %{rows: [[json]]} = Ecto.Adapters.SQL.query!(Threadline.Test.Repo, "EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) " <> query, [])
    File.write!(Path.expand(Path.join("baselines", file_path), __DIR__), Jason.encode!(json, pretty: true))
  end
end
