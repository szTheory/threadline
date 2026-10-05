defmodule Threadline.Semantics.AuditContext do
  @moduledoc """
  An `AuditContext` carries request or job details into a semantic audit action.

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

  @typedoc "Request or job context attached to a semantic audit action."
  @type t :: %__MODULE__{
          actor_ref: Threadline.Semantics.ActorRef.t() | nil,
          request_id: String.t() | nil,
          correlation_id: String.t() | nil,
          remote_ip: String.t() | nil
        }
end
