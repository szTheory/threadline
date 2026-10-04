defmodule Threadline.OptionAllowlistTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @row_history_keys [
    :repo,
    :from,
    :to,
    :limit,
    :cursor,
    :page_size,
    :scope,
    :scope_query_fn,
    :storage_schema
  ]
  @lookup_keys [:repo, :storage_schema, :scope, :scope_query_fn]
  @lookup_names [
    :audit_transaction,
    :audit_transaction!,
    :transaction_context,
    :transaction_context!,
    :incident_bundle,
    :incident_bundle!
  ]

  test "row_history rejects internal and unknown option keys before reading" do
    assert_raise ArgumentError, ~r/unknown row_history option key :surface/, fn ->
      Threadline.row_history(Threadline.Capture.AuditChange, 1, surface: :row_history)
    end

    assert_raise ArgumentError, ~r/unknown row_history option key :limitt/, fn ->
      Threadline.row_history(Threadline.Capture.AuditChange, 1, limitt: 3)
    end
  end

  test "row_history exposes its exact closed option allowlist" do
    assert Threadline.__option_keys__(:row_history) == @row_history_keys
    assert Threadline.__option_keys__(:not_a_function) == :not_closed
  end

  test "single-subject lookup functions share their exact option allowlist" do
    for name <- @lookup_names do
      assert Threadline.__option_keys__(name) == @lookup_keys
    end
  end
end
