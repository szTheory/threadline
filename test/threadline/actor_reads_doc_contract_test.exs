defmodule Threadline.ActorReadsDocContractTest do
  @moduledoc """
  Pins API-02: `Threadline.actor_history/2` and `Threadline.actor_window/3`
  are told apart by their return type, stated in the first sentence of each
  doc, and each links to the other. Backed by a recorded mutation control
  (see the plan SUMMARY) proving the cross-link assertions actually bite.
  """

  use ExUnit.Case, async: true

  test "actor_history/2's first paragraph names its return type" do
    doc = function_doc_text(:actor_history, 2)
    first_paragraph = first_paragraph(doc)

    assert first_paragraph =~ "%Threadline.Page{}"
    assert first_paragraph =~ "AuditTransaction"
  end

  test "actor_window/3's first paragraph names its return type" do
    doc = function_doc_text(:actor_window, 3)
    first_paragraph = first_paragraph(doc)

    assert first_paragraph =~ "LinkedChange"
  end

  test "actor_history/2's doc links to actor_window/3" do
    doc = function_doc_text(:actor_history, 2)
    assert doc =~ "actor_window/3"
  end

  test "actor_window/3's doc links to actor_history/2" do
    doc = function_doc_text(:actor_window, 3)
    assert doc =~ "actor_history/2"
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

  defp first_paragraph(text) do
    text
    |> String.split("\n\n", parts: 2)
    |> List.first()
  end
end
