defmodule Threadline.Query.ActorHistoryPage do
  @moduledoc """
  One keyset page from the actor history query layer.
  """

  alias Threadline.Capture.AuditTransaction

  @enforce_keys [:entries]
  defstruct [:entries, :next_cursor, :prev_cursor]

  @type cursor :: %{occurred_at: DateTime.t(), id: String.t()}
  @type t :: %__MODULE__{
          entries: [AuditTransaction.t()],
          next_cursor: cursor() | nil,
          prev_cursor: cursor() | nil
        }
end
