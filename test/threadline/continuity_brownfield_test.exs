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

  describe "capture readiness for selected host schemas" do
    setup do
      Repo.query!("DROP SCHEMA IF EXISTS support CASCADE")
      Repo.query!("CREATE SCHEMA support")

      Repo.query!("""
      CREATE TABLE support.tickets (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        subject text NOT NULL
      )
      """)

      Repo.query!(Threadline.Capture.TriggerSQL.create_trigger("support.tickets"))

      on_exit(fn ->
        Repo.query!("DROP SCHEMA IF EXISTS support CASCADE")
      end)

      :ok
    end

    test "accepts schema-qualified support.tickets" do
      assert :ok = Threadline.Continuity.assert_capture_ready!("support.tickets", repo: Repo)
    end

    test "accepts explicit host schema option for bare table names" do
      assert :ok = Threadline.Continuity.assert_capture_ready!("tickets", repo: Repo, schema: "support")
    end

    test "public shorthand remains the default for bare table names" do
      assert :ok =
               Threadline.Continuity.assert_capture_ready!("threadline_continuity_brownfield",
                 repo: Repo
               )
    end

    test "missing selected schemas fail without falling back to public" do
      assert_raise ArgumentError, ~r/schema "missing_support" was not found/, fn ->
        Threadline.Continuity.assert_capture_ready!("missing_support.tickets", repo: Repo)
      end
    end

    test "missing selected tables name the selected host schema" do
      assert_raise ArgumentError, ~r/table "support\.missing_tickets" does not exist/, fn ->
        Threadline.Continuity.assert_capture_ready!("support.missing_tickets", repo: Repo)
      end
    end
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
        ),
        repo_opts()
      )

    assert length(changes) == 1
    change = hd(changes)
    assert change.op == "update"
    assert change.table_pk["id"] != nil

    txns =
      Repo.all(
        from(at in AuditTransaction, where: at.id == ^change.transaction_id),
        repo_opts()
      )

    assert length(txns) == 1
  end
end
