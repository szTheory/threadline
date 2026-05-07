defmodule Mix.Tasks.Threadline.Policy.Show do
  @shortdoc "Show configured versus deployed redaction policy drift"

  @moduledoc """
  Shows configured versus deployed redaction policy drift for Threadline capture
  triggers, using the shared `Threadline.Policy.RedactionPresenter`.

  Unlike CI-gate tasks, this viewer ALWAYS exits 0 when drift is detected.

  ## Usage

      mix threadline.policy.show
      mix threadline.policy.show --json

  Default output prints one summary line, one aligned table, and detail blocks
  only for `Drift detected` and `Could not introspect` rows.

  `--json` emits a stable top-level object with summary fields plus a `tables`
  array. Status values are machine-stable strings:

    * `config_matches_deployed`
    * `drift_detected`
    * `could_not_introspect`
  """

  use Mix.Task

  alias Threadline.Policy.RedactionPresenter

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [json: :boolean])
    json? = Keyword.get(opts, :json, false)

    Mix.Task.run("app.config", [])
    {:ok, _} = Application.ensure_all_started(:ssl)
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto_sql)

    repo = resolve_repo!()
    ensure_repo_started!(repo)

    report = RedactionPresenter.build(repo: repo, schema: "public")

    if json? do
      render_json(report)
    else
      render_human(report)
    end

    :ok
  end

  defp resolve_repo! do
    case Application.get_env(:threadline, :ecto_repos, []) do
      [] ->
        Mix.raise(
          "Threadline: set :ecto_repos in config — no Ecto repository is configured to run threadline.policy.show."
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

  defp render_human(report) do
    Mix.shell().info(summary_line(report.summary))
    Mix.shell().info("")

    rows =
      Enum.map(report.tables, fn row ->
        [
          row.table,
          status_label(row.status),
          policy_cell(row.configured),
          deployed_cell(row.deployed),
          row.hint
        ]
      end)

    widths = column_widths([["TABLE", "STATUS", "CONFIG", "DEPLOYED", "HINT"] | rows])

    write_row(["TABLE", "STATUS", "CONFIG", "DEPLOYED", "HINT"], widths)
    Mix.shell().info(rule(widths))
    Enum.each(rows, &write_row(&1, widths))

    detail_rows =
      Enum.filter(report.tables, fn row ->
        row.status in [:drift_detected, :could_not_introspect]
      end)

    Enum.each(detail_rows, fn row ->
      Mix.shell().info("")
      Mix.shell().info("DETAILS #{row.table}")
      Mix.shell().info("  Status: #{status_label(row.status)}")
      Mix.shell().info("  Config: #{policy_cell(row.configured)}")
      Mix.shell().info("  Deployed: #{deployed_cell(row.deployed)}")

      diff_line = diff_summary(row.diff)

      if diff_line != "" do
        Mix.shell().info("  Diff: #{diff_line}")
      end

      if row.warning do
        Mix.shell().info("  Warning: #{row.warning}")
      end

      Mix.shell().info("  Hint: #{row.hint}")
    end)
  end

  defp render_json(report) do
    payload = %{
      "schema" => "public",
      "total_tables" => length(report.tables),
      "drift_detected" => report.summary.drift_detected,
      "could_not_introspect" => report.summary.could_not_introspect,
      "config_matches_deployed" => report.summary.config_matches_deployed,
      "tables" => Enum.map(report.tables, &json_row/1)
    }

    IO.puts(Jason.encode!(payload))
  end

  defp summary_line(summary) do
    "Policy drift: #{summary.drift_detected} drift detected, " <>
      "#{summary.could_not_introspect} could not introspect, " <>
      "#{summary.config_matches_deployed} config matches deployed"
  end

  defp status_label(:config_matches_deployed), do: "Config matches deployed"
  defp status_label(:drift_detected), do: "Drift detected"
  defp status_label(:could_not_introspect), do: "Could not introspect"

  defp status_key(status), do: status |> Atom.to_string()

  defp deployed_cell(nil), do: "unavailable"
  defp deployed_cell(policy), do: policy_cell(policy)

  defp list_literal(items) do
    "[" <> Enum.join(items, ",") <> "]"
  end

  defp column_widths(rows) do
    rows
    |> Enum.zip_with(fn column -> column |> Enum.map(&String.length/1) |> Enum.max() end)
  end

  defp write_row(cells, widths) do
    cells
    |> Enum.zip(widths)
    |> Enum.map_join("  ", fn {cell, width} -> String.pad_trailing(cell, width) end)
    |> Mix.shell().info()
  end

  defp rule(widths) do
    widths
    |> Enum.map(&String.duplicate("-", &1))
    |> Enum.join("  ")
  end

  defp diff_summary(diff) do
    []
    |> maybe_add_diff("exclude_only_in_config", diff.exclude_only_in_config)
    |> maybe_add_diff("exclude_only_in_deployed", diff.exclude_only_in_deployed)
    |> maybe_add_diff("mask_only_in_config", diff.mask_only_in_config)
    |> maybe_add_diff("mask_only_in_deployed", diff.mask_only_in_deployed)
    |> maybe_add_flag("placeholder_mismatch", diff.placeholder_mismatch)
    |> Enum.join("; ")
  end

  defp maybe_add_diff(parts, _label, []), do: parts
  defp maybe_add_diff(parts, label, items), do: parts ++ ["#{label}=#{list_literal(items)}"]

  defp maybe_add_flag(parts, _label, false), do: parts
  defp maybe_add_flag(parts, label, true), do: parts ++ [label]

  defp json_row(row) do
    %{
      "table" => row.table,
      "status" => status_key(row.status),
      "configured" => json_policy(row.configured),
      "deployed" => json_policy_or_nil(row.deployed),
      "diff" => %{
        "exclude_only_in_config" => row.diff.exclude_only_in_config,
        "exclude_only_in_deployed" => row.diff.exclude_only_in_deployed,
        "mask_only_in_config" => row.diff.mask_only_in_config,
        "mask_only_in_deployed" => row.diff.mask_only_in_deployed,
        "placeholder_mismatch" => row.diff.placeholder_mismatch
      },
      "warning" => row.warning,
      "hint" => row.hint
    }
  end

  defp json_policy(policy) do
    %{
      "exclude" => policy.exclude,
      "mask" => policy.mask,
      "mask_placeholder" => policy.mask_placeholder
    }
  end

  defp json_policy_or_nil(nil), do: nil
  defp json_policy_or_nil(policy), do: json_policy(policy)

  defp maybe_append_placeholder(parts, [], _placeholder), do: parts
  defp maybe_append_placeholder(parts, _mask, placeholder), do: parts ++ ["placeholder=#{placeholder}"]

  defp policy_cell(%{exclude: exclude, mask: mask, mask_placeholder: placeholder}) do
    []
    |> Kernel.++(["exclude=#{list_literal(exclude)}", "mask=#{list_literal(mask)}"])
    |> maybe_append_placeholder(mask, placeholder)
    |> Enum.join(" ")
  end
end
