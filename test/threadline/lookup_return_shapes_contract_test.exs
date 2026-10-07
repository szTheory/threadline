defmodule Threadline.LookupReturnShapesContractTest do
  @moduledoc """
  Pins the "everywhere" claim for the single-subject lookup family (D-05,
  API-06): every lookup that can be not-found exports both `name/2` and
  `name!/2`, states its tuple shape in its first doc line, and links the
  other. Also enforces the two reverse-drift checks that catch a new lookup
  added without joining the family — every exported `!` function's plain
  sibling must be listed, and every `@spec` returning `{:error, :not_found}`
  must be listed — plus the explicit `as_of/4` exemption (D-03): its
  `{:error, :deleted_record | :before_audit_horizon}` results are outcomes
  callers branch on, not "absence is a bug", so it has no `!` sibling.
  """

  use ExUnit.Case, async: true

  setup_all do
    Code.ensure_loaded!(Threadline)
    :ok
  end

  @lookups [audit_transaction: 2, transaction_context: 2, incident_bundle: 2]
  @exempt [
    as_of:
      {4,
       "returns {:error, :deleted_record | :before_audit_horizon} outcomes callers branch on, not absence-is-a-bug"}
  ]

  describe "every lookup exports both name/2 and name!/2 (D-05a)" do
    for {name, arity} <- @lookups do
      test "#{name}/#{arity} and #{name}!/#{arity} are both exported" do
        name = unquote(name)
        arity = unquote(arity)
        bang_name = :"#{name}!"

        assert function_exported?(Threadline, name, arity),
               "expected Threadline.#{name}/#{arity} to be exported"

        assert function_exported?(Threadline, bang_name, arity),
               "expected Threadline.#{bang_name}/#{arity} to be exported"
      end
    end
  end

  describe "doc first-line shapes (D-05b)" do
    for {name, arity} <- @lookups do
      test "#{name}/#{arity}'s plain doc starts with the {:ok, shape, mentions :not_found, and links the bang" do
        name = unquote(name)
        arity = unquote(arity)
        doc = function_doc_text(name, arity)

        assert String.starts_with?(doc, "Returns `{:ok,"),
               "expected #{name}/#{arity}'s doc to start with \"Returns `{:ok,\", got: #{inspect(String.slice(doc, 0, 40))}"

        assert doc =~ "{:error, :not_found}",
               "expected #{name}/#{arity}'s doc to mention {:error, :not_found}"

        assert doc =~ "#{name}!/#{arity}",
               "expected #{name}/#{arity}'s doc to link #{name}!/#{arity}"
      end

      test "#{name}!/#{arity}'s doc mentions Threadline.NotFoundError" do
        name = unquote(name)
        arity = unquote(arity)
        bang_doc = function_doc_text(:"#{name}!", arity)

        assert bang_doc =~ "Threadline.NotFoundError",
               "expected #{name}!/#{arity}'s doc to mention Threadline.NotFoundError"
      end
    end
  end

  describe "reverse drift: every bang's plain sibling is listed (D-05c)" do
    test "every exported Threadline function ending in \"!\" has {base_name, arity} in @lookups" do
      # Group by name and keep only the max arity per bang name — a
      # default-arg function (`opts \\ []`) exports both arities (e.g.
      # `audit_transaction!/1` and `/2`), and only the full arity is the
      # function's real signature for this check.
      bangs =
        Threadline.__info__(:functions)
        |> Enum.filter(fn {name, _arity} -> name |> Atom.to_string() |> String.ends_with?("!") end)
        |> Enum.group_by(fn {name, _arity} -> name end, fn {_name, arity} -> arity end)
        |> Enum.map(fn {name, arities} -> {name, Enum.max(arities)} end)

      for {name, arity} <- bangs do
        base_name = name |> Atom.to_string() |> String.trim_trailing("!") |> String.to_atom()

        assert {base_name, arity} in @lookups,
               "Threadline.#{name}/#{arity} is a bang function whose plain sibling " <>
                 "#{base_name}/#{arity} is not in @lookups — add it to the lookup family " <>
                 "doc contract or exempt it explicitly"
      end
    end
  end

  describe "reverse drift: every :not_found spec is listed (D-05c)" do
    test "every Threadline @spec containing :not_found is in @lookups or is a bang of one" do
      {:ok, specs} = Code.Typespec.fetch_specs(Threadline)

      not_found_specs =
        for {{name, arity}, spec_list} <- specs,
            spec <- spec_list,
            spec_text = Code.Typespec.spec_to_quoted(name, spec) |> Macro.to_string(),
            spec_text =~ ":not_found" do
          {name, arity}
        end

      for {name, arity} <- Enum.uniq(not_found_specs) do
        base_name = name |> Atom.to_string() |> String.trim_trailing("!") |> String.to_atom()

        assert {name, arity} in @lookups or {base_name, arity} in @lookups,
               "Threadline.#{name}/#{arity}'s @spec mentions :not_found but " <>
                 "{#{inspect(name)}, #{arity}} is not in @lookups (and neither is its base name)"
      end
    end
  end

  describe "as_of/4 exemption (D-03)" do
    test "as_of/4 is exported, as_of!/4 is not, and its doc states the exemption" do
      assert function_exported?(Threadline, :as_of, 4)
      refute function_exported?(Threadline, :as_of!, 4)

      doc = function_doc_text(:as_of, 4)

      assert doc =~ ":deleted_record"
      assert doc =~ ":before_audit_horizon"
      assert doc =~ "no `!` sibling"
    end

    test "@exempt names as_of/4 with its reason" do
      assert {4, reason} = @exempt[:as_of]
      assert is_binary(reason)
      assert reason =~ "callers branch on"
    end
  end

  defp function_doc_text(name, arity) do
    {:docs_v1, _, _, _, _module_doc, _, docs} = Code.fetch_docs(Threadline)

    Enum.find_value(docs, "", fn
      {{:function, ^name, ^arity}, _anno, _signature, doc, _metadata} -> doc_text(doc)
      _ -> false
    end)
  end

  defp doc_text(%{"en" => text}), do: text
  defp doc_text(:none), do: ""
  defp doc_text(:hidden), do: ""
  defp doc_text(_), do: ""
end
