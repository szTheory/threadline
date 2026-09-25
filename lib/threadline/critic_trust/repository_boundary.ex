defmodule Threadline.CriticTrust.RepositoryBoundary do
  @moduledoc false

  # The repository-only path, decode and atomic-write boundary behind
  # `mix critic.measure`. Every error names the task and keeps its
  # `critic.measure:` prefix, and the atomic-write test hook is read from the
  # task module's Process key, because the task is the public entry point.

  alias Threadline.CriticTrust.Measure

  def project_root! do
    case Mix.Project.project_file() do
      nil ->
        task_error!("no Mix project file is loaded", File.cwd!(), "mix help critic.measure")

      project_file ->
        project_file
        |> Path.expand()
        |> Path.dirname()
    end
  end

  def resolve_repository_root!(path, project_root, dataset) when is_binary(path) do
    expanded = Path.expand(path, project_root)
    canonical_project_root = canonicalize_root!(project_root, "project root")
    canonical_path = canonicalize_root!(expanded, dataset)
    relative = Path.relative_to(canonical_path, canonical_project_root)

    case Path.safe_relative_to(relative, canonical_project_root) do
      {:ok, safe_relative} ->
        Path.join(canonical_project_root, safe_relative)

      :error ->
        task_error!(
          "#{dataset} escapes or aliases the repository",
          expanded,
          "mix help critic.measure"
        )
    end
  end

  defp canonicalize_root!(path, dataset) do
    case System.cmd("realpath", ["--", path], stderr_to_stdout: true) do
      {canonical, 0} ->
        String.trim(canonical)

      {detail, _status} ->
        task_error!(
          "#{dataset} cannot be canonicalized (#{String.trim(detail)})",
          path,
          "mix help critic.measure"
        )
    end
  end

  def validate_root_separation!(fixture_root, output_root) do
    immutable = [
      Path.join(fixture_root, "scorecards"),
      Path.join(fixture_root, "golden"),
      Path.join(fixture_root, "refute"),
      Path.join(fixture_root, "design-system-ledger.json")
    ]

    if output_root == fixture_root or
         Enum.any?(immutable, fn root ->
           within?(output_root, root) or within?(root, output_root)
         end) do
      task_error!(
        "critic-score output root aliases immutable evidence",
        output_root,
        "mix help critic.measure"
      )
    end
  end

  defp within?(candidate, parent) do
    case Path.relative_to(candidate, parent) do
      "." -> true
      ".." -> false
      "../" <> _ -> false
      relative -> Path.type(relative) == :relative
    end
  end

  def require_directory!(path, dataset, recovery) do
    if not File.dir?(path), do: task_error!("#{dataset} is unavailable", path, recovery)
  end

  def read_json_object!(path, dataset, recovery) do
    case path |> read_text!(dataset, recovery) |> Jason.decode() do
      {:ok, decoded} when is_map(decoded) ->
        decoded

      {:ok, _other} ->
        task_error!("#{dataset} is invalid (expected a JSON object)", path, recovery)

      {:error, error} ->
        task_error!("#{dataset} is invalid (#{Exception.message(error)})", path, recovery)
    end
  end

  def read_json_text!(path, dataset, recovery) do
    text = read_text!(path, dataset, recovery)

    case Jason.decode(text) do
      {:ok, decoded} when is_map(decoded) ->
        text

      {:ok, _other} ->
        task_error!("#{dataset} is invalid (expected a JSON object)", path, recovery)

      {:error, error} ->
        task_error!("#{dataset} is invalid (#{Exception.message(error)})", path, recovery)
    end
  end

  def read_text!(path, dataset, recovery) do
    case File.read(path) do
      {:ok, text} ->
        text

      {:error, reason} ->
        task_error!(
          "#{dataset} is unavailable (#{:file.format_error(reason)})",
          path,
          recovery
        )
    end
  end

  def validate_score!(score, path) do
    valid =
      is_binary(score["cell_id"]) and score["cell_id"] != "" and
        score["lens"] in Measure.lenses() and
        score["band"] in ~w(fail weak ok strong exemplary) and
        is_number(score["score"]) and is_boolean(score["stable"]) and
        is_binary(score["model_id"]) and is_binary(score["rubric_version"])

    if not valid, do: task_error!("critic score is invalid", path, "mix verify.ui_critique")
  end

  def validate_golden!(golden, path, recovery) do
    items = Map.get(golden, "items")

    valid = is_list(items) and Enum.all?(items, &valid_golden_item?/1)

    if valid do
      golden
    else
      task_error!("golden oracle schema is invalid", path, recovery)
    end
  end

  defp valid_golden_item?(item) when is_map(item) do
    kind = item["kind"]
    r1 = item["r1"]
    r2 = item["r2"]
    adjudicated = item["adjudicated"]

    is_binary(item["cell_id"]) and item["cell_id"] != "" and
      item["lens"] in Measure.lenses() and kind in ~w(single pair) and
      valid_round_provenance?(r1, kind) and valid_round_provenance?(r2, kind) and
      valid_adjudication?(adjudicated, r1, r2, kind)
  end

  defp valid_golden_item?(_item), do: false

  defp valid_round_provenance?(round, kind) when is_map(round) do
    verdict_valid =
      case kind do
        "single" -> round["verdict"] in ~w(broken bad borderline good) and is_nil(round["margin"])
        "pair" -> round["verdict"] in ~w(better worse) and round["margin"] in ~w(clear subtle)
      end

    verdict_valid and round["blind"] == true and is_binary(round["evidence"]) and
      String.trim(round["evidence"]) != ""
  end

  defp valid_round_provenance?(_round, _kind), do: false

  defp valid_adjudication?(adjudicated, r1, r2, kind) when is_map(adjudicated) do
    source = adjudicated["source"]
    selected = adjudication_source(source, r1, r2)
    source_consistent = adjudication_source_consistent?(source, r1, r2, kind)

    is_map(selected) and source_consistent and adjudicated["verdict"] == selected["verdict"] and
      adjudicated_margin_valid?(adjudicated, selected, kind)
  end

  defp valid_adjudication?(_adjudicated, _r1, _r2, _kind), do: false

  defp adjudication_source("agreement", r1, _r2), do: r1
  defp adjudication_source("r1", r1, _r2), do: r1
  defp adjudication_source("r2", _r1, r2), do: r2
  defp adjudication_source(_other, _r1, _r2), do: nil

  defp adjudication_source_consistent?(source, r1, r2, kind) do
    source != "agreement" or
      (r1["verdict"] == r2["verdict"] and
         (kind != "pair" or r1["margin"] == r2["margin"]))
  end

  defp adjudicated_margin_valid?(adjudicated, selected, kind) do
    case kind do
      "single" -> is_nil(adjudicated["margin"])
      "pair" -> adjudicated["margin"] == selected["margin"]
    end
  end

  def atomic_replace!(target, contents) do
    temp = "#{target}.tmp-#{System.unique_integer([:positive, :monotonic])}"

    case File.open(temp, [:write, :binary, :exclusive]) do
      {:ok, io_device} ->
        result =
          try do
            with :ok <- IO.binwrite(io_device, contents),
                 :ok <- :file.sync(io_device),
                 :ok <- File.close(io_device),
                 :ok <- atomic_write_hook() do
              File.rename(temp, target)
            end
          after
            _ = File.close(io_device)
            _ = File.rm(temp)
          end

        case result do
          :ok ->
            :ok

          {:error, reason} ->
            task_error!(
              "atomic ledger replacement failed (#{inspect(reason)})",
              target,
              restore_command(target)
            )
        end

      {:error, reason} ->
        task_error!(
          "could not create exclusive sibling temp (#{inspect(reason)})",
          target,
          restore_command(target)
        )
    end
  end

  defp atomic_write_hook do
    case Process.get({Mix.Tasks.Critic.Measure, :atomic_write_hook}) do
      hook when is_function(hook, 0) -> hook.()
      _other -> :ok
    end
  end

  def restore_command(path), do: "git restore -- #{Path.relative_to(path, project_root!())}"

  @spec task_error!(String.t(), Path.t(), String.t()) :: no_return()
  def task_error!(message, path, recovery) do
    Mix.raise(
      "critic.measure: #{message}\n" <>
        "resolved path: #{Path.expand(path)}\n" <>
        "repository-only: true\n" <>
        "next: #{recovery}"
    )
  end
end
