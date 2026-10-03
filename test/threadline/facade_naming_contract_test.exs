defmodule Threadline.FacadeNamingContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

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

  defp metadata_for(docs, name, arity) do
    Enum.find_value(docs, fn
      {{:function, ^name, ^arity}, _anno, _sig, _doc, metadata} -> metadata
      _ -> nil
    end)
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
