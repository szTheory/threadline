defmodule Threadline.Semantics.AuditContext do
  @moduledoc """
  Execution context for an audited request or job.

  Plain struct — not an Ecto schema. Populated by `Threadline.Plug` for HTTP
  requests and by the caller for Oban jobs. Passed explicitly to
  `Threadline.record_action/2` when recording semantic actions.

  ## Fields

  - `:actor_ref` — `%Threadline.Semantics.ActorRef{}` or nil
  - `:request_id` — string from `x-request-id` header or nil
  - `:correlation_id` — string from `x-correlation-id` header or nil
  - `:remote_ip` — string representation of the client IP or nil
  """

  @enforce_keys []
  defstruct [:actor_ref, :request_id, :correlation_id, :remote_ip]
end
