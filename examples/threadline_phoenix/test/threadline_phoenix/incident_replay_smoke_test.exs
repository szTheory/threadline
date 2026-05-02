defmodule ThreadlinePhoenix.IncidentReplaySmokeTest do
  use ThreadlinePhoenix.DataCase, async: false

  @script_path "priv/scripts/incident_replay.exs"

  describe "Incident Replay Script" do
    test "aborts when THREADLINE_REPLAY_DISPOSABLE_DB is missing" do
      {output, exit_code} =
        System.cmd("mix", ["run", @script_path, "--incident", "who-changed-row"],
          env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "0"}, {"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert exit_code != 0
      assert output =~ "THREADLINE_REPLAY_DISPOSABLE_DB must be set to 1"
      
      # Should also fail if entirely unset
      {_output, exit_code2} =
        System.cmd("mix", ["run", @script_path, "--incident", "who-changed-row"],
          env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", nil}, {"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )
      assert exit_code2 != 0
    end

    test "dry run mode (default) does not mutate" do
      {output, exit_code} =
        System.cmd("mix", ["run", @script_path, "--incident", "who-changed-row"],
          env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "1"}, {"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert exit_code == 0
      
      # Parse the last line as JSON (mix run can output compilation info, so we take the last non-empty line)
      json_line = output |> String.split("\n", trim: true) |> List.last()
      
      assert {:ok, parsed} = Jason.decode(json_line)
      assert parsed["status"] == "info"
      assert parsed["message"] =~ "Dry run enabled"
      assert parsed["incident"] == "who-changed-row"
    end

    test "executes who-changed-row scenario successfully" do
      # Seed some initial data if needed, but DataCase does it or we can do it here
      %ThreadlinePhoenix.Post{}
      |> ThreadlinePhoenix.Post.changeset(%{title: "Test Post", slug: "test-#{System.unique_integer()}"})
      |> ThreadlinePhoenix.Repo.insert!()

      {output, exit_code} =
        System.cmd("mix", ["run", @script_path, "--incident", "who-changed-row", "--execute"],
          env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "1"}, {"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert exit_code == 0
      json_line = output |> String.split("\n", trim: true) |> List.last()
      
      assert {:ok, parsed} = Jason.decode(json_line)
      assert parsed["status"] == "success"
      assert parsed["incident"] == "who-changed-row"
      assert parsed["changes_count"] >= 1
    end
    
    test "executes service-account-today scenario successfully" do
      {output, exit_code} =
        System.cmd("mix", ["run", @script_path, "--incident", "service-account-today", "--execute"],
          env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "1"}, {"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert exit_code == 0
      json_line = output |> String.split("\n", trim: true) |> List.last()
      
      assert {:ok, parsed} = Jason.decode(json_line)
      assert parsed["status"] == "success"
      assert parsed["incident"] == "service-account-today"
      assert parsed["changes_count"] == 1
    end
    
    test "executes oban-job-mutation scenario successfully" do
      {output, exit_code} =
        System.cmd("mix", ["run", @script_path, "--incident", "oban-job-mutation", "--execute"],
          env: [{"THREADLINE_REPLAY_DISPOSABLE_DB", "1"}, {"MIX_ENV", "test"}],
          stderr_to_stdout: true
        )

      assert exit_code == 0
      json_line = output |> String.split("\n", trim: true) |> List.last()
      
      assert {:ok, parsed} = Jason.decode(json_line)
      assert parsed["status"] == "success"
      assert parsed["incident"] == "oban-job-mutation"
      assert parsed["changes_count"] == 1
    end
  end
end
