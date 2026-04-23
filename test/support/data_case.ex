defmodule Threadline.DataCase do
  @moduledoc """
  Test case for integration tests that require a real PostgreSQL database.

  Does NOT use Ecto sandbox — PostgreSQL triggers fire at the DB level, outside
  sandbox awareness. Each test cleans audit tables in `setup` (FK order).

  **`async: false` by default** so tests in the same module never hit the same DB concurrently.
  """

  defmacro __using__(opts) do
    opts = Keyword.merge([async: false], opts)

    quote do
      use ExUnit.Case, unquote(opts)

      alias Threadline.Test.Repo
      alias Threadline.Capture.{AuditChange, AuditTransaction}
      import Ecto.Query

      setup do
        # FK order: changes first, then transactions, then actions
        Repo.delete_all(AuditChange)
        Repo.delete_all(AuditTransaction)
        Repo.delete_all(Threadline.Semantics.AuditAction)
        :ok
      end
    end
  end
end
