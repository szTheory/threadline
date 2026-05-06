defmodule Threadline.Investigation.LinkedChange do
  @moduledoc """
  One investigation change row with linked transaction and optional action context.
  """

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.AuditAction

  @enforce_keys [:audit_change, :transaction]
  defstruct [:audit_change, :transaction, :action]

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

  @type t :: %__MODULE__{
          transaction: AuditTransaction.t() | nil,
          action: AuditAction.t() | nil,
          changes: [LinkedChange.t()]
        }
end
