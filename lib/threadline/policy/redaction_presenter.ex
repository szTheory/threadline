defmodule Threadline.Policy.RedactionPresenter do
  @moduledoc """
  Shared redaction drift presenter for Mix and LiveView parity.

  It compares validated configured policy against the deployed Threadline
  trigger SQL found in PostgreSQL catalogs. Parsing is intentionally narrow and
  fail-closed: only known `Threadline.Capture.TriggerSQL` fragments are trusted.
  """

  alias Ecto.Adapters.SQL
  alias Threadline.Capture.{RedactionPolicy, TriggerCaptureConfig}

  @group_order [:drift_detected, :could_not_introspect, :config_matches_deployed]
  @match_hint "Configured redaction matches deployed trigger redaction."
  @drift_hint "Configured redaction does not match deployed trigger SQL. Rerun `mix threadline.gen.triggers` and apply the migration."
  @introspect_hint "Could not inspect deployed trigger SQL. Rerun `mix threadline.gen.triggers`; do not assume capture is aligned."
  @missing_trigger_warning "No deployed Threadline trigger found for configured table."

  @type policy :: %{
          exclude: [String.t()],
          mask: [String.t()],
          mask_placeholder: String.t()
        }

  @doc """
  Builds a redaction drift report from the configured policy and live catalogs.
  """
  def build(opts) do
    repo = Keyword.fetch!(opts, :repo)
    schema = Keyword.get(opts, :schema, "public")

    build_report(TriggerCaptureConfig.load(), fetch_deployed(repo, schema))
  end

  @doc """
  Builds a redaction drift report from normalized config and deployed rows.
  """
  def build_report(configured_tables, deployed_rows) when is_map(configured_tables) and is_list(deployed_rows) do
    configured = Map.new(configured_tables, fn {table, entry} -> {table, normalize_policy(entry)} end)
    deployed_by_table = Enum.group_by(deployed_rows, &to_string(Map.fetch!(&1, :table)))

    tables =
      configured
      |> Map.keys()
      |> Kernel.++(Map.keys(deployed_by_table))
      |> Enum.uniq()
      |> Enum.sort()
      |> Enum.map(&build_row(&1, configured, deployed_by_table))
      |> Enum.sort_by(fn row -> {section_rank(row.status), row.table} end)

    grouped =
      Enum.map(@group_order, fn status ->
        {status, Enum.filter(tables, &(&1.status == status))}
      end)

    %{
      summary: %{
        drift_detected: Enum.count(tables, &(&1.status == :drift_detected)),
        could_not_introspect: Enum.count(tables, &(&1.status == :could_not_introspect)),
        config_matches_deployed: Enum.count(tables, &(&1.status == :config_matches_deployed))
      },
      tables: tables,
      grouped: grouped
    }
  end

  defp fetch_deployed(repo, schema) do
    sql = """
    SELECT
      c.relname AS table_name,
      t.tgname AS trigger_name,
      p.proname AS function_name,
      l.lanname AS function_language,
      p.prosrc AS function_source
    FROM pg_trigger t
    JOIN pg_class c ON t.tgrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_proc p ON t.tgfoid = p.oid
    JOIN pg_language l ON p.prolang = l.oid
    WHERE t.tgname LIKE 'threadline_audit_%'
      AND n.nspname = $1
      AND NOT t.tgisinternal
    ORDER BY c.relname, t.tgname
    """

    %{rows: rows} = SQL.query!(repo, sql, [schema])

    Enum.map(rows, fn [table, trigger_name, function_name, function_language, function_source] ->
      %{
        table: table,
        trigger_name: trigger_name,
        function_name: function_name,
        function_language: function_language,
        function_source: function_source
      }
    end)
  end

  defp build_row(table, configured, deployed_by_table) do
    configured_policy = Map.get(configured, table, empty_policy())
    deployed_rows = Map.get(deployed_by_table, table, [])

    case deployed_rows do
      [] ->
        status =
          if configured_policy == empty_policy() do
            :config_matches_deployed
          else
            :drift_detected
          end

        %{
          table: table,
          status: status,
          configured: configured_policy,
          deployed: nil,
          diff: diff(configured_policy, nil),
          warning: if(status == :drift_detected, do: @missing_trigger_warning),
          hint: hint_for(status)
        }

      [deployed_row] ->
        classify_row(table, configured_policy, deployed_row)

      _many ->
        %{
          table: table,
          status: :could_not_introspect,
          configured: configured_policy,
          deployed: nil,
          diff: diff(configured_policy, nil),
          warning: "Multiple deployed Threadline triggers found for table.",
          hint: @introspect_hint
        }
    end
  end

  defp classify_row(table, configured_policy, deployed_row) do
    case parse_deployed_policy(deployed_row) do
      {:ok, deployed_policy} ->
        row_diff = diff(configured_policy, deployed_policy)
        status = if matches?(row_diff), do: :config_matches_deployed, else: :drift_detected

        %{
          table: table,
          status: status,
          configured: configured_policy,
          deployed: deployed_policy,
          diff: row_diff,
          warning: nil,
          hint: hint_for(status)
        }

      {:error, {:unsupported_language, language}} ->
        %{
          table: table,
          status: :could_not_introspect,
          configured: configured_policy,
          deployed: nil,
          diff: diff(configured_policy, nil),
          warning: "Unsupported trigger function language: #{language}.",
          hint: @introspect_hint
        }

      {:error, reason} ->
        %{
          table: table,
          status: :could_not_introspect,
          configured: configured_policy,
          deployed: nil,
          diff: diff(configured_policy, nil),
          warning: warning_for_reason(reason),
          hint: @introspect_hint
        }
    end
  end

  defp parse_deployed_policy(%{function_language: language}) when language != "plpgsql" do
    {:error, {:unsupported_language, language}}
  end

  defp parse_deployed_policy(%{function_name: function_name, function_source: source}) do
    with :ok <- validate_function_name(function_name),
         :ok <- validate_threadline_shape(source),
         {:ok, exclude} <- parse_excludes(source),
         {:ok, {mask, placeholder}} <- parse_masking(source),
         :ok <- validate_changed_from_mask(source, mask, placeholder) do
      {:ok, normalize_policy(exclude: exclude, mask: mask, mask_placeholder: placeholder)}
    end
  end

  defp validate_function_name("threadline_capture_changes" <> _), do: :ok
  defp validate_function_name(_), do: {:error, :unexpected_function_name}

  defp validate_threadline_shape(source) do
    required = [
      "INSERT INTO audit_transactions",
      "INSERT INTO audit_changes",
      "threadline.actor_ref",
      "v_data_after",
      "TG_TABLE_NAME"
    ]

    if Enum.all?(required, &String.contains?(source, &1)) do
      :ok
    else
      {:error, :unexpected_function_shape}
    end
  end

  defp parse_excludes(source) do
    matches = Regex.scan(~r/v_data_after := v_data_after - '([^']+)';/, source, capture: :all_but_first)

    case bucket_fragment_occurrences(matches) do
      {:ok, []} -> {:ok, []}
      {:ok, values} -> {:ok, values |> List.flatten() |> Enum.sort()}
      {:error, _} = error -> error
    end
  end

  defp parse_masking(source) do
    matches =
      Regex.scan(
        ~r/v_data_after := v_data_after \|\| jsonb_build_object\((.+?)\);/,
        source,
        capture: :all_but_first
      )

    with {:ok, []} <- bucket_fragment_occurrences(matches) do
      {:ok, {[], RedactionPolicy.default_placeholder()}}
    else
      {:ok, [[fragment]]} ->
        parse_mask_fragment(fragment)

      {:ok, fragments} ->
        case Enum.uniq(fragments) do
          [[fragment]] -> parse_mask_fragment(fragment)
          _ -> {:error, :ambiguous_masking}
        end

      {:error, _} = error ->
        error
    end
  end

  defp validate_changed_from_mask(source, expected_mask, expected_placeholder) do
    matches =
      Regex.scan(
        ~r/WHEN u\.k = ANY\(ARRAY\[(.*?)\]::text\[\]\) THEN to_jsonb\('([^']*)'::text\)/,
        source,
        capture: :all_but_first
      )

    case repeated_or_single(matches) do
      [] ->
        :ok

      [[columns_fragment, placeholder]] ->
        with {:ok, mask} <- parse_mask_columns_fragment(columns_fragment),
             true <- mask == expected_mask and placeholder == expected_placeholder do
          :ok
        else
          false -> {:error, :changed_from_mask_mismatch}
          {:error, _} = error -> error
        end

      :ambiguous ->
        {:error, :ambiguous_changed_from_mask}
    end
  end

  defp parse_mask_fragment(fragment) do
    pieces = String.split(fragment, ~r/,\s*/)

    if rem(length(pieces), 2) != 0 do
      {:error, :unexpected_mask_fragment}
    else
      pairs = Enum.chunk_every(pieces, 2)

      parsed =
        Enum.reduce_while(pairs, [], fn [column_expr, value_expr], acc ->
          with [_, column] <- Regex.run(~r/^'([^']+)'$/, column_expr),
               [_, placeholder] <- Regex.run(~r/^to_jsonb\('([^']*)'::text\)$/, value_expr) do
            {:cont, [{column, placeholder} | acc]}
          else
            _ -> {:halt, :error}
          end
        end)

      case parsed do
        :error ->
          {:error, :unexpected_mask_fragment}

        list ->
          parsed_list = Enum.reverse(list)
          placeholders = Enum.map(parsed_list, &elem(&1, 1)) |> Enum.uniq()

          case placeholders do
            [placeholder] ->
              {:ok, {Enum.map(parsed_list, &elem(&1, 0)) |> Enum.sort(), placeholder}}

            _ ->
              {:error, :ambiguous_mask_placeholder}
          end
      end
    end
  end

  defp parse_mask_columns_fragment(""), do: {:ok, []}

  defp parse_mask_columns_fragment(fragment) do
    columns =
      fragment
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn item ->
        case Regex.run(~r/^'([^']+)'$/, item) do
          [_, column] -> {:ok, column}
          _ -> :error
        end
      end)

    if Enum.all?(columns, &match?({:ok, _}, &1)) do
      {:ok, columns |> Enum.map(fn {:ok, column} -> column end) |> Enum.sort()}
    else
      {:error, :unexpected_mask_columns_fragment}
    end
  end

  defp bucket_fragment_occurrences(matches) do
    case rem(length(matches), 2) do
      0 ->
        buckets =
          matches
          |> Enum.chunk_every(2)
          |> Enum.map(fn
            [left, right] when left == right -> left
            _ -> :mismatch
          end)

        if Enum.any?(buckets, &(&1 == :mismatch)) do
          {:error, :ambiguous_fragment_repetition}
        else
          {:ok, buckets}
        end

      _ when matches == [] ->
        {:ok, []}

      _ ->
        {:error, :ambiguous_fragment_repetition}
    end
  end

  defp repeated_or_single([]), do: []
  defp repeated_or_single([match]), do: [match]

  defp repeated_or_single(matches) do
    case bucket_fragment_occurrences(matches) do
      {:ok, deduped} -> deduped
      {:error, _} -> :ambiguous
    end
  end

  defp normalize_policy(entry) when is_map(entry), do: entry |> Enum.into([]) |> normalize_policy()

  defp normalize_policy(entry) when is_list(entry) do
    exclude = normalize_columns(Keyword.get(entry, :exclude, []))
    mask = normalize_columns(Keyword.get(entry, :mask, []))
    placeholder = Keyword.get(entry, :mask_placeholder, RedactionPolicy.default_placeholder())

    %{
      exclude: exclude,
      mask: mask,
      mask_placeholder: placeholder
    }
  end

  defp normalize_policy(_), do: empty_policy()

  defp empty_policy do
    %{
      exclude: [],
      mask: [],
      mask_placeholder: RedactionPolicy.default_placeholder()
    }
  end

  defp normalize_columns(list) when is_list(list) do
    list
    |> Enum.map(&to_string/1)
    |> Enum.sort()
  end

  defp normalize_columns(_), do: []

  defp diff(configured, deployed) do
    deployed_policy = deployed || empty_policy()
    placeholder_mismatch =
      (configured.mask != [] or deployed_policy.mask != []) and
        configured.mask_placeholder != deployed_policy.mask_placeholder

    %{
      exclude_only_in_config: configured.exclude -- deployed_policy.exclude,
      exclude_only_in_deployed: deployed_policy.exclude -- configured.exclude,
      mask_only_in_config: configured.mask -- deployed_policy.mask,
      mask_only_in_deployed: deployed_policy.mask -- configured.mask,
      placeholder_mismatch: placeholder_mismatch
    }
  end

  defp matches?(row_diff) do
    row_diff.exclude_only_in_config == [] and
      row_diff.exclude_only_in_deployed == [] and
      row_diff.mask_only_in_config == [] and
      row_diff.mask_only_in_deployed == [] and
      row_diff.placeholder_mismatch == false
  end

  defp warning_for_reason(:unexpected_function_name),
    do: "Deployed trigger function name is not a Threadline-generated shape."

  defp warning_for_reason(:unexpected_function_shape),
    do: "Deployed trigger SQL did not match the expected Threadline trigger shape."

  defp warning_for_reason(:ambiguous_fragment_repetition),
    do: "Deployed trigger SQL contained ambiguous redaction fragments."

  defp warning_for_reason(:unexpected_mask_fragment),
    do: "Deployed trigger SQL contained an unsupported mask fragment."

  defp warning_for_reason(:unexpected_mask_columns_fragment),
    do: "Deployed trigger SQL contained an unsupported changed_from mask fragment."

  defp warning_for_reason(:changed_from_mask_mismatch),
    do: "Deployed trigger SQL contained inconsistent mask behavior across fragments."

  defp warning_for_reason(:ambiguous_masking),
    do: "Deployed trigger SQL contained ambiguous masking fragments."

  defp warning_for_reason(:ambiguous_mask_placeholder),
    do: "Deployed trigger SQL contained multiple mask placeholders."

  defp warning_for_reason(:ambiguous_changed_from_mask),
    do: "Deployed trigger SQL contained ambiguous changed_from masking."

  defp warning_for_reason(_),
    do: "Could not inspect deployed Threadline trigger SQL."

  defp hint_for(:config_matches_deployed), do: @match_hint
  defp hint_for(:drift_detected), do: @drift_hint
  defp section_rank(status), do: Enum.find_index(@group_order, &(&1 == status)) || length(@group_order)
end
