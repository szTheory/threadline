defmodule Threadline.NotFoundError do
  @moduledoc """
  `Threadline.NotFoundError` is raised by the `!` sibling of a single-subject
  lookup when the subject does not exist or is not visible under the caller's
  scope.

  The message carries only the id the caller passed in — never row data,
  scope terms, or wording that distinguishes an existing-but-scope-filtered
  row from a genuinely missing one. `resource` names the subject looked up:
  `:audit_transaction` for `Threadline.audit_transaction!/2` and the other
  single-subject transaction lookups' `!` siblings.

  Implements `Plug.Exception` (`status/1` returns `404`, `actions/1` returns
  `[]`). Unlike `Ecto.NoResultsError`, which gets its 404 mapping from
  `phoenix_ecto`, Threadline depends on `:plug` directly (`mix.exs`), so it
  owns its own status.
  """

  @moduledoc since: "1.0.0"

  defexception [:resource, :id]

  @typedoc "A missing audit transaction identified by its caller-supplied UUID."
  @type t :: %__MODULE__{resource: :audit_transaction, id: Ecto.UUID.t()}

  @impl true
  def message(%{resource: resource, id: id}) do
    subject = resource |> to_string() |> String.replace("_", " ")
    "#{subject} not found: #{inspect(id)}"
  end
end

defimpl Plug.Exception, for: Threadline.NotFoundError do
  def status(_exception), do: 404
  def actions(_exception), do: []
end
