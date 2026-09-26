defmodule Threadline.Health.TriggerFindings do
  @moduledoc false

  alias Threadline.Capture.{Naming, TriggerCaptureConfig}
  alias Threadline.Health.{Finding, TriggerCatalog}
  alias Threadline.StorageSchema

  @doc false
  @spec codes() :: [Finding.code()]
  def codes do
    [
      :legacy_trigger_no_pk_args,
      :pk_drift,
      :shared_capture_function,
      :duplicate_capture_trigger,
      :capture_trigger_disabled
    ]
  end

  @doc false
  @spec run(keyword()) :: [Finding.t()]
  def run(opts) do
    repo = Keyword.fetch!(opts, :repo)
    requested_schemas = normalize_schema(opts)
    # Called unwrapped, so a malformed :trigger_capture config raises the
    # same ArgumentError TriggerCaptureConfig.load/0 raises.
    config = TriggerCaptureConfig.load()

    triggers =
      repo
      |> TriggerCatalog.threadline_triggers()
      |> reject_storage_own_tables()

    keys = TriggerCatalog.primary_keys(repo)
    columns = TriggerCatalog.live_columns(repo)
    shared_groups = TriggerCatalog.shared_functions(repo)

    findings =
      (disabled_findings(triggers) ++
         duplicate_findings(triggers) ++
         key_findings(repo, triggers, keys, columns, config) ++ shared_findings(shared_groups))
      |> filter_by_schema(requested_schemas)
      |> Enum.sort_by(&{&1.schema, &1.table, Atom.to_string(&1.code), &1.message})

    emit_telemetry(findings)

    findings
  end

  defp normalize_schema(opts) do
    case Keyword.fetch(opts, :schema) do
      :error ->
        nil

      {:ok, schema} when is_binary(schema) ->
        [schema]

      {:ok, [_ | _] = list} ->
        if Enum.all?(list, &is_binary/1) do
          list
        else
          invalid_schema!(list)
        end

      {:ok, other} ->
        invalid_schema!(other)
    end
  end

  defp invalid_schema!(value) do
    raise ArgumentError,
          ":schema must be a string or a non-empty list of strings, got: #{inspect(value)}"
  end

  defp reject_storage_own_tables(rows) do
    storage_schema = StorageSchema.get()

    Enum.reject(rows, fn row ->
      row.schema == storage_schema and StorageSchema.threadline_table?(row.table)
    end)
  end

  defp filter_by_schema(findings, nil), do: findings

  defp filter_by_schema(findings, schemas),
    do: Enum.filter(findings, &(&1.schema in schemas))

  defp emit_telemetry(findings) do
    errors = Enum.count(findings, &(&1.severity == :error))
    warnings = Enum.count(findings, &(&1.severity == :warning))
    Threadline.Telemetry.emit_findings_checked(errors, warnings)
  end

  # capture_trigger_disabled: a Threadline trigger that is disabled ('D') or
  # fires only for replica sessions ('R').
  defp disabled_findings(rows) do
    rows
    |> Enum.filter(&(&1.enabled in ["D", "R"]))
    |> Enum.map(&disabled_finding/1)
  end

  defp disabled_finding(%{schema: schema, table: table, trigger: trigger, enabled: enabled}) do
    %Finding{
      code: :capture_trigger_disabled,
      severity: :error,
      schema: schema,
      table: table,
      message: disabled_message(schema, table, trigger, enabled),
      details: %{trigger: trigger, enabled_state: enabled}
    }
  end

  defp disabled_message(schema, table, trigger, "D") do
    "#{schema}.#{table}: the capture trigger \"#{trigger}\" is disabled; writes are not " <>
      "being captured. Fix: ALTER TABLE #{quote_identifier(schema)}.#{quote_identifier(table)} " <>
      "ENABLE TRIGGER #{quote_identifier(trigger)};"
  end

  defp disabled_message(schema, table, trigger, "R") do
    "#{schema}.#{table}: the capture trigger \"#{trigger}\" fires only for replica sessions " <>
      "under session_replication_role = replica; ordinary application writes are not being " <>
      "captured. Fix: ALTER TABLE #{quote_identifier(schema)}.#{quote_identifier(table)} " <>
      "ENABLE ALWAYS TRIGGER #{quote_identifier(trigger)};"
  end

  # duplicate_capture_trigger: more than one Threadline trigger on the same
  # {schema, table} — the group key, never the bare table name, so same-named
  # tables in different schemas stay separate.
  defp duplicate_findings(rows) do
    rows
    |> Enum.group_by(&{&1.schema, &1.table})
    |> Enum.flat_map(fn {{schema, table}, group} -> duplicate_finding(schema, table, group) end)
  end

  defp duplicate_finding(_schema, _table, [_single]), do: []

  defp duplicate_finding(schema, table, group) do
    names = group |> Enum.map(& &1.trigger) |> Enum.sort()
    canonical = canonical_trigger_name(schema, table)
    extra = Enum.reject(names, &(&1 == canonical))

    [
      %Finding{
        code: :duplicate_capture_trigger,
        severity: :error,
        schema: schema,
        table: table,
        message: duplicate_message(schema, table, names, extra),
        details: %{triggers: names, canonical: canonical, extra: extra}
      }
    ]
  end

  defp canonical_trigger_name(schema, table) do
    Naming.trigger_name(%{schema: schema, table: table})
  rescue
    ArgumentError -> nil
  end

  defp duplicate_message(schema, table, names, extra) do
    qualified = "#{schema}.#{table}"

    drops =
      Enum.map_join(extra, " ", fn name ->
        "DROP TRIGGER #{quote_identifier(name)} ON #{quote_identifier(schema)}.#{quote_identifier(table)};"
      end)

    "#{qualified}: #{length(names)} Threadline capture triggers record every write more than " <>
      "once (#{Enum.join(names, ", ")}). Fix: #{drops} then #{fix_command(schema, table)} " <>
      "to confirm the canonical trigger."
  end

  defp quote_identifier(name), do: ~s("#{String.replace(name, "\"", "\"\"")}")

  # legacy_trigger_no_pk_args / pk_drift: compares the CANONICAL Threadline
  # trigger's recorded key set (from tgargs, or the legacy implicit {"id"}
  # for a no-argument trigger) against its expected key set — the set
  # `mix threadline.gen.triggers` would record if run now. Only the
  # canonical trigger per {schema, table} is checked: an extra/duplicate
  # trigger already gets its own :duplicate_capture_trigger finding, and
  # checking it too would double-report the same underlying problem (or, for
  # a no-argument copy trigger, misreport a legacy-key warning for a trigger
  # that is going to be dropped anyway). When no trigger in a duplicated
  # group matches the canonical name, the key check is skipped for that
  # table until the duplicates are resolved.
  #
  # Set equality only: recorded/expected are MapSets, never sorted-list
  # comparisons, and no column name is ever downcased or trimmed.
  defp key_findings(repo, triggers, keys, columns, config) do
    triggers
    |> Enum.group_by(&{&1.schema, &1.table})
    |> Enum.flat_map(fn {{schema, table}, group} ->
      case canonical_trigger_for_key_check(schema, table, group) do
        nil -> []
        trigger -> key_finding(repo, trigger, keys, columns, config)
      end
    end)
  end

  defp canonical_trigger_for_key_check(_schema, _table, [single]), do: single

  defp canonical_trigger_for_key_check(schema, table, group) do
    canonical_name = canonical_trigger_name(schema, table)
    Enum.find(group, &(&1.trigger == canonical_name))
  end

  defp key_finding(repo, trigger, keys, columns, config) do
    recorded = recorded_key(trigger)
    {expected, unresolved_reason, unresolved_extra} = expected_key(repo, trigger, keys, config)
    live_cols = Map.get(columns, trigger.relid, MapSet.new())
    missing = missing_key_columns(trigger, unresolved_reason, recorded, live_cols)

    cond do
      unresolved_reason != nil ->
        [pk_drift(trigger, recorded, expected, unresolved_reason, unresolved_extra)]

      missing != [] ->
        [
          pk_drift(trigger, recorded, expected, :recorded_column_missing, %{
            missing_columns: Enum.sort(missing)
          })
        ]

      trigger.nargs == 0 and MapSet.equal?(expected, MapSet.new(["id"])) ->
        [legacy_warning(trigger, recorded, expected)]

      trigger.nargs == 0 ->
        [pk_drift(trigger, recorded, expected, :legacy_trigger_on_non_id_key, %{})]

      not MapSet.equal?(recorded, expected) ->
        [pk_drift(trigger, recorded, expected, :key_mismatch, %{})]

      true ->
        []
    end
  end

  defp recorded_key(%{nargs: 0}), do: MapSet.new(["id"])
  defp recorded_key(%{args: args}), do: MapSet.new(args)

  # A recorded column is missing (renamed or dropped) only when no live
  # column of the table matches it under any case — a column that exists
  # under different casing is a byte-exact :key_mismatch, not a rename, so
  # this is the one comparison in this module that folds case, and only to
  # pick a reason, never to decide whether recorded == expected.
  defp missing_key_columns(%{nargs: nargs}, unresolved_reason, _recorded, _live_cols)
       when nargs == 0 or not is_nil(unresolved_reason),
       do: []

  defp missing_key_columns(_trigger, _unresolved_reason, recorded, live_cols) do
    live_lower = MapSet.new(live_cols, &String.downcase/1)

    recorded
    |> MapSet.to_list()
    |> Enum.reject(&MapSet.member?(live_lower, String.downcase(&1)))
  end

  # Expected key set: the configured primary_key: override when a qualifying
  # index exists, else the live primary key, else none — the same
  # resolution `mix threadline.gen.triggers` performs. Returns
  # {expected_or_nil, unresolved_reason_or_nil, extra_details_map}.
  defp expected_key(repo, trigger, keys, config) do
    qualified = "#{trigger.schema}.#{trigger.table}"
    live_pk = Map.get(keys, trigger.relid)

    case find_override(config, qualified) do
      nil ->
        case live_pk do
          nil -> {nil, :no_primary_key, %{}}
          cols -> {MapSet.new(cols), nil, %{}}
        end

      declared ->
        override_expected_key(repo, trigger.relid, declared, live_pk)
    end
  end

  defp override_expected_key(_repo, _relid, declared, live_pk) when not is_nil(live_pk) do
    {nil, :override_on_table_with_primary_key, %{declared_key: Enum.sort(declared)}}
  end

  defp override_expected_key(repo, relid, declared, nil) do
    if TriggerCatalog.qualifying_override_index?(repo, relid, declared) do
      {MapSet.new(declared), nil, %{}}
    else
      {nil, :override_without_qualifying_index, %{declared_key: Enum.sort(declared)}}
    end
  end

  defp find_override(config, qualified) do
    Enum.find_value(config, fn {key, entry} ->
      if Naming.qualified(key) == qualified, do: Keyword.get(entry, :primary_key)
    end)
  end

  defp sorted_key(nil), do: nil
  defp sorted_key(set), do: set |> MapSet.to_list() |> Enum.sort()

  defp fix_command(schema, table), do: "mix threadline.gen.triggers --tables #{schema}.#{table}"

  defp legacy_warning(%{schema: schema, table: table} = trigger, recorded, expected) do
    %Finding{
      code: :legacy_trigger_no_pk_args,
      severity: :warning,
      schema: schema,
      table: table,
      message: legacy_warning_message(trigger),
      details: %{
        trigger: trigger.trigger,
        recorded_key: sorted_key(recorded),
        expected_key: sorted_key(expected)
      }
    }
  end

  defp legacy_warning_message(%{schema: schema, table: table, trigger: trigger}) do
    qualified = "#{schema}.#{table}"

    "#{qualified}: the capture trigger \"#{trigger}\" was installed before primary keys " <>
      "were recorded (it has no trigger arguments) and still records the id column. " <>
      "Fix: #{fix_command(schema, table)}, then mix ecto.migrate."
  end

  defp pk_drift(%{schema: schema, table: table} = trigger, recorded, expected, reason, extra) do
    %Finding{
      code: :pk_drift,
      severity: :error,
      schema: schema,
      table: table,
      message: pk_drift_message(trigger, recorded, expected, reason, extra),
      details:
        Map.merge(
          %{
            trigger: trigger.trigger,
            recorded_key: sorted_key(recorded),
            expected_key: sorted_key(expected),
            reason: reason
          },
          extra
        )
    }
  end

  defp pk_drift_message(
         %{schema: schema, table: table, trigger: name},
         recorded,
         expected,
         reason,
         extra
       ) do
    qualified = "#{schema}.#{table}"
    recorded_str = format_key(recorded)
    fix = "#{fix_command(schema, table)}, then mix ecto.migrate."

    "#{qualified}: the capture trigger \"#{name}\" recorded key #{recorded_str}, but " <>
      pk_drift_reason_text(qualified, expected, reason, extra) <> " Fix: #{fix}"
  end

  defp pk_drift_reason_text(_qualified, expected, :key_mismatch, _extra) do
    "the expected key is #{format_key(expected)}."
  end

  defp pk_drift_reason_text(qualified, expected, :legacy_trigger_on_non_id_key, _extra) do
    "it has no trigger arguments (a legacy no-argument trigger implicitly records id), " <>
      "while #{qualified}'s expected key is #{format_key(expected)}."
  end

  defp pk_drift_reason_text(qualified, _expected, :no_primary_key, _extra) do
    "#{qualified} has no primary key and no configured override, so its expected key " <>
      "could not be resolved. Declare one with: " <>
      ~s(config :threadline, :trigger_capture, tables: %{"#{qualified}" => ) <>
      ~s([primary_key: ["column_name"]]}, backed by a unique index over NOT NULL columns.)
  end

  defp pk_drift_reason_text(qualified, _expected, :override_without_qualifying_index, extra) do
    declared = extra |> Map.fetch!(:declared_key) |> format_key_list()

    "the configured primary_key: override #{declared} for #{qualified} has no qualifying " <>
      "unique index. Create a unique, non-partial, immediate index over exactly those " <>
      "NOT NULL columns."
  end

  defp pk_drift_reason_text(qualified, _expected, :override_on_table_with_primary_key, extra) do
    declared = extra |> Map.fetch!(:declared_key) |> format_key_list()

    "#{qualified} already has a primary key, so its configured primary_key: override " <>
      "#{declared} is not needed. Remove primary_key: from this table's :trigger_capture entry."
  end

  defp pk_drift_reason_text(qualified, _expected, :recorded_column_missing, extra) do
    missing = extra |> Map.fetch!(:missing_columns) |> format_key_list()

    "the recorded column(s) #{missing} no longer exist on #{qualified} (renamed or dropped)."
  end

  defp format_key(nil), do: "none"
  defp format_key(set), do: set |> sorted_key() |> format_key_list()

  defp format_key_list(list), do: "(" <> Enum.join(list, ", ") <> ")"

  # shared_capture_function: one per-table capture function referenced by
  # Threadline triggers on more than one table. One finding is emitted per
  # affected table, every one naming every table that shares the function
  # and the single fix command that regenerates all of them together —
  # never one table at a time, since regenerating only one of a colliding
  # pair would leave the other applying the wrong redaction rules or stop
  # the migration. The storage schema's own audit tables are excluded from
  # each group the same way every other finding excludes them; a group left
  # with fewer than two tables after that is no longer a sharing problem
  # and is dropped.
  defp shared_findings(groups) do
    storage_schema = StorageSchema.get()

    groups
    |> Enum.map(fn group ->
      tables =
        Enum.reject(group.tables, fn {schema, table} ->
          schema == storage_schema and StorageSchema.threadline_table?(table)
        end)

      %{group | tables: tables}
    end)
    |> Enum.filter(&(length(&1.tables) > 1))
    |> Enum.flat_map(&shared_finding_group/1)
  end

  defp shared_finding_group(%{function_schema: fschema, function: fname, tables: tables}) do
    qualified_tables = tables |> Enum.map(fn {s, t} -> "#{s}.#{t}" end) |> Enum.sort()
    function_qualified = "#{fschema}.#{fname}"

    Enum.map(tables, fn {schema, table} ->
      %Finding{
        code: :shared_capture_function,
        severity: :error,
        schema: schema,
        table: table,
        message: shared_message(schema, table, function_qualified, qualified_tables),
        details: %{function: function_qualified, tables: qualified_tables}
      }
    end)
  end

  defp shared_message(schema, table, function_qualified, qualified_tables) do
    qualified = "#{schema}.#{table}"
    others = Enum.reject(qualified_tables, &(&1 == qualified))
    fix_tables = Enum.join(qualified_tables, ",")

    "#{qualified}: its capture trigger's function #{function_qualified} is also used by " <>
      "#{Enum.join(others, ", ")}; #{qualified} may now apply another table's redaction " <>
      "rules. Fix: mix threadline.gen.triggers --tables #{fix_tables}, then mix ecto.migrate."
  end
end
