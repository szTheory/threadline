defmodule Threadline.Test.OperatorSurfaceFixtures do
  @moduledoc false

  @root Path.expand("../fixtures/operator_surface", __DIR__)
  @recovery_command "mix test test/threadline/operator_surface/stress_ledger_test.exs"

  def root!, do: required_directory!(@root, "operator-surface fixture corpus")

  def ledger! do
    root!()
    |> Path.join("design-system-ledger.json")
    |> required_file!("design-system ledger")
  end

  defp required_file!(path, dataset) do
    if File.regular?(path), do: path, else: unavailable!(path, dataset, "file")
  end

  defp required_directory!(path, dataset) do
    if File.dir?(path), do: path, else: unavailable!(path, dataset, "directory")
  end

  defp unavailable!(path, dataset, kind) do
    raise ArgumentError, """
    Required #{dataset} #{kind} is unavailable.
    Resolved path: #{Path.expand(path)}
    Repository-only: true
    Recovery: #{@recovery_command}
    """
  end
end
