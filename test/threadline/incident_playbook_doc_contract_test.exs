defmodule Threadline.IncidentPlaybookDocContractTest do
  use ExUnit.Case, async: true

  @playbook_path "guides/incident-playbook.md"

  test "incident playbook follows canonical structure" do
    content = File.read!(@playbook_path)

    # Assert presence of "Reading change_diff"
    assert content =~ "## Reading `change_diff`"

    # Assert presence of all five canonical incident headings
    assert content =~ "## who changed this row at time T?"
    assert content =~ "## what did service-account X do today?"
    assert content =~ "## did this Oban job actually mutate the DB?"
    assert content =~ "## what did this row look like at time T?"
    assert content =~ "## single-transaction drilldown"

    # Assert presence of LIVE-JOIN-WARNING
    assert content =~ "<!-- LIVE-JOIN-WARNING -->"

    # Ensure no SELECT * in SQL blocks
    # We can use Regex to check inside sql blocks
    sql_blocks = Regex.scan(~r/```sql\n(.*?)\n```/s, content)
    
    assert length(sql_blocks) > 0, "No SQL blocks found"
    
    Enum.each(sql_blocks, fn [_, sql] ->
      refute sql =~ ~r/SELECT\s+\*/i, "Found SELECT * in SQL block:\n#{sql}"
    end)
  end
end
