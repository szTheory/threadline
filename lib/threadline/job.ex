defmodule Threadline.Job do
  @moduledoc """
  Carries serialized actor references and stable context keys through background-job argument maps.

  `actor_ref_from_args/1` decodes an `ActorRef`, and `context_opts/2` builds
  options for `Threadline.record_action/2`.

  Context is explicitly passed via serializable maps and never stored in process
  state, ETS, or a process dictionary. This satisfies CTX-05 and keeps helpers
  testable as pure functions.

  ## Usage in a worker

      def perform(%{args: args}) do
        with {:ok, actor_ref} <- Threadline.Job.actor_ref_from_args(args) do
          opts = Threadline.Job.context_opts(args)

          Threadline.record_action(:member_synced,
            [actor: actor_ref, repo: MyApp.Repo] ++ opts
          )
        end
      end

  ## Enqueue with context

  Serialize `actor_ref` with `Threadline.Semantics.ActorRef.to_map/1` under the
  `"actor_ref"` key alongside other string-key fields your worker expects.

  ## Compile-time coupling

  This module references only plain maps — no compile-time dependency on any
  specific job runner package. Pass the args map your worker receives into these
  helpers.
  """

  alias Threadline.Semantics.ActorRef

  @typedoc "A JSON-compatible job argument map with string keys."
  @type job_args :: Threadline.json_map()

  @typedoc "A failure returned while decoding an actor reference from job arguments."
  @type actor_ref_error ::
          :missing_actor_ref | :invalid_actor_ref_map | :unknown_actor_type | :missing_actor_id

  @typedoc "The decoded actor reference or its known decoding failure."
  @type actor_ref_result :: {:ok, ActorRef.t()} | {:error, actor_ref_error()}

  @typedoc "An allowed extra option for `context_opts/2`, including integer context ID overrides."
  @type context_opt ::
          Threadline.record_action_opt()
          | {:correlation_id, String.t() | integer() | nil}
          | {:job_id, String.t() | integer() | nil}

  @typedoc "The record-action options returned from `context_opts/2`."
  @type context_opts_result ::
          [
            Threadline.record_action_opt()
            | {:correlation_id, String.t() | nil}
            | {:job_id, String.t() | nil}
          ]

  @doc """
  Returns the `ActorRef` serialized in a job argument map.

  Looks for an `"actor_ref"` key containing a map serialized by
  `ActorRef.to_map/1`.

  ## Returns

  - `{:ok, %ActorRef{}}` — the serialized reference was valid.
  - `{:error, :missing_actor_ref | :invalid_actor_ref_map | :unknown_actor_type | :missing_actor_id}` — the arguments do not contain a valid reference.
  """
  @spec actor_ref_from_args(job_args()) :: actor_ref_result()
  def actor_ref_from_args(%{"actor_ref" => actor_ref_map}) when is_map(actor_ref_map) do
    ActorRef.from_map(actor_ref_map)
  end

  def actor_ref_from_args(_args), do: {:error, :missing_actor_ref}

  @doc """
  Builds `record_action/2` keyword opts from job args.

  Extracts `:correlation_id` and `:job_id` from the args map. Integer IDs are
  converted to strings; strings and `nil` are preserved. Pass these opts
  (merged with `:actor` and `:repo`) to `Threadline.record_action/2`. Allowed
  values supplied in `extra` override the values extracted from `args` and
  integer ID overrides are converted the same way.

  ## Options

  - `:repo` — `Ecto.Repo` module. Optional. Passed through to `record_action/2`.
  - `:storage_schema` — string. Optional. Passed through to `record_action/2`.
  - `:actor` — `ActorRef`. Optional. Passed through to `record_action/2`.
  - `:actor_ref` — `ActorRef`. Optional. Passed through to `record_action/2`.
  - `:status` — `:ok` or `:error`. Optional. Passed through to `record_action/2`.
  - `:verb` — atom or string. Optional. Passed through to `record_action/2`.
  - `:category` — atom or string. Optional. Passed through to `record_action/2`.
  - `:reason` — atom or string. Optional. Passed through to `record_action/2`.
  - `:comment` — string. Optional. Passed through to `record_action/2`.
  - `:correlation_id` — string or `nil` in the returned options. Optional. Read from `args`, then overridden by `extra` when supplied; integer input is converted to a string.
  - `:request_id` — string. Optional. Passed through to `record_action/2`.
  - `:job_id` — string or `nil` in the returned options. Optional. Read from `args`, then overridden by `extra` when supplied; integer input is converted to a string.

  `extra` must be a keyword list of `context_opt()` values, which are the
  documented `Threadline.record_action/2` options plus integer ID overrides.
  Unsupported keys, malformed IDs, non-keyword extras, and option values
  outside that domain raise `ArgumentError`.

  ## Returns

  - A keyword list of record-action options.

  ## Example

      opts = Threadline.Job.context_opts(args)
      Threadline.record_action(:event, [actor: actor_ref, repo: Repo] ++ opts)
  """
  @spec context_opts(job_args(), [context_opt()]) :: context_opts_result()
  def context_opts(args, extra \\ []) when is_map(args) do
    unless Keyword.keyword?(extra) and Enum.all?(extra, &valid_context_opt?/1) do
      raise ArgumentError,
            "extra must contain only supported Threadline.record_action/2 options and valid context IDs"
    end

    base = [
      correlation_id: normalize_id!(Map.get(args, "correlation_id"), :correlation_id),
      job_id: normalize_id!(Map.get(args, "job_id"), :job_id)
    ]

    normalized_extra =
      Enum.map(extra, fn
        {key, value} when key in [:correlation_id, :job_id] ->
          {key, normalize_id!(value, key)}

        option ->
          option
      end)

    Keyword.merge(base, normalized_extra)
  end

  defp normalize_id!(nil, _key), do: nil
  defp normalize_id!(value, _key) when is_binary(value), do: value
  defp normalize_id!(value, _key) when is_integer(value), do: Integer.to_string(value)

  defp normalize_id!(_value, key) do
    raise ArgumentError, "#{inspect(key)} must be a string, integer, or nil"
  end

  defp valid_context_opt?({:repo, value}), do: is_atom(value)
  defp valid_context_opt?({:storage_schema, value}), do: is_binary(value)
  defp valid_context_opt?({:actor, %ActorRef{}}), do: true
  defp valid_context_opt?({:actor_ref, %ActorRef{}}), do: true
  defp valid_context_opt?({:status, value}), do: value in [:ok, :error]

  defp valid_context_opt?({key, value}) when key in [:verb, :category, :reason],
    do: is_atom(value) or is_binary(value)

  defp valid_context_opt?({:comment, value}), do: is_binary(value)
  defp valid_context_opt?({:request_id, value}), do: is_binary(value)

  defp valid_context_opt?({key, value}) when key in [:correlation_id, :job_id] do
    is_nil(value) or is_binary(value) or is_integer(value)
  end

  defp valid_context_opt?(_option), do: false
end
