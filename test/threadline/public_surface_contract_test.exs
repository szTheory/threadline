defmodule Threadline.PublicSurfaceContractTest do
  @moduledoc false
  use ExUnit.Case, async: false

  @runtime_keys ~w(coverage_poll_ms ecto_repos export_queue_adapter export_status_poll_ms exports health operator_surface_embed_fonts operator_surface_embed_scripts retention retention_poll_ms storage_adapter storage_schema trigger_capture verify_coverage)a
  @hidden_modules [
    Threadline.CriticTrust.Measure,
    Threadline.CriticTrust.RankMetrics,
    Threadline.CriticTrust.LedgerSplice,
    Threadline.CriticTrust.KrippendorffAlpha,
    Threadline.CriticTrust.RepositoryBoundary,
    Mix.Tasks.Critic.Measure,
    Mix.Tasks.Critic.Synth
  ]
  # Released CHANGELOG entries are history and are never rewritten, so a module
  # renamed after release stays named there under its old name. Each rename is
  # recorded here explicitly (old => new). The old name is accepted as a
  # reference in CHANGELOG.md only; the pairing is itself asserted below, so an
  # entry cannot outlive the rename it records or stand in for a live module.
  @changelog_subject "CHANGELOG.md"
  @renamed_modules %{
    Threadline.OperatorSurface.Exports.FilterParams => Threadline.Query.FilterParams,
    Threadline.OperatorSurface.Scope => Threadline.Query.Scope
  }
  # The same history rule for Mix aliases that were deleted after release: a retired
  # alias is accepted as a reference in CHANGELOG.md only, and the register is itself
  # asserted below (gone from mix.exs, still named in the changelog).
  # Assembled so this file's own text never contains the retired alias name as a literal.
  @retired_aliases ["verify." <> "doc_contract"]
  @module_owner_tags [
    :module_visibility_seed,
    :module_visibility_capture,
    :module_visibility_governance,
    :module_visibility_domain_tail,
    :module_visibility_operator_coverage,
    :module_visibility_operator_plugs,
    :module_visibility_operator_helpers
  ]
  @reference_owner_tags [
    :public_doc_refs_external_design,
    :public_doc_refs_config,
    :public_doc_refs_extensions,
    :public_doc_refs_module_seed,
    :public_doc_refs_module_capture,
    :public_doc_refs_module_governance,
    :public_doc_refs_module_domain_tail,
    :public_doc_refs_module_operator_coverage,
    :public_doc_refs_module_operator_plugs,
    :public_doc_refs_module_operator_helpers,
    :public_doc_refs_changelog,
    :public_doc_refs_adopt_core,
    :public_doc_refs_example,
    :public_doc_refs_operate,
    :public_doc_refs_evaluate,
    :public_doc_refs_architecture,
    :public_doc_refs_integrations_contract,
    :public_doc_refs_integrations_tail,
    :public_doc_refs_contribute
  ]

  @local_reference_owners %{
    public_doc_refs_adopt_core: [
      "guides/getting-started-saas.md",
      "guides/production-checklist.md",
      "guides/local-docker-dx.md",
      "guides/upgrade-path.md",
      "guides/upgrading-to-0.11.md"
    ],
    public_doc_refs_operate: [
      "guides/operator-surface.md",
      "guides/incident-playbook.md",
      "guides/performance.md",
      "guides/audit-indexing.md"
    ],
    public_doc_refs_evaluate: [
      "guides/adoption-evidence-playbook.md",
      "guides/adoption-pilot-backlog.md",
      "guides/brownfield-continuity.md",
      "guides/domain-reference.md",
      "guides/evaluating-threadline.md"
    ],
    public_doc_refs_architecture: [
      "guides/how-threadline-works.md",
      "guides/code-walkthrough.md"
    ],
    public_doc_refs_integrations_contract: ["guides/integration-contracts.md"],
    public_doc_refs_integrations_tail: [
      "guides/integrations/sigra.md",
      "guides/integrations/phx-gen-auth.md"
    ],
    public_doc_refs_contribute: ["CONTRIBUTING.md"],
    public_doc_refs_changelog: ["CHANGELOG.md"],
    public_doc_refs_config: ["guides/configuration-and-commands.md"],
    public_doc_refs_module_seed: ["README.md"]
  }

  test "AST discovery handles multiline literal keys and reports dynamic module keys" do
    ast =
      Code.string_to_quoted!("""
      Application.get_env(
        :threadline,
        :storage_adapter,
        Threadline.Storage.Local
      )
      Application.fetch_env!(:threadline, adapter)
      Application.get_env(:other_app, :ignored)
      """)

    assert application_env_reads(ast).literal == MapSet.new([:storage_adapter])
    assert application_env_reads(ast).dynamic == MapSet.new(["adapter"])
  end

  test "classification helper rejects duplicates, omissions, and overlap by member" do
    assert :ok == exact_partition!(MapSet.new([:a, :b]), %{one: [:a], two: [:b]})

    assert_raise ExUnit.AssertionError, ~r/duplicate.*:a/, fn ->
      exact_partition!(MapSet.new([:a]), %{one: [:a, :a]})
    end

    assert_raise ExUnit.AssertionError, ~r/unclassified.*:b/, fn ->
      exact_partition!(MapSet.new([:a, :b]), %{one: [:a]})
    end

    assert_raise ExUnit.AssertionError, ~r/duplicate classification members.*:a/, fn ->
      exact_partition!(MapSet.new([:a]), %{one: [:a], two: [:a]})
    end
  end

  test "reference extractor rejects nonexistent modules, tasks, aliases, and config keys" do
    known = reference_inventory()

    bad = """
    `Threadline.DoesNotExist`
    `mix threadline.does_not_exist`
    `mix verify.does_not_exist`
    `config :threadline, does_not_exist: true`
    """

    assert validate_references(bad, known) == %{
             aliases: ["verify.does_not_exist"],
             keys: [:does_not_exist],
             modules: [Threadline.DoesNotExist],
             tasks: ["threadline.does_not_exist"]
           }
  end

  @tag :public_doc_refs_stable_modules
  test "README module references resolve through the compiled source inventory" do
    inventory = reference_inventory()
    refs = extract_references(File.read!("README.md"))

    assert refs.modules != [], "README module discovery is empty"
    assert Threadline.Audit in refs.modules, "README lost the Threadline.Audit façade sentinel"
    assert validate_references(File.read!("README.md"), inventory).modules == []
  end

  @tag :runtime_key_reference
  @tag :phase200_red
  test "literal runtime keys are an exact documented public compatibility set" do
    reads = source_env_reads()
    assert MapSet.size(reads.literal) > 0, "runtime-key AST discovery returned an empty set"
    assert :ecto_repos in reads.literal, "runtime-key discovery lost :ecto_repos sentinel"
    assert reads.literal == MapSet.new(@runtime_keys), runtime_key_diff(reads.literal)

    reference = read_public!("guides/configuration-and-commands.md")
    mentioned = extract_references(reference).keys |> MapSet.new()
    assert mentioned == reads.literal, runtime_key_diff(mentioned)
    assert MapSet.size(reads.dynamic) > 0, "dynamic adapter-module key discovery is empty"
  end

  @tag :command_reference
  @tag :phase200_red
  test "Mix tasks and repository aliases are exactly classified and documented" do
    tasks = discovered_mix_tasks()
    aliases = discovered_aliases()
    assert MapSet.size(tasks) > 0 and Mix.Tasks.Threadline.Install in tasks
    assert MapSet.size(aliases) > 0 and "ci.all" in aliases

    exact_partition!(tasks, task_classifications(tasks))
    exact_partition!(aliases, alias_classifications(aliases))

    unknown =
      validate_references(
        read_public!("guides/configuration-and-commands.md"),
        reference_inventory()
      )

    assert unknown.tasks == [] and unknown.aliases == [],
           "unknown Mix commands: #{inspect(unknown)}"
  end

  @tag :public_inventory
  @tag :phase200_red
  test "the complete public inventory is source-derived and non-vacuous" do
    assert source_env_reads().literal == MapSet.new(@runtime_keys)
    assert MapSet.size(discovered_mix_tasks()) > 0
    assert MapSet.size(discovered_aliases()) > 0
  end

  @tag :module_visibility_tracer
  @tag :phase200_red
  test "the public façade is grouped and mandatory critic modules are hidden" do
    groups = Threadline.MixProject.project()[:docs][:groups_for_modules]

    assert Keyword.keys(groups) == [
             :"Core API",
             :"Data Types",
             :"Configuration & Extension Points",
             :Integrations,
             :"Operator Surface",
             :"Mix Tasks"
           ]

    grouped = List.flatten(Keyword.values(groups))
    assert Enum.count(grouped, &(&1 == Threadline)) == 1

    assert Keyword.fetch!(groups, :"Mix Tasks") ==
             ~w(threadline.install threadline.gen.triggers threadline.gen.row_history_index threadline.verify_coverage threadline.continuity threadline.retention.purge threadline.export threadline.incident threadline.evidence.show threadline.health.coverage threadline.policy.show)
             |> Enum.map(&task_module/1)

    for module <- @hidden_modules do
      assert docs_visibility(module) == :hidden,
             "expected #{inspect(module)} to have @moduledoc false, got #{inspect(docs_visibility(module))}"

      refute module in grouped, "hidden module #{inspect(module)} appears in groups_for_modules"
    end
  end

  for tag <- @module_owner_tags do
    @tag tag
    @tag :phase200_red
    test "#{tag} remains a nonempty bounded visibility owner" do
      modules = modules_for_visibility_tag(unquote(tag))
      assert modules != [], "#{unquote(tag)} selected no modules"

      for module <- modules do
        assert module in MapSet.union(application_modules(), discovered_mix_tasks()),
               "#{inspect(module)} is absent from the compiled app"

        case docs_visibility(module) do
          :visible ->
            assert module in grouped_modules(), "visible #{inspect(module)} is ungrouped"

          :hidden ->
            refute module in grouped_modules(), "hidden #{inspect(module)} is grouped"

          :undocumented ->
            assert module in grouped_modules(),
                   "#{inspect(module)} has no @moduledoc, so ExDoc publishes it ungrouped; " <>
                     "give it @moduledoc false to hide it or add it to a group"

          :absent ->
            flunk("#{inspect(module)} has no compiled documentation chunk")
        end
      end
    end
  end

  @tag :module_visibility
  @tag :phase200_red
  test "every visible compiled module belongs to exactly one of six groups" do
    groups = Threadline.MixProject.project()[:docs][:groups_for_modules]

    assert Keyword.keys(groups) == [
             :"Core API",
             :"Data Types",
             :"Configuration & Extension Points",
             :Integrations,
             :"Operator Surface",
             :"Mix Tasks"
           ]

    flattened = List.flatten(Keyword.values(groups))

    assert length(flattened) == MapSet.size(MapSet.new(flattened)),
           "duplicate module group member"

    assert MapSet.new(flattened) == visible_modules(), visibility_diff(flattened)
  end

  for tag <- @reference_owner_tags do
    @tag tag
    @tag :phase200_red
    test "#{tag} owns a nonempty public-document reference slice" do
      subjects = reference_subjects(unquote(tag))
      assert subjects != [], "#{unquote(tag)} selected no public-document subjects"

      inventory = reference_inventory()

      for {subject, content} <- subjects do
        unknown = validate_references(content, inventory_for(subject, inventory))

        assert unknown == %{aliases: [], keys: [], modules: [], tasks: []},
               "#{subject} contains unknown public references: #{inspect(unknown)}"
      end
    end
  end

  test "every renamed module is gone, its successor is compiled, and the changelog still names it" do
    assert @renamed_modules != %{}, "the rename register is empty; drop the CHANGELOG exemption"

    compiled = application_modules()
    changelog = File.read!(@changelog_subject)

    for {old, new} <- @renamed_modules do
      refute MapSet.member?(compiled, old),
             "#{inspect(old)} is compiled again; remove it from @renamed_modules"

      assert MapSet.member?(compiled, new),
             "#{inspect(new)} (successor of #{inspect(old)}) is absent from the compiled app"

      assert String.contains?(changelog, inspect(old)),
             "#{@changelog_subject} no longer names #{inspect(old)}; remove it from @renamed_modules"
    end
  end

  test "every retired alias is gone from mix.exs and the changelog still names it" do
    changelog = File.read!(@changelog_subject)

    for name <- @retired_aliases do
      refute MapSet.member?(discovered_aliases(), name),
             "#{name} is a Mix alias again; remove it from @retired_aliases"

      assert String.contains?(changelog, name),
             "#{@changelog_subject} no longer names #{name}; remove it from @retired_aliases"
    end
  end

  @tag :public_doc_references
  @tag :phase200_red
  @tag :phase200_aggregate
  test "all local, external, and module-doc subjects have one exact owner" do
    extras = Threadline.MixProject.project()[:docs][:extras]
    {urls, local} = Enum.split_with(extras, &url_extra?/1)
    assert MapSet.new(local) == MapSet.new(local_extra_owner_paths()), local_extra_diff(local)
    assert length(local) == 23 and length(urls) == 2

    external_targets = Enum.map(urls, &external_extra_target/1) |> MapSet.new()

    assert external_targets ==
             MapSet.new(["DESIGN-SYSTEM.md", "examples/threadline_phoenix/README.md"])

    all_subjects =
      local
      |> Enum.map(&{&1, File.read!(&1)})
      |> Kernel.++(visible_module_doc_subjects())

    assert all_subjects != []
    assert Enum.any?(all_subjects, fn {name, _} -> name == "README.md" end)

    for {subject, content} <- all_subjects do
      unknown = validate_references(content, inventory_for(subject, reference_inventory()))

      assert unknown == %{aliases: [], keys: [], modules: [], tasks: []},
             "#{subject} contains unknown public references: #{inspect(unknown)}"
    end
  end

  defp source_env_reads do
    Enum.reduce(source_files(), %{literal: MapSet.new(), dynamic: MapSet.new()}, fn path, acc ->
      ast = path |> File.read!() |> Code.string_to_quoted!(file: path)
      reads = application_env_reads(ast)

      %{
        literal: MapSet.union(acc.literal, reads.literal),
        dynamic: MapSet.union(acc.dynamic, reads.dynamic)
      }
    end)
  end

  defp application_env_reads(ast) do
    {_ast, reads} =
      Macro.prewalk(ast, %{literal: MapSet.new(), dynamic: MapSet.new()}, fn
        {{:., _, [{:__aliases__, _, [:Application]}, fun]}, _, args} = node, acc
        when fun in [:get_env, :fetch_env, :fetch_env!] and length(args) in 2..3 ->
          case args do
            [:threadline, key | _] when is_atom(key) ->
              {node, update_in(acc.literal, &MapSet.put(&1, key))}

            [:threadline, key | _] ->
              {node, update_in(acc.dynamic, &MapSet.put(&1, Macro.to_string(key)))}

            _ ->
              {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    reads
  end

  defp discovered_mix_tasks do
    source_files()
    |> Enum.reduce(MapSet.new(), fn path, acc ->
      ast = path |> File.read!() |> Code.string_to_quoted!(file: path)

      {_ast, modules} =
        Macro.prewalk(ast, acc, fn
          {:defmodule, _, [{:__aliases__, _, parts} | _]} = node, found ->
            module = Module.concat(parts)

            {node,
             if(String.starts_with?(inspect(module), "Mix.Tasks."),
               do: MapSet.put(found, module),
               else: found
             )}

          node, found ->
            {node, found}
        end)

      modules
    end)
  end

  defp discovered_aliases do
    Threadline.MixProject.project()[:aliases]
    |> Keyword.keys()
    |> Enum.map(&to_string/1)
    |> MapSet.new()
  end

  defp exact_partition!(discovered, groups) do
    values = Map.values(groups) |> List.flatten()

    duplicates =
      values
      |> Enum.frequencies()
      |> Enum.filter(fn {_member, count} -> count > 1 end)
      |> Enum.map(&elem(&1, 0))

    assert duplicates == [], "duplicate classification members: #{inspect(duplicates)}"

    classified = MapSet.new(values)
    unclassified = MapSet.difference(discovered, classified)
    extra = MapSet.difference(classified, discovered)

    assert MapSet.size(unclassified) == 0,
           "unclassified members: #{inspect(MapSet.to_list(unclassified))}"

    assert MapSet.size(extra) == 0,
           "classified nonexistent members: #{inspect(MapSet.to_list(extra))}"

    overlaps =
      for {left_name, left} <- groups,
          {right_name, right} <- groups,
          left_name < right_name,
          member <- MapSet.intersection(MapSet.new(left), MapSet.new(right)),
          do: member

    assert overlaps == [], "classified more than once: #{inspect(overlaps)}"
    :ok
  end

  defp task_classifications(tasks) do
    public =
      ~w(threadline.install threadline.gen.triggers threadline.gen.row_history_index threadline.verify_coverage threadline.continuity threadline.retention.purge threadline.export threadline.incident threadline.evidence.show threadline.health.coverage threadline.policy.show)
      |> Enum.map(&task_module/1)

    repository = [Mix.Tasks.Threadline.VerifyTopology]
    maintainer = Enum.filter(tasks, &String.starts_with?(inspect(&1), "Mix.Tasks.Critic."))

    internal =
      tasks
      |> MapSet.difference(MapSet.new(public ++ repository ++ maintainer))
      |> MapSet.to_list()

    %{
      adopter_public: public,
      repository_only: repository,
      maintainer_only: maintainer,
      internal: internal
    }
  end

  defp alias_classifications(aliases) do
    maintainer =
      Enum.filter(
        aliases,
        &(&1 in [
            "verify.ui_critique",
            "verify.capture",
            "verify.operator_component_contracts"
          ])
      )

    repository = MapSet.to_list(aliases) -- maintainer
    %{adopter_public: [], repository_only: repository, maintainer_only: maintainer, internal: []}
  end

  defp task_module(name) do
    name
    |> String.split(".")
    |> Enum.map(&Macro.camelize/1)
    |> then(&Module.concat([Mix.Tasks | &1]))
  end

  defp extract_references(content) do
    modules =
      Regex.scan(~r/\b(?:Threadline|Mix\.Tasks)(?:\.[A-Z][A-Za-z0-9_]*)+\b/, content)
      |> Enum.map(fn [name] -> Module.concat(String.split(name, ".")) end)
      |> Enum.uniq()

    commands =
      Regex.scan(~r/\bmix\s+([a-z][a-z0-9_.-]*)\b/, content)
      |> Enum.map(&Enum.at(&1, 1))
      |> Enum.uniq()

    keys =
      Regex.scan(
        ~r/(?:config|Application\.(?:get_env|fetch_env!?))\s*\(?\s*:threadline\s*,?\s*:([a-z][a-z0-9_]*)|\bconfig\s+:threadline\s*,\s*([a-z][a-z0-9_]*)\s*:/m,
        content
      )
      |> Enum.map(fn matches -> matches |> Enum.drop(1) |> Enum.find(&(&1 != "")) end)
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&String.to_atom/1)
      |> Enum.uniq()

    %{modules: modules, commands: commands, keys: keys}
  end

  defp validate_references(content, inventory) do
    refs = extract_references(content)
    known_task_names = Enum.map(inventory.tasks, &mix_task_name/1)
    threadline_commands = Enum.filter(refs.commands, &String.starts_with?(&1, "threadline."))

    repository_aliases =
      Enum.filter(refs.commands, fn command ->
        String.starts_with?(command, ["verify.", "ci.", "test."])
      end)

    %{
      modules: Enum.reject(refs.modules, &(&1 in inventory.modules)),
      tasks: threadline_commands -- known_task_names,
      aliases: repository_aliases -- inventory.aliases,
      keys: Enum.reject(refs.keys, &(&1 in inventory.keys))
    }
  end

  defp inventory_for(@changelog_subject, inventory) do
    %{
      inventory
      | modules: inventory.modules ++ Map.keys(@renamed_modules),
        aliases: inventory.aliases ++ @retired_aliases
    }
  end

  defp inventory_for(_subject, inventory), do: inventory

  defp reference_inventory do
    application_modules = MapSet.to_list(application_modules())

    %{
      modules:
        application_modules ++
          module_namespaces(application_modules) ++ MapSet.to_list(discovered_mix_tasks()),
      tasks: MapSet.to_list(discovered_mix_tasks()),
      aliases: MapSet.to_list(discovered_aliases()),
      keys: MapSet.to_list(source_env_reads().literal)
    }
  end

  defp mix_task_name(module) do
    module
    |> Module.split()
    |> Enum.drop(2)
    |> Enum.map_join(".", &Macro.underscore/1)
  end

  defp module_namespaces(modules) do
    modules
    |> Enum.flat_map(fn module ->
      parts = Module.split(module)

      for length <- 2..max(length(parts) - 1, 2),
          length < Kernel.length(parts),
          do: parts |> Enum.take(length) |> Module.concat()
    end)
    |> Enum.uniq()
  end

  defp source_files, do: ["mix.exs" | Path.wildcard("lib/**/*.ex")]

  defp read_public!(path) do
    assert File.regular?(path), "missing required public-document subject: #{path}"
    File.read!(path)
  end

  defp application_modules do
    {:ok, modules} = :application.get_key(:threadline, :modules)

    modules
    |> Enum.filter(&packaged_source_module?/1)
    |> MapSet.new()
  end

  defp packaged_source_module?(module) do
    with {:module, ^module} <- Code.ensure_loaded(module),
         source when is_list(source) <- module.module_info(:compile)[:source] do
      source
      |> List.to_string()
      |> Path.relative_to(File.cwd!())
      |> String.starts_with?("lib/")
    else
      _ -> false
    end
  end

  # Every module ExDoc puts on the public index, which is both the documented
  # ones and the undocumented-but-published ones. The grouping criterion is a
  # property of the generated index, so it has to be measured over the same set
  # the index contains.
  defp visible_modules do
    application_modules()
    |> MapSet.union(discovered_mix_tasks())
    |> Enum.filter(&(docs_visibility(&1) in [:visible, :undocumented]))
    |> MapSet.new()
  end

  # :none means the module has a documentation chunk but no @moduledoc. ExDoc
  # PUBLISHES such a module — it is omitted only by @moduledoc false — so it is
  # classified :undocumented rather than :absent. Folding it into :absent is what
  # made the grouping assertion below vacuous against exactly the class of module
  # that violates it: published, ungrouped, and invisible to the check.
  # :absent is reserved for a module with no documentation chunk at all.
  defp docs_visibility(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, :hidden, _, _} -> :hidden
      {:docs_v1, _, _, _, :none, _, _} -> :undocumented
      {:docs_v1, _, _, _, %{} = docs, _, _} when map_size(docs) > 0 -> :visible
      _ -> :absent
    end
  end

  defp grouped_modules,
    do:
      Threadline.MixProject.project()[:docs][:groups_for_modules]
      |> Keyword.values()
      |> List.flatten()

  defp modules_for_visibility_tag(:module_visibility_seed),
    do: [
      Threadline.OperatorSurface.Style,
      Threadline.OperatorSurface.UI.Form,
      Threadline.OperatorSurface.UI.Actions,
      Threadline.OperatorSurface.UI.Display,
      Threadline.OperatorSurface.UI.Data,
      Threadline.OperatorSurface.UI.Overlay,
      Threadline.OperatorSurface.UI.Page,
      Threadline.Capture.Migration,
      Threadline.Evidence.Subject,
      Mix.Tasks.Threadline.Gen.Triggers
    ]

  defp modules_for_visibility_tag(:module_visibility_capture),
    do: [
      Threadline.Capture.RedactionPolicy,
      Threadline.Capture.TriggerCaptureConfig,
      Threadline.Capture.TriggerSQL,
      Threadline.Export.CleanupTask
    ]

  defp modules_for_visibility_tag(:module_visibility_governance),
    do: [
      Threadline.Governance.ExportJob,
      Threadline.Governance.Migration,
      Threadline.Governance.RetentionRun,
      Threadline.Governance.SavedView,
      Threadline.Health.CoverageSchemas
    ]

  defp modules_for_visibility_tag(:module_visibility_domain_tail),
    do: [
      Threadline.Policy.RedactionPresenter,
      Threadline.Query.Cursors,
      Threadline.Query.FilterParams,
      Threadline.Query.Scope,
      Threadline.Retention.Pruner,
      Threadline.Semantics.Migration,
      Threadline.OperatorSurface.Controllers.ThemeController,
      Threadline.OperatorSurface.Fonts
    ]

  defp modules_for_visibility_tag(:module_visibility_operator_coverage),
    do: [
      Threadline.OperatorSurface.Controllers.ExportController,
      Threadline.OperatorSurface.Coverage.OnMount,
      Threadline.OperatorSurface.Coverage.Snapshot
    ]

  defp modules_for_visibility_tag(:module_visibility_operator_plugs),
    do: [
      Threadline.OperatorSurface.ExportAuthPlug,
      Threadline.OperatorSurface.SessionPlug,
      Threadline.OperatorSurface.ThemeAuthPlug
    ]

  defp modules_for_visibility_tag(:module_visibility_operator_helpers),
    do: [
      Threadline.OperatorSurface.Exports.Filename,
      Threadline.OperatorSurface.Presentation,
      Threadline.OperatorSurface.Script,
      Threadline.OperatorSurface.Router
    ]

  defp reference_subjects(:public_doc_refs_external_design) do
    [{"DESIGN-SYSTEM.md", File.read!("DESIGN-SYSTEM.md")}]
  end

  defp reference_subjects(:public_doc_refs_example),
    do: [{"example README", File.read!("examples/threadline_phoenix/README.md")}]

  defp reference_subjects(:public_doc_refs_extensions),
    do: module_doc_subjects([Threadline.Storage, Threadline.Storage.Local, Threadline.Storage.S3])

  defp reference_subjects(:public_doc_refs_module_seed),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_seed))

  defp reference_subjects(:public_doc_refs_module_capture),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_capture))

  defp reference_subjects(:public_doc_refs_module_governance),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_governance))

  defp reference_subjects(:public_doc_refs_module_domain_tail),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_domain_tail))

  defp reference_subjects(:public_doc_refs_module_operator_coverage),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_operator_coverage))

  defp reference_subjects(:public_doc_refs_module_operator_plugs),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_operator_plugs))

  defp reference_subjects(:public_doc_refs_module_operator_helpers),
    do: module_doc_subjects(modules_for_visibility_tag(:module_visibility_operator_helpers))

  defp reference_subjects(tag) do
    @local_reference_owners
    |> Map.get(tag, ["README.md"])
    |> Enum.map(&{&1, File.read!(&1)})
  end

  defp visible_module_doc_subjects do
    visible_modules() |> Enum.sort() |> module_doc_subjects()
  end

  defp module_doc_subjects(modules) do
    Enum.map(modules, fn module -> {inspect(module), fetch_doc_text(module)} end)
  end

  defp fetch_doc_text(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, module_doc, _, docs} ->
        [doc_text(module_doc) | Enum.map(docs, fn {_, _, _, doc, _} -> doc_text(doc) end)]
        |> Enum.join("\n")

      _ ->
        ""
    end
  end

  defp doc_text(%{"en" => text}), do: text
  defp doc_text(:none), do: ""
  defp doc_text(:hidden), do: ""
  defp doc_text(_), do: ""

  defp local_extra_owner_paths do
    @local_reference_owners |> Map.values() |> List.flatten() |> Enum.uniq()
  end

  defp url_extra?(extra),
    do: is_tuple(extra) or (is_binary(extra) and String.starts_with?(extra, "http"))

  defp external_extra_target({url, _opts}), do: external_extra_target(url)

  defp external_extra_target(url) do
    case Regex.run(~r{/blob/[^/]+/(.+)$}, url) do
      [_, target] ->
        target

      _ ->
        flunk("external ExDoc extra is not a version-pinned repository blob URL: #{inspect(url)}")
    end
  end

  defp runtime_key_diff(actual),
    do:
      "runtime-key mismatch; actual=#{inspect(MapSet.to_list(actual))} expected=#{inspect(@runtime_keys)}"

  defp visibility_diff(actual),
    do:
      "module-group mismatch; grouped=#{inspect(actual)} visible=#{inspect(MapSet.to_list(visible_modules()))}"

  defp local_extra_diff(actual),
    do:
      "local-extra ownership mismatch; actual=#{inspect(actual)} owners=#{inspect(local_extra_owner_paths())}"
end
