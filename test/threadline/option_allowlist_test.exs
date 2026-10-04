defmodule Threadline.OptionAllowlistTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.Semantics.ActorRef

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
  @query_option_keys [:repo, :storage_schema, :scope, :scope_query_fn]
  @timeline_filter_keys [:repo, :table_schema, :table, :actor_ref, :from, :to, :correlation_id]
  @timeline_page_option_keys @query_option_keys ++ [:page_size, :cursor]
  @actor_history_keys @query_option_keys ++
                        [:from, :to, :cursor, :page_size, :after, :before, :limit]

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

  test "Query-backed facade functions reject internal and unknown option keys before reading" do
    {:ok, actor_ref} = ActorRef.new(:user, "option-allowlist")

    calls = [
      {:timeline, fn opts -> Threadline.timeline([], opts) end},
      {:timeline_page, fn opts -> Threadline.timeline_page([], opts) end},
      {:actor_history, fn opts -> Threadline.actor_history(actor_ref, opts) end}
    ]

    for {name, call} <- calls, key <- [:surface, :params, :limitt] do
      assert_raise ArgumentError, ~r/unknown #{name} option key #{inspect(key)}/, fn ->
        call.([{key, true}])
      end
    end
  end

  test "timeline facade functions reject unknown filter keys before reading" do
    assert_raise ArgumentError, ~r/unknown timeline filter key :limitt/, fn ->
      Threadline.timeline(limitt: true)
    end

    assert_raise ArgumentError, ~r/unknown timeline filter key :limitt/, fn ->
      Threadline.timeline_page(limitt: true)
    end
  end

  test "Query-backed facade functions expose their option and filter allowlists" do
    assert Threadline.__option_keys__(:timeline) == @query_option_keys
    assert Threadline.__option_keys__(:timeline_page) == @timeline_page_option_keys
    assert Threadline.__option_keys__(:actor_history) == @actor_history_keys
    assert Threadline.__filter_keys__(:timeline) == @timeline_filter_keys
    assert Threadline.__filter_keys__(:timeline_page) == @timeline_filter_keys
    assert Threadline.__filter_keys__(:actor_history) == :not_closed
  end
end
