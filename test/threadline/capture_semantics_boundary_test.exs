defmodule Threadline.CaptureSemanticsBoundaryTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @capture_files Path.wildcard(Path.join(@root, "lib/threadline/capture/**/*.ex"))

  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.AuditAction

  describe "API-07: capture and semantics schemas declare no cross-layer associations" do
    test "AuditTransaction declares no :action association" do
      refute :action in AuditTransaction.__schema__(:associations)
    end

    test "AuditAction declares no :transactions association" do
      refute :transactions in AuditAction.__schema__(:associations)
    end

    test "AuditTransaction keeps an explicit :action_id field and a virtual :action field" do
      assert :action_id in AuditTransaction.__schema__(:fields)
      assert :action in AuditTransaction.__schema__(:virtual_fields)
      assert %AuditTransaction{}.action == nil
    end

    test "AuditTransaction.action_id is :binary_id" do
      assert AuditTransaction.__schema__(:type, :action_id) == :binary_id
    end

    test "compiled AuditTransaction.t keeps the hydrated action field generic" do
      {:ok, types} = Code.Typespec.fetch_types(AuditTransaction)

      {:type, {:t, type_ast, args}} =
        Enum.find(types, fn
          {:type, {:t, _type_ast, _args}} -> true
          _ -> false
        end)

      rendered =
        {:t, type_ast, args}
        |> Code.Typespec.type_to_quoted()
        |> Macro.to_string()

      assert rendered =~ "action: struct() | nil"
      assert %AuditTransaction{}.action == nil
    end

    test "capture source does not reference the semantics action type" do
      assert @capture_files != []

      findings =
        Enum.flat_map(@capture_files, fn path ->
          ast = path |> File.read!() |> Code.string_to_quoted!()
          aliases = capture_aliases(ast)

          Macro.prewalk(ast, [], fn
            {{:., _, [{:__aliases__, _, module_parts}, :t]}, _, _args} = node, acc ->
              semantics_action? =
                module_parts == [:Threadline, :Semantics, :AuditAction] or
                  Map.get(aliases, module_parts) == [:Threadline, :Semantics, :AuditAction]

              if semantics_action?, do: {node, [path | acc]}, else: {node, acc}

            node, acc ->
              {node, acc}
          end)
          |> elem(1)
        end)

      assert findings == []
    end
  end

  defp capture_aliases(ast) do
    {_ast, aliases} =
      Macro.prewalk(ast, %{}, fn
        {:alias, _, [module_ast]} = node, aliases ->
          alias_target = alias_parts(module_ast)
          {node, Map.put(aliases, [List.last(alias_target)], alias_target)}

        {:alias, _, [module_ast, options]} = node, aliases ->
          alias_target = alias_parts(module_ast)
          alias_name = Keyword.get(options, :as, List.last(alias_target))
          {node, Map.put(aliases, [alias_name], alias_target)}

        node, aliases ->
          {node, aliases}
      end)

    aliases
  end

  defp alias_parts({:__aliases__, _, parts}), do: parts
  defp alias_parts(_other), do: []
end
