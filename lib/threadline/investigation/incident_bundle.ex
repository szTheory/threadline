defmodule Threadline.Investigation.IncidentChange do
  @moduledoc """
  One bundled incident change with raw linked structs and a packaged diff.
  """

  alias Threadline.Investigation.LinkedChange

  @enforce_keys [:linked_change, :change_diff]
  defstruct [:linked_change, :change_diff]

  @type t :: %__MODULE__{
          linked_change: LinkedChange.t(),
          change_diff: map()
        }
end

defmodule Threadline.Investigation.IncidentBundle do
  @moduledoc """
  One transaction-focused incident bundle with linked context and packaged diffs.
  """

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Investigation.IncidentChange
  alias Threadline.Semantics.AuditAction

  @enforce_keys [:transaction]
  defstruct [:transaction, :action, changes: []]

  @type t :: %__MODULE__{
          transaction: AuditTransaction.t(),
          action: AuditAction.t() | nil,
          changes: [IncidentChange.t()]
        }
end
