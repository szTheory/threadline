defmodule Threadline.Health.Policy do
  @moduledoc """
  Validates `:expected_uncovered_tables` and `:audit_anyway` configuration
  for `Threadline.Health.trigger_coverage/1`'s third bucket.

  Adopters typically configure:

      config :threadline, :health,
        expected_uncovered_tables: ["oban_jobs", "oban_peers", "oban_producers"],
        audit_anyway: []

  Validate at boot in `application.ex` to fail loud on bad config:

      Threadline.Health.Policy.validate!(Application.get_env(:threadline, :health, []))

  Lazy validation at first poll tick is supported but discouraged in production —
  a delay between release and first dashboard tick can hide config errors.
  """

  @known_keys ~w(expected_uncovered_tables audit_anyway)a

  @doc """
  Validates `:expected_uncovered_tables` and `:audit_anyway` config.

  Accepts a keyword list or a map (dual-form intake matching
  `Threadline.Capture.RedactionPolicy.validate!/1`).

  Raises `ArgumentError` on:
  - non-binary entries inside either list
  - duplicate entries inside either list
  - unknown top-level keys
  - non-keyword / non-map input shape
  """
  def validate!(opts) when is_list(opts) do
    if Keyword.keyword?(opts) do
      validate!(Map.new(opts))
    else
      raise ArgumentError,
            "Threadline.Health.Policy: expected a keyword list or map, got: #{inspect(opts)}"
    end
  end

  def validate!(opts) when is_map(opts) do
    validate_known_keys!(opts)
    validate_list!(:expected_uncovered_tables, Map.get(opts, :expected_uncovered_tables, []))
    validate_list!(:audit_anyway, Map.get(opts, :audit_anyway, []))
    :ok
  end

  def validate!(other) do
    raise ArgumentError,
          "Threadline.Health.Policy: expected a keyword list or map, got: #{inspect(other)}"
  end

  defp validate_known_keys!(opts) do
    unknown = Map.keys(opts) -- @known_keys

    if unknown != [] do
      raise ArgumentError,
            "Threadline.Health.Policy: unknown config key(s): #{inspect(unknown)}. " <>
              "Known keys: #{inspect(@known_keys)}."
    end
  end

  defp validate_list!(key, list) when is_list(list) do
    non_binary = Enum.reject(list, &is_binary/1)

    if non_binary != [] do
      raise ArgumentError,
            "Threadline.Health.Policy: :#{key} must contain only binary strings, " <>
              "got non-binary entry: #{inspect(hd(non_binary))}"
    end

    duplicates = list -- Enum.uniq(list)

    if duplicates != [] do
      raise ArgumentError,
            "Threadline.Health.Policy: :#{key} contains duplicate entries: #{inspect(Enum.uniq(duplicates))}"
    end

    :ok
  end

  defp validate_list!(key, other) do
    raise ArgumentError,
          "Threadline.Health.Policy: :#{key} must be a list of binary strings, got: #{inspect(other)}"
  end
end
