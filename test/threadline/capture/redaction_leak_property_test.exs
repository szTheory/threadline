defmodule Threadline.Capture.RedactionLeakPropertyTest do
  @moduledoc """
  PROP-04: a redacted column's plaintext never reaches the stored audit
  change, its `ChangeDiff` output, or its CSV/JSON/NDJSON export.

  Runs against a dedicated fixed table, `prop_redaction_leak` (D-07), with a
  real per-table redacted trigger installed from `lib/` in `setup_all` (so a
  mutant to `lib/threadline/capture/trigger_sql.ex` takes effect). Does
  **not** reuse the example suite's shared redaction fixture table — that
  fixture's `setup` drops triggers between examples and
  `config/test.exs`'s `:trigger_capture` points at it.

  `@max_runs PropertyRuns.db(20)` (D-05): measure first, lower only this
  property to `db(15)`/`db(10)` if it costs more than ~2s unscaled or ~9s at
  `THREADLINE_PROPERTY_SCALE=5`. Default `max_shrinking_steps`; no
  `max_run_time`. Worst-case shrink cost is bounded by ~100 x one iteration's
  measured ms per D-05; this file's own iterations are single DB
  round-trips, so shrinking stays cheap.

  Accepted, not a leak: the masked column's *name* appearing in
  `changed_fields`. Change detection compares raw `NEW`/`OLD` values before
  redaction runs, so `changed_fields` legitimately shows that a masked
  value changed — this is an intended equality side channel, documented
  here and checked structurally by `LeakOracle.assert_structure!/3`.

  Out of scope: the global redacted capture function
  (`install_function(exclude:/mask:)`) — `mix threadline.gen.triggers` never
  emits it.
  """

  use Threadline.DataCase, async: false
  use ExUnitProperties

  import Threadline.Test.DbProperty
  import Threadline.Test.RedactionLeakGenerators

  alias Threadline.Capture.TriggerSQL
  alias Threadline.ChangeDiff
  alias Threadline.Export
  alias Threadline.Test.LeakOracle
  alias Threadline.Test.PropertyRuns

  @t "prop_redaction_leak"
  @max_runs PropertyRuns.db(20)

  setup_all do
    Repo.query!("""
    CREATE TABLE IF NOT EXISTS #{@t} (
      id             uuid PRIMARY KEY,
      secret_excluded text NULL,
      secret_masked   text NULL,
      profile_masked  jsonb NULL,
      bio             text NULL
    )
    """)

    Repo.query!(
      TriggerSQL.install_function_for_table(@t,
        store_changed_from: true,
        exclude: ["secret_excluded"],
        mask: ["secret_masked", "profile_masked"]
      )
    )

    Repo.query!(
      TriggerSQL.create_trigger(@t, :per_table,
        redacted_columns: ["secret_excluded", "secret_masked", "profile_masked"]
      )
    )

    on_exit(fn ->
      Repo.query!(TriggerSQL.drop_trigger(@t))
      Repo.query!(TriggerSQL.drop_function_for_table(@t))
      Repo.query!("DROP TABLE IF EXISTS #{@t}")
    end)

    :ok
  end

  property "no canary survives a redacted trigger/storage/diff/CSV round trip" do
    check all(plan <- op_plan_gen(), max_runs: @max_runs) do
      with_iteration(
        fn n -> delete_iteration!(@t, [row_id(n)]) end,
        fn n ->
          id = row_id(n)

          insert_row!(id, plan.insert)

          Enum.each(plan.steps, fn {:touch_redacted, values} -> update_row!(id, values) end)

          changes = LeakOracle.stored_changes(@t, id, repo_opts())
          context = %{plan: plan, scrub: id}

          surfaces = build_surfaces(id, changes)

          LeakOracle.refute_canaries!(surfaces, canaries(plan), context)

          # audit_transactions carries no host-row columns, so the plain
          # marker (which lives in `bio`) is never expected there.
          marker_surfaces =
            Enum.reject(surfaces, fn {name, _} -> name == "stored:audit_transactions" end)

          LeakOracle.assert_markers!(marker_surfaces, markers(plan), context)
          LeakOracle.assert_structure!(changes, id, context)

          assert length(changes) == 2,
                 "expected one change per planned op (insert + 1 touch_redacted step)"
        end
      )
    end
  end

  defp row_id(n), do: Ecto.UUID.load!(<<n::128>>)
  defp uuid_param(id), do: Ecto.UUID.dump!(id)

  defp insert_row!(id, values) do
    Repo.query!(
      "INSERT INTO #{@t} (id, secret_excluded, secret_masked, profile_masked, bio) " <>
        "VALUES ($1::uuid, $2, $3, $4::jsonb, $5)",
      [
        uuid_param(id),
        values.secret_excluded,
        values.secret_masked,
        profile_json(values.profile_masked),
        values.bio
      ]
    )
  end

  defp update_row!(id, values) do
    Repo.query!(
      "UPDATE #{@t} SET secret_excluded = $2, secret_masked = $3, " <>
        "profile_masked = $4::jsonb, bio = $5 WHERE id = $1::uuid",
      [
        uuid_param(id),
        values.secret_excluded,
        values.secret_masked,
        profile_json(values.profile_masked),
        values.bio
      ]
    )
  end

  defp profile_json(nil), do: nil
  defp profile_json(v), do: Jason.encode!(%{"k" => v, "l" => [v]})

  defp build_surfaces(id, changes) do
    diff_bytes = Enum.map_join(changes, "\n", &Jason.encode!(ChangeDiff.from_audit_change(&1)))

    {:ok, %{data: csv_iodata}} =
      Export.to_csv_iodata([table: @t, repo: Threadline.Test.Repo], [])

    LeakOracle.stored_surfaces(@t, id) ++
      [
        {"diff:default", diff_bytes},
        {"export:csv", IO.iodata_to_binary(csv_iodata)}
      ]
  end
end
