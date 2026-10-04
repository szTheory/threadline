defmodule Threadline.FacadeNamingContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.DocContract

  @group_titles [
    "Capture & Transactions",
    "Querying & Timelines",
    "Actions & Context",
    "Operations"
  ]

  @facade_groups %{
    {:audit_transaction, 2} => "Capture & Transactions",
    {:audit_transaction!, 2} => "Capture & Transactions",
    {:transaction_context, 2} => "Capture & Transactions",
    {:transaction_context!, 2} => "Capture & Transactions",
    {:incident_bundle, 2} => "Capture & Transactions",
    {:incident_bundle!, 2} => "Capture & Transactions",
    {:audit_changes_for_transaction, 2} => "Capture & Transactions",
    {:timeline, 2} => "Querying & Timelines",
    {:timeline_page, 2} => "Querying & Timelines",
    {:row_history, 3} => "Querying & Timelines",
    {:as_of, 4} => "Querying & Timelines",
    {:change_diff, 2} => "Querying & Timelines",
    {:history, 3} => "Querying & Timelines",
    {:row_history, 4} => "Querying & Timelines",
    {:row_history_page, 4} => "Querying & Timelines",
    {:record_action, 2} => "Actions & Context",
    {:actor_history, 2} => "Actions & Context",
    {:actor_window, 3} => "Actions & Context",
    {:actor_window_page, 3} => "Actions & Context",
    {:correlation_bundle, 3} => "Actions & Context",
    {:correlation_bundle_page, 3} => "Actions & Context",
    {:export_csv, 2} => "Operations",
    {:export_json, 2} => "Operations"
  }

  @ungrouped_ratchet [
    {:actor_history, 2},
    {:actor_window, 3},
    {:actor_window_page, 3},
    {:as_of, 4},
    {:audit_changes_for_transaction, 2},
    {:audit_transaction, 2},
    {:audit_transaction!, 2},
    {:change_diff, 2},
    {:correlation_bundle, 3},
    {:correlation_bundle_page, 3},
    {:export_csv, 2},
    {:export_json, 2},
    {:history, 3},
    {:incident_bundle, 2},
    {:incident_bundle!, 2},
    {:record_action, 2},
    {:row_history, 3},
    {:row_history, 4},
    {:row_history_page, 4},
    {:timeline, 2},
    {:timeline_page, 2},
    {:transaction_context, 2},
    {:transaction_context!, 2}
  ]

  # D-19/SC3: among the Threadline facade's visible, non-deprecated
  # functions, timeline/2 + timeline_page/2 is the only paired base/_page
  # name. Every other `_page` sibling retired into a `cursor:` option on its
  # base function and is @deprecated (231/232 D-11).

  test "paired_names/1 over the visible, non-deprecated Threadline functions returns exactly [{:timeline, :timeline_page}]" do
    assert paired_names(visible_non_deprecated_names(Threadline)) == [{:timeline, :timeline_page}]
  end

  test "the only non-deprecated visible name ending in _page is :timeline_page" do
    page_names =
      visible_non_deprecated_names(Threadline)
      |> Enum.filter(&String.ends_with?(Atom.to_string(&1), "_page"))
      |> Enum.sort()

    assert page_names == [:timeline_page]
  end

  test "paired_names/1 over a fixture is non-vacuous" do
    assert paired_names(MapSet.new([:foo, :foo_page, :bar, :baz_page])) == [{:foo, :foo_page}]
  end

  test "row_history/3, actor_window/3 and correlation_bundle/3 carry since 1.0.0; each deprecated facade entry carries :deprecated metadata" do
    {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Threadline)

    for {name, arity} <- [{:row_history, 3}, {:actor_window, 3}, {:correlation_bundle, 3}] do
      metadata = metadata_for(docs, name, arity)

      assert metadata[:since] == "1.0.0",
             "expected Threadline.#{name}/#{arity} to carry @doc since: \"1.0.0\", got #{inspect(metadata)}"
    end

    deprecated_names = [:history, :row_history_page, :actor_window_page, :correlation_bundle_page]

    deprecated_entries =
      for {{:function, name, arity}, _anno, _sig, _doc, metadata} <- docs,
          name in deprecated_names,
          do: {name, arity, metadata}

    assert deprecated_entries != [], "expected at least one deprecated facade entry"

    for {name, arity, metadata} <- deprecated_entries do
      assert Map.has_key?(metadata, :deprecated),
             "expected Threadline.#{name}/#{arity} to carry :deprecated metadata"
    end

    row_history_4_metadata = metadata_for(docs, :row_history, 4)

    assert Map.has_key?(row_history_4_metadata, :deprecated),
           "expected the deprecated 4-arity Threadline.row_history/4 to carry :deprecated metadata"
  end

  describe "facade groups" do
    test "the reviewed grouping pin covers the exact visible facade function set" do
      {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Threadline)
      visible = visible_facade_entries(docs)
      visible_keys = Enum.map(visible, &elem(&1, 0)) |> Enum.sort()

      assert visible_keys == Map.keys(@facade_groups) |> Enum.sort()
      assert length(visible_keys) == 23
    end

    test "every visible function is grouped or remains in the exact ungrouped ratchet" do
      {:docs_v1, _, _, _, _, module_metadata, docs} = Code.fetch_docs(Threadline)
      visible = visible_facade_entries(docs)
      actual_ungrouped = DocContract.ungrouped(docs, @group_titles)

      actual_ungrouped_keys =
        Enum.map(actual_ungrouped, fn {name, arity, _group} -> {name, arity} end)

      assert Enum.sort(Map.keys(@facade_groups)) == Enum.sort(@ungrouped_ratchet)

      assert Enum.sort(actual_ungrouped_keys) == Enum.sort(@ungrouped_ratchet),
             "ungrouped facade entries changed: #{inspect(actual_ungrouped)}"

      for {{name, arity}, group} <- visible do
        if group do
          assert @facade_groups[{name, arity}] == group,
                 "Threadline.#{name}/#{arity} belongs to #{inspect(@facade_groups[{name, arity}])}, got #{inspect(group)}"
        else
          assert {name, arity} in @ungrouped_ratchet
        end
      end

      groups = Map.get(module_metadata, :groups, [])

      if Enum.sort(actual_ungrouped_keys) == Enum.sort(Map.keys(@facade_groups)) do
        assert groups == [],
               "module group metadata is stale while every function remains ungrouped"
      else
        assert group_titles(groups) == @group_titles

        for title <- @group_titles do
          assert Enum.any?(visible, fn {_key, group} -> group == title end),
                 "facade group #{inspect(title)} has no visible function"
        end

        {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} = Code.fetch_docs(Threadline)

        jobs = jobs_bullets(moduledoc)

        assert Enum.map(jobs, &elem(&1, 0)) == @group_titles,
               "the ## Jobs bullets must appear once in group order"

        for {title, names} <- jobs do
          assert length(names) in 2..3,
                 "the #{title} Jobs bullet should name two or three entry points"

          for {name, arity} <- names do
            assert @facade_groups[{name, arity}] == title,
                   "Jobs names Threadline.#{name}/#{arity} under the wrong group"
          end
        end
      end
    end

    test "ungrouped/2 rejects missing and unapproved group metadata in a literal fixture" do
      entries = [
        {{:function, :grouped, 1}, 0, [], %{"en" => "Grouped."}, %{group: "Capture"}},
        {{:function, :missing, 0}, 0, [], %{"en" => "Missing."}, %{}},
        {{:function, :wrong, 0}, 0, [], %{"en" => "Wrong."}, %{group: "Unknown"}}
      ]

      assert DocContract.ungrouped(entries, ["Capture"]) == [
               {:missing, 0, nil},
               {:wrong, 0, "Unknown"}
             ]
    end
  end

  defp metadata_for(docs, name, arity) do
    Enum.find_value(docs, fn
      {{:function, ^name, ^arity}, _anno, _sig, _doc, metadata} -> metadata
      _ -> nil
    end)
  end

  defp visible_facade_entries(docs) do
    for {{kind, name, arity}, _anno, _sig, doc, metadata} <- docs,
        kind in [:function, :macro],
        doc != :hidden,
        do: {{name, arity}, metadata[:group]}
  end

  defp group_titles(groups) do
    Enum.map(groups, fn
      %{title: title} -> title
      title when is_binary(title) -> title
    end)
  end

  defp jobs_bullets(moduledoc) do
    case Regex.split(~r/^## Jobs\s*$/m, moduledoc, parts: 2) do
      [_before, body] ->
        section = body |> String.split(~r/^## /m, parts: 2) |> hd()

        Regex.scan(~r/^- \*\*([^*]+)\*\*:(.*?)(?=^- \*\*|\z)/ms, section, capture: :all_but_first)
        |> Enum.map(fn [title, bullet] ->
          names =
            Regex.scan(~r/`([[:alpha:]_!?]+)\/([0-9]+)`/, bullet, capture: :all_but_first)
            |> Enum.map(fn [name, arity] -> {String.to_atom(name), String.to_integer(arity)} end)

          {title, names}
        end)

      _no_jobs_section ->
        []
    end
  end

  defp visible_non_deprecated_names(module) do
    {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(module)

    docs
    |> Enum.filter(fn {{:function, _name, _arity}, _anno, _sig, doc, metadata} ->
      doc != :hidden and not Map.has_key?(metadata, :deprecated)
    end)
    |> Enum.map(fn {{:function, name, _arity}, _anno, _sig, _doc, _metadata} -> name end)
    |> MapSet.new()
  end

  # Pairs each `X_page` name in `names` with a present base `X` also in
  # `names`. `names` may be any Enumerable of atoms (a MapSet in production
  # use, a plain list in fixture tests).
  defp paired_names(names) do
    names
    |> Enum.filter(&String.ends_with?(Atom.to_string(&1), "_page"))
    |> Enum.map(fn page_name ->
      base_name =
        page_name
        |> Atom.to_string()
        |> String.replace_suffix("_page", "")
        |> String.to_atom()

      {base_name, page_name}
    end)
    |> Enum.filter(fn {base_name, _page_name} -> base_name in names end)
    |> Enum.sort()
  end
end
