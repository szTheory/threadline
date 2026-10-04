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
  @window_option_keys @query_option_keys ++ [:cursor, :page_size]
  @actor_window_filter_keys [:table, :from, :to, :correlation_id, :repo]
  @correlation_bundle_filter_keys [:table, :actor_ref, :from, :to, :repo]
  @export_csv_option_keys @query_option_keys ++ [:max_rows, :include_action_metadata]
  @export_json_option_keys @query_option_keys ++ [:max_rows, :json_format]

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

  test "Investigation and export facade functions reject internal and unknown option keys" do
    {:ok, actor_ref} = ActorRef.new(:user, "option-allowlist")

    calls = [
      {:actor_window, fn opts -> Threadline.actor_window(actor_ref, [], opts) end},
      {:correlation_bundle, fn opts -> Threadline.correlation_bundle("corr-1", [], opts) end},
      {:export_csv, fn opts -> Threadline.export_csv([], opts) end},
      {:export_json, fn opts -> Threadline.export_json([], opts) end}
    ]

    for {name, call} <- calls, key <- [:surface, :params, :limitt] do
      assert_raise ArgumentError, ~r/unknown #{name} option key #{inspect(key)}/, fn ->
        call.([{key, true}])
      end
    end
  end

  test "Investigation and export facade functions reject unknown filter keys" do
    {:ok, actor_ref} = ActorRef.new(:user, "option-allowlist")

    assert_raise ArgumentError, ~r/unknown actor_window filter key :limitt/, fn ->
      Threadline.actor_window(actor_ref, limitt: true)
    end

    assert_raise ArgumentError, ~r/unknown correlation_bundle filter key :limitt/, fn ->
      Threadline.correlation_bundle("corr-1", limitt: true)
    end

    for export <- [&Threadline.export_csv/2, &Threadline.export_json/2] do
      assert_raise ArgumentError, ~r/unknown timeline filter key :limitt/, fn ->
        export.([limitt: true], [])
      end
    end
  end

  test "Investigation and export facade functions expose exact allowlists" do
    assert Threadline.__option_keys__(:actor_window) == @window_option_keys
    assert Threadline.__option_keys__(:correlation_bundle) == @window_option_keys
    assert Threadline.__option_keys__(:export_csv) == @export_csv_option_keys
    assert Threadline.__option_keys__(:export_json) == @export_json_option_keys
    assert Threadline.__filter_keys__(:actor_window) == @actor_window_filter_keys

    assert Threadline.__filter_keys__(:correlation_bundle) ==
             @correlation_bundle_filter_keys

    assert Threadline.__filter_keys__(:export_csv) == @timeline_filter_keys
    assert Threadline.__filter_keys__(:export_json) == @timeline_filter_keys
  end

  test "Export.to_csv_iodata rejects internal and unknown option keys before reading" do
    for key <- [:surface, :params, :limitt] do
      assert_raise ArgumentError,
                   ~r/unknown to_csv_iodata option key #{inspect(key)}.*Allowed:/,
                   fn ->
                     Threadline.Export.to_csv_iodata([], [{key, true}])
                   end
    end

    assert Threadline.Export.__option_keys__(:to_csv_iodata) ==
             Threadline.__option_keys__(:export_csv)
  end
end
