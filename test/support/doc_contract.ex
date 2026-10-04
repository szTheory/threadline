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
    |> Enum.map_join("\n", fn {module, name, arity, kind} ->
      "#{inspect(module)}.#{name}/#{arity}  #{gap_label(kind)}"
    end)
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

  @spec type_keys(list() | {:ok, list()} | {list(), (module() -> list())}, term()) :: [atom()]
  def type_keys(type_source, type_ref) do
    {types, resolver} = normalize_type_source(type_source)

    type_ref
    |> collect_type_keys(types, resolver, MapSet.new())
    |> Enum.uniq()
    |> Enum.sort()
  end

  @spec doc_bullet_keys(String.t(), String.t()) :: [atom()]
  def doc_bullet_keys(markdown, heading) do
    case heading_section(markdown, heading) do
      nil -> []
      content -> content |> section_lines() |> Enum.flat_map(&parse_doc_key_bullet/1)
    end
  end

  defp heading_section(markdown, heading) do
    markdown
    |> String.split(~r/^## /m)
    |> Enum.find(&heading_section?(&1, heading))
  end

  defp heading_section?(part, heading) do
    case String.split(part, "\n", parts: 2) do
      [^heading, _body] -> true
      [^heading] -> true
      _other -> false
    end
  end

  defp section_lines(content) do
    content
    |> String.split("\n", parts: 2)
    |> Enum.drop(1)
    |> List.first("")
    |> String.split("\n")
  end

  defp parse_doc_key_bullet(line) do
    case Regex.run(~r/^\s*-\s*`:([[:alpha:]_!?][[:alnum:]_!?]*)`\s+—/, line) do
      [_, key] -> [String.to_atom(key)]
      _no_key -> []
    end
  end

  @spec options_arg_type(tuple()) :: :untyped | {:local, atom()} | {:remote, module(), atom()}
  def options_arg_type(spec_ast) do
    spec_ast
    |> spec_arguments()
    |> List.last()
    |> option_type_reference()
  end

  @spec bare_types(term()) :: [:term | :any | :map | :keyword | :keyword_t]
  def bare_types(ast), do: collect_bare_types(ast)

  @spec first_paragraph(String.t()) :: String.t()
  def first_paragraph(markdown) do
    markdown
    |> String.trim()
    |> String.split(~r/\n\s*\n/, parts: 2)
    |> List.first("")
    |> String.trim()
  end

  @spec strip_code(String.t()) :: String.t()
  def strip_code(markdown) do
    markdown
    |> String.replace(~r/```[\s\S]*?```|~~~[\s\S]*?~~~/, "")
    |> String.replace(~r/(?:^|\n)(?: {4,}[^\n]*(?:\n|$))+/m, "\n")
    |> String.replace(~r/`[^`\n]*`/, "")
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

  defp normalize_type_source({:ok, types}) when is_list(types),
    do: {types, &fetch_remote_types/1}

  defp normalize_type_source({types, resolver}) when is_list(types) and is_function(resolver, 1),
    do: {types, resolver}

  defp normalize_type_source(types) when is_list(types), do: {types, &fetch_remote_types/1}
  defp normalize_type_source(_other), do: {[], &fetch_remote_types/1}

  defp fetch_remote_types(module) do
    case Code.Typespec.fetch_types(module) do
      {:ok, types} -> types
      _error -> []
    end
  end

  defp collect_type_keys({:local, name}, types, resolver, seen),
    do: collect_local_type_keys(name, types, resolver, seen)

  defp collect_type_keys({:remote, module, name}, types, resolver, seen),
    do: collect_remote_type_keys(module, name, types, resolver, seen)

  defp collect_type_keys(name, types, resolver, seen) when is_atom(name),
    do: collect_local_type_keys(name, types, resolver, seen)

  defp collect_type_keys({:type, _anno, :union, members}, types, resolver, seen),
    do: collect_type_keys(members, types, resolver, seen)

  defp collect_type_keys(
         {:type, _anno, :tuple, [{:atom, _atom_anno, key} | members]},
         types,
         resolver,
         seen
       )
       when is_atom(key),
       do: [key | collect_type_keys(members, types, resolver, seen)]

  defp collect_type_keys({:type, _anno, :list, members}, types, resolver, seen),
    do: collect_type_keys(members, types, resolver, seen)

  defp collect_type_keys({:user_type, _anno, name, _args}, types, resolver, seen),
    do: collect_local_type_keys(name, types, resolver, seen)

  defp collect_type_keys(
         {:remote_type, _anno, [{:atom, _module_anno, module}, {:atom, _name_anno, name}, _args]},
         types,
         resolver,
         seen
       ),
       do: collect_remote_type_keys(module, name, types, resolver, seen)

  defp collect_type_keys(list, types, resolver, seen) when is_list(list),
    do: Enum.flat_map(list, &collect_type_keys(&1, types, resolver, seen))

  defp collect_type_keys(tuple, types, resolver, seen) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> collect_type_keys(types, resolver, seen)

  defp collect_type_keys(_other, _types, _resolver, _seen), do: []

  defp collect_local_type_keys(name, types, resolver, seen) do
    key = {:local, name}

    case {MapSet.member?(seen, key), find_type_ast(types, name)} do
      {false, ast} when not is_nil(ast) ->
        collect_type_keys(ast, types, resolver, MapSet.put(seen, key))

      _not_resolvable ->
        []
    end
  end

  defp collect_remote_type_keys(module, name, _types, resolver, seen) do
    key = {module, name}

    case MapSet.member?(seen, key) do
      true ->
        []

      false ->
        remote_types = resolver.(module)

        case find_type_ast(remote_types, name) do
          nil -> []
          ast -> collect_type_keys(ast, remote_types, resolver, MapSet.put(seen, key))
        end
    end
  end

  defp find_type_ast(types, name) do
    Enum.find_value(types, fn
      {kind, {^name, ast, _args}} when kind in [:type, :opaque, :typep] -> ast
      _other -> nil
    end)
  end

  defp spec_arguments({:type, _anno, :bounded_fun, [function, _constraints]}),
    do: spec_arguments(function)

  defp spec_arguments(
         {:type, _anno, :fun, [{:type, _product_anno, :product, arguments}, _return]}
       ),
       do: arguments

  defp spec_arguments(_spec_ast), do: []

  defp option_type_reference({:type, _anno, :list, [element]}),
    do: named_type_reference(element)

  defp option_type_reference(
         {:remote_type, _anno,
          [{:atom, _module_anno, :elixir}, {:atom, _name_anno, :keyword}, _args]}
       ),
       do: :untyped

  defp option_type_reference(
         {:remote_type, _anno, [{:atom, _module_anno, Keyword}, {:atom, _name_anno, :t}, _args]}
       ),
       do: :untyped

  defp option_type_reference(_other), do: :untyped

  defp named_type_reference({:user_type, _anno, name, _args}), do: {:local, name}

  defp named_type_reference(
         {:remote_type, _anno, [{:atom, _module_anno, module}, {:atom, _name_anno, name}, _args]}
       ),
       do: {:remote, module, name}

  defp named_type_reference(_other), do: :untyped

  defp collect_bare_types({:type, _anno, :bounded_fun, [function, _constraints]}),
    do: collect_bare_types(function)

  defp collect_bare_types({:type, _anno, :term, []}), do: [:term]
  defp collect_bare_types({:type, _anno, :any, []}), do: [:any]
  defp collect_bare_types({:type, _anno, :map, :any}), do: [:map]

  defp collect_bare_types(
         {:remote_type, _anno,
          [{:atom, _module_anno, :elixir}, {:atom, _name_anno, :keyword}, _args]}
       ),
       do: [:keyword]

  defp collect_bare_types(
         {:remote_type, _anno, [{:atom, _module_anno, Keyword}, {:atom, _name_anno, :t}, _args]}
       ),
       do: [:keyword_t]

  defp collect_bare_types(list) when is_list(list), do: Enum.flat_map(list, &collect_bare_types/1)

  defp collect_bare_types(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> collect_bare_types()

  defp collect_bare_types(_other), do: []

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
