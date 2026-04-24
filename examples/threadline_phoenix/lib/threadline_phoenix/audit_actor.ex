defmodule ThreadlinePhoenix.AuditActor do
  @moduledoc false

  @doc """
  Returns a stable synthetic `ActorRef` for the example HTTP API.

  Phase 23 ignores `conn`; production should derive the actor from authentication.
  """
  def from_conn(_conn) do
    case Threadline.Semantics.ActorRef.new(:service_account, "threadline-phoenix-example") do
      {:ok, ref} -> ref
      {:error, _} -> nil
    end
  end
end
