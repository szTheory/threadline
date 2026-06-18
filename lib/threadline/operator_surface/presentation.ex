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
  @spec truncate_middle(term(), pos_integer(), keyword()) :: String.t()
  def truncate_middle(value, max_length \\ 34, opts \\ []) do
    value = to_string(value || "")

    if String.length(value) <= max_length do
      value
    else
      # Backward-compatible default split (unchanged when :tail_min is absent).
      default_keep = max(div(max_length - 3, 2), 4)
      tail_min = Keyword.get(opts, :tail_min)

      # When :tail_min is requested, guarantee at least that many trailing chars
      # of the ORIGINAL value survive verbatim (the forensic discriminating tail).
      tail = if tail_min, do: max(default_keep, tail_min), else: default_keep
      head = default_keep

      String.slice(value, 0, head) <> "..." <> String.slice(value, -tail, tail)
    end
  end

  @spec ref(term(), keyword()) :: %{visible: String.t(), title: String.t(), full: String.t()}
  def ref(value, opts \\ []) do
    full = secondary_ref_value(value)

    %{
      visible: truncate_for(full, opts),
      title: full,
      full: full
    }
  end

  # Per-kind truncation (DATA-01, D-03). All rules guarantee the discriminating
  # tail survives; :timestamp is never truncated.
  defp truncate_for(full, opts) do
    case Keyword.get(opts, :kind) do
      :timestamp ->
        full

      :hash ->
        truncate_middle(full, 24, tail_min: 8)

      :path ->
        truncate_tail(full, 42)

      :email ->
        truncate_email(full, 42)

      :url ->
        truncate_url(full)

      kind when kind in [:arn, :actor] ->
        truncate_middle(full, 34, tail_min: 12)

      _ ->
        # uuid / correlation / default
        truncate_middle(full, 34, tail_min: 8)
    end
  end

  # Keep the trailing `max` characters (filename / last-segment tail).
  defp truncate_tail(value, max) do
    value = to_string(value || "")

    if String.length(value) <= max do
      value
    else
      "..." <> String.slice(value, -max, max)
    end
  end

  # Truncate the localpart but keep the full domain verbatim.
  defp truncate_email(value, max) do
    value = to_string(value || "")

    case String.split(value, "@", parts: 2) do
      [local, domain] ->
        if String.length(value) <= max do
          value
        else
          budget = max(max - String.length(domain) - 4, 4)
          head = String.slice(local, 0, budget)
          head <> "...@" <> domain
        end

      _ ->
        truncate_middle(value, max, tail_min: 8)
    end
  end

  # Keep scheme+host head and the last path segment tail.
  defp truncate_url(value) do
    value = to_string(value || "")

    case URI.parse(value) do
      %URI{scheme: scheme, host: host} when is_binary(scheme) and is_binary(host) ->
        head = "#{scheme}://#{host}"
        last_segment = value |> String.split("/") |> List.last() |> to_string()

        cond do
          String.length(value) <= 56 ->
            value

          last_segment == "" ->
            truncate_middle(value, 56, tail_min: 8)

          true ->
            head <> "/..." <> last_segment
        end

      _ ->
        truncate_middle(value, 56, tail_min: 8)
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

  @spec operation_modifier(String.t() | atom() | nil) :: String.t()
  def operation_modifier(operation) do
    case normalize_operation(operation) do
      "insert" -> "tl-change__op--insert"
      "update" -> "tl-change__op--update"
      "delete" -> "tl-change__op--delete"
      _ -> ""
    end
  end

  @spec operation_label(String.t() | atom() | nil) :: String.t()
  def operation_label(operation) do
    case normalize_operation(operation) do
      nil -> "UNKNOWN"
      "" -> "UNKNOWN"
      operation -> String.upcase(operation)
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

  @spec export_readiness(map(), keyword()) ::
          :ready | :preparing | :needs_attention | :unavailable
  def export_readiness(job, opts \\ []) when is_map(job) do
    status = job |> Map.get(:status, Map.get(job, "status")) |> normalize_status()
    file_path = Map.get(job, :file_path, Map.get(job, "file_path"))
    expires_at = Map.get(job, :expires_at, Map.get(job, "expires_at"))

    cond do
      status == "completed" and has_file_path?(file_path) and not expired?(expires_at, opts) ->
        :ready

      status in ~w(pending running queued processing) ->
        :preparing

      status in ~w(failed error) ->
        :needs_attention

      true ->
        :unavailable
    end
  end

  @spec export_readiness_title(map(), keyword()) :: String.t()
  def export_readiness_title(job, opts \\ []) do
    case export_readiness(job, opts) do
      :ready -> "Ready to hand off"
      :preparing -> "Preparing"
      :needs_attention -> "Needs attention"
      :unavailable -> "Unavailable"
    end
  end

  @spec export_readiness_rank(map(), keyword()) :: non_neg_integer()
  def export_readiness_rank(job, opts \\ []) do
    case export_readiness(job, opts) do
      :ready -> 0
      :preparing -> 1
      :needs_attention -> 2
      :unavailable -> 3
    end
  end

  @spec export_downloadable?(map(), keyword()) :: boolean()
  def export_downloadable?(job, opts \\ []), do: export_readiness(job, opts) == :ready

  @spec export_action_label(map(), keyword()) :: String.t()
  def export_action_label(job, opts \\ []) when is_map(job) do
    status = job |> Map.get(:status, Map.get(job, "status")) |> normalize_status()
    expires_at = Map.get(job, :expires_at, Map.get(job, "expires_at"))

    case export_readiness(job, opts) do
      :ready ->
        "Download export"

      :preparing ->
        "Preparing download"

      :needs_attention ->
        "Reopen source search"

      :unavailable ->
        if status == "completed" and expired?(expires_at, opts),
          do: "Export expired",
          else: "File unavailable"
    end
  end

  @spec secondary_ref(term(), pos_integer()) :: %{visible: String.t(), title: String.t()}
  def secondary_ref(value, max_length \\ 34) do
    full = secondary_ref_value(value)

    %{
      visible: truncate_middle(full, max_length),
      title: full
    }
  end

  @spec value_token(term()) :: %{
          required(:text) => String.t(),
          required(:modifier) => String.t(),
          optional(:title) => String.t()
        }
  def value_token(nil), do: %{text: "null", modifier: "tl-value--null"}

  def value_token(%DateTime{} = value) do
    %{
      text: human_time(value),
      title: exact_time(value),
      modifier: "tl-value--time"
    }
  end

  def value_token(value) when is_binary(value) do
    cond do
      value == "[REDACTED]" ->
        %{text: value, modifier: "tl-value--redacted"}

      timestamp = parse_iso8601(value) ->
        value_token(timestamp)

      true ->
        value_token_string(value, "tl-value--string")
    end
  end

  def value_token(value) when is_boolean(value) or is_number(value) do
    %{text: to_string(value), modifier: "tl-value--primitive"}
  end

  def value_token(value) when is_map(value) or is_list(value) do
    value_token_string(deterministic_json(value), "tl-value--json")
  end

  def value_token(value), do: value_token_string(to_string(value), "tl-value--string")

  # DATA-04: truncate long machine values at ~56 chars (tail-safe), keeping the
  # complete value in :title so the rendered copy affordance can recover it.
  @value_token_max 56
  defp value_token_string(value, modifier) do
    if String.length(value) <= @value_token_max do
      %{text: value, modifier: modifier}
    else
      %{
        text: truncate_middle(value, @value_token_max, tail_min: 8),
        title: value,
        modifier: modifier
      }
    end
  end

  @spec change_value_token(map(), String.t() | atom()) :: %{
          required(:text) => String.t(),
          required(:modifier) => String.t(),
          optional(:title) => String.t()
        }
  def change_value_token(field, axis) when is_map(field) do
    case fetch_axis(field, axis) do
      {:ok, value} ->
        value_token(value)

      :error ->
        if normalize_axis(axis) == "before" do
          %{text: "(omitted)", modifier: "tl-value--omitted"}
        else
          %{text: "(absent)", modifier: "tl-value--absent"}
        end
    end
  end

  @spec expected_gap_count_label(non_neg_integer()) :: String.t()
  def expected_gap_count_label(1), do: "1 expected gap"
  def expected_gap_count_label(count), do: "#{count} expected gaps"

  @safe_generator_identifier ~r/\A[a-z_][a-z0-9_]{0,62}\z/

  @spec coverage_remediation(term(), keyword()) :: %{
          label: String.t(),
          command: String.t() | nil,
          follow_up: String.t()
        }
  def coverage_remediation(table_name, opts \\ []) do
    table_name = table_name |> to_string() |> String.trim()
    schema = opts |> Keyword.get(:schema, "public") |> to_string() |> String.trim()

    if schema == "public" and safe_generator_identifier?(table_name) do
      %{
        label: "Add capture",
        command: "mix threadline.gen.triggers --tables #{table_name}",
        follow_up: "Run mix threadline.verify_coverage after applying the migration."
      }
    else
      %{
        label: "Add capture",
        command: nil,
        follow_up:
          "Generate a trigger migration for #{schema}.#{table_name} after confirming the identifier; do not paste an auto-built shell command for this table."
      }
    end
  end

  @spec actor_transaction_summary(nil | [map()]) :: String.t()
  def actor_transaction_summary(nil), do: "Changes unavailable"
  def actor_transaction_summary([]), do: "Changes unavailable"

  def actor_transaction_summary(changes) when is_list(changes) do
    first = List.first(changes)
    op = first |> change_value(:op, "op") |> to_string() |> String.upcase()
    table = first |> change_value(:table_name, "table_name") |> to_string()

    tables =
      changes
      |> Enum.map(fn change -> change_value(change, :table_name, "table_name") end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.uniq()

    change_count =
      changes
      |> Enum.map(&field_change_count/1)
      |> Enum.sum()

    cond do
      op == "" or table == "" ->
        "Changes unavailable"

      length(tables) > 1 ->
        "#{op} #{table} + #{length(tables) - 1} tables - #{change_count} #{change_word(change_count)}"

      true ->
        "#{op} #{table} - #{change_count} #{change_word(change_count)}"
    end
  end

  defp secondary_ref_value(%Threadline.Semantics.ActorRef{type: type, id: id})
       when not is_nil(id),
       do: "#{type}/#{id}"

  defp secondary_ref_value(%{"type" => type, "id" => id}) when not is_nil(id), do: "#{type}/#{id}"
  defp secondary_ref_value(%{} = value), do: Jason.encode!(value)
  defp secondary_ref_value(nil), do: ""
  defp secondary_ref_value(value), do: to_string(value)

  defp has_file_path?(value) when is_binary(value), do: String.trim(value) != ""
  defp has_file_path?(_), do: false

  defp expired?(%DateTime{} = expires_at, opts) do
    now = Keyword.get_lazy(opts, :now, &DateTime.utc_now/0)
    DateTime.compare(expires_at, now) != :gt
  end

  defp expired?(_expires_at, _opts), do: false

  defp normalize_status(nil), do: nil
  defp normalize_status(status) when is_atom(status), do: Atom.to_string(status)
  defp normalize_status(status) when is_binary(status), do: status
  defp normalize_status(status), do: to_string(status)

  defp normalize_operation(nil), do: nil

  defp normalize_operation(operation) when is_atom(operation) do
    operation |> Atom.to_string() |> normalize_operation()
  end

  defp normalize_operation(operation) when is_binary(operation) do
    operation
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_operation(operation), do: operation |> to_string() |> normalize_operation()

  defp parse_iso8601(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} -> dt
      {:error, _reason} -> nil
    end
  end

  defp deterministic_json(value) when is_list(value) do
    "[" <> (value |> Enum.map(&deterministic_json/1) |> Enum.join(",")) <> "]"
  end

  defp deterministic_json(%{} = value) do
    entries =
      value
      |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
      |> Enum.map(fn {key, nested} ->
        Jason.encode!(to_string(key)) <> ":" <> deterministic_json(nested)
      end)

    "{" <> Enum.join(entries, ",") <> "}"
  end

  defp deterministic_json(value), do: Jason.encode!(value)

  defp safe_generator_identifier?(value), do: Regex.match?(@safe_generator_identifier, value)

  defp fetch_axis(field, axis) do
    axis = normalize_axis(axis)
    axis_atom = axis_atom(axis)

    cond do
      Map.has_key?(field, axis) -> {:ok, Map.fetch!(field, axis)}
      axis_atom && Map.has_key?(field, axis_atom) -> {:ok, Map.fetch!(field, axis_atom)}
      true -> :error
    end
  end

  defp normalize_axis(axis) when is_atom(axis), do: Atom.to_string(axis)
  defp normalize_axis(axis), do: to_string(axis)

  defp axis_atom("before"), do: :before
  defp axis_atom("after"), do: :after
  defp axis_atom(_), do: nil

  defp change_value(%{change_diff: %{} = diff}, atom_key, string_key),
    do: change_value(diff, atom_key, string_key)

  defp change_value(%{"change_diff" => %{} = diff}, atom_key, string_key),
    do: change_value(diff, atom_key, string_key)

  defp change_value(%{} = change, atom_key, string_key) do
    Map.get(change, atom_key, Map.get(change, string_key))
  end

  defp change_value(_change, _atom_key, _string_key), do: nil

  defp field_change_count(%{} = change) do
    case change_value(change, :field_changes, "field_changes") do
      values when is_list(values) -> length(values)
      nil -> 0
      _other -> 1
    end
  end

  defp field_change_count(_change), do: 0

  defp change_word(1), do: "change"
  defp change_word(_count), do: "changes"

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
