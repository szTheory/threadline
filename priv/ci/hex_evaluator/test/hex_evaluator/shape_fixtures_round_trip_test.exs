defmodule HexEvaluator.ShapeFixturesRoundTripTest do
  @moduledoc """
  TWIN-01: a thin mirror of the example app's shape fixture round trips
  (examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs),
  proving every table shape works through the packaged, hex-resolved
  `:threadline` (D-21), and that `trigger_findings/1` reports nothing for any
  of them.
  """
  use HexEvaluator.DataCase, async: false

  import Ecto.Query

  alias HexEvaluator.ShapeFixtures.{
    CodeKeyed,
    Composite,
    Join,
    LongName,
    TwinPublic,
    TwinShapes
  }

  defp ops(history), do: Enum.map(history, & &1.op)

  describe "shape_composite (composite primary key)" do
    test "insert, update, delete round-trip and are addressed with a keyword list" do
      id = [tenant_id: 9_007_199_254_740_993, line_no: 1]

      composite =
        Repo.insert!(%Composite{tenant_id: 9_007_199_254_740_993, line_no: 1, qty: 1})

      composite
      |> Ecto.Changeset.change(qty: 2)
      |> Repo.update!()

      Repo.delete!(composite)

      history = Threadline.history(Composite, id, repo: Repo)

      assert ops(history) == ["delete", "update", "insert"]
    end

    test "precision edge: a tenant_id above 2^53 round-trips exactly" do
      big = 9_007_199_254_740_993

      Repo.insert!(%Composite{tenant_id: big, line_no: 2, qty: 1})

      [insert_change] = Threadline.history(Composite, [tenant_id: big, line_no: 2], repo: Repo)

      assert insert_change.data_after["tenant_id"] == big
    end
  end

  describe "shape_code_keyed (text primary key)" do
    test "encoding edge: a multi-byte code round-trips, insert/update/delete order" do
      code = "café-1"

      row = Repo.insert!(%CodeKeyed{code: code, label: "first"})

      row
      |> Ecto.Changeset.change(label: "second")
      |> Repo.update!()

      Repo.delete!(row)

      history = Threadline.history(CodeKeyed, code, repo: Repo)

      assert ops(history) == ["delete", "update", "insert"]
    end

    test "empty edge: history for a key that was never written returns []" do
      assert Threadline.history(CodeKeyed, "never-written", repo: Repo) == []
    end
  end

  describe "shape_join (no primary key, primary_key: override)" do
    test "insert, update, delete round-trip and are addressed by the override columns" do
      Repo.insert!(%Join{left_id: 1, right_id: 2, note: "a"})

      Repo.update_all(
        from(j in Join, where: j.left_id == 1 and j.right_id == 2),
        set: [note: "b"]
      )

      Repo.delete_all(from(j in Join, where: j.left_id == 1 and j.right_id == 2))

      history = Threadline.history(Join, [left_id: 1, right_id: 2], repo: Repo)
      assert ops(history) == ["delete", "update", "insert"]

      assert Threadline.history(Join, [left_id: 2, right_id: 1], repo: Repo) == []
    end
  end

  describe "shape_twin (same table name in two schemas)" do
    test "each schema's history stays separate and the note is masked" do
      Repo.insert!(%TwinPublic{id: 7, note: "public-plaintext"})
      Repo.insert!(%TwinShapes{id: 7, note: "shapes-plaintext"})

      public_history = Threadline.history(TwinPublic, 7, repo: Repo)
      shapes_history = Threadline.history(TwinShapes, 7, repo: Repo)

      assert length(public_history) == 1
      assert length(shapes_history) == 1

      [public_change] = public_history
      [shapes_change] = shapes_history

      assert public_change.table_schema == "public"
      assert shapes_change.table_schema == "shapes"

      refute public_change.data_after["note"] == "public-plaintext"
      refute shapes_change.data_after["note"] == "shapes-plaintext"
    end

    test "each table's capture trigger calls a distinct function" do
      %{rows: rows} =
        Repo.query!(
          """
          SELECT n.nspname, p.proname
          FROM pg_trigger t
          JOIN pg_class c ON c.oid = t.tgrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          JOIN pg_proc p ON p.oid = t.tgfoid
          WHERE NOT t.tgisinternal
            AND c.relname = 'shape_twin'
            AND t.tgname LIKE 'threadline_audit_%'
          """,
          []
        )

      pronames =
        rows
        |> Enum.map(fn [_nspname, proname] -> proname end)
        |> Enum.uniq()

      assert length(rows) == 2
      assert length(pronames) == 2
    end
  end

  describe "shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok (long table name)" do
    test "boundary edge: the table name is between 60 and 63 bytes and history round-trips" do
      table_name = LongName.__schema__(:source)
      assert byte_size(table_name) in 60..63

      row = Repo.insert!(%LongName{label: "first"})

      row
      |> Ecto.Changeset.change(label: "second")
      |> Repo.update!()

      Repo.delete!(row)

      history = Threadline.history(LongName, row.id, repo: Repo)
      assert ops(history) == ["delete", "update", "insert"]
    end
  end

  describe "trigger_findings/1" do
    test "reports nothing for the fixture tables" do
      findings =
        Threadline.Health.trigger_findings(repo: Repo)
        |> Enum.filter(&String.starts_with?(&1.table, "shape_"))

      assert findings == []
    end
  end
end
