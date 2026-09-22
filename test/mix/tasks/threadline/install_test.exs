defmodule Mix.Tasks.Threadline.InstallTest do
  # async: false — the task writes relative to the working directory and reads
  # the global :storage_schema application env, and both are VM-wide.
  use ExUnit.Case, async: false

  @suffixes [
    "_threadline_audit_schema.exs",
    "_threadline_semantics_schema.exs",
    "_threadline_governance_schema.exs"
  ]

  setup do
    previous_shell = Mix.shell()
    previous_schema = Application.fetch_env(:threadline, :storage_schema)
    Mix.shell(Mix.Shell.Process)

    tmp =
      Path.join(System.tmp_dir!(), "threadline-install-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp)

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous_schema do
        {:ok, value} -> Application.put_env(:threadline, :storage_schema, value)
        :error -> Application.delete_env(:threadline, :storage_schema)
      end

      File.rm_rf!(tmp)
    end)

    %{tmp: tmp}
  end

  defp run_install(tmp) do
    File.cd!(tmp, fn -> Mix.Tasks.Threadline.Install.run([]) end)
    drain_shell([])
  end

  defp drain_shell(acc) do
    receive do
      {:mix_shell, :info, [msg]} -> drain_shell([msg | acc])
    after
      0 -> acc |> Enum.reverse() |> Enum.join("\n")
    end
  end

  defp generated(tmp) do
    tmp
    |> Path.join("**/*.exs")
    |> Path.wildcard()
    |> Enum.filter(fn file -> Enum.any?(@suffixes, &String.ends_with?(file, &1)) end)
  end

  test "an unconfigured new install is told to delete the migrations it just wrote before re-running",
       %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)

    output = run_install(tmp)
    files = generated(tmp)

    assert length(files) == 3

    for file <- files do
      relative = Path.relative_to(file, tmp)

      assert String.contains?(output, relative),
             "the storage-schema advice must name #{relative}, which this run generated into " <>
               "`public` — re-running without deleting it keeps the `public` migration while " <>
               "the config points at the dedicated schema"
    end

    assert output =~ "Delete the migration files this run just generated"
    assert output =~ ~s(config :threadline, storage_schema: "threadline")

    # The advice follows generation, so it can name what was actually written.
    {advice_at, _} = :binary.match(output, "No `:storage_schema` is configured")
    {created_at, _} = :binary.match(output, "creating")
    assert created_at < advice_at
  end

  test "following the advice produces migrations that target the dedicated schema", %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)
    run_install(tmp)

    Enum.each(generated(tmp), &File.rm!/1)

    Application.put_env(:threadline, :storage_schema, "threadline")
    output = run_install(tmp)
    files = generated(tmp)

    assert length(files) == 3
    refute output =~ "No `:storage_schema` is configured"

    audit = Enum.find(files, &String.ends_with?(&1, "_threadline_audit_schema.exs"))
    assert File.read!(audit) =~ ~s("threadline")
  end

  test "a re-run over an existing install skips every migration and gives no schema advice",
       %{tmp: tmp} do
    Application.delete_env(:threadline, :storage_schema)
    run_install(tmp)
    before = generated(tmp)

    output = run_install(tmp)

    assert generated(tmp) == before
    assert output =~ "already exists — skipping"
    refute output =~ "No `:storage_schema` is configured"
    refute output =~ "Run `mix ecto.migrate`"
  end

  test "a configured install gets no schema advice", %{tmp: tmp} do
    Application.put_env(:threadline, :storage_schema, "threadline")

    output = run_install(tmp)

    assert length(generated(tmp)) == 3
    refute output =~ "No `:storage_schema` is configured"
  end
end
