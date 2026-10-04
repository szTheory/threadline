defmodule Threadline.DocContract do
  @moduledoc false

  @type gap ::
          {module(), atom(), non_neg_integer(), :missing_doc | :missing_spec | :missing_typedoc}

  @spec universe() :: [{module(), tuple(), list()}]
  def universe do
    {:ok, modules} = :application.get_key(:threadline, :modules)

    modules
    |> Enum.reject(&source_under_test?/1)
    |> Enum.flat_map(fn module ->
      docs_v1 = fetch_docs!(module)

      case moduledoc(docs_v1) do
        :hidden -> []
        _doc -> [{module, docs_v1, fetch_specs(module)}]
      end
    end)
    |> Enum.sort_by(fn {module, _docs_v1, _specs} -> inspect(module) end)
  end

  @spec checked_entries(tuple()) :: [{atom(), atom(), non_neg_integer(), term(), map()}]
  def checked_entries({:docs_v1, _anno, _lang, _format, _moduledoc, _metadata, entries}) do
    for {{kind, name, arity}, _anno, _signature, doc, metadata} <- entries,
        kind in [:function, :macro],
        doc != :hidden,
        not internal_name?(name) do
      {kind, name, arity, doc, metadata}
    end
  end

  @spec gaps(module(), tuple(), {:ok, list()} | list()) :: [gap()]
  def gaps(module, docs_v1, specs_result) do
    specs = normalize_specs(specs_result)

    function_gaps =
      for {kind, name, arity, doc, _metadata} <- checked_entries(docs_v1),
          missing <- missing_entry_gaps(kind, name, arity, doc, specs),
          do: {module, name, arity, missing}

    type_gaps =
      for {{kind, name, arity}, _anno, _signature, doc, _metadata} <- docs_entries(docs_v1),
          kind in [:type, :opaque],
          doc != :hidden,
          doc == :none,
          do: {module, name, arity, :missing_typedoc}

    Enum.sort_by(function_gaps ++ type_gaps, &gap_sort_key/1)
  end

  @spec format_gaps([gap()]) :: String.t()
  def format_gaps(gaps) do
    gaps
    |> Enum.sort_by(&gap_sort_key/1)
    |> Enum.map(fn {module, name, arity, kind} ->
      "#{inspect(module)}.#{name}/#{arity}  #{gap_label(kind)}"
    end)
    |> Enum.join("\n")
  end

  @spec explicitly_hidden(module(), tuple()) :: [{module(), atom(), non_neg_integer()}]
  def explicitly_hidden(module, docs_v1) do
    callbacks = behaviour_callbacks(module)

    docs_v1
    |> docs_entries()
    |> Enum.flat_map(fn
      {{kind, name, arity}, _anno, _signature, :hidden, _metadata}
      when kind in [:function, :macro] ->
        if internal_name?(name) or MapSet.member?(callbacks, {name, arity}) do
          []
        else
          [{module, name, arity}]
        end

      _other ->
        []
    end)
    |> Enum.sort_by(fn {hidden_module, name, arity} ->
      {inspect(hidden_module), Atom.to_string(name), arity}
    end)
  end

  @spec ungrouped([tuple()], [String.t()]) :: [{atom(), non_neg_integer(), String.t() | nil}]
  def ungrouped(entries, allowed_titles) do
    entries
    |> Enum.flat_map(fn
      {{kind, name, arity}, _anno, _signature, doc, metadata}
      when kind in [:function, :macro] and doc != :hidden ->
        group = Map.get(metadata, :group)

        if internal_name?(name) or group in allowed_titles do
          []
        else
          [{name, arity, group}]
        end

      _other ->
        []
    end)
    |> Enum.sort_by(fn {name, arity, _group} -> {Atom.to_string(name), arity} end)
  end

  defp missing_entry_gaps(:macro, _name, _arity, doc, _specs), do: doc_gap(doc)

  defp missing_entry_gaps(:function, name, arity, doc, specs) do
    doc_gap(doc) ++
      if Enum.any?(specs, fn {{spec_name, spec_arity}, _clauses} ->
           spec_name == name and spec_arity == arity
         end) do
        []
      else
        [:missing_spec]
      end
  end

  defp doc_gap(doc) when is_map(doc) and map_size(doc) > 0, do: []
  defp doc_gap(_doc), do: [:missing_doc]

  defp normalize_specs({:ok, specs}) when is_list(specs), do: specs
  defp normalize_specs(specs) when is_list(specs), do: specs
  defp normalize_specs(_other), do: []

  defp fetch_specs(module) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} -> specs
      _error -> []
    end
  end

  defp fetch_docs!(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, _} = docs_v1 -> docs_v1
      other -> raise "expected a docs_v1 chunk for #{inspect(module)}, got: #{inspect(other)}"
    end
  end

  defp moduledoc({:docs_v1, _anno, _lang, _format, moduledoc, _metadata, _entries}),
    do: moduledoc

  defp docs_entries({:docs_v1, _anno, _lang, _format, _moduledoc, _metadata, entries}),
    do: entries

  defp source_under_test?(module) do
    source = module.module_info(:compile)[:source] |> List.to_string()
    "test" in Path.split(source)
  end

  defp behaviour_callbacks(module) do
    module.module_info(:attributes)
    |> Keyword.get(:behaviour, [])
    |> Enum.flat_map(fn behaviour ->
      if Code.ensure_loaded?(behaviour) and function_exported?(behaviour, :behaviour_info, 1) do
        behaviour.behaviour_info(:callbacks)
      else
        []
      end
    end)
    |> MapSet.new()
  end

  defp internal_name?(name) do
    name = Atom.to_string(name)
    String.starts_with?(name, "__") and String.ends_with?(name, "__")
  end

  defp gap_sort_key({module, name, arity, kind}),
    do: {inspect(module), Atom.to_string(name), arity, Atom.to_string(kind)}

  defp gap_label(:missing_doc), do: "missing @doc"
  defp gap_label(:missing_spec), do: "missing @spec"
  defp gap_label(:missing_typedoc), do: "missing @typedoc"
end
