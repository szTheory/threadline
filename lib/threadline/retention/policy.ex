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
  """

  @typedoc "Normalized retention options as returned by `resolve/1`."
  @type t :: %__MODULE__{
          enabled: boolean(),
          delete_empty_transactions: boolean(),
          window_seconds: pos_integer()
        }

  defstruct [:enabled, :delete_empty_transactions, :window_seconds]

  @doc """
  Validates retention config from `Application.get_env(:threadline, :retention)`.

  Raises `ArgumentError` with a message containing `"retention"` when the shape
  is invalid, keys conflict, or the window is not positive.

  In `:test`, missing `:keep_days` / `:max_age_seconds` is allowed only when the
  caller passes a non-empty map/list that still fails other checks — for empty
  config in test, hosts should set explicit values in `config/test.exs`.
  """
  @spec validate_config!(keyword() | map()) :: :ok
  def validate_config!(opts) when is_list(opts), do: validate_config!(Map.new(opts))

  def validate_config!(opts) when is_map(opts) do
    _ = resolve!(opts)
    :ok
  end

  @doc """
  Resolves config into a struct or raises like `validate_config!/1`.
  """
  @spec resolve!(keyword() | map()) :: t()
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
  """
  @spec cutoff_utc_datetime_usec!(keyword()) :: DateTime.t()
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
