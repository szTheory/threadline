defmodule Threadline.Job do
  @moduledoc """
  Helpers for propagating audit context through background job `args` maps.

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

  @doc """
  Extracts an `ActorRef` from a job args map.

  Looks for an `"actor_ref"` key containing a map serialized by
  `ActorRef.to_map/1`.

  Returns `{:ok, %ActorRef{}}` or `{:error, reason}`.
  """
  def actor_ref_from_args(%{"actor_ref" => actor_ref_map}) when is_map(actor_ref_map) do
    ActorRef.from_map(actor_ref_map)
  end

  def actor_ref_from_args(_args), do: {:error, :missing_actor_ref}

  @doc """
  Builds `record_action/2` keyword opts from job args.

  Extracts `:correlation_id` and `:job_id` from the args map. Pass these opts
  (merged with `:actor` and `:repo`) to `Threadline.record_action/2`.

  ## Example

      opts = Threadline.Job.context_opts(args)
      Threadline.record_action(:event, [actor: actor_ref, repo: Repo] ++ opts)
  """
  def context_opts(args, extra \\ []) when is_map(args) do
    base = [
      correlation_id: Map.get(args, "correlation_id"),
      job_id: Map.get(args, "job_id")
    ]

    Keyword.merge(base, extra)
  end
end
