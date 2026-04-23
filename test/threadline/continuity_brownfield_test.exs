defmodule Threadline.ContinuityBrownfieldTest do
  use Threadline.DataCase

  import Ecto.Query

  defmodule Row do
    use Ecto.Schema

    @primary_key {:id, :binary_id, autogenerate: false}
    schema "threadline_continuity_brownfield" do
      field(:name, :string)
    end
  end

  setup_all do
    Repo.query!("DROP TABLE IF EXISTS threadline_continuity_brownfield")

    Repo.query!("""
    CREATE TABLE threadline_continuity_brownfield (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      name text NOT NULL
    )
    """)

    on_exit(fn ->
      Repo.query!(Threadline.Capture.TriggerSQL.drop_trigger("threadline_continuity_brownfield"))
      Repo.query!("DROP TABLE IF EXISTS threadline_continuity_brownfield")
    end)

    :ok
  end

  setup do
    Repo.query!(Threadline.Capture.TriggerSQL.drop_trigger("threadline_continuity_brownfield"))
    Repo.query!("TRUNCATE threadline_continuity_brownfield")
    Repo.query!("INSERT INTO threadline_continuity_brownfield (name) VALUES ('before_trigger')")
    Repo.query!(Threadline.Capture.TriggerSQL.create_trigger("threadline_continuity_brownfield"))
    :ok
  end

  test "history is empty at T0 until first audited write after trigger install" do
    id =
      Repo.one!(
        from(r in Row,
          where: r.name == "before_trigger",
          select: r.id
        )
      )

    assert Threadline.history(Row, id, repo: Repo) == []

    {1, _} =
      Repo.update_all(from(r in Row, where: r.id == ^id), set: [name: "after_trigger"])

    changes =
      Repo.all(
        from(ac in AuditChange,
          where: ac.table_name == "threadline_continuity_brownfield"
        )
      )

    assert length(changes) == 1
    change = hd(changes)
    assert change.op == "update"
    assert change.table_pk["id"] != nil

    txns = Repo.all(from(at in AuditTransaction, where: at.id == ^change.transaction_id))
    assert length(txns) == 1
  end
end
