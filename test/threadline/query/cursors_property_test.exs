defmodule Threadline.Query.CursorsPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.CursorGenerators

  alias Threadline.Test.KeysetModel
  alias Threadline.Test.PropertyRuns

  property "actor-history paging returns every entry exactly once in keyset order, forward and backward" do
    check all({entries, k} <- paging_gen(), max_runs: PropertyRuns.pure(200)) do
      assert {:ok, forward_pages, backward_pages} = KeysetModel.walk_actor_history(entries, k),
             "walker did not hit its bound without a nil continuation cursor"

      forward_ids = List.flatten(forward_pages)
      input_ids = Enum.map(entries, & &1.id)

      assert forward_ids == KeysetModel.expected_order(entries),
             "concatenated forward page ids must equal the independent keyset order"

      assert MapSet.new(forward_ids) == MapSet.new(input_ids),
             "paged ids must be exactly the set of input ids"

      assert length(forward_ids) == length(Enum.uniq(forward_ids)),
             "no id may appear twice across forward pages"

      expected_backward =
        forward_pages
        |> Enum.reverse()
        |> Enum.drop(1)

      assert backward_pages == expected_backward,
             "walking before: back from the last forward page must reproduce every earlier " <>
               "forward page, in the same order"
    end
  end

  property "timeline paging returns every entry exactly once in keyset order" do
    check all({entries, k} <- paging_gen(), max_runs: PropertyRuns.pure(200)) do
      assert {:ok, pages} = KeysetModel.walk_timeline(entries, k),
             "walker did not hit its bound without a nil continuation cursor"

      ids = List.flatten(pages)
      input_ids = Enum.map(entries, & &1.id)
      n = length(entries)

      assert ids == KeysetModel.expected_order(entries),
             "concatenated page ids must equal the independent keyset order"

      assert MapSet.new(ids) == MapSet.new(input_ids),
             "paged ids must be exactly the set of input ids"

      assert length(ids) == length(Enum.uniq(ids)),
             "no id may appear twice across pages"

      empty_page_count = Enum.count(pages, &(&1 == []))

      assert empty_page_count <= 1,
             "at most one trailing page may be empty (timeline_page fetches page_size rows, not limit + 1)"

      if empty_page_count == 1 do
        assert n == 0 or rem(n, k) == 0,
               "an empty trailing page only occurs when n == 0 or the entries divide evenly by the page size"
      end

      if n == 0 do
        assert pages == [[]],
               "zero entries must yield exactly one empty page"
      end
    end
  end
end
