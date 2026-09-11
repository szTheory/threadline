defmodule Threadline.Test.OperatorSurfaceFixtures do
  @moduledoc false

  @root Path.expand("../../.planning", __DIR__)
  @recovery_command "mix test test/threadline/operator_surface/stress_ledger_test.exs"

  def root!, do: required_directory!(@root, "operator-surface fixture corpus")

  def ledger! do
    root!()
    |> Path.join("design-system-ledger.json")
    |> required_file!("design-system ledger")
  end

  def scorecards! do
    root!()
    |> Path.join("scorecards")
    |> required_directory!("operator-surface scorecards")
  end

  def golden! do
    root!()
    |> Path.join("golden")
    |> required_directory!("operator-surface golden corpus")
  end

  def refute! do
    root!()
    |> Path.join("refute")
    |> required_directory!("operator-surface refute corpus")
  end

  def critic_scores! do
    root!()
    |> Path.join("critic-scores")
    |> required_directory!("generated critic scores")
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
