defmodule Threadline.Mix.TriggerMigrationPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.NamingGenerators

  alias Threadline.Capture.{Naming, TriggerSQL}
  alias Threadline.Mix.TriggerMigration

  # The trigger statement exactly as the generator writes it into a migration
  # file. Built from the current SQL, so a change to the emitted form that the
  # rerun parser cannot read fails here. The storage schema is passed
  # explicitly so the test does not read application env.
  defp generated(pair) do
    sql =
      TriggerSQL.create_trigger(Naming.qualified(pair), :default, storage_schema: "threadline")

    "    execute " <> inspect(sql, printable_limit: :infinity, limit: :infinity)
  end

  property "a table's own generated trigger migration is a rerun of it" do
    check all(pair <- pair_gen(), max_runs: 300) do
      assert TriggerMigration.rerun?(pair, [generated(pair)])
    end
  end

  property "another table's generated trigger migration is never a rerun" do
    check all({p, q} <- pair_of_pairs_gen(), p != q, max_runs: 300) do
      refute TriggerMigration.rerun?(q, [generated(p)])
      refute TriggerMigration.rerun?(p, [generated(q)])
    end
  end
end
