defmodule Threadline.SchemaFieldsContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.AuditAction

  @schema_contracts [
    {AuditChange, "Threadline.Capture.AuditChange",
     ~w(id transaction_id table_schema table_name table_pk op data_after changed_fields changed_from captured_at)a},
    {AuditTransaction, "Threadline.Capture.AuditTransaction",
     ~w(id txid occurred_at actor_ref action_id source)a},
    {AuditAction, "Threadline.Semantics.AuditAction",
     ~w(id name actor_ref status reason correlation_id inserted_at)a}
  ]

  test "stable field subsets are documented and present in their schemas" do
    for {schema, name, stable_fields} <- @schema_contracts do
      section = stable_fields_section!(schema)
      errors = contract_errors(name, stable_fields, schema.__schema__(:fields), section)

      assert errors == [], format_errors(errors)
    end

    transaction_fields = AuditTransaction.__schema__(:fields)
    refute :meta in stable_fields(AuditTransaction)
    assert :meta in transaction_fields

    assert contract_errors(
             "Threadline.Capture.AuditTransaction",
             stable_fields(AuditTransaction),
             transaction_fields,
             stable_fields_section!(AuditTransaction)
           ) == []
  end

  test "AuditChange stable snapshot documentation limits the JSON and list promises" do
    section = stable_fields_section!(AuditChange) |> String.replace(~r/\s+/, " ")

    assert section =~ "`data_after` and `changed_from` are additive JSONB maps"
    assert section =~ "keys and shapes may be added in 1.x"
    assert section =~ "`changed_fields` is an additive list of text column names"
    assert section =~ "do not guarantee byte-stable JSON serialization or key order"
    assert section =~ "existing rows are not rewritten"
  end

  test "AuditChange removal mutation control catches a missing schema field and doc claim" do
    name = "Threadline.Capture.AuditChange"
    fields = stable_fields(AuditChange)
    schema_fields = AuditChange.__schema__(:fields)
    section = stable_fields_section!(AuditChange)

    schema_mutation = contract_errors(name, fields, schema_fields -- [:table_name], section)
    assert {name, :table_name, :missing_schema_field} in schema_mutation

    doc_mutation = String.replace(section, "`table_name`", "table_name", global: false)
    doc_errors = contract_errors(name, fields, schema_fields, doc_mutation)
    assert {name, :table_name, :missing_documented_field} in doc_errors
  end

  test "AuditTransaction removal mutation control catches a missing schema field and doc claim" do
    name = "Threadline.Capture.AuditTransaction"
    fields = stable_fields(AuditTransaction)
    schema_fields = AuditTransaction.__schema__(:fields)
    section = stable_fields_section!(AuditTransaction)

    schema_mutation = contract_errors(name, fields, schema_fields -- [:actor_ref], section)
    assert {name, :actor_ref, :missing_schema_field} in schema_mutation

    doc_mutation = String.replace(section, "`actor_ref`", "actor_ref", global: false)
    doc_errors = contract_errors(name, fields, schema_fields, doc_mutation)
    assert {name, :actor_ref, :missing_documented_field} in doc_errors
  end

  test "AuditAction removal mutation control catches a missing schema field and doc claim" do
    name = "Threadline.Semantics.AuditAction"
    fields = stable_fields(AuditAction)
    schema_fields = AuditAction.__schema__(:fields)
    section = stable_fields_section!(AuditAction)

    schema_mutation = contract_errors(name, fields, schema_fields -- [:correlation_id], section)
    assert {name, :correlation_id, :missing_schema_field} in schema_mutation

    doc_mutation = String.replace(section, "`correlation_id`", "correlation_id", global: false)
    doc_errors = contract_errors(name, fields, schema_fields, doc_mutation)
    assert {name, :correlation_id, :missing_documented_field} in doc_errors
  end

  defp stable_fields(schema) do
    Enum.find_value(@schema_contracts, fn
      {^schema, _name, fields} -> fields
      _ -> nil
    end)
  end

  defp stable_fields_section!(schema) do
    {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(schema)

    case String.split(moduledoc, "## Stable 1.x fields", parts: 2) do
      [_before, after_heading] ->
        after_heading
        |> String.split(~r/^## /m, parts: 2)
        |> hd()

      [_only] ->
        flunk("#{inspect(schema)} is missing its Stable 1.x fields moduledoc section")
    end
  end

  defp contract_errors(name, fields, schema_fields, section) do
    Enum.flat_map(fields, fn field ->
      schema_error =
        if field in schema_fields, do: [], else: [{name, field, :missing_schema_field}]

      doc_error =
        if section =~ "`#{field}`", do: [], else: [{name, field, :missing_documented_field}]

      schema_error ++ doc_error
    end)
  end

  defp format_errors(errors) do
    Enum.map_join(errors, "\n", fn {name, field, reason} ->
      "#{name} promised field #{inspect(field)}: #{reason}"
    end)
  end
end
