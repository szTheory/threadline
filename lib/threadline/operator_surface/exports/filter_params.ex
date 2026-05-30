defmodule Threadline.OperatorSurface.Exports.FilterParams do
  @moduledoc """
  Parses a string-keyed URL params map into a keyword list ready for
  `Threadline.Query.validate_timeline_filters!/1`.

  Used by both `Threadline.OperatorSurface.Live.TimelineLive` (LV-side) and
  `Threadline.OperatorSurface.Controllers.ExportController` (HTTP-side) so
  the two surfaces share one parser — guaranteeing the EXPO-05 byte-equality
  parity test holds for every input edge case (RESEARCH §"Pitfall 3").

  ## Allowed URL keys

      from, to, table, actor_kind, actor_id, correlation_id

  Mapping to filter keys:

  - `from`/`to` — ISO-8601 datetime-local (16-char form `YYYY-MM-DDTHH:MM` is
    padded to `:00Z`; 19-char form `YYYY-MM-DDTHH:MM:SS` is padded to `Z`).
  - `table` — passed through verbatim.
  - `actor_kind` + `actor_id` — collapsed to a single `actor_ref:
    %Threadline.Semantics.ActorRef{}` keyword. `actor_kind=anonymous` strips
    `actor_id`. Other kinds require both fields.
  - `correlation_id` — passed through verbatim.

  ## Atom safety

  `actor_kind` is converted to an atom via `String.to_existing_atom/1` — never
  via the unsafe variant that creates fresh atoms from arbitrary strings. The
  atom table (16 MiB default) is shared process-wide; unfiltered HTTP input
  could otherwise be used to fill it (RESEARCH §"Pitfall 11").
  """

  alias Threadline.Semantics.ActorRef

  # Allowed URL keys mapped to their filter atoms. Declaring the atoms in a
  # compile-time literal here (rather than deriving them at runtime via
  # String.to_existing_atom/1) guarantees they exist no matter which threadline
  # modules have been lazily loaded when a request first hits the timeline — the
  # example app crashed with "not an already existing atom" on
  # `?correlation_id=…` precisely because `:correlation_id` is only created when
  # `Threadline.Query` loads, which happens *after* normalize_params/1 runs.
  # Bounding the conversion to this fixed allowlist also preserves the
  # atom-table-exhaustion guard (Pitfall 11): arbitrary input can never mint a
  # fresh atom.
  @filter_key_atoms %{
    "from" => :from,
    "to" => :to,
    "table" => :table,
    "actor_kind" => :actor_kind,
    "actor_id" => :actor_id,
    "correlation_id" => :correlation_id
  }

  @doc """
  Parses a string-keyed map of URL params into either a validated keyword list
  ready for `Threadline.Query.validate_timeline_filters!/1` (success) or an
  `{:error, message}` tuple (failure — invalid datetime, unknown actor kind,
  or missing actor id).

  Returns `{:ok, []}` for an empty input map (no filters supplied).
  """
  @spec parse(map()) :: {:ok, keyword()} | {:error, String.t()}
  def parse(params) when is_map(params) do
    with normalized <- normalize_params(params),
         {:ok, with_datetimes} <- parse_datetimes(normalized),
         {:ok, with_actor_ref} <- collapse_actor_ref(with_datetimes) do
      {:ok, with_actor_ref}
    end
  end

  @doc """
  Returns a string-keyed `%{key => value}` map suitable for re-rendering the
  filter form on URL paste. Mirrors the `actor_kind=anonymous` strip-id
  normalization so the form echoes the canonical (post-strip) URL.
  """
  @spec filters_raw_from_params(map()) :: %{required(String.t()) => String.t()}
  def filters_raw_from_params(params) when is_map(params) do
    raw = %{
      "from" => params["from"] || "",
      "to" => params["to"] || "",
      "table" => params["table"] || "",
      "actor_kind" => params["actor_kind"] || "",
      "actor_id" => params["actor_id"] || "",
      "correlation_id" => params["correlation_id"] || ""
    }

    case raw["actor_kind"] do
      "anonymous" -> Map.put(raw, "actor_id", "")
      _ -> raw
    end
  end

  # ---- Private helpers (lifted verbatim from timeline_live.ex:282-393) ----

  defp normalize_params(params) do
    for {key, value} <- params,
        is_map_key(@filter_key_atoms, key),
        is_binary(value),
        value != "",
        into: [] do
      {Map.fetch!(@filter_key_atoms, key), value}
    end
  end

  defp parse_datetimes(filters) do
    Enum.reduce_while(filters, {:ok, []}, fn
      {:from, val}, {:ok, acc} ->
        case parse_datetime_local(val) do
          {:ok, nil} -> {:cont, {:ok, acc}}
          {:ok, dt} -> {:cont, {:ok, [{:from, dt} | acc]}}
          {:error, _} -> {:halt, {:error, "invalid datetime: #{val}"}}
        end

      {:to, val}, {:ok, acc} ->
        case parse_datetime_local(val) do
          {:ok, nil} -> {:cont, {:ok, acc}}
          {:ok, dt} -> {:cont, {:ok, [{:to, dt} | acc]}}
          {:error, _} -> {:halt, {:error, "invalid datetime: #{val}"}}
        end

      other, {:ok, acc} ->
        {:cont, {:ok, [other | acc]}}
    end)
    |> case do
      {:ok, filters} -> {:ok, Enum.reverse(filters)}
      error -> error
    end
  end

  defp parse_datetime_local(nil), do: {:ok, nil}
  defp parse_datetime_local(""), do: {:ok, nil}

  defp parse_datetime_local(str) when is_binary(str) do
    padded = if String.length(str) == 16, do: str <> ":00Z", else: str <> "Z"

    case DateTime.from_iso8601(padded) do
      {:ok, dt, _offset} -> {:ok, dt}
      _ -> {:error, :invalid_datetime}
    end
  end

  defp collapse_actor_ref(filters) do
    actor_kind = Keyword.get(filters, :actor_kind)
    actor_id = Keyword.get(filters, :actor_id)

    filters_without_actor_params =
      filters
      |> Keyword.delete(:actor_kind)
      |> Keyword.delete(:actor_id)

    cond do
      actor_kind == "anonymous" ->
        actor_ref = %ActorRef{type: :anonymous, id: nil}
        {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}

      is_binary(actor_kind) and actor_kind != "" and is_binary(actor_id) and actor_id != "" ->
        case safe_actor_kind(actor_kind) do
          {:ok, kind_atom} ->
            case ActorRef.new(kind_atom, actor_id) do
              {:ok, actor_ref} ->
                {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}

              {:error, :unknown_actor_type} ->
                {:error, "unknown actor kind: " <> inspect(actor_kind)}

              {:error, :missing_actor_id} ->
                {:error, "actor id is required for non-anonymous actors"}
            end

          {:error, :unknown_actor_type} ->
            {:error, "unknown actor kind: " <> inspect(actor_kind)}
        end

      is_binary(actor_kind) and actor_kind != "" ->
        # kind supplied but no id — leave without actor_ref filter
        {:ok, filters_without_actor_params}

      true ->
        {:ok, filters_without_actor_params}
    end
  end

  defp safe_actor_kind(kind) when is_binary(kind) do
    try do
      {:ok, String.to_existing_atom(kind)}
    rescue
      ArgumentError -> {:error, :unknown_actor_type}
    end
  end
end
