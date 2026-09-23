if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive.Helpers do
    @moduledoc false

    alias Threadline.OperatorSurface.Presentation

    @default_window_hours 24

    @doc false
    def default_window_hours, do: @default_window_hours

    @doc false
    def actor_label(%{transaction: %{actor_ref: %{type: type, id: id}}}) when not is_nil(id),
      do: "#{type}/#{id}"

    def actor_label(%{transaction: %{actor_ref: %{"type" => type, "id" => id}}})
        when not is_nil(id),
        do: "#{type}/#{id}"

    def actor_label(_), do: "unknown"

    @doc false
    def actor_path(base_path, change) when is_binary(base_path) do
      case actor_ref(change) do
        {type, id} when is_binary(type) and is_binary(id) and id != "" ->
          "#{base_path}/actors/#{URI.encode_www_form(type)}/#{URI.encode_www_form(id)}"

        _ ->
          nil
      end
    end

    def actor_path(_base_path, _change), do: nil

    defp actor_ref(%{transaction: %{actor_ref: %{type: type, id: id}}}) when not is_nil(id),
      do: {to_string(type), to_string(id)}

    defp actor_ref(%{transaction: %{actor_ref: %{"type" => type, "id" => id}}})
         when not is_nil(id),
         do: {to_string(type), to_string(id)}

    defp actor_ref(_), do: nil

    @doc false
    def correlation_id(%{transaction: %{action: %{correlation_id: correlation_id}}})
        when is_binary(correlation_id) and correlation_id != "",
        do: correlation_id

    def correlation_id(_), do: nil

    @doc false
    def correlation_path(base_path, correlation_id) when is_binary(correlation_id) do
      "#{base_path}?#{URI.encode_query(%{"correlation_id" => correlation_id})}"
    end

    def correlation_path(base_path, _correlation_id), do: base_path

    @doc false
    def table_ref(%{table_name: table_name}), do: Presentation.secondary_ref(table_name, 30)
    def table_ref(_change), do: Presentation.secondary_ref("", 30)

    @doc false
    def routeable_row_ref(change) do
      case routeable_row_identity(change) do
        {_table, record_id} -> record_id
        nil -> nil
      end
    end

    @doc false
    def safe_row_history_path(base_path, change, schemas)
        when is_binary(base_path) and is_map(schemas) do
      with {table, record_id} <- routeable_row_identity(change),
           route_table when is_binary(route_table) <-
             row_history_route_table(schemas, table, host_table_schema(change)) do
        "#{base_path}/rows/#{encode_segment(route_table)}/#{encode_segment(record_id)}"
      else
        _ ->
          nil
      end
    end

    def safe_row_history_path(_base_path, _change, _schemas), do: nil

    defp row_history_route_table(schemas, table, table_schema) when is_map(schemas) do
      schema = normalize_host_table_schema(table_schema)
      table = String.trim(table)

      case row_history_schema_for_table(schemas, table, schema) do
        nil -> nil
        _schema -> row_history_table_identity(table, schema)
      end
    end

    defp row_history_schema_for_table(_schemas, "", _schema), do: nil

    defp row_history_schema_for_table(schemas, table, "public") do
      schema_for_public_table(schemas, table)
    end

    defp row_history_schema_for_table(schemas, table, schema) do
      Map.get(schemas, "#{schema}.#{table}")
    end

    defp row_history_table_identity(table, "public"), do: table
    defp row_history_table_identity(table, schema), do: "#{schema}.#{table}"

    defp schema_for_public_table(schemas, table) when is_map(schemas) do
      case Map.fetch(schemas, table) do
        {:ok, schema} ->
          schema

        :error ->
          Enum.find_value(schemas, fn
            {key, schema} when is_atom(key) ->
              # Structural debt: if inside find_value fn inside case — extract the key matcher
              # credo:disable-for-next-line Credo.Check.Refactor.Nesting
              if Atom.to_string(key) == table, do: schema

            _entry ->
              nil
          end)
      end
    end

    defp host_table_schema(%{table_schema: table_schema}),
      do: normalize_host_table_schema(table_schema)

    defp host_table_schema(%{change_diff: %{} = diff}) do
      diff
      |> Map.get("table_schema", Map.get(diff, :table_schema))
      |> normalize_host_table_schema()
    end

    defp host_table_schema(_change), do: "public"

    defp normalize_host_table_schema(schema) when is_binary(schema) do
      case String.trim(schema) do
        "" -> "public"
        value -> value
      end
    end

    defp normalize_host_table_schema(_schema), do: "public"

    defp routeable_row_identity(%{table_name: table, table_pk: table_pk}),
      do: routeable_row_identity(table, table_pk)

    defp routeable_row_identity(%{change_diff: %{} = diff}) do
      table = Map.get(diff, "table_name") || Map.get(diff, :table_name)
      table_pk = Map.get(diff, "table_pk") || Map.get(diff, :table_pk)

      routeable_row_identity(table, table_pk)
    end

    defp routeable_row_identity(_change), do: nil

    defp routeable_row_identity(table, %{} = table_pk) when is_binary(table) do
      table = String.trim(table)

      with true <- table != "",
           [{_key, value}] <- Map.to_list(table_pk),
           true <- routeable_row_value?(value) do
        {table, to_string(value)}
      else
        _ -> nil
      end
    end

    defp routeable_row_identity(_table, _table_pk), do: nil

    defp routeable_row_value?(value) when is_binary(value), do: String.trim(value) != ""
    defp routeable_row_value?(value) when is_integer(value), do: true
    defp routeable_row_value?(value) when is_float(value), do: true
    defp routeable_row_value?(_value), do: false

    defp encode_segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

    # Renders the match count for the status line:
    # - At/above the cap (10_001) → "10,000+" so the UI does not imply an exact count
    # - Below the cap → exact integer with thousands separators
    @doc false
    def format_count(count) when is_integer(count) do
      if count >= 10_001 do
        "10,000+"
      else
        count
        |> Integer.to_string()
        |> String.reverse()
        |> String.codepoints()
        |> Enum.chunk_every(3)
        |> Enum.map_join(",", &Enum.join/1)
        |> String.reverse()
      end
    end

    @doc false
    def filter_window_summary(%{} = raw) do
      from_raw = Map.get(raw, "from", "")
      to_raw = Map.get(raw, "to", "")

      with {:ok, %DateTime{} = from} <- parse_window_datetime(from_raw),
           {:ok, %DateTime{} = to} <- parse_window_datetime(to_raw) do
        detail = "#{format_window_datetime(from)} to #{format_window_datetime(to)}"

        %{
          label: window_duration_label(from, to),
          detail: detail,
          title: detail
        }
      else
        {:ok, nil} ->
          partial_window_summary(from_raw, to_raw)

        {:error, _reason} ->
          %{
            label: "Custom",
            detail: "Invalid date value",
            title: "Invalid date value"
          }
      end
    end

    def filter_window_summary(_), do: default_window_summary()

    @doc false
    def active_filter_pairs(%{} = raw) do
      raw
      |> Map.take(["table", "table_schema", "actor_kind", "actor_id", "correlation_id"])
      |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
      |> Enum.map(fn {key, value} -> {filter_label(key), value} end)
    end

    def active_filter_pairs(_), do: []

    @doc false
    def advanced_filter_count(%{} = raw) do
      raw
      |> Map.take(["table_schema", "actor_kind", "actor_id"])
      |> Enum.count(fn {_key, value} -> is_binary(value) and value != "" end)
    end

    def advanced_filter_count(_), do: 0

    defp parse_window_datetime(value) when value in [nil, ""], do: {:ok, nil}

    defp parse_window_datetime(value) when is_binary(value) do
      padded =
        cond do
          String.ends_with?(value, "Z") -> value
          String.length(value) == 16 -> value <> ":00Z"
          String.length(value) == 19 -> value <> "Z"
          true -> value
        end

      case DateTime.from_iso8601(padded) do
        {:ok, dt, _offset} -> {:ok, dt}
        _ -> {:error, :invalid_datetime}
      end
    end

    defp parse_window_datetime(_), do: {:error, :invalid_datetime}

    defp partial_window_summary("", ""), do: default_window_summary()

    defp partial_window_summary(from_raw, "") when is_binary(from_raw) do
      case parse_window_datetime(from_raw) do
        {:ok, %DateTime{} = from} ->
          detail = "From #{format_window_datetime(from)}"
          %{label: "From", detail: detail, title: detail}

        _ ->
          %{label: "Custom", detail: "Invalid date value", title: "Invalid date value"}
      end
    end

    defp partial_window_summary("", to_raw) when is_binary(to_raw) do
      case parse_window_datetime(to_raw) do
        {:ok, %DateTime{} = to} ->
          detail = "Until #{format_window_datetime(to)}"
          %{label: "Until", detail: detail, title: detail}

        _ ->
          %{label: "Custom", detail: "Invalid date value", title: "Invalid date value"}
      end
    end

    defp partial_window_summary(_from_raw, _to_raw),
      do: %{label: "Custom", detail: "Invalid date value", title: "Invalid date value"}

    defp default_window_summary do
      %{
        label: "Last 24h",
        detail: "Default rolling window",
        title: "Default rolling 24 hour window"
      }
    end

    defp window_duration_label(%DateTime{} = from, %DateTime{} = to) do
      seconds = DateTime.diff(to, from, :second)

      cond do
        seconds == @default_window_hours * 3600 ->
          "24h"

        seconds > 0 and rem(seconds, 86_400) == 0 and seconds <= 86_400 * 14 ->
          "#{div(seconds, 86_400)}d"

        seconds > 0 and rem(seconds, 3600) == 0 and seconds < 86_400 ->
          "#{div(seconds, 3600)}h"

        true ->
          "Custom"
      end
    end

    defp format_window_datetime(%DateTime{} = dt) do
      "#{dt.year}-#{pad2(dt.month)}-#{pad2(dt.day)} #{pad2(dt.hour)}:#{pad2(dt.minute)} UTC"
    end

    defp pad2(value) when is_integer(value) and value < 10, do: "0#{value}"
    defp pad2(value) when is_integer(value), do: Integer.to_string(value)

    defp filter_label("table_schema"), do: "host schema"
    defp filter_label("actor_kind"), do: "actor kind"
    defp filter_label("actor_id"), do: "actor id"
    defp filter_label("correlation_id"), do: "correlation id"
    defp filter_label(key), do: key

    @doc false
    def invalid_filter_message(message) do
      target = invalid_filter_target(message)

      "Timeline filters could not be applied. Fix the #{target} filter, then apply filters again. #{message}"
    end

    defp invalid_filter_target(message) when is_binary(message) do
      cond do
        String.contains?(message, "correlation_id") -> "correlation id"
        String.contains?(message, "actor_kind") -> "actor kind"
        String.contains?(message, "actor_id") -> "actor id"
        String.contains?(message, "table_schema") -> "host schema"
        String.contains?(message, "table") -> "table"
        String.contains?(message, "from") or String.contains?(message, "to") -> "time window"
        true -> "named"
      end
    end

    defp invalid_filter_target(_message), do: "named"

    @doc false
    def unknown_table_message(table, audited_tables) do
      table_name =
        table
        |> to_string()
        |> String.trim()
        |> case do
          "" -> "selected table"
          value -> value
        end

      base =
        "Table filter `#{table_name}` is not audited. Select an audited table or clear the table filter."

      case audited_tables do
        [] -> base
        tables -> base <> " Audited tables: " <> Enum.join(tables, ", ")
      end
    end

    # Distinguish the two successful empty states: a first-run empty (no narrowing
    # filter beyond the time window) is `never` (history icon); a filtered-but-empty
    # result is `no_data` (funnel icon). AsyncResult/empty cannot make this call —
    # the page author branches it from whether a narrowing filter is active.
    @timeline_narrowing_filters ~w(table table_schema actor_kind actor_id correlation_id)

    defp timeline_filters_active?(%{} = raw) do
      Enum.any?(@timeline_narrowing_filters, fn key ->
        value = Map.get(raw, key)
        is_binary(value) and String.trim(value) != ""
      end)
    end

    defp timeline_filters_active?(_), do: false

    defp timeline_empty_reason(_raw, true), do: :future_window

    defp timeline_empty_reason(raw, false),
      do: if(timeline_filters_active?(raw), do: :filtered, else: :first_run)

    @doc false
    def timeline_empty_variant(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :filtered -> "no_data"
        _ -> "never"
      end
    end

    @doc false
    def timeline_empty_icon(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :filtered -> :funnel
        _ -> :history
      end
    end

    @doc false
    def timeline_empty_title(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :future_window -> "No captured changes in this time window"
        :first_run -> "No captured changes in this window"
        :filtered -> "No captured changes match this window"
      end
    end

    @doc false
    def timeline_empty_body(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :future_window ->
          "This window has no matching changes, but Threadline has audit data outside it. Move the window back toward recent activity or clear filters."

        :first_run ->
          "No audit changes were captured in this window. Reset to last 24h or widen the time range."

        :filtered ->
          "Widen the time range, or clear the table filter to search every audited table. Scoped views only show records you are authorized to see."
      end
    end

    @doc false
    def timeline_empty_action_label(raw, future_window_empty) do
      case timeline_empty_reason(raw, future_window_empty) do
        :first_run -> "Reset to last 24h"
        _ -> "Clear filters"
      end
    end

    @doc false
    def coverage_warning?(%{uncovered_count: count}) when is_integer(count), do: count > 0
    def coverage_warning?(_), do: false

    @doc false
    def coverage_summary(%{uncovered_count: count}) when is_integer(count) and count > 0 do
      "#{count} need capture"
    end

    def coverage_summary(%{uncovered_count: 0}), do: "All captured"
    def coverage_summary(_), do: "Not enabled"

    @doc false
    def op_row_modifier(op) do
      case op |> to_string() |> String.downcase() do
        "insert" -> "tl-change--insert"
        "update" -> "tl-change--update"
        "delete" -> "tl-change--delete"
        _ -> nil
      end
    end
  end
end
