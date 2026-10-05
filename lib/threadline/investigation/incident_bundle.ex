defmodule Threadline.Investigation.IncidentChange do
  @moduledoc """
  An incident change pairs a linked audit change with its JSON diff for
  investigation review.
  """

  alias Threadline.Investigation.LinkedChange

  @enforce_keys [:linked_change, :change_diff]
  defstruct [:linked_change, :change_diff]

  @typedoc "A linked incident change and its JSON change diff."
  @type t :: %__MODULE__{
          linked_change: LinkedChange.t(),
          change_diff: Threadline.json_map()
        }
end

defmodule Threadline.Investigation.IncidentBundle do
  @moduledoc """
  An IncidentBundle groups one captured transaction with its linked action and change diffs.
  """

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Investigation.IncidentChange
  alias Threadline.Semantics.AuditAction

  @enforce_keys [:transaction]
  defstruct [:transaction, :action, changes: []]

  @typedoc "A captured transaction with its optional action and bundled incident changes."
  @type t :: %__MODULE__{
          transaction: AuditTransaction.t(),
          action: AuditAction.t() | nil,
          changes: [IncidentChange.t()]
        }
end
