defmodule ThreadlinePhoenix.DemoManifestContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @manifest Path.expand("../../DEMO-MANIFEST.md", __DIR__)

  describe "recipe table" do
    test "DEMO-MANIFEST.md contains the State recipes section header" do
      doc = File.read!(@manifest)

      assert String.contains?(doc, "## State recipes"),
             "expected DEMO-MANIFEST.md to include \"## State recipes\""
    end

    test "DEMO-MANIFEST.md contains screen-state-login triples for empty and scoped states" do
      doc = File.read!(@manifest)

      for literal <- [
            "empty",
            "offboarded-co.example.com",
            "support@offboarded-co.example.com",
            "Timeline",
            "Transactions",
            "Actor",
            "Row History"
          ] do
        assert String.contains?(doc, literal),
               "expected DEMO-MANIFEST.md to include #{inspect(literal)}"
      end
    end

    test "DEMO-MANIFEST.md contains a future-date filter literal" do
      doc = File.read!(@manifest)

      assert String.contains?(doc, "?from=2030"),
             "expected DEMO-MANIFEST.md to include \"?from=2030\""
    end

    test "DEMO-MANIFEST.md references the one-command seed story without --profile flags" do
      doc = File.read!(@manifest)

      assert String.contains?(doc, "mix demo.reset && mix demo.seed"),
             "expected DEMO-MANIFEST.md to include \"mix demo.reset && mix demo.seed\""

      assert String.contains?(doc, "--profile") == false or
               String.contains?(doc, "no `--profile`"),
             "expected DEMO-MANIFEST.md to document that no --profile flag is used"
    end

    test "DEMO-MANIFEST.md notes the Coverage deferred state as Phase 138 owned" do
      doc = File.read!(@manifest)

      assert String.contains?(doc, "Phase 138"),
             "expected DEMO-MANIFEST.md to include \"Phase 138\" (D-04 Coverage deferral)"
    end
  end

  describe "named actor literals" do
    test "DEMO-MANIFEST.md contains all three named non-human actor literals" do
      doc = File.read!(@manifest)

      for literal <- [
            "zendesk-sync",
            "oban-retention-purge",
            "trigger-backfill"
          ] do
        assert String.contains?(doc, literal),
               "expected DEMO-MANIFEST.md to include named actor literal #{inspect(literal)}"
      end
    end

    test "DEMO-MANIFEST.md contains the Named actor literals section" do
      doc = File.read!(@manifest)

      assert String.contains?(doc, "Named actor literals"),
             "expected DEMO-MANIFEST.md to include \"Named actor literals\" section (D-06)"
    end

    test "DEMO-MANIFEST.md documents the anonymous actor kind" do
      doc = File.read!(@manifest)

      assert String.contains?(doc, "anonymous"),
             "expected DEMO-MANIFEST.md to document the :anonymous actor kind"
    end
  end
end
