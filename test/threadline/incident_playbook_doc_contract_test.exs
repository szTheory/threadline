defmodule Threadline.IncidentPlaybookDocContractTest do
  use ExUnit.Case, async: true

  @playbook_path "guides/incident-playbook.md"

  setup do
    content = File.read!(@playbook_path)
    %{content: content}
  end

  describe "Incident Playbook Contract" do
    test "contains the Reading change_diff subsection", %{content: content} do
      assert content =~ "## Reading `change_diff`"
    end

    test "contains all five canonical incident headings", %{content: content} do
      assert content =~ "## Scenario: who changed this row at time T?"
      assert content =~ "## Scenario: what did service-account X do today?"
      assert content =~ "## Scenario: did this Oban job actually mutate the DB?"
      assert content =~ "## Scenario: what did this row look like at time T?"
      assert content =~ "## Scenario: single-transaction drilldown"
    end

    test "contains LIVE-JOIN-WARNING callout", %{content: content} do
      assert content =~ "<!-- LIVE-JOIN-WARNING -->"
    end

    test "locks the incident drill-down auth baseline and host-owned policy boundary", %{content: content} do
      assert content =~ "GET /api/audit_transactions/:id/changes"
      assert content =~ "incident drill-down requires an"
      assert content =~ "authenticated actor"
      assert content =~ "Treat that as the minimum host shape, then layer your own"
      assert content =~ "tenancy and policy rules on top"
    end

    test "uses the shipped Threadline public surface", %{content: content} do
      assert content =~ "Threadline.history("
      assert content =~ "Threadline.actor_history("
      assert content =~ "Threadline.audit_changes_for_transaction("
      assert content =~ "Threadline.as_of("

      refute content =~ "Threadline.Query.changes_for_record"
      refute content =~ "Threadline.Query.changes_by_actor"
      refute content =~ "Threadline.Query.changes_by_context"
      refute content =~ "Threadline.Query.changes_in_transaction"
      refute content =~ "Threadline.Continuity.reconstruct_at"
      refute content =~ "threadline_changes"
      refute content =~ "record_pk"
      refute content =~ "context_json"
    end

    test "does not contain SELECT * in raw SQL blocks", %{content: content} do
      # Extract all SQL blocks
      sql_blocks = Regex.scan(~r/```sql\n(.*?)```/s, content)
      
      assert length(sql_blocks) > 0, "Expected to find at least one SQL block"

      Enum.each(sql_blocks, fn [_, sql_content] ->
        # Assert that SELECT * is not in the block
        refute sql_content =~ ~r/SELECT\s+\*/i, "Found 'SELECT *' in a SQL block: \n#{sql_content}"
      end)
    end
    
    test "has expected structure for each scenario", %{content: content} do
      scenarios = [
        "who changed this row at time T?",
        "what did service-account X do today?",
        "did this Oban job actually mutate the DB?",
        "what did this row look like at time T?",
        "single-transaction drilldown"
      ]

      Enum.each(scenarios, fn scenario ->
        # Find the section for the scenario
        header = "## Scenario: " <> scenario
        assert String.contains?(content, header), "Could not find header: #{header}"

        # Get everything after the header
        [_before, after_header] = String.split(content, header, parts: 2)
        
        # The section content goes until the next "## " or the end of the string
        section_content = hd(String.split(after_header, "\n## ", parts: 2))
        
        assert section_content =~ "### Diagnosis (API)", "Missing 'Diagnosis (API)' in scenario: #{scenario}"
        assert section_content =~ "### Diagnosis (raw SQL)", "Missing 'Diagnosis (raw SQL)' in scenario: #{scenario}"
        assert section_content =~ "### Expected output", "Missing 'Expected output' in scenario: #{scenario}"
        assert section_content =~ "### Recovery", "Missing 'Recovery' in scenario: #{scenario}"
      end)
    end
  end
end
