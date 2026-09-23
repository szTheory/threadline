defmodule Threadline.Query.FilterParams do
  @moduledoc false

  alias Threadline.Semantics.ActorRef

  # Allowed URL keys mapped to their filter atoms. Declaring the atoms in a
  # compile-time literal here (rather than deriving them at runtime via
  # String.to_existing_atom/1) guarantees they exist no matter which threadline
  # modules have been lazily loaded when a request first hits the timeline — the
  # example app crashed with "not an already existing atom" on
  # `?correlation_id=…` precisely because `:correlation_id` is only created when
  # `Threadline.Query` loads, which happens *after* normalize_params/1 runs.
  # Bounding the conversion to this fixed allowlist also preserves the
  # atom-table-exhaustion guard: arbitrary input can never mint a
  # fresh atom.
  @filter_key_atoms %{
    "from" => :from,
    "to" => :to,
    "table_schema" => :table_schema,
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
         {:ok, with_datetimes} <- parse_datetimes(normalized) do
      collapse_actor_ref(with_datetimes)
    end
  end

  # Form fields echoed back by filters_raw_from_params/1; a missing field echoes
  # as the empty string.
  @raw_filter_keys ~w(from to table_schema table actor_kind actor_id correlation_id)

  @doc """
  Returns a string-keyed `%{key => value}` map suitable for re-rendering the
  filter form on URL paste. Mirrors the `actor_kind=anonymous` strip-id
  normalization so the form echoes the canonical (post-strip) URL.
  """
  @spec filters_raw_from_params(map()) :: %{required(String.t()) => String.t()}
  def filters_raw_from_params(params) when is_map(params) do
    raw = Map.new(@raw_filter_keys, &{&1, params[&1] || ""})

    case raw["actor_kind"] do
      "anonymous" -> Map.put(raw, "actor_id", "")
      _ -> raw
    end
  end

  # Canonical key order for query-string rendering. Shared by TimelineLive
  # (self-patches, saved-view apply) and StartLive (Home recent/saved fast-path)
  # so every surface produces byte-identical timeline URLs from a raw filter map.
  @canonical_key_order ~w(from to table_schema table actor_kind actor_id correlation_id)

  @doc """
  Builds the canonical, deterministically-ordered query string for a string-keyed
  raw filter map (the shape stored on `SavedView.filters` and produced by the
  timeline filter form). Drops blank values, applies the `actor_kind=anonymous`
  strip-id normalization, and orders keys by `@canonical_key_order` so two equal
  filter sets always encode to the same string.
  """
  @spec canonical_query(map()) :: String.t()
  def canonical_query(%{} = raw) do
    raw
    |> normalize_anonymous()
    |> Enum.filter(fn {k, v} -> k in @canonical_key_order and is_binary(v) and v != "" end)
    |> Enum.sort_by(fn {k, _v} -> Enum.find_index(@canonical_key_order, &(&1 == k)) end)
    |> URI.encode_query()
  end

  defp normalize_anonymous(%{"actor_kind" => "anonymous"} = raw),
    do: Map.delete(raw, "actor_id")

  defp normalize_anonymous(raw), do: raw

  # Shared parsing helpers keep LiveView and HTTP export filters identical.

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
    filters_without_actor_params =
      filters
      |> Keyword.delete(:actor_kind)
      |> Keyword.delete(:actor_id)

    case actor_ref_from(Keyword.get(filters, :actor_kind), Keyword.get(filters, :actor_id)) do
      :none -> {:ok, filters_without_actor_params}
      {:ok, actor_ref} -> {:ok, Keyword.put(filters_without_actor_params, :actor_ref, actor_ref)}
      {:error, _message} = error -> error
    end
  end

  defp actor_ref_from("anonymous", _actor_id), do: {:ok, %ActorRef{type: :anonymous, id: nil}}

  defp actor_ref_from(actor_kind, actor_id) do
    case {present?(actor_kind), present?(actor_id)} do
      {true, true} -> build_actor_ref(actor_kind, actor_id)
      {true, false} -> {:error, "actor id is required for non-anonymous actors"}
      {false, true} -> {:error, "actor kind is required when actor id is present"}
      {false, false} -> :none
    end
  end

  defp present?(value), do: is_binary(value) and value != ""

  defp build_actor_ref(actor_kind, actor_id) do
    with {:ok, kind_atom} <- safe_actor_kind(actor_kind),
         {:ok, actor_ref} <- ActorRef.new(kind_atom, actor_id) do
      {:ok, actor_ref}
    else
      {:error, :unknown_actor_type} ->
        {:error, "unknown actor kind: " <> inspect(actor_kind)}

      {:error, :missing_actor_id} ->
        {:error, "actor id is required for non-anonymous actors"}
    end
  end

  defp safe_actor_kind(kind) when is_binary(kind) do
    {:ok, String.to_existing_atom(kind)}
  rescue
    ArgumentError -> {:error, :unknown_actor_type}
  end
end
