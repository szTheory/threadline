defmodule Threadline.OperatorSurface.Unsupported do
  @moduledoc false

  @generic_export_fallback "mix threadline.export --dry-run"

  @descriptors %{
    coverage_unavailable: %{
      title: "Coverage unavailable",
      body:
        "Coverage is unavailable in this support lane. This is not a permissions issue. Run the coverage check from the host app.",
      fallback_label: "Try instead",
      fallback_value: "mix threadline.health.coverage",
      fallback_kind: :generic
    },
    policy_redaction_unavailable: %{
      title: "Redaction policy unavailable",
      body:
        "Redaction policy status is unavailable in this support lane. This is not a permissions issue. Run the policy command from the host app.",
      fallback_label: "Try instead",
      fallback_value: "mix threadline.policy.show",
      fallback_kind: :generic
    },
    evidence_unavailable: %{
      title: "Evidence unavailable",
      body:
        "Evidence is unavailable in this support lane. This is not a permissions issue. Use mix threadline.evidence.show or the Threadline.Evidence API instead.",
      fallback_label: "Try instead",
      fallback_value: "mix threadline.evidence.show",
      fallback_kind: :generic
    },
    retention_unavailable: %{
      title: "Retention history unavailable",
      body:
        "Retention history is unavailable in this support lane. This is not a permissions issue. Run the retention command from the host app.",
      fallback_label: "Try instead",
      fallback_value: "mix threadline.retention.purge --dry-run",
      fallback_kind: :operational
    }
  }

  def descriptor(key) when is_atom(key) do
    Map.fetch!(@descriptors, key)
  end

  def export_denied_descriptor(params \\ %{}) do
    params = stringify_keys(params)
    exact_filters = exact_export_filters(params)

    %{
      title: "Export access needed",
      body:
        "You do not have access to exports. The export surface exists; your account needs `export_authorize_fn` approval.",
      fallback_label: "Try instead",
      fallback_value: export_fallback_command(exact_filters),
      fallback_kind: if(exact_filters == :generic, do: :generic, else: :exact)
    }
  end

  defp export_fallback_command(:generic), do: @generic_export_fallback

  defp export_fallback_command(filters) when is_list(filters) do
    Enum.reduce(filters, @generic_export_fallback, fn {flag, value}, command ->
      command <> " " <> flag <> " " <> shell_escape(value)
    end)
  end

  defp exact_export_filters(params) do
    normalized =
      params
      |> Map.take(~w(table from to actor_kind actor_id correlation_id))
      |> Enum.reject(fn {_key, value} -> blank?(value) end)
      |> Map.new()

    allowed_keys = ~w(table from to)
    keys = Map.keys(normalized)

    cond do
      normalized == %{} ->
        :generic

      Enum.any?(keys, &(&1 not in allowed_keys)) ->
        :generic

      partial_range?(normalized) ->
        :generic

      true ->
        build_exact_filters(normalized)
    end
  end

  defp build_exact_filters(filters) do
    []
    |> maybe_put_flag("--table", filters["table"])
    |> maybe_put_flag("--from", filters["from"])
    |> maybe_put_flag("--to", filters["to"])
  end

  defp maybe_put_flag(filters, _flag, value) when value in [nil, ""], do: filters
  defp maybe_put_flag(filters, flag, value), do: filters ++ [{flag, value}]

  defp partial_range?(filters) do
    blank?(filters["from"]) != blank?(filters["to"])
  end

  defp stringify_keys(params) when is_map(params) do
    Map.new(params, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp blank?(value), do: value in [nil, ""]

  defp shell_escape(value) do
    escaped = String.replace(to_string(value), "'", "'\"'\"'")
    "'" <> escaped <> "'"
  end
end
