defmodule Threadline.OperatorSurface.Exports.FilterParamsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.OperatorSurface.Exports.FilterParams
  alias Threadline.Semantics.ActorRef

  describe "parse/1" do
    test "returns {:ok, []} for an empty input map" do
      assert FilterParams.parse(%{}) == {:ok, []}
    end

    test "drops unknown URL keys (allowlist enforcement)" do
      assert {:ok, filters} = FilterParams.parse(%{"foo" => "bar", "table" => "posts"})
      assert filters == [table: "posts"]
    end

    test "drops empty-string values (so `?from=&to=` is treated as no filters)" do
      assert FilterParams.parse(%{"from" => "", "to" => ""}) == {:ok, []}
    end

    test "pads 16-char datetime-local input to ISO-8601 with seconds and Z suffix" do
      assert {:ok, filters} = FilterParams.parse(%{"from" => "2026-05-06T12:00"})

      assert {:from, %DateTime{year: 2026, month: 5, day: 6, hour: 12, minute: 0, second: 0}} =
               List.keyfind(filters, :from, 0)
    end

    test "passes 19-char datetime-local input through with Z suffix" do
      assert {:ok, filters} = FilterParams.parse(%{"to" => "2026-05-06T12:00:30"})
      assert {:to, %DateTime{minute: 0, second: 30}} = List.keyfind(filters, :to, 0)
    end

    test "returns {:error, ...} for an unparseable datetime" do
      assert FilterParams.parse(%{"from" => "not-a-date"}) ==
               {:error, "invalid datetime: not-a-date"}
    end

    test "anonymous actor_kind drops actor_id and produces %ActorRef{type: :anonymous, id: nil}" do
      assert {:ok, filters} =
               FilterParams.parse(%{"actor_kind" => "anonymous", "actor_id" => "ignored"})

      assert {:actor_ref, %ActorRef{type: :anonymous, id: nil}} =
               List.keyfind(filters, :actor_ref, 0)
    end

    test "actor_kind + actor_id produce %ActorRef{type: kind_atom, id: id_string}" do
      assert {:ok, filters} = FilterParams.parse(%{"actor_kind" => "user", "actor_id" => "42"})
      assert {:actor_ref, %ActorRef{type: :user, id: "42"}} = List.keyfind(filters, :actor_ref, 0)
    end

    test "actor_kind without actor_id (and not anonymous) is silently dropped — no actor_ref filter" do
      assert {:ok, filters} = FilterParams.parse(%{"actor_kind" => "user"})
      refute Keyword.has_key?(filters, :actor_ref)
      refute Keyword.has_key?(filters, :actor_kind)
    end

    test "unknown actor_kind atom string returns {:error, ...}" do
      # "definitely_not_a_real_actor_kind" is unlikely to be a registered atom — covered by
      # String.to_existing_atom/1 raising ArgumentError, mapped to :unknown_actor_type.
      assert {:error, "unknown actor kind: " <> _} =
               FilterParams.parse(%{
                 "actor_kind" => "definitely_not_a_real_actor_kind",
                 "actor_id" => "x"
               })
    end

    test "actor_id whitespace-only with non-anonymous kind treats as missing id (drops actor_ref)" do
      assert {:ok, filters} = FilterParams.parse(%{"actor_kind" => "user", "actor_id" => ""})
      refute Keyword.has_key?(filters, :actor_ref)
    end

    test "correlation_id is passed through verbatim" do
      assert {:ok, filters} = FilterParams.parse(%{"correlation_id" => "abc-123"})
      assert filters == [correlation_id: "abc-123"]
    end

    test "table is passed through verbatim (validation against `audited_tables` happens elsewhere)" do
      assert {:ok, filters} = FilterParams.parse(%{"table" => "posts"})
      assert filters == [table: "posts"]
    end
  end

  describe "filters_raw_from_params/1" do
    test "returns the canonical six-key map even when some keys are absent" do
      assert FilterParams.filters_raw_from_params(%{"from" => "2026-05-06T12:00"}) == %{
               "from" => "2026-05-06T12:00",
               "to" => "",
               "table" => "",
               "actor_kind" => "",
               "actor_id" => "",
               "correlation_id" => ""
             }
    end

    test "strips actor_id when actor_kind == \"anonymous\" (mirrors URL canonicalization)" do
      raw =
        FilterParams.filters_raw_from_params(%{
          "actor_kind" => "anonymous",
          "actor_id" => "ignored"
        })

      assert raw["actor_kind"] == "anonymous"
      assert raw["actor_id"] == ""
    end
  end

  describe "atom safety (RESEARCH Pitfall 11)" do
    test "FilterParams source uses String.to_existing_atom, NEVER String.to_atom" do
      src = File.read!("lib/threadline/operator_surface/exports/filter_params.ex")
      assert src =~ "String.to_existing_atom"
      refute src =~ ~r/String\.to_atom\b/
    end
  end
end
