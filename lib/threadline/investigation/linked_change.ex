defmodule Threadline.Investigation.LinkedChange do
  @moduledoc """
  A LinkedChange connects one captured row mutation to its transaction and optional action.
  """

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.AuditAction

  @enforce_keys [:audit_change, :transaction]
  defstruct [:audit_change, :transaction, :action]

  @typedoc "A captured row change linked to its transaction and optional semantic action."
  @type t :: %__MODULE__{
          audit_change: AuditChange.t(),
          transaction: AuditTransaction.t(),
          action: AuditAction.t() | nil
        }
end

defmodule Threadline.Investigation.LinkedTransaction do
  @moduledoc """
  One transaction-oriented investigation slice with optional action metadata.
  """

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Investigation.LinkedChange
  alias Threadline.Semantics.AuditAction

  defstruct [:transaction, :action, changes: []]

  @typedoc "A transaction-centered investigation result with linked changes and optional action."
  @type t :: %__MODULE__{
          transaction: AuditTransaction.t() | nil,
          action: AuditAction.t() | nil,
          changes: [LinkedChange.t()]
        }
end
