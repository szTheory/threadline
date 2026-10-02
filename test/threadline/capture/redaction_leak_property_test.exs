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

  `@max_runs PropertyRuns.db(20)` (D-05): measured at ~0.1s unscaled and well
  under budget at `THREADLINE_PROPERTY_SCALE=5`, so no reason to drop to
  `db(15)`/`db(10)`. Default `max_shrinking_steps`; no `max_run_time`.
  Worst-case shrink cost is bounded by ~100 x one iteration's measured ms
  per D-05 — this file's own iterations are a handful of DB round-trips, so
  shrinking stays cheap.

  Accepted, not a leak: the masked column's *name* appearing in
  `changed_fields`. Change detection compares raw `NEW`/`OLD` values before
  redaction runs, so `changed_fields` legitimately shows that a masked
  value changed — this is an intended equality side channel, documented
  here and checked structurally by `LeakOracle.assert_structure!/3`.

  Out of scope: the global redacted capture function
  (`install_function(exclude:/mask:)`) — `mix threadline.gen.triggers` never
  emits it.

  Surfaces checked every iteration (D-10): raw stored `audit_changes` and
  `audit_transactions` rows (storage-qualified, bypassing the Ecto schema);
  `ChangeDiff` in its default, `expand_insert_fields: true`, and
  `format: :export_compat` variants; `to_csv_iodata/2` (with a generated
  `include_action_metadata`), `to_json_document/2` in `:wrapped` and
  `:ndjson`; `stream_export_rows/2` piped through `format_changes_iodata/3`
  for `:csv`, `:json_wrapped`, and `:ndjson`; and (D-14) one
  `"telemetry:<event>"` surface per `Threadline.Telemetry` event observed
  while the CSV/JSON/NDJSON exports above run — the inspected
  measurements/metadata, not the export's own data.
  `format_changes_iodata/3` over a plain Ecto read of the audit changes
  schema is not viable here because it needs the join's `tx_*` fields —
  hence `stream_export_rows/2`.
  """

  use Threadline.DataCase, async: false
  use ExUnitProperties

  import Threadline.Test.DbProperty
  import Threadline.Test.RedactionLeakGenerators
  import Threadline.TelemetryHelpers, only: [attach_telemetry!: 1]

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

  setup do
    event_names = Threadline.Telemetry.__events__() |> Enum.map(& &1.name)
    %{telemetry_ref: attach_telemetry!(event_names)}
  end

  property "no canary survives a redacted trigger/storage/diff/CSV/JSON/NDJSON round trip",
           %{telemetry_ref: telemetry_ref} do
    check all(plan <- op_plan_gen(), max_runs: @max_runs) do
      with_iteration(
        fn n -> delete_iteration!(@t, [row_id(n)]) end,
        fn n ->
          id = row_id(n)
          context = %{plan: plan, scrub: id}

          insert_values = row_values(plan.insert)
          insert_row!(id, insert_values)

          final_values = run_steps!(id, plan.steps, plan.paired, insert_values)

          expected_count = 1 + length(plan.steps)

          expected_count =
            if plan.delete? do
              delete_row!(id)
              expected_count + 1
            else
              # The final row state is still live; touching it here keeps
              # `final_values` from being flagged unused when delete? is true.
              _ = final_values
              expected_count
            end

          changes = LeakOracle.stored_changes(@t, id, repo_opts())

          assert length(changes) == expected_count,
                 "expected one change per planned op (insert + #{length(plan.steps)} step(s)" <>
                   if(plan.delete?, do: " + delete)", else: ")")

          {surfaces, telemetry_surfaces} =
            build_surfaces(
              id,
              changes,
              plan.include_action_metadata,
              length(changes),
              telemetry_ref
            )

          marker_surfaces =
            Enum.reject(surfaces, fn {name, _} ->
              name == "stored:audit_transactions" or String.starts_with?(name, "telemetry:")
            end)

          LeakOracle.refute_canaries!(surfaces, canaries(plan), context)
          LeakOracle.assert_markers!(marker_surfaces, markers(plan), context)

          LeakOracle.refute_canaries!(
            telemetry_surfaces,
            canaries(plan) ++ markers(plan),
            context
          )

          LeakOracle.assert_structure!(changes, id, context)
        end
      )
    end
  end

  defp row_id(n), do: Ecto.UUID.load!(<<n::128>>)
  defp uuid_param(id), do: Ecto.UUID.dump!(id)

  defp row_values(insert_plan) do
    %{
      secret_excluded: value(insert_plan.secret_excluded),
      secret_masked: value(insert_plan.secret_masked),
      profile_masked: value(insert_plan.profile_masked),
      bio: value(insert_plan.bio)
    }
  end

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

  defp delete_row!(id) do
    Repo.query!("DELETE FROM #{@t} WHERE id = $1::uuid", [uuid_param(id)])
  end

  defp profile_json(nil), do: nil
  defp profile_json(v), do: Jason.encode!(%{"k" => v, "l" => [v]})

  # Threads the row's current full state through 1-4 steps. Untouched
  # columns are resent unchanged (a real UPDATE statement must set every
  # column); `paired` runs two consecutive steps inside one
  # `Repo.transaction`, exercising the same-txid upsert (D-09).
  defp run_steps!(id, steps, paired, current) do
    indexed = Enum.with_index(steps)
    run_indexed_steps!(id, indexed, paired, current)
  end

  defp run_indexed_steps!(_id, [], _paired, current), do: current

  defp run_indexed_steps!(id, [{step, idx} | rest], paired, current) when paired == idx do
    case rest do
      [{next_step, _next_idx} | rest2] ->
        {:ok, next_current} =
          Repo.transaction(fn ->
            c1 = merge_step(current, step)
            update_row!(id, c1)
            c2 = merge_step(c1, next_step)
            update_row!(id, c2)
            c2
          end)

        run_indexed_steps!(id, rest2, paired, next_current)

      [] ->
        c1 = merge_step(current, step)
        update_row!(id, c1)
        c1
    end
  end

  defp run_indexed_steps!(id, [{step, _idx} | rest], paired, current) do
    c = merge_step(current, step)
    update_row!(id, c)
    run_indexed_steps!(id, rest, paired, c)
  end

  defp merge_step(current, %{kind: :touch_redacted, values: values, bio: bio}) do
    redacted = values |> Enum.map(fn {k, v} -> {k, value(v)} end) |> Map.new()
    current |> Map.merge(redacted) |> Map.put(:bio, value(bio))
  end

  defp merge_step(current, %{kind: :touch_plain_only, bio: bio}) do
    Map.put(current, :bio, value(bio))
  end

  defp merge_step(current, %{kind: :noop_update}), do: current

  defp build_surfaces(id, changes, include_meta, expected_count, telemetry_ref) do
    diff_default = Enum.map_join(changes, "\n", &Jason.encode!(ChangeDiff.from_audit_change(&1)))

    diff_expand =
      Enum.map_join(changes, "\n", fn change ->
        Jason.encode!(ChangeDiff.from_audit_change(change, expand_insert_fields: true))
      end)

    diff_export_compat =
      Enum.map_join(changes, "\n", fn change ->
        Jason.encode!(ChangeDiff.from_audit_change(change, format: :export_compat))
      end)

    filters = [table: @t, repo: Threadline.Test.Repo]

    # D-14: drain any stray pre-existing messages before the exports below
    # run, so the post-drain only ever reflects events this iteration
    # itself caused.
    discard_telemetry(telemetry_ref)

    {:ok, csv} = Export.to_csv_iodata(filters, include_action_metadata: include_meta)
    {:ok, json_wrapped} = Export.to_json_document(filters, json_format: :wrapped)
    {:ok, json_ndjson} = Export.to_json_document(filters, json_format: :ndjson)

    assert csv.returned_count == expected_count
    assert json_wrapped.returned_count == expected_count
    assert json_ndjson.returned_count == expected_count

    telemetry_events = drain_telemetry(telemetry_ref)
    assert_export_telemetry_structure!(telemetry_events, expected_count)

    telemetry_surfaces =
      Enum.map(telemetry_events, fn {event, measurements, metadata} ->
        {"telemetry:" <> Enum.map_join(event, ".", &Atom.to_string/1),
         inspect(measurements, limit: :infinity, printable_limit: :infinity) <>
           inspect(metadata, limit: :infinity, printable_limit: :infinity)}
      end)

    stream_rows = filters |> Export.stream_export_rows() |> Enum.to_list()

    stream_csv =
      Export.format_changes_iodata(stream_rows, :csv, include_action_metadata: include_meta)

    stream_json_wrapped = Export.format_changes_iodata(stream_rows, :json_wrapped)
    stream_ndjson = Export.format_changes_iodata(stream_rows, :ndjson)

    surfaces =
      LeakOracle.stored_surfaces(@t, id) ++
        [
          {"diff:default", diff_default},
          {"diff:expand_insert_fields", diff_expand},
          {"diff:export_compat", diff_export_compat},
          {"export:csv", IO.iodata_to_binary(csv.data)},
          {"export:json_wrapped", IO.iodata_to_binary(json_wrapped.data)},
          {"export:ndjson", IO.iodata_to_binary(json_ndjson.data)},
          {"stream:csv", IO.iodata_to_binary(stream_csv)},
          {"stream:json_wrapped", IO.iodata_to_binary(stream_json_wrapped)},
          {"stream:ndjson", IO.iodata_to_binary(stream_ndjson)}
        ] ++ telemetry_surfaces

    {surfaces, telemetry_surfaces}
  end

  # D-14: drains every `{event, ^ref, measurements, metadata}` message
  # currently queued for this test process, collecting each as
  # `{event, measurements, metadata}`.
  defp drain_telemetry(ref) do
    receive do
      {event, ^ref, measurements, metadata} ->
        [{event, measurements, metadata} | drain_telemetry(ref)]
    after
      0 -> []
    end
  end

  # Same mailbox walk as `drain_telemetry/1`, but discards instead of
  # collecting (used to clear the mailbox before the step whose events we
  # actually care about).
  defp discard_telemetry(ref) do
    receive do
      {_event, ^ref, _measurements, _metadata} -> discard_telemetry(ref)
    after
      0 -> :ok
    end
  end

  # Structural guard (D-14 / T-228-16): a detached or silently-no-op
  # handler must not let this property pass vacuously. Requires at least
  # one `[:threadline, :export, ...]` event, exactly three
  # `[:threadline, :export, :completed]` events (csv/json/ndjson, each
  # reporting the actual row count), and nothing else that would indicate a
  # partially-wired observer.
  defp assert_export_telemetry_structure!(telemetry_events, expected_count) do
    assert Enum.any?(telemetry_events, fn {event, _measurements, _metadata} ->
             Enum.take(event, 2) == [:threadline, :export]
           end),
           "no [:threadline, :export, ...] telemetry observed this iteration — a detached " <>
             "handler would let this property pass vacuously"

    completed =
      Enum.filter(telemetry_events, fn {event, _measurements, _metadata} ->
        event == [:threadline, :export, :completed]
      end)

    assert length(completed) == 3,
           "expected exactly 3 [:threadline, :export, :completed] events (csv/json/ndjson), " <>
             "got #{length(completed)}: #{inspect(completed)}"

    formats =
      completed
      |> Enum.map(fn {_event, _measurements, metadata} -> metadata.format end)
      |> Enum.sort()

    assert formats == [:csv, :json, :ndjson],
           "expected [:threadline, :export, :completed] formats [:csv, :json, :ndjson], got #{inspect(formats)}"

    for {_event, measurements, _metadata} <- completed do
      assert measurements.row_count == expected_count,
             "expected row_count #{expected_count}, got #{measurements.row_count}"
    end
  end
end
