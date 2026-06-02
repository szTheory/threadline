defmodule Threadline.OperatorSurface.Presentation do
  @moduledoc false

  @month_names ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)

  @spec human_time(DateTime.t() | nil, keyword()) :: String.t()
  def human_time(value, opts \\ [])
  def human_time(nil, opts), do: Keyword.get(opts, :empty, "Not recorded")

  def human_time(%DateTime{} = dt, opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    dt = DateTime.shift_zone!(dt, "Etc/UTC")

    date_label =
      cond do
        Date.compare(DateTime.to_date(dt), DateTime.to_date(now)) == :eq ->
          "Today"

        dt.year == now.year ->
          "#{month_name(dt.month)} #{dt.day}"

        true ->
          "#{month_name(dt.month)} #{dt.day}, #{dt.year}"
      end

    "#{date_label}, #{clock(dt)} UTC"
  end

  @spec exact_time(DateTime.t() | nil) :: String.t()
  def exact_time(nil), do: ""
  def exact_time(%DateTime{} = dt), do: DateTime.to_iso8601(dt)

  @spec checked_label(DateTime.t() | nil) :: String.t()
  def checked_label(nil), do: "Not checked yet"

  def checked_label(%DateTime{} = ts) do
    seconds = max(DateTime.diff(DateTime.utc_now(), ts, :second), 0)

    cond do
      seconds < 5 -> "Checked just now"
      seconds < 60 -> "Checked #{seconds}s ago"
      seconds < 3_600 -> "Checked #{div(seconds, 60)}m ago"
      true -> "Checked #{div(seconds, 3_600)}h ago"
    end
  end

  @spec short_id(term(), pos_integer()) :: String.t()
  def short_id(value, max_length \\ 12) do
    value = to_string(value || "")

    if String.length(value) <= max_length do
      value
    else
      String.slice(value, 0, max_length)
    end
  end

  @spec truncate_middle(term(), pos_integer()) :: String.t()
  def truncate_middle(value, max_length \\ 34) do
    value = to_string(value || "")

    if String.length(value) <= max_length do
      value
    else
      keep = max(div(max_length - 3, 2), 4)
      String.slice(value, 0, keep) <> "..." <> String.slice(value, -keep, keep)
    end
  end

  @spec status_modifier(String.t() | atom() | nil) :: String.t()
  def status_modifier(status) do
    case normalize_status(status) do
      status when status in ~w(completed covered proven configured config_matches_deployed) ->
        "tl-chip--success"

      status when status in ~w(failed error uncovered unsupported invalid) ->
        "tl-chip--danger"

      status when status in ~w(drift_detected could_not_introspect stale expired) ->
        "tl-chip--warning"

      status when status in ~w(pending running queued processing inferred_posture) ->
        "tl-chip--info"

      _ ->
        "tl-chip--neutral"
    end
  end

  @spec status_label(String.t() | atom() | nil) :: String.t()
  def status_label(status) do
    case normalize_status(status) do
      "inferred_posture" -> "Inferred"
      "config_matches_deployed" -> "Deployed matches config"
      "could_not_introspect" -> "Could not introspect"
      "drift_detected" -> "Drift detected"
      "expected_uncovered" -> "Expected gap"
      "uncovered" -> "Needs capture"
      "covered" -> "Captured"
      "completed" -> "Completed"
      "failed" -> "Failed"
      "pending" -> "Queued"
      "running" -> "Running"
      "proven" -> "Proven"
      "unsupported" -> "Unsupported"
      nil -> "Unknown"
      "" -> "Unknown"
      other -> other |> String.replace("_", " ") |> String.capitalize()
    end
  end

  @spec query_pairs(map() | nil) :: [{String.t(), String.t()}]
  def query_pairs(nil), do: []

  def query_pairs(params) when is_map(params) do
    params
    |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
    |> Enum.reject(fn {_key, value} -> value == "" end)
    |> Enum.sort_by(fn {key, _value} -> filter_rank(key) end)
  end

  @spec export_summary(map() | nil) :: String.t()
  def export_summary(params) when is_map(params) do
    pairs = query_pairs(params)

    cond do
      table = params["table"] || params[:table] ->
        "#{table} export"

      correlation = params["correlation_id"] || params[:correlation_id] ->
        "Timeline export for #{truncate_middle(correlation, 28)}"

      pairs == [] ->
        "Full timeline export"

      true ->
        "Filtered timeline export"
    end
  end

  def export_summary(_), do: "Timeline export"

  defp normalize_status(nil), do: nil
  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status
  defp normalize_status(status), do: to_string(status)

  defp filter_rank("table"), do: {0, "table"}
  defp filter_rank("correlation_id"), do: {1, "correlation_id"}
  defp filter_rank("actor_kind"), do: {2, "actor_kind"}
  defp filter_rank("actor_id"), do: {3, "actor_id"}
  defp filter_rank("from"), do: {4, "from"}
  defp filter_rank("to"), do: {5, "to"}
  defp filter_rank(key), do: {9, key}

  defp month_name(month), do: Enum.at(@month_names, month - 1)

  defp clock(%DateTime{} = dt) do
    hour = rem(dt.hour + 11, 12) + 1
    suffix = if dt.hour < 12, do: "AM", else: "PM"
    minute = dt.minute |> Integer.to_string() |> String.pad_leading(2, "0")
    "#{hour}:#{minute} #{suffix}"
  end
end
