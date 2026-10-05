defmodule Threadline.DocRubricContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.DocContract

  @root Path.expand("../..", __DIR__)
  @unknown_key_sentence "Unknown keys raise `ArgumentError` naming the allowed keys."

  @new_in_1_0 [
    {Threadline, :actor_window, 3},
    {Threadline, :audit_transaction!, 2},
    {Threadline, :audit_transaction, 2},
    {Threadline, :correlation_bundle, 3},
    {Threadline, :incident_bundle!, 2},
    {Threadline, :row_history, 3},
    {Threadline, :transaction_context!, 2}
  ]

  @permanent_bare_allowlist %{
    {Threadline.Audit, :spec, :transaction, 3} =>
      "R1: callback results and caller-owned rollback reasons remain opaque",
    {Threadline, :type, :scope_opt, 0} => "R1: the caller's scope value is opaque to Threadline",
    {Threadline, :type, :scope_query_fn, 0} =>
      "R1: the callback receives an opaque scope and open surface-specific context params",
    {Threadline.Semantics.ActorRef, :spec, :identifiable?, 1} =>
      "R2: predicate accepts arbitrary input and reports whether it identifies an actor",
    {Threadline.Semantics.ActorRef, :spec, :from_map, 1} =>
      "R2: validator accepts arbitrary input and reports when it is not an ActorRef JSON map",
    {Threadline.Evidence.Subject, :spec, :validate, 1} =>
      "R2: validator accepts arbitrary input and includes the unsupported value in its error",
    {Threadline.Storage, :type, :options, 0} =>
      "R4: storage options are defined by the adapter contract",
    {Threadline.Page, :type, :t, 0} =>
      "R1: the producer chooses the page entry type; callers should prefer t(entry)"
  }

  test "option and filter docs, types, and runtime allowlists have no gaps" do
    actual = option_parity_findings()

    assert actual == [], "option parity findings: #{inspect(actual, limit: :infinity)}"
  end

  test "first paragraphs and placeholders have no M2 findings" do
    actual = first_paragraph_findings()

    assert actual == [], "M2 first-paragraph findings: #{inspect(actual, limit: :infinity)}"
  end

  test "docs do not point to deprecated entries" do
    actual = deprecated_reference_findings()

    assert actual == [], "M4 deprecated references: #{inspect(actual, limit: :infinity)}"
  end

  test "voice and sentence endings have no M6 findings" do
    actual = voice_findings()

    assert actual == [], "M6 voice findings: #{inspect(actual, limit: :infinity)}"
  end

  test "since metadata is limited to the pinned 1.0 names" do
    actual = since_entries()

    expected =
      Enum.map(@new_in_1_0, fn {module, name, arity} -> {module, name, arity, "1.0.0"} end)
      |> Enum.sort_by(&inspect/1)

    assert actual == expected,
           "@doc since metadata changed; measured: #{inspect(actual, limit: :infinity)}"

    assert since_findings() == []
  end

  test "indented examples parse and have no unsupported iex prompts" do
    actual = code_block_findings()

    assert actual == [], "M8 code-block findings: #{inspect(actual, limit: :infinity)}"
  end

  test "bare types use only the reasoned permanent cases" do
    actual = bare_type_findings()

    assert actual == [], "bare-type findings: #{inspect(actual, limit: :infinity)}"

    measured = all_bare_type_occurrences()

    assert Map.keys(@permanent_bare_allowlist) |> Enum.sort() ==
             [
               {Threadline, :type, :scope_opt, 0},
               {Threadline, :type, :scope_query_fn, 0},
               {Threadline.Audit, :spec, :transaction, 3},
               {Threadline.Evidence.Subject, :spec, :validate, 1},
               {Threadline.Page, :type, :t, 0},
               {Threadline.Semantics.ActorRef, :spec, :from_map, 1},
               {Threadline.Semantics.ActorRef, :spec, :identifiable?, 1},
               {Threadline.Storage, :type, :options, 0}
             ]

    for {key, reason} <- @permanent_bare_allowlist do
      assert is_binary(reason) and Regex.match?(~r/^R[1-4]: /, reason)

      assert Map.has_key?(measured, key),
             "permanent bare-type allowance #{inspect(key)} went stale"
    end
  end

  test "public specs do not reference hidden modules or private types" do
    actual = private_type_reference_findings()

    assert actual == [], "hidden/private type references: #{inspect(actual, limit: :infinity)}"
  end

  test "type_keys follows tagged unions and local types, with an extra-key mutation control" do
    {fixture, types} =
      compile_types_fixture("""
      @type shared :: {:c, atom()}
      @type options :: {:a, integer()} | {:b, String.t()} | shared()
      """)

    on_exit(fn -> purge_fixture(fixture) end)

    assert DocContract.type_keys(types, :options) == [:a, :b, :c]

    {mutated_fixture, mutated_types} =
      compile_types_fixture("""
      @type shared :: {:c, atom()}
      @type options :: {:a, integer()} | {:b, String.t()} | {:d, term()} | shared()
      """)

    on_exit(fn -> purge_fixture(mutated_fixture) end)

    doc_keys =
      DocContract.doc_bullet_keys(
        "## Options\n\n- `:a` — integer.\n- `:b` — string.\n- `:c` — atom.\n",
        "Options"
      )

    extra = DocContract.type_keys(mutated_types, :options) -- doc_keys

    assert extra == [:d]
  end

  test "doc_bullet_keys reads only the exact heading and treats an empty section as empty" do
    markdown = """
    ## Filters

    - `:table` — table name.

    ## Options

    - `:repo` — repository.

    ## Deprecated options

    - `:limit` — use `:page_size`.
    """

    assert DocContract.doc_bullet_keys(markdown, "Options") == [:repo]
    assert DocContract.doc_bullet_keys(markdown, "Deprecated options") == [:limit]
    assert DocContract.doc_bullet_keys("## Options\n\nNo keys here.\n", "Options") == []
  end

  test "bare_types recognizes every unsupported broad type form" do
    {fixture, types} =
      compile_types_fixture("""
      @type term_type :: term()
      @type any_type :: any()
      @type map_type :: map()
      @type keyword_type :: keyword()
      @type keyword_t_type :: Keyword.t()
      """)

    on_exit(fn -> purge_fixture(fixture) end)

    expected = %{
      term_type: [:term],
      any_type: [:any],
      map_type: [:map],
      keyword_type: [:keyword],
      keyword_t_type: [:keyword_t]
    }

    for {kind, {name, ast, _args}} <- types, kind == :type, name in Map.keys(expected) do
      assert DocContract.bare_types(ast) == expected[name]
    end

    assert DocContract.options_arg_type(
             {:type, 1, :fun,
              [{:type, 1, :product, [{:type, 1, :list, [{:user_type, 1, :named_opt, []}]}]}, :any]}
           ) ==
             {:local, :named_opt}

    assert DocContract.options_arg_type(
             {:type, 1, :fun,
              [
                {:type, 1, :product,
                 [{:remote_type, 1, [{:atom, 1, :elixir}, {:atom, 1, :keyword}, []]}]},
                :any
              ]}
           ) ==
             :untyped
  end

  test "first_paragraph and strip_code separate prose from examples" do
    markdown = """
    Returns one captured `AuditChange`.

    ```elixir
    powerful!(value)
    ```

        seamless!(value)
    """

    assert DocContract.first_paragraph(markdown) == "Returns one captured `AuditChange`."
    refute DocContract.strip_code(markdown) =~ "powerful"
    refute DocContract.strip_code(markdown) =~ "seamless"
  end

  defp option_parity_findings do
    Enum.flat_map(DocContract.universe(), fn {module, docs_v1, specs_result} ->
      specs = normalize_specs(specs_result)

      types =
        case Code.Typespec.fetch_types(module) do
          {:ok, module_types} -> module_types
          _error -> []
        end

      {:docs_v1, _, _, _, _, _, entries} = docs_v1

      Enum.flat_map(entries, fn
        {{kind, name, arity}, _anno, _sig, doc, _metadata}
        when kind in [:function, :macro] and doc != :hidden ->
          markdown = doc_text(doc)
          specs_for_entry = specs_for(specs, kind, name, arity)

          check_option_heading(module, name, arity, markdown, specs_for_entry, :options, types) ++
            check_option_heading(module, name, arity, markdown, specs_for_entry, :filters, types)

        _other ->
          []
      end)
    end)
    |> Enum.uniq()
    |> Enum.sort_by(&inspect/1)
  end

  defp check_option_heading(module, name, arity, markdown, specs, section, types) do
    heading = if section == :options, do: "Options", else: "Filters"

    if heading?(markdown, heading) do
      active_keys =
        DocContract.doc_bullet_keys(markdown, heading) ++
          if(heading == "Options",
            do: DocContract.doc_bullet_keys(markdown, "Deprecated options"),
            else: []
          )

      type_ref = specs |> Enum.map(&argument_type_for(&1, section)) |> List.first(:untyped)
      type_keys = if type_ref == :untyped, do: [], else: DocContract.type_keys(types, type_ref)
      runtime_keys = runtime_keys(module, name, section)

      findings =
        option_heading_findings(module, name, arity, heading, active_keys, type_ref, type_keys)

      runtime_parity_findings(
        {module, name, arity, heading},
        markdown,
        active_keys,
        type_keys,
        runtime_keys,
        findings
      )
    else
      []
    end
  end

  defp option_heading_findings(module, name, arity, heading, active_keys, type_ref, type_keys) do
    empty_section_finding(module, name, arity, heading, active_keys) ++
      duplicate_key_findings(module, name, arity, heading, active_keys) ++
      option_type_findings(module, name, arity, heading, active_keys, type_ref, type_keys)
  end

  defp empty_section_finding(module, name, arity, heading, []),
    do: [{:empty_section, module, name, arity, heading}]

  defp empty_section_finding(_module, _name, _arity, _heading, _keys), do: []

  defp duplicate_key_findings(module, name, arity, heading, keys) do
    keys
    |> Enum.frequencies()
    |> Enum.filter(fn {_key, count} -> count > 1 end)
    |> Enum.map(fn {key, _count} -> {:duplicate_key, module, name, arity, heading, key} end)
  end

  defp option_type_findings(module, name, arity, heading, _keys, :untyped, _type_keys),
    do: [{:options_untyped, module, name, arity, heading}]

  defp option_type_findings(module, name, arity, heading, keys, _type_ref, type_keys) do
    if Enum.sort(type_keys) == Enum.sort(keys) do
      []
    else
      [{:type_doc_keys, module, name, arity, heading, Enum.sort(type_keys), Enum.sort(keys)}]
    end
  end

  defp runtime_parity_findings(
         {module, name, arity, heading},
         markdown,
         _active_keys,
         _type_keys,
         :not_closed,
         findings
       ) do
    if String.contains?(section_markdown(markdown, heading), @unknown_key_sentence) do
      [{:unexpected_unknown_key_sentence, module, name, arity, heading} | findings]
    else
      findings
    end
  end

  defp runtime_parity_findings(
         entry,
         markdown,
         active_keys,
         type_keys,
         runtime_keys,
         findings
       ) do
    runtime_key_findings(entry, runtime_keys, type_keys, active_keys) ++
      unknown_key_sentence_findings(entry, markdown) ++ findings
  end

  defp section_markdown(markdown, heading) do
    pattern = ~r/^## #{Regex.escape(heading)}[ \t]*\r?\n(.*?)(?=^## |\z)/ms

    case Regex.run(pattern, markdown, capture: :all_but_first) do
      [section] -> section
      _missing_section -> ""
    end
  end

  defp runtime_key_findings({module, name, arity, heading}, runtime_keys, type_keys, doc_keys) do
    if Enum.sort(runtime_keys) == Enum.sort(type_keys) and
         Enum.sort(runtime_keys) == Enum.sort(doc_keys) do
      []
    else
      [
        {:runtime_keys, module, name, arity, heading, Enum.sort(runtime_keys),
         Enum.sort(type_keys), Enum.sort(doc_keys)}
      ]
    end
  end

  defp unknown_key_sentence_findings({module, name, arity, heading}, markdown) do
    if String.contains?(markdown, @unknown_key_sentence),
      do: [],
      else: [{:missing_unknown_key_sentence, module, name, arity, heading}]
  end

  defp runtime_keys(module, name, :options), do: read_runtime_keys(module, :__option_keys__, name)
  defp runtime_keys(module, name, :filters), do: read_runtime_keys(module, :__filter_keys__, name)

  defp read_runtime_keys(module, function, name) do
    if function_exported?(module, function, 1) do
      case apply(module, function, [name]) do
        keys when is_list(keys) -> Enum.sort(keys)
        _not_closed -> :not_closed
      end
    else
      :not_closed
    end
  rescue
    _error -> :not_closed
  end

  defp specs_for(specs, :function, name, arity),
    do:
      Enum.find_value(specs, [], fn {{spec_name, spec_arity}, clauses} ->
        if spec_name == name and spec_arity == arity, do: clauses
      end)

  defp specs_for(specs, :macro, name, arity),
    do:
      Enum.find_value(specs, [], fn {{spec_name, spec_arity}, clauses} ->
        if spec_name == String.to_atom("MACRO-#{name}") and spec_arity == arity + 1,
          do: clauses
      end)

  defp argument_type_for(spec_ast, :options), do: DocContract.options_arg_type(spec_ast)

  defp argument_type_for(spec_ast, :filters) do
    arguments = spec_arguments(spec_ast)

    arguments
    |> Enum.at(length(arguments) - 2)
    |> list_type_reference()
  end

  defp list_type_reference({:type, _anno, :list, [element]}) do
    case element do
      {:user_type, _, name, _args} -> {:local, name}
      {:remote_type, _, [{:atom, _, module}, {:atom, _, name}, _args]} -> {:remote, module, name}
      _other -> :untyped
    end
  end

  defp list_type_reference(_other), do: :untyped

  defp spec_arguments({:type, _anno, :bounded_fun, [function, _constraints]}),
    do: spec_arguments(function)

  defp spec_arguments({:type, _anno, :fun, [{:type, _product_anno, :product, args}, _return]}),
    do: args

  defp spec_arguments(_spec), do: []

  defp first_paragraph_findings do
    findings =
      for {module, kind, name, arity, markdown, _metadata} <- documentation_records(),
          first = DocContract.first_paragraph(markdown),
          issue <- first_paragraph_issues(first, markdown),
          do: {module, kind, name, arity, issue}

    Enum.sort_by(findings, &inspect/1)
  end

  defp first_paragraph_issues("", _markdown), do: [:empty_first_paragraph]

  defp first_paragraph_issues(_first, markdown) do
    if Regex.match?(~r/\b(?:TODO|FIXME|XXX)\b/i, DocContract.strip_code(markdown)),
      do: [:placeholder],
      else: []
  end

  defp deprecated_reference_findings do
    records = documentation_records()

    deprecated =
      for {module, _kind, name, arity, _markdown, metadata} <- records,
          metadata_value(metadata, :deprecated),
          do: {module, name, arity}

    deprecated_set = MapSet.new(deprecated)

    findings =
      for {module, kind, name, arity, markdown, metadata} <- records,
          not (module == Threadline and kind == :module),
          is_nil(metadata_value(metadata, :deprecated)),
          reference <- deprecated_references(strip_fenced_blocks(markdown), module),
          MapSet.member?(deprecated_set, reference),
          do: {module, kind, name, arity, reference}

    findings
    |> Enum.uniq()
    |> Enum.sort_by(&inspect/1)
  end

  defp deprecated_references(markdown, owner_module) do
    Regex.scan(
      ~r/`((?:Threadline(?:\.[[:upper:]][[:alnum:]_]*)*\.)?[[:lower:]_][[:alnum:]_!?]*\/[0-9]+)`/,
      markdown,
      capture: :all_but_first
    )
    |> Enum.map(fn [reference] ->
      [name, arity] = String.split(reference, "/")
      parts = String.split(name, ".")

      case Enum.split(parts, length(parts) - 1) do
        {[], [local_name]} ->
          {owner_module, String.to_atom(local_name), String.to_integer(arity)}

        {module_parts, [local_name]} ->
          target_module = module_atom(Enum.join(module_parts, "."))
          {target_module, String.to_atom(local_name), String.to_integer(arity)}
      end
    end)
    |> Enum.reject(fn {module, _name, _arity} -> is_nil(module) end)
  end

  defp metadata_value(metadata, key) when is_map(metadata), do: Map.get(metadata, key)

  defp metadata_value(metadata, key) when is_list(metadata) do
    Enum.find_value(metadata, fn
      {^key, value} -> {:found, value}
      _other -> nil
    end)
    |> case do
      {:found, value} -> value
      nil -> nil
    end
  end

  defp metadata_value(_metadata, _key), do: nil

  defp strip_fenced_blocks(markdown),
    do: String.replace(markdown, ~r/```[\s\S]*?```|~~~[\s\S]*?~~~/, "")

  defp module_atom("Threadline"), do: Threadline

  defp module_atom("Threadline." <> suffix) do
    Module.safe_concat([Threadline | String.split(suffix, ".")])
  rescue
    _error -> nil
  end

  defp module_atom(_other), do: nil

  defp voice_findings do
    bans = [
      "powerful",
      "seamless",
      "robust",
      "next-generation",
      "provenance",
      "governance",
      "immutable ledger"
    ]

    word_findings =
      for {module, kind, name, arity, markdown, _metadata} <- documentation_records(),
          text = DocContract.strip_code(markdown),
          ban <- bans,
          Regex.match?(Regex.compile!("\\b" <> Regex.escape(ban) <> "\\b", "i"), text),
          do: {module, kind, name, arity, ban}

    punctuation_findings =
      for {module, kind, name, arity, markdown, _metadata} <- documentation_records(),
          text = DocContract.strip_code(markdown),
          Regex.match?(~r/\w!(\s|$)/, text),
          do: {module, kind, name, arity, :sentence_exclamation}

    (word_findings ++ punctuation_findings)
    |> Enum.uniq()
    |> Enum.sort_by(&inspect/1)
  end

  defp since_entries do
    documentation_records()
    |> Enum.flat_map(fn {module, _kind, name, arity, _markdown, metadata} ->
      case metadata[:since] do
        nil -> []
        value -> [{module, name, arity, value}]
      end
    end)
    |> Enum.sort_by(&inspect/1)
  end

  defp since_findings do
    expected =
      MapSet.new(
        Enum.map(@new_in_1_0, fn {module, name, arity} -> {module, name, arity, "1.0.0"} end)
      )

    since_entries()
    |> Enum.reject(&MapSet.member?(expected, &1))
    |> Enum.map(&{:unexpected_since, &1})
    |> Kernel.++(
      expected
      |> MapSet.difference(MapSet.new(since_entries()))
      |> Enum.map(&{:missing_since, &1})
    )
    |> Enum.sort_by(&inspect/1)
  end

  defp code_block_findings do
    doctested = doctested_modules()

    findings =
      for {module, kind, name, arity, markdown, _metadata} <- documentation_records(),
          failure <- code_failures(markdown, module in doctested),
          do: {module, kind, name, arity, failure}

    Enum.sort_by(findings, &inspect/1)
  end

  defp code_failures(markdown, doctested?) do
    prompt_failures =
      if not doctested? and String.contains?(markdown, "iex>"),
        do: [:iex_prompt_without_doctest],
        else: []

    parse_failures =
      markdown
      |> indented_code_blocks()
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {block, index} ->
        {parsed, _diagnostics} =
          Code.with_diagnostics(fn -> Code.string_to_quoted(block) end)

        case parsed do
          {:ok, _ast} -> []
          {:error, _error} -> [{:unparseable_indented_block, index}]
        end
      end)

    prompt_failures ++ parse_failures
  end

  defp indented_code_blocks(markdown) do
    {blocks, current} =
      markdown
      |> String.split("\n")
      |> Enum.reduce({[], nil}, fn line, {blocks, current} ->
        cond do
          String.starts_with?(line, "    ") ->
            {blocks, [String.replace_prefix(line, "    ", "") | current || []]}

          line == "" and not is_nil(current) ->
            {blocks, ["" | current]}

          true ->
            {if(current,
               do: [current |> Enum.reverse() |> Enum.join("\n") | blocks],
               else: blocks
             ), nil}
        end
      end)

    if(current, do: [current |> Enum.reverse() |> Enum.join("\n") | blocks], else: blocks)
    |> Enum.reverse()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp doctested_modules do
    @root
    |> Path.join("test/**/*.exs")
    |> Path.wildcard()
    |> Enum.flat_map(fn path ->
      path
      |> File.read!()
      |> then(
        &Regex.scan(~r/\bdoctest\s+([[:upper:]][[:alnum:]_.]*)/, &1, capture: :all_but_first)
      )
      |> Enum.map(fn [name] -> module_atom(name) end)
    end)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  defp bare_type_findings do
    all_bare_type_occurrences()
    |> Enum.reject(fn {key, _bare} -> Map.has_key?(@permanent_bare_allowlist, key) end)
    |> Enum.sort_by(&inspect/1)
  end

  defp all_bare_type_occurrences do
    DocContract.universe()
    |> Enum.flat_map(fn {module, docs_v1, _specs} ->
      {:docs_v1, _, _, _, _, _, entries} = docs_v1

      function_bare_type_occurrences(module, entries) ++
        type_bare_type_occurrences(module, entries)
    end)
    |> Enum.sort_by(&inspect/1)
    |> Map.new()
  end

  defp function_bare_type_occurrences(module, entries) do
    visible_specs = visible_function_specs(entries)

    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} ->
        for {{name, arity}, clauses} <- specs,
            MapSet.member?(visible_specs, {name, arity}),
            bare = Enum.flat_map(clauses, &DocContract.bare_types/1),
            bare != [],
            do: {{module, :spec, name, arity}, Enum.sort(bare)}

      _error ->
        []
    end
  end

  defp visible_function_specs(entries) do
    entries
    |> Enum.flat_map(fn
      {{:function, name, arity}, _anno, _sig, doc, _metadata} when doc != :hidden ->
        [{name, arity}]

      {{:macro, name, arity}, _anno, _sig, doc, _metadata} when doc != :hidden ->
        [{String.to_atom("MACRO-#{name}"), arity + 1}]

      _other ->
        []
    end)
    |> MapSet.new()
  end

  defp type_bare_type_occurrences(module, entries) do
    visible_types =
      entries
      |> Enum.flat_map(fn
        {{kind, name, arity}, _anno, _sig, doc, _metadata}
        when kind in [:type, :opaque] and doc != :hidden ->
          [{name, arity}]

        _other ->
          []
      end)
      |> MapSet.new()

    case Code.Typespec.fetch_types(module) do
      {:ok, types} ->
        for {kind, {name, ast, args}} <- types,
            kind in [:type, :opaque],
            MapSet.member?(visible_types, {name, length(args)}),
            bare = DocContract.bare_types(ast),
            bare != [],
            do: {{module, :type, name, length(args)}, Enum.sort(bare)}

      _error ->
        []
    end
  end

  defp private_type_reference_findings do
    app_modules =
      case :application.get_key(:threadline, :modules) do
        {:ok, modules} -> MapSet.new(modules)
        _error -> MapSet.new()
      end

    findings =
      for {module, docs_v1, _specs} <- DocContract.universe(),
          {:docs_v1, _, _, _, _, _, entries} <- [docs_v1],
          {:ok, specs} <- [Code.Typespec.fetch_specs(module)],
          {{name, arity}, clauses} <- specs,
          visible_spec?(entries, name, arity),
          ast <- clauses,
          reference <- type_references(ast),
          finding <- private_type_reference_for(module, reference, app_modules),
          do: {module, name, arity, finding}

    findings
    |> Enum.uniq()
    |> Enum.sort_by(&inspect/1)
  end

  defp visible_spec?(entries, name, arity) do
    Enum.any?(entries, fn
      {{:function, ^name, ^arity}, _anno, _sig, doc, _metadata} ->
        doc != :hidden

      {{:macro, macro_name, macro_arity}, _anno, _sig, doc, _metadata} ->
        macro_name == String.to_atom(String.replace_prefix(Atom.to_string(name), "MACRO-", "")) and
          macro_arity + 1 == arity and doc != :hidden

      _other ->
        false
    end)
  end

  defp private_type_reference_for(module, {:local, name}, _app_modules) do
    private_types = private_type_names(module)
    if MapSet.member?(private_types, name), do: [{:private_type, module, name}], else: []
  end

  defp private_type_reference_for(_module, {:remote, remote_module, name}, app_modules) do
    if MapSet.member?(app_modules, remote_module) do
      private_remote_type_reference(remote_module, name)
    else
      []
    end
  end

  defp private_remote_type_reference(module, name) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, :hidden, _, _} ->
        [{:hidden_module_type, module, name}]

      _visible_module ->
        if MapSet.member?(private_type_names(module), name),
          do: [{:private_type, module, name}],
          else: []
    end
  end

  defp private_type_names(module) do
    case Code.Typespec.fetch_types(module) do
      {:ok, types} ->
        types
        |> Enum.flat_map(fn
          {:typep, {name, _ast, _args}} -> [name]
          _public -> []
        end)
        |> MapSet.new()

      _error ->
        MapSet.new()
    end
  end

  defp type_references({:user_type, _anno, name, _args}), do: [{:local, name}]

  defp type_references(
         {:remote_type, _anno, [{:atom, _module_anno, module}, {:atom, _name_anno, name}, _args]}
       ),
       do: [{:remote, module, name}]

  defp type_references(list) when is_list(list), do: Enum.flat_map(list, &type_references/1)

  defp type_references(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> type_references()

  defp type_references(_other), do: []

  defp documentation_records do
    Enum.flat_map(DocContract.universe(), fn {module, docs_v1, _specs} ->
      {:docs_v1, _, _, _, moduledoc, _, entries} = docs_v1

      [
        {module, :module, :moduledoc, 0, doc_text(moduledoc), %{}}
        | for(
            {{kind, name, arity}, _anno, _sig, doc, metadata} <- entries,
            kind in [:function, :macro, :type, :opaque],
            doc != :hidden,
            do: {module, kind, name, arity, doc_text(doc), metadata}
          )
      ]
    end)
    |> Enum.sort_by(&inspect/1)
  end

  defp doc_text(%{"en" => markdown}), do: markdown
  defp doc_text(:none), do: ""
  defp doc_text(:hidden), do: ""
  defp doc_text(_other), do: ""

  defp heading?(markdown, heading),
    do: Regex.match?(Regex.compile!("^## " <> Regex.escape(heading) <> "\\s*$", "m"), markdown)

  defp normalize_specs({:ok, specs}) when is_list(specs), do: specs
  defp normalize_specs(specs) when is_list(specs), do: specs
  defp normalize_specs(_other), do: []

  defp compile_types_fixture(body) do
    module = Module.concat(Threadline, "DocRubricFixture#{System.unique_integer([:positive])}")

    source = "defmodule #{inspect(module)} do\n" <> body <> "\nend\n"
    previous_options = Code.compiler_options()

    compiled =
      try do
        Code.compiler_options(docs: true, debug_info: true)
        Code.compile_string(source)
      after
        Code.compiler_options(previous_options)
      end

    {_module, binary} =
      Enum.find(compiled, fn {compiled_module, _bin} -> compiled_module == module end)

    {:ok, types} = Code.Typespec.fetch_types(binary)
    {module, types}
  end

  defp purge_fixture(module) do
    :code.purge(module)
    :code.delete(module)
  end
end
