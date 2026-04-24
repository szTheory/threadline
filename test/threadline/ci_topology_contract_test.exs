defmodule Threadline.CiTopologyContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
    yaml = read_rel!([".github", "workflows", "ci.yml"])

    assert String.contains?(yaml, "verify-pgbouncer-topology:")
    assert String.contains?(yaml, "POOL_MODE: transaction")
    assert String.contains?(yaml, "AUTH_TYPE: scram-sha-256")
    assert String.contains?(yaml, "THREADLINE_PGBOUNCER_TOPOLOGY: \"1\"")
    assert String.contains?(yaml, "mix verify.topology")
    assert String.contains?(yaml, "priv/ci/topology_bootstrap.exs")
    assert String.contains?(yaml, "edoburu/pgbouncer:")
  end

  test "adoption pilot backlog carries CI topology contract marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "CI-PGBOUNCER-TOPOLOGY-CONTRACT")
  end

  test "adoption pilot backlog carries STG host topology template marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
  end

  test "adoption pilot backlog carries STG audited path rubric marker" do
    doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
    assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  end
end
