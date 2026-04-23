defmodule Threadline.DataCase do
  @moduledoc """
  Test case for integration tests that require a real PostgreSQL database.

  Does NOT use Ecto sandbox — PostgreSQL triggers fire at the DB level, outside
  sandbox awareness. Each test cleans audit tables in setup (D-09).
  """

  use ExUnit.CaseTemplate

  alias Threadline.Test.Repo
  alias Threadline.Capture.{AuditChange, AuditTransaction}

  using do
    quote do
      alias Threadline.Test.Repo
      alias Threadline.Capture.{AuditChange, AuditTransaction}
      import Ecto.Query
    end
  end

  setup do
    # Clean audit tables before each test (FK order: changes first, then transactions)
    Repo.delete_all(AuditChange)
    Repo.delete_all(AuditTransaction)
    :ok
  end
end
