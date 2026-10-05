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

  @typedoc "An option passed through to `Threadline.record_action/2` or extracted from job arguments."
  @type context_opt ::
          Threadline.record_action_opt()
          | {:correlation_id, String.t() | nil}
          | {:job_id, String.t() | nil}

  @typedoc "The record-action options returned from `context_opts/2`."
  @type context_opts_result :: [context_opt()]

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

  Extracts `:correlation_id` and `:job_id` from the args map. Pass these opts
  (merged with `:actor` and `:repo`) to `Threadline.record_action/2`. Values
  supplied in `extra` override the values extracted from `args`.

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
  - `:correlation_id` — string or `nil`. Optional. Read from `args`, then overridden by `extra` when supplied.
  - `:request_id` — string. Optional. Passed through to `record_action/2`.
  - `:job_id` — string or `nil`. Optional. Read from `args`, then overridden by `extra` when supplied.

  Other option keys are retained and validated by `record_action/2` when used.

  ## Returns

  - A keyword list of record-action options.

  ## Example

      opts = Threadline.Job.context_opts(args)
      Threadline.record_action(:event, [actor: actor_ref, repo: Repo] ++ opts)
  """
  @spec context_opts(job_args(), [context_opt()]) :: context_opts_result()
  def context_opts(args, extra \\ []) when is_map(args) do
    base = [
      correlation_id: Map.get(args, "correlation_id"),
      job_id: Map.get(args, "job_id")
    ]

    Keyword.merge(base, extra)
  end
end
