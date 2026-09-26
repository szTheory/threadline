defmodule Threadline.Capture.TriggerBodyInvariantsTest do
  @moduledoc """
  Pins the durable no-catalog-lookup guarantee (no database, pure string
  assertions over generated SQL) so a regression is caught by the default
  `mix test`, not only by a real-PostgreSQL integration test.

  Every capture-function body — global and per-table, with and without
  redaction — must resolve its primary key from trigger arguments alone.
  Catalog lookups, dynamic statements, and per-row aggregates belong only
  in the migrate-time `DO` block (`Threadline.Capture.PrimaryKeySQL`),
  which this test does not scan: it is generated SQL that legitimately
  reads the catalog once, at DDL time, never once per row.
  """

  use ExUnit.Case, async: true

  alias Threadline.Capture.TriggerSQL

  # Anchors extraction on the $threadline_trigger$ delimiters so a body that
  # cannot be found fails loudly (no match) instead of the test vacuously
  # passing against captured nothing.
  @body_delimiters ~r/\$threadline_trigger\$\n(.*?)\n\$threadline_trigger\$/s

  # DO blocks legitimately read pg_index, to_regclass and EXECUTE at
  # migrate time; this regex only ever runs against text extracted from
  # inside the $threadline_trigger$ delimiters, so a DO block's own use of
  # these tokens is out of scope by construction, not by a looser regex.
  @forbidden ~r/\bpg_(index|attribute|class|namespace|constraint|trigger)\b|pg_catalog|information_schema|TG_RELID|regclass|to_reg\w+|\bEXECUTE\b/i

  # Every generated capture-function body this test covers, labeled.
  defp statements do
    [
      {"install_function([])", TriggerSQL.install_function([])},
      {"install_function(exclude: [\"secret\"])",
       TriggerSQL.install_function(exclude: ["secret"])},
      {"install_function_for_table(store_changed_from: true)",
       TriggerSQL.install_function_for_table("pk_inv_a", store_changed_from: true)},
      {"install_function_for_table(store_changed_from: true, except_columns: [\"updated_at\"])",
       TriggerSQL.install_function_for_table("pk_inv_a",
         store_changed_from: true,
         except_columns: ["updated_at"]
       )},
      {"install_function_for_table(mask: [\"email\"])",
       TriggerSQL.install_function_for_table("pk_inv_a", mask: ["email"])},
      {"install_function_for_table(mask: [...], exclude: [...], store_changed_from: true)",
       TriggerSQL.install_function_for_table("pk_inv_a",
         mask: ["email"],
         exclude: ["notes"],
         store_changed_from: true
       )}
    ]
  end

  # The per-table option sets, reused to build a second table's function for
  # the "differ only on the function name" comparison below.
  defp per_table_option_sets do
    [
      [store_changed_from: true],
      [store_changed_from: true, except_columns: ["updated_at"]],
      [mask: ["email"]],
      [mask: ["email"], exclude: ["notes"], store_changed_from: true]
    ]
  end

  # Extracts the single function body between the $threadline_trigger$
  # delimiters. A body that cannot be found (no match, or more than one)
  # fails the match instead of silently returning nothing to assert against.
  defp extract_body!(sql) do
    assert [[_, body]] = Regex.scan(@body_delimiters, sql)
    body
  end

  test "every generated body extracts exactly one match with no forbidden token" do
    for {label, sql} <- statements() do
      body = extract_body!(sql)

      refute body =~ @forbidden,
             "#{label}: forbidden catalog/dynamic token found in the body: #{body}"

      refute body =~ ~r/unnest\(\s*TG_ARGV/i, "#{label}: unnest(TG_ARGV) aggregate found"
    end
  end

  test "every generated body reads the key from TG_ARGV and ends with a coalesce" do
    for {label, sql} <- statements() do
      body = extract_body!(sql)

      assert body =~ "TG_ARGV[i]", "#{label}: TG_ARGV[i] missing"
      assert body =~ "coalesce(v_table_pk, '{}'::jsonb)", "#{label}: final coalesce missing"
    end
  end

  test "the no-arguments legacy branch quotes only 'id' and '{}'" do
    for {label, sql} <- statements() do
      body = extract_body!(sql)

      [legacy_branch] =
        Regex.run(~r/IF TG_NARGS = 0 THEN.*?END IF;\s*\n\s*ELSE/s, body, capture: :first)

      literals =
        ~r/'([^']*)'/
        |> Regex.scan(legacy_branch)
        |> Enum.map(fn [_, literal] -> literal end)
        |> Enum.uniq()

      assert literals -- ["id", "{}"] == [],
             "#{label}: unexpected literal in the no-arguments legacy branch: #{inspect(literals)}"
    end
  end

  test "per-table bodies for two different tables differ only on the function name" do
    for opts <- per_table_option_sets() do
      a = TriggerSQL.install_function_for_table("pk_inv_a", opts)
      b = TriggerSQL.install_function_for_table("billing.pk_inv_b", opts)

      [a_head | a_rest] = String.split(a, "\n")
      [b_head | b_rest] = String.split(b, "\n")

      refute a_head == b_head, "expected distinct function names, got: #{a_head}"
      assert String.starts_with?(a_head, "CREATE OR REPLACE FUNCTION")
      assert String.starts_with?(b_head, "CREATE OR REPLACE FUNCTION")
      assert a_rest == b_rest, "bodies differ beyond the function-name line for #{inspect(opts)}"
    end
  end
end
