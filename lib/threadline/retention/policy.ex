defmodule Threadline.Retention.Policy do
  @moduledoc """
  Validates **`config :threadline, :retention`** before purge runs.

  Threadline supports a **single global retention window** (`:keep_days` or
  `:max_age_seconds`, mutually exclusive) plus an **`enabled`** flag that must
  be true for destructive purge. **`delete_empty_transactions`** defaults to
  `true` (remove parent `audit_transactions` rows with no remaining children
  after change deletes).

  Per-table and per-tenant overrides are not supported; this module validates
  the global policy shape only.

  `validate_config!/1` checks configuration, `resolve!/1` returns normalized
  policy values, and `cutoff_utc_datetime_usec!/1` computes the expiry cutoff.
  """

  @typedoc "Normalized retention options as returned by `resolve/1`."
  @type t :: %__MODULE__{
          enabled: boolean(),
          delete_empty_transactions: boolean(),
          window_seconds: pos_integer()
        }

  @typedoc "An atom-keyed option in the retention policy configuration."
  @type config_opt ::
          {:enabled, boolean() | String.t()}
          | {:delete_empty_transactions, boolean() | String.t()}
          | {:keep_days, pos_integer()}
          | {:max_age_seconds, pos_integer()}

  @typedoc ~S"""
  A retention config map. Recognized keys are atom or string spellings of `:enabled`,
  `:delete_empty_transactions`, `:keep_days`, and `:max_age_seconds`. The boolean keys accept
  booleans or the strings `"true"` and `"false"`; each window key accepts a positive integer.
  Other keys are ignored, and the string-key map arm represents extra keys and mixed atom/string
  maps.

  For boolean keys, a present atom key wins over its string spelling even when its value is
  invalid. For window keys, `atom_value || string_value` is used, so nil or false falls back to
  the string key while 0 or another truthy invalid value does not. Positive window values remain
  mutually exclusive; when both are absent, the test environment uses a one-day default.
  """
  @type config_map ::
          %{
            optional(:enabled) => boolean() | String.t(),
            optional(:delete_empty_transactions) => boolean() | String.t(),
            optional(:keep_days) => pos_integer(),
            optional(:max_age_seconds) => pos_integer()
          }
          | %{optional(String.t()) => boolean() | String.t() | pos_integer()}

  @typedoc "The keyword-list or map form accepted by retention policy validation and resolution."
  @type config :: [config_opt()] | config_map()

  @typedoc "An option accepted by `cutoff_utc_datetime_usec!/1`."
  @type cutoff_opt :: {:policy, t()}

  defstruct [:enabled, :delete_empty_transactions, :window_seconds]

  @doc """
  Returns `:ok` when retention config from `Application.get_env(:threadline, :retention)` is valid.

  Raises `ArgumentError` with a message containing `"retention"` when either boolean option is
  not a boolean or its string spelling, when both window keys are set, or when a window is
  non-positive or missing outside the test environment.

  In `:test`, missing `:keep_days` / `:max_age_seconds` is allowed only when the
  caller passes a non-empty map/list that still fails other checks — for empty
  config in test, hosts should set explicit values in `config/test.exs`.
  """
  @spec validate_config!(config()) :: :ok
  def validate_config!(opts) when is_list(opts), do: validate_config!(Map.new(opts))

  def validate_config!(opts) when is_map(opts) do
    _ = resolve!(opts)
    :ok
  end

  @doc """
  Resolves config into a struct or raises like `validate_config!/1`.
  """
  @spec resolve!(config()) :: t()
  def resolve!(opts) when is_list(opts), do: resolve!(Map.new(opts))

  def resolve!(opts) when is_map(opts) do
    env = mix_env()

    enabled =
      boolean_opt!(Map.get(opts, :enabled, Map.get(opts, "enabled", false)), ":enabled")

    delete_empty_transactions =
      boolean_opt!(
        Map.get(
          opts,
          :delete_empty_transactions,
          Map.get(opts, "delete_empty_transactions", true)
        ),
        ":delete_empty_transactions"
      )

    days = Map.get(opts, :keep_days) || Map.get(opts, "keep_days")
    secs = Map.get(opts, :max_age_seconds) || Map.get(opts, "max_age_seconds")

    %__MODULE__{
      enabled: enabled,
      delete_empty_transactions: delete_empty_transactions,
      window_seconds: window_seconds!(days, secs, env)
    }
  end

  defp boolean_opt!(true, _key), do: true
  defp boolean_opt!(false, _key), do: false
  defp boolean_opt!("true", _key), do: true
  defp boolean_opt!("false", _key), do: false

  defp boolean_opt!(other, key) do
    raise ArgumentError, "retention: #{key} must be boolean, got: #{inspect(other)}"
  end

  # Clause order is the original check order (first match wins): the
  # both-keys conflict, then the valid windows, then the non-positive errors,
  # then the test-env default, then the catch-all.
  defp window_seconds!(days, secs, _env)
       when is_integer(days) and days > 0 and is_integer(secs) and secs > 0 do
    raise ArgumentError,
          "retention: use only one of :keep_days or :max_age_seconds, not both"
  end

  defp window_seconds!(days, nil, _env) when is_integer(days) and days > 0, do: days * 86_400

  defp window_seconds!(nil, secs, _env) when is_integer(secs) and secs > 0, do: secs

  defp window_seconds!(days, _secs, _env) when is_integer(days) and days <= 0 do
    raise ArgumentError, "retention: :keep_days must be positive"
  end

  defp window_seconds!(_days, secs, _env) when is_integer(secs) and secs <= 0 do
    raise ArgumentError, "retention: :max_age_seconds must be positive"
  end

  # Sensible default so purge integration tests can omit repeating window keys.
  defp window_seconds!(nil, nil, :test), do: 86_400

  defp window_seconds!(_days, _secs, _env) do
    raise ArgumentError,
          "retention: set exactly one of :keep_days or :max_age_seconds as a positive integer"
  end

  @doc """
  Returns UTC `DateTime` strictly **before** which `AuditChange.captured_at` values
  are considered expired for purge (i.e. delete rows with `captured_at < cutoff`).

  Uses `DateTime.add/3` in microsecond mode for consistency with `:utc_datetime_usec`.

  ## Options

  - `:policy` — normalized retention policy. Optional. Defaults to the configured policy.

  ## Returns

  - The UTC cutoff timestamp.

  Other option keys are ignored.
  """
  @spec cutoff_utc_datetime_usec!([cutoff_opt()]) :: DateTime.t()
  def cutoff_utc_datetime_usec!(opts \\ []) do
    policy =
      case Keyword.get(opts, :policy) do
        %__MODULE__{} = p -> p
        _ -> resolve!(Application.get_env(:threadline, :retention) || [])
      end

    DateTime.utc_now(:microsecond)
    |> DateTime.add(-policy.window_seconds, :second)
  end

  defp mix_env do
    if Code.ensure_loaded?(Mix) and function_exported?(Mix, :env, 0) do
      Mix.env()
    else
      :prod
    end
  end
end
