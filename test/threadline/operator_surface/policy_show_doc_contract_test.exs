defmodule Threadline.OperatorSurface.PolicyShowDocContractTest do
  @moduledoc """
  Phase 67 (REDN-05) doc-contract — pure source-reading literal pin.

  Locks the route literal, LiveView and Mix-task status copy, JSON status enums,
  rerun guidance, ordering/parity invariants, optional-Phoenix gating posture,
  and no-sample-values guardrails for the redaction drift surface.
  """

  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @router_path "lib/threadline/operator_surface/router.ex"
  @live_view_path "lib/threadline/operator_surface/live/policy_redaction_live.ex"
  @mix_task_path "lib/mix/tasks/threadline.policy.show.ex"
  @presenter_path "lib/threadline/policy/redaction_presenter.ex"

  describe "route literal" do
    test "router wires the policy redaction LiveView route" do
      src = File.read!(@router_path)

      assert String.contains?(src, ~s|live("/policy/redaction", PolicyRedactionLive, :index)|)
    end
  end

  describe "human-facing state literals" do
    test "LiveView source pins the three operator-safe status labels" do
      src = File.read!(@live_view_path)

      assert String.contains?(src, ~s|{:drift_detected, "Drift detected"}|)
      assert String.contains?(src, ~s|{:could_not_introspect, "Could not introspect"}|)
      assert String.contains?(src, ~s|{:config_matches_deployed, "Config matches deployed"}|)
    end

    test "Mix task source pins the same three status labels" do
      src = File.read!(@mix_task_path)

      assert String.contains?(src, ~s|defp status_label(:config_matches_deployed), do: "Config matches deployed"|)
      assert String.contains?(src, ~s|defp status_label(:drift_detected), do: "Drift detected"|)
      assert String.contains?(src, ~s|defp status_label(:could_not_introspect), do: "Could not introspect"|)
    end
  end

  describe "Mix-task help and rerun guidance" do
    test "mix threadline.policy.show source documents default and --json usage" do
      src = File.read!(@mix_task_path)

      assert String.contains?(src, ~s|@shortdoc "Show configured versus deployed redaction policy drift"|)
      assert String.contains?(src, "mix threadline.policy.show")
      assert String.contains?(src, "mix threadline.policy.show --json")
      assert String.contains?(src, "Default output prints one summary line, one aligned table, and detail blocks")
    end

    test "shared presenter carries the rerun hint and Mix task renders shared hints" do
      presenter_src = File.read!(@presenter_path)
      mix_src = File.read!(@mix_task_path)

      assert String.contains?(presenter_src, "Rerun `mix threadline.gen.triggers`")
      assert String.contains?(presenter_src, "do not assume capture is aligned.")
      assert String.contains?(mix_src, "row.hint")
    end
  end

  describe "JSON contract" do
    setup do
      Mix.Task.reenable("threadline.policy.show")
      :ok
    end

    test "--json emits the locked top-level keys and stable status enums" do
      output =
        capture_io(fn ->
          Mix.Tasks.Threadline.Policy.Show.run(["--json"])
        end)

      parsed = Jason.decode!(output)

      assert parsed |> Map.keys() |> Enum.sort() == [
               "config_matches_deployed",
               "could_not_introspect",
               "drift_detected",
               "schema",
               "tables",
               "total_tables"
             ]

      assert Enum.all?(parsed["tables"], fn row ->
               row["status"] in [
                 "config_matches_deployed",
                 "drift_detected",
                 "could_not_introspect"
               ]
             end)
    end
  end

  describe "ordering and parity invariants" do
    test "LiveView and presenter lock the same drift-first section order" do
      live_src = File.read!(@live_view_path)
      presenter_src = File.read!(@presenter_path)

      drift_index = byte_index(live_src, ~s|{:drift_detected, "Drift detected"}|)
      introspect_index = byte_index(live_src, ~s|{:could_not_introspect, "Could not introspect"}|)
      match_index = byte_index(live_src, ~s|{:config_matches_deployed, "Config matches deployed"}|)

      assert drift_index < introspect_index
      assert introspect_index < match_index

      assert String.contains?(
               presenter_src,
               "@group_order [:drift_detected, :could_not_introspect, :config_matches_deployed]"
             )
    end

    test "Mix task keeps the shared table/status/config/deployed/hint parity columns" do
      src = File.read!(@mix_task_path)

      assert String.contains?(src, ~s|["TABLE", "STATUS", "CONFIG", "DEPLOYED", "HINT"]|)
      assert String.contains?(src, "policy_cell(row.configured)")
      assert String.contains?(src, "deployed_cell(row.deployed)")
    end
  end

  describe "optional Phoenix gating posture" do
    test "LiveView stays file-scope gated while presenter and Mix task stay ungated" do
      live_src = File.read!(@live_view_path)
      mix_src = File.read!(@mix_task_path)
      presenter_src = File.read!(@presenter_path)

      assert String.starts_with?(live_src, "if Code.ensure_loaded?(Phoenix.LiveView) do")
      refute String.contains?(mix_src, "Code.ensure_loaded?")
      refute String.contains?(presenter_src, "Code.ensure_loaded?")
    end
  end

  describe "no-sample-values invariants" do
    test "source literals do not leak example payload values or sample secrets" do
      for path <- [@live_view_path, @mix_task_path, @presenter_path] do
        src = File.read!(path)

        refute src =~ "alice@example.com", "unexpected sample email leak in #{path}"
        refute src =~ "hunter2", "unexpected sample secret leak in #{path}"
        refute src =~ "super-secret", "unexpected sample secret leak in #{path}"
      end
    end

    test "source locks explicit unavailable/not-used placeholders instead of sample values" do
      src = File.read!(@live_view_path)

      assert String.contains?(src, ~s|defp deployed_columns_label(nil, _field), do: "not available"|)
      assert String.contains?(src, ~s|defp placeholder_label(_placeholder, []), do: "not used"|)
      assert String.contains?(src, ~s|defp deployed_placeholder_label(nil), do: "not available"|)
      assert String.contains?(src, ~s|defp deployed_placeholder_label(%{mask: []}), do: "not used"|)
    end
  end

  defp byte_index(haystack, needle) do
    case :binary.match(haystack, needle) do
      {index, _length} -> index
      :nomatch -> flunk("expected #{inspect(needle)} in source")
    end
  end
end
