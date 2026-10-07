defmodule Threadline.Guides.TableShapesContractTest do
  use ExUnit.Case, async: true

  @guide "guides/supported-tables.md"
  @primary_key_sql "lib/threadline/capture/primary_key_sql.ex"
  @required_claims [
    "One-column, composite, or non-`id` primary key",
    "smallint`, `integer`, `bigint`, `text`, `varchar`, `char`, `citext`, `uuid`, `date`, `timestamp without time zone",
    "an enum",
    "a domain over one of those types",
    "Table without a primary key",
    "`primary_key:`",
    "exactly equal the key columns",
    "valid, ready, immediate, unconditional, non-expression unique index",
    "every indexed key column must be `NOT NULL`",
    "Subsets, supersets, `INCLUDE` columns, partial indexes, expression indexes, deferred indexes, and nullable key columns do not qualify",
    "Schema-qualified table",
    "`schema.table`",
    "63 **bytes**",
    "`char(n)` key",
    "original blank padding",
    "Partitioned table",
    "clones its row trigger to partitions",
    "physical leaf relation",
    "Unlogged table",
    "truncates it after a crash or unclean shutdown",
    "audit trail may no longer match the source table's post-crash state",
    "View",
    "row-level `AFTER INSERT OR UPDATE OR DELETE` trigger",
    "test/threadline/capture/trigger_pk_shapes_test.exs",
    "test/threadline/capture/trigger_pk_override_test.exs",
    "test/threadline/capture/trigger_migrate_time_errors_test.exs",
    "test/threadline/capture/naming_test.exs"
  ]

  test "every named table shape states its conditions, caveat, and evidence" do
    guide = File.read!(@guide)

    for claim <- @required_claims do
      assert guide =~ claim, "supported-tables guide is missing: #{claim}"
    end
  end

  test "the override and type conditions remain tied to implementation" do
    source = File.read!(@primary_key_sql)

    for source_claim <- [
          "indisunique AND i.indisvalid AND i.indisready AND i.indimmediate",
          "i.indpred IS NULL AND i.indexprs IS NULL",
          "a.attnotnull",
          "Supported types: smallint, integer, bigint, text, varchar, char, citext, uuid, date, timestamp without time zone, enum types, and domains over these"
        ] do
      assert source =~ source_claim, "source no longer proves #{source_claim}"
    end
  end

  test "removing a support row claim fails the document contract" do
    guide = File.read!(@guide)

    mutated =
      String.replace(
        guide,
        "| Unlogged table | Accepted with durability risk |",
        "| Removed | Removed |"
      )

    assert "Unlogged table" in missing_claims(mutated)
  end

  defp missing_claims(guide), do: Enum.reject(@required_claims, &String.contains?(guide, &1))
end
