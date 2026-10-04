defmodule Threadline.DocSpecCoverageContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Threadline.DocContract

  @gap_ratchet [
    {Threadline, :as_of, 4, :missing_spec},
    {Threadline, :audit_changes_for_transaction, 2, :missing_spec},
    {Threadline, :change_diff, 2, :missing_spec},
    {Threadline, :export_csv, 2, :missing_spec},
    {Threadline, :export_json, 2, :missing_spec},
    {Threadline, :record_action, 2, :missing_spec},
    {Threadline, :timeline, 2, :missing_spec},
    {Threadline.Audit, :action_opt, 0, :missing_typedoc},
    {Threadline.Continuity, :assert_capture_ready!, 2, :missing_spec},
    {Threadline.Continuity, :explain_cutover, 1, :missing_spec},
    {Threadline.Evidence, :get_latest_subject_ref, 3, :missing_spec},
    {Threadline.Evidence, :list_history, 2, :missing_spec},
    {Threadline.Evidence, :list_latest_subject_refs, 2, :missing_doc},
    {Threadline.Evidence, :list_latest_subject_refs, 2, :missing_spec},
    {Threadline.Evidence, :list_latest_subject_refs, 3, :missing_spec},
    {Threadline.Evidence, :list_overview, 2, :missing_spec},
    {Threadline.Evidence, :list_subject_ref_history, 3, :missing_doc},
    {Threadline.Evidence, :list_subject_ref_history, 3, :missing_spec},
    {Threadline.Evidence, :list_subject_ref_history, 4, :missing_spec},
    {Threadline.Evidence, :record_export_delivery, 3, :missing_spec},
    {Threadline.Evidence, :record_redaction_policy, 3, :missing_spec},
    {Threadline.Evidence, :record_retention_policy, 3, :missing_spec},
    {Threadline.Evidence, :record_retention_run, 3, :missing_spec},
    {Threadline.Evidence, :record_support_scope_posture, 3, :missing_spec},
    {Threadline.Evidence, :record_trigger_coverage, 3, :missing_spec},
    {Threadline.Evidence.Proof, :present_record, 1, :missing_doc},
    {Threadline.Evidence.Proof, :present_record, 1, :missing_spec},
    {Threadline.Evidence.Proof, :proof_document, 2, :missing_spec},
    {Threadline.Evidence.Proof, :record_claim_assessment, 1, :missing_doc},
    {Threadline.Evidence.Proof, :record_claim_assessment, 1, :missing_spec},
    {Threadline.Evidence.Proof, :render_human, 1, :missing_spec},
    {Threadline.Evidence.Proof, :render_json, 1, :missing_spec},
    {Threadline.Evidence.Proof, :to_json_iodata, 2, :missing_spec},
    {Threadline.Evidence.Subject, :subject_descriptor, 0, :missing_typedoc},
    {Threadline.Evidence.Subject, :supported_subjects, 0, :missing_spec},
    {Threadline.Export.Orchestrator, :run, 2, :missing_spec},
    {Threadline.ExportQueue, :job_id, 0, :missing_typedoc},
    {Threadline.ExportQueue.TaskAdapter, :enqueue, 2, :missing_spec},
    {Threadline.Health, :trigger_coverage, 1, :missing_spec},
    {Threadline.Health.Finding, :code, 0, :missing_typedoc},
    {Threadline.Health.Finding, :severity, 0, :missing_typedoc},
    {Threadline.Health.Finding, :t, 0, :missing_typedoc},
    {Threadline.Health.Policy, :validate!, 1, :missing_spec},
    {Threadline.Integrations.Sigra, :audit_overrides, 0, :missing_typedoc},
    {Threadline.Investigation.IncidentBundle, :t, 0, :missing_typedoc},
    {Threadline.Investigation.IncidentChange, :t, 0, :missing_typedoc},
    {Threadline.Investigation.LinkedChange, :t, 0, :missing_typedoc},
    {Threadline.Investigation.LinkedTransaction, :t, 0, :missing_typedoc},
    {Threadline.Job, :actor_ref_from_args, 1, :missing_spec},
    {Threadline.Job, :context_opts, 2, :missing_spec},
    {Threadline.NotFoundError, :t, 0, :missing_typedoc},
    {Threadline.OperatorSurface.Auth, :on_mount, 4, :missing_doc},
    {Threadline.OperatorSurface.Auth, :on_mount, 4, :missing_spec},
    {Threadline.OperatorSurface.Router, :threadline_operator_surface, 2, :missing_doc},
    {Threadline.Semantics.ActorRef, :from_map, 1, :missing_spec},
    {Threadline.Semantics.ActorRef, :new, 2, :missing_spec},
    {Threadline.Semantics.ActorRef, :to_map, 1, :missing_spec},
    {Threadline.Storage, :content, 0, :missing_typedoc},
    {Threadline.Storage, :file_id, 0, :missing_typedoc},
    {Threadline.Storage, :options, 0, :missing_typedoc},
    {Threadline.StorageSchema, :function, 2, :missing_spec},
    {Threadline.StorageSchema, :get, 1, :missing_spec},
    {Threadline.StorageSchema, :host_table_suffix, 1, :missing_spec},
    {Threadline.StorageSchema, :parse_table_identifier, 1, :missing_spec},
    {Threadline.StorageSchema, :qualified_host_table, 1, :missing_spec},
    {Threadline.StorageSchema, :qualify, 2, :missing_spec},
    {Threadline.StorageSchema, :quote_ident, 1, :missing_spec},
    {Threadline.StorageSchema, :repo_opts, 1, :missing_spec},
    {Threadline.StorageSchema, :table, 2, :missing_spec},
    {Threadline.StorageSchema, :threadline_table?, 1, :missing_spec},
    {Threadline.StorageSchema, :validate!, 1, :missing_spec},
    {Threadline.Telemetry, :transaction_committed, 2, :missing_spec},
    {Threadline.Verify.CoveragePolicy, :summary_counts, 2, :missing_spec},
    {Threadline.Verify.CoveragePolicy, :violations, 2, :missing_spec}
  ]

  describe "coverage at rest" do
    test "the live universe and checked entries are non-vacuous" do
      universe = DocContract.universe()

      assert length(universe) >= 50,
             "expected at least 50 documented modules, got #{length(universe)}"

      checked =
        for {module, docs_v1, _specs} <- universe,
            {kind, name, arity, _doc, _metadata} <- DocContract.checked_entries(docs_v1),
            do: {module, kind, name, arity}

      assert length(checked) >= 90,
             "expected at least 90 visible entries, got #{length(checked)}"

      assert {Threadline, :function, :timeline, 2} in checked,
             "expected the facade timeline/2 entry to be part of the scanned universe"
    end

    test "all live gaps match the baseline ratchet exactly" do
      actual =
        DocContract.universe()
        |> Enum.flat_map(fn {module, docs_v1, specs} ->
          DocContract.gaps(module, docs_v1, specs)
        end)

      new_gaps = actual -- @gap_ratchet
      fixed_but_still_pinned = @gap_ratchet -- actual

      assert actual == @gap_ratchet,
             "documentation/specification coverage changed.\n" <>
               "new gap(s):\n#{DocContract.format_gaps(new_gaps)}\n" <>
               "fixed but still pinned:\n#{DocContract.format_gaps(fixed_but_still_pinned)}\n" <>
               "add @doc/@spec, or @doc false plus a reasoned entry in the hidden pin"

      assert length(actual) == 74
      assert Enum.count(actual, fn {_, _, _, kind} -> kind == :missing_spec end) == 53
      assert Enum.count(actual, fn {_, _, _, kind} -> kind == :missing_doc end) == 6
      assert Enum.count(actual, fn {_, _, _, kind} -> kind == :missing_typedoc end) == 15
    end
  end

  describe "checker mutation control" do
    test "reads Docs and specs from the compiled fixture binary and applies the arity rules" do
      suffix = System.unique_integer([:positive])
      behaviour = Module.concat(Threadline, "DocContractFixtureBehaviour#{suffix}")
      fixture = Module.concat(Threadline, "DocContractFixture#{suffix}")

      source = """
      defmodule #{inspect(behaviour)} do
        @callback impl() :: :ok
      end

      defmodule #{inspect(fixture)} do
        @moduledoc "A checker fixture."

        @type no_typedoc :: term()

        def undocumented, do: :ok

        @doc "Documented, but deliberately unspecced."
        def documented_unspecced, do: :ok

        @doc false
        def hidden, do: :ok

        @doc "The maximum docs arity is the only entry that needs a spec."
        @spec defaults(integer(), integer()) :: integer()
        def defaults(left, right \\\\ 1), do: left + right

        @doc "A macro needs documentation, but not a spec."
        defmacro documented_macro, do: quote(do: :ok)

        @deprecated "fixture"
        @doc "Deprecated entries still need specs."
        def deprecated_unspecced, do: :ok

        @behaviour #{inspect(behaviour)}
        @impl true
        def impl, do: :ok
      end
      """

      previous_compiler_options = Code.compiler_options()

      compiled =
        try do
          Code.compiler_options(docs: true, debug_info: true)
          Code.compile_string(source)
        after
          Code.compiler_options(previous_compiler_options)
        end

      on_exit(fn ->
        Enum.each(compiled, fn {module, _bin} ->
          :code.purge(module)
          :code.delete(module)
        end)
      end)

      {_module, binary} = Enum.find(compiled, fn {module, _bin} -> module == fixture end)

      assert {:ok, {^fixture, [{~c"Docs", docs_binary}]}} =
               :beam_lib.chunks(binary, [~c"Docs"])

      docs_v1 = :erlang.binary_to_term(docs_binary)
      assert {:ok, specs} = Code.Typespec.fetch_specs(binary)

      assert DocContract.gaps(fixture, docs_v1, {:ok, specs}) == [
               {fixture, :deprecated_unspecced, 0, :missing_spec},
               {fixture, :documented_unspecced, 0, :missing_spec},
               {fixture, :no_typedoc, 0, :missing_typedoc},
               {fixture, :undocumented, 0, :missing_doc},
               {fixture, :undocumented, 0, :missing_spec}
             ]

      checked = DocContract.checked_entries(docs_v1)
      checked_keys = Enum.map(checked, fn {_kind, name, arity, _doc, _meta} -> {name, arity} end)

      refute {:hidden, 0} in checked_keys
      refute {:impl, 0} in checked_keys
      assert {:documented_macro, 0} in checked_keys
      assert {:defaults, 2} in checked_keys
      refute {:defaults, 1} in checked_keys
    end

    test "gap formatting is stable, sorted, and labels each missing annotation" do
      gaps = [
        {Threadline.Query, :zeta, 1, :missing_spec},
        {Threadline, :alpha, 2, :missing_doc},
        {Threadline, :alpha, 2, :missing_spec}
      ]

      assert DocContract.format_gaps(gaps) ==
               "Threadline.alpha/2  missing @doc\n" <>
                 "Threadline.alpha/2  missing @spec\n" <>
                 "Threadline.Query.zeta/1  missing @spec"
    end
  end
end
