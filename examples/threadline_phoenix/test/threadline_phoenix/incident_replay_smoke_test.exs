defmodule ThreadlinePhoenix.IncidentReplaySmokeTest do
  use ExUnit.Case, async: false

  @script_path "priv/scripts/incident_replay.exs"

  test "aborts without required environment variable" do
    {output, exit_code} = System.cmd("mix", ["run", @script_path], 
      env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", nil}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
    
    assert exit_code != 0
    assert output =~ "Error: THREADLINE_REPLAY_DISPOSABLE_DB=1 is required."
  end

  test "dry-run is default behavior" do
    {output, exit_code} = System.cmd("mix", ["run", @script_path, "--incident=who-changed-this-row"], 
      env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "1"}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
    
    assert exit_code == 0, "Execution failed with output:\n#{output}"
    
    # Check that it output valid JSON for the dry-run
    # System.cmd will output compile warnings possibly, so we extract JSON lines
    lines = String.split(output, "\n", trim: true)
    json_line = Enum.find(lines, &String.starts_with?(&1, "{"))
    
    assert json_line != nil, "Expected JSON output, got:\n#{output}"
    parsed = Jason.decode!(json_line)
    
    assert parsed["incident"] == "who-changed-this-row"
    assert parsed["status"] == "dry-run"
  end

  test "executes scenario and returns expected shape" do
    {output, exit_code} = System.cmd("mix", ["run", @script_path, "--incident=single-transaction", "--execute"], 
      env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "1"}, {"MIX_ENV", "test"}],
      stderr_to_stdout: true
    )
    
    assert exit_code == 0, "Execution failed with output:\n#{output}"
    
    lines = String.split(output, "\n", trim: true)
    json_line = Enum.find(lines, &String.starts_with?(&1, "{"))
    
    assert json_line != nil, "Expected JSON output, got:\n#{output}"
    parsed = Jason.decode!(json_line)
    
    assert parsed["incident"] == "single-transaction"
    assert parsed["status"] == "executed"
    assert parsed["tx_changes"] >= 2
  end
end
